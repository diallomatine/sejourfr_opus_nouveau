import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/audience_repository.dart';
import 'package:sejourfr_mobile/core/api/learning_plan_repository.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/dashboard_models.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/providers/dashboard_provider.dart';
import 'package:sejourfr_mobile/core/providers/target_level_provider.dart';
import 'package:sejourfr_mobile/core/widgets/progress_ring.dart';
import 'package:sejourfr_mobile/screens/plan/plan_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpPlan(
    WidgetTester tester, {
    NiveauCecrl? estimated = NiveauCecrl.b1,
  }) async {
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
          dashboardProvider.overrideWith((ref) async => _summary(estimated)),
        ],
        child: const MaterialApp(home: PlanScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Plan met la priorité et l’exercice recommandé avant les stats',
      (tester) async {
    await pumpPlan(tester);

    expect(find.text('Mon plan'), findsOneWidget);
    expect(find.text('Développer un argument'), findsWidgets);
    // Le Plan ne nomme QUE des compétences : le titre du sujet recommandé vit
    // sur l'écran d'étape, où le candidat voit les 5 et choisit.
    expect(find.text('Donner une raison et un exemple'), findsNothing);
    expect(find.text('Commencer'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Voir mon diagnostic'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Voir mon diagnostic'), findsOneWidget);

    // « Voir ma progression » a quitté le Plan pour le Profil : le Plan dit
    // quoi travailler maintenant, la progression se consulte ailleurs.
    expect(find.text('Voir ma progression'), findsNothing);
  });

  testWidgets(
      'le héros affiche le cap « niveau estimé → objectif » servi par le dashboard',
      (tester) async {
    await pumpPlan(tester);

    // Le niveau estimé n'a qu'une seule surface autorisée : on l'affiche tel
    // quel, on ne le recalcule jamais.
    expect(find.text('B1'), findsOneWidget);
    expect(find.text('B2'), findsOneWidget);
    // Trois compteurs réels, jamais un pourcentage d'avancement.
    expect(find.text('3'), findsWidgets);
    expect(find.text('priorités'), findsOneWidget);
    expect(find.text('cette semaine'), findsOneWidget);
    expect(find.text('compétences observées'), findsOneWidget);
  });

  testWidgets('sans niveau estimé le héros dégrade sur le seul objectif',
      (tester) async {
    await pumpPlan(tester, estimated: null);

    expect(find.text('Objectif : B2'), findsOneWidget);
  });

  testWidgets('le parcours se lit en étapes numérotées, en cours puis à venir',
      (tester) async {
    await pumpPlan(tester);

    // On défile jusqu'à la DERNIÈRE étape, pas jusqu'au titre de section : une
    // liste ne construit que ses enfants visibles, et s'arrêter au titre
    // laissait les étapes hors de l'arbre.
    await tester.scrollUntilVisible(
      find.text('Relier ses idées'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    // 3 priorités numérotées 1..3. Le chemin ne se termine plus par une carte
    // « Réévaluation » : elle était rendue en dur, ne venait d'aucun champ du
    // DTO et annonçait une action qui n'existait pas.
    for (final number in ['1', '2', '3']) {
      expect(find.text(number), findsWidgets, reason: 'étape $number');
    }
    expect(find.text('EN COURS'), findsOneWidget);
    expect(find.text('À VENIR'), findsNWidgets(2));
    expect(find.text('Réévaluation'), findsNothing);

    // Ordre : l'étape en cours vient avant les deux suivantes.
    final current = tester.getTopLeft(find.text('EN COURS')).dy;
    final upcoming = tester
        .getTopLeft(find.text('Relier ses idées'))
        .dy;
    expect(current, lessThan(upcoming));
  });

  testWidgets('les anneaux du parcours lisent les compteurs réels du serveur',
      (tester) async {
    await pumpPlan(tester);

    // Jusqu'à la dernière étape : une liste ne construit que ses enfants
    // visibles, s'arrêter au titre de section laisserait les anneaux hors de
    // l'arbre.
    await tester.scrollUntilVisible(
      find.text('Relier ses idées'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    final rings = tester
        .widgetList<ProgressRing>(find.byType(ProgressRing))
        .toList(growable: false);

    // Étape 1 : 2 sujets traités sur les 5 de l'ÉTAPE (`step*`), pas sur les 15
    // de la compétence — jamais un pourcentage d'avancement inventé, et jamais
    // « % du plan maîtrisé ».
    expect(rings.first.label, '2');
    expect(rings.first.sub, '/5');
    expect(rings.first.value, closeTo(40, 0.01));
  });

  testWidgets('les compétences observées reprennent le libellé du module',
      (tester) async {
    await pumpPlan(tester);

    await tester.scrollUntilVisible(
      find.text('Mes compétences observées'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    // Miroir exact de `competenceProgressLabel` (Réviser → Compétences).
    expect(find.textContaining('1 réussi · 3 restants'), findsOneWidget);
    // Libellé de statut aligné sur le web.
    expect(find.textContaining('Prioritaire'), findsWidgets);
  });

  testWidgets('aucun débordement sur un téléphone étroit (360 px)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpPlan(tester);

    // Le chemin, ses anneaux et les cartes de compétence tiennent la largeur
    // la plus étroite du parc : un `RenderFlex overflowed` ferait échouer ici.
    expect(find.text('Votre parcours'), findsOneWidget);
    expect(find.text('Mes compétences observées'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

DashboardSummary _summary(NiveauCecrl? level) => DashboardSummary(
      currentStreakDays: 0,
      recordStreakDays: 0,
      activeToday: false,
      mockExamsTotal: 0,
      civiqueMockExams: 0,
      tcfMockExams: 0,
      globalSuccessPercent: null,
      estimatedTcfLevel: level,
      estimatedTcfLevelEpreuvesCounted: level == null ? 0 : 4,
      estimatedTcfLevelEpreuvesExpected: 4,
      estimatedTcfLevelPartial: false,
      civique: const [],
      tcf: const [],
    );

/// ⚠️ Deux jeux de compteurs : `promptCount` décrit la **compétence entière**
/// (15 sujets, ce que lisent les cartes « compétences observées »),
/// `stepPromptCount` décrit l'**étape** (les 5 premiers). C'est le second que
/// l'anneau du parcours affiche.
LearningPlanPriority _priority({
  required String skillId,
  required String title,
  required SkillSection section,
  int promptCount = 15,
  int attemptedCount = 0,
  int stepPromptCount = 5,
  int stepAttemptedCount = 0,
  int stepValidatedCount = 0,
  bool stepCompleted = false,
  PlanRecommendedExercise? exercise,
  String? evidence,
}) =>
    LearningPlanPriority(
      skillId: skillId,
      skillCode: '${section.wire}1-C1',
      title: title,
      section: section,
      nature: PlanActionNature.aRenforcer,
      status: LearningPlanSkillStatus.priority,
      confidence: ObservationConfidence.high,
      observedAt: DateTime.utc(2026, 8, 9),
      evidence: evidence,
      recommendedExercise: exercise,
      promptCount: promptCount,
      attemptedCount: attemptedCount,
      stepPromptCount: stepPromptCount,
      stepAttemptedCount: stepAttemptedCount,
      stepValidatedCount: stepValidatedCount,
      stepCompleted: stepCompleted,
    );

final _activePlan = LearningPlan(
  state: LearningPlanState.active,
  diagnosticSessionId: 'session-1',
  diagnosticCompletedAt: DateTime.utc(2026, 8, 9),
  currentPriority: _priority(
    skillId: 'skill-1',
    title: 'Développer un argument',
    section: SkillSection.ee,
    attemptedCount: 2,
    stepAttemptedCount: 2,
    evidence: 'Parce que c’est utile.',
    exercise: const PlanRecommendedExercise(
      kind: PlanExerciseKind.microTraining,
      skillPromptId: 'prompt-1',
      skillId: 'skill-1',
      skillCode: 'EE1-C1',
      title: 'Donner une raison et un exemple',
      section: SkillSection.ee,
      estimatedMinutes: 4,
    ),
  ),
  nextPriorities: [
    _priority(
      skillId: 'skill-2',
      title: 'Relier ses idées',
      section: SkillSection.ee,
    ),
    _priority(
      skillId: 'skill-3',
      title: 'Nuancer un avis',
      section: SkillSection.eo,
    ),
  ],
  observedSkills: [
    LearningPlanSkill(
      skillId: 'skill-1',
      skillCode: 'EE1-C1',
      title: 'Développer un argument',
      section: SkillSection.ee,
      status: LearningPlanSkillStatus.priority,
      lastObservedAt: DateTime.utc(2026, 8, 9),
      promptCount: 4,
      attemptedCount: 1,
      validatedCount: 1,
    ),
  ],
  observedSkillCount: 5,
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
