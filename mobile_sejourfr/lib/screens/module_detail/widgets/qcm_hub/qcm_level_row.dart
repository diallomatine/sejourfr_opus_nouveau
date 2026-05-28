import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Ligne d'un niveau CECRL (A2/B1/B2) dans le hub TCF QCM. Pastille colorée à
/// gauche, titre + sous-titre, compteur de lots à droite, chevron.
class QcmLevelRow extends StatelessWidget {
  const QcmLevelRow({
    super.key,
    required this.levelLabel,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentBg,
    required this.onTap,
    required this.lotCount,
  });

  final String levelLabel;
  final String title;
  final String subtitle;
  final Color accent;
  final Color accentBg;
  final VoidCallback onTap;
  final int? lotCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    levelLabel,
                    style: AppFonts.jakarta(
                      size: 13,
                      weight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppFonts.jakarta(
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (lotCount != null) ...[
                  Text(
                    '$lotCount lots',
                    style:
                        AppFonts.jakarta(size: 11, color: AppColors.muted2),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted2,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
