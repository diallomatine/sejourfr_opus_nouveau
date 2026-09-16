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

/* ------------------------------------------------- où vous en êtes ------- */

/// Une carte compacte de « Où vous en êtes » : le libellé, la pastille, la
/// jauge, l'état en un mot, et ce qu'on peut faire.
///
/// 🛑 **Cette brique ne classe rien.** Tout ce qu'elle rend lui arrive
/// **composé** par `accueilEpreuve*` (`screens/progres/progres_labels.dart`),
/// la même autorité que l'écran Progrès. Elle ne voit ni niveau, ni statut, ni
/// pourcentage — seulement des mots et un ton déjà décidés.
///
/// 🛑 **La jauge n'affiche aucun chiffre** : c'est le codage visuel de l'état
/// écrit juste en dessous, pas une progression vers un palier.
///
/// 🛑 **Elle vit dans une [HomeSituationGrid]**, donc sur une demi-largeur
/// d'écran : tout ce qu'elle rend doit tenir dans ~130 px de contenu.
class HomeSituationCard extends StatelessWidget {
  const HomeSituationCard({
    super.key,
    required this.title,
    required this.badge,
    required this.mesure,
    required this.statut,
    required this.jauge,
    required this.tone,
    required this.cta,
    required this.onTap,
  });

  final String title;

  /// La pastille de droite : un palier servi, ou « À évaluer ».
  final String badge;

  /// Y a-t-il une mesure derrière cette pastille ?
  ///
  /// 🛑 **Passé, jamais deviné du texte de [badge]** : comparer un libellé pour
  /// décider d'une couleur ferait dépendre l'apparence d'une chaîne qu'on peut
  /// reformuler sans y penser.
  final bool mesure;

  /// L'état en un mot. `null` quand aucune démarche n'est déclarée : sans
  /// objectif, il n'y a rien à situer, et on préfère un blanc à un verdict.
  final String? statut;

  final double jauge;
  final SfBarTone tone;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SituationHead(title: title, badge: badge, mesure: mesure),
          SfProgressMini(ratio: jauge, tone: tone, semanticsLabel: statut),
          // Sans statut (aucune démarche déclarée), la carte se referme sur la
          // jauge : un blanc de 10 px se lirait comme un mot manquant.
          if (statut != null) ...[
            const SizedBox(height: 6),
            Text(
              statut!,
              style: AppFonts.ui(size: 13, weight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: HomeLink(label: cta, onTap: onTap),
          ),
        ],
      ),
    );
  }
}

/// L'en-tête d'une carte de situation : le libellé, puis la pastille,
/// **alignée à droite sous lui**.
///
/// 🛑 **La pastille n'est PAS sur la ligne du titre**, et c'est mesuré : sur une
/// demi-largeur de téléphone la carte n'offre que ~130 px de contenu, où
/// « Compréhension » (~100 px) et « À évaluer » (~80 px) ne tiennent pas côte à
/// côte — les y forcer casserait le titre au milieu d'un mot, le pire des deux
/// rendus. Le web fait de même à ces largeurs : son `.home-situation-head`
/// laisse le navigateur renvoyer la pastille à la ligne dès que le titre ne peut
/// plus poser son mot le plus long à côté d'elle.
///
/// ⚠️ **Décidé une fois pour toutes, pas mesuré à l'exécution** : un
/// `LayoutBuilder` ici casserait la grille, qui aligne les hauteurs de deux
/// cartes par intrinsèques. L'app étant verrouillée en portrait téléphone, la
/// largeur où la rangée redeviendrait possible n'existe pas.
class _SituationHead extends StatelessWidget {
  const _SituationHead({
    required this.title,
    required this.badge,
    required this.mesure,
  });

  final String title;
  final String badge;
  final bool mesure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppFonts.ui(size: 14.5, weight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              // Non mesuré : neutre. Le bleu est réservé à un palier réel — une
              // pastille de marque sur une absence de mesure se lirait comme un
              // résultat.
              color: mesure ? AppColors.blueLight : AppColors.surface3,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              badge,
              style: AppFonts.ui(
                size: 12.5,
                weight: FontWeight.w800,
                color: mesure ? AppColors.blue : AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Les cartes de « Où vous en êtes », rangées **deux par rangée**.
///
/// 🛑 **Miroir de `.home-situation-grid` côté web**, qui pose les deux mêmes
/// colonnes sous son palier desktop. C'est la maquette du propriétaire : des
/// cartes compactes côte à côte, jamais une file de cartes pleine largeur.
///
/// 🛑 **Les deux cartes d'une rangée ont la MÊME hauteur** — c'est ce que fait
/// une grille CSS, et deux cartes décalées se liraient comme un défaut
/// d'alignement. Un nombre impair laisse la dernière sur une demi-largeur,
/// jamais étirée : elle changerait de format au milieu de la grille.
class HomeSituationGrid extends StatelessWidget {
  const HomeSituationGrid({super.key, required this.children});

  final List<Widget> children;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final rangees = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rangees.isNotEmpty) rangees.add(const SizedBox(height: _gap));
      final droite = i + 1 < children.length ? children[i + 1] : null;
      rangees.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: _gap),
              Expanded(child: droite ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rangees,
    );
  }
}

/// Le bandeau « Objectif actuel — Atteindre B1 partout », sous les cartes.
///
/// 🛑 Le palier est **servi** (`ProgressTcf.objectif`) : sans lui, ce bandeau
/// n'existe pas. On ne devine pas l'objectif d'un candidat qui n'a déclaré
/// aucune démarche.
class HomeGoalBanner extends StatelessWidget {
  const HomeGoalBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Le MÊME gris que la pastille non mesurée, et que les deux surfaces
        // du web (`--color-paper-2`) : trois gris pour deux surfaces se voient.
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              kHomeGoalLabel,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: AppFonts.ui(size: 13.5, weight: FontWeight.w800)),
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
            // Le libellé cède, la flèche non : dans une demi-largeur de carte
            // (`HomeSituationGrid`), « Voir mes résultats » dépasse la ligne et
            // pousserait la flèche hors du cadre. Même garde que le
            // `flex-shrink: 0` posé sur le chevron côté web.
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
