import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/app_sheet.dart';
import 'tcf_note_scale.dart';

/// Règle de lecture de la note. Elle vit derrière la pastille d'information du
/// panneau de niveau, et non à plat sous l'échelle : l'échelle DESSINE déjà la
/// règle, ce texte l'explique. Trois lignes de prose entre la note et le premier
/// conseil, c'est exactement la verbosité que cette refonte corrige.
const String kNotePorteeSurLaTache =
    'Cette note est une estimation, exprimée sur l\'échelle du TCF : c\'est elle '
    'qui donne le niveau. Elle porte ici sur cette seule tâche — au TCF, la note '
    'sur 20 est celle de l\'épreuve entière, vos trois tâches.';

/// Repli quand le correcteur signale une confiance basse sans dire pourquoi :
/// une pastille seule laisse le candidat sans explication.
const String kConfianceSansRaison =
    'Une partie de votre production était difficile à analyser : cette note est '
    'à prendre avec prudence.';

/// En-tête du rapport : **le verdict, la note et le niveau dans UN SEUL bloc**,
/// calqué sur le `.hero` de la maquette « Rapport express » — dégradé de marque,
/// halo clair en haut à droite, note à droite, et panneau de niveau
/// **translucide** posé dessus.
///
/// Avant, c'étaient trois cartes empilées (bandeau « Évaluation terminée »,
/// carte objectif, carte note) qui disaient chacune une moitié de la même chose,
/// et remplissaient un écran entier avant le premier conseil. Le candidat doit
/// pouvoir répondre à « c'est bien ou pas ? » sans défiler.
///
/// Ce qui n'a pas bougé, parce que ce sont des règles et non de la mise en page :
/// - la note s'affiche AVEC l'échelle du TCF : séparée, elle se lit comme une
///   note scolaire française, et « 4,5/20 » y passe pour une catastrophe alors
///   que c'est un A2 ;
/// - jamais de niveau sans sa confiance ([EvaluationResult.hasNiveauObserve]) ;
/// - la confiance ne s'affiche QUE lorsqu'elle n'est pas haute ;
/// - notre niveau est une **estimation** : « proche du niveau B1 », jamais
///   « B1 » sec ;
/// - la portée de la note ([kNotePorteeSurLaTache], ou l'`avertissementNiveau`
///   du backend qui la **remplace**) reste accessible en un geste.
class ProductionResultsHero extends StatelessWidget {
  const ProductionResultsHero({
    super.key,
    required this.evaluation,
    this.eyebrow,
  });

  final EvaluationResult evaluation;

  /// Situe la correction (« Expression écrite · Tâche 1 »). Absent depuis un
  /// contexte qui ne connaît pas la tâche : le hero se rend sans, sans trou.
  final String? eyebrow;

  /// « Objectif atteint » plutôt que « Atteint » seul : sur un hero, le mot doit
  /// se suffire à lui-même. Aucune pastille d'icône ne le précède — la maquette
  /// n'en a pas, et le verdict est déjà écrit en toutes lettres.
  static String objectifTitle(ObjectifAccomplissement o) =>
      'Objectif ${o.displayName.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final objectif = evaluation.feedback.accomplissement?.objectif;
    final resume = evaluation.feedback.accomplissement?.objectifResume;

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (eyebrow != null) ...[
                                Text(
                                  eyebrow!.toUpperCase(),
                                  style: AppFonts.label(
                                    size: 11,
                                    color: AppColors.white
                                        .withValues(alpha: 0.75),
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        _Score(note: evaluation.noteSurVingt),
                      ],
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
                    _LevelPanel(evaluation: evaluation),
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

class _Score extends StatelessWidget {
  const _Score({required this.note});

  final double? note;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: note == null ? '—' : formatScore(note!),
            style: AppFonts.display(
              size: 40,
              weight: FontWeight.w700,
              color: AppColors.white,
            ).copyWith(height: 1),
          ),
          TextSpan(
            text: '/20',
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panneau `.level` de la maquette : **translucide**, posé sur le dégradé.
/// Niveau estimé à gauche, pastille à droite, échelle du TCF dessous.
///
/// Le panneau entier est tactile et ouvre la règle de lecture — la pastille
/// d'information à côté du sur-titre en est le repère visible. Une ligne
/// « Comment lire cette note ? » écrite en toutes lettres coûtait une ligne de
/// plus dans le bloc que cette refonte est censée alléger.
class _LevelPanel extends StatelessWidget {
  const _LevelPanel({required this.evaluation});

  final EvaluationResult evaluation;

  static const readingRuleTooltip = 'Comment lire cette note';

  /// « Proche du niveau B1 », pas « B1 ». Sauf pour le plancher, où « proche
  /// de » n'a aucun sens : on n'est pas proche d'un niveau non atteint.
  static String levelLabel(NiveauCecrl niveau) =>
      niveau == NiveauCecrl.a1NonAtteint
          ? 'Niveau A1 non atteint'
          : 'Proche du niveau ${niveau.displayName}';

  void _openReadingRule(BuildContext context) {
    showAppSheet<void>(
      context,
      icon: LucideIcons.info,
      title: readingRuleTooltip,
      children: [
        Text(
          evaluation.avertissementNiveau ?? kNotePorteeSurLaTache,
          style: AppFonts.ui(size: 13.5, color: AppColors.ink, height: 1.55),
        ),
        const SizedBox(height: 16),
        const _ReadingTable(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final niveau = evaluation.hasNiveauObserve ? evaluation.niveauObserve : null;
    final confiance = evaluation.confiance;
    final showConfiance =
        confiance != null && confiance != ConfianceEvaluation.haute;

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
                                  niveau == null
                                      ? 'NOTE SUR L\'ÉCHELLE DU TCF'
                                      : 'NIVEAU ESTIMÉ',
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
                          if (niveau != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              levelLabel(niveau),
                              style: AppFonts.display(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (niveau != null) ...[
                      const SizedBox(width: 10),
                      _LevelPill(niveau: niveau),
                    ],
                  ],
                ),
                const SizedBox(height: 11),
                TcfNoteScale.onDark(note: evaluation.noteSurVingt),
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

/// Pastille `.pill.light` : fond blanc, **texte à la teinte du palier**
/// ([CecrlColor]). C'est elle qui porte la couleur du niveau, puisque l'échelle
/// passe en blanc sur le dégradé.
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

/// Les cinq paliers officiels et leurs bornes, dans la feuille de règle de
/// lecture : c'est là que vit le tableau, pas dans le hero.
class _ReadingTable extends StatelessWidget {
  const _ReadingTable();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final band in kTcfNoteBands)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: band.tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    band.rangeLabel,
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w800,
                      color: band.tone,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    band.label,
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
