import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../../tcf_production/widgets/writing_zone.dart';
import 'diagnostic_common.dart';

class DiagnosticWrittenStep extends StatelessWidget {
  const DiagnosticWrittenStep({
    super.key,
    required this.exercise,
    required this.controller,
    required this.wordCount,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmit,
    this.errorMessage,
  });

  final DiagnosticExercise exercise;
  final TextEditingController controller;
  final int wordCount;
  final bool isSubmitting;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final minimum = exercise.wordsMin ?? 100;
    final maximum = exercise.wordsMax ?? 130;
    final valid = wordCount >= minimum && wordCount <= maximum;
    return Column(
      children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const DiagnosticProgress(activeStep: 1, completedSteps: 0),
              const SizedBox(height: 14),
              DiagnosticExerciseCard(exercise: exercise),
              const SizedBox(height: 18),
              WritingZone(
                controller: controller,
                wordCount: wordCount,
                minWords: minimum,
                maxWords: maximum,
                minLines: 12,
                title: 'Votre diagnostic écrit',
                hint: 'Rédigez votre réponse ici…',
                onChanged: onChanged,
                onClear: controller.text.isEmpty
                    ? null
                    : () {
                        controller.clear();
                        onChanged('');
                      },
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                DiagnosticErrorBanner(message: errorMessage!),
              ],
            ],
          ),
        ),
        FixedActionBar(
          child: AppButton(
            label: 'Valider mon écrit',
            iconRight: LucideIcons.arrowRight,
            isLoading: isSubmitting,
            onPressed: valid && !isSubmitting ? onSubmit : null,
          ),
        ),
      ],
    );
  }
}
