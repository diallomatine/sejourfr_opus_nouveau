import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../expression_hub_data.dart';

/// Widget compact rendu à droite du pill « difficulté » dans un slot
/// d'examen blanc EE/EO terminé : check vert + Score/20 (moyenne). Le niveau
/// CECRL n'apparaît plus ici — il est réservé au bilan d'épreuve. Ré-utilise
/// `avgScore` exposé par `expression_hub_data.dart`.
class ProductionExamDoneResult extends StatelessWidget {
  const ProductionExamDoneResult({super.key, required this.exam});

  final ExamSession exam;

  @override
  Widget build(BuildContext context) {
    final score = exam.avgScore;
    final parts = <String>[
      if (score != null) '${formatScore(score)}/20',
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.circleCheck,
            size: 13, color: AppColors.green),
        const SizedBox(width: 3),
        Text(
          parts.isEmpty ? 'Terminé' : parts.join(' · '),
          style: AppFonts.ui(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.green,
          ),
        ),
      ],
    );
  }
}
