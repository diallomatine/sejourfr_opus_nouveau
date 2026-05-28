import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Bandeau « Lancer un examen blanc » du hub Civique d'un thème.
/// Pendant Civique de `QcmExamHero` — accent rouge également (signal
/// « examen » homogène sur toute l'app), eyebrow mono + titre Jakarta +
/// description + CTA rouge.
class CiviqueExamHero extends StatelessWidget {
  const CiviqueExamHero({
    super.key,
    required this.icon,
    required this.examSubtitle,
    required this.description,
    required this.onStart,
  });

  final IconData icon;

  /// Sous-titre repris dans l'eyebrow (« 20 questions · 20 min »).
  final String examSubtitle;

  /// Texte descriptif sous le titre — typiquement la formule du thème
  /// (20 Q tirées du thème, seuil 16/20).
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
              Expanded(
                child: Text(
                  'EXAMEN DU THÈME · ${examSubtitle.toUpperCase()}',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.blueDark,
                    letterSpacing: 1.2,
                    weight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
