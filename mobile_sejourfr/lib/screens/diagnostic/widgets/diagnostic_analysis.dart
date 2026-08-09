import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'diagnostic_common.dart';

class DiagnosticAnalysisView extends StatelessWidget {
  const DiagnosticAnalysisView({
    super.key,
    required this.journey,
    required this.isBusy,
    required this.onRefresh,
    required this.onRetry,
    this.errorMessage,
  });

  final DiagnosticJourney journey;
  final bool isBusy;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final failed = journey.status == DiagnosticJourneyStatus.failed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        const DiagnosticProgress(activeStep: 2, completedSteps: 2),
        const SizedBox(height: 28),
        AppCard(
          borderRadius: AppRadii.xl,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: failed ? AppColors.redLight : AppColors.blueLight,
                  shape: BoxShape.circle,
                ),
                child: failed
                    ? const Icon(
                        LucideIcons.triangleAlert,
                        size: 30,
                        color: AppColors.red,
                      )
                    : const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.blue,
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              Text(
                failed
                    ? 'L’analyse n’a pas abouti'
                    : 'Nous préparons votre plan',
                textAlign: TextAlign.center,
                style: AppFonts.display(size: 23),
              ),
              const SizedBox(height: 8),
              Text(
                failed
                    ? (journey.errorMessage ??
                        'Vos productions sont conservées. Vous pouvez relancer l’analyse sans les refaire.')
                    : 'Vos deux productions sont analysées séparément, puis réunies en trois priorités maximum.',
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              if (failed && journey.canRetry)
                AppButton(
                  label: 'Relancer l’analyse',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onRetry,
                )
              else if (!failed)
                AppButton(
                  label: 'Actualiser',
                  variant: AppButtonVariant.soft,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onRefresh,
                ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          DiagnosticErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: 16),
        Text(
          'Vous pouvez quitter cet écran : la reprise se fera automatiquement depuis le serveur.',
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 12, color: AppColors.inkFaint, height: 1.4),
        ),
      ],
    );
  }
}
