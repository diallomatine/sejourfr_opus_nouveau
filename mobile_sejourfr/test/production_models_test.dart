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
        'confiance_raisons': [
          'transcription temps réel partiellement incertaine'
        ],
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
      expect(
          acc.pistesNonAbordees.map((p) => p.libelle), ['Loyer non mentionné']);
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
      expect(
          priorite.exemple!.apres, 'Je cherche un travail et je suis motivé.');
      expect(priorite.isTeaching, isTrue);
    });

    test('un exemple corrigé expose ce qu\'il démontre de plus', () {
      final exemple =
          EvaluationResult.fromJson(json).feedback.exemplesCorriges.single;

      expect(exemple.gain, 'emploie une subordonnée, marqueur attendu au B1');
    });
  });

  group('rubriques v8 : verdict d\'objectif et version améliorée', () {
    EvaluationFeedback parse(Map<String, dynamic> feedback) =>
        EvaluationResult.fromJson(<String, dynamic>{'feedback': feedback})
            .feedback;

    test('mappe le verdict, son résumé et la version réécrite', () {
      final feedback = parse(<String, dynamic>{
        'accomplissement': <String, dynamic>{
          'objectif': 'PARTIELLEMENT_ATTEINT',
          'objectif_resume': 'Vous annoncez la nouvelle sans inviter.',
          'points_traites': [
            {'libelle': 'Nouvelle annoncée', 'obligatoire': true},
          ],
        },
        'version_amelioree': 'Bonjour Marie, je viens de déménager.',
      });

      final acc = feedback.accomplissement!;
      expect(acc.objectif, ObjectifAccomplissement.partiellementAtteint);
      expect(acc.objectifResume, 'Vous annoncez la nouvelle sans inviter.');
      expect(acc.hasObjectif, isTrue);
      expect(feedback.versionAmelioree, 'Bonjour Marie, je viens de déménager.');
    });

    test('les trois verdicts du contrat sont reconnus', () {
      for (final (wire, expected) in [
        ('ATTEINT', ObjectifAccomplissement.atteint),
        ('PARTIELLEMENT_ATTEINT', ObjectifAccomplissement.partiellementAtteint),
        ('NON_ATTEINT', ObjectifAccomplissement.nonAtteint),
      ]) {
        final acc = parse(<String, dynamic>{
          'accomplissement': <String, dynamic>{'objectif': wire},
        }).accomplissement!;
        expect(acc.objectif, expected);
      }
    });

    test('une évaluation legacy n\'invente ni verdict ni réécriture', () {
      final feedback = parse(<String, dynamic>{
        'accomplissement': <String, dynamic>{
          'points_traites': [
            {'libelle': 'Nouvelle annoncée', 'obligatoire': true},
          ],
        },
      });

      final acc = feedback.accomplissement!;
      expect(acc.objectif, isNull);
      expect(acc.objectifResume, isNull);
      expect(acc.hasObjectif, isFalse);
      // La check-list, elle, reste lisible : les deux niveaux sont independants.
      expect(acc.isEmpty, isFalse);
      expect(feedback.versionAmelioree, isNull);
    });

    test('un verdict illisible ou vide ne casse pas le parsing', () {
      for (final raw in <Object?>[null, '', '   ', 'PEUT_MIEUX_FAIRE', 42]) {
        final acc = parse(<String, dynamic>{
          'accomplissement': <String, dynamic>{'objectif': raw},
        }).accomplissement!;
        expect(acc.objectif, isNull, reason: 'objectif = $raw');
      }
    });

    test('une version améliorée vide vaut absente : pas de bloc à blanc', () {
      expect(parse(<String, dynamic>{'version_amelioree': '   '})
          .versionAmelioree, isNull);
      expect(parse(<String, dynamic>{'version_amelioree': 12})
          .versionAmelioree, isNull);
    });

    test('un feedback sans aucun champ du contrat courant reste parsable', () {
      final feedback = parse(const <String, dynamic>{});

      expect(feedback.accomplissement, isNull);
      expect(feedback.versionAmelioree, isNull);
      expect(feedback.pointsForts, isEmpty);
      expect(feedback.pointsAAmeliorer, isEmpty);
      expect(feedback.scoresCriteres, isEmpty);
      expect(feedback.avertissements, isEmpty);
    });
  });

  group('points_a_ameliorer : les deux formes portées en base', () {
    EvaluationFeedback feedbackWith(List<Object?> points) =>
        EvaluationResult.fromJson(<String, dynamic>{
          'feedback': <String, dynamic>{'points_a_ameliorer': points},
        }).feedback;

    test('une chaîne devient un constat seul, sans technique inventée', () {
      final priorite =
          feedbackWith(['Penser à inviter']).pointsAAmeliorer.single;

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

  test('l\'échelle TCF IRN plafonne les anciens niveaux C1/C2 à B2', () {
    expect(NiveauCecrl.b2.scaleIndex, 3);
    expect(NiveauCecrl.c1.scaleIndex, NiveauCecrl.b2.scaleIndex);
    expect(NiveauCecrl.c2.scaleIndex, NiveauCecrl.b2.scaleIndex);
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

      expect(
          c.phrase, 'Au TCF, le niveau A1 correspond à la note de 1 sur 20.');
    });

    test('un bilan sans niveau exploitable n\'a pas de correspondance', () {
      expect(
          ProductionBilan.fromJson(bilanJson(null)).correspondanceTcf, isNull);
      expect(
        ProductionBilan.fromJson(bilanJson(<String, dynamic>{'niveau': 'B1'}))
            .correspondanceTcf,
        isNull,
      );
    });
  });

  group('bornes strictes EE du TCF IRN', () {
    ProductionTaskDto task(int numero, int min, int max) => ProductionTaskDto(
          id: 'ee-t$numero',
          epreuve: EpreuveType.tcfEe,
          tacheNumero: numero,
          niveauCible: 'B1',
          consigne: 'Consigne',
          motsMin: min,
          motsMax: max,
        );

    test('T1 accepte 30 et 60, refuse 29 et 61', () {
      final t1 = task(1, 30, 60);

      expect(isEeWordCountWithinBounds(t1, 29), isFalse);
      expect(isEeWordCountWithinBounds(t1, 30), isTrue);
      expect(isEeWordCountWithinBounds(t1, 60), isTrue);
      expect(isEeWordCountWithinBounds(t1, 61), isFalse);
    });

    // Le volume officiel du TCF IRN en tâches 2 et 3 est 40-90 mots. Le minimum
    // a valu 60 jusqu'à V724 : une copie de 40 à 59 mots, parfaitement
    // recevable, était refusée. Les cas à 59 sont cette régression.
    test('T2 et T3 acceptent 40, 59 et 90, refusent 39 et 91', () {
      for (final numero in [2, 3]) {
        final current = task(numero, 40, 90);
        expect(isEeWordCountWithinBounds(current, 39), isFalse);
        expect(isEeWordCountWithinBounds(current, 40), isTrue);
        expect(isEeWordCountWithinBounds(current, 59), isTrue);
        expect(isEeWordCountWithinBounds(current, 90), isTrue);
        expect(isEeWordCountWithinBounds(current, 91), isFalse);
      }
    });
  });
}
