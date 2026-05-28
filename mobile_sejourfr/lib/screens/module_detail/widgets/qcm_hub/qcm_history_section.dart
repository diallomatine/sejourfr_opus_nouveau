import 'package:flutter/material.dart';

import '../../../../core/models/attempt_summary.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_date.dart';

/// Section « Historique » du hub TCF QCM : top 3 examens terminés + lien
/// « Tout voir » vers la page Examens. Empty state si aucun examen passé.
class QcmHistorySection extends StatelessWidget {
  const QcmHistorySection({
    super.key,
    required this.history,
    required this.onSeeAll,
    required this.onTap,
  });

  final List<AttemptSummary> history;
  final VoidCallback onSeeAll;
  final ValueChanged<AttemptSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final finished = history.where((a) => a.isFinished).toList();
    if (finished.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            'Aucun examen passé. Lance un examen blanc ou entraîne-toi par niveau.',
            style: AppFonts.jakarta(
              size: 12.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final recent = finished.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Row(
            children: [
              Text(
                'Historique',
                style: AppFonts.jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Tout voir',
                  style: AppFonts.jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final attempt in recent)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _HistoryRow(
              attempt: attempt,
              onTap: () => onTap(attempt),
            ),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.attempt, required this.onTap});

  final AttemptSummary attempt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = attempt.weightedScore;
    final maxScore = attempt.maxWeightedScore;
    final scoreColor = _scoreColor(score, maxScore);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 18,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Examen complet',
                        style: AppFonts.jakarta(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        formatLongDate(attempt.finishedAt ?? attempt.startedAt),
                        style: AppFonts.jakarta(
                          size: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (score != null && maxScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score/$maxScore',
                      style: AppFonts.jakarta(
                        size: 11,
                        weight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted2,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int? score, int? max) {
    if (score == null || max == null || max == 0) return AppColors.muted;
    final pct = score / max * 100;
    if (pct >= 70) return AppColors.green;
    if (pct >= 40) return AppColors.amber;
    return AppColors.red;
  }
}
