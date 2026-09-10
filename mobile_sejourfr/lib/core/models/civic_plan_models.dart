import 'civic_diagnostic_models.dart';
import 'enums.dart';

/// Miroirs de `CivicPlanDto` (L10, `20_` §6).
///
/// 🛑 **Des faits, jamais des phrases** : aucun `reason_text` n'arrive du
/// serveur. Les libellés vivent dans `screens/plan/civic_plan_labels.dart`,
/// miroir mot pour mot de `web_sejoufr/lib/civic-plan.ts`.
///
/// 🛑 **Rien n'est persisté côté serveur** : le plan se recalcule à chaque
/// lecture depuis l'historique des réponses. Il n'y a donc pas de « recompute ».

/// L'état de maîtrise d'une cible civique (`20_` §5.2).
///
/// 🛑 [nonEvaluee] n'est **pas** un mauvais verdict : moins de deux réponses ne
/// conclut rien. C'est l'invariant `null = inconnu` appliqué au civique.
enum CivicMaitrise {
  nonEvaluee('NON_EVALUEE', 'Non évaluée'),
  aTravailler('A_TRAVAILLER', 'À travailler'),
  enProgression('EN_PROGRESSION', 'En progression'),
  maitrisee('MAITRISEE', 'Maîtrisée');

  const CivicMaitrise(this.wire, this.label);

  final String wire;

  /// Libellé FR **gelé** : miroir de `CIVIC_MAITRISE_LABEL` côté web.
  final String label;

  static CivicMaitrise fromWire(String value) => CivicMaitrise.values
      .firstWhere((e) => e.wire == value, orElse: () => CivicMaitrise.nonEvaluee);
}

/// Le **grain** auquel le plan travaille (`20_` §3.3).
///
/// 🛑 Il se **mesure**, il ne se décrète pas. Tant que les questions ne sont pas
/// taguées, [theme] est le mode **prévu** par la spec, pas une panne.
enum CivicPlanGrain {
  theme('THEME'),
  notion('NOTION');

  const CivicPlanGrain(this.wire);

  final String wire;

  static CivicPlanGrain fromWire(String value) => CivicPlanGrain.values
      .firstWhere((e) => e.wire == value, orElse: () => CivicPlanGrain.theme);
}

/// L'état du tagging, et ce qu'il autorise.
class CivicPlanGrainDto {
  const CivicPlanGrainDto({
    required this.courant,
    required this.themesParNotion,
    required this.themesTotal,
    required this.taguees,
    required this.total,
  });

  /// `notion` seulement quand **tous** les thèmes ont basculé.
  final CivicPlanGrain courant;
  final int themesParNotion;
  final int themesTotal;
  final int taguees;
  final int total;

  static CivicPlanGrainDto fromJson(Map<String, dynamic> json) => CivicPlanGrainDto(
        courant: CivicPlanGrain.fromWire(json['courant'] as String? ?? 'THEME'),
        themesParNotion: (json['themesParNotion'] as num?)?.toInt() ?? 0,
        themesTotal: (json['themesTotal'] as num?)?.toInt() ?? 0,
        taguees: (json['taguees'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

/// La dernière mesure **comparable au seuil** : le diagnostic.
///
/// 🛑 Ce n'est **pas** une estimation courante. Mélanger des séries
/// d'entraînement à un examen produirait un nombre qui ressemble à un score sans
/// en être un.
class CivicPlanResultat {
  const CivicPlanResultat({
    required this.bonnes,
    required this.posees,
    required this.seuil,
    required this.format,
    this.mesureA,
  });

  final int bonnes;
  final int posees;
  final int seuil;
  final int format;
  final DateTime? mesureA;

  static CivicPlanResultat fromJson(Map<String, dynamic> json) => CivicPlanResultat(
        bonnes: (json['bonnes'] as num?)?.toInt() ?? 0,
        posees: (json['posees'] as num?)?.toInt() ?? 0,
        seuil: (json['seuil'] as num?)?.toInt() ?? 0,
        format: (json['format'] as num?)?.toInt() ?? 0,
        mesureA: DateTime.tryParse(json['mesureA'] as String? ?? ''),
      );
}

/// Une cible du plan : une **notion**, ou un **thème** tant que ce thème n'a pas
/// basculé.
///
/// 🛑 **Tout est dérivé serveur** — [maitrise], [boite] et [prochaineRevue] se
/// replient sur l'historique des réponses à chaque lecture. Aucun front ne
/// classe un compteur en état pédagogique.
class CivicPlanCible {
  const CivicPlanCible({
    required this.id,
    required this.code,
    required this.label,
    required this.grain,
    required this.themeId,
    required this.themeCode,
    required this.themeLabel,
    required this.etatDuTheme,
    required this.maitrise,
    required this.boite,
    required this.reponses,
    required this.correctes,
    required this.erreursRecentes,
    required this.aRevoir,
    required this.score,
    required this.contenuInsuffisant,
    required this.questionsSerie,
    required this.dureeEstimeeSec,
    required this.locked,
    this.derniereErreur,
    this.prochaineRevue,
  });

  final String id;
  final String code;
  final String label;
  final CivicPlanGrain grain;
  final String themeId;
  final String themeCode;
  final String themeLabel;

  /// 🛑 `nonEvalue` n'est pas « faible ».
  final CivicThemeState etatDuTheme;
  final CivicMaitrise maitrise;
  final int boite;
  final int reponses;
  final int correctes;
  final int erreursRecentes;
  final DateTime? derniereErreur;

  /// `null` = jamais vue, donc **jamais** « en retard ».
  final DateTime? prochaineRevue;
  final bool aRevoir;

  /// Servi pour l'admin et les tests — **jamais montré au candidat**.
  final int score;
  final bool contenuInsuffisant;
  final int questionsSerie;
  final int dureeEstimeeSec;

  /// 🛑 Le verrou porte sur la **série**, jamais sur le constat.
  final bool locked;

  static CivicPlanCible fromJson(Map<String, dynamic> json) => CivicPlanCible(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        grain: CivicPlanGrain.fromWire(json['grain'] as String? ?? 'THEME'),
        themeId: json['themeId'] as String? ?? '',
        themeCode: json['themeCode'] as String? ?? '',
        themeLabel: json['themeLabel'] as String? ?? '',
        etatDuTheme:
            CivicThemeState.fromWire(json['etatDuTheme'] as String? ?? 'NON_EVALUE'),
        maitrise: CivicMaitrise.fromWire(json['maitrise'] as String? ?? 'NON_EVALUEE'),
        boite: (json['boite'] as num?)?.toInt() ?? 1,
        reponses: (json['reponses'] as num?)?.toInt() ?? 0,
        correctes: (json['correctes'] as num?)?.toInt() ?? 0,
        erreursRecentes: (json['erreursRecentes'] as num?)?.toInt() ?? 0,
        derniereErreur: DateTime.tryParse(json['derniereErreur'] as String? ?? ''),
        prochaineRevue: DateTime.tryParse(json['prochaineRevue'] as String? ?? ''),
        aRevoir: json['aRevoir'] as bool? ?? false,
        score: (json['score'] as num?)?.toInt() ?? 0,
        contenuInsuffisant: json['contenuInsuffisant'] as bool? ?? false,
        questionsSerie: (json['questionsSerie'] as num?)?.toInt() ?? 0,
        dureeEstimeeSec: (json['dureeEstimeeSec'] as num?)?.toInt() ?? 0,
        locked: json['locked'] as bool? ?? false,
      );
}

/// **Le plan civique**.
class CivicPlan {
  const CivicPlan({
    required this.disponible,
    required this.mention,
    required this.priorites,
    required this.autresPriorites,
    required this.aRevoir,
    required this.solides,
    required this.grain,
    this.resultat,
    this.prochaine,
  });

  /// `false` quand aucun diagnostic n'est terminé : rien à bâtir.
  final bool disponible;
  final Difficulty mention;
  final CivicPlanResultat? resultat;

  /// « À faire maintenant » — la cible de rang 1.
  final CivicPlanCible? prochaine;

  /// 🛑 Plafond d'**affichage** : le moteur en a classé davantage.
  final List<CivicPlanCible> priorites;

  /// Ce que la liste ne montre pas (« + 6 autres notions à consolider »).
  final int autresPriorites;

  /// Révisions d'entretien. 🛑 **Jamais une priorité rouge** (`20_` §5.2).
  final List<CivicPlanCible> aRevoir;
  final List<CivicPlanCible> solides;
  final CivicPlanGrainDto grain;

  static List<CivicPlanCible> _cibles(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((e) => CivicPlanCible.fromJson(e as Map<String, dynamic>))
          .toList();

  static CivicPlan fromJson(Map<String, dynamic> json) => CivicPlan(
        disponible: json['disponible'] as bool? ?? false,
        mention: Difficulty.fromWire(json['mention'] as String? ?? 'CSP'),
        resultat: json['resultat'] == null
            ? null
            : CivicPlanResultat.fromJson(json['resultat'] as Map<String, dynamic>),
        prochaine: json['prochaine'] == null
            ? null
            : CivicPlanCible.fromJson(json['prochaine'] as Map<String, dynamic>),
        priorites: _cibles(json['priorites']),
        autresPriorites: (json['autresPriorites'] as num?)?.toInt() ?? 0,
        aRevoir: _cibles(json['aRevoir']),
        solides: _cibles(json['solides']),
        grain: CivicPlanGrainDto.fromJson(
            json['grain'] as Map<String, dynamic>? ?? const {}),
      );
}
