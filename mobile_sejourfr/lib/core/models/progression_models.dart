import 'civic_diagnostic_models.dart' show CivicThemeState;
import 'enums.dart';
import 'full_tcf_exam.dart' show ContinuiteSimulation;
import 'progress_models.dart' show NiveauEvolution;

/// Miroirs de `/api/me/progression/*` — les quatre écrans de progression
/// (2026-09-24). Contrat : `docs/regles/progression.md` § « Écrans de
/// progression ».
///
/// 🛑 **Tout est SERVI** : états, bandes, écarts, sens, ordinaux, durées
/// fiables, meilleur / premier / dernier, verrou du bouton. L'app place des
/// points et pose des libellés ; elle ne recalcule ni ne classe rien.

/// Ce que mesure un axe : score de progression /499 (CO/CE, **sans bande**),
/// note officielle /20 (EE/EO), bonnes réponses (civique).
enum ProgressionUnite {
  progression499('PROGRESSION_499'),
  note20('NOTE_20'),
  questions('QUESTIONS');

  const ProgressionUnite(this.wire);
  final String wire;

  static ProgressionUnite fromWire(String value) =>
      ProgressionUnite.values.firstWhere((e) => e.wire == value);
}

enum ProgressionProvenance {
  epreuveSeule('EPREUVE_SEULE'),
  examenComplet('EXAMEN_COMPLET'),
  examenTheme('EXAMEN_THEME'),
  examenGlobal('EXAMEN_GLOBAL');

  const ProgressionProvenance(this.wire);
  final String wire;

  static ProgressionProvenance fromWire(String value) =>
      ProgressionProvenance.values.firstWhere((e) => e.wire == value);
}

/// Quel rapport ouvre « Voir → ». 🛑 Choisi par ce champ, jamais par une route.
enum ProgressionRapport {
  qcm('QCM'),
  production('PRODUCTION'),
  examenComplet('EXAMEN_COMPLET');

  const ProgressionRapport(this.wire);
  final String wire;

  static ProgressionRapport fromWire(String value) =>
      ProgressionRapport.values.firstWhere((e) => e.wire == value);
}

/// D'où vient l'état d'un thème sur son écran (D13). Libellé gelé côté serveur
/// (`ProgressionEchelleResolverTest`) — et servi aussi en toutes lettres.
enum ProgressionEtatSource {
  dernierExamenTheme(
      'DERNIER_EXAMEN_THEME', "D'après votre dernier examen de ce thème");

  const ProgressionEtatSource(this.wire, this.label);
  final String wire;
  final String label;

  static ProgressionEtatSource fromWire(String value) =>
      ProgressionEtatSource.values.firstWhere((e) => e.wire == value);
}

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
int? _intN(Object? v) => (v as num?)?.toInt();
double? _doubleN(Object? v) => (v as num?)?.toDouble();
DateTime? _date(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();
List<Map<String, dynamic>> _list(Object? v) =>
    ((v as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();

/// Une zone de l'axe, bornes incluses. [niveau] en EE/EO, [etat] en civique.
class ProgressionBande {
  const ProgressionBande({
    required this.niveau,
    required this.etat,
    required this.min,
    required this.max,
  });

  final NiveauCecrl? niveau;
  final CivicThemeState? etat;
  final int min;
  final int max;

  factory ProgressionBande.fromJson(Map<String, dynamic> json) =>
      ProgressionBande(
        niveau: NiveauCecrl.fromWireNullable(json['niveau'] as String?),
        etat: json['etat'] == null
            ? null
            : CivicThemeState.fromWire(json['etat'] as String),
        min: _int(json['min']),
        max: _int(json['max']),
      );
}

class ProgressionEchelle {
  const ProgressionEchelle({
    required this.unite,
    required this.min,
    required this.max,
    required this.seuil,
    required this.bandes,
    required this.reperes,
  });

  final ProgressionUnite unite;
  final int min;
  final int max;

  /// Civique seulement (16 / 20, 32 / 40).
  final int? seuil;

  /// 🛑 Vide en CO/CE.
  final List<ProgressionBande> bandes;

  /// Lignes neutres de l'axe.
  final List<int> reperes;

  factory ProgressionEchelle.fromJson(Map<String, dynamic> json) =>
      ProgressionEchelle(
        unite: ProgressionUnite.fromWire(json['unite'] as String),
        min: _int(json['min']),
        max: _int(json['max']),
        seuil: _intN(json['seuil']),
        bandes: _list(json['bandes']).map(ProgressionBande.fromJson).toList(),
        reperes: ((json['reperes'] as List<dynamic>?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
}

/// Un examen blanc : un point de la courbe ET une ligne de la liste.
class ProgressionMesure {
  const ProgressionMesure({
    required this.attemptId,
    required this.numero,
    required this.date,
    required this.score,
    required this.max,
    required this.niveau,
    required this.etat,
    required this.seuilAtteint,
    required this.pointsManquants,
    required this.taux,
    required this.dureeSecondes,
    required this.provenance,
    required this.rapportKind,
    required this.rapportAttemptId,
  });

  final String attemptId;

  /// Ordinal chronologique, 1 = le plus ancien. Jamais le `slotNumber`.
  final int numero;
  final DateTime? date;

  /// /499, /20 (une décimale) ou bonnes réponses ; null = inconnu (« — »).
  final double? score;
  final int max;

  /// TCF : palier DE CET EXAMEN. Null en civique.
  final NiveauCecrl? niveau;

  /// Civique : état de l'examen. Null en TCF.
  final CivicThemeState? etat;
  final bool? seuilAtteint;
  final int? pointsManquants;

  /// Civique : bonnes / posées (0..1), ce que remplit l'anneau. Null en TCF.
  final double? taux;

  /// Servie seulement si fiable ; null ⇒ « — » (toujours en EO).
  final int? dureeSecondes;
  final ProgressionProvenance provenance;
  final ProgressionRapport rapportKind;

  /// L'attempt à ouvrir — le PARENT pour [ProgressionRapport.examenComplet].
  final String rapportAttemptId;

  factory ProgressionMesure.fromJson(Map<String, dynamic> json) {
    final rapport = json['rapport'] as Map<String, dynamic>;
    return ProgressionMesure(
      attemptId: json['attemptId'] as String,
      numero: _int(json['numero']),
      date: _date(json['date']),
      score: _doubleN(json['score']),
      max: _int(json['max']),
      niveau: NiveauCecrl.fromWireNullable(json['niveau'] as String?),
      etat: json['etat'] == null
          ? null
          : CivicThemeState.fromWire(json['etat'] as String),
      seuilAtteint: json['seuilAtteint'] as bool?,
      pointsManquants: _intN(json['pointsManquants']),
      taux: _doubleN(json['taux']),
      dureeSecondes: _intN(json['dureeSecondes']),
      provenance: ProgressionProvenance.fromWire(json['provenance'] as String),
      rapportKind: ProgressionRapport.fromWire(rapport['kind'] as String),
      rapportAttemptId: rapport['attemptId'] as String,
    );
  }
}

class ProgressionResume {
  const ProgressionResume({
    required this.nombre,
    required this.dernier,
    required this.meilleur,
    required this.premier,
    required this.ecart,
    required this.sens,
    required this.serie,
  });

  final int nombre;
  final ProgressionMesure? dernier;

  /// Plus haut score ; à égalité, le plus récent.
  final ProgressionMesure? meilleur;

  /// Le plus ancien portant un score.
  final ProgressionMesure? premier;

  /// dernier − premier ; 🛑 null avec un seul examen (jamais « +0 »).
  final double? ecart;
  final NiveauEvolution sens;

  /// Sparkline : au plus 7 scores, du plus ancien au plus récent.
  final List<double> serie;

  static ProgressionMesure? _m(Object? v) =>
      v == null ? null : ProgressionMesure.fromJson(v as Map<String, dynamic>);

  factory ProgressionResume.fromJson(Map<String, dynamic> json) =>
      ProgressionResume(
        nombre: _int(json['nombre']),
        dernier: _m(json['dernier']),
        meilleur: _m(json['meilleur']),
        premier: _m(json['premier']),
        ecart: _doubleN(json['ecart']),
        sens: NiveauEvolution.fromWire(json['sens'] as String? ?? 'INCONNUE'),
        serie: ((json['serie'] as List<dynamic>?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

/// 🛑 D20 : seul le bouton porte un cadenas ; tous les résultats sont visibles.
class ProgressionCta {
  const ProgressionCta({required this.locked});

  final bool locked;

  factory ProgressionCta.fromJson(Map<String, dynamic>? json) =>
      ProgressionCta(locked: json?['locked'] as bool? ?? false);
}

/// `GET /api/me/progression/tcf/{epreuve}`.
class ProgressionEpreuve {
  const ProgressionEpreuve({
    required this.epreuve,
    required this.echelle,
    required this.resume,
    required this.niveauActuel,
    required this.examens,
    required this.cta,
  });

  final EpreuveType epreuve;
  final ProgressionEchelle echelle;
  final ProgressionResume resume;

  /// Niveau actuel estimé (le chiffre de l'Accueil) — ligne secondaire (D4).
  final NiveauCecrl? niveauActuel;

  /// Tous les examens (≤ 50), du plus récent au plus ancien.
  final List<ProgressionMesure> examens;
  final ProgressionCta cta;

  factory ProgressionEpreuve.fromJson(Map<String, dynamic> json) =>
      ProgressionEpreuve(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        echelle: ProgressionEchelle.fromJson(
            json['echelle'] as Map<String, dynamic>),
        resume:
            ProgressionResume.fromJson(json['resume'] as Map<String, dynamic>),
        niveauActuel:
            NiveauCecrl.fromWireNullable(json['niveauActuel'] as String?),
        examens: _list(json['examens']).map(ProgressionMesure.fromJson).toList(),
        cta: ProgressionCta.fromJson(json['cta'] as Map<String, dynamic>?),
      );
}

/// Une épreuve d'un examen complet. [score] null = « — », jamais 0.
class ProgressionEpreuveLigne {
  const ProgressionEpreuveLigne({
    required this.epreuve,
    required this.attemptId,
    required this.score,
    required this.max,
    required this.niveau,
    required this.locked,
  });

  final EpreuveType epreuve;
  final String? attemptId;
  final double? score;
  final int max;
  final NiveauCecrl? niveau;
  final bool locked;

  factory ProgressionEpreuveLigne.fromJson(Map<String, dynamic> json) =>
      ProgressionEpreuveLigne(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        attemptId: json['attemptId'] as String?,
        score: _doubleN(json['score']),
        max: _int(json['max']),
        niveau: NiveauCecrl.fromWireNullable(json['niveau'] as String?),
        locked: json['locked'] as bool? ?? false,
      );
}

/// Un examen blanc complet. « Voir → » ouvre son bilan ([attemptId] = parent).
class ProgressionExamenComplet {
  const ProgressionExamenComplet({
    required this.attemptId,
    required this.numero,
    required this.date,
    required this.niveau,
    required this.partiel,
    required this.epreuvesComptees,
    required this.continuite,
    required this.parEpreuve,
  });

  final String attemptId;
  final int numero;
  final DateTime? date;

  /// Palier global re-dérivé à la lecture ; null tant qu'une évaluation est en vol.
  final NiveauCecrl? niveau;
  final bool partiel;
  final int epreuvesComptees;
  final ContinuiteSimulation? continuite;

  /// CO, CE, EE, EO.
  final List<ProgressionEpreuveLigne> parEpreuve;

  factory ProgressionExamenComplet.fromJson(Map<String, dynamic> json) =>
      ProgressionExamenComplet(
        attemptId: json['attemptId'] as String,
        numero: _int(json['numero']),
        date: _date(json['date']),
        niveau: NiveauCecrl.fromWireNullable(json['niveau'] as String?),
        partiel: json['partiel'] as bool? ?? false,
        epreuvesComptees: _int(json['epreuvesComptees']),
        continuite:
            ContinuiteSimulation.fromWireNullable(json['continuite'] as String?),
        parEpreuve: _list(json['parEpreuve'])
            .map(ProgressionEpreuveLigne.fromJson)
            .toList(),
      );
}

/// 🛑 D7 : examens terminés avec ≥ 1 épreuve mesurée ; meilleur / premier non
/// partiels.
class ProgressionExamensComplets {
  const ProgressionExamensComplets({
    required this.nombre,
    required this.dernier,
    required this.meilleur,
    required this.premier,
    required this.evolution,
  });

  final int nombre;
  final ProgressionExamenComplet? dernier;
  final ProgressionExamenComplet? meilleur;
  final ProgressionExamenComplet? premier;
  final NiveauEvolution evolution;

  static ProgressionExamenComplet? _e(Object? v) => v == null
      ? null
      : ProgressionExamenComplet.fromJson(v as Map<String, dynamic>);

  factory ProgressionExamensComplets.fromJson(Map<String, dynamic> json) =>
      ProgressionExamensComplets(
        nombre: _int(json['nombre']),
        dernier: _e(json['dernier']),
        meilleur: _e(json['meilleur']),
        premier: _e(json['premier']),
        evolution:
            NiveauEvolution.fromWire(json['evolution'] as String? ?? 'INCONNUE'),
      );
}

/// Carte d'une épreuve ou d'un thème : le même résumé que l'en-tête de son écran.
class ProgressionCarte {
  const ProgressionCarte({
    required this.epreuve,
    required this.themeId,
    required this.code,
    required this.label,
    required this.echelle,
    required this.resume,
  });

  /// TCF seulement.
  final EpreuveType? epreuve;

  /// Civique seulement.
  final String? themeId;
  final String? code;
  final String? label;
  final ProgressionEchelle echelle;
  final ProgressionResume resume;

  factory ProgressionCarte.fromJson(Map<String, dynamic> json) =>
      ProgressionCarte(
        epreuve: json['epreuve'] == null
            ? null
            : EpreuveType.fromWire(json['epreuve'] as String),
        themeId: json['themeId'] as String?,
        code: json['code'] as String?,
        label: json['label'] as String?,
        echelle: ProgressionEchelle.fromJson(
            json['echelle'] as Map<String, dynamic>),
        resume:
            ProgressionResume.fromJson(json['resume'] as Map<String, dynamic>),
      );
}

/// `GET /api/me/progression/tcf[?tous=true]`. 🛑 Aucun score global (D6).
class ProgressionTcf {
  const ProgressionTcf({
    required this.niveauActuel,
    required this.niveauActuelEpreuves,
    required this.niveauActuelPartiel,
    required this.examensComplets,
    required this.epreuves,
    required this.examens,
    required this.cta,
  });

  final NiveauCecrl? niveauActuel;
  final int niveauActuelEpreuves;
  final bool niveauActuelPartiel;
  final ProgressionExamensComplets examensComplets;

  /// Toujours les 4, ordre CO, CE, EE, EO.
  final List<ProgressionCarte> epreuves;

  /// 3 derniers, ou tous (≤ 50) avec `?tous=true`.
  final List<ProgressionExamenComplet> examens;
  final ProgressionCta cta;

  factory ProgressionTcf.fromJson(Map<String, dynamic> json) => ProgressionTcf(
        niveauActuel:
            NiveauCecrl.fromWireNullable(json['niveauActuel'] as String?),
        niveauActuelEpreuves: _int(json['niveauActuelEpreuves']),
        niveauActuelPartiel: json['niveauActuelPartiel'] as bool? ?? false,
        examensComplets: ProgressionExamensComplets.fromJson(
            json['examensComplets'] as Map<String, dynamic>),
        epreuves: _list(json['epreuves']).map(ProgressionCarte.fromJson).toList(),
        examens: _list(json['examens'])
            .map(ProgressionExamenComplet.fromJson)
            .toList(),
        cta: ProgressionCta.fromJson(json['cta'] as Map<String, dynamic>?),
      );
}

/// Part d'un thème dans un examen global : « x / n posées », jamais « / 20 ».
class ProgressionPartTheme {
  const ProgressionPartTheme({
    required this.themeId,
    required this.code,
    required this.label,
    required this.bonnes,
    required this.posees,
  });

  final String themeId;
  final String code;
  final String label;
  final int bonnes;

  /// 0 = thème non posé (« — »), pas raté.
  final int posees;

  factory ProgressionPartTheme.fromJson(Map<String, dynamic> json) =>
      ProgressionPartTheme(
        themeId: json['themeId'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        bonnes: _int(json['bonnes']),
        posees: _int(json['posees']),
      );
}

class ProgressionExamenGlobal {
  const ProgressionExamenGlobal({required this.mesure, required this.parTheme});

  final ProgressionMesure mesure;
  final List<ProgressionPartTheme> parTheme;

  factory ProgressionExamenGlobal.fromJson(Map<String, dynamic> json) =>
      ProgressionExamenGlobal(
        mesure:
            ProgressionMesure.fromJson(json['mesure'] as Map<String, dynamic>),
        parTheme:
            _list(json['parTheme']).map(ProgressionPartTheme.fromJson).toList(),
      );
}

/// `GET /api/me/progression/civique[?tous=true]`.
class ProgressionCivique {
  const ProgressionCivique({
    required this.echelle,
    required this.global,
    required this.themes,
    required this.examens,
    required this.cta,
  });

  final ProgressionEchelle echelle;
  final ProgressionResume global;

  /// Toujours les 5 thèmes, ordre officiel ; résumés sur leurs examens de thème.
  final List<ProgressionCarte> themes;

  /// 3 derniers, ou tous (≤ 50) avec `?tous=true` ; le total est `global.nombre`.
  final List<ProgressionExamenGlobal> examens;
  final ProgressionCta cta;

  factory ProgressionCivique.fromJson(Map<String, dynamic> json) =>
      ProgressionCivique(
        echelle: ProgressionEchelle.fromJson(
            json['echelle'] as Map<String, dynamic>),
        global:
            ProgressionResume.fromJson(json['global'] as Map<String, dynamic>),
        themes: _list(json['themes']).map(ProgressionCarte.fromJson).toList(),
        examens: _list(json['examens'])
            .map(ProgressionExamenGlobal.fromJson)
            .toList(),
        cta: ProgressionCta.fromJson(json['cta'] as Map<String, dynamic>?),
      );
}

/// `GET /api/me/progression/civique/themes/{themeId}`.
class ProgressionTheme {
  const ProgressionTheme({
    required this.themeId,
    required this.code,
    required this.label,
    required this.echelle,
    required this.resume,
    required this.etat,
    required this.etatSource,
    required this.etatSourceLabel,
    required this.examens,
    required this.cta,
  });

  final String themeId;
  final String code;
  final String label;
  final ProgressionEchelle echelle;
  final ProgressionResume resume;

  /// État d'après le DERNIER EXAMEN DE CE THÈME (pas celui de l'Accueil, D13).
  final CivicThemeState? etat;
  final ProgressionEtatSource etatSource;

  /// Phrase servie, à afficher à côté de l'état.
  final String etatSourceLabel;
  final List<ProgressionMesure> examens;
  final ProgressionCta cta;

  factory ProgressionTheme.fromJson(Map<String, dynamic> json) =>
      ProgressionTheme(
        themeId: json['themeId'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        echelle: ProgressionEchelle.fromJson(
            json['echelle'] as Map<String, dynamic>),
        resume:
            ProgressionResume.fromJson(json['resume'] as Map<String, dynamic>),
        etat: json['etat'] == null
            ? null
            : CivicThemeState.fromWire(json['etat'] as String),
        etatSource:
            ProgressionEtatSource.fromWire(json['etatSource'] as String),
        etatSourceLabel: json['etatSourceLabel'] as String? ?? '',
        examens: _list(json['examens']).map(ProgressionMesure.fromJson).toList(),
        cta: ProgressionCta.fromJson(json['cta'] as Map<String, dynamic>?),
      );
}
