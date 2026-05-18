import 'attempt_models.dart';
import 'enums.dart';

/// Résumé d'un attempt — utilisé pour la liste d'historique.
/// Plus léger que [Attempt] : pas les questions imbriquées, juste les méta.
class AttemptSummary {
  AttemptSummary({
    required this.id,
    required this.type,
    required this.module,
    required this.totalQuestions,
    required this.startedAt,
    this.finishedAt,
    this.score,
    this.passThreshold,
    this.difficulty,
    this.examTemplateId,
    this.examTemplateSlug,
    this.examTemplateName,
  });

  final String id;
  final AttemptType type;
  final AppModule module;
  final int totalQuestions;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? score;
  final int? passThreshold;
  final Difficulty? difficulty;
  // Template d'examen lié (null si entraînement libre). Permet de marquer un
  // examen comme "déjà fait" sur la liste, et de proposer voir détails / refaire.
  final String? examTemplateId;
  final String? examTemplateSlug;
  final String? examTemplateName;

  bool get isFinished => finishedAt != null;
  bool get isPassed => score != null && passThreshold != null && score! >= passThreshold!;
  bool get isFailed => isFinished && passThreshold != null && score! < passThreshold!;

  /// Durée en secondes entre le démarrage et la finalisation (null si pas fini).
  int? get durationSeconds => finishedAt == null
      ? null
      : finishedAt!.difference(startedAt).inSeconds;

  factory AttemptSummary.fromJson(Map<String, dynamic> json) => AttemptSummary(
        id: json['id'] as String,
        type: AttemptType.values
            .firstWhere((e) => e.wire == json['type'] as String),
        module: AppModule.fromWire(json['module'] as String),
        totalQuestions: (json['totalQuestions'] as num).toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        score: (json['score'] as num?)?.toInt(),
        passThreshold: (json['passThreshold'] as num?)?.toInt(),
        difficulty: json['difficulty'] == null
            ? null
            : Difficulty.fromWire(json['difficulty'] as String),
        examTemplateId: json['examTemplateId'] as String?,
        examTemplateSlug: json['examTemplateSlug'] as String?,
        examTemplateName: json['examTemplateName'] as String?,
      );
}
