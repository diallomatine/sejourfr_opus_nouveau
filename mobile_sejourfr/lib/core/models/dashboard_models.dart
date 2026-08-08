import 'enums.dart';

/// Miroir Dart de `DashboardSummaryResponse` backend
/// (`GET /api/me/dashboard`). Agrégat unique qui alimente Accueil, Réviser
/// et Progrès : streak, progression globale, niveau TCF estimé et une
/// entrée par catégorie (thèmes civique, épreuves TCF + EE/EO synthétiques).
class DashboardSummary {
  DashboardSummary({
    required this.currentStreakDays,
    required this.recordStreakDays,
    required this.activeToday,
    required this.mockExamsTotal,
    required this.civiqueMockExams,
    required this.tcfMockExams,
    required this.globalSuccessPercent,
    required this.estimatedTcfLevel,
    required this.civique,
    required this.tcf,
  });

  final int currentStreakDays;
  final int recordStreakDays;
  final bool activeToday;
  final int mockExamsTotal;
  final int civiqueMockExams;
  final int tcfMockExams;

  /// Progression globale 0-100 (moyenne des catégories renseignées).
  /// Null si rien travaillé.
  final int? globalSuccessPercent;

  /// Niveau TCF **estimé** du candidat : plancher des 4 épreuves
  /// (CO/CE/EE/EO), chacune retenant son **meilleur** résultat, une épreuve
  /// abandonnée sans rien rendre (0 réponse / 0 soumission) étant **exclue**.
  /// Null tant qu'aucune épreuve n'a été réellement passée — null = inconnu,
  /// jamais mauvais. Dérivé serveur (`TcfProfileService`) : ne jamais le
  /// recalculer côté front.
  final NiveauCecrl? estimatedTcfLevel;

  final List<DashboardCategoryStat> civique;
  final List<DashboardCategoryStat> tcf;

  /// Toutes les catégories des deux parcours (ordre backend conservé).
  List<DashboardCategoryStat> get allCategories => [...tcf, ...civique];

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        currentStreakDays: (json['currentStreakDays'] as num? ?? 0).toInt(),
        recordStreakDays: (json['recordStreakDays'] as num? ?? 0).toInt(),
        activeToday: json['activeToday'] as bool? ?? false,
        mockExamsTotal: (json['mockExamsTotal'] as num? ?? 0).toInt(),
        civiqueMockExams: (json['civiqueMockExams'] as num? ?? 0).toInt(),
        tcfMockExams: (json['tcfMockExams'] as num? ?? 0).toInt(),
        globalSuccessPercent: (json['globalSuccessPercent'] as num?)?.toInt(),
        estimatedTcfLevel:
            NiveauCecrl.fromWireNullable(json['estimatedTcfLevel'] as String?),
        civique: (json['civique'] as List<dynamic>? ?? [])
            .map((e) =>
                DashboardCategoryStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        tcf: (json['tcf'] as List<dynamic>? ?? [])
            .map((e) =>
                DashboardCategoryStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Stat d'une catégorie du dashboard — miroir de
/// `DashboardSummaryResponse.CategoryStat`.
///
/// `themeId` est null pour les entrées synthétiques EE/EO. `percent` est la
/// progression 0-100 (réussite × confiance), null si jamais travaillée.
/// Codes connus : `CIV_PRINCIPES`, `CIV_INSTITUTIONS`, `CIV_DROITS_DEVOIRS`,
/// `CIV_HISTOIRE_GEO`, `CIV_SOCIETE`, `TCF_CO`, `TCF_CE`, `TCF_STRUCTURE`,
/// `TCF_EE`, `TCF_EO`.
class DashboardCategoryStat {
  DashboardCategoryStat({
    required this.themeId,
    required this.code,
    required this.label,
    required this.percent,
    required this.answered,
    required this.total,
    required this.mockExams,
    required this.bestMockScore,
    required this.lastMockScore,
    required this.prevMockScore,
    required this.level,
  });

  final String? themeId;
  final String code;
  final String label;
  final int? percent;
  final int answered;
  final int total;
  final int mockExams;
  final int? bestMockScore;
  final int? lastMockScore;
  final int? prevMockScore;

  /// Dernier niveau CECRL évalué — renseigné uniquement pour EE/EO.
  final NiveauCecrl? level;

  bool get isProduction => code == 'TCF_EE' || code == 'TCF_EO';

  factory DashboardCategoryStat.fromJson(Map<String, dynamic> json) =>
      DashboardCategoryStat(
        themeId: json['themeId'] as String?,
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        percent: (json['percent'] as num?)?.toInt(),
        answered: (json['answered'] as num? ?? 0).toInt(),
        total: (json['total'] as num? ?? 0).toInt(),
        mockExams: (json['mockExams'] as num? ?? 0).toInt(),
        bestMockScore: (json['bestMockScore'] as num?)?.toInt(),
        lastMockScore: (json['lastMockScore'] as num?)?.toInt(),
        prevMockScore: (json['prevMockScore'] as num?)?.toInt(),
        level: NiveauCecrl.fromWireNullable(json['level'] as String?),
      );
}
