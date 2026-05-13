import 'enums.dart';
import 'question_models.dart';

/// Type d'exercice qu'on lance (côté backend).
enum AttemptType {
  training('TRAINING'),
  mockExam('MOCK_EXAM'),
  review('REVIEW');

  const AttemptType(this.wire);
  final String wire;
}

/// Demande de création d'un attempt.
class StartAttemptRequest {
  StartAttemptRequest({
    required this.type,
    required this.module,
    this.themeId,
    this.difficulty,
    this.questionType,
    this.size,
  });

  final AttemptType type;
  final AppModule module;
  final String? themeId;
  final Difficulty? difficulty;
  final QuestionType? questionType;
  final int? size;

  Map<String, dynamic> toJson() => {
        'type': type.wire,
        'module': module.wire,
        if (themeId != null) 'themeId': themeId,
        if (difficulty != null) 'difficulty': difficulty!.wire,
        if (questionType != null) 'questionType': questionType!.wire,
        if (size != null) 'size': size,
      };
}

class AttemptQuestion {
  AttemptQuestion({
    required this.id,
    required this.position,
    required this.question,
    required this.answered,
    this.selectedChoiceIds = const [],
    this.correct,
  });

  final String id;
  final int position;
  final QuestionDto question;
  final bool answered;
  final List<String> selectedChoiceIds;
  final bool? correct;

  factory AttemptQuestion.fromJson(Map<String, dynamic> json) =>
      AttemptQuestion(
        id: json['id'] as String,
        position: (json['position'] as num).toInt(),
        question:
            QuestionDto.fromJson(json['question'] as Map<String, dynamic>),
        answered: json['answered'] as bool? ?? false,
        selectedChoiceIds: (json['selectedChoiceIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        correct: json['correct'] as bool?,
      );
}

class Attempt {
  Attempt({
    required this.id,
    required this.type,
    required this.module,
    required this.totalQuestions,
    required this.startedAt,
    required this.questions,
    this.timeLimitSeconds,
    this.passThreshold,
    this.finishedAt,
    this.score,
  });

  final String id;
  final AttemptType type;
  final AppModule module;
  final int totalQuestions;
  final DateTime startedAt;
  final List<AttemptQuestion> questions;
  final int? timeLimitSeconds;
  final int? passThreshold;
  final DateTime? finishedAt;
  final int? score;

  bool get isMockExam => type == AttemptType.mockExam;
  bool get isFinished => finishedAt != null;

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
        id: json['id'] as String,
        type: AttemptType.values
            .firstWhere((e) => e.wire == json['type'] as String),
        module: AppModule.fromWire(json['module'] as String),
        totalQuestions: (json['totalQuestions'] as num).toInt(),
        timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
        passThreshold: (json['passThreshold'] as num?)?.toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        score: (json['score'] as num?)?.toInt(),
        questions: (json['questions'] as List<dynamic>?)
                ?.map((q) =>
                    AttemptQuestion.fromJson(q as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Résultat d'une soumission de réponse (entraînement uniquement, mode immédiat).
class AnswerResult {
  AnswerResult({
    required this.correct,
    required this.correctChoiceIds,
    this.explanation,
  });

  final bool correct;
  final List<String> correctChoiceIds;
  final String? explanation;

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        correct: json['correct'] as bool,
        correctChoiceIds: (json['correctChoiceIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        explanation: json['explanation'] as String?,
      );
}
