/// **Le parcours TCF** — la file d'étapes que le Plan suit.
/// Miroir manuel de `JourneyDto` / `JourneyStepDto` (`GET /api/me/plan/journey`).
///
/// 🛑 **Le serveur sert des FAITS, la phrase appartient à ce front.**
/// « Expression écrite · Tâche 1 », « Vérifier mes progrès », « Évaluer mon
/// niveau », « Déjà maîtrisée » se composent dans `screens/plan/plan_labels.dart`,
/// miroir de `web_sejoufr/lib/plan-domain.ts`. Les faire servir ouvrirait une
/// 7ᵉ copie de libellés dans le dépôt.
///
/// 🛑 **Rien ici ne se recalcule.** `status`, `locked` et l'étape courante sont
/// dérivés **par le serveur** à chaque lecture — un abonnement souscrit change
/// l'écran sans qu'une ligne bouge en base. Un front qui les redéduirait
/// finirait par désigner une autre étape que le serveur.
library;

import 'diagnostic_models.dart';
import 'enums.dart';
import 'skill_models.dart';

/// Nature d'une étape du parcours.
enum JourneyStepType {
  /// Le diagnostic rapide. Proposé **uniquement** quand aucune évaluation
  /// exploitable n'existe, historique compris.
  diagnostic('DIAGNOSTIC'),

  /// Travailler une compétence. ⚠️ **Deux grains sous un seul nom** : en
  /// expression, les petits sujets de l'étape ; en compréhension, des séries
  /// ciblées de 20 QCM. L'unité est **servie** ([JourneyProgress.unit]), jamais
  /// déduite de la nullité de `taskCode`.
  trainSkill('TRAIN_SKILL'),

  /// Passer une épreuve. L'intention se lit sur [JourneyStep.purpose].
  sectionExam('SECTION_EXAM');

  const JourneyStepType(this.wire);

  final String wire;

  static JourneyStepType? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final type in JourneyStepType.values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// Pourquoi cette épreuve est proposée — la même action, deux raisons.
enum JourneyStepPurpose {
  /// L'épreuve n'a **jamais** été mesurée.
  initialAssessment('INITIAL_ASSESSMENT'),

  /// Le **checkpoint** d'un lot : l'examen qui clôt ses priorités.
  reassess('REASSESS');

  const JourneyStepPurpose(this.wire);

  final String wire;

  static JourneyStepPurpose? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final purpose in JourneyStepPurpose.values) {
      if (purpose.wire == value) return purpose;
    }
    return null;
  }
}

/// Où en est une étape, **tel que l'écran l'affiche**.
enum JourneyStepStatus {
  upcoming('UPCOMING'),

  /// À faire maintenant — **une seule par parcours**. C'est la première étape
  /// ouverte **et exécutable** : une étape que le candidat ne peut pas mener à
  /// son terme ne prend jamais la main.
  current('CURRENT'),

  /// Close dans son tour.
  completed('COMPLETED'),

  /// Close **hors de son tour** (entraînement libre, ou en passant devant une
  /// étape verrouillée). S'affiche cochée.
  skipped('SKIPPED'),

  /// Remplacée par une évaluation plus récente. **Jamais servie.**
  obsolete('OBSOLETE');

  const JourneyStepStatus(this.wire);

  final String wire;

  static JourneyStepStatus? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final status in JourneyStepStatus.values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// En quoi se compte l'avancement d'une étape d'entraînement. **Servie.**
enum JourneyProgressUnit {
  /// Les petits sujets de l'étape — expression.
  prompt('PROMPT'),

  /// Les séries ciblées terminées — compréhension. Les compétences CO/CE n'ont
  /// ni tâche ni petit sujet.
  series('SERIES');

  const JourneyProgressUnit(this.wire);

  final String wire;

  static JourneyProgressUnit? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final unit in JourneyProgressUnit.values) {
      if (unit.wire == value) return unit;
    }
    return null;
  }
}

/// L'état d'ensemble du parcours. Le front le **lit** pour choisir quelle carte
/// montrer ; il ne le déduit ni du nombre d'étapes, ni de la nullité de
/// [Journey.current].
enum JourneyState {
  /// Aucune démarche déclarée, donc aucun niveau cible — et **aucun parcours en
  /// base**. L'écran propose « Choisir mon objectif ». Ce n'est pas un parcours
  /// vide : c'est l'absence de parcours.
  needsObjective('NEEDS_OBJECTIVE'),

  inProgress('IN_PROGRESS'),

  /// Des étapes restent ouvertes mais **aucune n'est exécutable** :
  /// [Journey.current] vaut `null` et la carte montre la première étape
  /// verrouillée, avec son paywall.
  locked('LOCKED'),

  /// **Le cycle est terminé** : ses quatre blocs le sont, et il reste quelque
  /// chose à proposer (spec §6). L'écran affiche « Prochaine étape » et la carte
  /// finale à deux actions, lues dans [Journey.nextStep] — jamais déduites du
  /// nombre d'étapes.
  ///
  /// 🛑 **Distinct de [upToDate]**, qui garde son sens : « plus rien à faire du
  /// tout ». Un cycle terminé n'est pas un parcours fini — c'est un palier
  /// franchi, et le suivant attend d'être ouvert.
  ///
  /// ⚠️ **Ajouté au `fromWireNullable` en même temps que le champ** : sans lui,
  /// un cycle terminé retombait sur [needsObjective] et l'écran proposait de
  /// choisir un objectif à un candidat qui venait de finir son plan.
  cycleCompleted('CYCLE_COMPLETED'),

  /// Plus aucune étape ouverte, **et plus rien à proposer**.
  upToDate('UP_TO_DATE');

  const JourneyState(this.wire);

  final String wire;

  static JourneyState? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final state in JourneyState.values) {
      if (state.wire == value) return state;
    }
    return null;
  }
}

/// Où en est un **bloc** du cycle — c'est-à-dire une **épreuve**.
///
/// 🛑 **Dérivé serveur à la lecture, jamais persisté** (D-12, D-14). Le serveur
/// sert la nature, la phrase appartient à ce front (`journey_labels.dart`).
enum JourneyBlocStatus {
  /// Toutes les étapes du bloc sont clôturées.
  termine('TERMINE'),

  /// Le bloc porte l'étape **courante**. Un seul bloc à la fois.
  enCours('EN_COURS'),

  /// Aucune compétence, et l'épreuve n'a **jamais** été mesurée : son examen est
  /// ouvert immédiatement (D-15). 🛑 Ce n'est pas « bloc vide », c'est « on ne
  /// sait pas encore ».
  aEvaluer('A_EVALUER'),

  /// Des étapes restent, mais la main est ailleurs.
  aVenir('A_VENIR');

  const JourneyBlocStatus(this.wire);

  final String wire;

  static JourneyBlocStatus? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final status in JourneyBlocStatus.values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// Ce que le parcours **suggère** quand il n'a plus d'étape. Une suggestion
/// n'est **pas** une étape : hors file, sans position, elle ne se clôt pas.
enum JourneySuggestionType {
  mockExam('MOCK_EXAM');

  const JourneySuggestionType(this.wire);

  final String wire;

  static JourneySuggestionType? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final type in JourneySuggestionType.values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// L'avancement d'une étape d'entraînement.
class JourneyProgress {
  const JourneyProgress({
    required this.done,
    required this.quota,
    required this.unit,
  });

  final int done;

  /// Vaut ce qui existe : une compétence qui publie moins de sujets a une étape
  /// plus courte, et on n'invente jamais un dénominateur.
  final int quota;

  final JourneyProgressUnit unit;

  factory JourneyProgress.fromJson(Map<String, dynamic> json) => JourneyProgress(
        done: (json['done'] as num?)?.toInt() ?? 0,
        quota: (json['quota'] as num?)?.toInt() ?? 0,
        unit: JourneyProgressUnit.fromWireNullable(json['unit'] as String?) ??
            JourneyProgressUnit.prompt,
      );
}


/// La nature de l'axe d'un bloc de cycle. Miroir de `JourneyBlocKind`.
enum JourneyBlocKind {
  epreuve('EPREUVE'),
  thematique('THEMATIQUE');

  const JourneyBlocKind(this.wire);
  final String wire;

  static JourneyBlocKind fromWire(String? value) => JourneyBlocKind.values
      .firstWhere((e) => e.wire == value, orElse: () => JourneyBlocKind.epreuve);
}

/// Le **bloc** d'une étape ou d'un lot, **servi**.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/types.ts` (`JourneyBlocRefDto`).**
///
/// 🛑 **Un seul contrat pour les deux modules** (2026-09-19, D-47). Le contrat
/// précédent portait `examType: EpreuveType`, qu'un bloc civique ne peut pas
/// remplir. L'alternative — `examType` + `themeCode`, et **chaque front branche
/// sur le module** — a été écartée : un front qui branche finit par afficher
/// autre chose que son jumeau.
///
/// 🛑 **Le [label] est SERVI.** Les libellés d'épreuve vivaient dans
/// `core/utils/tcf_epreuves.dart` et dans `EpreuveType.displayLabel`, qui
/// restent pour leurs autres emplois. L'écran du cycle lit ce [label]-ci, et
/// c'est ce qui garantit qu'une thématique civique et une épreuve TCF
/// s'affichent **par le même chemin**.
class JourneyBlocRef {
  const JourneyBlocRef({
    required this.kind,
    required this.code,
    required this.label,
  });

  final JourneyBlocKind kind;

  /// L'identifiant stable — `TCF_CO`, `CIV_PRINCIPES`. Une **clé**, jamais un
  /// affichage.
  final String code;

  /// Ce que le **candidat lit** — « Compréhension orale », « Principes et
  /// valeurs de la République ».
  final String label;

  bool get estEpreuve => kind == JourneyBlocKind.epreuve;

  factory JourneyBlocRef.fromJson(Map<String, dynamic> json) => JourneyBlocRef(
        kind: JourneyBlocKind.fromWire(json['kind'] as String?),
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  static JourneyBlocRef? fromJsonNullable(Object? json) =>
      json is Map<String, dynamic> ? JourneyBlocRef.fromJson(json) : null;
}

/// Une étape de la file.
class JourneyStep {
  const JourneyStep({
    required this.id,
    required this.type,
    required this.status,
    required this.position,
    required this.locked,
    this.purpose,
    this.bloc,
    this.unite,
    this.section,
    this.taskCode,
    this.skillCode,
    this.skillTitle,
    this.lotId,
    this.sourceAssessmentId,
    this.progress,
    this.assessment,
    this.exercise,
  });

  final String id;
  final JourneyStepType type;

  /// Non `null` pour les seules étapes [JourneyStepType.sectionExam].
  final JourneyStepPurpose? purpose;

  final JourneyStepStatus status;

  /// Le bloc **servi**. `null` pour une étape [JourneyStepType.diagnostic]
  /// seulement — elle n'appartient à aucun bloc (R11, A45).
  final JourneyBlocRef? bloc;

  /// **L'unité travaillable, servie** — compétence TCF ou unité officielle
  /// civique, et l'écran ne branche pas (D-50). `null` hors `TRAIN_SKILL`.
  final JourneyUniteRef? unite;

  /// Le domaine de la compétence. `null` hors [JourneyStepType.trainSkill].
  final SkillSection? section;

  /// 🛑 **`null` = compétence de COMPRÉHENSION** : CO/CE n'ont ni tâche ni petit
  /// sujet. Discriminant du sous-titre — **pas** de l'unité de progression, qui
  /// est servie.
  final SkillTaskCode? taskCode;

  final String? skillCode;

  /// `skills.title` : un **fait éditorial** du référentiel, pas une phrase.
  final String? skillTitle;

  final String? lotId;
  final String? sourceAssessmentId;
  final int position;

  /// `null` hors [JourneyStepType.trainSkill] : un examen ne se compte pas.
  final JourneyProgress? progress;

  /// **Cette étape ne peut pas être menée à son terme avec l'accès du
  /// candidat.**
  ///
  /// 🛑 Une étape verrouillée reste **affichée à sa place** : le Plan reste
  /// intégralement visible, on floute l'ACTION jamais le RÉSULTAT (D-18).
  ///
  /// ⚠️ **Elle PEUT être courante** depuis D-60. La phrase précédente disait
  /// « jamais », et c'était vrai tant que rien ne servait l'étape à nommer
  /// quand plus aucune n'est exécutable : chaque front inventait alors son
  /// repli sur le plan dérivé, et les deux tombaient sur un autre bloc que le
  /// badge « EN COURS ». Le serveur sert désormais cette étape-là, verrouillée.
  /// 🛑 **Courante ne veut donc plus dire « exécutable »** — c'est
  /// `Journey.state` qui le dit (`locked`), et le geste se décide sur
  /// `free || locked`, jamais sur le statut.
  final bool locked;

  /// **Par quoi mesurer cette épreuve** — l'action que la carte lance, non
  /// `null` pour les seules étapes [JourneyStepType.sectionExam].
  ///
  /// 🛑 **Relayée du même resolver que partout ailleurs**
  /// (`PlanDomainAssessmentResolver.pour`) : le parcours ne compose aucune
  /// action, il en devient le sixième lecteur.
  ///
  /// ⚠️ **À lire ici, jamais à retrouver dans `domainesAEvaluer`** : celui-ci
  /// ne liste que les épreuves **jamais mesurées**, or le point d'étape d'un
  /// lot porte toujours sur une épreuve **déjà** mesurée — c'est elle qui a
  /// créé le lot. Les fronts ne résolvaient donc aucune action pour le cas le
  /// plus courant du parcours.
  final PlanDomainAssessment? assessment;

  /// **Le micro-exercice que cette étape LANCE** — non `null` pour les seules
  /// étapes [JourneyStepType.trainSkill] dont la compétence a du contenu publié.
  ///
  /// 🛑 **Même raisonnement que [assessment] (A24), même cause** : les priorités
  /// du Plan (`currentPriority` + `nextPriorities`) sont une **vue bornée** à 5
  /// lignes, la file ne l'est pas. Un cycle de six compétences ou plus avait donc
  /// des étapes dont l'action ne se résolvait nulle part, et le garde-fou « une
  /// ligne ne lance jamais autre chose que l'étape qu'elle annonce » les rendait
  /// **sans bouton**.
  ///
  /// 🛑 **Relayé de `RecommendedExerciseSelector`**, son unique autorité — le
  /// parcours n'en compose aucun. Et [locked] **ne s'en déduit pas** : le verrou
  /// d'une étape reste celui que le serveur sert sur l'étape.
  ///
  /// `null` sur une étape d'examen (elle porte [assessment]), sur une compétence
  /// sans sujet publié, et sur un backend antérieur au champ — d'où le repli sur
  /// les priorités dans `planStepAction`.
  final PlanRecommendedExercise? exercise;

  factory JourneyStep.fromJson(Map<String, dynamic> json) => JourneyStep(
        id: json['id'] as String,
        type: JourneyStepType.fromWireNullable(json['type'] as String?) ??
            JourneyStepType.trainSkill,
        purpose: JourneyStepPurpose.fromWireNullable(json['purpose'] as String?),
        status: JourneyStepStatus.fromWireNullable(json['status'] as String?) ??
            JourneyStepStatus.upcoming,
        bloc: JourneyBlocRef.fromJsonNullable(json['bloc']),
        unite: JourneyUniteRef.fromJsonNullable(json['unite']),
        section: SkillSection.fromWireNullable(json['section'] as String?),
        taskCode: _tache(json['taskCode'] as String?),
        skillCode: json['skillCode'] as String?,
        skillTitle: json['skillTitle'] as String?,
        lotId: json['lotId'] as String?,
        sourceAssessmentId: json['sourceAssessmentId'] as String?,
        position: (json['position'] as num?)?.toInt() ?? 0,
        progress: json['progress'] == null
            ? null
            : JourneyProgress.fromJson(json['progress'] as Map<String, dynamic>),
        locked: json['locked'] as bool? ?? false,
        assessment: json['assessment'] == null
            ? null
            : PlanDomainAssessment.fromJson(
                json['assessment'] as Map<String, dynamic>),
        exercise: json['exercise'] == null
            ? null
            : PlanRecommendedExercise.fromJson(
                json['exercise'] as Map<String, dynamic>),
      );
}

/// **L'avancement du cycle** : la barre continue et son repère.
///
/// 🛑 **Des nombres, pas des phrases** : « 3 étapes sur 8 terminées » et
/// « Cycle 2 » se composent dans `journey_labels.dart`.
class JourneyCycle {
  const JourneyCycle({
    required this.numero,
    required this.etapesTerminees,
    required this.etapesTotal,
    required this.complete,
    required this.cycleDeMesure,
  });

  /// Le rang de ce cycle : nombre de cycles historisés + 1. Le premier vaut 1.
  final int numero;

  /// Étapes clôturées, **obsolètes exclues**.
  final int etapesTerminees;

  /// Étapes du cycle, obsolètes exclues — le dénominateur de la barre.
  final int etapesTotal;

  /// Plus **aucune** étape ouverte : les quatre blocs sont terminés. C'est la
  /// condition — et la seule — qui ouvre « Prochaine étape ».
  final bool complete;

  /// Ce cycle ne porte **aucune** étape d'entraînement : des examens seuls.
  final bool cycleDeMesure;

  factory JourneyCycle.fromJson(Map<String, dynamic> json) => JourneyCycle(
        numero: (json['numero'] as num?)?.toInt() ?? 1,
        etapesTerminees: (json['etapesTerminees'] as num?)?.toInt() ?? 0,
        etapesTotal: (json['etapesTotal'] as num?)?.toInt() ?? 0,
        complete: json['complete'] as bool? ?? false,
        cycleDeMesure: json['cycleDeMesure'] as bool? ?? false,
      );
}

/// **Un bloc du cycle : une épreuve.**
///
/// 🛑 **Toujours QUATRE blocs, dans l'ordre servi `CO, CE, EO, EE`** — l'ordre
/// du serveur est l'autorité, aucun front ne retrie.
class JourneyBloc {
  const JourneyBloc({
    required this.bloc,
    required this.status,
    required this.etapesRestantes,
    required this.meta,
    required this.steps,
    this.exam,
  });

  /// Le bloc **servi** — sa nature, son code et son **libellé**. C'est **lui**
  /// que le candidat lit partout (D-21, transposé par D-47).
  final JourneyBlocRef bloc;

  final JourneyBlocStatus status;

  /// Étapes d'entraînement encore ouvertes. C'est ce nombre qui verrouille
  /// l'examen du bloc (D-15).
  /// Étapes de travail encore ouvertes dans ce bloc.
  ///
  /// ⚠️ Nommé `competencesRestantes` jusqu'au 2026-09-19 (D-50) : une thématique
  /// civique ne compte pas des *compétences*. Le champ était juste, son nom
  /// mentait de l'autre côté.
  final int etapesRestantes;

  /// **La phrase d'état du bloc, SERVIE** — « 3 unités restantes · puis
  /// examen ».
  ///
  /// 🛑 Servie parce que le MOT dépend du grain du module (D-50 §4) :
  /// « compétence » côté TCF, « unité » côté civique. Un front qui le
  /// choisirait le choisirait **seul** — c'est le motif de `DETTE-P1`, dont la
  /// 3ᵉ occurrence a ouvert le chantier.
  final String meta;

  /// Les étapes d'entraînement du bloc, dans l'ordre de la file. L'examen n'y
  /// figure pas : il est servi à part, l'écran l'imbriquant en fin de bloc.
  final List<JourneyStep> steps;

  /// L'examen du bloc — l'étape ouverte s'il y en a une, sinon la dernière
  /// clôturée. `null` quand le bloc n'en porte pas encore.
  final JourneyStep? exam;

  factory JourneyBloc.fromJson(Map<String, dynamic> json) => JourneyBloc(
        bloc: JourneyBlocRef.fromJson(json['bloc'] as Map<String, dynamic>),
        status: JourneyBlocStatus.fromWireNullable(json['status'] as String?) ??
            JourneyBlocStatus.aVenir,
        etapesRestantes:
            (json['etapesRestantes'] as num?)?.toInt() ?? 0,
        meta: json['meta'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .map((item) => JourneyStep.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        exam: json['exam'] == null
            ? null
            : JourneyStep.fromJson(json['exam'] as Map<String, dynamic>),
      );
}

/// **Les issues d'un cycle terminé** (spec §6) — la carte finale à deux actions.
///
/// 🛑 `null` tant que le cycle n'est pas terminé.
class JourneyNextStep {
  const JourneyNextStep({
    required this.examenCompletPossible,
    required this.actualisationPossible,
  });

  /// « Passer l'examen blanc complet » crée un **cycle de mesure**.
  /// 🛑 Faux à la fin d'un cycle de mesure. ⚠️ Cette action **crée le cycle**,
  /// elle ne démarre aucun examen.
  final bool examenCompletPossible;

  /// « Actualiser mon plan » : le cycle en attente devient le cycle courant.
  final bool actualisationPossible;

  factory JourneyNextStep.fromJson(Map<String, dynamic> json) =>
      JourneyNextStep(
        examenCompletPossible: json['examenCompletPossible'] as bool? ?? false,
        actualisationPossible: json['actualisationPossible'] as bool? ?? false,
      );
}

/// **L'unité travaillable d'une étape, servie.**
///
/// 🛑 **Miroir mot pour mot de `JourneyUniteRefDto`** (`lib/types.ts`). Le
/// patron du bloc servi : une compétence TCF et une unité officielle civique
/// s'affichent par le **même chemin**. `skillCode` / `skillTitle` restent pour
/// ce qu'ils portent d'autre (la séance, l'exercice recommandé).
class JourneyUniteRef {
  const JourneyUniteRef({required this.code, required this.label});

  /// `EE1-C1`, `P2_LAICITE` — une **clé**, jamais un affichage.
  final String code;

  /// Ce que le **candidat lit**.
  final String label;

  factory JourneyUniteRef.fromJson(Map<String, dynamic> json) => JourneyUniteRef(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  static JourneyUniteRef? fromJsonNullable(Object? json) =>
      json is Map<String, dynamic> ? JourneyUniteRef.fromJson(json) : null;
}

/// La nature de l'objectif d'un cycle. Miroir de `JourneyObjectifKind`.
enum JourneyObjectifKind {
  niveau('NIVEAU'),
  procedure('PROCEDURE');

  const JourneyObjectifKind(this.wire);
  final String wire;

  static JourneyObjectifKind fromWire(String? value) =>
      JourneyObjectifKind.values.firstWhere((e) => e.wire == value,
          orElse: () => JourneyObjectifKind.niveau);
}

/// **L'objectif d'un cycle, servi** — ce vers quoi le candidat travaille.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/types.ts`
/// (`JourneyObjectifRefDto`).**
///
/// 🛑 **Le patron du bloc servi** ([JourneyBlocRef], D-47), appliqué au dernier
/// champ du contrat qui était encore typé TCF : `targetLevel` ne pouvait pas
/// porter l'objectif d'un cycle civique, qui est une **mention**.
///
/// L'écran lit [kind] pour choisir sa **tournure**, **jamais pour brancher sur
/// le module**. Le [label] arrive servi : c'est le mot du livret.
class JourneyObjectifRef {
  const JourneyObjectifRef({
    required this.kind,
    required this.code,
    required this.label,
  });

  final JourneyObjectifKind kind;

  /// L'identifiant stable — `B2`, `NAT`. Une **clé**, jamais un affichage.
  final String code;

  /// Ce que le **candidat lit** — « B2 », « Naturalisation ».
  final String label;

  factory JourneyObjectifRef.fromJson(Map<String, dynamic> json) =>
      JourneyObjectifRef(
        kind: JourneyObjectifKind.fromWire(json['kind'] as String?),
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  static JourneyObjectifRef? fromJsonNullable(Object? json) =>
      json is Map<String, dynamic> ? JourneyObjectifRef.fromJson(json) : null;
}

/// Le parcours servi.
class Journey {
  const Journey({
    required this.state,
    required this.blocs,
    this.objectif,
    this.current,
    this.suggestion,
    this.cycle,
    this.nextStep,
  });

  /// **L'objectif du cycle, servi.** `null` quand [state] vaut
  /// [JourneyState.needsObjective].
  final JourneyObjectifRef? objectif;

  final JourneyState state;

  /// L'étape à faire maintenant. `null` dans quatre cas que [state] distingue :
  /// pas d'objectif, cycle terminé, plus rien à faire, rien d'exécutable.
  final JourneyStep? current;

  /// L'avancement du cycle borné. `null` sans parcours.
  ///
  /// ⚠️ **`steps` et `hiddenUpcomingCount` ont quitté ce miroir** (2026-09-18) :
  /// la file plate est remplacée par les blocs, et le serveur retire ces deux
  /// champs juste après. Les relire serait rouvrir un second parcours.
  final JourneyCycle? cycle;

  /// Les quatre blocs, **dans l'ordre servi**. Vide sans parcours.
  final List<JourneyBloc> blocs;

  /// 🛑 `null` sauf cycle terminé.
  final JourneyNextStep? nextStep;

  /// `null` est le cas courant.
  final JourneySuggestionType? suggestion;

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
        objectif: JourneyObjectifRef.fromJsonNullable(json['objectif']),
        state: JourneyState.fromWireNullable(json['state'] as String?) ??
            JourneyState.needsObjective,
        current: json['current'] == null
            ? null
            : JourneyStep.fromJson(json['current'] as Map<String, dynamic>),
        cycle: json['cycle'] == null
            ? null
            : JourneyCycle.fromJson(json['cycle'] as Map<String, dynamic>),
        blocs: (json['blocs'] as List<dynamic>? ?? const [])
            .map((item) => JourneyBloc.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        nextStep: json['nextStep'] == null
            ? null
            : JourneyNextStep.fromJson(json['nextStep'] as Map<String, dynamic>),
        suggestion:
            JourneySuggestionType.fromWireNullable(json['suggestion'] as String?),
      );
}


/// Idem pour la tâche : `null` veut dire **compétence de compréhension**, un
/// fait ordinaire — jamais une erreur de lecture.
SkillTaskCode? _tache(String? wire) {
  if (wire == null) return null;
  for (final tache in SkillTaskCode.values) {
    if (tache.wire == wire) return tache;
  }
  return null;
}

/* =============================================================================
   L'HISTORIQUE DES CYCLES — « Mes cycles » (ex-« Ma progression », D16)
   Miroir manuel de `JourneyHistoryDto` (`GET /api/me/plan/journey/history`).

   🛑 **Rien n'y est recalcule cote front.** Les compteurs, les titres de
   competence et les deux niveaux sont servis ; les phrases (« 6 competences »,
   « Niveau mesure », les dates) se composent dans
   `screens/plan/journey_labels.dart`, miroir de `web_sejoufr/lib/journey.ts`.

   🛑 **`cycles` vide est un ETAT D'ECRAN**, pas une erreur : aucun cycle n'a
   encore ete historise, et les compteurs du bandeau restent vrais.
   ========================================================================== */

/// Les trois compteurs du bandeau. **Servis**, jamais recomptes d'une liste.
class JourneyHistoryStats {
  const JourneyHistoryStats({
    required this.competencesTravaillees,
    required this.examensPasses,
    required this.cyclesTermines,
  });

  final int competencesTravaillees;
  final int examensPasses;
  final int cyclesTermines;

  factory JourneyHistoryStats.fromJson(Map<String, dynamic> json) =>
      JourneyHistoryStats(
        competencesTravaillees:
            (json['competencesTravaillees'] as num?)?.toInt() ?? 0,
        examensPasses: (json['examensPasses'] as num?)?.toInt() ?? 0,
        cyclesTermines: (json['cyclesTermines'] as num?)?.toInt() ?? 0,
      );
}

/// Ce qu'un bloc a recu pendant un cycle historise.
class JourneyHistoryBloc {
  const JourneyHistoryBloc({
    required this.bloc,
    required this.skillTitles,
    required this.examens,
  });

  /// **Le bloc, servi** — epreuve TCF ou thematique civique (D-47).
  /// ⚠️ Remplace `examType`, dernier champ type TCF de l'historique.
  final JourneyBlocRef bloc;

  /// Les unites travaillees, **dans l'ordre servi** : competences TCF ou
  /// unites officielles civiques.
  final List<String> skillTitles;

  /// Les examens de ce bloc enregistres pendant le cycle.
  final int examens;

  factory JourneyHistoryBloc.fromJson(Map<String, dynamic> json) =>
      JourneyHistoryBloc(
        bloc: JourneyBlocRef.fromJsonNullable(json['bloc']) ??
            const JourneyBlocRef(
                kind: JourneyBlocKind.epreuve, code: '', label: ''),
        skillTitles: (json['skillTitles'] as List<dynamic>? ?? const [])
            .map((item) => item as String)
            .toList(growable: false),
        examens: (json['examens'] as num?)?.toInt() ?? 0,
      );
}

/// Un cycle **historise**.
class JourneyHistoryCycle {
  const JourneyHistoryCycle({
    required this.numero,
    required this.debut,
    required this.fin,
    required this.competences,
    required this.examens,
    required this.blocs,
    this.entryLevel,
    this.exitLevel,
    this.entryScore,
    this.exitScore,
  });

  /// Le rang du cycle, tel que le Plan l'affichait (« Cycle 2 »).
  final int numero;

  final DateTime debut;

  /// La date d'historisation.
  final DateTime fin;

  final int competences;
  final int examens;

  /// Le niveau au moment ou le cycle s'est ouvert — le niveau de sortie du
  /// precedent, ou celui du diagnostic pour le premier. `null` = **inconnu**.
  final TargetLevel? entryLevel;

  /// Le niveau **persiste a l'historisation** (D-12), jamais recalcule.
  ///
  /// 🛑 `null` = rien n'a ete mesure, ou la mesure est **sous l'A2**, que la
  /// colonne ne sait pas dire (A35). Aucun front n'y met un palier a la
  /// place : `null` = inconnu, jamais mauvais.
  final TargetLevel? exitLevel;

  /// **Le score d'entrée — CIVIQUE**, sur 40. `null` côté TCF, et `null` côté
  /// civique sans examen complet : **inconnu, jamais zéro**.
  final int? entryScore;

  /// **Le score de sortie — CIVIQUE**. Même règle.
  final int? exitScore;

  /// Un bloc par epreuve touchee, **dans l'ordre servi**.
  final List<JourneyHistoryBloc> blocs;

  factory JourneyHistoryCycle.fromJson(Map<String, dynamic> json) =>
      JourneyHistoryCycle(
        numero: (json['numero'] as num?)?.toInt() ?? 1,
        debut: DateTime.parse(json['debut'] as String),
        fin: DateTime.parse(json['fin'] as String),
        competences: (json['competences'] as num?)?.toInt() ?? 0,
        examens: (json['examens'] as num?)?.toInt() ?? 0,
        entryLevel:
            TargetLevel.fromWireNullable(json['entryLevel'] as String?),
        exitLevel: TargetLevel.fromWireNullable(json['exitLevel'] as String?),
        entryScore: (json['entryScore'] as num?)?.toInt(),
        exitScore: (json['exitScore'] as num?)?.toInt(),
        blocs: (json['blocs'] as List<dynamic>? ?? const [])
            .map((item) =>
                JourneyHistoryBloc.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// L'archive servie.
class JourneyHistory {
  const JourneyHistory({required this.stats, required this.cycles});

  final JourneyHistoryStats stats;

  /// Du plus recent au plus ancien, **dans l'ordre servi**.
  final List<JourneyHistoryCycle> cycles;

  factory JourneyHistory.fromJson(Map<String, dynamic> json) => JourneyHistory(
        stats: JourneyHistoryStats.fromJson(
            json['stats'] as Map<String, dynamic>? ?? const {}),
        cycles: (json['cycles'] as List<dynamic>? ?? const [])
            .map((item) =>
                JourneyHistoryCycle.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/* ===========================================================================
 * LE DÉTAIL D'UNE ÉTAPE DE SÉRIES — l'écran intermédiaire du Plan
 * GET  /api/me/plan/journey/steps/{stepId}
 * POST /api/me/plan/journey/steps/{stepId}/series/{index}
 *
 * Miroir manuel de `JourneyStepDetailDto`. C'est ce qui s'ouvre quand on touche
 * une étape d'entraînement de **compréhension** (CO/CE) ou une étape
 * **civique** dans le cycle du Plan : la compétence ou l'unité travaillée, son
 * avancement, et ses séries une par une.
 *
 * 🛑 **Les étapes d'EXPRESSION (EE/EO) n'entrent pas ici** : elles gardent leur
 * chemin vers leurs petits sujets.
 *
 * 🛑 **Aucune phrase n'est servie.** « À faire », « Verrouillée », « Réussie »,
 * « À refaire », « Après la série 1 », l'encart de validation et le pied de
 * page se composent dans `screens/plan/journey_etape_labels.dart`, miroir de
 * `web_sejoufr/lib/journey-etape.ts`.
 * ======================================================================== */

/// L'unité travaillée, **avec sa description**.
///
/// ⚠️ **Une extension de [JourneyUniteRef], pas un second contrat** : le code et
/// le libellé sont ceux que le cycle sert déjà, et le détail y ajoute la phrase
/// du référentiel que l'écran met sous le titre.
class JourneyUniteDetail {
  const JourneyUniteDetail({
    required this.code,
    required this.label,
    this.description,
  });

  /// `CO-B1`, `P2_LAICITE` — une **clé**, jamais un affichage.
  final String code;

  /// Ce que le **candidat lit**.
  final String label;

  /// La phrase du référentiel sous le titre. `null` = aucune description.
  final String? description;

  factory JourneyUniteDetail.fromJson(Map<String, dynamic> json) =>
      JourneyUniteDetail(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String?,
      );
}

/// **Une série de l'étape.**
///
/// 🛑 **L'état se lit sur [locked] et [validee], jamais en comparant
/// [dernierScore] à `seuilReussite`.** Un front qui classerait un nombre en état
/// pédagogique désignerait tôt ou tard autre chose que le serveur — c'est la
/// règle « aucun front ne classe un nombre » du dépôt.
class JourneySerie {
  const JourneySerie({
    required this.index,
    required this.locked,
    required this.validee,
    this.dernierScore,
    this.dernierAttemptId,
    this.dernierEssaiAt,
  });

  /// 1, 2 — le rang **servi**, et la clé du démarrage.
  final int index;

  /// La série précédente n'est pas réussie. **Servi**, jamais déduit d'un rang.
  final bool locked;

  /// Réussie **au moins une fois** — et c'est DÉFINITIF : une série refaite et
  /// ratée reste validée, seule la carte change de dernier score.
  final bool validee;

  /// Sur `questionsParSerie`. `null` = **jamais jouée**, jamais zéro.
  final int? dernierScore;

  /// De quoi rouvrir le corrigé de la dernière passation. `null` si jamais jouée.
  final String? dernierAttemptId;

  final DateTime? dernierEssaiAt;

  factory JourneySerie.fromJson(Map<String, dynamic> json) => JourneySerie(
        index: (json['index'] as num?)?.toInt() ?? 1,
        locked: json['locked'] as bool? ?? false,
        validee: json['validee'] as bool? ?? false,
        dernierScore: (json['dernierScore'] as num?)?.toInt(),
        dernierAttemptId: json['dernierAttemptId'] as String?,
        dernierEssaiAt: json['dernierEssaiAt'] == null
            ? null
            : DateTime.tryParse(json['dernierEssaiAt'] as String),
      );
}

/// L'étape d'entraînement, dépliée.
class JourneyStepDetail {
  const JourneyStepDetail({
    required this.stepId,
    required this.type,
    required this.bloc,
    required this.unite,
    required this.priorite,
    required this.quota,
    required this.validees,
    required this.questionsParSerie,
    required this.seuilReussite,
    required this.locked,
    required this.series,
    this.section,
    this.objectif,
    this.dureeEstimeeMin,
  });

  final String stepId;
  final JourneyStepType type;

  /// « Compréhension orale » / la thématique civique — le titre de l'écran.
  final JourneyBlocRef bloc;

  /// La compétence TCF ou l'unité officielle civique travaillée.
  final JourneyUniteDetail unite;

  /// `null` en civique.
  final SkillSection? section;

  /// **Ce vers quoi le candidat travaille, servi avec son libellé** — un palier
  /// (« B2 ») ou une **mention** (« Naturalisation »).
  ///
  /// 🛑 **On lit `label`, jamais `code`, et on ne branche jamais sur le
  /// module** : c'est le patron [JourneyBlocRef] (D-47), et c'est exactement ce
  /// que ce type existe pour éviter. Seule la **tournure** se choisit sur
  /// `kind`, comme dans `journeyTitle`.
  ///
  /// `null` si aucun objectif n'est déclaré.
  final JourneyObjectifRef? objectif;

  /// La pastille « Priorité ». **Servi.**
  final bool priorite;

  /// Le nombre de séries à réussir.
  final int quota;

  /// Les séries déjà réussies, sur [quota].
  ///
  /// 🛑 **SERVI, jamais recompté depuis [series]** : c'est le **même** nombre
  /// que le moteur compare au quota pour clore l'étape, donc l'écran ne peut
  /// pas annoncer « 1 sur 2 » sur une étape que le serveur vient de clore.
  final int validees;

  final int questionsParSerie;

  /// 🛑 **SERVI, jamais écrit dans un front** : c'est le seuil de réussite.
  final int seuilReussite;

  /// En minutes. `null` = inconnu — l'écran n'affiche alors aucune durée.
  final int? dureeEstimeeMin;

  /// Le verrou **freemium** de l'étape. L'écran reste entier et lisible.
  final bool locked;

  /// Les séries, **dans l'ordre servi**.
  final List<JourneySerie> series;

  factory JourneyStepDetail.fromJson(Map<String, dynamic> json) =>
      JourneyStepDetail(
        stepId: json['stepId'] as String? ?? '',
        type: JourneyStepType.fromWireNullable(json['type'] as String?) ??
            JourneyStepType.trainSkill,
        bloc: JourneyBlocRef.fromJson(
            json['bloc'] as Map<String, dynamic>? ?? const {}),
        unite: JourneyUniteDetail.fromJson(
            json['unite'] as Map<String, dynamic>? ?? const {}),
        section: SkillSection.fromWireNullable(json['section'] as String?),
        objectif: JourneyObjectifRef.fromJsonNullable(json['objectif']),
        priorite: json['priorite'] as bool? ?? false,
        quota: (json['quota'] as num?)?.toInt() ?? 0,
        validees: (json['validees'] as num?)?.toInt() ?? 0,
        questionsParSerie: (json['questionsParSerie'] as num?)?.toInt() ?? 0,
        seuilReussite: (json['seuilReussite'] as num?)?.toInt() ?? 0,
        dureeEstimeeMin: (json['dureeEstimeeMin'] as num?)?.toInt(),
        locked: json['locked'] as bool? ?? false,
        series: (json['series'] as List<dynamic>? ?? const [])
            .map((item) => JourneySerie.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );
}
