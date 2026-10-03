import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/diagnostic_run_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import 'widgets/diagnostic_common.dart';
import 'widgets/diagnostic_report_labels.dart';
import 'widgets/diagnostic_result.dart';

/// Une session de diagnostic TCF lue par son identifiant
/// (`GET /api/diagnostics/{sessionId}`).
final diagnosticSessionProvider = FutureProvider.autoDispose
    .family<DiagnosticJourney, String>((ref, sessionId) {
  return ref.read(diagnosticRepositoryProvider).detail(sessionId);
});

/// Le texte servi quand la session désignée n'a pas (ou plus) de rapport.
/// Miroir de `DIAGNOSTIC_RAPPORT_INDISPONIBLE` (web `DiagnosticView.tsx`).
const String kDiagnosticRapportIndisponible =
    'Ce diagnostic n’a pas de rapport à relire pour l’instant.';

/// **La relecture d'un diagnostic TCF CLOS**, désigné par son identifiant — la
/// destination de « Mon diagnostic » du Plan
/// ([AppRoutes.diagnosticRapportPath]).
///
/// 🛑 **Jamais `/diagnostic` pour relire.** Cette route-là lit la session
/// COURANTE (`GET /api/diagnostics/current`) : un compte qui a clos un
/// diagnostic d'un autre code, puis commencé le rapide sans le finir, y voyait
/// l'invitation à REPRENDRE au lieu de son rapport. Ici, la session est celle
/// que le serveur désigne (`estimationSessionId`).
///
/// 🛑 **Lecture seule** : aucun démarrage, aucune soumission, aucune relance.
/// Le rendu est le MÊME [DiagnosticResultView] que celui de `/diagnostic`.
///
/// Miroir web : `DiagnosticRapportView` (`DiagnosticView.tsx`).
class DiagnosticRapportScreen extends ConsumerStatefulWidget {
  const DiagnosticRapportScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<DiagnosticRapportScreen> createState() =>
      _DiagnosticRapportScreenState();
}

class _DiagnosticRapportScreenState
    extends ConsumerState<DiagnosticRapportScreen> {
  bool _resultViewedTracked = false;

  static bool _aUnRapport(DiagnosticJourney journey) =>
      journey.result != null &&
      (journey.status == DiagnosticJourneyStatus.completed ||
          journey.nextStep == DiagnosticStep.result);

  void _trackReportViewed() {
    if (_resultViewedTracked) return;
    _resultViewedTracked = true;
    ref.read(analyticsServiceProvider).track(
          AnalyticsEvent.diagnosticReportViewed,
          path: AnalyticsPath.diagnostic,
          diagnosticType: AnalyticsDiagnosticType.rapid,
          diagnosticRun: DiagnosticRunType.quickTcf,
        );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(diagnosticSessionProvider(widget.sessionId));
    final objective = ref.watch(userTargetLevelProvider);
    final journey = session.valueOrNull;
    final rapport = journey != null && _aUnRapport(journey);
    if (rapport) _trackReportViewed();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: rapport ? kDiagnosticReportTitle : 'Diagnostic TCF',
              sub: rapport ? kDiagnosticReportKicker : null,
              onBack: () => retourOuRepli(context, repli: AppRoutes.tcfPlan),
            ),
            Expanded(
              child: session.when(
                loading: () => DiagnosticLoadState(
                  isLoading: true,
                  onRetry: () => ref
                      .invalidate(diagnosticSessionProvider(widget.sessionId)),
                ),
                error: (_, __) => DiagnosticLoadState(
                  isLoading: false,
                  errorMessage: 'Impossible de charger votre diagnostic.',
                  onRetry: () => ref
                      .invalidate(diagnosticSessionProvider(widget.sessionId)),
                ),
                data: (value) => _aUnRapport(value)
                    ? DiagnosticResultView(
                        result: value.result!,
                        objective: objective,
                      )
                    : const _RapportIndisponible(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RapportIndisponible extends StatelessWidget {
  const _RapportIndisponible();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DiagnosticErrorBanner(
                message: kDiagnosticRapportIndisponible,
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Retour au plan',
                variant: AppButtonVariant.soft,
                onPressed: () =>
                    retourOuRepli(context, repli: AppRoutes.tcfPlan),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
