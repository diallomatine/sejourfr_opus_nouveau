import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'diagnostic_analysis_labels.dart';
import 'diagnostic_common.dart';
import 'diagnostic_outcomes.dart';
import 'diagnostic_wait.dart';

class DiagnosticAnalysisView extends StatelessWidget {
  const DiagnosticAnalysisView({
    super.key,
    required this.journey,
    required this.isBusy,
    required this.isPolling,
    required this.onRefresh,
    required this.onRetry,
    required this.onOpenPlan,
    required this.onOpenHome,
    this.errorMessage,
  });

  final DiagnosticJourney journey;
  final bool isBusy;

  /// Le contrôleur relit encore la session. Il s'arrête au bout de 10 min
  /// (`maxPolls`) : c'est alors seulement qu'« Actualiser » apparaît.
  final bool isPolling;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenHome;

  /// Échec de l'action qu'on vient de tenter (typiquement la relance). À ne pas
  /// confondre avec [DiagnosticJourney.errorMessage], qui dit pourquoi
  /// l'analyse elle-même a échoué.
  final String? errorMessage;

  /// La forme de CETTE session : un oral seulement s'il a été servi.
  bool get _hasOral => journey.oral != null;

  @override
  Widget build(BuildContext context) {
    final failed = journey.status == DiagnosticJourneyStatus.failed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
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
              kDiagnosticAnalysisFailedTitle,
              textAlign: TextAlign.center,
              style: AppFonts.display(size: 23),
            ),
            const SizedBox(height: 8),
            Text(
              diagnosticAnalysisFailedText(_hasOral),
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
                diagnosticAnalysisRetryExhausted(_hasOral),
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

  /// L'attente de l'analyse. Miroir de `AnalysisWaiting` (web) : une ligne
  /// par production que la session comporte, jamais un oral « en attente »
  /// sur le diagnostic rapide qui n'en a pas.
  Widget _waitingCard() {
    final title = diagnosticAnalysisTitle(_hasOral);
    return DiagnosticWaitCard(
      kicker: kDiagnosticAnalysisKicker,
      title: diagnosticWaitTitle(title.lead, title.em, title.tail),
      lead: kDiagnosticAnalysisLead,
      steps: diagnosticAnalysisSteps(
        writtenReceived: journey.written == null
            ? null
            : journey.written!.submissionId != null,
        oralReceived:
            journey.oral == null ? null : journey.oral!.submissionId != null,
      ),
      footer: (elapsed) => [
        const SizedBox(height: 10),
        Text(
          elapsed >= kDiagnosticAnalysisUsual
              ? diagnosticAnalysisSlow(_hasOral)
              : kDiagnosticAnalysisUsualText,
          style: AppFonts.ui(size: 13.5, color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        const _OutcomesPanel(),
        const SizedBox(height: 22),
        if (!isPolling) ...[
          AppButton(
            label: 'Actualiser',
            isLoading: isBusy,
            onPressed: isBusy ? null : onRefresh,
          ),
          const SizedBox(height: 10),
        ],
        AppButton(
          label: kDiagnosticAnalysisHomeCta,
          variant: AppButtonVariant.soft,
          onPressed: onOpenHome,
        ),
      ],
    );
  }
}

/// Ce que contiendra le rapport : les items de l'écran de compte
/// (`kTcfDiagnosticGateOutcomes`), une information vraie pendant l'attente.
/// Icônes miroirs de `TCF_DIAGNOSTIC_PANEL` (web).
class _OutcomesPanel extends StatelessWidget {
  const _OutcomesPanel();

  static const _icons = [
    LucideIcons.gauge,
    LucideIcons.target,
    LucideIcons.route,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kDiagnosticOutcomesTitle.toUpperCase(),
            style: AppFonts.label(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < kTcfDiagnosticGateOutcomes.length; i++) ...[
            if (i != 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    _icons[i % _icons.length],
                    size: 16,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kTcfDiagnosticGateOutcomes[i].title,
                        style: AppFonts.ui(size: 14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kTcfDiagnosticGateOutcomes[i].text,
                        style: AppFonts.ui(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            kDiagnosticDisclaimer,
            style: AppFonts.ui(size: 12, color: AppColors.muted2),
          ),
        ],
      ),
    );
  }
}
