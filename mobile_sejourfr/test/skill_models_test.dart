import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';

/// Le module Compétences a son propre contrat, distinct de la notation des
/// productions complètes : quatre statuts de sujet (dont `TREATED`, l'état
/// honnête d'une production sans analyse IA), un verdict de critère unique, et
/// **jamais** de note /20 ni de niveau CECRL.
///
/// Ces tests verrouillent le décodage et les règles dérivées lues par l'UI.
Map<String, dynamic> _promptJson(Map<String, dynamic> extra) => {
      'id': 's1',
      'skillId': 'c1',
      'skillCode': 'EE1-C1',
      'skillTitle': 'Saluer et prendre congé',
      'section': 'EE',
      'taskCode': 'EE1',
      'taskTitle': 'Écrire un message court',
      'code': 'EE1-C1-S1',
      'title': 'Un mot à ta voisine',
      'context': 'Tu pars en vacances.',
      'instruction': 'Écris un mot à ta voisine.',
      'uniqueCriterion': 'Ouvrir et fermer le message.',
      'difficultyLevel': 'EASY',
      'displayOrder': 1,
      'status': 'TODO',
      'attemptCount': 0,
      ...extra,
    };

void main() {
  group('Enums du contrat', () {
    test('les libellés FR des statuts sont ceux du contrat', () {
      expect(SkillPromptStatus.todo.label, 'À faire');
      expect(SkillPromptStatus.treated.label, 'Fait');
      expect(SkillPromptStatus.validated.label, 'Validé');
      expect(SkillPromptStatus.toReinforce.label, 'À renforcer');
    });

    test("les libellés de l'auto-évaluation sont ceux du contrat", () {
      expect(SkillSelfEvaluation.reussi.label, 'Je pense avoir réussi');
      expect(SkillSelfEvaluation.incertain.label, 'Je ne suis pas sûr');
      expect(SkillSelfEvaluation.difficile.label, "J'ai eu du mal");
    });

    // Les libellés ne transitent pas par le réseau : le backend, le web et
    // l'admin en tiennent chacun une copie écrite à la main. Le verdict
    // `NOT_VALIDATED` avait ainsi dérivé en trois formulations à la fois
    // (« non validé » serveur, « non atteint » mobile, « à retravailler » web).
    // Le test jumeau côté web est `lib/skill-labels.test.ts`, côté backend
    // `SkillLabelsTest` — les trois figent EXACTEMENT les mêmes chaînes.
    test('le verdict du critère porte les libellés du contrat', () {
      expect(SkillCriterionStatus.validated.label, 'Critère validé');
      expect(SkillCriterionStatus.partial.label, 'Critère partiellement atteint');
      expect(SkillCriterionStatus.notValidated.label, 'Critère non atteint');
    });

    test('aucun verdict ne reprend « à retravailler » (mot d\'un statut de sujet)',
        () {
      for (final verdict in SkillCriterionStatus.values) {
        expect(verdict.label.toLowerCase(), isNot(contains('retravailler')));
      }
    });

    test('la difficulté décrit le sujet, elle ne juge pas le candidat', () {
      expect(SkillDifficulty.easy.label, 'Accessible');
      expect(SkillDifficulty.medium.label, 'Intermédiaire');
      expect(SkillDifficulty.hard.label, 'Exigeant');
    });

    test('les trois références portent leurs libellés d\'onglet', () {
      expect(SkillReferenceLevel.insufficient.label, 'Insuffisant');
      expect(SkillReferenceLevel.expected.label, 'Attendu');
      expect(SkillReferenceLevel.excellent.label, 'Très réussi');
    });

    test('seul TODO n\'est pas « traité » — TREATED compte dans la progression',
        () {
      expect(SkillPromptStatus.todo.isTreated, isFalse);
      expect(SkillPromptStatus.treated.isTreated, isTrue);
      expect(SkillPromptStatus.validated.isTreated, isTrue);
      expect(SkillPromptStatus.toReinforce.isTreated, isTrue);
    });

    test('RECORDED est un statut FINAL, pas une attente', () {
      expect(SkillAttemptStatut.recorded.isFinal, isTrue);
      expect(SkillAttemptStatut.evaluated.isFinal, isTrue);
      expect(SkillAttemptStatut.failed.isFinal, isTrue);
      expect(SkillAttemptStatut.submitted.isInProgress, isTrue);
      expect(SkillAttemptStatut.transcribing.isInProgress, isTrue);
      expect(SkillAttemptStatut.evaluating.isInProgress, isTrue);
    });

    test('une section construit le code de tâche attendu par l\'API', () {
      expect(SkillSection.ee.taskCode(1), 'EE1');
      expect(SkillSection.eo.taskCode(3), 'EO3');
    });

    test('un statut inconnu ne fait pas planter le décodage', () {
      expect(SkillPromptStatus.fromWire('WAT'), SkillPromptStatus.todo);
      expect(SkillAttemptStatut.fromWire('WAT'), SkillAttemptStatut.recorded);
      expect(SkillDifficulty.fromWire('WAT'), SkillDifficulty.medium);
    });
  });

  group('SkillDto', () {
    SkillDto build({
      required int promptCount,
      required int attemptedCount,
    }) =>
        SkillDto.fromJson({
          'id': 'c1',
          'section': 'EE',
          'taskCode': 'EE1',
          'code': 'EE1-C1',
          'title': 'Saluer et prendre congé',
          'description': 'Ouvrir et fermer un message court.',
          'generalCriterion': 'Le message est ouvert et fermé.',
          'targetLevel': 'A2',
          'displayOrder': 1,
          'promptCount': promptCount,
          'attemptedCount': attemptedCount,
          'validatedCount': 1,
          'toReinforceCount': 1,
        });

    test('la progression se compte en sujets TRAITÉS, pas validés', () {
      final skill = build(promptCount: 5, attemptedCount: 3);
      expect(skill.progress, closeTo(0.6, 1e-9));
      expect(skill.isComplete, isFalse);
    });

    test('une compétence sans sujet ne divise pas par zéro', () {
      final skill = build(promptCount: 0, attemptedCount: 0);
      expect(skill.progress, 0);
      expect(skill.isComplete, isFalse);
    });

    test('tous les sujets traités ⇒ complète', () {
      expect(build(promptCount: 5, attemptedCount: 5).isComplete, isTrue);
    });

    test(
        'l\'explication et le critère général sont deux textes distincts, '
        'rendus à deux endroits', () {
      final skill = build(promptCount: 5, attemptedCount: 0);
      expect(skill.description, 'Ouvrir et fermer un message court.');
      expect(skill.generalCriterion, 'Le message est ouvert et fermé.');
      expect(skill.generalCriterion, isNot(skill.description));
    });

    test('un backend sans generalCriterion ne fait pas planter le décodage',
        () {
      final skill = SkillDto.fromJson({
        'id': 'c1',
        'section': 'EE',
        'taskCode': 'EE1',
        'code': 'EE1-C1',
        'title': 'Saluer et prendre congé',
        'description': 'Ouvrir et fermer un message court.',
        'targetLevel': 'A2',
        'displayOrder': 1,
        'promptCount': 5,
        'attemptedCount': 0,
        'validatedCount': 0,
        'toReinforceCount': 0,
      });
      expect(skill.generalCriterion, isEmpty);
    });
  });

  group('SkillDetail', () {
    SkillDetail buildDetail(List<String> statuses) => SkillDetail.fromJson({
          'skill': {
            'id': 'c1',
            'section': 'EO',
            'taskCode': 'EO2',
            'code': 'EO2-C4',
            'title': 'Demander une information',
            'description': 'Formuler une demande claire.',
            'generalCriterion': 'La demande est explicite et polie.',
            'targetLevel': 'B1',
            'displayOrder': 4,
            'promptCount': statuses.length,
            'attemptedCount': 0,
            'validatedCount': 0,
            'toReinforceCount': 0,
          },
          'prompts': [
            for (var i = 0; i < statuses.length; i++)
              {
                'id': 's$i',
                'code': 'EO2-C4-S${i + 1}',
                'title': 'Sujet ${i + 1}',
                'uniqueCriterion': 'Poser une question directe.',
                'difficultyLevel': 'EASY',
                'displayOrder': i + 1,
                'status': statuses[i],
                'attemptCount': 0,
                'recommendedDurationSeconds': 45,
              },
          ],
        });

    test('firstTodo pointe le premier sujet jamais traité', () {
      final detail = buildDetail(['VALIDATED', 'TREATED', 'TODO', 'TODO']);
      expect(detail.firstTodo?.id, 's2');
    });

    test('firstTodo est nul quand tout a été vu au moins une fois', () {
      final detail = buildDetail(['VALIDATED', 'TO_REINFORCE', 'TREATED']);
      expect(detail.firstTodo, isNull);
    });
  });

  group('SkillAttemptDto', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {
          'id': 'a1',
          'skillPromptId': 's1',
          'skillPromptCode': 'EE1-C1-S1',
          'statut': 'EVALUATED',
          'analysisRequested': true,
          'createdAt': '2026-08-06T10:15:00Z',
          ...extra,
        };

    test('décode une analyse complète, sans note ni niveau', () {
      final attempt = SkillAttemptDto.fromJson(base({
        'writtenProduction': 'Bonjour Marie, je viens te dire au revoir.',
        'wordsCount': 8,
        'selfEvaluation': 'INCERTAIN',
        'criterionStatus': 'PARTIAL',
        'analysis': {
          'status': 'PARTIAL',
          'verdict': 'La salutation est là, la formule de congé manque.',
          'successPoint': 'Tu ouvres ton message par une salutation adaptée.',
          'improvementPriority': 'Termine par une formule de congé.',
          'improvedVersion': 'Bonjour Marie, … À bientôt !',
        },
      }));

      expect(attempt.analysis, isNotNull);
      expect(attempt.analysis!.status, SkillCriterionStatus.partial);
      expect(attempt.criterionStatus, SkillCriterionStatus.partial);
      expect(attempt.selfEvaluation, SkillSelfEvaluation.incertain);
      expect(attempt.productionText, startsWith('Bonjour Marie'));
    });

    test('une tentative RECORDED n\'a ni analyse ni verdict', () {
      final attempt = SkillAttemptDto.fromJson(base({
        'statut': 'RECORDED',
        'analysisRequested': false,
        'writtenProduction': 'Salut !',
      }));

      expect(attempt.statut, SkillAttemptStatut.recorded);
      expect(attempt.statut.isFinal, isTrue);
      expect(attempt.analysis, isNull);
      expect(attempt.criterionStatus, isNull);
    });

    test('en EO sans analyse, il n\'y a pas de transcription à relire', () {
      final attempt = SkillAttemptDto.fromJson(base({
        'statut': 'RECORDED',
        'analysisRequested': false,
        'audioUrl': 'https://r2.example/audio.wav',
        'audioDurationSec': 42,
      }));

      expect(attempt.productionText, isNull);
      expect(attempt.audioDurationSec, 42);
    });

    test('en EO analysée, la transcription tient lieu de production', () {
      final attempt = SkillAttemptDto.fromJson(base({
        'transcript': 'Bonjour, je voudrais savoir à quelle heure vous ouvrez.',
        'audioDurationSec': 38,
      }));

      expect(attempt.productionText, startsWith('Bonjour, je voudrais'));
    });
  });

  group('SkillPromptDto', () {
    test('porte la reprise et le sujet suivant, jamais les références', () {
      final prompt = SkillPromptDto.fromJson({
        'id': 's1',
        'skillId': 'c1',
        'skillCode': 'EE1-C1',
        'skillTitle': 'Saluer et prendre congé',
        'skillPromptCount': 5,
        'skillDescription': 'Ouvrir et fermer un message court.',
        'skillGeneralCriterion': 'Le message est ouvert et fermé.',
        'skillTargetLevel': 'A2',
        'section': 'EE',
        'taskCode': 'EE1',
        'taskTitle': 'Écrire un message court',
        'code': 'EE1-C1-S1',
        'title': 'Un mot à ta voisine',
        'context': 'Tu pars en vacances.',
        'instruction': 'Écris un mot à ta voisine.',
        'uniqueCriterion': 'Ouvrir et fermer le message.',
        'difficultyLevel': 'EASY',
        'displayOrder': 1,
        'status': 'TO_REINFORCE',
        'attemptCount': 2,
        'recommendedMinWords': 30,
        'recommendedMaxWords': 60,
        'lastAttemptId': 'a9',
        'nextPromptId': 's2',
      });

      expect(prompt.section, SkillSection.ee);
      expect(prompt.section.isEo, isFalse);
      expect(prompt.lastAttemptId, 'a9');
      expect(prompt.nextPromptId, 's2');
      expect(prompt.recommendedDurationSeconds, isNull);
    });

    test(
        'le sujet porte de quoi rendre « Sujet i/N », le palier et « Pourquoi '
        'cet exercice ? » sans charger la compétence', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'displayOrder': 3,
        'skillPromptCount': 5,
        'skillDescription': 'Ouvrir et fermer un message court.',
        'skillGeneralCriterion': 'Le message est ouvert et fermé.',
        'skillTargetLevel': 'A2',
      }));

      expect(prompt.displayOrder, 3);
      expect(prompt.skillPromptCount, 5);
      expect(prompt.skillDescription, 'Ouvrir et fermer un message court.');
      expect(prompt.skillGeneralCriterion, 'Le message est ouvert et fermé.');
      // Le palier vient du sujet : supprimer l'appel à la compétence ne doit
      // pas le faire disparaître de l'écran (spec §3 niveau 5).
      expect(prompt.skillTargetLevel, 'A2');
      // Le critère du sujet reste celui du sujet, jamais celui de la compétence.
      expect(prompt.uniqueCriterion, isNot(prompt.skillGeneralCriterion));
    });

    test('un backend sans les champs de compétence reste décodable', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({}));

      expect(prompt.skillPromptCount, 0);
      expect(prompt.skillDescription, isEmpty);
      expect(prompt.skillGeneralCriterion, isEmpty);
      expect(prompt.skillTargetLevel, isEmpty);
    });
  });

  group('SkillAnalysisQuotaDto', () {
    test('remaining == -1 vaut illimité et ne bloque rien', () {
      final quota = SkillAnalysisQuotaDto.fromJson({
        'premium': true,
        'unlimited': true,
        'freeAnalysesTotal': 3,
        'freeAnalysesUsed': 0,
        'remaining': -1,
      });
      expect(quota.isUnlimited, isTrue);
      expect(quota.canAnalyse, isTrue);
    });

    test('un compte gratuit garde ses analyses offertes', () {
      final quota = SkillAnalysisQuotaDto.fromJson({
        'premium': false,
        'unlimited': false,
        'freeAnalysesTotal': 3,
        'freeAnalysesUsed': 1,
        'remaining': 2,
      });
      expect(quota.isUnlimited, isFalse);
      expect(quota.canAnalyse, isTrue);
      expect(quota.remaining, 2);
    });

    test('quota épuisé ⇒ analyse verrouillée (mais le sujet reste ouvert)', () {
      final quota = SkillAnalysisQuotaDto.fromJson({
        'premium': false,
        'unlimited': false,
        'freeAnalysesTotal': 3,
        'freeAnalysesUsed': 3,
        'remaining': 0,
      });
      expect(quota.canAnalyse, isFalse);
    });
  });
}
