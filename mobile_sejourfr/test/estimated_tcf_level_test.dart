import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/dashboard_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';

/// Fige la **mention de périmètre** du niveau TCF estimé, côté mobile.
///
/// La chaîne ne transite pas par le réseau : le mobile et le web en tiennent
/// chacun une copie écrite à la main (`estimatedTcfLevelScopeLabel`, ici et
/// dans `web_sejoufr/lib/types.ts`). Rien n'empêcherait une couche de dériver —
/// c'est exactement comme ça que les libellés du module Compétences avaient
/// décroché. Le miroir web est `lib/estimated-tcf-level.test.ts`, sur
/// **exactement** les mêmes chaînes.
///
/// Un échec ici veut dire que la mention a bougé et que l'autre copie doit
/// bouger dans la **même passe**.
DashboardSummary _summary({
  required int counted,
  required int expected,
  required bool partial,
  NiveauCecrl? level = NiveauCecrl.b1,
}) =>
    DashboardSummary(
      currentStreakDays: 0,
      recordStreakDays: 0,
      activeToday: false,
      mockExamsTotal: 0,
      civiqueMockExams: 0,
      tcfMockExams: 0,
      globalSuccessPercent: null,
      estimatedTcfLevel: level,
      estimatedTcfLevelEpreuvesCounted: counted,
      estimatedTcfLevelEpreuvesExpected: expected,
      estimatedTcfLevelPartial: partial,
      civique: const [],
      tcf: const [],
    );

void main() {
  group('mention de périmètre du niveau TCF estimé', () {
    test('les deux formes sont gelées, au caractère près', () {
      expect(
        estimatedTcfLevelScopeLabel(
            _summary(counted: 1, expected: 4, partial: true)),
        "D'après 1 épreuve sur 4",
      );
      expect(
        estimatedTcfLevelScopeLabel(
            _summary(counted: 3, expected: 4, partial: true)),
        "D'après 3 épreuves sur 4",
      );
    });

    test('accorde le pluriel à partir de deux épreuves', () {
      expect(
        estimatedTcfLevelScopeLabel(
            _summary(counted: 2, expected: 4, partial: true)),
        "D'après 2 épreuves sur 4",
      );
    });

    // LE DÉFAUT D'ORIGINE : quatre épreuves sur quatre, le niveau porte sur
    // tout — annoter là serait inventer une réserve.
    test("un niveau complet n'est pas annoté", () {
      expect(
        estimatedTcfLevelScopeLabel(
            _summary(counted: 4, expected: 4, partial: false)),
        isNull,
      );
    });

    test('aucune épreuve : le niveau vaut déjà « — », rien à annoter', () {
      expect(
        estimatedTcfLevelScopeLabel(_summary(
            counted: 0, expected: 4, partial: false, level: null)),
        isNull,
      );
    });

    // Le drapeau vient du serveur et c'est LUI qui décide : un front ne
    // recompte pas le périmètre, il l'affiche.
    test('le drapeau serveur fait foi, jamais un décompte refait côté app', () {
      expect(
        estimatedTcfLevelScopeLabel(
            _summary(counted: 1, expected: 4, partial: false)),
        isNull,
      );
    });

    test("des compteurs absurdes ou un résumé manquant n'affichent rien", () {
      expect(
        estimatedTcfLevelScopeLabel(
            _summary(counted: 0, expected: 0, partial: true)),
        isNull,
      );
      expect(estimatedTcfLevelScopeLabel(null), isNull);
    });

    // Aucun chiffre de barème ne doit se glisser dans cette mention : c'est un
    // décompte d'épreuves, pas une note.
    test('ne parle jamais d\'une note', () {
      for (final counted in [1, 2, 3]) {
        final label = estimatedTcfLevelScopeLabel(
                _summary(counted: counted, expected: 4, partial: true)) ??
            '';
        expect(label, isNot(contains('/20')));
        expect(label.toLowerCase(), isNot(contains('note')));
      }
    });
  });

  group('DashboardSummary.fromJson — périmètre', () {
    test('lit les trois champs serveur', () {
      final s = DashboardSummary.fromJson(const {
        'estimatedTcfLevel': 'B1',
        'estimatedTcfLevelEpreuvesCounted': 2,
        'estimatedTcfLevelEpreuvesExpected': 4,
        'estimatedTcfLevelPartial': true,
      });

      expect(s.estimatedTcfLevelEpreuvesCounted, 2);
      expect(s.estimatedTcfLevelEpreuvesExpected, 4);
      expect(s.estimatedTcfLevelPartial, isTrue);
    });

    // Un serveur d'avant ce champ ne doit pas faire tomber l'app ni inventer
    // une réserve : absence ⇒ pas de mention.
    test('un dashboard sans ces champs ne signale rien', () {
      final s = DashboardSummary.fromJson(const {'estimatedTcfLevel': 'B1'});

      expect(s.estimatedTcfLevelPartial, isFalse);
      expect(estimatedTcfLevelScopeLabel(s), isNull);
    });
  });
}
