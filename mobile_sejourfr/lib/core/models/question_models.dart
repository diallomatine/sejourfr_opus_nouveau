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

final _singleLetterChoice = RegExp(r'^[A-Za-z]$');

/// Ordre d'affichage des choix, partagé entre le runner et le rapport pour
/// qu'un même attempt présente les choix dans le même ordre des deux côtés.
///
/// Pour les questions TCF CO en mode FULL_AUDIO ([QuestionDto.usesLetterKeyChoices]),
/// on trie par label pour un affichage A→D — la lettre étant la clé de réponse
/// citée par l'audio et l'explication. Les autres questions gardent leur ordre
/// d'origine (shuffle backend, seedé par AttemptQuestion.id).
List<ChoiceDto> orderedDisplayChoices(QuestionDto question) {
  final choices = question.choices;
  if (!question.usesLetterKeyChoices) return choices;
  return [...choices]..sort((a, b) =>
      a.label.trim().toUpperCase().compareTo(b.label.trim().toUpperCase()));
}

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

  /// Questions TCF CO en mode FULL_AUDIO : le contenu des réponses vit dans
  /// l'audio, les labels en base ne sont que des lettres A/B/C/D (la clé citée
  /// par l'audio et l'explication). Le runner affiche alors cette lettre dans
  /// la pastille et masque le texte redondant.
  ///
  /// Restreint aux types CO et CO_IMAGE : sans ce garde-fou, une question
  /// STRUCTURE dont une réponse est une lettre isolée (« y », « en »…)
  /// déclenchait à tort ce mode et affichait « Y » à la place de la pastille C.
  /// En CO_IMAGE les propositions sont toujours des lettres nues (le contenu
  /// vit dans l'audio).
  bool get usesLetterKeyChoices =>
      (questionType == QuestionType.co ||
          questionType == QuestionType.coImage) &&
      choices.isNotEmpty &&
      choices.every((c) => _singleLetterChoice.hasMatch(c.label.trim()));

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
