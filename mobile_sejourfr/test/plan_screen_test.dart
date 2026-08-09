import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/audience_repository.dart';
import 'package:sejourfr_mobile/core/api/learning_plan_repository.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/providers/target_level_provider.dart';
import 'package:sejourfr_mobile/screens/plan/plan_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Plan met la priorité et l’exercice recommandé avant les stats',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningPlanRepositoryProvider.overrideWithValue(
            _FakeLearningPlanRepository(_activePlan),
          ),
          audienceRepositoryProvider.overrideWithValue(
            _FakeAudienceRepository(),
          ),
          userTargetLevelProvider.overrideWithValue(TargetLevel.b2),
        ],
        child: const MaterialApp(home: PlanScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mon plan'), findsOneWidget);
    expect(find.text('Objectif : B2'), findsOneWidget);
    expect(find.text('Développer un argument'), findsWidgets);
    expect(find.text('Donner une raison et un exemple'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Voir ma progression'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Voir ma progression'), findsOneWidget);
  });
}

final _activePlan = LearningPlan(
  state: LearningPlanState.active,
  diagnosticSessionId: 'session-1',
  diagnosticCompletedAt: DateTime.utc(2026, 8, 9),
  currentPriority: LearningPlanPriority(
    skillId: 'skill-1',
    skillCode: 'EE_ARG',
    title: 'Développer un argument',
    section: SkillSection.ee,
    status: LearningPlanSkillStatus.priority,
    confidence: ObservationConfidence.high,
    observedAt: DateTime.utc(2026, 8, 9),
    explanation: 'La raison mérite encore un exemple concret.',
    recommendedExercise: const PlanRecommendedExercise(
      skillPromptId: 'prompt-1',
      skillId: 'skill-1',
      skillCode: 'EE_ARG',
      title: 'Donner une raison et un exemple',
      section: SkillSection.ee,
      estimatedMinutes: 4,
    ),
  ),
  nextPriorities: const [],
  observedSkills: [
    LearningPlanSkill(
      skillId: 'skill-1',
      skillCode: 'EE_ARG',
      title: 'Développer un argument',
      section: SkillSection.ee,
      status: LearningPlanSkillStatus.priority,
      lastObservedAt: DateTime.utc(2026, 8, 9),
    ),
  ],
  observedSkillCount: 1,
  activitiesThisWeek: 2,
  progressionAvailable: true,
);

class _FakeLearningPlanRepository implements LearningPlanRepository {
  _FakeLearningPlanRepository(this.plan);

  final LearningPlan plan;

  @override
  Future<LearningPlan> get() async => plan;
}

class _FakeAudienceRepository implements AudienceRepository {
  @override
  Future<void> track({
    required String path,
    required AudienceEvent event,
  }) async {}
}
