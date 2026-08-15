import 'enums.dart';

/// Ordre canonique des 4 épreuves d'un examen blanc TCF complet. Déclaré ici et
/// nulle part ailleurs — trois écrans en tenaient chacun une copie.
const List<EpreuveType> kFullTcfExamOrder = [
  EpreuveType.tcfCo,
  EpreuveType.tcfCe,
  EpreuveType.tcfEe,
  EpreuveType.tcfEo,
];

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

/// L'examen blanc TCF complet a-t-il été joué **d'une traite** ou repris entre
/// plusieurs épreuves ? Miroir de `ContinuiteSimulation` (backend), **dérivé
/// serveur** : l'app affiche [label] tel quel et ne recalcule rien.
///
/// **Deux valeurs seulement.** Le troisième cas de restitution — « pas de
/// résultat global définitif » — existe déjà et ne se dédouble pas ici : c'est
/// `finalLevelPartial` / `epreuvesCountedInFinalLevel`, qui disent sur combien
/// d'épreuves porte réellement le niveau plancher.
enum ContinuiteSimulation {
  sessionUnique('SESSION_UNIQUE', 'Simulation complète — conditions examen'),
  plusieursSessions(
      'PLUSIEURS_SESSIONS', 'Simulation complétée en plusieurs sessions');

  const ContinuiteSimulation(this.wire, this.label);

  final String wire;

  /// Libellé FR affiché au candidat. Contrat gelé côté backend
  /// (`ContinuiteSimulationTest`), miroir manuel sur les 3 fronts.
  final String label;

  static ContinuiteSimulation? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final c in ContinuiteSimulation.values) {
      if (c.wire == value) return c;
    }
    return null;
  }
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
    this.calibratedScore,
    required this.submissionsCount,
    required this.failedSubmissionIds,
    this.locked = false,
    this.timeLimitSeconds,
    this.timerStartedAt,
    this.deadlineAt,
  });

  final String attemptId;
  final EpreuveType epreuve;
  final DateTime? finishedAt;
  final NiveauCecrl? cecrlLevel;
  /// CO/CE : score **pondéré interne** (A2=1, B1=2, B2=3) et sa borne. Servis
  /// comme repli — « 23/50 » ne correspond à rien sur le relevé d'un candidat.
  final int? score;
  final int? maxScore;

  /// CO/CE : score calibré **100-499**, l'échelle du relevé TCF. Dérivé serveur
  /// (`TcfLevelEstimatorService`, correction du hasard comprise) — **jamais
  /// recalculé ici** depuis [score]/[maxScore]. Null pour EE/EO (pas de QCM),
  /// pour une épreuve `locked` et tant que le score pondéré n'est pas posé.
  final int? calibratedScore;

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

  /// Durée de **cette** épreuve, en secondes (CO 1200, CE 2100, EE 1800).
  /// **Null pour l'expression orale**, qui n'a volontairement pas de chrono
  /// d'épreuve : son temps se compte par tâche et ne démarre qu'au lancement de
  /// la tâche (`ProductionTaskDto.dureeMaxSec`). Null aussi sur une épreuve
  /// `locked`.
  ///
  /// C'est le **seul** endroit où lire la durée d'une épreuve d'examen complet :
  /// aucun écran ne recopie « 30 min » en dur (la CE avait déjà divergé — 30 min
  /// dans un écran, 35 dans un autre).
  final int? timeLimitSeconds;

  /// Instant où le candidat a **lancé** l'épreuve
  /// (`POST /api/full-tcf-exams/{id}/begin`). Null tant qu'elle ne l'a pas été :
  /// les 4 sous-attempts sont créés d'un bloc au démarrage de l'examen, leur
  /// `startedAt` ne dit donc rien du moment où le candidat les ouvre.
  final DateTime? timerStartedAt;

  /// Échéance effective (`timerStartedAt + timeLimitSeconds`), calculée serveur.
  /// **C'est L'UNIQUE source du compte à rebours** — l'app ne recompose jamais
  /// une échéance. Null quand l'épreuve n'a pas de chrono (EO) ou n'a pas encore
  /// été lancée. Quitter ne suspend rien : le temps court pendant l'absence, et
  /// passé cette échéance le serveur clôture l'épreuve avec ce qui était
  /// enregistré.
  final DateTime? deadlineAt;

  bool get isFinished => finishedAt != null;
  bool get hasFailures => failedSubmissionIds.isNotEmpty;

  /// Score d'une sous-épreuve QCM (CO/CE) **sur l'échelle du relevé TCF**.
  ///
  /// [calibratedScore] (100-499) est ce qu'on affiche : le pondéré interne
  /// (« 23/50 ») ne veut rien dire pour un candidat. Repli sur le pondéré quand
  /// le calibré manque — on n'invente **jamais** un /499 à partir d'un pondéré,
  /// et on ne remplace pas par un tiret une donnée qu'on possède. Null quand il
  /// n'y a rien à afficher (EE/EO, épreuve verrouillée, pas encore notée).
  ///
  /// Miroir web : `qcmScoreLabel` (`lib/exam-levels.ts`).
  String? get qcmScoreLabel {
    if (calibratedScore != null) return '$calibratedScore/499';
    if (score != null && maxScore != null) return '$score/$maxScore';
    return null;
  }

  /// Close **sans jamais avoir été ouverte** : l'examen a été abandonné avant
  /// d'y arriver. Le serveur ne lui donne alors **aucun** niveau (`null` =
  /// inconnu, jamais mauvais) et l'exclut du plancher — cf.
  /// `FullTcfExamResponseBuilder`. Sans ce discriminant, une telle épreuve se
  /// lit « Évaluation en cours… », c'est-à-dire une attente qui n'aboutira
  /// jamais.
  ///
  /// Miroir web : l'état `not_taken` de `subAttemptView` (`lib/exam-levels.ts`).
  bool get jamaisOuverte =>
      finishedAt != null &&
      !locked &&
      timerStartedAt == null &&
      cecrlLevel == null &&
      failedSubmissionIds.isEmpty;

  /// Épreuve lancée, chronométrée et pas encore terminée.
  bool get isRunning => deadlineAt != null && finishedAt == null;

  /// Temps restant sur cette épreuve à l'instant [now]. Null quand elle n'a pas
  /// d'échéance (pas de chrono, ou pas encore lancée) ; `Duration.zero` quand
  /// l'échéance est passée.
  Duration? remainingAt(DateTime now) {
    final ends = deadlineAt;
    if (ends == null) return null;
    final diff = ends.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

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
      calibratedScore: (json['calibratedScore'] as num?)?.toInt(),
      submissionsCount: json['submissionsCount'] as int?,
      failedSubmissionIds: failed.map((e) => e as String).toList(),
      locked: json['locked'] as bool? ?? false,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      timerStartedAt: json['timerStartedAt'] != null
          ? DateTime.parse(json['timerStartedAt'] as String).toLocal()
          : null,
      deadlineAt: json['deadlineAt'] != null
          ? DateTime.parse(json['deadlineAt'] as String).toLocal()
          : null,
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
    this.continuite,
    this.epreuvesCountedInFinalLevel,
    this.epreuvesExpected,
    this.finalLevelPartial = false,
  });

  final String id;
  final DateTime startedAt;

  /// Lancement réel de la 1re épreuve — **trace du début de l'examen**, plus
  /// l'ancre d'un décompte : l'enveloppe globale de 90 min a été supprimée
  /// (chaque épreuve porte sa durée, rien ne se transfère de l'une à l'autre, et
  /// l'abandon-reprise entre épreuves est officiellement supporté). L'app n'en
  /// dérive **aucun** compte à rebours — elle lit
  /// [FullTcfExamSubAttempt.deadlineAt]. NULL tant que le candidat n'a rien
  /// lancé. Distinct de [startedAt] = instant de CRÉATION de l'examen.
  final DateTime? timerStartedAt;

  final DateTime? finishedAt;
  final NiveauCecrl? finalCecrlLevel;
  final FullTcfExamStatus status;
  final List<FullTcfExamSubAttempt> subAttempts;

  /// Examen enchaîné d'une traite, ou repris entre plusieurs épreuves ? Dérivé
  /// serveur. **NULL tant que l'examen n'est pas terminé** — la question ne se
  /// pose qu'au moment de restituer le résultat. À ne pas confondre avec
  /// [finalLevelPartial], qui dit tout autre chose : sur combien d'épreuves
  /// porte le niveau.
  final ContinuiteSimulation? continuite;

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
    for (int i = 0; i < kFullTcfExamOrder.length; i++) {
      final s = subFor(kFullTcfExamOrder[i]);
      if (s == null || !s.isFinished) return i;
    }
    return kFullTcfExamOrder.length;
  }

  /// Sous-attempt de l'épreuve en cours (la première non terminée), ou null
  /// quand tout est joué.
  FullTcfExamSubAttempt? get currentSubAttempt {
    final idx = currentStepIndex;
    return idx >= kFullTcfExamOrder.length
        ? null
        : subFor(kFullTcfExamOrder[idx]);
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
      continuite:
          ContinuiteSimulation.fromWireNullable(json['continuite'] as String?),
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
    this.continuite,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final NiveauCecrl? finalCecrlLevel;
  final FullTcfExamStatus status;

  /// Cf. [FullTcfExamResponse.continuite]. NULL tant que l'examen n'est pas
  /// terminé.
  final ContinuiteSimulation? continuite;
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
      continuite:
          ContinuiteSimulation.fromWireNullable(json['continuite'] as String?),
    );
  }
}
