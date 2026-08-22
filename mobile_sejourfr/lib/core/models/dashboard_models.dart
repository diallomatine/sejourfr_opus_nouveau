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
    required this.estimatedTcfLevelEpreuvesCounted,
    required this.estimatedTcfLevelEpreuvesExpected,
    required this.estimatedTcfLevelPartial,
    required this.civique,
    required this.tcf,
    this.tcfDomainProfile,
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

  /// **Périmètre** de [estimatedTcfLevel] : combien d'épreuves ont réellement
  /// pesé (0..4), sur combien, et si ça n'en fait pas le tour.
  ///
  /// Même contrat que `epreuvesCountedInFinalLevel` / `epreuvesExpected` /
  /// `finalLevelPartial` d'un examen blanc complet, et même raison : un
  /// candidat qui n'a passé que l'expression écrite lisait « Niveau TCF
  /// estimé : B1 » sur la foi d'**une** épreuve sur quatre. Dérivé serveur —
  /// **ne jamais recompter** côté app.
  final int estimatedTcfLevelEpreuvesCounted;
  final int estimatedTcfLevelEpreuvesExpected;

  /// Au moins une épreuve comptée, mais pas les quatre. À zéro épreuve le
  /// niveau vaut déjà `null` (« — ») : il n'y a rien à annoter.
  final bool estimatedTcfLevelPartial;

  /// Le niveau TCF **domaine par domaine** — ce que « Mon profil TCF »
  /// affiche, et ce dont « Compléter mon profil » déduit les domaines
  /// manquants. Miroir de `DashboardSummaryResponse.tcfDomainProfile`.
  ///
  /// Les trois scalaires ci-dessus en sont le **résumé** : ils restent servis
  /// et restent justes, ce bloc ne les remplace pas. `null` seulement face à un
  /// backend antérieur au champ.
  final TcfDomainProfile? tcfDomainProfile;

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
        estimatedTcfLevelEpreuvesCounted:
            (json['estimatedTcfLevelEpreuvesCounted'] as num? ?? 0).toInt(),
        estimatedTcfLevelEpreuvesExpected:
            (json['estimatedTcfLevelEpreuvesExpected'] as num? ?? 0).toInt(),
        estimatedTcfLevelPartial:
            json['estimatedTcfLevelPartial'] as bool? ?? false,
        tcfDomainProfile:
            TcfDomainProfile.fromJsonOrNull(json['tcfDomainProfile']),
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

/// Le profil TCF d'un candidat **domaine par domaine**, servi sur
/// `GET /api/me/dashboard`. Miroir de `TcfDomainProfileDto`.
///
/// 🛑 **Les quatre domaines sont TOUJOURS présents**, dans un **ordre figé
/// serveur** (CO, CE, EO, EE) : un domaine jamais passé reste dans la liste
/// avec `evaluated == false`. Aucun front ne retrie, aucun front ne complète
/// la liste, aucun front ne dérive un niveau.
class TcfDomainProfile {
  const TcfDomainProfile({
    required this.domaines,
    required this.evaluated,
    required this.expected,
    required this.partial,
    this.globalLevel,
  });

  /// Les 4 domaines, dans l'ordre du serveur. Jamais `null`.
  final List<TcfDomain> domaines;

  /// Le niveau global : plancher des domaines évalués. `null` tant qu'aucun
  /// domaine n'a été mesuré — **null = inconnu, jamais mauvais**.
  final NiveauCecrl? globalLevel;

  /// Domaines réellement mesurés (0..4) sur [expected] (4, toujours).
  final int evaluated;
  final int expected;

  /// Au moins un domaine mesuré, mais pas les quatre.
  final bool partial;

  /// Les domaines qui n'ont jamais été mesurés, dans l'ordre du serveur.
  /// C'est la matière de « Compléter mon profil » — mais **ce n'est pas elle
  /// qui dit par quoi les mesurer** : c'est `LearningPlan.domainesAEvaluer`.
  List<TcfDomain> get manquants =>
      domaines.where((d) => !d.evaluated).toList(growable: false);

  static TcfDomainProfile? fromJsonOrNull(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return TcfDomainProfile(
      domaines: (value['domaines'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TcfDomain.fromJson)
          .toList(growable: false),
      globalLevel:
          NiveauCecrl.fromWireNullable(value['globalLevel'] as String?),
      evaluated: (value['evaluated'] as num? ?? 0).toInt(),
      expected: (value['expected'] as num? ?? 0).toInt(),
      partial: value['partial'] as bool? ?? false,
    );
  }
}

/// Un domaine du profil TCF. Miroir de `TcfDomainDto`.
///
/// `evaluated == false` ⇔ `niveau == null` : le domaine n'a jamais été passé,
/// son niveau est **inconnu**, jamais `A1_NON_ATTEINT`. L'écran affiche « Pas
/// encore évaluée » et **ne dérive aucun niveau** — il est calculé serveur.
class TcfDomain {
  const TcfDomain({
    required this.epreuve,
    required this.evaluated,
    this.niveau,
  });

  /// `TCF_CO` | `TCF_CE` | `TCF_EO` | `TCF_EE`.
  final EpreuveType epreuve;
  final bool evaluated;
  final NiveauCecrl? niveau;

  factory TcfDomain.fromJson(Map<String, dynamic> json) => TcfDomain(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        evaluated: json['evaluated'] as bool? ?? false,
        niveau: NiveauCecrl.fromWireNullable(json['niveau'] as String?),
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

/// Ce qu'on écrit **sous** un niveau TCF estimé qui ne porte pas sur les quatre
/// épreuves.
///
/// Une seule chaîne, courte, la même sur toutes les surfaces (accueil, profil,
/// progrès) et **au caractère près** identique au web
/// (`estimatedTcfLevelScopeLabel`, `web_sejoufr/lib/types.ts`). Elle tient dans
/// la légende d'une `StatValueCard` à 360 px, ce qui est la vraie contrainte :
/// une phrase longue n'aurait pas pu être la même partout, et deux formulations
/// auraient divergé au premier retouche.
///
/// ⚠️ Règle de ton : elle **constate un périmètre**, elle ne reproche pas un
/// inachèvement. « D'après 1 épreuve sur 4 » dit ce qu'on sait ; « il te manque
/// 3 épreuves » dirait au candidat qu'il est en retard. Et **aucun chiffre de
/// barème** n'y apparaît — un décompte d'épreuves n'en est pas un.
///
/// `null` quand il n'y a rien à annoter : niveau complet (4/4) ou inconnu (0/4,
/// l'écran affiche déjà « — »).
String? estimatedTcfLevelScopeLabel(DashboardSummary? summary) {
  if (summary == null || !summary.estimatedTcfLevelPartial) return null;
  final counted = summary.estimatedTcfLevelEpreuvesCounted;
  final expected = summary.estimatedTcfLevelEpreuvesExpected;
  if (counted <= 0 || expected <= 0) return null;
  return "D'après $counted épreuve${counted > 1 ? 's' : ''} sur $expected";
}
