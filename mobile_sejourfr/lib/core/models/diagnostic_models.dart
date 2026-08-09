import 'enums.dart';
import 'skill_models.dart';

enum DiagnosticJourneyStatus {
  notStarted('NOT_STARTED'),
  inProgress('IN_PROGRESS'),
  analyzing('ANALYZING'),
  completed('COMPLETED'),
  failed('FAILED');

  const DiagnosticJourneyStatus(this.wire);

  final String wire;

  static DiagnosticJourneyStatus fromWire(String value) =>
      DiagnosticJourneyStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => DiagnosticJourneyStatus.notStarted,
      );

  bool get isFinal =>
      this == DiagnosticJourneyStatus.completed ||
      this == DiagnosticJourneyStatus.failed;
}

enum DiagnosticStep {
  presentation('PRESENTATION'),
  written('WRITTEN'),
  oral('ORAL'),
  analysis('ANALYSIS'),
  result('RESULT');

  const DiagnosticStep(this.wire);

  final String wire;

  static DiagnosticStep fromWire(String value) =>
      DiagnosticStep.values.firstWhere(
        (step) => step.wire == value,
        orElse: () => DiagnosticStep.presentation,
      );
}

enum LearningPlanState {
  needsDiagnostic('NEEDS_DIAGNOSTIC'),
  diagnosticInProgress('DIAGNOSTIC_IN_PROGRESS'),
  active('ACTIVE');

  const LearningPlanState(this.wire);

  final String wire;

  static LearningPlanState fromWire(String value) =>
      LearningPlanState.values.firstWhere(
        (state) => state.wire == value,
        orElse: () => LearningPlanState.needsDiagnostic,
      );
}

enum LearningPlanSkillStatus {
  notObserved('NOT_OBSERVED', 'À évaluer'),
  priority('PRIORITY', 'Priorité'),
  toReinforce('TO_REINFORCE', 'À renforcer'),
  solid('SOLID', 'Solide');

  const LearningPlanSkillStatus(this.wire, this.label);

  final String wire;
  final String label;

  static LearningPlanSkillStatus fromWire(String value) =>
      LearningPlanSkillStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => LearningPlanSkillStatus.notObserved,
      );
}

enum ObservationConfidence {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const ObservationConfidence(this.wire);

  final String wire;

  static ObservationConfidence fromWire(String value) =>
      ObservationConfidence.values.firstWhere(
        (confidence) => confidence.wire == value,
        orElse: () => ObservationConfidence.low,
      );
}

enum DiagnosticTaskCompletion {
  completed('COMPLETED'),
  partial('PARTIAL'),
  notCompleted('NOT_COMPLETED');

  const DiagnosticTaskCompletion(this.wire);

  final String wire;

  static DiagnosticTaskCompletion fromWire(String value) =>
      DiagnosticTaskCompletion.values.firstWhere(
        (completion) => completion.wire == value,
        orElse: () => DiagnosticTaskCompletion.notCompleted,
      );
}

enum DiagnosticCommunicationStatus {
  effective('EFFECTIVE'),
  partial('PARTIAL'),
  ineffective('INEFFECTIVE');

  const DiagnosticCommunicationStatus(this.wire);

  final String wire;

  static DiagnosticCommunicationStatus fromWire(String value) =>
      DiagnosticCommunicationStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => DiagnosticCommunicationStatus.ineffective,
      );
}

class DiagnosticExercise {
  const DiagnosticExercise({
    required this.productionTaskId,
    required this.attemptId,
    required this.epreuve,
    required this.title,
    required this.instruction,
    required this.helperText,
    this.wordsMin,
    this.wordsMax,
    this.durationMinSeconds,
    this.durationMaxSeconds,
    this.instructionAudioUrl,
    this.submissionId,
    this.submissionStatus,
  });

  final String productionTaskId;
  final String attemptId;
  final EpreuveType epreuve;
  final String title;
  final String instruction;
  final String helperText;
  final int? wordsMin;
  final int? wordsMax;
  final int? durationMinSeconds;
  final int? durationMaxSeconds;
  final String? instructionAudioUrl;
  final String? submissionId;
  final SubmissionStatut? submissionStatus;

  factory DiagnosticExercise.fromJson(Map<String, dynamic> json) =>
      DiagnosticExercise(
        productionTaskId: json['productionTaskId'] as String,
        attemptId: json['attemptId'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        title: json['title'] as String? ?? '',
        instruction: json['instruction'] as String? ?? '',
        helperText: json['helperText'] as String? ?? '',
        wordsMin: (json['wordsMin'] as num?)?.toInt(),
        wordsMax: (json['wordsMax'] as num?)?.toInt(),
        durationMinSeconds: (json['durationMinSeconds'] as num?)?.toInt(),
        durationMaxSeconds: (json['durationMaxSeconds'] as num?)?.toInt(),
        instructionAudioUrl: _trimmedOrNull(json['instructionAudioUrl']),
        submissionId: json['submissionId'] as String?,
        submissionStatus: json['submissionStatus'] == null
            ? null
            : SubmissionStatut.fromWire(json['submissionStatus'] as String),
      );
}

class DiagnosticSkillObservation {
  const DiagnosticSkillObservation({
    required this.skillId,
    required this.skillCode,
    required this.skillTitle,
    required this.section,
    required this.observed,
    required this.status,
    required this.confidence,
    required this.priority,
    this.evidence,
    this.explanation,
  });

  final String skillId;
  final String skillCode;
  final String skillTitle;
  final SkillSection section;
  final bool observed;
  final LearningPlanSkillStatus status;
  final String? evidence;
  final String? explanation;
  final ObservationConfidence confidence;
  final bool priority;

  factory DiagnosticSkillObservation.fromJson(Map<String, dynamic> json) =>
      DiagnosticSkillObservation(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        skillTitle: json['skillTitle'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        observed: json['observed'] as bool? ?? false,
        status: LearningPlanSkillStatus.fromWire(
          json['status'] as String? ?? 'NOT_OBSERVED',
        ),
        evidence: _trimmedOrNull(json['evidence']),
        explanation: _trimmedOrNull(json['explanation']),
        confidence: ObservationConfidence.fromWire(
          json['confidence'] as String? ?? 'LOW',
        ),
        priority: json['priority'] as bool? ?? false,
      );
}

class DiagnosticProductionResult {
  const DiagnosticProductionResult({
    required this.levelEstimate,
    required this.taskCompletion,
    required this.communicationStatus,
    required this.strengths,
    required this.weaknesses,
    required this.skills,
    this.summary,
  });

  final NiveauCecrl levelEstimate;
  final DiagnosticTaskCompletion taskCompletion;
  final DiagnosticCommunicationStatus communicationStatus;
  final String? summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<DiagnosticSkillObservation> skills;

  factory DiagnosticProductionResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticProductionResult(
        levelEstimate: NiveauCecrl.fromWire(json['levelEstimate'] as String),
        taskCompletion: DiagnosticTaskCompletion.fromWire(
          json['taskCompletion'] as String,
        ),
        communicationStatus: DiagnosticCommunicationStatus.fromWire(
          json['communicationStatus'] as String,
        ),
        summary: _trimmedOrNull(json['summary']),
        strengths: _stringList(json['strengths']),
        weaknesses: _stringList(json['weaknesses']),
        skills: _objectList(json['skills'])
            .map(DiagnosticSkillObservation.fromJson)
            .toList(growable: false),
      );
}

class PlanRecommendedExercise {
  const PlanRecommendedExercise({
    required this.skillPromptId,
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.estimatedMinutes,
  });

  final String skillPromptId;
  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;
  final int estimatedMinutes;

  factory PlanRecommendedExercise.fromJson(Map<String, dynamic> json) =>
      PlanRecommendedExercise(
        skillPromptId: json['skillPromptId'] as String,
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        estimatedMinutes: (json['estimatedMinutes'] as num? ?? 0).toInt(),
      );
}

class DiagnosticResult {
  const DiagnosticResult({
    required this.strengths,
    required this.priorities,
    this.written,
    this.oral,
    this.mainPriorityExplanation,
    this.nextAction,
  });

  final DiagnosticProductionResult? written;
  final DiagnosticProductionResult? oral;
  final List<String> strengths;
  final List<DiagnosticSkillObservation> priorities;
  final String? mainPriorityExplanation;
  final PlanRecommendedExercise? nextAction;

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticResult(
        written: json['written'] == null
            ? null
            : DiagnosticProductionResult.fromJson(
                json['written'] as Map<String, dynamic>,
              ),
        oral: json['oral'] == null
            ? null
            : DiagnosticProductionResult.fromJson(
                json['oral'] as Map<String, dynamic>,
              ),
        strengths: _stringList(json['strengths']),
        priorities: _objectList(json['priorities'])
            .map(DiagnosticSkillObservation.fromJson)
            .take(3)
            .toList(growable: false),
        mainPriorityExplanation:
            _trimmedOrNull(json['mainPriorityExplanation']),
        nextAction: json['nextAction'] == null
            ? null
            : PlanRecommendedExercise.fromJson(
                json['nextAction'] as Map<String, dynamic>,
              ),
      );
}

class DiagnosticJourney {
  const DiagnosticJourney({
    required this.diagnosticCode,
    required this.diagnosticVersion,
    required this.status,
    required this.nextStep,
    required this.canRetry,
    this.sessionId,
    this.written,
    this.oral,
    this.result,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  final String? sessionId;
  final String diagnosticCode;
  final int diagnosticVersion;
  final DiagnosticJourneyStatus status;
  final DiagnosticStep nextStep;
  final DiagnosticExercise? written;
  final DiagnosticExercise? oral;
  final DiagnosticResult? result;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final bool canRetry;

  int get completedExerciseCount =>
      (written?.submissionId == null ? 0 : 1) +
      (oral?.submissionId == null ? 0 : 1);

  factory DiagnosticJourney.fromJson(Map<String, dynamic> json) =>
      DiagnosticJourney(
        sessionId: json['sessionId'] as String?,
        diagnosticCode: json['diagnosticCode'] as String? ?? '',
        diagnosticVersion: (json['diagnosticVersion'] as num? ?? 0).toInt(),
        status: DiagnosticJourneyStatus.fromWire(
          json['status'] as String? ?? 'NOT_STARTED',
        ),
        nextStep: DiagnosticStep.fromWire(
          json['nextStep'] as String? ?? 'PRESENTATION',
        ),
        written: json['written'] == null
            ? null
            : DiagnosticExercise.fromJson(
                json['written'] as Map<String, dynamic>,
              ),
        oral: json['oral'] == null
            ? null
            : DiagnosticExercise.fromJson(
                json['oral'] as Map<String, dynamic>,
              ),
        result: json['result'] == null
            ? null
            : DiagnosticResult.fromJson(
                json['result'] as Map<String, dynamic>,
              ),
        startedAt: _date(json['startedAt']),
        completedAt: _date(json['completedAt']),
        errorMessage: _trimmedOrNull(json['errorMessage']),
        canRetry: json['canRetry'] as bool? ?? false,
      );
}

class LearningPlanPriority {
  const LearningPlanPriority({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.status,
    required this.confidence,
    required this.observedAt,
    this.explanation,
    this.evidence,
    this.recommendedExercise,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;
  final LearningPlanSkillStatus status;
  final String? explanation;
  final String? evidence;
  final ObservationConfidence confidence;
  final DateTime observedAt;
  final PlanRecommendedExercise? recommendedExercise;

  factory LearningPlanPriority.fromJson(Map<String, dynamic> json) =>
      LearningPlanPriority(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        status: LearningPlanSkillStatus.fromWire(
          json['status'] as String? ?? 'NOT_OBSERVED',
        ),
        explanation: _trimmedOrNull(json['explanation']),
        evidence: _trimmedOrNull(json['evidence']),
        confidence: ObservationConfidence.fromWire(
          json['confidence'] as String? ?? 'LOW',
        ),
        observedAt: _date(json['observedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        recommendedExercise: json['recommendedExercise'] == null
            ? null
            : PlanRecommendedExercise.fromJson(
                json['recommendedExercise'] as Map<String, dynamic>,
              ),
      );
}

class LearningPlanSkill {
  const LearningPlanSkill({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.status,
    required this.lastObservedAt,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;
  final LearningPlanSkillStatus status;
  final DateTime lastObservedAt;

  factory LearningPlanSkill.fromJson(Map<String, dynamic> json) =>
      LearningPlanSkill(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        status: LearningPlanSkillStatus.fromWire(
          json['status'] as String? ?? 'NOT_OBSERVED',
        ),
        lastObservedAt: _date(json['lastObservedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

class LearningPlan {
  const LearningPlan({
    required this.state,
    required this.nextPriorities,
    required this.observedSkills,
    required this.observedSkillCount,
    required this.activitiesThisWeek,
    required this.progressionAvailable,
    this.diagnosticSessionId,
    this.diagnosticCompletedAt,
    this.currentPriority,
  });

  final LearningPlanState state;
  final String? diagnosticSessionId;
  final DateTime? diagnosticCompletedAt;
  final LearningPlanPriority? currentPriority;
  final List<LearningPlanPriority> nextPriorities;
  final List<LearningPlanSkill> observedSkills;
  final int observedSkillCount;
  final int activitiesThisWeek;
  final bool progressionAvailable;

  factory LearningPlan.fromJson(Map<String, dynamic> json) => LearningPlan(
        state: LearningPlanState.fromWire(
          json['state'] as String? ?? 'NEEDS_DIAGNOSTIC',
        ),
        diagnosticSessionId: json['diagnosticSessionId'] as String?,
        diagnosticCompletedAt: _date(json['diagnosticCompletedAt']),
        currentPriority: json['currentPriority'] == null
            ? null
            : LearningPlanPriority.fromJson(
                json['currentPriority'] as Map<String, dynamic>,
              ),
        nextPriorities: _objectList(json['nextPriorities'])
            .map(LearningPlanPriority.fromJson)
            .toList(growable: false),
        observedSkills: _objectList(json['observedSkills'])
            .map(LearningPlanSkill.fromJson)
            .toList(growable: false),
        observedSkillCount: (json['observedSkillCount'] as num? ?? 0).toInt(),
        activitiesThisWeek: (json['activitiesThisWeek'] as num? ?? 0).toInt(),
        progressionAvailable: json['progressionAvailable'] as bool? ?? false,
      );
}

String? _trimmedOrNull(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _objectList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().toList(growable: false);
}
