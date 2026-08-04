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
        'points_a_ameliorer': [
          {
            'constat': 'Vos idées sont juxtaposées.',
            'comment': 'Remplacez le point entre deux idées liées par « et ».',
            'exemple': {
              'avant': 'Je cherche un travail. Je suis motivé.',
              'apres': 'Je cherche un travail et je suis motivé.',
            },
          },
        ],
        'exemples_corriges': [
          {
            'original': 'Il fait beau. Je sors.',
            'corrige': 'Comme il fait beau, je sors.',
            'explication': 'La subordonnée relie les deux idées.',
            'gain': 'emploie une subordonnée, marqueur attendu au B1',
          },
        ],
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
      expect(feedback.pointsAAmeliorer, hasLength(1));
    });

    test('une priorité porte la technique et sa démonstration', () {
      final priorite =
          EvaluationResult.fromJson(json).feedback.pointsAAmeliorer.single;

      expect(priorite.constat, 'Vos idées sont juxtaposées.');
      expect(priorite.comment, contains('Remplacez le point'));
      expect(priorite.exemple!.avant, 'Je cherche un travail. Je suis motivé.');
      expect(priorite.exemple!.apres, 'Je cherche un travail et je suis motivé.');
      expect(priorite.isTeaching, isTrue);
    });

    test('un exemple corrigé expose ce qu\'il démontre de plus', () {
      final exemple =
          EvaluationResult.fromJson(json).feedback.exemplesCorriges.single;

      expect(exemple.gain, 'emploie une subordonnée, marqueur attendu au B1');
    });
  });

  group('points_a_ameliorer : les deux formes portées en base', () {
    EvaluationFeedback feedbackWith(List<Object?> points) =>
        EvaluationResult.fromJson(<String, dynamic>{
          'feedback': <String, dynamic>{'points_a_ameliorer': points},
        }).feedback;

    test('une chaîne devient un constat seul, sans technique inventée', () {
      final priorite = feedbackWith(['Penser à inviter']).pointsAAmeliorer.single;

      expect(priorite.constat, 'Penser à inviter');
      expect(priorite.comment, isNull);
      expect(priorite.exemple, isNull);
      expect(priorite.isTeaching, isFalse);
    });

    test('les deux formes cohabitent dans une même liste', () {
      final priorites = feedbackWith([
        'Penser à inviter',
        {'constat': 'Idées juxtaposées.', 'comment': 'Ajoutez « et ».'},
      ]).pointsAAmeliorer;

      expect(priorites.map((p) => p.constat),
          ['Penser à inviter', 'Idées juxtaposées.']);
      expect(priorites.first.comment, isNull);
      expect(priorites.last.comment, 'Ajoutez « et ».');
    });

    test('une entrée vide ou illisible est ignorée, pas rendue à blanc', () {
      final priorites = feedbackWith([
        '   ',
        null,
        42,
        <String, dynamic>{'comment': 'technique sans constat'},
        <String, dynamic>{'constat': 'Reste lisible'},
      ]).pointsAAmeliorer;

      expect(priorites.map((p) => p.constat), ['Reste lisible']);
    });

    test('un exemple incomplet ne s\'affiche pas à moitié', () {
      final priorite = feedbackWith([
        {
          'constat': 'Idées juxtaposées.',
          'exemple': {'avant': 'Je sors.'},
        },
      ]).pointsAAmeliorer.single;

      expect(priorite.exemple, isNull);
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

  group('correspondance avec la grille officielle du TCF', () {
    Map<String, dynamic> bilanJson(Object? correspondance, {String? niveau}) =>
        <String, dynamic>{
          'attemptId': 'a1',
          'epreuve': 'TCF_EE',
          'exam': true,
          'evaluatedCount': 3,
          'expectedCount': 3,
          'finished': true,
          'moyenneSur20': 12.5,
          'niveauGlobal': niveau,
          'correspondanceTcf': correspondance,
        };

    test('le bilan expose la fourchette envoyée par le backend', () {
      final bilan = ProductionBilan.fromJson(bilanJson(
        <String, dynamic>{'niveau': 'B1', 'scoreTcfMin': 6, 'scoreTcfMax': 9},
        niveau: 'B1',
      ));

      expect(bilan.correspondanceTcf, isNotNull);
      expect(bilan.correspondanceTcf!.niveau, NiveauCecrl.b1);
      expect(bilan.correspondanceTcf!.scoreTcfMin, 6);
      expect(bilan.correspondanceTcf!.scoreTcfMax, 9);
      expect(
        bilan.correspondanceTcf!.phrase,
        'Au TCF, le niveau B1 correspond à une note de 6 à 9 sur 20.',
      );
    });

    test('une fourchette d\'un seul point se formule au singulier', () {
      const c = CorrespondanceTcf(
        niveau: NiveauCecrl.a1,
        scoreTcfMin: 1,
        scoreTcfMax: 1,
      );

      expect(c.phrase, 'Au TCF, le niveau A1 correspond à la note de 1 sur 20.');
    });

    test('un bilan sans niveau exploitable n\'a pas de correspondance', () {
      expect(ProductionBilan.fromJson(bilanJson(null)).correspondanceTcf, isNull);
      expect(
        ProductionBilan.fromJson(bilanJson(<String, dynamic>{'niveau': 'B1'}))
            .correspondanceTcf,
        isNull,
      );
    });
  });
}
