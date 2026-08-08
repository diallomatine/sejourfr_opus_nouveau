// Compteur et blocage de la zone de rédaction EE, au mot près.
//
// Les bornes du TCF IRN sont STRICTES : 30–60 mots en tâche 1, **40–90** en
// tâches 2 et 3. Elles viennent de la base (`production_tasks.mots_min/max`,
// portées par `ProductionTaskDto`) et pilotent trois choses qui doivent dire la
// même chose : le compteur affiché, le message d'état de `WritingZone`, et
// `isEeWordCountWithinBounds` — qui débloque le bouton de soumission et décide
// de l'auto-soumission à l'expiration du chrono d'examen.
//
// Un front qui refuse une copie que le serveur accepte, c'est un candidat
// bloqué pour rien : les 59 mots en T2/T3 sont exactement la régression
// corrigée (le minimum valait 60). Pendants : `ProductionEvaluationServiceTest`
// (backend) et `lib/ee-word-bounds.test.ts` (web), sur les mêmes frontières.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/writing_zone.dart';

ProductionTaskDto _eeTask(int tache, int min, int max) => ProductionTaskDto(
      id: 'ee-t$tache',
      epreuve: EpreuveType.tcfEe,
      tacheNumero: tache,
      niveauCible: 'B1',
      consigne: 'Consigne',
      motsMin: min,
      motsMax: max,
    );

Future<void> _pumpZone(
  WidgetTester tester, {
  required int wordCount,
  required int minWords,
  required int maxWords,
}) async {
  final controller = TextEditingController(
    text: List<String>.filled(wordCount, 'mot').join(' '),
  );
  addTearDown(controller.dispose);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: WritingZone(
          controller: controller,
          onChanged: (_) {},
          wordCount: wordCount,
          minWords: minWords,
          maxWords: maxWords,
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('compteur de la zone de rédaction', () {
    testWidgets('59 mots en tâche 2 sont dans la plage, pas sous le minimum',
        (tester) async {
      await _pumpZone(tester, wordCount: 59, minWords: 40, maxWords: 90);

      expect(find.text('59 mots'), findsWidgets);
      expect(find.text('Dans la plage recommandée'), findsOneWidget);
    });

    testWidgets('39 mots en tâche 2 annoncent le mot qui manque',
        (tester) async {
      await _pumpZone(tester, wordCount: 39, minWords: 40, maxWords: 90);

      expect(find.text('39 mots'), findsWidgets);
      expect(find.text('Encore 1 mot min.'), findsOneWidget);
    });

    testWidgets('91 mots en tâche 2 annoncent le mot de trop', (tester) async {
      await _pumpZone(tester, wordCount: 91, minWords: 40, maxWords: 90);

      expect(find.text('1 mot de trop'), findsOneWidget);
    });
  });

  group('blocage de la soumission EE', () {
    test('le compteur et le blocage racontent la même chose', () {
      final t2 = _eeTask(2, 40, 90);

      // Sous le minimum : la zone annonce ce qui manque, la soumission est
      // fermée — les deux sur le même nombre.
      expect(isEeWordCountWithinBounds(t2, 39), isFalse);
      // Dans la plage : la zone dit « recommandée », la soumission s'ouvre.
      expect(isEeWordCountWithinBounds(t2, 59), isTrue);
      expect(isEeWordCountWithinBounds(t2, 91), isFalse);
    });
  });
}
