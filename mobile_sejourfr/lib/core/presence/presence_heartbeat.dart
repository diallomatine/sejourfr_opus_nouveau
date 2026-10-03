import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/presence_repository.dart';
import '../api/repositories.dart';
import '../auth/auth_controller.dart';

/// Battement de présence d'un compte connecté (chantier « Activité », D1-D3) —
/// le seul de l'app. Miroir web : `lib/presence.ts`.
///
/// - **Premier plan uniquement** : un battement immédiat quand l'app passe en
///   `AppLifecycleState.resumed`, puis toutes les 60 s ; arrêt dès qu'elle le
///   quitte (`inactive`, `hidden`, `paused`, `detached`).
/// - **Compte connecté uniquement** : armé sur `AuthAuthenticated`, désarmé à
///   la déconnexion.
/// - **Best-effort** : un échec est silencieux et n'est jamais rejoué. Le
///   rafraîchissement de jeton est celui de tout appel (`ApiClient`), jamais
///   déclenché exprès.
///
/// Rien n'est écrit sur l'appareil.
class PresenceHeartbeat {
  PresenceHeartbeat({required PresenceRepository repository})
      : _repository = repository;

  static const Duration period = Duration(seconds: 60);

  final PresenceRepository _repository;
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  bool _authenticated = false;
  bool _foreground = false;

  void start() {
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) =>
          _setForeground(state == AppLifecycleState.resumed),
    );
    _sync();
  }

  void setAuthenticated(bool authenticated) {
    if (_authenticated == authenticated) return;
    _authenticated = authenticated;
    _sync();
  }

  void dispose() {
    _lifecycle?.dispose();
    _lifecycle = null;
    _stop();
  }

  void _setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    _sync();
  }

  void _sync() {
    if (!_authenticated || !_foreground) {
      _stop();
      return;
    }
    if (_timer != null) return;
    unawaited(_beat());
    _timer = Timer.periodic(period, (_) => unawaited(_beat()));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _beat() async {
    try {
      await _repository.beat();
    } catch (_) {
      // Un battement perdu est sans conséquence.
    }
  }
}

/// Vivant toute la session : `SejourFrApp` l'observe, à côté de la file
/// d'analytics.
final Provider<PresenceHeartbeat> presenceHeartbeatProvider =
    Provider<PresenceHeartbeat>((ref) {
  final heartbeat = PresenceHeartbeat(
    repository: ref.watch(presenceRepositoryProvider),
  )..start();
  ref.listen<AuthState>(
    authControllerProvider,
    (_, next) => heartbeat.setAuthenticated(next is AuthAuthenticated),
    fireImmediately: true,
  );
  ref.onDispose(heartbeat.dispose);
  return heartbeat;
});
