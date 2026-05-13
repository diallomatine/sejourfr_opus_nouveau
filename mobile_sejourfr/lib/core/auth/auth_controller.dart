import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_repository.dart';
import '../models/auth_models.dart';
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

  Future<void> _bootstrap() async {
    final access = await _storage.readAccess();
    if (access == null) {
      state = const AuthUnauthenticated();
      return;
    }
    // Token présent : on tente /me. Si le token est expiré, l'intercepteur
    // de Dio va refresh automatiquement. Si tout échoue, on tombe en logout.
    try {
      final user = await _repo.me();
      state = AuthAuthenticated(user);
    } catch (_) {
      await _storage.clear();
      state = const AuthUnauthenticated();
    }
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

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthUnauthenticated();
  }

  /// Logout déclenché par l'intercepteur quand le refresh échoue.
  void forceLogout() {
    // Pas besoin d'attendre le clear : il a déjà eu lieu côté intercepteur.
    state = const AuthUnauthenticated();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
