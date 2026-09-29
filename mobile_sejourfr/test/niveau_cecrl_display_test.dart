import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/full_tcf_exam.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';

/// Regles PURES derriere l'affichage d'un niveau : son libelle court, sa
/// teinte, et le decompte d'epreuves retenues d'un examen complet. Aucun
/// widget monte ici — les ecrans sont verifies a la main.
void main() {
  group('NiveauCecrl.shortName', () {
    test('A1 non atteint se rend « <A1 », jamais « A1 »', () {
      expect(NiveauCecrl.a1NonAtteint.shortName, '<A1');
      expect(NiveauCecrl.a1.shortName, 'A1');
    });

    test('les autres paliers gardent leur code', () {
      expect(NiveauCecrl.a2.shortName, 'A2');
      expect(NiveauCecrl.b1.shortName, 'B1');
      expect(NiveauCecrl.b2.shortName, 'B2');
    });
  });

  group('CecrlColor', () {
    test('le vert dit B2, pas « termine »', () {
      expect(NiveauCecrl.b2.color, AppColors.green);
      for (final l in [
        NiveauCecrl.a1NonAtteint,
        NiveauCecrl.a1,
        NiveauCecrl.a2,
        NiveauCecrl.b1,
      ]) {
        expect(l.color, isNot(AppColors.green), reason: l.wire);
      }
    });
  });

  group('FullTcfExamResponse — perimetre du niveau final', () {
    Map<String, dynamic> payload({Map<String, dynamic> extra = const {}}) =>
        <String, dynamic>{
          'id': 'exam-1',
          'startedAt': '2026-08-05T10:00:00Z',
          'finishedAt': null,
          'timerStartedAt': null,
          'finalCecrlLevel': 'B1',
          'status': 'COMPLETED',
          'subAttempts': <dynamic>[],
          ...extra,
        };

    test('champs absents (vieux backend) → aucun decompte, non partiel', () {
      final exam = FullTcfExamResponse.fromJson(payload());
      expect(exam.epreuvesCountedInFinalLevel, isNull);
      expect(exam.epreuvesExpected, isNull);
      expect(exam.finalLevelPartial, isFalse);
    });

    test('perimetre partiel repris tel quel', () {
      final exam = FullTcfExamResponse.fromJson(payload(extra: {
        'epreuvesCountedInFinalLevel': 3,
        'epreuvesExpected': 4,
        'finalLevelPartial': true,
      }));
      expect(exam.epreuvesCountedInFinalLevel, 3);
      expect(exam.epreuvesExpected, 4);
      expect(exam.finalLevelPartial, isTrue);
    });

    test('resume d\'historique : le drapeau partiel est lu', () {
      final summary = FullTcfExamSummary.fromJson(<String, dynamic>{
        'id': 'exam-1',
        'startedAt': '2026-08-05T10:00:00Z',
        'finishedAt': null,
        'finalCecrlLevel': 'A2',
        'status': 'COMPLETED',
        'finalLevelPartial': true,
      });
      expect(summary.finalLevelPartial, isTrue);
    });
  });
}
