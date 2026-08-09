import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/diagnostic_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';

void main() {
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
