import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_repository.dart';
import '../api/billing_repository.dart';
import '../api/repositories.dart';
import '../models/account_models.dart';
import '../models/auth_models.dart';
import '../models/billing_models.dart';
import 'social_sign_in_service.dart';
import 'token_storage.dart';

// ---------------------------------------------------------------------------
// Dependency providers
// ---------------------------------------------------------------------------

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(tokenStorage: storage);
  client.onUnauthorized = () {
    // Force le passage en état "déconnecté" si le refresh échoue.
    ref.read(authControllerProvider.notifier).forceLogout();
  };
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final socialSignInServiceProvider = Provider<SocialSignInService>(
  (ref) => SocialSignInService(),
);

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthLoading()) {
    _bootstrap();
  }

  final Ref _ref;

  TokenStorage get _storage => _ref.read(tokenStorageProvider);
  AuthRepository get _repo => _ref.read(authRepositoryProvider);
  BillingRepository get _billing => _ref.read(billingRepositoryProvider);
  SocialSignInService get _socialService =>
      _ref.read(socialSignInServiceProvider);

  /// Durée minimale d'affichage du splash, pour éviter un flash quand le
  /// bootstrap est très rapide (typiquement quand il n'y a pas de token).
  static const _minSplashDuration = Duration(milliseconds: 900);

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    // Défaut sûr : si quoi que ce soit échoue ci-dessous, on quitte le splash
    // vers l'écran de connexion plutôt que de rester bloqué en AuthLoading.
    AuthState next = const AuthUnauthenticated();
    try {
      final access = await _storage.readAccess();
      if (access != null) {
        // Token présent : on tente /me. Si le token est expiré, l'intercepteur
        // de Dio refresh automatiquement. Si tout échoue, on tombe en logout.
        try {
          AuthUser user = await _repo.me();
          // Sync best-effort de l'état Premium depuis /subscription-status.
          // Source de vérité unique côté backend (Stripe + Apple + Google
          // agrégés). En cas d'échec réseau, on garde l'état renvoyé par /me.
          try {
            final status = await _billing.getSubscriptionStatus();
            user = _applyStatus(user, status);
          } catch (_) {/* tolérant */}
          next = AuthAuthenticated(user);
        } catch (_) {
          await _storage.clear();
          next = const AuthUnauthenticated();
        }
      }
    } catch (_) {
      // Filet de sécurité : un secure storage illisible (données chiffrées
      // d'une ancienne version, clé Keystore invalidée…) ne doit jamais figer
      // le boot. On repart d'un état propre. Sans ce catch, l'exception
      // laissait l'app coincée sur le splash (bug de mise à jour Android).
      try {
        await _storage.clear();
      } catch (_) {/* best-effort */}
      next = const AuthUnauthenticated();
    }
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minSplashDuration) {
      await Future.delayed(_minSplashDuration - elapsed);
    }
    state = next;
  }

  /// Met à jour le user authentifié avec un statut Premium fraîchement obtenu
  /// du backend (typiquement après un verify-receipt IAP ou un appel direct
  /// à /subscription-status). No-op si on n'est pas authentifié.
  Future<void> refreshSubscriptionStatus([
    SubscriptionStatusResponse? known,
  ]) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    SubscriptionStatusResponse status;
    if (known != null) {
      status = known;
    } else {
      try {
        status = await _billing.getSubscriptionStatus();
      } catch (_) {
        return;
      }
    }
    final updated = _applyStatus(current.user, status);
    await _storage.saveUser(updated);
    state = AuthAuthenticated(updated);
  }

  AuthUser _applyStatus(AuthUser user, SubscriptionStatusResponse status) {
    return user.copyWith(
      isPremium: status.isPremium,
      hasCivique: status.hasCivique,
      hasTcf: status.hasTcf,
      premiumEndsAt: status.expiresAt,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final tokens = await _repo.login(email: email, password: password);
    await _storage.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: tokens.user,
    );
    state = AuthAuthenticated(tokens.user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final tokens = await _repo.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    await _storage.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: tokens.user,
    );
    state = AuthAuthenticated(tokens.user);
  }

  /// Sign-in via Google. Levee `SocialSignInException` si l'utilisateur
  /// annule ou si le provider est mal configure — a attraper dans l'ecran
  /// appelant pour distinguer annulation et erreur.
  Future<void> loginWithGoogle() async {
    final result = await _socialService.signInWithGoogle();
    final tokens = await _repo.loginWithGoogle(idToken: result.idToken);
    await _storage.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: tokens.user,
    );
    state = AuthAuthenticated(tokens.user);
  }

  /// Sign-in via Apple (iOS uniquement). Idem Google cote levees.
  Future<void> loginWithApple() async {
    final result = await _socialService.signInWithApple();
    final tokens = await _repo.loginWithApple(
      identityToken: result.idToken,
      firstName: result.firstName,
      lastName: result.lastName,
    );
    await _storage.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: tokens.user,
    );
    state = AuthAuthenticated(tokens.user);
  }

  Future<void> logout() async {
    // Révocation serveur du refresh token (best-effort — le repo absorbe
    // les erreurs réseau). Sans ça, un refresh token volé resterait
    // utilisable jusqu'à son expiration de 30 jours.
    final refreshToken = await _storage.readRefresh();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _repo.logout(refreshToken: refreshToken);
    }
    await _socialService.signOutAll();
    await _storage.clear();
    state = const AuthUnauthenticated();
  }

  /// Supprime définitivement le compte côté backend (anonymisation). Ne touche
  /// PAS la session : l'écran appelant peut ainsi afficher un éventuel message
  /// d'action manuelle (résiliation Apple/Google) tant qu'il est encore monté,
  /// puis appeler [logout] pour vider la session et déclencher la redirection.
  /// Lève si l'appel réseau échoue — la session locale reste alors intacte.
  Future<AccountDeletionResult> deleteAccount() async {
    return _repo.deleteAccount();
  }

  /// Recharge les infos du user depuis le backend et met à jour le state.
  /// Utile après un update du profil (targetProcedure, etc.).
  Future<void> refreshUser() async {
    final user = await _repo.me();
    await _storage.saveUser(user);
    state = AuthAuthenticated(user);
  }

  /// Logout déclenché par l'intercepteur sur un 401 non récupérable (session
  /// morte). Les tokens ont déjà été vidés côté intercepteur.
  ///
  /// On bascule d'abord en [AuthLoading] : le router affiche alors le splash
  /// (spinner « déconnexion en cours ») et remplace immédiatement la page
  /// courante — ainsi l'écran n'affiche jamais l'erreur 401 « Authentification
  /// requise ». Après un court instant on passe en [AuthUnauthenticated] →
  /// redirection vers l'écran de connexion.
  void forceLogout() {
    if (state is AuthUnauthenticated || state is AuthLoading) return;
    state = const AuthLoading();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (state is AuthLoading) {
        state = const AuthUnauthenticated();
      }
    });
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
