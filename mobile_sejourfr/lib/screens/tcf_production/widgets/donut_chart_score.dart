import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';

/// Carte de note de la tache : explication a gauche, donut a droite avec la
/// note en son centre. Miroir strict du `ProductionScoreHero` web.
///
/// La note est celle du TCF, sur la MEME echelle que l'examen officiel
/// (10-20 = B2, 6-9 = B1, 2-5 = A2, 1 = A1, 0 = hors sujet). Deux consequences
/// portees ici :
///
/// - **aucun pourcentage** : sur cette echelle comprimee, 7/20 vaut B1 — le
///   niveau exige pour la carte de resident — et s'afficherait en « 35 % » ;
/// - **aucun libelle scolaire** (« en progres », « a retravailler ») ni rampe
///   [masteryColor] : la teinte suit le palier CECRL, pas un barreme sur 100.
///
/// Ce qui reste vrai, et ce que dit le texte : la note porte sur CETTE tache,
/// alors qu'au TCF la note sur 20 est celle de l'epreuve entiere (3 taches),
/// et c'est elle qui donne le niveau officiel.
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

  /// Teinte par palier de la grille TCF, jamais par pourcentage : sur cette
  /// echelle 10/20 est deja un B2 et 7/20 un B1, que des seuils scolaires
  /// peindraient en rouge.
  Color get _tone {
    final note = noteSur20;
    if (note == null) return AppColors.muted2;
    if (note >= 10) return AppColors.green;
    if (note >= 6) return AppColors.blue;
    if (note >= 2) return AppColors.amber;
    return AppColors.red;
  }

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
            'Note de la tâche',
            style: AppFonts.ui(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Note sur 20 attribuée par l\'IA sur l\'échelle du TCF : 10 et '
                  'plus correspond à B2, 6 à 9 à B1, 2 à 5 à A2. Elle porte sur '
                  'cette seule tâche — au TCF, la note sur 20 est celle de '
                  'l\'épreuve entière, tes trois tâches.',
                  style:
                      AppFonts.ui(size: 12, color: AppColors.muted, height: 1.5),
                ),
              ),
              const SizedBox(width: 14),
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
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatNote(),
                            style: AppFonts.display(
                              size: 24,
                              weight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          TextSpan(
                            text: '/20',
                            style: AppFonts.ui(
                              size: 12,
                              weight: FontWeight.w500,
                              color: AppColors.muted2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
