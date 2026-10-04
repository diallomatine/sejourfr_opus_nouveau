import 'enums.dart';

class ThemeDto {
  ThemeDto({
    required this.id,
    required this.module,
    required this.code,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.questionCount,
  });

  final String id;
  final AppModule module;
  final String code;
  final String name;
  final String? description;
  final int displayOrder;
  final int questionCount;

  factory ThemeDto.fromJson(Map<String, dynamic> json) => ThemeDto(
        id: json['id'] as String,
        module: AppModule.fromWire(json['module'] as String),
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        displayOrder: (json['displayOrder'] as num).toInt(),
        questionCount: (json['questionCount'] as num? ?? 0).toInt(),
      );
}

class MediaDto {
  MediaDto({
    required this.id,
    required this.type,
    required this.url,
    this.durationSeconds,
    this.transcript,
    this.inlineSvg,
  });

  final String id;
  final MediaType type;

  /// URL distante (null quand le media est porté entièrement par inlineSvg,
  /// ce qui est le cas des captures TCF dessinées en migration Flyway).
  final String url;
  final int? durationSeconds;
  final String? transcript;

  /// SVG brut. Quand non-null, le runner doit afficher ce balisage plutôt
  /// que de charger url.
  final String? inlineSvg;

  bool get hasInlineSvg => inlineSvg != null && inlineSvg!.isNotEmpty;

  factory MediaDto.fromJson(Map<String, dynamic> json) => MediaDto(
        id: json['id'] as String,
        type: MediaType.fromWire(json['type'] as String),
        url: (json['url'] as String?) ?? '',
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        transcript: json['transcript'] as String?,
        inlineSvg: json['inlineSvg'] as String?,
      );
}

class ChoiceDto {
  ChoiceDto({
    required this.id,
    required this.label,
    required this.correct,
    required this.displayOrder,
  });

  final String id;
  final String label;
  final bool correct;
  final int displayOrder;

  factory ChoiceDto.fromJson(Map<String, dynamic> json) => ChoiceDto(
        id: json['id'] as String,
        label: json['label'] as String,
        correct: json['correct'] as bool? ?? json['isCorrect'] as bool? ?? false,
        displayOrder: (json['displayOrder'] as num).toInt(),
      );
}

final _letterKeyLabel = RegExp(r'^(?:r[ée]ponse\s+)?([A-D])$', caseSensitive: false);

class QuestionDto {
  QuestionDto({
    required this.id,
    required this.module,
    required this.themeId,
    required this.themeName,
    required this.difficulty,
    required this.questionType,
    required this.statement,
    required this.explanation,
    required this.choices,
    this.passageText,
    this.media,
    this.audioMedia,
    this.userSelectedChoiceIds = const [],
  });

  final String id;
  final AppModule module;
  final String themeId;
  final String themeName;
  final Difficulty difficulty;
  final QuestionType questionType;
  final String statement;
  final String? explanation;
  final List<ChoiceDto> choices;
  final String? passageText;
  final MediaDto? media;

  /// Média audio additionnel, distinct de [media]. Pour une question
  /// CO_IMAGE : [media] porte l'IMAGE affichée, [audioMedia] porte l'AUDIO
  /// qui énonce les propositions A/B/C/D. Null pour tous les autres types.
  final MediaDto? audioMedia;

  /// Choix sélectionnés par l'utilisateur lors de sa dernière tentative —
  /// renseigné uniquement dans la version "review" (`GET /api/me/questions/:id/review`).
  /// Liste vide pour les autres endpoints. Permet au sheet de marquer en
  /// rouge le choix incorrect choisi.
  final List<String> userSelectedChoiceIds;

  bool get hasMedia => media != null;
  bool get hasAudio => media?.type == MediaType.audio;
  bool get hasImage => media?.type == MediaType.image;
  bool get hasVideo => media?.type == MediaType.video;

  /// Propositions réduites à une lettre-clé : la pastille porte la lettre, le
  /// texte du choix n'est jamais affiché (runner, rapport, favoris). Miroir web :
  /// `isLetterKeyQuestion` (`web_sejoufr/lib/choice-key-letters.ts`).
  ///
  /// - CO_IMAGE : toujours, le texte des propositions vit dans l'audio — même
  ///   si `label` n'est pas une lettre, il ne doit jamais s'afficher.
  /// - CO (FULL_AUDIO) : quand tous les labels sont une lettre (« A » ou
  ///   « Réponse A »).
  /// - Aucun autre type : une question STRUCTURE dont un choix est « a »
  ///   (verbe avoir) garde son texte.
  bool get isLetterKeyQuestion =>
      questionType == QuestionType.coImage ||
      (questionType == QuestionType.co &&
          choices.isNotEmpty &&
          choices.every((c) => _letterKeyLabel.hasMatch(c.label.trim())));

  /// Lettre du choix d'indice [index] : celle du label quand il en est une,
  /// sinon celle de sa position (l'ordre servi suit déjà les lettres).
  String choiceKeyLetter(int index) {
    final match = _letterKeyLabel.firstMatch(choices[index].label.trim());
    return match != null
        ? match.group(1)!.toUpperCase()
        : String.fromCharCode('A'.codeUnitAt(0) + index);
  }

  /// CO ou CO_IMAGE : l'audio de la question se lance seul dans le runner.
  bool get isComprehensionOrale =>
      questionType == QuestionType.co || questionType == QuestionType.coImage;

  factory QuestionDto.fromJson(Map<String, dynamic> json) => QuestionDto(
        id: json['id'] as String,
        module: AppModule.fromWire(json['module'] as String),
        themeId: json['themeId'] as String,
        themeName: json['themeName'] as String? ?? '',
        difficulty: Difficulty.fromWire(json['difficulty'] as String),
        questionType: QuestionType.fromWire(json['questionType'] as String),
        statement: json['statement'] as String,
        explanation: json['explanation'] as String?,
        passageText: json['passageText'] as String?,
        media: json['media'] == null
            ? (json['mediaUrl'] == null
                ? null
                : MediaDto(
                    id: json['mediaId'] as String? ?? '',
                    type: MediaType.fromWire(
                      json['mediaType'] as String? ?? 'IMAGE',
                    ),
                    url: json['mediaUrl'] as String,
                  ))
            : MediaDto.fromJson(json['media'] as Map<String, dynamic>),
        audioMedia: json['audioMedia'] == null
            ? null
            : MediaDto.fromJson(json['audioMedia'] as Map<String, dynamic>),
        choices: (json['choices'] as List<dynamic>?)
                ?.map((c) => ChoiceDto.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        userSelectedChoiceIds: (json['userSelectedChoiceIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

/// `Page<T>` du backend Spring Data.
class PageResponse<T> {
  PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) =>
      PageResponse<T>(
        content: (json['content'] as List<dynamic>)
            .map((e) => parse(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num).toInt(),
        size: (json['size'] as num).toInt(),
        totalElements: (json['totalElements'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
        first: json['first'] as bool,
        last: json['last'] as bool,
      );
}
