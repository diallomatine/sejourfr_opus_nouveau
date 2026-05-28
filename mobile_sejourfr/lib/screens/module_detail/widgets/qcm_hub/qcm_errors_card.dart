import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Carte « Erreurs à revoir » du hub TCF QCM. Pastille ambre + libellé
/// dynamique (compteur de questions ratées) + chevron. Tap → page Erreurs.
class QcmErrorsCard extends StatelessWidget {
  const QcmErrorsCard({
    super.key,
    required this.wrongCount,
    required this.onTap,
  });

  final int? wrongCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = wrongCount == null
        ? 'Revoir tes questions ratées'
        : wrongCount! == 0
            ? 'Aucune erreur pour l\'instant'
            : '$wrongCount question${wrongCount! > 1 ? "s" : ""} à revoir';

    return Container(
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Erreurs à revoir',
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
