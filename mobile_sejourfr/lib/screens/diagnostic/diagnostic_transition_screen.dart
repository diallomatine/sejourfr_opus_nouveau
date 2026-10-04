import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../plan/learning_plan_provider.dart';
import 'diagnostic_rapport_labels.dart';
import 'diagnostic_rapport_screen.dart';
import 'widgets/diagnostic_common.dart';

/// **« Votre plan commence ici »** — la transition entre le rapport du
/// diagnostic rapide et le Plan (2026-10-04, écran 2 de la maquette).
/// Miroir web : `/diagnostic/rapport/[sessionId]/plan`.
///
/// 🛑 **Tout est servi** : les priorités sont celles du **lot du Plan**
/// (`planPriorities`, ordre servi, jamais tronqué), l'état des épreuves vient
/// de `plan.domaines[].evaluated`, la prochaine étape de `journey.current`
/// nommée par les libellés du parcours.
class DiagnosticTransitionScreen extends ConsumerWidget {
  const DiagnosticTransitionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(diagnosticSessionProvider(sessionId));
    void retour() => retourOuRepli(
          context,
          repli: AppRoutes.diagnosticRapportPath(sessionId),
        );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(title: kDiagnosticAnswerKicker, onBack: retour),
            Expanded(
              child: session.when(
                loading: () => DiagnosticLoadState(
                  isLoading: true,
                  onRetry: () =>
                      ref.invalidate(diagnosticSessionProvider(sessionId)),
                ),
                error: (_, __) => DiagnosticLoadState(
                  isLoading: false,
                  errorMessage: 'Impossible de charger votre diagnostic.',
                  onRetry: () =>
                      ref.invalidate(diagnosticSessionProvider(sessionId)),
                ),
                data: (journey) {
                  final result = journey.result;
                  if (result == null) {
                    return DiagnosticLoadState(
                      isLoading: false,
                      errorMessage: kDiagnosticRapportIndisponible,
                      onRetry: () =>
                          ref.invalidate(diagnosticSessionProvider(sessionId)),
                    );
                  }
                  return _Body(result: result, onBackToReport: retour);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.result, required this.onBackToReport});

  final DiagnosticResult result;
  final VoidCallback onBackToReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorities = result.planPriorities;
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final journey = ref.watch(journeyProvider).valueOrNull;
    final etape = journey?.current;
    final pill = diagnosticPrioritiesPill(priorities);
    final note = diagnosticPrioritiesNote(priorities);

    return ListView(
      padding: const EdgeInsets.only(top: 22, bottom: 32),
      children: [
        Padding(
          padding: sfGutter,
          child: SfDoneHero(
            kicker: kDiagnosticTransitionKicker,
            title: kDiagnosticTransitionTitle,
            text: diagnosticTransitionPhrase(result.objectiveLevel),
          ),
        ),
        SfSection(
          child: SfStack(
            children: [
              if (priorities.isNotEmpty)
                SfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SfPanelHead(
                              title: diagnosticPrioritiesTitle(
                                priorities.length,
                              ),
                              sub: kDiagnosticPrioritiesSub,
                            ),
                          ),
                          if (pill != null) ...[
                            const SizedBox(width: 10),
                            SfBadge(pill),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      SfNumberedSteps(
                        steps: [
                          for (final p in priorities)
                            (
                              number: p.rank,
                              title: p.skillTitle,
                              text: p.generalCriterion.isEmpty
                                  ? null
                                  : p.generalCriterion,
                            ),
                        ],
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 14),
                        SfTiny(note),
                      ],
                    ],
                  ),
                ),
              SfCard(
                variant: SfCardVariant.warn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SfHeadline(kDiagnosticBridgeTitle),
                    const SizedBox(height: 6),
                    const SfInsight(kDiagnosticBridgeText),
                    const SizedBox(height: 14),
                    SfEpreuveTiles(
                      tiles: [
                        for (final e in kDiagnosticBridgeEpreuves)
                          _tile(e.section.wire, e.epreuve, plan),
                      ],
                    ),
                  ],
                ),
              ),
              if (journey != null && etape != null)
                SfNextStepCard(
                  eyebrow: kDiagnosticNextStepEyebrow,
                  title: diagnosticNextStepTitle(journey, etape),
                  text: kDiagnosticNextStepText,
                  facts: const [],
                ),
              const SizedBox(height: 4),
              SfButton(
                label: kDiagnosticPlanCta,
                onPressed: () => context.go(AppRoutes.tcfPlan),
              ),
              SfTextLink(
                label: kDiagnosticBackToReport,
                onTap: onBackToReport,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static SfEpreuveTile _tile(
    String code,
    EpreuveType epreuve,
    LearningPlan? plan,
  ) {
    bool? evaluated;
    for (final d in plan?.domaines ?? const <PlanDomain>[]) {
      if (d.epreuve == epreuve) evaluated = d.evaluated;
    }
    return (
      code: code,
      name: epreuve.displayLabel,
      state: diagnosticEpreuveEtat(evaluated),
      done: evaluated == true,
    );
  }
}
