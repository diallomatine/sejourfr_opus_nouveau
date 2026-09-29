import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/competence_result_screen.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/skill_references_tabs.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';

import 'support/skill_fixtures.dart';

/// **Au résultat, on voit l'analyse, pas un bandeau.**
///
/// Le retour IA vient d'être mérité : il s'affiche déplié, sans clic. Ce sont
/// les références comparatives — génériques, écrites en base — qui se replient.
/// Le bandeau premium ne subsiste que quand il n'y a rien à montrer.

/// Assez haut pour que la liste construise tous ses blocs : ces tests parlent
/// de présence et d'ordre, pas de ligne de flottaison (celle-ci est verrouillée
/// sur l'écran de saisie).
const Size _kTallView = Size(430, 1800);

Future<void> _pumpResult(
  WidgetTester tester, {
  Map<String, dynamic>? attempt,
  Map<String, dynamic>? quota,
  List<Map<String, dynamic>>? references,
}) async {
  tester.view.physicalSize = _kTallView;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = FakeSkillRepository(
    prompt: SkillPromptDto.fromJson(promptJson()),
    attempt: attempt,
    quota: quota,
    references: references,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [skillRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: CompetenceResultScreen(
          module: TcfProductionModule.ee,
          attemptId: 'a1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Le polling s'arrête de lui-même sur un statut final : on lui laisse son
  // premier battement pour qu'aucun timer ne survive au test.
  await tester.pump(const Duration(seconds: 4));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('l\'analyse est dépliée par défaut', () {
    testWidgets('elle se lit sans clic, et sans bandeau à déverrouiller',
        (tester) async {
      await _pumpResult(tester);

      expect(find.textContaining('le vouvoiement n\'est pas tenu'),
          findsOneWidget);
      expect(find.text('Ce qui est réussi'), findsOneWidget);
      expect(find.text('À travailler en priorité'), findsOneWidget);
      expect(find.text('Proposition améliorée'), findsOneWidget);

      // Le bandeau premium et son bouton n'ont plus rien à faire ici.
      expect(find.text('Analyse IA du critère'), findsNothing);
      expect(find.text('Voir'), findsNothing);
      expect(find.text('Masquer'), findsNothing);
    });

    testWidgets('elle reste au-dessus des références (§13.4)', (tester) async {
      await _pumpResult(tester);

      final verdict = tester.getRect(
        find.textContaining('le vouvoiement n\'est pas tenu'),
      );
      final references = tester.getRect(
        find.text('Compare avec les niveaux de référence'),
      );
      expect(verdict.top, lessThan(references.top));
    });
  });

  group('les références se replient', () {
    testWidgets('repliées par défaut quand une analyse est affichée',
        (tester) async {
      await _pumpResult(tester);

      expect(find.text('Compare avec les niveaux de référence'), findsOneWidget);
      expect(find.byType(SkillReferencesTabs), findsNothing);
      expect(find.text('Comparer'), findsOneWidget);
    });

    testWidgets('une action claire les ouvre, puis les referme',
        (tester) async {
      await _pumpResult(tester);

      await tester.ensureVisible(find.text('Comparer'));
      await tester.tap(find.text('Comparer'));
      await tester.pumpAndSettle();

      expect(find.byType(SkillReferencesTabs), findsOneWidget);
      expect(find.text('Attendu'), findsOneWidget);
      expect(find.text('Masquer'), findsOneWidget);
      expect(find.text('Comparer'), findsNothing);

      await tester.ensureVisible(find.text('Masquer'));
      await tester.tap(find.text('Masquer'));
      await tester.pumpAndSettle();

      expect(find.byType(SkillReferencesTabs), findsNothing);
      expect(find.text('Comparer'), findsOneWidget);
    });

    testWidgets('aucune référence ⇒ ni intertitre, ni interrupteur orphelin',
        (tester) async {
      await _pumpResult(tester, references: const []);

      expect(find.text('Compare avec les niveaux de référence'), findsNothing);
      expect(find.text('Comparer'), findsNothing);
    });
  });

  group('sans analyse à montrer, le bandeau reste', () {
    testWidgets('quota épuisé : bandeau « Débloquer » et références ouvertes',
        (tester) async {
      await _pumpResult(
        tester,
        attempt: attemptJson(
          statut: 'RECORDED',
          analysisRequested: false,
          analysis: null,
        ),
        quota: quotaJson(remaining: 0),
      );

      expect(find.text('Analyse IA du critère'), findsOneWidget);
      expect(find.text('Débloquer'), findsOneWidget);
      expect(find.text('Réponse enregistrée, sans analyse IA'), findsOneWidget);
      expect(find.text('Débloquer les analyses IA'), findsOneWidget);

      // Elles sont alors le seul retour de l'écran : on ne les cache pas.
      expect(find.byType(SkillReferencesTabs), findsOneWidget);
      expect(find.text('Masquer'), findsOneWidget);
    });

    testWidgets('analyse en échec : la relance est toujours là', (tester) async {
      await _pumpResult(
        tester,
        attempt: attemptJson(
          statut: 'FAILED',
          analysis: null,
          errorMessage: 'Le service d\'analyse n\'a pas répondu.',
        ),
      );

      expect(find.text('L\'analyse n\'a pas abouti'), findsOneWidget);
      expect(find.text('Relancer l\'analyse'), findsOneWidget);
      expect(find.byType(SkillReferencesTabs), findsOneWidget);
    });
  });
}
