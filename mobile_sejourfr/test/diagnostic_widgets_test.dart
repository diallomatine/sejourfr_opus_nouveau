import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/widgets/app_button.dart';
import 'package:sejourfr_mobile/screens/diagnostic/widgets/diagnostic_intro.dart';
import 'package:sejourfr_mobile/screens/diagnostic/widgets/diagnostic_result.dart';
import 'package:sejourfr_mobile/screens/diagnostic/widgets/diagnostic_written.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('la présentation annonce la durée réaliste et les deux exercices',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosticIntro(isStarting: false, onStart: () {}),
        ),
      ),
    );

    expect(find.textContaining('8 à 10 min'), findsOneWidget);
    expect(find.text('1 production écrite'), findsOneWidget);
    expect(find.text('1 production orale enregistrée'), findsOneWidget);
    expect(find.text('Commencer mon diagnostic gratuit'), findsOneWidget);
  });

  testWidgets('l’écrit applique strictement les bornes 100–130 du serveur',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    Future<void> pump(int words) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiagnosticWrittenStep(
                exercise: _writtenExercise,
                controller: controller,
                wordCount: words,
                isSubmitting: false,
                onChanged: (_) {},
                onSubmit: () {},
              ),
            ),
          ),
        );

    await pump(99);
    expect(_submitButton(tester).onPressed, isNull);

    await pump(100);
    expect(_submitButton(tester).onPressed, isNotNull);

    await pump(130);
    expect(_submitButton(tester).onPressed, isNotNull);

    await pump(131);
    expect(_submitButton(tester).onPressed, isNull);
  });

  testWidgets('le résultat reste léger avec trois priorités au maximum',
      (tester) async {
    PlanRecommendedExercise? openedExercise;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosticResultView(
            result: DiagnosticResult(
              strengths: const ['Message clair'],
              priorities: [
                for (var index = 0; index < 3; index++)
                  _priority('Priorité ${index + 1}'),
              ],
              mainPriorityExplanation:
                  'Ajoutez une raison et un exemple concret.',
              nextAction: _recommendedExercise,
            ),
            objective: 'B2',
            onOpenPlan: () {},
            onOpenRecommended: (exercise) => openedExercise = exercise,
          ),
        ),
      ),
    );

    expect(find.text('Objectif : B2'), findsOneWidget);
    expect(find.text('Priorité 1'), findsOneWidget);
    expect(find.text('Priorité 2'), findsOneWidget);
    expect(find.text('Priorité 3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('À TRAVAILLER MAINTENANT'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Donner une raison et un exemple'), findsOneWidget);
    expect(find.text('4 min · écrit'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Commencer l’exercice'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pump();
    await tester.tap(find.text('Commencer l’exercice'));
    expect(openedExercise, same(_recommendedExercise));
    expect(find.text('Voir mon plan'), findsOneWidget);
  });

  testWidgets('le résultat sans exercice recommande le Plan en repli',
      (tester) async {
    var openedPlan = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosticResultView(
            result: DiagnosticResult(
              strengths: const ['Message clair'],
              priorities: [_priority('Priorité 1')],
            ),
            onOpenPlan: () => openedPlan = true,
            onOpenRecommended: (_) {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Commencer mon plan'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Commencer mon plan'));
    expect(openedPlan, isTrue);
  });
}

AppButton _submitButton(WidgetTester tester) => tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Valider mon écrit'),
    );

const _writtenExercise = DiagnosticExercise(
  productionTaskId: 'task-ee',
  attemptId: 'attempt-ee',
  epreuve: EpreuveType.tcfEe,
  title: 'Diagnostic écrit',
  instruction: 'Écrivez un texte argumenté.',
  helperText: 'Donnez une raison et un exemple.',
  wordsMin: 100,
  wordsMax: 130,
);

DiagnosticSkillObservation _priority(String title) =>
    DiagnosticSkillObservation(
      skillId: title,
      skillCode: 'EE_ARG',
      skillTitle: title,
      section: SkillSection.ee,
      observed: true,
      status: LearningPlanSkillStatus.priority,
      confidence: ObservationConfidence.medium,
      priority: true,
    );

const _recommendedExercise = PlanRecommendedExercise(
  skillPromptId: 'prompt-1',
  skillId: 'skill-1',
  skillCode: 'EE_ARG',
  title: 'Donner une raison et un exemple',
  section: SkillSection.ee,
  estimatedMinutes: 4,
);
