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
///
/// Si [examTemplateId] est fourni, le backend ignore les autres filtres et
/// applique la composition de l'ExamTemplate (rules ordonnées).
class StartAttemptRequest {
  StartAttemptRequest({
    required this.type,
    required this.module,
    this.examTemplateId,
    this.themeId,
    this.difficulty,
    this.questionType,
    this.size,
    this.lotNumero,
    this.moduleExamQuestionType,
    this.slotNumber,
  });

  final AttemptType type;
  final AppModule module;
  final String? examTemplateId;
  final String? themeId;
  final Difficulty? difficulty;
  final QuestionType? questionType;
  final int? size;

  /// Si renseigné, le backend renvoie l'attempt construit sur la fenêtre
  /// exacte du lot (cf. `LotService` côté Java). module + difficulty +
  /// questionType doivent matcher l'appel `/api/lots` qui a listé ce lot.
  final int? lotNumero;

  /// Si renseigné, déclenche un examen blanc scopé à une épreuve TCF QCM
  /// (CO ou CE). type doit être MOCK_EXAM. Le backend tire 8 A2 + 9 B1 +
  /// 8 B2 progressifs et applique un chrono (20 min CO / 35 min CE).
  /// Cf. `AttemptService.startModuleExam` côté Java.
  final QuestionType? moduleExamQuestionType;

  /// Slot d'examen blanc visé dans la grille UI (1..10). Ignoré pour
  /// TRAINING / REVIEW côté backend. Permet à l'UI de stabiliser la
  /// numérotation : refaire le slot N crée un nouvel attempt avec le
  /// même slot_number=N, l'écran liste prend le plus récent par slot.
  /// Cf. migration V110 + `AttemptService.start`.
  final int? slotNumber;

  Map<String, dynamic> toJson() => {
        'type': type.wire,
        'module': module.wire,
        if (examTemplateId != null) 'examTemplateId': examTemplateId,
        if (themeId != null) 'themeId': themeId,
        if (difficulty != null) 'difficulty': difficulty!.wire,
        if (questionType != null) 'questionType': questionType!.wire,
        if (size != null) 'size': size,
        if (lotNumero != null) 'lotNumero': lotNumero,
        if (moduleExamQuestionType != null)
          'moduleExamQuestionType': moduleExamQuestionType!.wire,
        if (slotNumber != null) 'slotNumber': slotNumber,
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
    this.examTemplateId,
    this.examTemplateSlug,
    this.examTemplateName,
    this.timeLimitSeconds,
    this.passThreshold,
    this.finishedAt,
    this.score,
    this.levelAchieved,
    this.moduleExamQuestionType,
    this.themeId,
    this.calibratedScore,
    this.cecrlLevel,
    this.epreuveResults = const [],
  });

  final String id;
  final AttemptType type;
  final AppModule module;
  final int totalQuestions;
  final DateTime startedAt;
  final List<AttemptQuestion> questions;
  final String? examTemplateId;
  final String? examTemplateSlug;
  final String? examTemplateName;
  final int? timeLimitSeconds;
  final int? passThreshold;
  final DateTime? finishedAt;
  final int? score;
  final TargetLevel? levelAchieved;

  /// Non-null quand l'attempt est un examen module TCF (CO ou CE). Active
  /// le mode strict côté runner : audio auto-play 2s, lecture unique, pas
  /// de pause, soumission auto à la fin du temps.
  final QuestionType? moduleExamQuestionType;

  /// Thème civique scopé (lotThemeId backend) — non-null pour les séries et
  /// examens thématiques civiques.
  final String? themeId;

  /// Score calibré 100-499 (examens module TCF) — affichage façon relevé TCF
  /// à la place du score pondéré X/50. Null hors examen module.
  final int? calibratedScore;

  /// Niveau CECRL estimé de l'examen module TCF (CO/CE). Null hors module.
  /// Sur un examen multi-épreuves (diagnostic CO→CE), c'est le PLANCHER des
  /// niveaux de [epreuveResults] (règle TCF IRN : il faut le niveau partout).
  final NiveauCecrl? cecrlLevel;

  /// Détail par épreuve d'un examen TCF stratifié fini (CO_IMAGE regroupée
  /// sous CO). Vide hors examen TCF ou tant que l'attempt court.
  final List<AttemptEpreuveResult> epreuveResults;

  bool get isMockExam => type == AttemptType.mockExam;
  bool get isFinished => finishedAt != null;
  bool get isTcf => module == AppModule.tcf;
  bool get isModuleExam => moduleExamQuestionType != null;

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
        id: json['id'] as String,
        type: AttemptType.values
            .firstWhere((e) => e.wire == json['type'] as String),
        module: AppModule.fromWire(json['module'] as String),
        examTemplateId: json['examTemplateId'] as String?,
        examTemplateSlug: json['examTemplateSlug'] as String?,
        examTemplateName: json['examTemplateName'] as String?,
        // Nullable cote backend depuis l'ajout des production attempts (EO/EE) :
        // un attempt productif n'a pas de questions QCM, le champ vaut alors null.
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
        passThreshold: (json['passThreshold'] as num?)?.toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        score: (json['score'] as num?)?.toInt(),
        levelAchieved: TargetLevel.fromWireNullable(json['levelAchieved'] as String?),
        moduleExamQuestionType: json['moduleExamQuestionType'] == null
            ? null
            : QuestionType.fromWire(json['moduleExamQuestionType'] as String),
        themeId: json['themeId'] as String?,
        calibratedScore: (json['calibratedScore'] as num?)?.toInt(),
        cecrlLevel: NiveauCecrl.fromWireNullable(json['cecrlLevel'] as String?),
        epreuveResults: (json['epreuveResults'] as List<dynamic>?)
                ?.map((e) =>
                    AttemptEpreuveResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        questions: (json['questions'] as List<dynamic>?)
                ?.map((q) =>
                    AttemptQuestion.fromJson(q as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Résultat d'une épreuve au sein d'un examen TCF stratifié (miroir du DTO
/// backend `AttemptEpreuveResult`). Le niveau global de l'attempt est le
/// plancher de ces niveaux.
class AttemptEpreuveResult {
  AttemptEpreuveResult({
    required this.epreuve,
    required this.correct,
    required this.total,
    required this.calibratedScore,
    required this.cecrlLevel,
  });

  final QuestionType epreuve;
  final int correct;
  final int total;
  final int calibratedScore;
  final NiveauCecrl? cecrlLevel;

  factory AttemptEpreuveResult.fromJson(Map<String, dynamic> json) =>
      AttemptEpreuveResult(
        epreuve: QuestionType.fromWire(json['epreuve'] as String),
        correct: (json['correct'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        calibratedScore: (json['calibratedScore'] as num).toInt(),
        cecrlLevel: NiveauCecrl.fromWireNullable(json['cecrlLevel'] as String?),
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
        // En MOCK_EXAM le backend renvoie correct/correctChoiceIds = null (la
        // correction n'est révélée qu'au finish). On coerce vers des valeurs
        // neutres pour ne pas faire crasher le parsing — sinon chaque
        // soumission d'examen blanc tombe dans le `catch` de submitCurrent,
        // ce qui rend une vraie erreur réseau indiscernable d'un succès.
        correct: json['correct'] as bool? ?? false,
        correctChoiceIds: (json['correctChoiceIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        explanation: json['explanation'] as String?,
      );
}
