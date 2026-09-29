import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// Bannière d'avertissement bleue rendue en haut du hub TCF QCM quand le
/// module n'est pas évalué au TCF IRN officiel (Structure de la langue).
class QcmNoticeBanner extends StatelessWidget {
  const QcmNoticeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.info, color: AppColors.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'À SAVOIR',
                  style: AppFonts.label(size: 10.5, color: AppColors.blue),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.ink2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
