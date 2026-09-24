import 'civic_plan_models.dart';
import 'diagnostic_models.dart';
import 'enums.dart';

/// Miroirs de `ProgressDto` — ce que l'**Accueil** lit de la progression
/// (`GET /api/me/progress`, « Où vous en êtes »).
///
/// ⚠️ **Élagué le 2026-09-24** avec l'ancien écran Progrès : l'activité, la
/// courbe des diagnostics, le palier global, les compteurs de compétences et
/// les compteurs civiques ne sont plus servis. Les écrans de progression lisent
/// `/api/me/progression/*` (`progression_models.dart`).
///
/// 🛑 **Rien n'est calculé côté app** : les paliers, les sens d'évolution et les
/// états arrivent servis.

/// Le sens d'une comparaison de paliers.
///
/// 🛑 [inconnue] n'est **pas** [stable] : une épreuve non évaluée d'un côté n'a
/// ni progressé ni tenu. Les confondre déguiserait l'incident V040/V041/V042 en
/// bonne nouvelle. 🛑 [baisse] existe et se sert.
enum NiveauEvolution {
  hausse('HAUSSE'),
  stable('STABLE'),
  baisse('BAISSE'),
  inconnue('INCONNUE');

  const NiveauEvolution(this.wire);

  final String wire;

  static NiveauEvolution fromWire(String value) => NiveauEvolution.values
      .firstWhere((e) => e.wire == value, orElse: () => NiveauEvolution.inconnue);
}

/// Où en est une épreuve **face à l'objectif** du candidat — dérivé serveur
/// (`StatutObjectifResolver`), jamais recalculé ici.
///
/// 🛑 [toReinforce] recouvre **deux** situations : « mesuré, et loin » et
/// « jamais mesuré ». C'est [ProgressEpreuve.niveau] qui les distingue, et il
/// vaut `null` dans le second cas — les confondre à l'écran rejouerait
/// l'incident V040/V041/V042.
enum StatutObjectif {
  targetReached('TARGET_REACHED'),
  closeToTarget('CLOSE_TO_TARGET'),
  toReinforce('TO_REINFORCE');

  const StatutObjectif(this.wire);

  final String wire;

  static StatutObjectif? fromWire(String? value) {
    if (value == null) return null;
    for (final statut in StatutObjectif.values) {
      if (statut.wire == value) return statut;
    }
    return null;
  }
}

/// Une épreuve, son palier d'aujourd'hui, et ce qui a bougé.
class ProgressEpreuve {
  const ProgressEpreuve({
    required this.epreuve,
    required this.evolution,
    this.niveau,
    this.niveauInitial,
    this.status,
    this.evaluation,
  });

  final EpreuveType epreuve;

  /// `null` = jamais évaluée. 🛑 Jamais rendu en « A1 ».
  final NiveauCecrl? niveau;
  final NiveauCecrl? niveauInitial;
  final NiveauEvolution evolution;

  /// 🛑 `null` quand aucune démarche n'est déclarée : rien à comparer.
  final StatutObjectif? status;

  /// **Par quoi mesurer cette épreuve**, quand elle ne l'a **jamais** été
  /// ([niveau] `null`). `null` dès qu'un palier existe : il n'y a plus rien à
  /// lancer.
  ///
  /// 🛑 **Même descripteur que « Compléter mon profil » et que la ligne
  /// `A_EVALUER` de la séance**, donc **même lanceur** — `openPlanAssessment`,
  /// jamais un second. C'est ce qui fait que « Évaluer mon niveau » sur
  /// l'Accueil ouvre exactement le parcours que le Plan ouvrirait pour le même
  /// domaine.
  final PlanDomainAssessment? evaluation;

  static ProgressEpreuve fromJson(Map<String, dynamic> json) => ProgressEpreuve(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        niveau: json['niveau'] == null
            ? null
            : NiveauCecrl.fromWire(json['niveau'] as String),
        niveauInitial: json['niveauInitial'] == null
            ? null
            : NiveauCecrl.fromWire(json['niveauInitial'] as String),
        evolution:
            NiveauEvolution.fromWire(json['evolution'] as String? ?? 'INCONNUE'),
        status: StatutObjectif.fromWire(json['status'] as String?),
        evaluation: json['evaluation'] == null
            ? null
            : PlanDomainAssessment.fromJson(
                json['evaluation'] as Map<String, dynamic>),
      );
}

class ProgressTcf {
  const ProgressTcf({required this.epreuves, this.objectif});

  /// 🛑 `null` quand aucune démarche n'est déclarée : on ne devine jamais.
  final NiveauCecrl? objectif;

  /// Les 4 épreuves, **toutes**, évaluées ou non. La liste n'est jamais vide.
  final List<ProgressEpreuve> epreuves;

  static ProgressTcf fromJson(Map<String, dynamic> json) => ProgressTcf(
        objectif: json['objectif'] == null
            ? null
            : NiveauCecrl.fromWire(json['objectif'] as String),
        epreuves: (json['epreuves'] as List<dynamic>? ?? const [])
            .map((e) => ProgressEpreuve.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Un résultat civique, directement comparable au seuil.
class ProgressScore {
  const ProgressScore({
    required this.sessionId,
    required this.bonnes,
    required this.posees,
    required this.seuil,
    required this.format,
    this.mesureA,
  });

  final String sessionId;
  final int bonnes;
  final int posees;
  final int seuil;
  final int format;
  final DateTime? mesureA;

  static ProgressScore fromJson(Map<String, dynamic> json) => ProgressScore(
        sessionId: json['sessionId'] as String? ?? '',
        bonnes: (json['bonnes'] as num?)?.toInt() ?? 0,
        posees: (json['posees'] as num?)?.toInt() ?? 0,
        seuil: (json['seuil'] as num?)?.toInt() ?? 0,
        format: (json['format'] as num?)?.toInt() ?? 0,
        mesureA: DateTime.tryParse(json['mesureA'] as String? ?? ''),
      );
}

/// 🛑 **Aucune métrique CECRL côté civique** (`20_` §12).
class ProgressCivique {
  const ProgressCivique({
    required this.historique,
    this.themes = const <CivicPlanThemeLigne>[],
  });

  /// Les diagnostics clos, du plus ancien au plus récent — l'Accueil en
  /// affiche le dernier score.
  final List<ProgressScore> historique;

  /// Le détail par thème, **même modèle que le Plan / Réviser** : le serveur
  /// réexpose ce que son moteur civique produit déjà.
  ///
  /// 🛑 L'`etat` est **servi**, et se rend par `CivicThemeState.label` : l'app
  /// pose un libellé, elle ne classe aucun nombre.
  final List<CivicPlanThemeLigne> themes;

  static ProgressCivique fromJson(Map<String, dynamic> json) => ProgressCivique(
        historique: (json['historique'] as List<dynamic>? ?? const [])
            .map((e) => ProgressScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        themes: (json['themes'] as List<dynamic>? ?? const [])
            .map((e) => CivicPlanThemeLigne.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// « Où vous en êtes » — le TCF et le civique de l'Accueil.
class Progress {
  const Progress({required this.tcf, required this.civique});

  final ProgressTcf tcf;
  final ProgressCivique civique;

  static Progress fromJson(Map<String, dynamic> json) => Progress(
        tcf: ProgressTcf.fromJson(json['tcf'] as Map<String, dynamic>? ?? const {}),
        civique: ProgressCivique.fromJson(
            json['civique'] as Map<String, dynamic>? ?? const {}),
      );
}
