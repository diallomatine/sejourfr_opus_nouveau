import 'enums.dart';

/// Vue publique d'un ExamTemplate (vitrine, briefing). Pas de questions ni de
/// règles ici : la composition est tirée côté backend au moment du start.
class ExamTemplateSummary {
  ExamTemplateSummary({
    required this.id,
    required this.slug,
    required this.module,
    required this.name,
    required this.durationSeconds,
    required this.totalQuestions,
    required this.passingScore,
    required this.free,
    required this.position,
    this.targetProcedure,
    this.targetLevel,
    this.subtitle,
    this.description,
  });

  final String id;
  final String slug;
  final AppModule module;
  final String name;
  final int durationSeconds;
  final int totalQuestions;
  final int passingScore;
  final bool free;
  final int position;
  final TargetProcedure? targetProcedure;
  final TargetLevel? targetLevel;
  final String? subtitle;
  final String? description;

  int get durationMinutes => (durationSeconds / 60).round();

  String get targetLabel {
    if (module == AppModule.civique) {
      return targetProcedure?.shortLabel ?? 'Tous parcours';
    }
    return targetLevel?.wire ?? 'Diagnostic';
  }

  factory ExamTemplateSummary.fromJson(Map<String, dynamic> json) =>
      ExamTemplateSummary(
        id: json['id'] as String,
        slug: json['slug'] as String,
        module: AppModule.fromWire(json['module'] as String),
        name: json['name'] as String,
        subtitle: json['subtitle'] as String?,
        description: json['description'] as String?,
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        totalQuestions: (json['totalQuestions'] as num).toInt(),
        passingScore: (json['passingScore'] as num).toInt(),
        free: json['free'] as bool,
        position: (json['position'] as num).toInt(),
        targetProcedure: json['targetProcedure'] == null
            ? null
            : TargetProcedure.fromWire(json['targetProcedure'] as String),
        targetLevel: TargetLevel.fromWireNullable(json['targetLevel'] as String?),
      );
}
