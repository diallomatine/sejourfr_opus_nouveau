import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../plan_labels.dart';

/// Le bandeau « Plan actualisé » — il n'apparaît **que** si quelque chose a
/// bougé (`recentChanges != null`, dont l'absence est le cas normal). Aucune
/// ligne n'est jamais fabriquée pour remplir la place.
class PlanUpdatedBanner extends StatelessWidget {
  const PlanUpdatedBanner({
    super.key,
    required this.changes,
    required this.onTap,
  });

  final PlanRecentChanges changes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.refreshCw,
                  size: 15,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: kPlanBannerLabel,
                          style: AppFonts.ui(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: AppColors.blueDark,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${planBannerText(changes)}',
                          style: AppFonts.ui(
                            size: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
        ),
      );
}

/// La barre d'un compte sans abonnement TCF.
///
/// 🛑 **Elle ne masque rien.** Le Plan reste intégralement visible sans
/// abonnement — priorités, compteurs, exercice recommandé compris : masquer
/// priverait le candidat du résultat de sa propre production. Seuls les
/// **accès** sont fermés, et ils le sont un par un, par le `locked` que le
/// serveur pose sur chaque élément.
class PlanFreeBar extends StatelessWidget {
  const PlanFreeBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.lock,
                  size: 15,
                  color: AppColors.inkFaint,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Version gratuite',
                          style: AppFonts.ui(
                            size: 12.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' · certains entraînements demandent '
                              'l\'abonnement',
                          style: AppFonts.ui(
                            size: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Débloquer',
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
