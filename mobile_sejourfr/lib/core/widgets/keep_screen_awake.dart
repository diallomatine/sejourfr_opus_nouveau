import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/screen_wake_lock.dart';

/// « Tant que ce sous-arbre est affiche, l'ecran reste allume. »
///
/// Enveloppe declarative de [ScreenWakeLock] pour les ecrans qui n'ont pas de
/// service a cabler : acquisition au montage, relachement a la destruction, et
/// bascule a chaud via [enabled] (pendant de `useScreenWakeLock(active)` cote
/// web). Le comptage par references vit dans la primitive : deux
/// [KeepScreenAwake] montes en meme temps ne se marchent pas dessus.
class KeepScreenAwake extends ConsumerStatefulWidget {
  const KeepScreenAwake({
    super.key,
    required this.child,
    this.reason = 'screen',
    this.enabled = true,
  });

  final Widget child;

  /// Identifie le detenteur dans le compteur de references. Deux surfaces
  /// distinctes doivent porter deux raisons distinctes.
  final String reason;

  /// Faux = on relache sans demonter le sous-arbre.
  final bool enabled;

  @override
  ConsumerState<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends ConsumerState<KeepScreenAwake> {
  late final ScreenWakeLock _lock;
  String? _heldReason;

  @override
  void initState() {
    super.initState();
    _lock = ref.read(screenWakeLockProvider);
    _sync();
  }

  @override
  void didUpdateWidget(covariant KeepScreenAwake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_heldReason != null && _heldReason != widget.reason) _releaseHeld();
    _sync();
  }

  @override
  void dispose() {
    _releaseHeld();
    super.dispose();
  }

  void _sync() {
    if (widget.enabled && _heldReason == null) {
      _heldReason = widget.reason;
      unawaited(_lock.acquire(widget.reason));
    } else if (!widget.enabled) {
      _releaseHeld();
    }
  }

  void _releaseHeld() {
    final held = _heldReason;
    if (held == null) return;
    _heldReason = null;
    unawaited(_lock.release(held));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
