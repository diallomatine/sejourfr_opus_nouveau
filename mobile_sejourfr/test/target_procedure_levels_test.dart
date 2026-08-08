import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';

/// Verrouille les paliers de langue exigés par démarche depuis la réforme du
/// 1er janvier 2026 (carte de résident passée de A2 à B1, naturalisation de B1
/// à B2). Un candidat qui révise le mauvais palier voit son dossier refusé :
/// ces trois valeurs ne doivent jamais régresser silencieusement.
///
/// C'est le **miroir mobile** de la table portée par l'enum `TargetProcedure`
/// côté backend. `TargetProcedureTest` (Java) et `lib/target-level.test.ts`
/// (web) tiennent les leurs, sur exactement les mêmes correspondances — même
/// technique que `skill_models_test.dart` pour les libellés Compétences. Un
/// échec ici veut dire que la correspondance a bougé et que les deux autres
/// copies doivent bouger dans la **même passe**.
void main() {
  group('TargetProcedure — paliers exigés depuis le 01/01/2026', () {
    test('CSP exige A2', () {
      expect(TargetProcedure.csp.requiredLevel, TargetLevel.a2);
      expect(TargetProcedure.csp.tcfLevel, 'A2');
    });

    test('CR exige B1 (et non plus A2)', () {
      expect(TargetProcedure.cr.requiredLevel, TargetLevel.b1);
      expect(TargetProcedure.cr.tcfLevel, 'B1');
    });

    test('NAT exige B2 (et non plus B1)', () {
      expect(TargetProcedure.nat.requiredLevel, TargetLevel.b2);
      expect(TargetProcedure.nat.tcfLevel, 'B2');
    });

    test('aucune démarche ne vise au-delà de B2 (plafond du TCF IRN)', () {
      for (final p in TargetProcedure.values) {
        expect(const ['A2', 'B1', 'B2'], contains(p.tcfLevel));
      }
    });

    test('le libellé court dérive du palier typé : une seule table', () {
      for (final p in TargetProcedure.values) {
        expect(p.tcfLevel, p.requiredLevel.wire);
      }
    });

    test("l'ordre des paliers est celui du CECRL : tout le plancher en dépend",
        () {
      expect(TargetLevel.values,
          [TargetLevel.a2, TargetLevel.b1, TargetLevel.b2]);
    });
  });

  group('niveauVise — la démarche fait plancher', () {
    // LE DÉFAUT D'ORIGINE. Un compte NAT portant un `targetLevel` hérité à B1
    // était réputé « au niveau visé » dès qu'il écrivait du B1 : plus aucun
    // texte modèle sur l'écran de résultat, et le candidat n'était jamais tiré
    // vers le B2 dont sa démarche a besoin.
    test('naturalisation + niveau déclaré plus bas ⇒ B2', () {
      expect(
        TargetProcedure.niveauVise(TargetProcedure.nat, TargetLevel.b1),
        TargetLevel.b2,
      );
      expect(
        TargetProcedure.niveauVise(TargetProcedure.nat, TargetLevel.a2),
        TargetLevel.b2,
      );
    });

    test('viser plus haut que sa démarche est respecté', () {
      expect(
        TargetProcedure.niveauVise(TargetProcedure.csp, TargetLevel.b2),
        TargetLevel.b2,
      );
      expect(
        TargetProcedure.niveauVise(TargetProcedure.csp, TargetLevel.b1),
        TargetLevel.b1,
      );
    });

    test('démarche seule ⇒ le palier qu\'elle exige', () {
      expect(
        TargetProcedure.niveauVise(TargetProcedure.cr, null),
        TargetLevel.b1,
      );
    });

    test('sans démarche ⇒ le niveau déclaré, seul', () {
      expect(TargetProcedure.niveauVise(null, TargetLevel.b1), TargetLevel.b1);
    });

    test('rien de connu ⇒ rien de deviné', () {
      expect(TargetProcedure.niveauVise(null, null), isNull);
    });

    test('un couple cohérent est un point fixe', () {
      for (final p in TargetProcedure.values) {
        expect(TargetProcedure.niveauVise(p, p.requiredLevel), p.requiredLevel);
      }
    });
  });
}
