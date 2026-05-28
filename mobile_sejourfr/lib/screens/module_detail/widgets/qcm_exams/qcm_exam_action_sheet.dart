import 'package:flutter/material.dart';

import '../../../../core/models/attempt_summary.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';

/// Bottom sheet affichée au tap sur un slot d'examen QCM déjà terminé :
/// résumé du score + 2 actions (Voir les détails / Reprendre).
class QcmExamActionSheet extends StatelessWidget {
  const QcmExamActionSheet({
    super.key,
    required this.attempt,
    required this.onViewDetails,
    required this.onRetake,
  });

  final AttemptSummary attempt;
  final VoidCallback onViewDetails;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Examen passé',
                style: AppFonts.fraunces(size: 22, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Score : ${attempt.weightedScore ?? 0}/${attempt.maxWeightedScore ?? 50} · ${attempt.score ?? 0}/${attempt.totalQuestions} bonnes réponses',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Voir les détails',
                icon: Icons.visibility_outlined,
                onPressed: onViewDetails,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Reprendre (questions différentes)',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: onRetake,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
