import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/competence_prompt_screen.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';

import 'support/skill_fixtures.dart';

/// **L'analyse IA n'est plus une option.** L'écran de saisie n'offre plus de
/// bascule : l'analyse est demandée dès que le compte y a droit, et quand il
/// n'y a plus droit la production part **sans** analyse au lieu d'échouer.
///
/// Ce qui reste, c'est une information : combien d'analyses offertes il reste.
/// La supprimer ferait consommer un quota à l'insu du candidat.

Future<FakeSkillRepository> _pumpPrompt(
  WidgetTester tester, {
  Map<String, dynamic>? quota,
}) async {
  final prompt = SkillPromptDto.fromJson(promptJson());
  final repo = FakeSkillRepository(prompt: prompt, quota: quota);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const CompetencePromptScreen(
          module: TcfProductionModule.ee,
          skillId: 'c1',
          promptId: 'p1',
        ),
      ),
      GoRoute(
        path: '/tcf/ee/competences/resultat/:attemptId',
        builder: (_, __) => const Scaffold(body: Text('ÉCRAN RÉSULTAT')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [skillRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// La liste construit ses enfants à la demande : pour affirmer qu'un bloc est
/// absent, il faut l'avoir fait défiler en entier.
Future<void> _scrollListToEnd(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
  }
}

/// Produit une réponse recevable puis valide.
Future<void> _produceAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextField),
    'Bonjour Madame, je suis votre voisin du 3e étage.',
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Valider et comparer'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('la bascule d\'analyse a disparu', () {
    testWidgets('aucune option à cocher avant de valider', (tester) async {
      await _pumpPrompt(tester);
      await _scrollListToEnd(tester);

      expect(find.text('Analyser ma réponse avec l\'IA'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
  });

  group('l\'information de quota reste, la décision non', () {
    testWidgets('un compte gratuit voit ce qu\'il lui reste', (tester) async {
      await _pumpPrompt(tester, quota: quotaJson(remaining: 3));
      await _scrollListToEnd(tester);

      expect(
        find.textContaining('Il te reste 3 analyses offertes'),
        findsOneWidget,
      );
    });

    testWidgets('le singulier est respecté', (tester) async {
      await _pumpPrompt(tester, quota: quotaJson(remaining: 1));
      await _scrollListToEnd(tester);

      expect(
        find.textContaining('Il te reste 1 analyse offerte.'),
        findsOneWidget,
      );
    });

    testWidgets('un accès illimité n\'a rien à décompter', (tester) async {
      await _pumpPrompt(
        tester,
        quota: quotaJson(premium: true, unlimited: true, remaining: -1),
      );
      await _scrollListToEnd(tester);

      expect(find.textContaining('Il te reste'), findsNothing);
      // Et surtout jamais la valeur brute d'un quota illimité.
      expect(find.textContaining('-1'), findsNothing);
    });

    testWidgets('quota épuisé : l\'écran de saisie n\'en fait pas un mur',
        (tester) async {
      await _pumpPrompt(tester, quota: quotaJson(remaining: 0));
      await _scrollListToEnd(tester);

      expect(find.textContaining('Il te reste'), findsNothing);
      expect(find.text('Valider et comparer'), findsOneWidget);
    });
  });

  group('ce qui part au serveur', () {
    testWidgets('analyse demandée d\'office quand le compte y a droit',
        (tester) async {
      final repo = await _pumpPrompt(tester, quota: quotaJson(remaining: 3));
      await _produceAndSubmit(tester);

      expect(repo.lastRequestAnalysis, isTrue);
      expect(find.text('ÉCRAN RÉSULTAT'), findsOneWidget);
    });

    testWidgets('abonné : analyse demandée aussi', (tester) async {
      final repo = await _pumpPrompt(
        tester,
        quota: quotaJson(premium: true, unlimited: true, remaining: -1),
      );
      await _produceAndSubmit(tester);

      expect(repo.lastRequestAnalysis, isTrue);
    });

    testWidgets(
        'quota épuisé : la production part SANS analyse, jamais en échec',
        (tester) async {
      final repo = await _pumpPrompt(tester, quota: quotaJson(remaining: 0));
      await _produceAndSubmit(tester);

      // C'est l'écran de résultat qui invitera à s'abonner : la production,
      // elle, est enregistrée.
      expect(repo.lastRequestAnalysis, isFalse);
      expect(find.text('ÉCRAN RÉSULTAT'), findsOneWidget);
    });
  });
}
