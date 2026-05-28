import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Bandeau « Lancer un examen blanc » bleu du hub TCF QCM (CO/CE/Structure).
/// Eyebrow mono + titre Jakarta + sous-titre + CTA bleu.
class QcmExamHero extends StatelessWidget {
  const QcmExamHero({
    super.key,
    required this.icon,
    required this.examSubtitle,
    required this.description,
    required this.onStart,
  });

  final IconData icon;

  /// Sous-titre repris dans l'eyebrow (« 25 questions · 20 min »).
  final String examSubtitle;

  /// Texte descriptif sous le titre — varie selon le module (les modules
  /// officiels mentionnent la progression CECRL, Structure utilise une
  /// formulation neutre).
  final String description;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.blueDark),
              const SizedBox(width: 6),
              Text(
                'EXAMEN COMPLET · ${examSubtitle.toUpperCase()}',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blueDark,
                  letterSpacing: 1.2,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lancer un examen blanc',
            style: AppFonts.jakarta(
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      size: 18, color: AppColors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Commencer',
                    style: AppFonts.jakarta(
                      size: 13.5,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
