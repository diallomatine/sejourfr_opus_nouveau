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

  /// Des étapes restent ouvertes mais **aucune n'est exécutable** : [Journey.current]
  /// vaut `null` et la carte montre la première étape de [Journey.steps],
  /// verrouillée, avec son paywall.
  locked('LOCKED'),

  /// Plus aucune étape ouverte.
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

/// Une étape de la file.
class JourneyStep {
  const JourneyStep({
    required this.id,
    required this.type,
    required this.status,
    required this.position,
    required this.locked,
    this.purpose,
    this.examType,
    this.section,
    this.taskCode,
    this.skillCode,
    this.skillTitle,
    this.lotId,
    this.sourceAssessmentId,
    this.progress,
  });

  final String id;
  final JourneyStepType type;

  /// Non `null` pour les seules étapes [JourneyStepType.sectionExam].
  final JourneyStepPurpose? purpose;

  final JourneyStepStatus status;

  /// `null` pour une étape [JourneyStepType.diagnostic] seulement.
  final EpreuveType? examType;

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
  /// 🛑 Une étape verrouillée reste **affichée à sa place** et ne devient
  /// **jamais** courante : le parcours avance au lieu de mourir, et le Plan
  /// reste intégralement visible.
  final bool locked;

  factory JourneyStep.fromJson(Map<String, dynamic> json) => JourneyStep(
        id: json['id'] as String,
        type: JourneyStepType.fromWireNullable(json['type'] as String?) ??
            JourneyStepType.trainSkill,
        purpose: JourneyStepPurpose.fromWireNullable(json['purpose'] as String?),
        status: JourneyStepStatus.fromWireNullable(json['status'] as String?) ??
            JourneyStepStatus.upcoming,
        examType: _epreuve(json['examType'] as String?),
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
      );
}

/// Le parcours servi.
class Journey {
  const Journey({
    required this.state,
    required this.steps,
    required this.hiddenUpcomingCount,
    this.targetLevel,
    this.current,
    this.suggestion,
  });

  /// `null` quand [state] vaut [JourneyState.needsObjective].
  final TargetLevel? targetLevel;

  final JourneyState state;

  /// L'étape à faire maintenant. `null` dans trois cas que [state] distingue :
  /// pas d'objectif, plus rien à faire, ou rien d'exécutable.
  final JourneyStep? current;

  /// Déjà filtrées côté serveur et dans l'ordre de la file. Les étapes obsolètes
  /// n'y sont jamais.
  final List<JourneyStep> steps;

  final int hiddenUpcomingCount;

  /// `null` est le cas courant.
  final JourneySuggestionType? suggestion;

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
        targetLevel: TargetLevel.fromWireNullable(json['targetLevel'] as String?),
        state: JourneyState.fromWireNullable(json['state'] as String?) ??
            JourneyState.needsObjective,
        current: json['current'] == null
            ? null
            : JourneyStep.fromJson(json['current'] as Map<String, dynamic>),
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .map((item) => JourneyStep.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        hiddenUpcomingCount:
            (json['hiddenUpcomingCount'] as num?)?.toInt() ?? 0,
        suggestion:
            JourneySuggestionType.fromWireNullable(json['suggestion'] as String?),
      );
}

/// 🛑 **Une valeur inconnue rend `null`, jamais une exception ni un repli
/// arbitraire.** Un front qui planterait sur une épreuve ajoutée côté serveur
/// serait pire qu'un front qui l'ignore ; et lui inventer une épreuve la
/// rangerait dans le mauvais domaine.
EpreuveType? _epreuve(String? wire) {
  if (wire == null) return null;
  for (final epreuve in EpreuveType.values) {
    if (epreuve.wire == wire) return epreuve;
  }
  return null;
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
