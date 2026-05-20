import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Waveform animee (33 barres) calquee sur `.waveform` du mockup HTML.
/// Combine l'amplitude reelle du micro avec une variation sinusoidale pour
/// rester visuellement vivant meme quand le signal est faible.
class RecordingWaveform extends StatefulWidget {
  const RecordingWaveform({super.key, this.amplitude, this.barCount = 33});

  /// Amplitude normalisee 0..1. Si null, juste un mouvement decoratif.
  final double? amplitude;
  final int barCount;

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value * 2 * math.pi;
          final amp = widget.amplitude ?? 0.35;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              // Hauteur = base + amp(amplitude reelle) + variation sinusoidale.
              const base = 10.0;
              final wave = (math.sin(t + i * 0.55).abs()) * 18.0;
              final h = (base + amp * 32.0 + wave).clamp(8.0, 60.0).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
