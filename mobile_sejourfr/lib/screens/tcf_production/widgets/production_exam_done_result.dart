import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../expression_hub_data.dart';

/// Widget compact rendu à droite du pill « difficulté » dans un slot
/// d'examen blanc EE/EO terminé : check vert + (Niveau · Score/20). Ré-utilise
/// [ExamSession.niveauPlancher] et `avgScore` exposés par
/// `expression_hub_data.dart`.
class ProductionExamDoneResult extends StatelessWidget {
  const ProductionExamDoneResult({super.key, required this.exam});

  final ExamSession exam;

  @override
  Widget build(BuildContext context) {
    final niveau = exam.niveauPlancher;
    final score = exam.avgScore;
    final parts = <String>[
      if (niveau != null) niveau.displayName,
      if (score != null) '${formatScore(score)}/20',
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 13, color: AppColors.green),
        const SizedBox(width: 3),
        Text(
          parts.isEmpty ? 'Terminé' : parts.join(' · '),
          style: AppFonts.jakarta(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.green,
          ),
        ),
      ],
    );
  }
}
