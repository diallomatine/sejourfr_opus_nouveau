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

/// Ce que l'Accueil montre du parcours : **deux étapes**, pas plus (demande du
/// propriétaire, 2026-09-12 — un parcours d'expression en compte huit, et la
/// carte poussait tout le reste de l'écran hors de vue).
const int kHomePlanStepsMax = 2;

/// La fenêtre d'étapes affichée sur l'Accueil.
///
/// 🛑 **Un plafond d'AFFICHAGE, jamais un budget pédagogique** : le parcours
/// entier est servi, il est **calculé en entier**, et il se lit sur le Plan —
/// où « Voir mon Plan » renvoie. On n'en tronque que la vue.
///
/// 🛑 **La fenêtre contient TOUJOURS l'étape en cours** : elle et la suivante,
/// ou la précédente et elle quand elle ferme le parcours. Montrer « les deux
/// premières » aurait caché exactement ce que le candidat doit faire
/// maintenant. Sans étape en cours **servie**, on prend les premières — on n'en
/// devine aucune.
List<SfPathStep> homePlanSteps(List<SfPathStep> steps) {
  if (steps.length <= kHomePlanStepsMax) return steps;
  final maintenant = steps.indexWhere((s) => s.state == SfStepState.now);
  if (maintenant < 0) {
    return steps.take(kHomePlanStepsMax).toList(growable: false);
  }
  final debut = maintenant + kHomePlanStepsMax <= steps.length
      ? maintenant
      : steps.length - kHomePlanStepsMax;
  return steps.sublist(debut, debut + kHomePlanStepsMax);
}

/// **Votre Plan** — la priorité actuelle et son parcours, en aperçu.
///
/// 🛑 **Un aperçu, pas un second Plan** : aucune action ne part d'ici, la carte
/// mène au Plan, qui porte les lanceurs. Les états des étapes sont **servis** —
/// la dérivation vit dans `planTaskPath` (TCF) et `civicPath` (civique), toutes
/// deux partagées avec l'écran Plan.
class HomeMiniPlan extends StatelessWidget {
  const HomeMiniPlan({
    super.key,
    required this.title,
    this.subtitle,
    this.counter,
    required this.steps,
    required this.onOpen,
  });

  final String title;
  final String? subtitle;

  /// « Étape 3 / 5 ». `null` quand le serveur n'en sert pas.
  final String? counter;
  final List<SfPathStep> steps;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: SfLabel(kHomePlanCurrentLabel)),
              if (counter != null) ...[
                const SizedBox(width: 10),
                SfTiny(counter!),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style:
                AppFonts.display(size: 17, weight: FontWeight.w700, height: 1.2),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            SfTiny(subtitle!),
          ],
          const SizedBox(height: 10),
          for (final step in homePlanSteps(steps))
            SfPathRow(label: step.label, state: step.state),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: HomeLink(label: kHomePlanLink, onTap: onOpen),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------- parcours ---- */

/// Une ligne de « Vos parcours » : le module, ce qu'elle ouvre, un chevron.
///
/// 🛑 **Ce bloc n'est PAS scopé** : il garde la vue d'ensemble des deux modules
/// pendant que le reste de l'écran suit la bascule.
class HomeTrackRow extends StatelessWidget {
  const HomeTrackRow({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.ui(size: 15.5, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 1),
                    const SfTiny(kHomeTrackLink),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.arrowRight, size: 20, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

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
            Text(
              label,
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blue,
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
