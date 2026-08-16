import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Maintien de l'ecran allume, **compte par references**.
///
/// Plusieurs surfaces peuvent le demander en meme temps (un enregistrement en
/// cours, un ecran qui veut rester lisible, une session temps reel) : le
/// relachement de l'une ne doit jamais eteindre pour les autres. On compte donc
/// les detenteurs par `reason` et la plateforme n'est appelee qu'aux
/// transitions 0 -> 1 et 1 -> 0.
///
/// Deux invariants a ne pas casser :
/// - **rien ne remonte a l'appelant** : un wakelock qui echoue est un confort
///   perdu, jamais un enregistrement casse. Toute exception plateforme est
///   avalee et journalisee en debug.
/// - **`release` d'une raison jamais acquise est un no-op** : un double
///   relachement (dispose + listener d'etat) ne doit pas faire passer le
///   compteur sous zero et eteindre pour un autre detenteur.
///
/// Cycle de vie : sur Android le drapeau `FLAG_KEEP_SCREEN_ON` est pose sur la
/// fenetre de l'activite. On le **re-applique au retour au premier plan** tant
/// qu'un detenteur existe, pour ne pas dependre de ce que l'OS a fait de la
/// fenetre pendant la mise en arriere-plan. L'observer de cycle de vie vit ici,
/// pas dans `main.dart` : la primitive doit rester autonome.
class ScreenWakeLock with WidgetsBindingObserver {
  ScreenWakeLock();

  /// Detenteurs courants, par raison (une raison peut etre detenue N fois).
  final Map<String, int> _holders = <String, int>{};
  bool _observing = false;

  /// Vrai des qu'au moins un detenteur demande l'ecran allume.
  bool get isHeld => _holders.isNotEmpty;

  /// Demande le maintien de l'ecran pour [reason]. Idempotent au sens ou
  /// l'appel plateforme n'a lieu qu'a la premiere demande ; les suivantes ne
  /// font qu'incrementer le compteur.
  Future<void> acquire(String reason) async {
    final wasHeld = isHeld;
    _holders.update(reason, (n) => n + 1, ifAbsent: () => 1);
    if (wasHeld) return;
    _startObserving();
    await _apply(enabled: true);
  }

  /// Relache la demande de [reason]. Sans effet si cette raison n'est pas
  /// detenue -- un double relachement est un cas normal, pas une erreur.
  Future<void> release(String reason) async {
    final current = _holders[reason];
    if (current == null) return;
    if (current > 1) {
      _holders[reason] = current - 1;
      return;
    }
    _holders.remove(reason);
    if (isHeld) return;
    _stopObserving();
    await _apply(enabled: false);
  }

  /// Relache tous les detenteurs d'un coup (destruction de la primitive).
  Future<void> releaseAll() async {
    if (!isHeld) return;
    _holders.clear();
    _stopObserving();
    await _apply(enabled: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isHeld) {
      unawaited(_apply(enabled: true));
    }
  }

  Future<void> dispose() => releaseAll();

  void _startObserving() {
    if (_observing) return;
    _observing = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void _stopObserving() {
    if (!_observing) return;
    _observing = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> _apply({required bool enabled}) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (e) {
      dev.log(
        'Wakelock ${enabled ? 'enable' : 'disable'} refuse par la plateforme',
        name: 'ScreenWakeLock',
        error: e,
      );
    }
  }
}

/// Singleton applicatif : le compteur de references n'a de sens que s'il est
/// partage par toutes les surfaces (l'enregistreur audio est lui-meme un
/// singleton consomme par 3 modules).
final screenWakeLockProvider = Provider<ScreenWakeLock>((ref) {
  final lock = ScreenWakeLock();
  ref.onDispose(lock.dispose);
  return lock;
});
