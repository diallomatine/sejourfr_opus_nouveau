import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../home_labels.dart';

/// Les briques **propres à l'Accueil** — le bandeau d'un compte sans
/// démarche. Les blocs de la maquette (objectifs, cartes d'action) vivent dans
/// le kit (`SfObjectivesCard`, `SfActionCard`).
///
/// 🛑 **Aucune couleur en dur** : `AppColors` / `AppFonts` / `AppRadii`
/// exclusivement.

/* --------------------------------------------------------------- bandeau -- */

/// Le bandeau « Choisissez votre parcours » d'un compte sans démarche.
class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: sfGutter.add(const EdgeInsets.only(top: 14)),
      child: Material(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kHomeParcoursBannerTitle,
                        style: AppFonts.ui(
                          size: 14,
                          weight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kHomeParcoursBannerText,
                        style: AppFonts.ui(
                          size: 13,
                          color: AppColors.ink2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(LucideIcons.arrowRight,
                    size: 18, color: AppColors.blue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
