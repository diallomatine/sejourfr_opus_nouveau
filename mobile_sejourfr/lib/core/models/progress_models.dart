import 'enums.dart';

/// Miroirs de `ProgressDto` (T28, `30_` §7) — « montrer le MOUVEMENT, pas un
/// tableau de bord ».
///
/// 🛑 **Rien n'est calculé côté app** : les paliers, les sens d'évolution, les
/// états de maîtrise et les compteurs arrivent servis.

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

/// Une semaine de la frise d'activité. [jours] vaut 0 à 7.
class ProgressSemaine {
  const ProgressSemaine({required this.debut, required this.jours});

  final DateTime? debut;
  final int jours;

  static ProgressSemaine fromJson(Map<String, dynamic> json) => ProgressSemaine(
        debut: DateTime.tryParse(json['debut'] as String? ?? ''),
        jours: (json['jours'] as num?)?.toInt() ?? 0,
      );
}

/// L'activité récente — des **faits**, jamais un jeu.
///
/// 🛑 Ni flamme, ni record, ni objectif hebdomadaire (`30_` §7). Un compteur
/// qu'on peut casser transforme une mesure en dette.
class ProgressActivite {
  const ProgressActivite({
    required this.joursActifs,
    required this.fenetreJours,
    required this.semaines,
  });

  final int joursActifs;

  /// **Servi** : aucun écran n'écrit la fenêtre en dur, donc aucun ne ment.
  final int fenetreJours;

  /// De la plus ancienne à la plus récente — le sens de lecture d'une frise.
  final List<ProgressSemaine> semaines;

  static ProgressActivite fromJson(Map<String, dynamic> json) => ProgressActivite(
        joursActifs: (json['joursActifs'] as num?)?.toInt() ?? 0,
        fenetreJours: (json['fenetreJours'] as num?)?.toInt() ?? 0,
        semaines: (json['semaines'] as List<dynamic>? ?? const [])
            .map((e) => ProgressSemaine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Un point de l'historique des estimations TCF.
class ProgressEstimation {
  const ProgressEstimation({required this.sessionId, this.niveau, this.mesureA});

  final String sessionId;
  final NiveauCecrl? niveau;
  final DateTime? mesureA;

  static ProgressEstimation fromJson(Map<String, dynamic> json) => ProgressEstimation(
        sessionId: json['sessionId'] as String? ?? '',
        niveau: json['niveau'] == null
            ? null
            : NiveauCecrl.fromWire(json['niveau'] as String),
        mesureA: DateTime.tryParse(json['mesureA'] as String? ?? ''),
      );
}

/// Une épreuve, son palier d'aujourd'hui, et ce qui a bougé.
class ProgressEpreuve {
  const ProgressEpreuve({
    required this.epreuve,
    required this.evolution,
    this.niveau,
    this.niveauInitial,
  });

  final EpreuveType epreuve;

  /// `null` = jamais évaluée. 🛑 Jamais rendu en « A1 ».
  final NiveauCecrl? niveau;
  final NiveauCecrl? niveauInitial;
  final NiveauEvolution evolution;

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
      );
}

/// Une compétence tenue.
///
/// 🛑 [preuveA] est la date de la **dernière observation solide** — pas une
/// « date d'acquisition » : le moteur agrège plusieurs observations, aucune ne
/// marque un instant d'acquisition.
class ProgressCompetence {
  const ProgressCompetence({
    required this.skillId,
    required this.code,
    required this.titre,
    this.preuveA,
  });

  final String skillId;
  final String code;
  final String titre;
  final DateTime? preuveA;

  static ProgressCompetence fromJson(Map<String, dynamic> json) => ProgressCompetence(
        skillId: json['skillId'] as String? ?? '',
        code: json['code'] as String? ?? '',
        titre: json['titre'] as String? ?? '',
        preuveA: DateTime.tryParse(json['preuveA'] as String? ?? ''),
      );
}

/// Bloc 3 — « 4 compétences maîtrisées sur 11 travaillées ».
///
/// 🛑 **Les compteurs sont servis même verrouillés** : c'est le *détail* qui est
/// premium, pas le fait d'avoir progressé.
class ProgressCompetences {
  const ProgressCompetences({
    required this.travaillees,
    required this.maitrisees,
    required this.dernieres,
    required this.locked,
  });

  final int travaillees;
  final int maitrisees;

  /// Vide quand [locked].
  final List<ProgressCompetence> dernieres;
  final bool locked;

  static ProgressCompetences fromJson(Map<String, dynamic> json) => ProgressCompetences(
        travaillees: (json['travaillees'] as num?)?.toInt() ?? 0,
        maitrisees: (json['maitrisees'] as num?)?.toInt() ?? 0,
        dernieres: (json['dernieres'] as List<dynamic>? ?? const [])
            .map((e) => ProgressCompetence.fromJson(e as Map<String, dynamic>))
            .toList(),
        locked: json['locked'] as bool? ?? false,
      );
}

class ProgressTcf {
  const ProgressTcf({
    required this.disponible,
    required this.historique,
    required this.epreuves,
    required this.competences,
    this.niveauActuel,
    this.objectif,
  });

  /// `false` tant qu'aucun diagnostic n'est clos : rien à tracer.
  final bool disponible;
  final NiveauCecrl? niveauActuel;
  final NiveauCecrl? objectif;

  /// Du plus ancien au plus récent. 🛑 Une courbe demande **deux** points.
  final List<ProgressEstimation> historique;

  /// Les 4 épreuves, **toutes**, évaluées ou non.
  final List<ProgressEpreuve> epreuves;
  final ProgressCompetences competences;

  static ProgressTcf fromJson(Map<String, dynamic> json) => ProgressTcf(
        disponible: json['disponible'] as bool? ?? false,
        niveauActuel: json['niveauActuel'] == null
            ? null
            : NiveauCecrl.fromWire(json['niveauActuel'] as String),
        objectif: json['objectif'] == null
            ? null
            : NiveauCecrl.fromWire(json['objectif'] as String),
        historique: (json['historique'] as List<dynamic>? ?? const [])
            .map((e) => ProgressEstimation.fromJson(e as Map<String, dynamic>))
            .toList(),
        epreuves: (json['epreuves'] as List<dynamic>? ?? const [])
            .map((e) => ProgressEpreuve.fromJson(e as Map<String, dynamic>))
            .toList(),
        competences: ProgressCompetences.fromJson(
            json['competences'] as Map<String, dynamic>? ?? const {}),
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
    required this.disponible,
    required this.historique,
    required this.travaillees,
    required this.maitrisees,
    required this.grainNotion,
  });

  final bool disponible;
  final List<ProgressScore> historique;
  final int travaillees;
  final int maitrisees;

  /// L'écran doit pouvoir **nommer** ce qu'il compte : notions ou thèmes.
  final bool grainNotion;

  static ProgressCivique fromJson(Map<String, dynamic> json) => ProgressCivique(
        disponible: json['disponible'] as bool? ?? false,
        historique: (json['historique'] as List<dynamic>? ?? const [])
            .map((e) => ProgressScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        travaillees: (json['travaillees'] as num?)?.toInt() ?? 0,
        maitrisees: (json['maitrisees'] as num?)?.toInt() ?? 0,
        grainNotion: json['grainNotion'] as bool? ?? false,
      );
}

/// **Progrès** — « montrer le mouvement, pas un tableau de bord ».
///
/// 🛑 [activite] est **transverse** : les jours de travail ne se répartissent
/// pas par module — une séance civique et une production TCF sont le même effort
/// du même jour.
class Progress {
  const Progress({
    required this.activite,
    required this.tcf,
    required this.civique,
  });

  final ProgressActivite activite;
  final ProgressTcf tcf;
  final ProgressCivique civique;

  static Progress fromJson(Map<String, dynamic> json) => Progress(
        activite: ProgressActivite.fromJson(
            json['activite'] as Map<String, dynamic>? ?? const {}),
        tcf: ProgressTcf.fromJson(json['tcf'] as Map<String, dynamic>? ?? const {}),
        civique: ProgressCivique.fromJson(
            json['civique'] as Map<String, dynamic>? ?? const {}),
      );
}
