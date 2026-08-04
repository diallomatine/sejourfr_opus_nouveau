import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'accomplishment_card.dart';
import 'avertissements_card.dart';
import 'correction_example.dart';
import 'criterion_row.dart';
import 'donut_chart_score.dart';
import 'feedback_block.dart';
import 'niveau_observe_card.dart';
import 'priority_card.dart';

/// Corps commun des ecrans de resultats EE et EO : meme correction, meme ordre,
/// un seul endroit a faire evoluer.
///
/// Ordre voulu :
/// 1. niveau observe sur la tache (avec sa confiance, jamais sans) — c'est
///    l'information que le candidat cherche, elle passe AVANT la note et avant
///    toute precaution ;
/// 2. note /20, sur l'echelle du TCF ;
/// 3. avertissements — dont la limite de l'evaluation orale, visible et non
///    enterree en bas d'ecran ;
/// 4. accomplissement de la consigne, AVANT la langue : le candidat voit
///    d'abord s'il a oublie un point demande ;
/// 5. detail par critere en bandes qualitatives ;
/// 6. points forts, puis priorites (2 max), corrections, suggestion.
///
/// Tout est optionnel : une evaluation ancienne n'expose ni niveau, ni
/// accomplissement, ni bandes — les blocs concernes disparaissent et l'ecran
/// reste celui d'avant.
class EvaluationReport extends StatelessWidget {
  const EvaluationReport({
    super.key,
    required this.evaluation,
    this.correctionsTitle = 'Exemples et corrections',
  });

  final EvaluationResult evaluation;

  /// Titre du bloc d'exemples corriges : l'oral parle de reformulations, pas
  /// de corrections d'ecriture.
  final String correctionsTitle;

  @override
  Widget build(BuildContext context) {
    final feedback = evaluation.feedback;
    final priorites = feedback.pointsAAmeliorer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NiveauObserveCard(evaluation: evaluation),
        DonutChartScore(noteSur20: evaluation.noteSurVingt),
        AvertissementsCard(avertissements: feedback.avertissements),
        AccomplishmentCard(accomplissement: feedback.accomplissement),
        if (feedback.scoresCriteres.isNotEmpty)
          _CriteresCard(criteres: feedback.scoresCriteres),
        if (feedback.pointsForts.isNotEmpty)
          FeedbackBlock(
            kind: FeedbackKind.positive,
            title: 'Points forts',
            items: feedback.pointsForts,
          ),
        if (priorites.isNotEmpty)
          FeedbackBlock.rich(
            kind: FeedbackKind.improve,
            title: priorites.length > 1 ? 'Vos priorités' : 'Votre priorité',
            subtitle: 'À travailler en premier lors de votre prochaine '
                'production — pas la peine de tout corriger d\'un coup.',
            blocks: [
              for (final (index, priorite) in priorites.indexed)
                PriorityCard(priorite: priorite, rang: index + 1),
            ],
          ),
        if (feedback.exemplesCorriges.isNotEmpty)
          _CorrectionsCard(
            examples: feedback.exemplesCorriges,
            title: correctionsTitle,
          ),
        if (feedback.suggestions.isNotEmpty)
          FeedbackBlock(
            kind: FeedbackKind.suggest,
            title: 'Suggestion globale',
            items: feedback.suggestions,
          ),
      ],
    );
  }
}

/// Carte « Détail par critères » : une bande qualitative par critere, plus une
/// note chiffree (cf. [CriterionRow]).
class _CriteresCard extends StatelessWidget {
  const _CriteresCard({required this.criteres});

  final List<CriterionScore> criteres;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détail par critères',
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...criteres.map((c) => CriterionRow(criterion: c)),
        ],
      ),
    );
  }
}

class _CorrectionsCard extends StatelessWidget {
  const _CorrectionsCard({required this.examples, required this.title});

  final List<CorrectionExample> examples;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, size: 18, color: AppColors.amber),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.ui(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...examples.map((e) => CorrectionExampleCard(example: e)),
        ],
      ),
    );
  }
}
