import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/rich_paragraph_text.dart';

class DiagnosticProgress extends StatelessWidget {
  const DiagnosticProgress({
    super.key,
    required this.activeStep,
    required this.completedSteps,
  });

  final int activeStep;
  final int completedSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape $activeStep sur 2, $completedSteps exercice terminé',
      child: Row(
        children: [
          for (var index = 1; index <= 2; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                decoration: BoxDecoration(
                  color: index <= completedSteps || index == activeStep
                      ? AppColors.blue
                      : AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            if (index != 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class DiagnosticExerciseCard extends StatelessWidget {
  const DiagnosticExerciseCard({super.key, required this.exercise});

  final DiagnosticExerciseView exercise;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadii.xl,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  exercise.epreuve.isAudio
                      ? LucideIcons.mic
                      : LucideIcons.penLine,
                  size: 21,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.epreuve.isAudio
                          ? 'DIAGNOSTIC ORAL'
                          : 'DIAGNOSTIC ÉCRIT',
                      style: AppFonts.label(color: AppColors.blue),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.title,
                      style: AppFonts.display(size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          RichParagraphText(exercise.instruction),
          if (exercise.helperText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 17,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      exercise.helperText,
                      style: AppFonts.ui(
                        size: 12.5,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DiagnosticErrorBanner extends StatelessWidget {
  const DiagnosticErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              size: 18,
              color: AppColors.red,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.redDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
