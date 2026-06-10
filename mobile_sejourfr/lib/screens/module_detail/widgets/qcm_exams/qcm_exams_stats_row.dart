import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../tcf_production/widgets/exam_stat_card.dart';

/// Rangée de 3 stats au-dessus de la liste des examens QCM : Terminés (count
/// /total) · Score moyen · Meilleur score. Scores en /maxPossible (typiquement
/// 50 pour les examens module TCF, exposé en paramètre pour rester souple).
class QcmExamsStatsRow extends StatelessWidget {
  const QcmExamsStatsRow({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.bestScore,
    required this.avgScore,
    required this.maxPossible,
  });

  final int doneCount;
  final int totalCount;
  final int? bestScore;
  final int? avgScore;
  final int maxPossible;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ExamStatCard(
            icon: LucideIcons.listChecks,
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
            icon: LucideIcons.target,
            iconColor: AppColors.green,
            value: avgScore == null ? '—' : '$avgScore',
            suffix: avgScore == null ? '' : '/$maxPossible',
            valueColor: AppColors.green,
            label: 'Score moyen',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ExamStatCard(
            icon: LucideIcons.flame,
            iconColor: AppColors.amber,
            value: bestScore == null ? '—' : '$bestScore',
            suffix: bestScore == null ? '' : '/$maxPossible',
            valueColor: AppColors.ink,
            label: 'Meilleur score',
          ),
        ),
      ],
    );
  }
}
