import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Anneau de progression de la refonte 2026 (cf. `Ring` maquette).
///
/// Affiche `value` (0-100) en arc à bouts ronds sur une piste `surface3`,
/// avec au centre le pourcentage (ou [label]) en Bricolage et un éventuel
/// [sub] en dessous.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 7,
    this.color = AppColors.blue,
    this.trackColor = AppColors.surface3,
    this.textColor = AppColors.ink,
    this.subColor = AppColors.inkFaint,
    this.label,
    this.sub,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;

  /// Piste de l'anneau. À surcharger sur fond sombre : la piste claire du
  /// thème y disparaît (le hero du parcours EE/EO est un dégradé bleu nuit).
  final Color trackColor;
  final Color textColor;
  final Color subColor;
  final String? label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 100).toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => CustomPaint(
          painter: _RingPainter(
            value: animated,
            stroke: stroke,
            color: color,
            trackColor: trackColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? '${value.round()}%',
                  style: AppFonts.display(
                    size: size * 0.27,
                    height: 1.0,
                    color: textColor,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: AppFonts.ui(size: 10, color: subColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (value / 100),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.stroke != stroke ||
      old.trackColor != trackColor;
}
