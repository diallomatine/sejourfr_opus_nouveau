import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
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
    required this.hasOral,
    this.errorMessage,
    this.submitLabel = 'Valider mon écrit',
    this.onCancelEdit,
    this.editNote,
  });

  final DiagnosticExerciseView exercise;
  final TextEditingController controller;
  final int wordCount;
  final bool isSubmitting;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  /// La forme servie comporte-t-elle un oral ? Décide du nombre d'étapes
  /// affichées — jamais « 1 sur 2 » sur un diagnostic à un seul exercice.
  final bool hasOral;
  final String? errorMessage;
  final String submitLabel;

  /// Présent quand l'écrit a été rouvert depuis l'écran de compte : le lien
  /// « ← Revenir sans modifier » ramène au compte sans toucher à la
  /// production enregistrée.
  final VoidCallback? onCancelEdit;

  /// Ce qui reste conservé pendant la modification.
  final String? editNote;

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
              if (onCancelEdit != null) ...[
                DiagnosticBackLink(
                  label: kDiagnosticEditCancel,
                  onTap: onCancelEdit!,
                ),
                const SizedBox(height: 8),
              ],
              DiagnosticProgress(
                activeStep: 1,
                completedSteps: 0,
                totalSteps: diagnosticExpressionSteps(hasOral: hasOral),
              ),
              const SizedBox(height: 14),
              if (editNote != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    editNote!,
                    style: AppFonts.ui(
                      size: 13.5,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
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
            label: submitLabel,
            iconRight: LucideIcons.arrowRight,
            isLoading: isSubmitting,
            onPressed: valid && !isSubmitting ? onSubmit : null,
          ),
        ),
      ],
    );
  }
}
