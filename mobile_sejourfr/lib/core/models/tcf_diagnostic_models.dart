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
      );
}
