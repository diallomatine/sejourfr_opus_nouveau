import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/widgets/app_button.dart';
import 'package:sejourfr_mobile/screens/diagnostic/widgets/diagnostic_written.dart';

/// ⚠️ Héritage. Le dépôt **n'écrit plus de test front** (cf. `CLAUDE.md` racine,
/// § Tests) : ce fichier n'est ni étendu, ni recréé ailleurs.
///
/// Les trois cas qui portaient sur la **présentation** et sur le **résultat**
/// ont été retirés avec la refonte de ces deux écrans : ils gelaient des
/// libellés (« Diagnostic terminé », « Découvrir mon plan », « 8 à 10 min »)
/// que la maquette a remplacés, et le résultat lit désormais le Plan — il
/// n'est plus montable hors `ProviderScope`. Les réécrire aurait été **écrire
/// de nouveaux tests front**. Le seul cas conservé est celui qui ne dépend
/// d'aucun de ces écrans.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('l’écrit applique strictement les bornes servies par le serveur',
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
