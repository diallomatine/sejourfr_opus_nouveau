import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';

void main() {
  /// Libellés **gelés**, miroir mot pour mot du web
  /// (`LEARNING_PLAN_SKILL_STATUS_LABEL`, `web_sejoufr/lib/diagnostic.ts`).
  /// Ces chaînes ne transitent pas par le réseau : chaque front en tient une
  /// copie écrite à la main, donc rien n'empêche une couche de dériver — et
  /// c'est arrivé (le mobile disait « À évaluer / Priorité »). Un échec ici
  /// veut dire que l'autre copie doit bouger dans la **même passe**.
  test('les statuts de compétence portent les libellés du web', () {
    expect(LearningPlanSkillStatus.notObserved.label, 'Non observée');
    expect(LearningPlanSkillStatus.priority.label, 'Prioritaire');
    expect(LearningPlanSkillStatus.toReinforce.label, 'À renforcer');
    expect(LearningPlanSkillStatus.solid.label, 'Solide');
  });

  /// Même contrat pour les deux verdicts des cartes « Vos productions »
  /// (`DIAGNOSTIC_TASK_COMPLETION_LABEL` / `DIAGNOSTIC_COMMUNICATION_LABEL`).
  /// Les deux fronts les rendent, donc les deux copies doivent coïncider : le
  /// mobile avait écrit « Message qui passe » là où le web dit « Message clair ».
  test('les verdicts de production portent les libellés du web', () {
    expect(DiagnosticTaskCompletion.completed.label, 'Consigne accomplie');
    expect(
      DiagnosticTaskCompletion.partial.label,
      'Consigne partiellement accomplie',
    );
    expect(DiagnosticTaskCompletion.notCompleted.label, 'Consigne non accomplie');

    expect(DiagnosticCommunicationStatus.effective.label, 'Message clair');
    expect(
      DiagnosticCommunicationStatus.partial.label,
      'Message compris avec effort',
    );
    expect(
      DiagnosticCommunicationStatus.ineffective.label,
      'Message difficile à suivre',
    );
  });

  group('DiagnosticJourney.fromJson', () {
    test('décode l’état serveur avant démarrage sans inventer de session', () {
      final journey = DiagnosticJourney.fromJson({
        'sessionId': null,
        'diagnosticCode': 'INITIAL_TCF',
        'diagnosticVersion': 1,
        'status': 'NOT_STARTED',
        'nextStep': 'PRESENTATION',
        'written': null,
        'oral': null,
        'result': null,
        'canRetry': false,
      });

      expect(journey.sessionId, isNull);
      expect(journey.status, DiagnosticJourneyStatus.notStarted);
      expect(journey.nextStep, DiagnosticStep.presentation);
      expect(journey.completedExerciseCount, 0);
    });

    test('décode exercices, résultat et trois priorités au maximum', () {
      final journey = DiagnosticJourney.fromJson({
        'sessionId': 'session-1',
        'diagnosticCode': 'INITIAL_TCF',
        'diagnosticVersion': 1,
        'status': 'COMPLETED',
        'nextStep': 'RESULT',
        'written': _exerciseJson('TCF_EE', 'sub-ee'),
        'oral': _exerciseJson('TCF_EO', 'sub-eo'),
        'result': {
          'written': _productionResultJson('B1', 'EE'),
          'oral': _productionResultJson('A2', 'EO'),
          'strengths': [' Consigne comprise ', 'Message clair'],
          'priorities': [
            for (var index = 0; index < 4; index++)
              _skillJson('skill-$index', index.isEven ? 'EE' : 'EO'),
          ],
          'mainPriorityExplanation': 'Développer les raisons.',
          'nextAction': _exerciseRecommendationJson(),
        },
        'startedAt': '2026-08-09T10:00:00Z',
        'completedAt': '2026-08-09T10:08:00Z',
        'canRetry': false,
      });

      expect(journey.completedExerciseCount, 2);
      expect(journey.written?.wordsMin, 100);
      expect(journey.oral?.epreuve, EpreuveType.tcfEo);
      expect(journey.result?.written?.levelEstimate, NiveauCecrl.b1);
      expect(journey.result?.oral?.skills.single.section, SkillSection.eo);
      expect(journey.result?.priorities, hasLength(3));
      expect(journey.result?.strengths.first, 'Consigne comprise');
      expect(journey.result?.nextAction?.estimatedMinutes, 4);
    });
  });

  test('LearningPlan décode le plan actif sans recalcul client', () {
    final plan = LearningPlan.fromJson({
      'state': 'ACTIVE',
      'diagnosticSessionId': 'session-1',
      'diagnosticCompletedAt': '2026-08-09T10:08:00Z',
      'currentPriority': {
        'skillId': 'skill-1',
        'skillCode': 'EE_ARG',
        'title': 'Développer un argument',
        'section': 'EE',
        'status': 'PRIORITY',
        'explanation': 'La raison est encore trop courte.',
        'evidence': 'Parce que c’est utile.',
        'confidence': 'HIGH',
        'observedAt': '2026-08-09T10:08:00Z',
        'recommendedExercise': _exerciseRecommendationJson(),
        'promptCount': 5,
        'attemptedCount': 2,
        'validatedCount': 1,
      },
      'nextPriorities': [],
      'observedSkills': [
        {
          'skillId': 'skill-1',
          'skillCode': 'EE_ARG',
          'title': 'Développer un argument',
          'section': 'EE',
          'status': 'PRIORITY',
          'lastObservedAt': '2026-08-09T10:08:00Z',
          'promptCount': 5,
          'attemptedCount': 3,
          'validatedCount': 2,
        },
      ],
      'observedSkillCount': 5,
      'activitiesThisWeek': 2,
      'progressionAvailable': true,
    });

    expect(plan.state, LearningPlanState.active);
    expect(plan.currentPriority?.status, LearningPlanSkillStatus.priority);
    expect(plan.currentPriority?.confidence, ObservationConfidence.high);
    expect(plan.observedSkills.single.section, SkillSection.ee);
    expect(plan.observedSkillCount, 5);
    expect(plan.progressionAvailable, isTrue);

    // Compteurs de petits sujets : servis par le serveur, jamais recalculés.
    expect(plan.currentPriority?.promptCount, 5);
    expect(plan.currentPriority?.attemptedCount, 2);
    expect(plan.currentPriority?.validatedCount, 1);
    expect(plan.observedSkills.single.promptCount, 5);
    expect(plan.observedSkills.single.attemptedCount, 3);
    expect(plan.observedSkills.single.validatedCount, 2);
  });

  test('un plan servi sans compteurs ne fabrique pas de progression', () {
    final plan = LearningPlan.fromJson({
      'state': 'ACTIVE',
      'currentPriority': {
        'skillId': 'skill-1',
        'title': 'Développer un argument',
        'section': 'EE',
        'status': 'PRIORITY',
        'confidence': 'LOW',
        'observedAt': '2026-08-09T10:08:00Z',
      },
      'nextPriorities': [],
      'observedSkills': [],
      'observedSkillCount': 0,
      'activitiesThisWeek': 0,
      'progressionAvailable': false,
    });

    expect(plan.currentPriority?.promptCount, 0);
    expect(plan.currentPriority?.attemptedCount, 0);
    expect(plan.currentPriority?.validatedCount, 0);
  });
}

Map<String, dynamic> _exerciseJson(String epreuve, String submissionId) => {
      'productionTaskId': 'task-$epreuve',
      'attemptId': 'attempt-$epreuve',
      'epreuve': epreuve,
      'title': 'Exercice $epreuve',
      'instruction': 'Répondez à la consigne.',
      'helperText': 'Aide courte',
      'wordsMin': epreuve == 'TCF_EE' ? 100 : null,
      'wordsMax': epreuve == 'TCF_EE' ? 130 : null,
      'durationMinSeconds': epreuve == 'TCF_EO' ? 120 : null,
      'durationMaxSeconds': epreuve == 'TCF_EO' ? 180 : null,
      'instructionAudioUrl': null,
      'submissionId': submissionId,
      'submissionStatus': 'EVALUATED',
    };

Map<String, dynamic> _productionResultJson(String level, String section) => {
      'levelEstimate': level,
      'taskCompletion': 'COMPLETED',
      'communicationStatus': 'EFFECTIVE',
      'summary': 'Production exploitable.',
      'strengths': ['Message compréhensible'],
      'weaknesses': ['À préciser'],
      'skills': [_skillJson('observed-$section', section)],
    };

Map<String, dynamic> _skillJson(String id, String section) => {
      'skillId': id,
      'skillCode': '${section}_ARG',
      'skillTitle': 'Développer un argument',
      'section': section,
      'observed': true,
      'status': 'PRIORITY',
      'evidence': 'Une raison brève.',
      'explanation': 'La raison mérite un exemple.',
      'confidence': 'MEDIUM',
      'priority': true,
    };

Map<String, dynamic> _exerciseRecommendationJson() => {
      'skillPromptId': 'prompt-1',
      'skillId': 'skill-1',
      'skillCode': 'EE_ARG',
      'title': 'Donner une raison et un exemple',
      'section': 'EE',
      'estimatedMinutes': 4,
    };
