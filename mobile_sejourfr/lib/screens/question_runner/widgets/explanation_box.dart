import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';

/// Bloc qui apparaît après la soumission d'une réponse en entraînement.
class ExplanationBox extends StatelessWidget {
  const ExplanationBox({
    super.key,
    required this.correct,
    required this.explanation,
  });

  final bool correct;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: correct
            ? AppColors.green.withValues(alpha: 0.35)
            : AppColors.red.withValues(alpha: 0.35),
      ),
      color: correct
          ? AppColors.green.withValues(alpha: 0.05)
          : AppColors.redLight,
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? AppColors.green : AppColors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Bonne réponse' : 'Mauvaise réponse',
                style: AppFonts.jakarta(
                  size: 14,
                  weight: FontWeight.w800,
                  color: correct ? AppColors.green : AppColors.red,
                ),
              ),
              const Spacer(),
              AppTag(
                label: 'Explication',
                tone: correct ? TagTone.success : TagTone.red,
              ),
            ],
          ),
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              explanation!,
              style: AppFonts.jakarta(
                size: 13.5,
                color: AppColors.ink2,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
