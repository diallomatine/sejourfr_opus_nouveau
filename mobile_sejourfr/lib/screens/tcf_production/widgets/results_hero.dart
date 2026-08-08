import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_sheet.dart';
import '../production_result_labels.dart';

/// En-tête du rapport : **le verdict et le niveau dans UN SEUL bloc**, calqué
/// sur le `.hero` de la maquette « Rapport express » — dégradé de marque, halo
/// clair en haut à droite, et panneau de niveau **translucide** posé dessus.
///
/// Avant, c'étaient trois cartes empilées (bandeau « Évaluation terminée »,
/// carte objectif, carte note) qui disaient chacune une moitié de la même chose,
/// et remplissaient un écran entier avant le premier conseil. Le candidat doit
/// pouvoir répondre à « c'est bien ou pas ? » sans défiler.
///
/// **La note /20 a disparu du résultat d'une tâche** (décision produit du
/// 2026-08-08) : au TCF, un correcteur attribue **un niveau par tâche**, jamais
/// une note — le /20 ne porte que sur l'épreuve entière (3 tâches). Et comme
/// 10/20 y vaut déjà B2, un A2 parfaitement normal s'affichait « 3,5/20 », qu'un
/// francophone lit comme une catastrophe scolaire. Le **niveau** est donc le
/// héros de la carte, et la note reste là où elle a un sens : les bilans
/// d'épreuve et d'examen complet. Corollaire assumé : les bornes chiffrées du
/// barème (« 2-5 → A2 ») ne sont plus affichées nulle part ici.
///
/// Ce qui n'a pas bougé, parce que ce sont des règles et non de la mise en page :
/// - jamais de niveau sans sa confiance ([EvaluationResult.hasNiveauObserve]) ;
/// - la confiance ne s'affiche QUE lorsqu'elle n'est pas haute ;
/// - la portée du niveau ([kNiveauPorteeTache], ou l'`avertissementNiveau` du
///   backend qui la **remplace**) reste accessible en un geste.
class ProductionResultsHero extends StatelessWidget {
  const ProductionResultsHero({
    super.key,
    required this.evaluation,
    this.eyebrow,
    this.targetLevel,
  });

  final EvaluationResult evaluation;

  /// Situe la correction (« Expression écrite · Tâche 1 »). Absent depuis un
  /// contexte qui ne connaît pas la tâche : le hero se rend sans, sans trou.
  final String? eyebrow;

  /// Palier visé par la démarche du candidat. `null` = inconnu : aucun rappel
  /// d'enjeu n'est alors affiché — un message générique parlerait d'une
  /// démarche qu'il n'a pas choisie.
  final TargetLevel? targetLevel;

  /// « Objectif atteint » plutôt que « Atteint » seul : sur un hero, le mot doit
  /// se suffire à lui-même. Aucune pastille d'icône ne le précède — la maquette
  /// n'en a pas, et le verdict est déjà écrit en toutes lettres.
  static String objectifTitle(ObjectifAccomplissement o) =>
      'Objectif ${o.displayName.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final objectif = evaluation.feedback.accomplissement?.objectif;
    final resume = evaluation.feedback.accomplissement?.objectifResume;
    final niveau = evaluation.hasNiveauObserve ? evaluation.niveauObserve : null;
    final rappel = demarcheRappel(targetLevel, niveau);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.hero(AppColors.blueDark, AppColors.blue),
          ),
          child: Stack(
            children: [
              const Positioned(top: -70, right: -70, child: _Halo()),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: AppFonts.label(
                          size: 11,
                          color: AppColors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      objectif == null
                          ? 'Votre correction'
                          : objectifTitle(objectif),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        size: 25,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ).copyWith(height: 1.1),
                    ),
                    if (resume != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        resume,
                        // Trois lignes au maximum : c'est un résumé, le détail
                        // de ce qui a été traité vit dans la carte « CE QUI
                        // MARCHE » juste dessous.
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 13.5,
                          color: AppColors.white.withValues(alpha: 0.84),
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _LevelPanel(evaluation: evaluation, niveau: niveau),
                    if (rappel != null) ...[
                      const SizedBox(height: 12),
                      _StakeBlock(rappel: rappel),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le halo clair en haut à droite du dégradé (`radial-gradient` de la maquette) :
/// c'est lui qui empêche l'aplat bleu de paraître plat.
class _Halo extends StatelessWidget {
  const _Halo();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.white.withValues(alpha: 0.20),
              AppColors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panneau `.level` de la maquette : **translucide**, posé sur le dégradé.
/// Niveau atteint à gauche, pastille à droite, paliers du TCF dessous.
///
/// Le panneau entier est tactile et ouvre la règle de lecture — la pastille
/// d'information à côté du sur-titre en est le repère visible. Une ligne
/// « Comment lire ce niveau ? » écrite en toutes lettres coûtait une ligne de
/// plus dans le bloc que cette refonte est censée alléger.
class _LevelPanel extends StatelessWidget {
  const _LevelPanel({required this.evaluation, required this.niveau});

  final EvaluationResult evaluation;

  /// Niveau affichable (déjà passé par la garde « jamais sans confiance »).
  final NiveauCecrl? niveau;

  static const readingRuleTooltip = 'Comment lire ce niveau';

  /// « Votre production est au niveau A2 », pas « Proche du niveau A2 » :
  /// « proche de » veut dire « pas encore » en français courant.
  static String levelLabel(NiveauCecrl niveau) => niveauAtteintLabel(niveau);

  void _openReadingRule(BuildContext context) {
    showAppSheet<void>(
      context,
      icon: LucideIcons.info,
      title: readingRuleTooltip,
      children: [
        Text(
          evaluation.avertissementNiveau ?? kNiveauPorteeTache,
          style: AppFonts.ui(size: 13.5, color: AppColors.ink, height: 1.55),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final confiance = evaluation.confiance;
    final showConfiance =
        confiance != null && confiance != ConfianceEvaluation.haute;
    final situation = situationView(evaluation);

    return Semantics(
      button: true,
      label: readingRuleTooltip,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: () => _openReadingRule(context),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'NIVEAU ESTIMÉ',
                                  style: AppFonts.label(
                                    size: 10.5,
                                    color: AppColors.white
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                LucideIcons.info,
                                size: 13,
                                color:
                                    AppColors.white.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            niveau == null
                                ? 'Niveau indisponible pour cette production'
                                : levelLabel(niveau!),
                            style: AppFonts.display(
                              size: 15,
                              weight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          // Le cran DANS le palier : c'est lui qui remplace la
                          // note disparue, sans chiffre et sans vocabulaire de
                          // manque. Il nuance le niveau, il ne le remplace
                          // pas — d'ou la discretion.
                          if (situation != null) ...[
                            const SizedBox(height: 6),
                            _SituationChip(situation: situation),
                          ],
                        ],
                      ),
                    ),
                    if (niveau != null) ...[
                      const SizedBox(width: 10),
                      _LevelPill(niveau: niveau!),
                    ],
                  ],
                ),
                if (niveau != null) ...[
                  const SizedBox(height: 11),
                  _PaliersBar(niveau: niveau!),
                ],
                if (showConfiance) ...[
                  const SizedBox(height: 12),
                  _ConfianceBlock(
                    confiance: confiance,
                    raisons: evaluation.feedback.confianceRaisons,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le cran de progression **dans** le palier, en pastille translucide sous le
/// niveau. Aucun chiffre : c'est tout l'objet du champ.
///
/// Elle porte la forme **composée** (« A2 solide »), celle que
/// `docs/notation-ia-eo-ee.md` §6.3 bis annonce au candidat — et jamais
/// « presque B1 », qui réintroduirait le vocabulaire de manque qu'on vient de
/// retirer avec la note.
class _SituationChip extends StatelessWidget {
  const _SituationChip({required this.situation});

  final SituationView situation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.26)),
      ),
      child: Text(
        situation.libelleAvecNiveau,
        style: AppFonts.ui(
          size: 11.5,
          weight: FontWeight.w700,
          color: AppColors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

/// Pastille `.pill.light` : fond blanc, **texte à la teinte du palier**
/// ([CecrlColor]). C'est elle qui porte la couleur du niveau, puisque la barre
/// des paliers passe en blanc sur le dégradé.
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.niveau});

  final NiveauCecrl niveau;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        niveau.shortName,
        style: AppFonts.display(
          size: 14,
          weight: FontWeight.w800,
          color: niveau.color,
        ),
      ),
    );
  }
}

/// Les cinq paliers du TCF **sur le dégradé**, celui du candidat mis en avant.
///
/// C'était l'échelle des notes, curseur compris ; elle situe désormais un
/// **palier**, la seule chose que le résultat d'une tâche annonce. Les paliers
/// sont dessinés à largeur égale : ce qu'on montre, c'est la suite des paliers,
/// pas un axe métrique.
class _PaliersBar extends StatelessWidget {
  const _PaliersBar({required this.niveau});

  final NiveauCecrl niveau;

  static const double _gap = 4;
  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final activeIndex = niveau.tcfPalierIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < kTcfPaliers.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.white
                        .withValues(alpha: i == activeIndex ? 1 : 0.18),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < kTcfPaliers.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(
                child: Text(
                  kTcfPaliers[i].shortName,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 9.5,
                    weight:
                        i == activeIndex ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.white
                        .withValues(alpha: i == activeIndex ? 1 : 0.55),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Le rappel d'enjeu : un A2 qui vise la carte de séjour pluriannuelle EST au
/// niveau demandé, et personne ne le lui disait. Filet vertical côté gauche,
/// jamais rouge — un objectif encore devant n'est pas une faute.
class _StakeBlock extends StatelessWidget {
  const _StakeBlock({required this.rappel});

  final DemarcheRappel rappel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.white
            .withValues(alpha: rappel.atteint ? 0.17 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border(
          left: BorderSide(
            color: AppColors.white
                .withValues(alpha: rappel.atteint ? 1 : 0.55),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOTRE DÉMARCHE',
            style: AppFonts.label(
              size: 10,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rappel.text,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// La confiance dit ce que l'évaluation SAIT, pas ce que vaut la production.
/// Elle n'apparaît que lorsqu'elle n'est pas haute — sinon c'est du bruit.
class _ConfianceBlock extends StatelessWidget {
  const _ConfianceBlock({required this.confiance, required this.raisons});

  final ConfianceEvaluation confiance;
  final List<String> raisons;

  @override
  Widget build(BuildContext context) {
    final label = confiance.displayName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${label[0].toUpperCase()}${label.substring(1)}',
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          for (final raison
              in raisons.isEmpty ? const [kConfianceSansRaison] : raisons) ...[
            const SizedBox(height: 5),
            Text(
              raison,
              style: AppFonts.ui(
                size: 12,
                color: AppColors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
