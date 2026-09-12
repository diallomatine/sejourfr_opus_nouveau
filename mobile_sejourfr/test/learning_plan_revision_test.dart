import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sejourfr_mobile/core/api/learning_plan_repository.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/screens/plan/learning_plan_provider.dart';

// ⚠️ Ce fichier s'appelait `home_plan_priority_test.dart` : il gelait en plus
// l'anatomie de `PlanPriorityHomeCard`, la carte de priorité de l'ancien
// Accueil, supprimée quand l'écran a été refait sur le KIT (la règle qu'elle
// portait — une priorité verrouillée n'est jamais nommée sur l'Accueil — vit
// maintenant dans `HomeScreen._actionTcf`). Reste ici le seul contrat qui n'a
// rien à voir avec un écran : le signal de rechargement du Plan.

void main() {
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

final _livePlan = LearningPlan(
  state: LearningPlanState.active,
  currentPriority: LearningPlanPriority(
    skillId: 'live-skill',
    skillCode: 'EO_LIVE',
    title: 'Priorité mise à jour après entraînement',
    section: SkillSection.eo,
    nature: PlanActionNature.aRenforcer,
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
