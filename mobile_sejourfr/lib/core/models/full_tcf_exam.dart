import 'enums.dart';

/// Statut global d'un examen blanc TCF complet (miroir Dart de
/// `FullTcfExamResponse.FullTcfExamStatus`).
enum FullTcfExamStatus {
  inProgress('IN_PROGRESS'),
  pendingEvaluations('PENDING_EVALUATIONS'),
  completed('COMPLETED');

  const FullTcfExamStatus(this.wire);
  final String wire;

  static FullTcfExamStatus fromWire(String value) =>
      FullTcfExamStatus.values.firstWhere((e) => e.wire == value);
}

/// Description d'un sous-attempt (CO / CE / EE / EO) d'un examen blanc TCF
/// complet. Tous les champs résultat (`cecrlLevel`, `score`, `maxScore`,
/// `submissionsCount`) sont nullables — le backend les remplit au fur et à
/// mesure de la progression.
class FullTcfExamSubAttempt {
  const FullTcfExamSubAttempt({
    required this.attemptId,
    required this.epreuve,
    required this.finishedAt,
    required this.cecrlLevel,
    required this.score,
    required this.maxScore,
    required this.submissionsCount,
    required this.failedSubmissionIds,
    this.locked = false,
  });

  final String attemptId;
  final EpreuveType epreuve;
  final DateTime? finishedAt;
  final NiveauCecrl? cecrlLevel;
  final int? score;
  final int? maxScore;
  /// EE/EO : nombre de submissions ayant atteint EVALUATED (sur 3 attendues).
  final int? submissionsCount;

  /// EE/EO : ids des submissions FAILED — le mobile peut les retenter via
  /// `POST /api/production-submissions/{id}/retry`. Vide pour CO/CE.
  final List<String> failedSubmissionIds;

  /// EE/EO seulement : épreuve verrouillée pour un compte gratuit ayant déjà
  /// utilisé l'expression écrite/orale offerte une fois. Pré-terminée, comptée
  /// A1_NON_ATTEINT — afficher un cadenas + invitation à l'abonnement plutôt
  /// qu'un état « non passé ». Toujours false pour CO/CE et les abonnés.
  final bool locked;

  bool get isFinished => finishedAt != null;
  bool get hasFailures => failedSubmissionIds.isNotEmpty;

  factory FullTcfExamSubAttempt.fromJson(Map<String, dynamic> json) {
    final failed = (json['failedSubmissionIds'] as List<dynamic>?) ?? const [];
    return FullTcfExamSubAttempt(
      attemptId: json['attemptId'] as String,
      epreuve: EpreuveType.fromWire(json['epreuve'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String).toLocal()
          : null,
      cecrlLevel: NiveauCecrl.fromWireNullable(json['cecrlLevel'] as String?),
      score: json['score'] as int?,
      maxScore: json['maxScore'] as int?,
      submissionsCount: json['submissionsCount'] as int?,
      failedSubmissionIds: failed.map((e) => e as String).toList(),
      locked: json['locked'] as bool? ?? false,
    );
  }
}

/// Vue complète d'un examen blanc TCF complet — parent `TCF_COMPLET` + ses 4
/// sous-attempts (ordre canonique CO → CE → EE → EO).
///
/// `finalCecrlLevel` est posé à la finalisation, quand toutes les évaluations
/// IA EE/EO sont remontées (statut `COMPLETED`). Sinon le mobile polle
/// `GET /api/full-tcf-exams/{id}` pour récupérer le niveau quand prêt.
class FullTcfExamResponse {
  const FullTcfExamResponse({
    required this.id,
    required this.startedAt,
    required this.timerStartedAt,
    required this.finishedAt,
    required this.finalCecrlLevel,
    required this.status,
    required this.subAttempts,
    this.epreuvesCountedInFinalLevel,
    this.epreuvesExpected,
    this.finalLevelPartial = false,
  });

  final String id;
  final DateTime startedAt;

  /// Lancement réel de la 1re épreuve (CO) — ancre du chrono global 90 min.
  /// NULL tant que le candidat n'a pas démarré (hub de progression figé à
  /// 90:00). Distinct de [startedAt] = instant de CRÉATION de l'examen.
  final DateTime? timerStartedAt;

  final DateTime? finishedAt;
  final NiveauCecrl? finalCecrlLevel;
  final FullTcfExamStatus status;
  final List<FullTcfExamSubAttempt> subAttempts;

  /// Nombre d'épreuves qui portent un niveau et entrent réellement dans le
  /// plancher [finalCecrlLevel]. Le backend écarte les épreuves **verrouillées**
  /// par le freemium (un verrou commercial n'est pas un verdict de langue) et
  /// celles dont le niveau est resté inconnu (évaluations IA en échec) : dire
  /// « le plus bas de tes 4 épreuves » devient faux dès qu'il en manque une.
  ///
  /// `null` uniquement face à un backend antérieur au champ — l'UI n'affirme
  /// alors aucun décompte plutôt qu'un chiffre inventé.
  final int? epreuvesCountedInFinalLevel;

  /// Épreuves attendues dans un examen complet (toujours 4 : CO/CE/EE/EO),
  /// publié pour que le front ne code pas la constante en dur.
  final int? epreuvesExpected;

  /// `true` quand le plancher ne porte pas sur toutes les épreuves attendues :
  /// le bilan ne doit alors pas se présenter comme un résultat d'examen
  /// complet.
  final bool finalLevelPartial;

  /// Sous-attempt pour une épreuve donnée, ou null s'il n'existe pas (ne devrait
  /// pas arriver côté backend qui en crée 4 atomiquement).
  FullTcfExamSubAttempt? subFor(EpreuveType epreuve) {
    for (final s in subAttempts) {
      if (s.epreuve == epreuve) return s;
    }
    return null;
  }

  /// Indice 0..3 de la prochaine épreuve à passer (première non finie dans
  /// l'ordre CO → CE → EE → EO). Renvoie 4 si tout est terminé.
  int get currentStepIndex {
    const order = [
      EpreuveType.tcfCo,
      EpreuveType.tcfCe,
      EpreuveType.tcfEe,
      EpreuveType.tcfEo,
    ];
    for (int i = 0; i < order.length; i++) {
      final s = subFor(order[i]);
      if (s == null || !s.isFinished) return i;
    }
    return order.length;
  }

  factory FullTcfExamResponse.fromJson(Map<String, dynamic> json) {
    return FullTcfExamResponse(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
      timerStartedAt: json['timerStartedAt'] != null
          ? DateTime.parse(json['timerStartedAt'] as String).toLocal()
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String).toLocal()
          : null,
      finalCecrlLevel:
          NiveauCecrl.fromWireNullable(json['finalCecrlLevel'] as String?),
      status: FullTcfExamStatus.fromWire(json['status'] as String),
      subAttempts: (json['subAttempts'] as List<dynamic>)
          .map((e) =>
              FullTcfExamSubAttempt.fromJson(e as Map<String, dynamic>))
          .toList(),
      epreuvesCountedInFinalLevel:
          (json['epreuvesCountedInFinalLevel'] as num?)?.toInt(),
      epreuvesExpected: (json['epreuvesExpected'] as num?)?.toInt(),
      finalLevelPartial: json['finalLevelPartial'] as bool? ?? false,
    );
  }
}

/// Résumé compact pour l'historique (`GET /api/me/full-tcf-exams`).
class FullTcfExamSummary {
  const FullTcfExamSummary({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.finalCecrlLevel,
    required this.status,
    this.slotNumber,
    this.finalLevelPartial = false,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final NiveauCecrl? finalCecrlLevel;
  final FullTcfExamStatus status;
  /// Slot dans la grille « 20 examens TCF complets » (cf. V110). Permet à
  /// l'UI de retrouver le dernier essai par slot.
  final int? slotNumber;

  /// [finalCecrlLevel] ne porte pas sur les 4 épreuves : au moins une était
  /// verrouillée (freemium) ou sans niveau exploitable. Un tel examen ne peut
  /// pas alimenter un « meilleur niveau atteint » — ce n'est pas un examen
  /// complet.
  final bool finalLevelPartial;

  factory FullTcfExamSummary.fromJson(Map<String, dynamic> json) {
    return FullTcfExamSummary(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String).toLocal()
          : null,
      finalCecrlLevel:
          NiveauCecrl.fromWireNullable(json['finalCecrlLevel'] as String?),
      status: FullTcfExamStatus.fromWire(json['status'] as String),
      slotNumber: (json['slotNumber'] as num?)?.toInt(),
      finalLevelPartial: json['finalLevelPartial'] as bool? ?? false,
    );
  }
}
