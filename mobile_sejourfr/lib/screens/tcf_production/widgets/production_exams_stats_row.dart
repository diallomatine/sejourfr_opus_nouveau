import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import 'exam_stat_card.dart';

/// Rangée de 3 stats au-dessus de la liste des examens blancs EE/EO :
/// Terminés (count/total) · Score moyen (sur 20) · Niveau estimé (CECRL).
/// Le niveau estimé est calculé côté écran (meilleur niveau plancher des
/// sessions évaluées).
class ProductionExamsStatsRow extends StatelessWidget {
  const ProductionExamsStatsRow({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.avgScore,
    required this.niveau,
  });

  final int doneCount;
  final int totalCount;
  final double? avgScore;
  final NiveauCecrl? niveau;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ExamStatCard(
            icon: Icons.checklist_rounded,
            iconColor: AppColors.blue,
            value: '$doneCount',
            suffix: '/$totalCount',
            valueColor: AppColors.ink,
            label: 'Terminés',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ExamStatCard(
            icon: Icons.adjust_rounded,
            iconColor: AppColors.green,
            value: avgScore == null ? '—' : avgScore!.round().toString(),
            suffix: avgScore == null ? '' : '/20',
            valueColor: AppColors.green,
            label: 'Score moyen',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ExamStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.red,
            value: niveau?.displayName ?? '—',
            suffix: '',
            valueColor: AppColors.ink,
            label: 'Niveau estimé',
          ),
        ),
      ],
    );
  }
}
