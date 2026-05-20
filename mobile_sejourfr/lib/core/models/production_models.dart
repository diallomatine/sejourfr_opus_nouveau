import 'enums.dart';

/// Miroir mobile des DTOs backend du pipeline EO/EE (cf. PRODUCTION_TASKS_SPEC_V2.md
/// section 8 + ProductionTaskDto.java / ProductionSubmissionDto.java).
///
/// Convention : les champs sont en camelCase Dart, parses depuis les noms
/// camelCase renvoyes par Spring (Jackson). En cas de divergence backend, c'est
/// ICI qu'on adapte le mapping.

class ProductionTaskDto {
  ProductionTaskDto({
    required this.id,
    required this.epreuve,
    required this.tacheNumero,
    required this.niveauCible,
    required this.consigne,
    this.contexte,
    this.dureeMaxSec,
    this.motsMin,
    this.motsMax,
  });

  final String id;
  final EpreuveType epreuve;

  /// Numero de tache au sein de l'epreuve (1, 2 ou 3).
  final int tacheNumero;

  /// "A2" / "B1" / "B2" -- string raw pour rester aligne avec le backend.
  final String niveauCible;

  final String consigne;
  final String? contexte;

  /// EO uniquement : duree max d'enregistrement en secondes.
  final int? dureeMaxSec;

  /// EE uniquement : bornes du nombre de mots attendu.
  final int? motsMin;
  final int? motsMax;

  /// Libelle court genere cote front (le backend ne fournit pas ce titre).
  String get displayTitle {
    if (epreuve == EpreuveType.tcfEo) {
      return switch (tacheNumero) {
        1 => 'Entretien dirige',
        2 => 'Jeu de role',
        3 => 'Point de vue',
        _ => 'Tache $tacheNumero',
      };
    }
    if (epreuve == EpreuveType.tcfEe) {
      return switch (tacheNumero) {
        1 => 'Message simple',
        2 => 'Recit d\'experience',
        3 => 'Point de vue argumente',
        _ => 'Tache $tacheNumero',
      };
    }
    return 'Tache $tacheNumero';
  }

  factory ProductionTaskDto.fromJson(Map<String, dynamic> json) => ProductionTaskDto(
        id: json['id'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        tacheNumero: (json['tacheNumero'] as num).toInt(),
        niveauCible: json['niveauCible'] as String,
        consigne: json['consigne'] as String,
        contexte: json['contexte'] as String?,
        dureeMaxSec: (json['dureeMaxSec'] as num?)?.toInt(),
        motsMin: (json['motsMin'] as num?)?.toInt(),
        motsMax: (json['motsMax'] as num?)?.toInt(),
      );
}

class ProductionSubmissionDto {
  ProductionSubmissionDto({
    required this.id,
    required this.attemptId,
    required this.productionTaskId,
    required this.statut,
    required this.submittedAt,
    required this.retryCount,
    this.mediaUrl,
    this.texteSoumis,
    this.motsCount,
    this.mediaDurationSec,
    this.erreurMessage,
    this.evaluation,
    this.transcription,
  });

  final String id;
  final String? attemptId;
  final String? productionTaskId;
  final SubmissionStatut statut;

  /// URL pre-signee (TTL court) vers l'audio EO. NULL pour EE.
  final String? mediaUrl;

  final String? texteSoumis;
  final int? motsCount;
  final int? mediaDurationSec;

  final int retryCount;
  final String? erreurMessage;
  final DateTime submittedAt;

  /// Presente uniquement quand `statut == evaluated`.
  final EvaluationResult? evaluation;

  /// Texte transcrit par Whisper (EO uniquement). Null pour EE et tant que la
  /// transcription n'a pas tourne.
  final String? transcription;

  bool get isAudio => mediaUrl != null;
  bool get isText => texteSoumis != null;

  factory ProductionSubmissionDto.fromJson(Map<String, dynamic> json) => ProductionSubmissionDto(
        id: json['id'] as String,
        attemptId: json['attemptId'] as String?,
        productionTaskId: json['productionTaskId'] as String?,
        statut: SubmissionStatut.fromWire(json['statut'] as String),
        mediaUrl: json['mediaUrl'] as String?,
        texteSoumis: json['texteSoumis'] as String?,
        motsCount: (json['motsCount'] as num?)?.toInt(),
        mediaDurationSec: (json['mediaDurationSec'] as num?)?.toInt(),
        retryCount: (json['retryCount'] as num? ?? 0).toInt(),
        erreurMessage: json['erreurMessage'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        evaluation: json['evaluation'] == null
            ? null
            : EvaluationResult.fromJson(json['evaluation'] as Map<String, dynamic>),
        transcription: json['transcription'] as String?,
      );
}

/// Vue front d'une AiEvaluation. Le bloc `feedback` est passe en l'etat depuis
/// le JSONB persiste cote backend.
class EvaluationResult {
  EvaluationResult({
    required this.feedback,
    this.noteSurVingt,
    this.niveauCecrl,
  });

  /// Note 0..20, peut etre nulle si l'IA n'a pas pu noter (ex: production vide).
  final double? noteSurVingt;
  final NiveauCecrl? niveauCecrl;
  final EvaluationFeedback feedback;

  factory EvaluationResult.fromJson(Map<String, dynamic> json) => EvaluationResult(
        noteSurVingt: (json['noteSurVingt'] as num?)?.toDouble(),
        niveauCecrl: NiveauCecrl.fromWireNullable(json['niveauCecrl'] as String?),
        feedback: EvaluationFeedback.fromJson(
          (json['feedback'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}

/// Detail structure du feedback IA (cf. backend tool_use submit_evaluation).
class EvaluationFeedback {
  EvaluationFeedback({
    this.noteGlobale,
    this.niveauCecrl,
    this.scoresCriteres = const [],
    this.pointsForts = const [],
    this.pointsAAmeliorer = const [],
    this.suggestions = const [],
    this.exemplesCorriges = const [],
  });

  final double? noteGlobale;
  final NiveauCecrl? niveauCecrl;
  final List<CriterionScore> scoresCriteres;
  final List<String> pointsForts;
  final List<String> pointsAAmeliorer;
  final List<String> suggestions;
  final List<CorrectionExample> exemplesCorriges;

  factory EvaluationFeedback.fromJson(Map<String, dynamic> json) {
    return EvaluationFeedback(
      noteGlobale: (json['note_globale'] as num?)?.toDouble(),
      niveauCecrl: NiveauCecrl.fromWireNullable(json['niveau_cecrl'] as String?),
      scoresCriteres: ((json['scores_criteres'] as List?) ?? const [])
          .map((e) => CriterionScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      pointsForts: ((json['points_forts'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      pointsAAmeliorer: ((json['points_a_ameliorer'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      suggestions: ((json['suggestions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      exemplesCorriges: ((json['exemples_corriges'] as List?) ?? const [])
          .map((e) => CorrectionExample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CriterionScore {
  CriterionScore({
    required this.code,
    required this.noteSurVingt,
    required this.commentaire,
  });

  final String code;
  final double noteSurVingt;
  final String commentaire;

  factory CriterionScore.fromJson(Map<String, dynamic> json) => CriterionScore(
        code: json['code'] as String,
        noteSurVingt: (json['note_sur_20'] as num).toDouble(),
        commentaire: json['commentaire'] as String? ?? '',
      );
}

class CorrectionExample {
  CorrectionExample({
    required this.original,
    required this.corrige,
    required this.explication,
  });

  final String original;
  final String corrige;
  final String explication;

  factory CorrectionExample.fromJson(Map<String, dynamic> json) => CorrectionExample(
        original: json['original'] as String? ?? '',
        corrige: json['corrige'] as String? ?? '',
        explication: json['explication'] as String? ?? '',
      );
}
