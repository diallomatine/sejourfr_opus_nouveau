import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../home_labels.dart';

/// Les briques **propres à l'Accueil**.
///
/// 🛑 **Elles ne montent pas dans le kit**, et c'est la règle : le kit porte
/// les motifs des écrans de diagnostic et de plan, communs aux deux fronts
/// brique pour brique. Ce qui suit est le pendant Dart de la feuille
/// `homeStyles` du web — locale à son écran des deux côtés.
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

/* --------------------------------------------------------- votre plan ---- */

/// 🛑 **`HomeMiniPlan`, `homePlanSteps` et `kHomePlanStepsMax` sont SUPPRIMÉS**
/// le 2026-09-19 (arbitrage du propriétaire) : l'aperçu « Votre Plan » a quitté
/// l'Accueil, des deux côtés — le Plan entier se lit sur `/plan`, où la carte
/// menait. **Ne pas les recréer** ; le plafond d'affichage des deux étapes est
/// parti avec eux, et son miroir web (`apercuSteps`) aussi.

/* ------------------------------------------------- où vous en êtes ------- */

/// 🛑 **« Où vous en êtes » est passé dans le KIT le 2026-09-16** (maquette du
/// propriétaire), avec son miroir web dans la même passe : `SfLevelLadder`,
/// `SfLevelCard`, `SfLevelCardGrid` (maquette v3, 2026-09-24), `SfGoalBanner`
/// et `SfMicroNote` remplacent
/// `HomeSituationCard`, `HomeSituationGrid` et `HomeGoalBanner`, **supprimées**
/// avec leurs appelants. C'est ce qui garantit que les deux fronts montrent la
/// même carte, brique pour brique.


/* ----------------------------------------------------------- parcours ---- */

/// 🛑 **`HomeTrackRow` est SUPPRIMÉ** le 2026-09-19 (arbitrage du
/// propriétaire) : « Vos parcours » a quitté l'Accueil des deux côtés — la
/// **bascule** en tête d'écran fait déjà ce travail, et la bottom nav porte
/// Réviser et Examens. Ne pas la recréer.

/* -------------------------------------------------------------- liens ---- */

/// Le lien bleu à flèche des cartes de l'Accueil (`.sf-link` de la maquette).
class HomeLink extends StatelessWidget {
  const HomeLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Le libellé cède, la flèche non : dans une demi-largeur de carte,
            // « Voir mes résultats » dépasse la ligne et pousserait la flèche
            // hors du cadre. Même garde que le `flex-shrink: 0` posé sur le
            // chevron côté web.
            Flexible(
              child: Text(
                label,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.arrowRight, size: 15, color: AppColors.blue),
          ],
        ),
      ),
    );
  }
}

/// L'action secondaire d'une carte : un lien centré, jamais un second bouton
/// plein — une seule action dominante par écran.
class HomeSoftAction extends StatelessWidget {
  const HomeSoftAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            label,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
