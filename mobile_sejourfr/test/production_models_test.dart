import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';

/// Le contrat de notation v4 ajoute trois champs a `EvaluationResultDto` ENTRE
/// `noteSurVingt` et `feedback` cote Java. Ces tests verrouillent deux choses :
/// le parsing se fait par cle JSON (l'ordre du record n'a aucun effet), et une
/// evaluation v3 deja en base reste lisible avec les nouveaux champs a null.
void main() {
  group('EvaluationResult v4', () {
    final json = <String, dynamic>{
      'noteSurVingt': 13.5,
      'niveauObserve': 'B1',
      'confiance': 'MOYENNE',
      'avertissementNiveau':
          'Estimation pédagogique portant sur cette seule tâche.',
      'feedback': <String, dynamic>{
        'note_globale': 13.5,
        'confiance': 'MOYENNE',
        'confiance_raisons': ['transcription temps réel partiellement incertaine'],
        'accomplissement': <String, dynamic>{
          'points_traites': [
            {'libelle': 'Nouvelle annoncée', 'obligatoire': true},
            {'libelle': 'Quartier évoqué', 'obligatoire': false},
          ],
          'points_oublies': [
            {'libelle': 'Invitation absente', 'obligatoire': true},
            {'libelle': 'Loyer non mentionné', 'obligatoire': false},
          ],
        },
        'scores_criteres': [
          {
            'code': 'realisation_consigne',
            'label': 'Réalisation de la consigne',
            'note_sur_20': 12,
            'bande': 'SATISFAISANT',
            'commentaire': 'Deux points sur trois sont traités.',
            'preuve': "j'ai trouvé un appartement",
          },
        ],
        'points_a_ameliorer': ['Penser à inviter', 'Varier les connecteurs'],
        'avertissements': [
          'Évaluation fondée sur la transcription : la voix n\'est pas analysée.',
        ],
      },
    };

    test('mappe les trois champs de niveau et la confiance', () {
      final eval = EvaluationResult.fromJson(json);

      expect(eval.noteSurVingt, 13.5);
      expect(eval.niveauObserve, NiveauCecrl.b1);
      expect(eval.confiance, ConfianceEvaluation.moyenne);
      expect(eval.avertissementNiveau, isNotNull);
      expect(eval.hasNiveauObserve, isTrue);
    });

    test('distingue points obligatoires et pistes', () {
      final acc = EvaluationResult.fromJson(json).feedback.accomplissement!;

      expect(acc.pointsTraites, hasLength(2));
      expect(acc.manques.map((p) => p.libelle), ['Invitation absente']);
      expect(acc.pistesNonAbordees.map((p) => p.libelle), ['Loyer non mentionné']);
    });

    test('expose la bande et la preuve du critere', () {
      final critere =
          EvaluationResult.fromJson(json).feedback.scoresCriteres.single;

      expect(critere.code, 'realisation_consigne');
      expect(critere.bande, BandeCritere.satisfaisant);
      expect(critere.preuve, "j'ai trouvé un appartement");
      expect(critere.noteSurVingt, 12);
    });

    test('remonte les raisons de confiance et les avertissements', () {
      final feedback = EvaluationResult.fromJson(json).feedback;

      expect(feedback.confiance, ConfianceEvaluation.moyenne);
      expect(feedback.confianceRaisons, hasLength(1));
      expect(feedback.avertissements, hasLength(1));
      expect(feedback.pointsAAmeliorer, hasLength(2));
    });
  });

  group('EvaluationResult v3 (retrocompatibilite)', () {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 14,
      'feedback': <String, dynamic>{
        'note_globale': 14,
        'scores_criteres': [
          {
            'code': 'lexique',
            'note_sur_20': 13,
            'commentaire': 'Vocabulaire correct.',
          },
        ],
        'points_forts': ['Message clair'],
      },
    });

    test('laisse niveau, confiance et avertissement a null', () {
      expect(eval.niveauObserve, isNull);
      expect(eval.confiance, isNull);
      expect(eval.avertissementNiveau, isNull);
      expect(eval.hasNiveauObserve, isFalse);
    });

    test('n\'invente ni accomplissement, ni bande, ni preuve', () {
      expect(eval.feedback.accomplissement, isNull);
      expect(eval.feedback.confianceRaisons, isEmpty);

      final critere = eval.feedback.scoresCriteres.single;
      expect(critere.bande, isNull);
      expect(critere.preuve, isNull);
      expect(critere.noteSurVingt, 13);
    });
  });

  test('un niveau sans confiance n\'est jamais affichable', () {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 12,
      'niveauObserve': 'B1',
      'feedback': <String, dynamic>{},
    });

    expect(eval.niveauObserve, NiveauCecrl.b1);
    expect(eval.confiance, isNull);
    expect(eval.hasNiveauObserve, isFalse);
  });
}
