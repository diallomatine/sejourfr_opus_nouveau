import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';

/// Carte de score "EE" : donut a droite (CustomPainter), texte score /20 a
/// gauche. Aucun niveau CECRL ici : le niveau n'est attribue qu'au bilan
/// d'epreuve (examen blanc).
///
/// La couleur du donut suit la rampe de maitrise de la marque
/// ([masteryColor]) — pas de teinte hors palette.
///
/// La note est PEDAGOGIQUE : notre echelle (16-20 = B2, 11-15 = B1, 6-10 = A2,
/// 1-5 = A1) est plus fine que celle du TCF, ou 10/20 vaut deja B2. Aucune
/// correspondance TCF ici — au TCF, la note /20 porte sur les 3 taches d'une
/// epreuve, jamais sur une tache isolee.
class DonutChartScore extends StatelessWidget {
  const DonutChartScore({
    super.key,
    required this.noteSur20,
  });

  /// Note 0..20 ; null si pas evaluable.
  final double? noteSur20;

  double get _percent {
    if (noteSur20 == null) return 0.0;
    return ((noteSur20! / 20.0) * 100).clamp(0, 100).toDouble();
  }

  String get _percentLabel {
    final p = _percent;
    if (p == p.truncateToDouble()) return '${p.toInt()}%';
    return '${p.toStringAsFixed(0)}%';
  }

  String get _subLabel {
    final p = _percent;
    if (p == 0) return 'Non évaluable';
    if (p < 40) return 'À retravailler';
    if (p < 60) return 'En progrès';
    if (p < 80) return 'Bon niveau';
    return 'Très bon niveau';
  }

  Color get _tone => masteryColor(_percent);

  String _formatNote() =>
      noteSur20 == null ? '—' : formatScore(noteSur20!);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note pédagogique de la tâche',
            style: AppFonts.ui(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatNote(),
                            style: AppFonts.ui(
                              size: 28,
                              weight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          TextSpan(
                            text: '/20',
                            style: AppFonts.ui(
                              size: 14,
                              weight: FontWeight.w500,
                              color: AppColors.muted2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subLabel,
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _DonutPainter(
                        percent: _percent,
                        background: _tone.withValues(alpha: 0.14),
                        foreground: _tone,
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _percentLabel,
                          style: AppFonts.ui(
                            size: 20,
                            weight: FontWeight.w700,
                            color: _tone,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subLabel,
                          style: AppFonts.ui(
                            size: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Note sur 20 attribuée par l\'IA selon les critères du TCF. Notre '
            'échelle est plus fine que celle du TCF, qui note l\'épreuve entière '
            'et pas une tâche : la correspondance officielle s\'affiche au bilan '
            'de l\'épreuve.',
            style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.percent,
    required this.background,
    required this.foreground,
    required this.strokeWidth,
  });

  final double percent; // 0..100
  final Color background;
  final Color foreground;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final bgPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (percent <= 0) return;
    final fgPaint = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = (percent / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.percent != percent ||
      old.background != background ||
      old.foreground != foreground ||
      old.strokeWidth != strokeWidth;
}
