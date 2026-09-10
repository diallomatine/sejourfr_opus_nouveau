import 'enums.dart';

/// Miroirs des `TcfDiagnostic*Dto` du backend (lot L4).
///
/// 🛑 **À ne pas confondre avec le diagnostic INITIAL** (une production écrite
/// + une orale, `diagnostic_models.dart`) : ce sont deux objets produit
/// distincts, et `10_` §4.1 interdit de les confondre — comme il interdit
/// d'appeler celui-ci un examen blanc.

/// État d'ensemble. Deux valeurs seulement : un diagnostic dont le délai de
/// reprise est écoulé reste `inProgress`, parce que le délai borne la reprise
/// et non la validité.
enum TcfDiagnosticStatus {
  inProgress('IN_PROGRESS'),
  completed('COMPLETED');

  const TcfDiagnosticStatus(this.wire);
  final String wire;

  static TcfDiagnosticStatus fromWire(String value) =>
      TcfDiagnosticStatus.values.firstWhere((e) => e.wire == value);
}

/// État d'une section, **dérivé serveur**. Le front ne le recalcule jamais.
enum TcfDiagnosticSectionState {
  aFaire('A_FAIRE'),
  enCours('EN_COURS'),
  terminee('TERMINEE');

  const TcfDiagnosticSectionState(this.wire);
  final String wire;

  static TcfDiagnosticSectionState fromWire(String value) =>
      TcfDiagnosticSectionState.values.firstWhere((e) => e.wire == value);
}

class TcfDiagnosticSectionDto {
  const TcfDiagnosticSectionDto({
    required this.epreuve,
    required this.attemptId,
    required this.etat,
    this.timeLimitSeconds,
    this.totalQuestions,
  });

  final EpreuveType epreuve;

  /// `null` = section absente du diagnostic (mode dégradé : pas de contenu).
  /// Elle se présente « non évaluée », jamais comme un manque de contenu.
  final String? attemptId;

  final TcfDiagnosticSectionState etat;

  /// Chrono de la section. `null` en EO, qui se chronomètre par tâche.
  final int? timeLimitSeconds;

  final int? totalQuestions;

  factory TcfDiagnosticSectionDto.fromJson(Map<String, dynamic> json) =>
      TcfDiagnosticSectionDto(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        attemptId: json['attemptId'] as String?,
        etat: TcfDiagnosticSectionState.fromWire(json['etat'] as String),
        timeLimitSeconds: json['timeLimitSeconds'] as int?,
        totalQuestions: json['totalQuestions'] as int?,
      );
}

/// L'écran d'accueil du diagnostic.
///
/// 🛑 **Aucun niveau ici, et ce n'est pas un oubli** : `10_` §4.2 interdit tout
/// résultat partiel entre les sections — « le résultat est le moment de
/// conversion, il ne doit pas être dilué ».
class TcfDiagnosticDto {
  const TcfDiagnosticDto({
    required this.sessionId,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.repriseEcoulee,
    required this.sections,
    this.completedAt,
  });

  final String sessionId;
  final TcfDiagnosticStatus status;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  /// Le délai de reprise est passé. **Rien n'est perdu** : les sections faites
  /// comptent toujours, les autres restent « non évaluée ».
  final bool repriseEcoulee;

  final List<TcfDiagnosticSectionDto> sections;

  factory TcfDiagnosticDto.fromJson(Map<String, dynamic> json) => TcfDiagnosticDto(
        sessionId: json['sessionId'] as String,
        status: TcfDiagnosticStatus.fromWire(json['status'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        repriseEcoulee: json['repriseEcoulee'] as bool? ?? false,
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((e) => TcfDiagnosticSectionDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Une priorité. Le score de tri n'est **pas** exposé, volontairement : le
/// montrer inviterait à le comparer d'un diagnostic à l'autre alors qu'il
/// dépend de la cible du candidat.
class TcfDiagnosticPriorityDto {
  const TcfDiagnosticPriorityDto({
    required this.rang,
    required this.epreuve,
    this.taskCode,
    this.niveauTache,
    this.niveauEpreuve,
  });

  final int rang;
  final EpreuveType epreuve;

  /// « EE1 »… « EO3 ». `null` en compréhension : la priorité porte sur l'épreuve.
  final String? taskCode;

  final NiveauCecrl? niveauTache;
  final NiveauCecrl? niveauEpreuve;

  factory TcfDiagnosticPriorityDto.fromJson(Map<String, dynamic> json) =>
      TcfDiagnosticPriorityDto(
        rang: json['rang'] as int,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        taskCode: json['taskCode'] as String?,
        niveauTache: json['niveauTache'] != null
            ? NiveauCecrl.fromWire(json['niveauTache'] as String)
            : null,
        niveauEpreuve: json['niveauEpreuve'] != null
            ? NiveauCecrl.fromWire(json['niveauEpreuve'] as String)
            : null,
      );
}

/// Le niveau d'une épreuve.
///
/// 🛑 `niveau == null` signifie **non évaluée**, jamais A1 : afficher un palier
/// plancher serait rendre un verdict que personne n'a rendu.
class TcfDiagnosticEpreuveNiveau {
  const TcfDiagnosticEpreuveNiveau({required this.epreuve, this.niveau});

  final EpreuveType epreuve;
  final NiveauCecrl? niveau;

  factory TcfDiagnosticEpreuveNiveau.fromJson(Map<String, dynamic> json) =>
      TcfDiagnosticEpreuveNiveau(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        niveau: json['niveau'] != null
            ? NiveauCecrl.fromWire(json['niveau'] as String)
            : null,
      );
}

/// L'écran de résultat (`10_` §4.5).
///
/// 🛑 **Aucun `locked`** : le paywall porte sur le plan, jamais sur le constat.
class TcfDiagnosticResultDto {
  const TcfDiagnosticResultDto({
    required this.sessionId,
    required this.epreuves,
    required this.priorites,
    required this.dejaAuNiveau,
    this.niveauGlobal,
    this.cible,
    this.completedAt,
    this.progression,
    this.tachesSousLaCible = 0,
  });

  final String sessionId;

  /// `null` = aucune épreuve évaluée. Jamais un palier inventé.
  final NiveauCecrl? niveauGlobal;

  final NiveauCecrl? cible;
  final List<TcfDiagnosticEpreuveNiveau> epreuves;
  final List<TcfDiagnosticPriorityDto> priorites;

  /// Épreuves déjà à la cible — le bloc « Déjà au niveau attendu ».
  final List<TcfDiagnosticEpreuveNiveau> dejaAuNiveau;

  final DateTime? completedAt;

  /// Ce qui a bougé depuis le diagnostic précédent (L7).
  ///
  /// 🛑 **`null` est le cas NORMAL** : c'est le premier diagnostic, il n'y a
  /// rien à comparer. L'écran n'affiche alors aucun bloc — il n'en fabrique
  /// pas un vide.
  final TcfDiagnosticProgressionDto? progression;

  /// Combien de tâches d'expression **mesurées** restent sous la cible.
  ///
  /// 🛑 **Non plafonné**, contrairement à [priorites] qui l'est à trois par
  /// règle produit. C'est lui, et lui seul, qui fait le « N compétences
  /// ciblées détectées » de l'écran : le lire sur une liste tronquée
  /// afficherait « 3 » quel que soit le nombre réel.
  ///
  /// 🛑 `0` est un état **normal** — tout est à la cible. Aucune ligne alors.
  final int tachesSousLaCible;

  factory TcfDiagnosticResultDto.fromJson(Map<String, dynamic> json) =>
      TcfDiagnosticResultDto(
        sessionId: json['sessionId'] as String,
        niveauGlobal: json['niveauGlobal'] != null
            ? NiveauCecrl.fromWire(json['niveauGlobal'] as String)
            : null,
        cible: json['cible'] != null
            ? NiveauCecrl.fromWire(json['cible'] as String)
            : null,
        epreuves: (json['epreuves'] as List<dynamic>? ?? const [])
            .map((e) => TcfDiagnosticEpreuveNiveau.fromJson(e as Map<String, dynamic>))
            .toList(),
        priorites: (json['priorites'] as List<dynamic>? ?? const [])
            .map((e) => TcfDiagnosticPriorityDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        dejaAuNiveau: (json['dejaAuNiveau'] as List<dynamic>? ?? const [])
            .map((e) => TcfDiagnosticEpreuveNiveau.fromJson(e as Map<String, dynamic>))
            .toList(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        progression: json['progression'] != null
            ? TcfDiagnosticProgressionDto.fromJson(
                json['progression'] as Map<String, dynamic>)
            : null,
        tachesSousLaCible: (json['tachesSousLaCible'] as num? ?? 0).toInt(),
      );
}

// ----------------------------------------------------------------------------
// L7 — LA BOUCLE DE RÉÉVALUATION
// Miroirs de `TcfDiagnosticProgressionDto` et `TcfReassessmentEligibilityDto`.
// ----------------------------------------------------------------------------

/// Le sens d'une variation de palier entre deux diagnostics.
///
/// 🛑 **`inconnue` n'est pas `stable`.** Une épreuve non évaluée d'un côté ou
/// de l'autre n'a ni progressé ni régressé : elle n'est pas comparable.
/// Afficher « = » dessus laisserait croire qu'un niveau a été tenu alors que
/// personne n'a rien mesuré.
enum NiveauEvolution {
  hausse('HAUSSE'),
  stable('STABLE'),
  baisse('BAISSE'),
  inconnue('INCONNUE');

  const NiveauEvolution(this.wire);
  final String wire;

  static NiveauEvolution fromWire(String value) =>
      NiveauEvolution.values.firstWhere((e) => e.wire == value);
}

/// L'évolution d'une épreuve. `avant` et `apres` sont nuls indépendamment.
class TcfEpreuveEvolution {
  const TcfEpreuveEvolution({
    required this.epreuve,
    required this.evolution,
    this.avant,
    this.apres,
  });

  final EpreuveType epreuve;
  final NiveauCecrl? avant;
  final NiveauCecrl? apres;
  final NiveauEvolution evolution;

  factory TcfEpreuveEvolution.fromJson(Map<String, dynamic> json) =>
      TcfEpreuveEvolution(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        avant: json['avant'] != null
            ? NiveauCecrl.fromWire(json['avant'] as String)
            : null,
        apres: json['apres'] != null
            ? NiveauCecrl.fromWire(json['apres'] as String)
            : null,
        evolution: NiveauEvolution.fromWire(json['evolution'] as String),
      );
}

/// La comparaison au diagnostic précédent (`10_` §4.6, `30_` §7 bloc 2).
///
/// 🛑 **Le serveur dit d'où à où ; « Vous avez progressé ! » appartient à
/// l'écran.** Rien ici ne se recalcule côté mobile.
class TcfDiagnosticProgressionDto {
  const TcfDiagnosticProgressionDto({
    required this.previousSessionId,
    required this.niveauGlobal,
    required this.epreuves,
    this.previousCompletedAt,
    this.previousNiveauGlobal,
  });

  final String previousSessionId;
  final DateTime? previousCompletedAt;
  final NiveauCecrl? previousNiveauGlobal;
  final NiveauEvolution niveauGlobal;
  final List<TcfEpreuveEvolution> epreuves;

  factory TcfDiagnosticProgressionDto.fromJson(Map<String, dynamic> json) =>
      TcfDiagnosticProgressionDto(
        previousSessionId: json['previousSessionId'] as String,
        previousCompletedAt: json['previousCompletedAt'] != null
            ? DateTime.tryParse(json['previousCompletedAt'] as String)
            : null,
        previousNiveauGlobal: json['previousNiveauGlobal'] != null
            ? NiveauCecrl.fromWire(json['previousNiveauGlobal'] as String)
            : null,
        niveauGlobal: NiveauEvolution.fromWire(json['niveauGlobal'] as String),
        epreuves: (json['epreuves'] as List<dynamic>? ?? const [])
            .map((e) => TcfEpreuveEvolution.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Ce qui empêche aujourd'hui de relancer un diagnostic. `null` = rien.
enum TcfReassessmentBlocker {
  premiumRequired('PREMIUM_REQUIRED'),
  intervalNotElapsed('INTERVAL_NOT_ELAPSED');

  const TcfReassessmentBlocker(this.wire);
  final String wire;

  static TcfReassessmentBlocker fromWire(String value) =>
      TcfReassessmentBlocker.values.firstWhere((e) => e.wire == value);
}

/// **Peut-il relancer, et sinon pourquoi ?** — l'écran T11 (`30_` §5.6) et la
/// boucle de réévaluation (`10_` §4.6), servis.
///
/// 🛑 **Le front ne recalcule rien d'ici** : ni les 14 jours, ni les jours
/// restants, ni « c'est le premier ». Le serveur sert ce DTO **et** garde
/// l'ouverture avec le même calcul — un bouton actif que l'API refuse est donc
/// impossible par construction.
class TcfReassessmentEligibilityDto {
  const TcfReassessmentEligibilityDto({
    required this.canStart,
    required this.locked,
    required this.first,
    required this.inProgress,
    required this.intervalDays,
    required this.triggeredByPlan,
    this.blocker,
    this.message,
    this.availableAt,
    this.daysUntilAvailable,
    this.lastSessionId,
    this.lastCompletedAt,
    this.lastNiveauGlobal,
  });

  final bool canStart;
  final TcfReassessmentBlocker? blocker;

  /// Porte **commerciale** : l'écran ouvre le paywall. Strictement
  /// `blocker == premiumRequired` — un délai non écoulé n'est pas un cadenas,
  /// payer ne l'ouvre pas.
  final bool locked;

  /// La phrase exacte à afficher. `null` quand rien ne bloque.
  final String? message;

  /// Aucun diagnostic à ce jour : c'est l'**initial**, offert. Pas une
  /// réévaluation.
  final bool first;

  /// Un diagnostic est ouvert : l'action est « Reprendre », pas « Relancer ».
  final bool inProgress;

  /// Le délai de la règle, pour pouvoir le **dire** sans le connaître.
  final int intervalDays;

  final DateTime? availableAt;
  final int? daysUntilAvailable;

  /// Une priorité du Plan a été terminée depuis le dernier diagnostic :
  /// `10_` §4.6 ouvre alors la réévaluation **sans attendre** le délai.
  final bool triggeredByPlan;

  final String? lastSessionId;
  final DateTime? lastCompletedAt;

  /// 🛑 `null` = **non évalué**, jamais A1.
  final NiveauCecrl? lastNiveauGlobal;

  factory TcfReassessmentEligibilityDto.fromJson(Map<String, dynamic> json) =>
      TcfReassessmentEligibilityDto(
        canStart: json['canStart'] as bool? ?? false,
        blocker: json['blocker'] != null
            ? TcfReassessmentBlocker.fromWire(json['blocker'] as String)
            : null,
        locked: json['locked'] as bool? ?? false,
        message: json['message'] as String?,
        first: json['first'] as bool? ?? false,
        inProgress: json['inProgress'] as bool? ?? false,
        intervalDays: json['intervalDays'] as int? ?? 0,
        availableAt: json['availableAt'] != null
            ? DateTime.tryParse(json['availableAt'] as String)
            : null,
        daysUntilAvailable: json['daysUntilAvailable'] as int?,
        triggeredByPlan: json['triggeredByPlan'] as bool? ?? false,
        lastSessionId: json['lastSessionId'] as String?,
        lastCompletedAt: json['lastCompletedAt'] != null
            ? DateTime.tryParse(json['lastCompletedAt'] as String)
            : null,
        lastNiveauGlobal: json['lastNiveauGlobal'] != null
            ? NiveauCecrl.fromWire(json['lastNiveauGlobal'] as String)
            : null,
      );
}
