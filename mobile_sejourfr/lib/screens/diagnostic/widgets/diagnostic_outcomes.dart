import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../diagnostic_civique/civic_diagnostic_labels.dart';
import '../diagnostic_rapport_labels.dart';

/// Ce qu'un diagnostic rend au candidat — déclaré une fois.
///
/// Lu par l'écran de choix du visiteur (`DiagnosticChoice`) et par les deux
/// écrans de compte des diagnostics (TCF et civique). Miroir mot pour mot de
/// `web_sejoufr/app/_components/diagnostic/diagnostic-outcomes.ts` et des
/// panneaux `TCF_DIAGNOSTIC_PANEL` / `CIVIC_DIAGNOSTIC_PANEL`
/// (`web_sejoufr/app/_components/auth/auth-panels.ts`).
///
/// 🛑 Rien d'autre qu'un constat vrai : pas de chiffre, pas de durée, pas de
/// résultat inventé.
class DiagnosticOutcome {
  const DiagnosticOutcome(this.title, this.text);

  final String title;
  final String text;
}

const kDiagnosticOutcomeLevel =
    DiagnosticOutcome('Votre niveau', 'Une estimation simple à comprendre');
const kDiagnosticOutcomePriorities =
    DiagnosticOutcome('Vos priorités', 'Ce qu’il faut travailler en premier');
const kDiagnosticOutcomePlan =
    DiagnosticOutcome('Votre plan', 'Un parcours adapté à votre résultat');

const List<DiagnosticOutcome> kDiagnosticOutcomes = [
  kDiagnosticOutcomeLevel,
  kDiagnosticOutcomePriorities,
  kDiagnosticOutcomePlan,
];

const String kDiagnosticDisclaimer =
    'Estimation d’entraînement, non officielle.';

/// Écran de compte du diagnostic TCF : ce que l'analyse rendra. Le niveau
/// porte l'intitulé EXACT du rapport — jamais « votre niveau TCF ».
const String kTcfDiagnosticGatePanelTitle = 'Ce que l’analyse vous rendra';
final List<DiagnosticOutcome> kTcfDiagnosticGateOutcomes = [
  DiagnosticOutcome(kDiagnosticLevelEyebrow, kDiagnosticOutcomeLevel.text),
  kDiagnosticOutcomePriorities,
  kDiagnosticOutcomePlan,
];

/// Écran de compte du diagnostic civique : les blocs du résultat, sous leurs
/// intitulés. 🛑 Aucun score : c'est ce qu'on échange contre le compte.
const String kCivicDiagnosticGatePanelTitle =
    'Ce que votre résultat vous montrera';
final List<DiagnosticOutcome> kCivicDiagnosticGateOutcomes = [
  const DiagnosticOutcome(
      kCivicScoreLabel, 'Comparées au seuil de réussite de l’examen'),
  const DiagnosticOutcome(kCivicThemesTitle,
      'Où vous en êtes sur chacun des $kCivicThemesCount thèmes du livret'),
  DiagnosticOutcome(kCivicPrioritesTitle, kDiagnosticOutcomePriorities.text),
  kDiagnosticOutcomePlan,
];

/// La carte des résultats promis : une ligne par élément, titre à gauche,
/// explication à droite.
class DiagnosticOutcomesCard extends StatelessWidget {
  const DiagnosticOutcomesCard({super.key, required this.items});

  final List<DiagnosticOutcome> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _OutcomeRow(outcome: items[i], last: i == items.length - 1),
        ],
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.outcome, required this.last});

  final DiagnosticOutcome outcome;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              outcome.title,
              style: AppFonts.ui(size: 13, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              outcome.text,
              textAlign: TextAlign.right,
              style: AppFonts.ui(
                size: 12,
                color: AppColors.inkSoft,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
