import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/learning_plan_repository.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/screens/home/home_screen.dart';
import 'package:sejourfr_mobile/screens/plan/learning_plan_provider.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
      'l’accueil préfère la priorité vivante du Plan au diagnostic figé',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningPlanRepositoryProvider.overrideWithValue(
            _FakeLearningPlanRepository(_livePlan),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PlanPriorityHomeCard(
              journey: _completedDiagnostic,
              onOpenPlan: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.text('Priorité mise à jour après entraînement'), findsOneWidget);
    expect(find.text('Priorité initiale du diagnostic'), findsNothing);
  });

  test('le signal d’activité recharge un Plan actuellement observé', () async {
    final repository = _CountingLearningPlanRepository(_livePlan);
    final container = ProviderContainer(
      overrides: [
        learningPlanRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      learningPlanProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(learningPlanProvider.future);
    container.read(learningPlanRevisionProvider.notifier).state++;
    await container.read(learningPlanProvider.future);

    expect(repository.calls, 2);
  });
}

final _completedDiagnostic = DiagnosticJourney(
  sessionId: 'session-1',
  diagnosticCode: 'INITIAL_TCF',
  diagnosticVersion: 1,
  status: DiagnosticJourneyStatus.completed,
  nextStep: DiagnosticStep.result,
  canRetry: false,
  result: DiagnosticResult(
    strengths: const [],
    priorities: [
      DiagnosticSkillObservation(
        skillId: 'initial-skill',
        skillCode: 'EE_INITIAL',
        skillTitle: 'Priorité initiale du diagnostic',
        section: SkillSection.ee,
        observed: true,
        status: LearningPlanSkillStatus.priority,
        confidence: ObservationConfidence.medium,
        priority: true,
      ),
    ],
  ),
);

final _livePlan = LearningPlan(
  state: LearningPlanState.active,
  currentPriority: LearningPlanPriority(
    skillId: 'live-skill',
    skillCode: 'EO_LIVE',
    title: 'Priorité mise à jour après entraînement',
    section: SkillSection.eo,
    status: LearningPlanSkillStatus.priority,
    confidence: ObservationConfidence.high,
    observedAt: DateTime.utc(2026, 8, 9),
  ),
  nextPriorities: const [],
  observedSkills: const [],
  observedSkillCount: 1,
  activitiesThisWeek: 1,
  progressionAvailable: true,
);

class _FakeLearningPlanRepository implements LearningPlanRepository {
  _FakeLearningPlanRepository(this.plan);

  final LearningPlan plan;

  @override
  Future<LearningPlan> get() async => plan;
}

class _CountingLearningPlanRepository extends _FakeLearningPlanRepository {
  _CountingLearningPlanRepository(super.plan);

  var calls = 0;

  @override
  Future<LearningPlan> get() async {
    calls++;
    return super.get();
  }
}
