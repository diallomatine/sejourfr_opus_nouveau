import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Barre de progression du parcours d'examens blancs : `doneCount / total`.
/// Fond `blueLight`, barre `blue`. Partagée entre les pages QCM et EE/EO.
class ExamProgressCard extends StatelessWidget {
  const ExamProgressCard({
    super.key,
    required this.doneCount,
    required this.total,
  });

  final int doneCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : doneCount / total;
    final percent = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progression du parcours',
                style: AppFonts.jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const Spacer(),
              Text(
                '$percent %',
                style: AppFonts.jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.blue.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
