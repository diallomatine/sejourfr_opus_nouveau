import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Timer décompte pour l'examen blanc. Appelle [onElapsed] quand le temps
/// arrive à zéro.
class ExamTimer extends StatefulWidget {
  const ExamTimer({
    super.key,
    required this.durationSeconds,
    required this.startedAt,
    required this.onElapsed,
  });

  final int durationSeconds;
  final DateTime startedAt;
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
    final elapsed = DateTime.now().difference(widget.startedAt);
    final remaining =
        Duration(seconds: widget.durationSeconds) - elapsed;
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
          Icon(Icons.timer_outlined, size: 14, color: color),
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
