import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'accomplishment_card.dart';
import 'avertissements_card.dart';
import 'correction_example.dart';
import 'criterion_row.dart';
import 'feedback_block.dart';
import 'improved_version_card.dart';
import 'objective_card.dart';
import 'priority_card.dart';
import 'production_score_hero.dart';

/// Limite de l'evaluation orale, mot pour mot (cf. `docs/notation-ia-eo-ee.md`
/// §9). Le correcteur la renvoie normalement dans ses `avertissements` ; ce
/// texte est le REPLI quand la liste arrive vide sur une tache orale — le
/// candidat doit savoir dans tous les cas que sa voix n'a pas ete ecoutee.
const String kOralEvaluationLimitNotice =
    'Cette évaluation est fondée sur la transcription écrite de votre '
    'production : nous n\'analysons pas votre voix. L\'aisance, la fluidité, '
    'le débit et la prononciation ne sont donc pas évalués ici — c\'est une '
    'limite technique de notre correction, pas un choix pédagogique. '
    'À l\'examen officiel, ces dimensions comptent.';

/// Corps commun des ecrans de resultats EE et EO : meme correction, meme ordre,
/// un seul endroit a faire evoluer.
///
/// L'ecran repond a trois questions, dans cet ordre, et range le reste :
/// 1. **ai-je fait ce qu'on me demandait ?** — le verdict d'objectif, avant
///    tout le reste ;
/// 2. **combien, et ca vaut quoi ?** — la note AVEC l'echelle du TCF, dans un
///    seul bloc : notre note EST celle du TCF, 4,5/20 vaut A2 ;
/// 3. **que faire maintenant ?** — deux points forts, deux priorites, puis la
///    version amelioree quand elle existe (ecrit uniquement).
///
/// Tout le reste — avertissements, detail par critere, check-list de la
/// consigne, exemples corriges, suggestions — vit dans « Voir l'analyse
/// complete », **replie par defaut**. Rien n'est perdu : c'est range.
///
/// Chaque bloc est optionnel : une evaluation ancienne n'expose ni objectif, ni
/// niveau, ni accomplissement — les blocs concernes disparaissent et l'ecran
/// reste coherent.
class EvaluationReport extends StatelessWidget {
  const EvaluationReport({
    super.key,
    required this.evaluation,
    required this.isOral,
  });

  final EvaluationResult evaluation;

  /// Tache orale : la limite de l'evaluation orale s'applique, les exemples
  /// sont des reformulations et non des corrections d'ecriture, et aucune
  /// version amelioree n'est attendue.
  final bool isOral;

  String get _correctionsTitle =>
      isOral ? 'Reformulations pour plus de clarté' : 'Corrections';

  /// Une tache orale porte toujours la limite de l'oral, meme si le correcteur
  /// a rendu une liste vide.
  List<String> get _avertissements {
    final fromAi = evaluation.feedback.avertissements;
    if (fromAi.isNotEmpty) return fromAi;
    return isOral ? const [kOralEvaluationLimitNotice] : const [];
  }

  @override
  Widget build(BuildContext context) {
    final feedback = evaluation.feedback;
    final priorites = feedback.pointsAAmeliorer;
    final accomplissement = feedback.accomplissement;
    final avertissements = _avertissements;

    final analyse = <Widget>[
      if (avertissements.isNotEmpty)
        AvertissementsCard(avertissements: avertissements),
      if (feedback.scoresCriteres.isNotEmpty)
        _CriteresCard(criteres: feedback.scoresCriteres),
      if (accomplissement != null && !accomplissement.isEmpty)
        AccomplishmentCard(accomplissement: accomplissement),
      if (feedback.exemplesCorriges.isNotEmpty)
        _CorrectionsCard(
          examples: feedback.exemplesCorriges,
          title: _correctionsTitle,
        ),
      if (feedback.suggestions.isNotEmpty)
        FeedbackBlock(
          kind: FeedbackKind.suggest,
          title: 'Suggestions',
          items: feedback.suggestions,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObjectiveCard(accomplissement: accomplissement),
        ProductionScoreHero(evaluation: evaluation),
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
        ImprovedVersionCard(texte: feedback.versionAmelioree),
        if (analyse.isNotEmpty) _FullAnalysis(children: analyse),
      ],
    );
  }
}

/// Le detail exhaustif, **replie par defaut** : un rapport de correction n'est
/// pas une expertise a lire d'un bout a l'autre. Ce qui est deplie sur demande
/// n'est pas perdu, il est range.
class _FullAnalysis extends StatefulWidget {
  const _FullAnalysis({required this.children});

  final List<Widget> children;

  @override
  State<_FullAnalysis> createState() => _FullAnalysisState();
}

class _FullAnalysisState extends State<_FullAnalysis> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.listChecks,
                    size: 18,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Voir l'analyse complète",
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 14),
          ...widget.children,
        ],
      ],
    );
  }
}

/// Carte « Détail par critère » : une bande qualitative par critere, plus une
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
            'Détail par critère',
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
