import 'enums.dart';
import 'tcf_diagnostic_models.dart';

/// Miroirs des `CivicDiagnostic*Dto` du backend (lot L9).
///
/// 🛑 **À ne pas confondre avec l'examen blanc civique.** `20_` §4.1 les oppose
/// ligne à ligne : couverture équilibrée contre représentative, il CRÉE le plan
/// là où l'examen blanc VÉRIFIE la préparation. Le format (40 questions) est le
/// même depuis l'arbitrage du 2026-09-10, pour que le score soit directement
/// comparable au seuil — mais les deux objets restent distincts.
///
/// 🛑 **Aucun coût LLM** : le civique est du QCM déterministe.

/// L'état d'un thème au diagnostic (`20_` §4.4).
enum CivicThemeState {
  solide('SOLIDE', 'Solide'),
  aRenforcer('A_RENFORCER', 'À renforcer'),
  faible('FAIBLE', 'Faible'),

  /// 🛑 **Pas un verdict.** Un thème qu'aucune question n'a touché n'a pas été
  /// raté : il n'a pas été mesuré. Le confondre avec [faible] reproduirait
  /// l'incident V040/V041/V042 sur le module civique.
  nonEvalue('NON_EVALUE', 'Non évalué');

  const CivicThemeState(this.wire, this.label);
  final String wire;
  final String label;

  static CivicThemeState fromWire(String value) =>
      CivicThemeState.values.firstWhere((e) => e.wire == value);
}

/// L'état d'un diagnostic civique.
///
/// 🛑 **Aucun score ici**, et ce n'est pas un oubli : le résultat est le moment
/// de conversion, le diluer pendant la passation le détruit.
class CivicDiagnosticDto {
  const CivicDiagnosticDto({
    required this.sessionId,
    required this.attemptId,
    required this.status,
    required this.mention,
    required this.total,
    required this.repondues,
    required this.startedAt,
    this.completedAt,
  });

  final String sessionId;

  /// L'attempt à ouvrir dans le runner de questions **existant**.
  ///
  /// 🛑 Aucun écran de passation n'est créé pour le diagnostic — un second
  /// runner divergerait du premier à la première évolution.
  final String attemptId;

  final TcfDiagnosticStatus status;
  final Difficulty mention;
  final int total;
  final int repondues;
  final DateTime startedAt;
  final DateTime? completedAt;

  factory CivicDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      CivicDiagnosticDto(
        sessionId: json['sessionId'] as String,
        attemptId: json['attemptId'] as String,
        status: TcfDiagnosticStatus.fromWire(json['status'] as String),
        mention: Difficulty.fromWire(json['mention'] as String),
        total: (json['total'] as num? ?? 0).toInt(),
        repondues: (json['repondues'] as num? ?? 0).toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );
}

/// Un thème et son état. `taux == null` = **non évalué**, jamais `0`.
class CivicThemeResultat {
  const CivicThemeResultat({
    required this.themeId,
    required this.code,
    required this.label,
    required this.etat,
    required this.bonnes,
    required this.posees,
    this.taux,
  });

  final String themeId;
  final String code;
  final String label;
  final CivicThemeState etat;
  final int bonnes;
  final int posees;

  /// 🛑 `null`, pas `0.0` : une barre à zéro se lit « tout faux » alors que la
  /// vérité est « rien de posé ».
  final double? taux;

  factory CivicThemeResultat.fromJson(Map<String, dynamic> json) =>
      CivicThemeResultat(
        themeId: json['themeId'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        etat: CivicThemeState.fromWire(json['etat'] as String),
        bonnes: (json['bonnes'] as num? ?? 0).toInt(),
        posees: (json['posees'] as num? ?? 0).toInt(),
        taux: (json['taux'] as num?)?.toDouble(),
      );
}

/// Un thème qui coûte des points.
///
/// 🛑 **Le rang n'est pas un score** : il ordonne, il ne quantifie pas.
class CivicPrioriteTheme {
  const CivicPrioriteTheme({
    required this.rang,
    required this.themeId,
    required this.code,
    required this.label,
    required this.etat,
    required this.manques,
  });

  final int rang;
  final String themeId;
  final String code;
  final String label;
  final CivicThemeState etat;
  final int manques;

  factory CivicPrioriteTheme.fromJson(Map<String, dynamic> json) =>
      CivicPrioriteTheme(
        rang: (json['rang'] as num? ?? 0).toInt(),
        themeId: json['themeId'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        etat: CivicThemeState.fromWire(json['etat'] as String),
        manques: (json['manques'] as num? ?? 0).toInt(),
      );
}

/// Les mises en situation, comptées **à part**.
typedef CivicSituations = ({int reussies, int posees});

/// L'écran de résultat du diagnostic civique (`20_` §4.5).
///
/// 🛑 **Le constat est intégralement gratuit** : aucun `locked` ici. Le paywall
/// porte sur l'accompagnement, jamais sur ce que le candidat vient de mesurer.
class CivicDiagnosticResultDto {
  const CivicDiagnosticResultDto({
    required this.sessionId,
    required this.mention,
    required this.bonnes,
    required this.posees,
    required this.seuilReussite,
    required this.formatQuestions,
    required this.themes,
    required this.situations,
    required this.priorites,
    this.projection40,
    this.completedAt,
  });

  final String sessionId;
  final Difficulty mention;
  final int bonnes;
  final int posees;

  /// 🛑 Vient du **serveur** : ni écrite en dur, ni recalculée ici. `null` si
  /// rien n'a été posé — « on n'a rien mesuré » ne se dit pas « 0 sur 40 ».
  final int? projection40;

  final int seuilReussite;

  /// 40, le format de l'épreuve réelle — **servi**, pas écrit en dur.
  ///
  /// 🛑 Quand `posees == formatQuestions`, le score **est** le résultat et
  /// l'écran le dit tel quel.
  final int formatQuestions;

  /// Les 5 thèmes, **tous**, y compris ceux qu'aucune question n'a touchés.
  final List<CivicThemeResultat> themes;
  final CivicSituations situations;

  /// Au niveau THÈME tant que le tagging des notions n'est pas fait (`20_` §3.4).
  final List<CivicPrioriteTheme> priorites;
  final DateTime? completedAt;

  factory CivicDiagnosticResultDto.fromJson(Map<String, dynamic> json) {
    final situations = json['situations'] as Map<String, dynamic>?;
    return CivicDiagnosticResultDto(
      sessionId: json['sessionId'] as String,
      mention: Difficulty.fromWire(json['mention'] as String),
      bonnes: (json['bonnes'] as num? ?? 0).toInt(),
      posees: (json['posees'] as num? ?? 0).toInt(),
      projection40: (json['projection40'] as num?)?.toInt(),
      seuilReussite: (json['seuilReussite'] as num? ?? 0).toInt(),
      formatQuestions: (json['formatQuestions'] as num? ?? 0).toInt(),
      themes: (json['themes'] as List<dynamic>? ?? const [])
          .map((e) => CivicThemeResultat.fromJson(e as Map<String, dynamic>))
          .toList(),
      situations: (
        reussies: (situations?['reussies'] as num? ?? 0).toInt(),
        posees: (situations?['posees'] as num? ?? 0).toInt(),
      ),
      priorites: (json['priorites'] as List<dynamic>? ?? const [])
          .map((e) => CivicPrioriteTheme.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
