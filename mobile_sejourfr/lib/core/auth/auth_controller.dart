import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/auth_repository.dart';
import '../api/billing_repository.dart';
import '../api/repositories.dart';
import '../models/account_models.dart';
import '../models/auth_models.dart';
import '../models/billing_models.dart';
import '../models/enums.dart';
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

  /// Watchdog : durée maximale avant de quitter le splash coûte que coûte. Si
  /// la résolution de l'état (lecture storage, appel /me…) ne rend pas la main
  /// — canal natif gelé, réseau qui ne répond jamais — on bascule en
  /// déconnecté plutôt que de tourner indéfiniment sur le splash.
  static const _maxBootstrap = Duration(seconds: 10);

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    final next = await _resolveBootState().timeout(
      _maxBootstrap,
      onTimeout: () => const AuthUnauthenticated(),
    );
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minSplashDuration) {
      await Future.delayed(_minSplashDuration - elapsed);
    }
    state = next;
  }

  /// Détermine l'état d'auth initial. Ne lève jamais : tout chemin d'erreur
  /// retombe sur [AuthUnauthenticated] (storage nettoyé) pour garantir un état
  /// terminal — le splash ne doit jamais rester bloqué.
  Future<AuthState> _resolveBootState() async {
    try {
      final access = await _storage.readAccess();
      if (access == null) return const AuthUnauthenticated();
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
        return AuthAuthenticated(user);
      } on ApiException catch (e) {
        // 🛑 UNE COUPURE RESEAU NE DECONNECTE PAS. `statusCode == 0` dit « je
        // n'ai pas pu demander », pas « tu n'es pas toi » : effacer les jetons
        // la-dessus jetait la session d'un candidat entre dans le metro, et lui
        // redemandait son mot de passe au retour du reseau.
        if (e.isNetwork) {
          final connu = await _storage.readUser();
          // Le dernier `user` connu suffit a rouvrir l'app ; les ecrans qui ont
          // besoin du serveur diront eux-memes qu'ils n'ont pas pu charger. Et
          // s'il n'y a rien de connu, on reste deconnecte SANS effacer les
          // jetons : la prochaine ouverture avec du reseau retombera sur ses
          // pieds.
          return connu == null ? const AuthUnauthenticated() : AuthAuthenticated(connu);
        }
        await _storage.clear();
        return const AuthUnauthenticated();
      } catch (_) {
        await _storage.clear();
        return const AuthUnauthenticated();
      }
    } catch (_) {
      // Secure storage illisible (données chiffrées d'une ancienne version,
      // clé Keystore invalidée…). On repart propre.
      try {
        await _storage.clear();
      } catch (_) {/* best-effort */}
      return const AuthUnauthenticated();
    }
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
    final avant = _signatureAcces(current.user);
    state = AuthAuthenticated(updated);
    // 🛑 **Le seul point d'émission d'[accesRevisionProvider].** Les deux
    // chemins d'achat passent par ici (vérification d'un reçu, restauration),
    // donc tout ce qui porte un `locked` se relit sans que le contrôleur de
    // facturation ait à connaître une seule source.
    if (_signatureAcces(updated) != avant) {
      _ref.read(accesRevisionProvider.notifier).state++;
    }
  }

  /// Ce qui, en changeant, rouvre ou referme des surfaces. Ni prénom, ni
  /// objectif, ni date d'examen : un statut identique ne recharge rien.
  ///
  /// ⚠️ `premiumEndsAt` en fait partie — un rachat qui repousse l'échéance sans
  /// changer de module reste un accès qui a changé.
  static String _signatureAcces(AuthUser user) =>
      '${user.hasCivique}|${user.hasTcf}|${user.premiumEndsAt?.toIso8601String() ?? ''}';

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

/// **L'identité du compte connecté**, et rien d'autre : son `id`, ou `null`
/// quand personne ne l'est.
///
/// 🛑 **C'est la clé de fraîcheur de tout ce qui est gardé en vie.** Depuis que
/// les sources de l'Accueil et du Plan survivent à la vie de leur écran
/// (`ref.keepAlive`), elles survivaient aussi à un **changement de compte** :
/// se reconnecter avec un autre identifiant, sans tuer l'app, affichait le plan
/// et la progression du compte précédent. Tout provider qui garde une donnée
/// **de compte** doit donc l'observer en première ligne — `ref.watch` suffit,
/// Riverpod recrée l'état dès que l'identité change.
///
/// 🛑 **L'identité, pas le fait d'être connecté.** Un `select` sur
/// `state is AuthAuthenticated` rend un booléen : il ne bouge pas d'un compte à
/// l'autre, et n'aurait rien invalidé du tout. C'était le défaut exact.
///
/// ⚠️ Il ne change PAS sur un simple rafraîchissement du profil (statut
/// premium, prénom, date d'examen) : l'`id` est stable, donc rien n'est
/// rechargé pour rien.
///
/// ⚠️ **Il ne dit RIEN de l'accès** : un achat ne change pas l'identifiant du
/// compte. Ce qu'une donnée portant un `locked` doit observer **en plus**, c'est
/// [accesRevisionProvider].
final compteIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider.select(
    (state) => state is AuthAuthenticated ? state.user.id : null,
  ));
});

/// **Le signal « l'ACCÈS du compte a changé »** — un pass vient d'être acheté,
/// restauré, prolongé, ou n'est plus actif.
///
/// 🛑 **C'est le pendant Dart d'`invalidateAccesServi()`
/// (`web_sejoufr/lib/api.ts`)** — à ceci près que le web **purge un cache** là
/// où le mobile **relance des lectures vivantes**. Tout provider qui porte un
/// `locked` servi, un quota ou une progression l'observe en première ligne :
/// `ref.watch` suffit, Riverpod recrée son état dès qu'il bouge, **y compris
/// sous un `ref.keepAlive()`**. C'était le défaut exact — dix sources gardées
/// en vie ne se renouvelaient qu'au changement de compte, et un achat ne change
/// pas l'identifiant du compte.
///
/// 🛑 **Il est émis à UN SEUL endroit**, [AuthController.refreshSubscriptionStatus] —
/// la seule méthode qui applique un accès fraîchement vérifié. Les deux chemins
/// d'achat (vérification d'un reçu, restauration) l'appelaient **déjà** :
/// `BillingController` n'a donc aucune liste de caches à tenir, et un provider
/// ajouté plus tard n'a rien à déclarer ailleurs qu'en tête de lui-même.
///
/// ⚠️ **Il n'est PAS dérivé de l'état d'authentification**, et c'est
/// délibéré : un provider de feuille (le détail d'une compétence, un petit
/// sujet, le quota d'analyses) le lit sans faire naître l'`AuthController`,
/// donc sans traîner son amorçage — lecture du stockage sécurisé et délai de
/// splash — dans des écrans qui n'en ont que faire.
///
/// ⚠️ **Il ne bouge que si l'accès bouge**, pas à chaque rafraîchissement du
/// profil : un statut identique n'émet rien, et rien n'est rechargé pour rien.
///
/// ⚠️ **Incrémenter déclenche un appel** sur chaque source observée. C'est le
/// prix, et il est bas : une salve par achat réel, au lieu d'un écran qui ment
/// jusqu'au prochain redémarrage.
final accesRevisionProvider = StateProvider<int>((ref) => 0);

/// **L'accès servi à un module**, et la seule lecture d'un verrou d'écran.
///
/// 🛑 **Un écran ne DÉDUIT jamais un accès** : ni d'un rang, ni d'un prix, ni
/// d'un plan. Il lit `hasCivique` / `hasTcf`, servis par le backend — un pass
/// civique n'ouvre donc pas le TCF, et l'Intégral ouvre les deux, sans qu'aucun
/// front n'ait à connaître la règle.
///
/// ⚠️ **À `watch` dans un `build`** : c'est ce qui rouvre l'écran à la seconde
/// où un achat est vérifié, sans le quitter ni le remonter. Douze écrans
/// recopiaient `ref.read(authControllerProvider)` puis
/// `auth is AuthAuthenticated && auth.user.canAccessModule(...)` — un `read` ne
/// réveille rien, et l'écran resté sous le paywall gardait ses cadenas.
/// Dans un geste (un `onPressed`), `ref.read` de ce provider reste correct :
/// c'est la même valeur, lue sans s'abonner.
final accesModuleProvider = Provider.family<bool, AppModule>((ref, module) {
  return ref.watch(authControllerProvider.select(
    (state) => state is AuthAuthenticated && state.user.canAccessModule(module),
  ));
});
