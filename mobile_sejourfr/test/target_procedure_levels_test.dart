import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';

/// Verrouille les paliers de langue exigés par démarche depuis la réforme du
/// 1er janvier 2026 (carte de résident passée de A2 à B1, naturalisation de B1
/// à B2). Un candidat qui révise le mauvais palier voit son dossier refusé :
/// ces trois valeurs ne doivent jamais régresser silencieusement.
void main() {
  group('TargetProcedure.tcfLevel — paliers exigés depuis le 01/01/2026', () {
    test('CSP exige A2', () {
      expect(TargetProcedure.csp.tcfLevel, 'A2');
    });

    test('CR exige B1 (et non plus A2)', () {
      expect(TargetProcedure.cr.tcfLevel, 'B1');
    });

    test('NAT exige B2 (et non plus B1)', () {
      expect(TargetProcedure.nat.tcfLevel, 'B2');
    });

    test('aucune démarche ne vise au-delà de B2 (plafond du TCF IRN)', () {
      for (final p in TargetProcedure.values) {
        expect(const ['A2', 'B1', 'B2'], contains(p.tcfLevel));
      }
    });
  });
}
