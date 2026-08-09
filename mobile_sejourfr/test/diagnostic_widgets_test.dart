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

  /// Écran long : on lui donne une fenêtre haute plutôt que d'enchaîner les
  /// `scrollUntilVisible`, qui s'arrêtent dès que l'élément est *construit*
  /// (cache du viewport) et pas quand il est réellement visible. Bonus : un
  /// débordement de mise en page fait échouer le test.
  Future<void> pumpTall(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'le résultat rend les niveaux, les compétences observées et les deux productions',
      (tester) async {
    PlanRecommendedExercise? openedExercise;
    await pumpTall(
      tester,
      DiagnosticResultView(
        result: DiagnosticResult(
          written: _production(NiveauCecrl.b1, SkillSection.ee),
          oral: _production(NiveauCecrl.a2, SkillSection.eo),
          strengths: const ['Vocabulaire du quotidien maîtrisé'],
          priorities: [
            for (var index = 0; index < 3; index++)
              _priority('Priorité ${index + 1}'),
          ],
          mainPriorityExplanation: 'Ajoutez une raison et un exemple concret.',
          nextAction: _recommendedExercise,
        ),
        objective: 'B2',
        onOpenPlan: () {},
        onOpenRecommended: (exercise) => openedExercise = exercise,
      ),
    );

    expect(find.text('Diagnostic terminé'), findsOneWidget);
    expect(find.text('Objectif : B2'), findsOneWidget);
    // Les deux niveaux estimés, côte à côte dans le héros.
    expect(find.text('B1'), findsWidgets);
    expect(find.text('A2'), findsWidgets);

    // Ce que le diagnostic révèle : compétences observées, teintées par statut.
    expect(find.text('Ce que votre diagnostic révèle'), findsOneWidget);
    expect(find.text('Observée EE'), findsOneWidget);
    expect(find.text('Observée EO'), findsOneWidget);
    // Libellé de statut aligné sur le web.
    expect(find.text('Prioritaire'), findsWidgets);

    // La priorité n°1 est mise en avant, les suivantes restent listées.
    expect(find.text('IMPACT ÉLEVÉ'), findsOneWidget);
    expect(find.text('Priorité 1/3'), findsOneWidget);
    expect(find.text('Priorité 1'), findsOneWidget);
    expect(find.text('Priorité 2'), findsOneWidget);
    expect(find.text('Priorité 3'), findsOneWidget);

    // Le gisement jusqu'ici jamais affiché : résumé, accomplissement de la
    // consigne, efficacité du message et points à travailler.
    expect(find.text('Vos deux productions'), findsOneWidget);
    expect(find.text('Production exploitable.'), findsNWidgets(2));
    expect(find.text('Consigne accomplie'), findsNWidgets(2));
    expect(find.text('Message clair'), findsNWidgets(2));
    expect(find.text('À préciser'), findsNWidgets(2));

    await tester.tap(find.textContaining('Commencer l’exercice'));
    expect(openedExercise, same(_recommendedExercise));
    expect(find.text('Découvrir mon plan'), findsOneWidget);
  });

  testWidgets('le résultat sans exercice ne propose que le plan',
      (tester) async {
    var openedPlan = false;
    await pumpTall(
      tester,
      DiagnosticResultView(
        result: DiagnosticResult(
          strengths: const ['Vocabulaire du quotidien maîtrisé'],
          priorities: [_priority('Priorité 1')],
        ),
        onOpenPlan: () => openedPlan = true,
        onOpenRecommended: (_) {},
      ),
    );

    expect(find.textContaining('Commencer l’exercice'), findsNothing);
    await tester.tap(find.text('Découvrir mon plan'));
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

DiagnosticProductionResult _production(
  NiveauCecrl level,
  SkillSection section,
) =>
    DiagnosticProductionResult(
      levelEstimate: level,
      taskCompletion: DiagnosticTaskCompletion.completed,
      communicationStatus: DiagnosticCommunicationStatus.effective,
      summary: 'Production exploitable.',
      strengths: const ['Message compréhensible'],
      weaknesses: const ['À préciser'],
      skills: [_priority('Observée ${section.wire}')],
    );

const _recommendedExercise = PlanRecommendedExercise(
  skillPromptId: 'prompt-1',
  skillId: 'skill-1',
  skillCode: 'EE_ARG',
  title: 'Donner une raison et un exemple',
  section: SkillSection.ee,
  estimatedMinutes: 4,
);
