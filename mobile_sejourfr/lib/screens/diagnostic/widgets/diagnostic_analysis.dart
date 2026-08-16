import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'diagnostic_common.dart';
import 'diagnostic_wait.dart';

/// Au-delà de ce délai, l'attente est annoncée comme inhabituelle. Ce n'est
/// **pas** un échec : l'échec, c'est `FAILED`, qui a son propre écran.
const _kAnalyseHabituelle = Duration(minutes: 2);

/// Textes de l'écran d'échec d'analyse. Miroir mot pour mot du web
/// (`DiagnosticView.tsx`) : ces chaînes ne transitent pas par le réseau, chaque
/// front en tient sa copie.
const kAnalysisFailedTitle = 'L’analyse n’a pas pu aboutir';
const kAnalysisFailedText =
    'Vos deux réponses sont conservées. Vous n’avez rien à refaire.';
const kAnalysisRetryExhausted =
    'Le nombre de relances automatiques est épuisé. Vos deux productions '
    'restent enregistrées : vous n’avez rien à refaire. L’analyse a échoué de '
    'notre côté, et votre plan reste accessible en attendant.';

class DiagnosticAnalysisView extends StatelessWidget {
  const DiagnosticAnalysisView({
    super.key,
    required this.journey,
    required this.isBusy,
    required this.onRefresh,
    required this.onRetry,
    required this.onOpenPlan,
    this.errorMessage,
  });

  final DiagnosticJourney journey;
  final bool isBusy;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onOpenPlan;

  /// Échec de l'action qu'on vient de tenter (typiquement la relance). À ne pas
  /// confondre avec [DiagnosticJourney.errorMessage], qui dit pourquoi
  /// l'analyse elle-même a échoué.
  final String? errorMessage;

  /// Le serveur n'expose pas de drapeau « reçue » une fois l'analyse lancée :
  /// à partir d'ANALYZING, les deux productions sont forcément en sa
  /// possession.
  bool get _received =>
      journey.status == DiagnosticJourneyStatus.analyzing ||
      journey.status == DiagnosticJourneyStatus.completed;

  @override
  Widget build(BuildContext context) {
    final failed = journey.status == DiagnosticJourneyStatus.failed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        const DiagnosticProgress(activeStep: 2, completedSteps: 2),
        const SizedBox(height: 28),
        if (failed) _failedCard() else _waitingCard(),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          DiagnosticErrorBanner(message: errorMessage!),
        ],
      ],
    );
  }

  /// La carte dit d'abord, en langage clair, ce que le candidat doit savoir.
  /// Le message brut du serveur (« Sortie diagnostic invalide après réparation :
  /// EO2-C3 … ») n'est pas écrit pour lui : il passe en second plan, sans
  /// jamais disparaître — le support s'en sert.
  Widget _failedCard() => AppCard(
        borderRadius: AppRadii.xl,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.redLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                size: 30,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              kAnalysisFailedTitle,
              textAlign: TextAlign.center,
              style: AppFonts.display(size: 23),
            ),
            const SizedBox(height: 8),
            Text(
              kAnalysisFailedText,
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
            if (!journey.canRetry) ...[
              const SizedBox(height: 12),
              Text(
                kAnalysisRetryExhausted,
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 22),
            if (journey.canRetry) ...[
              AppButton(
                label: 'Relancer l’analyse',
                isLoading: isBusy,
                onPressed: isBusy ? null : onRetry,
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
              label: 'Retour au plan',
              variant: AppButtonVariant.soft,
              onPressed: isBusy ? null : onOpenPlan,
            ),
            if (journey.errorMessage != null) ...[
              const SizedBox(height: 18),
              Text(
                'Détail technique : ${journey.errorMessage}',
                textAlign: TextAlign.center,
                style: AppFonts.ui(
                  size: 12,
                  color: AppColors.inkFaint,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      );

  Widget _waitingCard() => AppCard(
        borderRadius: AppRadii.xl,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: DiagnosticElapsed(
          builder: (context, elapsed) {
            final long = elapsed >= _kAnalyseHabituelle;
            return Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Analyse IA de vos deux productions',
                  textAlign: TextAlign.center,
                  style: AppFonts.display(size: 23),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre texte et votre enregistrement sont analysés '
                  'séparément, puis réunis en trois priorités au maximum.',
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 13.5,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                DiagnosticElapsedPill(elapsed: elapsed),
                const SizedBox(height: 18),
                DiagnosticWaitSteps(
                  steps: [
                    DiagnosticWaitStep(
                      'Écrit reçu',
                      _received
                          ? DiagnosticWaitState.done
                          : DiagnosticWaitState.pending,
                    ),
                    DiagnosticWaitStep(
                      'Oral reçu',
                      _received
                          ? DiagnosticWaitState.done
                          : DiagnosticWaitState.pending,
                    ),
                    const DiagnosticWaitStep(
                      'Analyse IA en cours',
                      DiagnosticWaitState.active,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  long
                      ? 'C’est plus long que d’habitude. L’analyse se poursuit '
                          'sur nos serveurs : rien n’est perdu. Vous pouvez '
                          'quitter cet écran et revenir plus tard pour voir '
                          'votre résultat.'
                      : 'L’analyse prend généralement moins de deux minutes. '
                          'Rien n’est perdu : vous pouvez quitter cet écran, '
                          'elle se poursuit sur nos serveurs.',
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Actualiser',
                  variant: AppButtonVariant.soft,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onRefresh,
                ),
              ],
            );
          },
        ),
      );
}
