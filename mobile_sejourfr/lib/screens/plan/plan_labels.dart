
/// **Les phrases du Plan.**
///
/// Le serveur expose des faits — un domaine évalué ou non, un palier qui
/// bloque, une fenêtre de changements, une étape de chemin — et **aucun
/// libellé** pour les domaines, le cycle, le chemin ni la séance. La phrase
/// appartient donc au front, et elle vit ici plutôt que dans les widgets :
/// c'est le seul moyen de garantir qu'un même fait se dise de la même façon
/// sur le Plan, sur la fiche d'un domaine et sur le résultat d'une série.
///
/// 🛑 **Rien n'est déduit ici qui ne soit pas servi.** Aucun niveau n'est
/// inventé (`objectiveLevel` est nullable et le reste), aucun pourcentage n'est
/// fabriqué, aucun domaine n'est retrié — le serveur les trie.
///
/// **Vouvoiement** : le Plan vouvoie, contrairement au module « Compétences ».
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/skill_models.dart';

/* ------------------------------------------------------------- les domaines */

/// Le domaine en toutes lettres. On délègue à [SkillSection.label], miroir du
/// backend, plutôt que d'écrire une seconde table de libellés.
String planDomainLabel(EpreuveType epreuve) =>
    planDomainSection(epreuve)?.label ?? 'Domaine TCF';

/// Le domaine, en abrégé : « CO », « EE »… Sert aux repères de ligne.
String planDomainShort(EpreuveType epreuve) =>
    planDomainSection(epreuve)?.wire ?? '—';

/// La section de compétences correspondant à un domaine du TCF. `null` sur une
/// épreuve qui n'est pas un domaine du Plan (civique, structure, complet).
SkillSection? planDomainSection(EpreuveType epreuve) => switch (epreuve) {
      EpreuveType.tcfCo => SkillSection.co,
      EpreuveType.tcfCe => SkillSection.ce,
      EpreuveType.tcfEe => SkillSection.ee,
      EpreuveType.tcfEo => SkillSection.eo,
      _ => null,
    };

/// Icône d'un domaine — la même que celle de son hub (`TcfQcmModule`) et de son
/// parcours, pour qu'un candidat reconnaisse le domaine d'un écran à l'autre.
IconData planDomainIcon(EpreuveType? epreuve) => switch (epreuve) {
      EpreuveType.tcfCo => LucideIcons.ear,
      EpreuveType.tcfCe => LucideIcons.fileText,
      EpreuveType.tcfEe => LucideIcons.penLine,
      EpreuveType.tcfEo => LucideIcons.mic,
      _ => LucideIcons.target,
    };

/// Clé de route d'un domaine (`/plan/domaine/co`). Aucune information n'y
/// voyage au-delà du domaine : la fiche relit le Plan déjà chargé.
String planDomainKey(EpreuveType epreuve) => switch (epreuve) {
      EpreuveType.tcfCo => 'co',
      EpreuveType.tcfCe => 'ce',
      EpreuveType.tcfEe => 'ee',
      EpreuveType.tcfEo => 'eo',
      _ => 'co',
    };

/// Le domaine du TCF correspondant à une section de compétences — la réciproque
/// de [planDomainSection]. C'est ce qui permet d'envoyer une priorité de
/// **compréhension** vers la fiche de son domaine : elle n'a pas d'écran de
/// compétence, la voie des petits sujets étant celle de l'expression.
EpreuveType? planEpreuveOfSection(SkillSection section) => switch (section) {
      SkillSection.co => EpreuveType.tcfCo,
      SkillSection.ce => EpreuveType.tcfCe,
      SkillSection.ee => EpreuveType.tcfEe,
      SkillSection.eo => EpreuveType.tcfEo,
    };

EpreuveType? planDomainFromKey(String key) => switch (key) {
      'co' => EpreuveType.tcfCo,
      'ce' => EpreuveType.tcfCe,
      'ee' => EpreuveType.tcfEe,
      'eo' => EpreuveType.tcfEo,
      _ => null,
    };

/// La ligne sous le nom d'un domaine, dans la liste du profil.
///
/// Un domaine jamais mesuré est **inconnu, jamais mauvais** : on dit comment le
/// mesurer, on ne lui prête aucun niveau.
String planDomainSubtitle(PlanDomain domain) {
  if (!domain.evaluated || domain.niveau == null) {
    return kPlanDomainNotEvaluated;
  }
  return 'Niveau estimé ${domain.niveau!.displayName}';
}

const String kPlanDomainNotEvaluated =
    'Pas encore mesuré — votre profil se précisera à votre prochain examen '
    'blanc de cette épreuve.';

/// Ce que le Plan retient d'un domaine, sur sa fiche. Uniquement des faits
/// servis : le palier consolidé, celui qui bloque, les compétences observées.
String planDomainSummary(PlanDomain domain) {
  if (!domain.evaluated) return kPlanDomainNotEvaluated;

  if (domain.paliers.isNotEmpty) {
    final blocking = domain.blockingLevel;
    final consolidated = domain.consolidatedLevel;
    if (blocking == null) {
      return 'Vos trois paliers sont consolidés sur ce domaine.';
    }
    if (consolidated == null) {
      return 'Le palier ${blocking.wire} n\'est pas encore consolidé : c\'est '
          'lui qui commande la suite.';
    }
    return 'Palier consolidé : ${consolidated.wire}. Le ${blocking.wire} n\'est '
        'pas encore acquis, c\'est lui qui commande la suite.';
  }

  if (domain.taches.isNotEmpty) {
    var observed = 0;
    var total = 0;
    for (final task in domain.taches) {
      observed += task.observedSkills;
      total += task.totalSkills;
    }
    if (total == 0) return 'Vos tâches de ce domaine sont en cours de mesure.';
    return '$observed compétence${observed > 1 ? 's' : ''} observée'
        '${observed > 1 ? 's' : ''} sur $total, réparties sur '
        '${domain.taches.length} tâche${domain.taches.length > 1 ? 's' : ''}.';
  }

  return 'Ce domaine est mesuré ; son détail arrive à votre prochaine session.';
}

/// « 3 / 8 compétences observées » — **pas une note** : une compétence non
/// observée n'est pas une compétence ratée. Le dénominateur vient du serveur.
String planTaskObservedLabel(PlanDomainTask task) =>
    '${task.observedSkills} / ${task.totalSkills} compétences observées';

/// Titre d'une tâche d'expression sur la fiche d'un domaine.
String planTaskTitle(PlanDomainTask task) => 'Tâche ${task.tacheNumero}';

/// « EE1 · Expression écrite » — le repère factuel sous le titre d'une
/// compétence. Le code peut manquer : on n'affiche alors que le domaine.
String planSkillMeta(String skillCode, SkillSection section) =>
    skillCode.isEmpty ? section.label : '$skillCode · ${section.label}';

const String kPlanComprehensionNote =
    'En compréhension, une compétence se mesure sur une série complète : c\'est '
    'ce qui permet de savoir si la difficulté est vraiment récurrente.';

const String kPlanNotEvaluatedNote =
    'Un domaine jamais mesuré n\'est pas un domaine faible : c\'est un domaine '
    'inconnu. Tant qu\'il l\'est, le Plan ne lui prête aucun niveau.';

/* ------------------------------------------------------------- les paliers  */

/// La ligne d'un palier de compréhension sur la fiche d'un domaine.
///
/// **Aucun pourcentage** : le score interne du moteur de maîtrise n'est exposé
/// à aucun front. `masteryState == null` veut dire « jamais observé ».
String planLevelSubtitle(PlanDomainLevel level) {
  if (level.blocking) return 'C\'est ce palier qui commande la suite';
  return level.masteryState == null
      ? 'Pas encore observé'
      : level.masteryState!.label;
}

const String kPlanLevelBlockingTag = 'À DÉBLOQUER';
const String kPlanSeriesCta = 'Faire une série ciblée';

/* -------------------------------------------------------------- la séance   */

const String kPlanSeanceTitle = 'Aujourd\'hui';
const String kPlanSeanceWhy = 'Pourquoi cette séance ?';
const String kPlanSeanceEmpty =
    'Rien à faire pour le moment : votre prochaine étape se décide à votre '
    'prochaine production.';
const String kPlanSeanceRestart = 'Refaire ma séance';
const String kPlanSeanceStart = 'Commencer ma séance';

/// « 3 entraînements · environ 24 min ». Le total est **recalculé serveur**, on
/// l'affiche tel quel.
String planSeanceMeta(PlanSeance seance) {
  final count = seance.items.length;
  return '$count entraînement${count > 1 ? 's' : ''} · environ '
      '${seance.estimatedMinutes} min';
}

/// Ce qu'est un item de la séance, en une formule. C'est la **nature** de
/// l'action, jamais un jugement sur le candidat.
String planItemKindLabel(PlanSeanceItem item) => switch (item.kind) {
      PlanExerciseKind.microTraining => 'Petit sujet ciblé',
      PlanExerciseKind.reassessment => 'Vérification en situation',
      PlanExerciseKind.targetedQcmSeries => planSeriesLabel(
          item.exercise?.questionCount,
        ),
      PlanExerciseKind.epreuveMockExam ||
      PlanExerciseKind.fullTcfMockExam =>
        'Examen blanc',
    };

/// « Série de 20 questions » — la taille est **décidée serveur**. Sans elle, on
/// ne l'invente pas.
String planSeriesLabel(int? questionCount) => questionCount == null
    ? 'Série ciblée de compréhension'
    : 'Série ciblée · $questionCount questions';

/// Le repère de ligne d'un item : « CO · B1 », « EE ».
///
/// Un **jalon** n'a ni section ni palier travaillé (il les vérifie tous) : son
/// repère vient de son épreuve. On lit [PlanSeanceItem.kind], jamais la nullité
/// d'un champ.
String planItemEyebrow(PlanSeanceItem item) {
  final milestone = item.milestone;
  if (milestone != null) return planDomainShort(milestone.epreuve);
  final section = item.section?.wire ?? '—';
  final level = item.level;
  return level == null ? section : '$section · $level';
}

/// « Pourquoi cette séance ? », composé **des faits servis** : ce que chaque
/// item travaille, où en est son étape, et si le serveur attend une
/// vérification. Aucune phrase ne vient du serveur.
List<String> planSeanceRationale(LearningPlan plan) {
  final lines = <String>[];
  final seance = plan.seance;
  if (seance.isEmpty) {
    lines.add(kPlanSeanceEmpty);
    return lines;
  }

  final priority = plan.currentPriority;
  if (priority != null) {
    lines.add(
      'Votre priorité n°1 est « ${priority.title} » : c\'est elle qui ouvre '
      'votre séance, parce que c\'est elle qui vous fera progresser le plus '
      'vite.',
    );
  }

  final comprehension =
      seance.items.where((i) => i.section?.isComprehension ?? false).length;
  if (comprehension > 0) {
    lines.add(
      'Vos séries de compréhension ne mesurent pas un domaine : elles '
      'entraînent la compétence exacte qui bloque votre palier. C\'est un '
      'examen blanc qui mesure un domaine.',
    );
  }

  if (seance.items.any((i) => i.readyForReassessment)) {
    lines.add(
      'Une de vos étapes est terminée : le Plan vous demande maintenant de le '
      'prouver sur une vraie tâche, pas sur un exercice ciblé.',
    );
  }

  lines.add(
    'Cette séance est recalculée à chaque nouveau résultat. Rien n\'y est '
    'périmé par le temps qui passe : c\'est ce que vous faites qui la fait '
    'avancer.',
  );
  return lines;
}

/* -------------------------------------------------------------- le cycle    */

/// Titre de la section « chemin ». Le palier visé est **nullable** : sans lui,
/// on ne nomme aucun objectif.
String planPathTitle(TargetLevel? objective) => objective == null
    ? 'Mon chemin'
    : 'Mon chemin vers le ${objective.wire}';

/// Titre d'une étape du chemin. Le serveur dit **quoi** et **où on en est** ;
/// la phrase est d'ici.
String planPathStepTitle(PlanPathStep step, TargetLevel? objective) =>
    switch (step.kind) {
      PlanPathStepKind.completeProfile => 'Compléter mon profil',
      PlanPathStepKind.buildLevel => step.level == null
          ? 'Construire mon palier'
          : 'Construire mon ${step.level!.wire}',
      PlanPathStepKind.stabilize => objective == null
          ? 'Stabiliser mon niveau'
          : 'Stabiliser mon ${objective.wire}',
    };

String planPathStepStatusLabel(PlanPathStepStatus status) => switch (status) {
      PlanPathStepStatus.done => 'Terminé',
      PlanPathStepStatus.current => 'En cours',
      PlanPathStepStatus.upcoming => 'À venir',
    };

/// La ligne de contexte sous l'en-tête. Elle ne promet rien : elle dit d'où
/// vient ce qui est affiché.
String planContextLine(NiveauCecrl? estimated) => estimated == null
    ? 'Mis à jour selon vos derniers résultats'
    : 'Mis à jour selon vos derniers résultats · niveau estimé '
        '${estimated.displayName}';

/// « 2 domaines sur 4 évalués ».
String planProfileCoverage(PlanCycle? cycle, int fallbackTotal) {
  final evaluated = cycle?.domainsEvaluated ?? 0;
  final expected = cycle?.domainsExpected ?? fallbackTotal;
  return '$evaluated domaine${evaluated > 1 ? 's' : ''} sur $expected '
      'évalué${evaluated > 1 ? 's' : ''}';
}

const String kPlanProfileTitle = 'Mon profil TCF';
const String kPlanCompleteProfileTitle = 'Compléter mon profil';
const String kPlanCompleteProfileText =
    'Votre diagnostic portait sur une production écrite et une production '
    'orale. Les domaines ci-dessous n\'ont encore jamais été mesurés — voici '
    'par quoi les mesurer.';
const String kPlanPrioritiesTitle = 'Mes priorités';
const String kPlanPrioritiesAll = 'Tout voir';
const String kPlanPrioritiesLess = 'Réduire';
const String kPlanObservedTitle = 'Mes compétences observées';

/// Ce qu'il faut lancer pour mesurer un domaine — **jamais** une série ciblée,
/// qui est un entraînement.
String planAssessmentLabel(PlanDomainAssessment assessment) =>
    switch (assessment.kind) {
      PlanDomainAssessmentKind.diagnostic => 'Passer le diagnostic',
      PlanDomainAssessmentKind.moduleMockExam => assessment.slotNumber == null
          ? 'Passer un examen blanc'
          : 'Examen blanc n°${assessment.slotNumber}',
      PlanDomainAssessmentKind.production => 'Rendre une production',
    };

String planAssessmentMeta(PlanDomainAssessment assessment) {
  final minutes = assessment.estimatedMinutes;
  final label = planAssessmentLabel(assessment);
  return minutes == null ? label : '$label · ≈ $minutes min';
}

/* ------------------------------------------------------- ce qui a changé    */

const String kPlanChangesDetail = 'Voir le détail';
const String kPlanChangesNewPriority = 'NOUVELLE PRIORITÉ';
const String kPlanBannerLabel = 'Plan actualisé';

/// « Priorité → En consolidation ». `before == null` veut dire « jamais
/// observée » : on le dit, on n'invente pas d'état de départ.
String planTransitionLabel(PlanMasteryTransition transition) {
  final before = transition.before?.label ?? 'Jamais observée';
  return '$before → ${transition.after.label}';
}

/// Le bandeau du haut, quand quelque chose a bougé.
String planBannerText(PlanRecentChanges changes) {
  final moves = changes.transitions.length;
  if (moves == 0) return 'une nouvelle priorité a été désignée';
  return '$moves compétence${moves > 1 ? 's' : ''} '
      '${moves > 1 ? 'ont' : 'a'} changé d\'état';
}

/* ---------------------------------------------- « votre programme évolue »  */

const String kPlanEvolutionTitle = 'Votre programme évolue';
const String kPlanEvolutionCta = 'Revenir à mon plan';
const String kPlanEvolutionNote =
    'Le CECRL n\'est pas une progression linéaire : chaque palier se construit '
    'compétence par compétence, et vos quatre domaines n\'avancent pas à la '
    'même vitesse.';
const String kPlanEvolutionEmpty =
    'Rien n\'a bougé depuis votre dernière session. Votre programme change '
    'quand un nouveau résultat arrive.';

/// Ce que le cycle construit maintenant. `startingLevel` est nullable tant que
/// rien n'est mesuré, `objectiveLevel` tant que la démarche n'est pas déclarée.
String planEvolutionSubtitle(PlanCycle? cycle) {
  if (cycle == null) return 'Votre programme suit vos derniers résultats.';
  final from = cycle.startingLevel?.displayName;
  final target = cycle.targetLevel.wire;
  return from == null
      ? 'Votre programme construit votre $target.'
      : 'Vous partez du $from ; votre programme construit votre $target.';
}

/* ------------------------------------------------------- la série ciblée    */

const String kPlanSerieDoneTitle = 'Série terminée';
const String kPlanSerieImpact = 'Impact sur votre maîtrise';
const String kPlanSerieBack = 'Revenir à mon plan';
const String kPlanSerieAgain = 'Faire une nouvelle série';
const String kPlanSerieNext = 'À travailler ensuite';
const String kPlanSerieConfirmed = 'Statut confirmé';
const String kPlanSerieUnchanged = 'Inchangé';
const String kPlanSeriePending =
    'Votre maîtrise se met à jour dès que ce résultat est pris en compte : '
    'elle apparaîtra sur votre plan.';
const String kPlanSerieNote =
    'Une série ciblée entraîne une compétence ; elle ne mesure pas le domaine. '
    'Seul un examen blanc de l\'épreuve le fait.';
