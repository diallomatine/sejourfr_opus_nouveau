import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Timer décompte d'une épreuve. Appelle [onElapsed] quand le temps arrive à
/// zéro.
///
/// 🛑 **Il décompte vers une ÉCHÉANCE ABSOLUE**, jamais vers une durée relancée
/// à l'ouverture de l'écran : quitter ne suspend rien, le temps court pendant
/// l'absence et l'app doit reprendre avec le temps réellement restant. Passer
/// `deadline` évite de recomposer un chrono localement — l'échéance vient du
/// serveur (`FullTcfExamSubAttempt.deadlineAt`) chaque fois qu'elle est
/// disponible ; [ExamTimer.fromStart] n'est là que pour les sessions isolées,
/// dont le `startedAt` **est** l'ancre.
class ExamTimer extends StatefulWidget {
  const ExamTimer({super.key, required this.deadline, required this.onElapsed});

  /// Session isolée : l'échéance se déduit de son début et de sa durée.
  ExamTimer.fromStart({
    super.key,
    required DateTime startedAt,
    required int durationSeconds,
    required this.onElapsed,
  }) : deadline = startedAt.add(Duration(seconds: durationSeconds));

  final DateTime deadline;
  final VoidCallback onElapsed;

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> {
  Timer? _ticker;
  late Duration _remaining;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _compute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _compute());
  }

  void _compute() {
    final remaining = widget.deadline.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    if (mounted) setState(() => _remaining = clamped);
    if (!_fired && clamped == Duration.zero) {
      _fired = true;
      widget.onElapsed();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = _remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = _remaining.inSeconds <= 300; // 5 dernières minutes
    final color = urgent ? AppColors.red : AppColors.blue;
    final bg =
        urgent ? AppColors.redLight : AppColors.blueLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$mm:$ss',
            style: AppFonts.mono(
              size: 13,
              color: color,
              letterSpacing: 1.5,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
