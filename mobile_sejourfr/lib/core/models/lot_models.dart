import 'enums.dart';

/// Miroir Dart de `LotDto` côté backend.
///
/// Un lot est un chunk déterministe de questions filtrées par module +
/// critères : pour TCF par (questionType, difficulty), pour Civique par
/// (themeId). Le numéro est 1-indexé. La taille du lot est constante :
/// TCF A2 = 15 / B1 = 20 / B2 = 25, Civique = 15.
///
/// Le champ `difficulty` est nullable — il est porté uniquement par les
/// lots TCF. Les lots Civique le laissent à null côté backend.
///
/// Les champs `last*` sont remplis avec le dernier attempt fini de l'user
/// sur ce lot (null si jamais tenté) — sert au mobile pour différencier
/// visuellement les lots déjà faits avec leur score précédent.
class LotDto {
  LotDto({
    required this.numero,
    required this.difficulty,
    required this.totalQuestions,
    this.lastScore,
    this.lastAttemptedAt,
  });

  final int numero;
  final Difficulty? difficulty;
  final int totalQuestions;
  final int? lastScore;
  final DateTime? lastAttemptedAt;

  bool get alreadyAttempted => lastScore != null;

  factory LotDto.fromJson(Map<String, dynamic> json) => LotDto(
        numero: (json['numero'] as num).toInt(),
        difficulty: json['difficulty'] == null
            ? null
            : Difficulty.fromWire(json['difficulty'] as String),
        totalQuestions: (json['totalQuestions'] as num).toInt(),
        lastScore: (json['lastScore'] as num?)?.toInt(),
        lastAttemptedAt: json['lastAttemptedAt'] == null
            ? null
            : DateTime.parse(json['lastAttemptedAt'] as String),
      );
}
