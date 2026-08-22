
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
import 'plan_milestone_labels.dart';

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
    return kPlanDomainNotEvaluatedShort;
  }
  return 'Niveau estimé ${domain.niveau!.displayName}';
}

/// L'état d'un domaine jamais mesuré, **en trois mots** — miroir mot pour mot du
/// web (`PLAN_DOMAIN_NOT_EVALUATED`). C'est ce que porte une **ligne de liste** :
/// le *comment le mesurer* vit juste en dessous, dans « Compléter mon profil »,
/// des deux côtés.
const String kPlanDomainNotEvaluatedShort = 'Pas encore évaluée';

/// La forme longue, réservée aux surfaces qui ont la place d'**expliquer** : la
/// fiche d'un domaine et son résumé. Jamais sur une ligne de liste.
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

/// « Tâche 1 · 3 / 8 compétences observées » — **pas une note** : une
/// compétence non observée n'est pas une compétence ratée. Le dénominateur
/// vient du serveur.
String planTaskObservedLabel(PlanDomainTask task) =>
    'Tâche ${task.tacheNumero} · ${task.observedSkills} / ${task.totalSkills} '
    'compétences observées';

/// Le titre d'une tâche d'expression : son **titre éditorial** quand son code
/// le désigne (miroir [SkillTaskCode], gelé côté backend), « Tâche N » sinon.
///
/// ⚠️ On ne devine jamais une tâche : un code inattendu retombe sur son numéro,
/// et le numéro reste par ailleurs lisible dans [planTaskObservedLabel].
String planTaskTitle(PlanDomainTask task) =>
    SkillTaskCode.fromSkillCode(task.taskCode)?.title ??
    'Tâche ${task.tacheNumero}';

/// « EE1 · Expression écrite » — le repère factuel sous le titre d'une
/// compétence. Le code peut manquer : on n'affiche alors que le domaine.
String planSkillMeta(String skillCode, SkillSection section) =>
    skillCode.isEmpty ? section.label : '$skillCode · ${section.label}';

/// Le palier travaillé par une compétence de **compréhension**, retrouvé dans
/// les domaines **servis** — jamais dérivé de son code. `null` en expression, ou
/// quand la compétence n'est pas dans les paliers publiés.
///
/// ⚠️ Miroir mot pour mot du web (`planSkillLevel`, `lib/plan-domain.ts`).
TargetLevel? planSkillLevel(LearningPlan plan, String skillId) {
  for (final domain in plan.domaines) {
    for (final palier in domain.paliers) {
      if (palier.skillId == skillId) return palier.niveau;
    }
  }
  return null;
}

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
/// L'en-tête de la carte quand le Plan n'a rien à proposer aujourd'hui.
const String kPlanSeanceNothingToDo =
    'Aucun entraînement à faire pour l\'instant';
const String kPlanSeanceRestart = 'Refaire ma séance';
const String kPlanSeanceStart = 'Commencer ma séance';

/// La phrase de tête du « pourquoi » : ce que la séance **est**, et ce qu'elle
/// n'est pas. Aucune date n'intervient nulle part — une compétence entrée dans
/// la séance y reste tant qu'elle n'est pas réussie.
///
/// ⚠️ Miroir mot pour mot du web (`PLAN_SEANCE_META_HINT`).
const String kPlanSeanceMetaHint =
    'Votre séance reprend, dans l\'ordre, les actions que votre plan a déjà '
    'désignées : rien n\'est tiré au hasard, et rien ne disparaît d\'un jour à '
    'l\'autre.';

/// Pourquoi une **mesure** passe devant tout le reste.
const String kPlanSeanceAssessmentLine =
    'Une de vos productions n\'a pas pu être analysée : votre séance commence '
    'par la mesurer, sinon tout ce qui suit avance à l\'aveugle.';

/// Pourquoi une compétence **jamais travaillée** figure dans la séance.
///
/// 🛑 Aucun mot de manque, aucun reproche : rien n'a été observé sur elle, donc
/// rien n'a échoué. Miroir mot pour mot du web.
const String kPlanSeanceAcquisitionLine =
    'Certaines lignes portent des compétences que vous n\'avez encore jamais '
    'travaillées : il n\'y a rien à y réparer, elles font partie du palier que '
    'votre plan construit.';

/// « 3 entraînements · environ 24 min ». Le total est **recalculé serveur**, on
/// l'affiche tel quel.
String planSeanceMeta(PlanSeance seance) {
  final count = seance.items.length;
  return '$count entraînement${count > 1 ? 's' : ''} · environ '
      '${seance.estimatedMinutes} min';
}

/// Ce qu'est un item de la séance, en une formule. C'est la **nature** de
/// l'action, jamais un jugement sur le candidat.
///
/// Une **mesure de domaine** n'est pas un entraînement : elle annonce le
/// parcours qu'elle ouvre (`planAssessmentNature`), pas un exercice.
String planItemKindLabel(PlanSeanceItem item) {
  final assessment = item.assessment;
  if (assessment != null) return planAssessmentNature(assessment);
  return switch (item.kind) {
    PlanExerciseKind.microTraining => 'Petit sujet ciblé',
    PlanExerciseKind.reassessment => 'Vérification en situation',
    PlanExerciseKind.targetedQcmSeries => planSeriesLabel(
        item.exercise?.questionCount,
      ),
    // Deux jalons, deux périmètres : une épreuve (3 tâches) n'est pas un TCF
    // complet (4 épreuves). Miroir mot pour mot du web (`planItemNature`).
    PlanExerciseKind.epreuveMockExam => 'Examen blanc d\'épreuve',
    PlanExerciseKind.fullTcfMockExam => 'Examen blanc TCF complet',
    // Une ligne sans exercice ni mesure n'existe pas (elle est écartée au
    // parsing) : ce repli n'est là que pour garder le `switch` total.
    null => item.nature.label,
  };
}

/// **Le titre d'une ligne de séance**, quelle que soit sa nature — déclaré une
/// seule fois parce que la carte « Aujourd'hui » et la feuille « Pourquoi cette
/// séance ? » affichent la **même** ligne. Deux copies auraient fini par
/// nommer deux choses différentes.
///
/// Une compétence porte son titre ; un **jalon** n'en a pas et prend celui de
/// son examen ; une **mesure de domaine** prend celui de l'épreuve qu'elle vient
/// observer.
String planItemTitle(PlanSeanceItem item) {
  final title = item.title;
  if (title != null && title.isNotEmpty) return title;
  final assessment = item.assessment;
  if (assessment != null) return planAssessmentTitle(assessment.epreuve);
  return item.milestone?.displayTitle ?? kPlanItemFallbackTitle;
}

const String kPlanItemFallbackTitle = 'Entraînement';

/// « Compléter mon évaluation d'expression orale » — ce que le candidat vient
/// **mesurer**, jamais un exercice de plus. Le domaine vient du serveur ; la
/// phrase est d'ici, comme toutes celles de la séance.
String planAssessmentTitle(EpreuveType epreuve) => switch (epreuve) {
      EpreuveType.tcfEe => 'Compléter mon évaluation d\'expression écrite',
      EpreuveType.tcfEo => 'Compléter mon évaluation d\'expression orale',
      EpreuveType.tcfCo => 'Compléter mon évaluation de compréhension orale',
      EpreuveType.tcfCe => 'Compléter mon évaluation de compréhension écrite',
      _ => 'Compléter mon évaluation',
    };

/// La ligne qui explique une carte **à acquérir**, là où une fragilité aurait
/// eu l'explication servie par le correcteur.
///
/// 🛑 Elle ne dit **jamais** qu'il y a un manque à réparer : rien n'a été
/// observé, donc rien n'a échoué. Miroir mot pour mot du web.
const String kPlanAcquisitionNote =
    'Nouvelle compétence de votre palier : vous ne l\'avez encore jamais '
    'travaillée.';

/// Ce que le Plan demande d'une compétence **assez travaillée en ciblé** : il
/// reste à le prouver en situation. Miroir mot pour mot du web
/// (`PLAN_REASON_A_VERIFIER`).
const String kPlanVerificationNote =
    'Assez travaillée en exercice ciblé : il reste à le prouver sur une vraie '
    'tâche, en situation.';

/// **Pourquoi cette compétence est en tête**, en deux lignes de faits servis.
///
/// 1. ce que le correcteur a observé (`explanation`), ou — sur une compétence
///    jamais travaillée — **ce qu'elle est** ;
/// 2. l'état agrégé et l'avancement de l'**étape** (les 5 sujets).
///
/// 🛑 **La nature passe avant les compteurs** : sur une compétence à acquérir,
/// « 0 sujet sur 5 traité » se lirait comme un retard alors qu'il n'y avait rien
/// à traiter.
///
/// ⚠️ **Miroir mot pour mot du web** (`priorityLines`, `LearningPlanView.tsx`).
/// Le mobile n'affichait que la ligne 1, le web que la ligne 2 : la même carte
/// racontait deux histoires selon l'appareil.
List<String> planPriorityLines(LearningPlanPriority priority) {
  final lines = <String>[];
  if (priority.nature == PlanActionNature.aAcquerir) {
    lines.add(kPlanAcquisitionNote);
  } else if (priority.explanation != null &&
      priority.explanation!.trim().isNotEmpty) {
    lines.add(priority.explanation!);
  } else if (priority.readyForReassessment) {
    lines.add(kPlanVerificationNote);
  }

  final state = priority.masteryState?.label;
  if (priority.stepPromptCount > 0) {
    final done = priority.stepAttemptedCount;
    final total = priority.stepPromptCount;
    final compteur = '$done sujet${done > 1 ? 's' : ''} sur $total '
        'traité${done > 1 ? 's' : ''} dans cette étape';
    lines.add(state == null ? '$compteur.' : '$state · $compteur.');
  } else if (lines.isEmpty || state != null) {
    lines.add(
      state == null
          ? 'C\'est cette compétence qui fait le plus avancer votre palier.'
          : '$state · c\'est cette compétence qui fait le plus avancer votre '
              'palier.',
    );
  }
  return lines;
}

/// « Série de 20 questions » — la taille est **décidée serveur**. Sans elle, on
/// ne l'invente pas.
String planSeriesLabel(int? questionCount) => questionCount == null
    ? 'Série ciblée de compréhension'
    : 'Série ciblée de $questionCount questions';

/// Le repère de ligne d'un item : « CO · B1 », « EE ».
///
/// Un **jalon** n'a ni section ni palier travaillé (il les vérifie tous) : son
/// repère vient de son épreuve. On lit [PlanSeanceItem.kind], jamais la nullité
/// d'un champ.
String planItemEyebrow(PlanSeanceItem item) {
  final milestone = item.milestone;
  if (milestone != null) return planDomainShort(milestone.epreuve);
  final assessment = item.assessment;
  if (assessment != null) return planDomainShort(assessment.epreuve);
  final section = item.section?.wire ?? '—';
  final level = item.level;
  return level == null ? section : '$section · $level';
}

/// **Pourquoi CETTE ligne est là** — des faits servis, jamais un jugement.
///
/// 🛑 **L'ordre des branches est celui des trois natures**, pas celui des
/// champs : une compétence *à acquérir* se dit « rien n'a été constaté ici »,
/// jamais un compteur d'étape à zéro qui se lirait comme un retard.
///
/// ⚠️ **Miroir mot pour mot du web** (`planItemReason`). La feuille « Pourquoi
/// cette séance ? » du mobile ne portait que la nature et le domaine, là où le
/// web expliquait chaque ligne.
String planItemReason(PlanSeanceItem item) {
  if (item.nature == PlanActionNature.aEvaluer) {
    return kPlanSeanceAssessmentLine;
  }
  if (item.nature == PlanActionNature.aAcquerir) return kPlanAcquisitionNote;
  if (item.kind == PlanExerciseKind.epreuveMockExam ||
      item.kind == PlanExerciseKind.fullTcfMockExam) {
    return kPlanMilestoneSectionText;
  }
  if (item.readyForReassessment) return kPlanVerificationNote;

  final state = item.masteryState?.label;
  if (item.stepPromptCount > 0) {
    final done = item.stepAttemptedCount;
    final compteur = '$done sujet${done > 1 ? 's' : ''} sur '
        '${item.stepPromptCount} traité${done > 1 ? 's' : ''}';
    return state == null ? compteur : '$state · $compteur';
  }
  final level = item.level;
  final palier = level == null
      ? (item.section == null
          ? kPlanItemFallbackTitle
          : item.section!.label)
      : 'Palier $level';
  return state == null ? palier : '$palier · $state';
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

  lines.add(kPlanSeanceMetaHint);

  // 🛑 La priorité n°1 n'est nommée que si elle est **accessible**. Le serveur
  // ouvre normalement la première place quelle que soit sa nature, mais il
  // reste des cas où la carte n°1 est verrouillée — et l'écrire en clair ici
  // démentirait le rideau posé deux blocs plus haut.
  final priority = plan.currentPriority;
  if (priority != null && !priority.locked) {
    lines.add(
      'Votre priorité n°1 est « ${priority.title} » : c\'est elle qui ouvre '
      'votre séance, parce que c\'est elle qui vous fera progresser le plus '
      'vite.',
    );
  }

  // Une mesure ouvre la séance : tant qu'un domaine travaillé n'a pas pu être
  // observé, les exercices qui suivent avancent à l'aveugle.
  if (seance.items.any((i) => i.nature == PlanActionNature.aEvaluer)) {
    lines.add(kPlanSeanceAssessmentLine);
  }

  // 🛑 « À acquérir » ne se dit jamais « à renforcer » : on le redit ici, là où
  // le candidat demande précisément pourquoi cette ligne est là.
  if (seance.items.any((i) => i.nature == PlanActionNature.aAcquerir)) {
    lines.add(kPlanSeanceAcquisitionLine);
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

/* ------------------------------------------- les encarts « épreuve → tâche » */

/// **La pastille d'un encart de tâche** : « Tâche 2 ». Le titre de la tâche,
/// lui, vit dans [SkillTaskCode.title] — miroir du backend, jamais réécrit ici.
String planTaskBadgeLabel(SkillTaskCode task) => 'Tâche ${task.tacheNumero}';

/// Le repère d'un encart **sans tâche** : la compréhension travaille un palier,
/// une mesure ouvre un parcours, un jalon est un jalon. `null` quand aucun de
/// ces trois faits n'est servi — on n'invente alors aucun repère.
String? planGroupContextLabel({
  String? level,
  PlanDomainAssessment? assessment,
  PlanMilestone? milestone,
}) {
  if (level != null && level.isNotEmpty) return 'Niveau $level';
  if (assessment != null) return planAssessmentNature(assessment);
  if (milestone != null) return kPlanMilestonePill;
  return null;
}

/// Le résumé d'un encart de **séance**, fermé : « Raconter une expérience ·
/// 2 entraînements · 12 min ». Le titre de tâche saute quand il n'y en a pas.
String planSeanceGroupSummary({
  String? taskTitle,
  required int count,
  required int minutes,
}) {
  final parts = <String>[
    if (taskTitle != null && taskTitle.isNotEmpty) taskTitle,
    '$count entraînement${count > 1 ? 's' : ''}',
    if (minutes > 0) '$minutes min',
  ];
  return parts.join(' · ');
}

/// Le résumé d'un encart de **priorités**, fermé : « Raconter une expérience ·
/// 1 priorité · 2 à renforcer ».
String planPrioritiesGroupSummary({
  String? taskTitle,
  required String statuses,
}) {
  final parts = <String>[
    if (taskTitle != null && taskTitle.isNotEmpty) taskTitle,
    if (statuses.isNotEmpty) statuses,
  ];
  return parts.join(' · ');
}

/// **Le statut d'une ligne de priorité**, tel qu'il s'affiche.
///
/// 🛑 **Rien de neuf n'est jugé ici.** C'est une **vue** de deux faits déjà
/// servis — la nature de l'action ([PlanActionNature]) et l'état agrégé de la
/// compétence ([SkillMasteryState]) — assemblés pour que l'encart fermé puisse
/// dire « 1 priorité · 2 à renforcer » d'un seul coup d'œil. Aucun libellé
/// n'est écrit ici : ils sont **repris** des deux enums, gelés côté serveur.
///
/// **L'ordre de déclaration EST l'ordre du résumé** : ce qui bloque d'abord, ce
/// qui se répare, ce qui s'apprend, ce qui se prouve, ce qui tient, ce qui
/// manque encore d'être mesuré.
enum PlanRowStatus {
  priorite,
  aRenforcer,
  aAcquerir,
  aVerifier,
  solide,
  aEvaluer;

  /// Le libellé de la pastille. **Emprunté**, jamais recopié : « Priorité » et
  /// « Solide » viennent de [SkillMasteryState], les quatre autres de
  /// [PlanActionNature]. Un libellé qui bouge côté serveur bouge ici sans que
  /// personne y touche.
  String get label => switch (this) {
        PlanRowStatus.priorite => SkillMasteryState.priority.label,
        PlanRowStatus.aRenforcer => PlanActionNature.aRenforcer.label,
        PlanRowStatus.aAcquerir => PlanActionNature.aAcquerir.label,
        PlanRowStatus.aVerifier => PlanActionNature.aVerifier.label,
        PlanRowStatus.solide => SkillMasteryState.solid.label,
        PlanRowStatus.aEvaluer => PlanActionNature.aEvaluer.label,
      };

  /// La forme **au singulier** dans le résumé d'un encart (« 1 priorité »).
  String get countedSingular => switch (this) {
        PlanRowStatus.priorite => 'priorité',
        PlanRowStatus.solide => 'solide',
        _ => label.toLowerCase(),
      };

  /// La forme **au pluriel** (« 2 priorités »). Les quatre natures s'écrivent
  /// déjà avec « à » : elles ne varient pas.
  String get countedPlural => switch (this) {
        PlanRowStatus.priorite => 'priorités',
        PlanRowStatus.solide => 'solides',
        _ => label.toLowerCase(),
      };

  /// Une compétence **solide** n'appelle plus d'action : c'est elle qu'on
  /// écarte quand l'encart cherche quoi proposer.
  bool get isActionable => this != PlanRowStatus.solide;
}

/// Le libellé complet d'une pastille de statut. « À acquérir » y **ajoute son
/// palier cible** — c'est le seul statut qui désigne un palier à venir plutôt
/// qu'un constat, et sans lui le candidat ne sait pas ce qu'il apprend. Sans
/// palier servi, on ne le nomme pas.
String planRowStatusLabel(PlanRowStatus status, TargetLevel? level) =>
    status == PlanRowStatus.aAcquerir && level != null
        ? '${status.label} · ${level.wire}'
        : status.label;

/// « 1 priorité · 2 à renforcer ». **Ordre figé** par l'ordre de déclaration de
/// [PlanRowStatus] ; un statut absent ne s'écrit pas.
String planStatusSummary(Iterable<PlanRowStatus> statuses) {
  final parts = <String>[];
  for (final status in PlanRowStatus.values) {
    final n = statuses.where((s) => s == status).length;
    if (n == 0) continue;
    parts.add('$n ${n > 1 ? status.countedPlural : status.countedSingular}');
  }
  return parts.join(' · ');
}

/// L'en-tête de la carte « Aujourd'hui » pour un compte **abonné** :
/// « 2 épreuves · 3 entraînements · environ 24 min ».
String planSeanceHeaderMeta({
  required int epreuves,
  required int items,
  required int minutes,
}) =>
    '$epreuves épreuve${epreuves > 1 ? 's' : ''} · $items '
    'entraînement${items > 1 ? 's' : ''} · environ $minutes min';

/// Le même en-tête pour un compte **sans accès** : ce qui est réellement
/// ouvert, sur le total.
///
/// 🛑 **Le nombre d'entraînements gratuits est COMPTÉ sur les `locked` servis**,
/// jamais posé à 1 par principe : c'est le serveur qui décide de ce qu'il
/// ouvre, et écrire « 1 » en dur mentirait le jour où il en ouvre deux.
String planSeanceFreeHeaderMeta({
  required int free,
  required int items,
  required int minutes,
}) =>
    '$free entraînement${free > 1 ? 's' : ''} gratuit${free > 1 ? 's' : ''} '
    'sur $items · environ $minutes min';

/// L'affordance de fin de ligne d'un entraînement à faire.
const String kPlanSeanceRowStart = 'Commencer';

/// Le sous-titre d'une ligne de séance : sa nature et sa durée.
String planSeanceRowSub(PlanSeanceItem item, int minutes) {
  final kind = planItemKindLabel(item);
  return minutes > 0 ? '$kind · $minutes min' : kind;
}

/// Le sous-titre d'une ligne de priorité **à acquérir** : le palier auquel elle
/// appartient. Sans palier servi, on ne le nomme pas.
String planAcquisitionRowSub(TargetLevel? level) => level == null
    ? 'Nouvelle compétence de votre palier'
    : 'Nouvelle compétence du palier ${level.wire}';

/// Le sous-titre d'une ligne de priorité d'**expression** : l'avancement de son
/// étape. Sans périmètre servi, on n'invente aucun dénominateur.
String planPromptCountSub(int done, int total) => total > 0
    ? '$done / $total petits sujets'
    : 'Petits sujets ciblés';

/// Le sous-titre d'une ligne **seulement observée** : d'où vient sa mesure.
///
/// 🛑 Aucun compteur d'étape n'est servi sur ces lignes — elles ne sont pas des
/// priorités. Y écrire « 0 / 5 petits sujets » se lirait comme un retard, alors
/// que la compétence a justement été mesurée.
const String kPlanObservedRowSub = 'Observée dans vos productions';

/// « + 3 autres compétences » — le reste d'un encart, **compté pour de vrai**
/// sur ce que le groupe contient. Jamais une constante recopiée d'une maquette.
String planGroupMoreLabel(int count) =>
    '+ $count autre${count > 1 ? 's' : ''} '
    'compétence${count > 1 ? 's' : ''}';

/// Le bouton de bas d'encart : ce qu'il propose de faire sur la **première
/// ligne qui appelle une action**.
const String kPlanGroupWorkCta = 'Travailler cette compétence';
const String kPlanGroupDiscoverCta = 'Découvrir cette compétence';
const String kPlanGroupUnlockCta = 'Débloquer cette compétence';

/// Ce que dit le bouton d'un encart de priorités.
String planGroupCta({
  required bool locked,
  required bool comprehension,
  required bool acquisition,
}) {
  if (locked) return kPlanGroupUnlockCta;
  if (comprehension) return kPlanSeriesCta;
  return acquisition ? kPlanGroupDiscoverCta : kPlanGroupWorkCta;
}

/* ------------------------------------------- ma progression (écran) ------- */

/// Le titre de l'écran de progression du Plan.
///
/// 🛑 **L'objectif est NULLABLE et on n'invente jamais « B2 »** : sans démarche
/// déclarée, l'écran s'appelle « Ma progression », sans palier. La maquette,
/// elle, l'écrit en dur — la suivre retirerait son A2 à un dossier CSP.
String planProgressTitle(TargetLevel? objective) => objective == null
    ? 'Ma progression'
    : 'Ma progression vers le ${objective.wire}';

const String kPlanProgressSub = 'Domaine par domaine, niveau par niveau';
const String kPlanProgressLevelLabel = 'NIVEAU ESTIMÉ';
const String kPlanProgressObjectiveLabel = 'OBJECTIF';

/// Ce qui s'affiche à la place du niveau global tant que rien n'est mesuré.
/// *null = inconnu, jamais mauvais* : on n'écrit pas « A1 » par défaut.
const String kPlanProgressNoLevel = '—';

/// La ligne sous le nom d'un domaine sur cet écran : son niveau estimé et, en
/// compréhension, le palier qu'il travaille. Uniquement des faits servis.
String planDomainProgressSubtitle(PlanDomain domain) {
  if (!domain.evaluated || domain.niveau == null) {
    return kPlanDomainNotEvaluatedShort;
  }
  final blocking = domain.blockingLevel;
  final niveau = 'Niveau estimé ${domain.niveau!.displayName}';
  return blocking == null ? niveau : '$niveau · travaille le ${blocking.wire}';
}

/// 🛑 **Aucun pourcentage nulle part sur cet écran.** La maquette affiche une
/// barre de maîtrise par palier ; le score interne du moteur n'est exposé à
/// aucun front, et cette note remplace donc celle qui l'expliquait.
const String kPlanProgressNote =
    'Chaque domaine avance à son rythme : un palier se construit compétence par '
    'compétence, et rien n\'est déduit d\'un domaine que vous n\'avez pas encore '
    'mesuré.';

const String kPlanProgressLevelsTitle = 'Vos paliers';
const String kPlanProgressTasksTitle = 'Vos tâches';

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

/// **Comment un palier se confirme.** C'est le cœur du parcours : on ne change
/// pas de niveau parce qu'on a fini des exercices, mais parce qu'un **examen
/// blanc complet** l'a confirmé en conditions réelles.
///
/// 🛑 **Rien n'est déduit ici** : la phrase ne s'affiche que sur une étape de
/// palier (`BUILD_LEVEL`) **pas encore terminée**, et sa variante « maintenant »
/// se lit sur l'état servi ([PlanCycleState.readyForGateMock]) — jamais sur un
/// calcul du front. Une étape déjà franchie ne dit rien : le serveur ne publie
/// pas *comment* elle l'a été, et l'inventer serait faux.
String? planPathStepNote(PlanPathStep step, PlanCycle cycle) {
  if (step.kind != PlanPathStepKind.buildLevel) return null;
  if (step.status == PlanPathStepStatus.done) return null;
  if (step.status == PlanPathStepStatus.current &&
      cycle.state == PlanCycleState.readyForGateMock) {
    return kPlanGateReady;
  }
  return kPlanGateRule;
}

const String kPlanGateRule =
    'Ce palier se confirme par un examen blanc complet.';
const String kPlanGateReady =
    'Vous y êtes : un examen blanc complet peut maintenant confirmer ce '
    'palier.';

/// La ligne de contexte sous l'en-tête : **d'où l'on part, ce que le cycle
/// construit**. Composée de faits servis, sans aucun chiffre écrit ici.
///
/// ⚠️ **Miroir mot pour mot du web** (`planCycleLine`, `lib/plan-domain.ts`).
/// Elle lit `cycle.startingLevel` — le plancher des domaines mesurés, servi
/// avec le Plan — et non plus le niveau estimé du tableau de bord : c'est la
/// **même** valeur (`TcfProfileService`), servie par le même appel, et deux
/// sources pour un même chiffre finissent toujours par se contredire.
String planCycleLine(PlanCycle? cycle) {
  if (cycle == null) return 'Votre plan suit vos derniers résultats.';
  final from = cycle.startingLevel?.displayName;
  if (from == null) {
    return 'Votre plan construit d\'abord votre ${cycle.targetLevel.wire}.';
  }
  return 'Niveau estimé $from · votre plan construit d\'abord votre '
      '${cycle.targetLevel.wire}.';
}

/// Ce qu'annonce l'**état du cycle**, en une phrase. Les quatre états sont
/// servis par le serveur et se disent au candidat, pas en jargon.
///
/// ⚠️ **Miroir mot pour mot du web** (`PLAN_CYCLE_STATE_TEXT`). Le mobile ne
/// disait nulle part dans quelle phase le candidat se trouve — c'est pourtant
/// ce qui explique pourquoi le Plan lui demande de **mesurer** plutôt que de
/// s'entraîner.
String planCycleStateText(PlanCycleState state) => switch (state) {
      PlanCycleState.buildingBaseline =>
        'Il manque des mesures : complétez votre profil pour que le plan cible '
            'les bons paliers.',
      PlanCycleState.training =>
        'Votre entraînement cible les compétences qui bloquent le palier en '
            'cours.',
      PlanCycleState.readyForGateMock =>
        'Le travail de ce palier est fait : il reste à le confirmer par un '
            'examen blanc TCF complet.',
      PlanCycleState.targetStabilization =>
        'Votre objectif est atteint sur les domaines mesurés : on entretient '
            'et on remesure.',
    };

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

/// 🛑 **La section « Mes compétences observées » n'existe plus** : ses cartes
/// répétaient, dans un autre ordre et plus bas dans la page, les compétences
/// déjà nommées ici. Chaque encart porte désormais **toutes** les compétences
/// de sa tâche — priorités en tête, acquis compris — et son résumé les compte
/// (« 1 priorité · 2 à renforcer · 3 solides »). Ne pas recréer un second bloc.
const String kPlanPrioritiesText =
    'Chaque tâche, avec ce qu\'il reste à y travailler et ce qui est déjà '
    'acquis.';

/// ⚠️ **Divergence VOULUE avec le web, arbitrée le 2026-08-21 : ne pas
/// « aligner ».** L'action s'appelle « Tout voir » ici et « Toutes mes
/// compétences » côté web (`plan.ts`). Ce n'est pas une copie qui a dérivé : les
/// deux maquettes diffèrent réellement, et la place à l'écran n'est pas la même
/// — un lien de fin de section sur une largeur de téléphone n'encaisse pas la
/// forme longue sans se tronquer ou pousser le compteur hors du bandeau.
///
/// Ce qui **doit** rester identique des deux côtés, et l'est : le titre de la
/// page d'arrivée ([kPlanAllSkillsTitle] = « Toutes mes compétences »). Le
/// contrat, c'est la destination ; ceci n'est qu'un libellé d'action.
const String kPlanPrioritiesAll = 'Tout voir';

/* ------------------------------------------- toutes mes compétences (page) */

const String kPlanAllSkillsTitle = 'Toutes mes compétences';
const String kPlanAllSkillsSub = 'Expression et compréhension';
const String kPlanComprehensionTitle = 'Compréhension';
const String kPlanAllSkillsEmpty =
    'Votre plan ne suit encore aucun domaine : il se remplit à votre premier '
    'résultat.';

/// **Le parcours réel** qu'ouvre une mesure, nommé tel quel — une *description*,
/// jamais un geste. Aucun contenu n'est créé : chacune de ces trois natures
/// existe déjà.
///
/// ⚠️ **Miroir mot pour mot du web** (`planAssessmentNature`). Le mobile ne
/// connaissait qu'une seule chaîne, employée à la fois comme repère de ligne et
/// comme libellé de bouton : « Rendre une production » se lisait donc dans une
/// meta, là où le web décrivait « Production complète ».
String planAssessmentNature(PlanDomainAssessment assessment) =>
    switch (assessment.kind) {
      PlanDomainAssessmentKind.diagnostic => 'Diagnostic',
      PlanDomainAssessmentKind.moduleMockExam => assessment.slotNumber == null
          ? 'Examen blanc'
          : 'Examen blanc n°${assessment.slotNumber}',
      PlanDomainAssessmentKind.production => 'Production complète',
    };

/// **Le geste** qui mesure ce domaine — le libellé d'un bouton, jamais d'une
/// meta. Miroir mot pour mot du web (`planAssessmentCta`).
String planAssessmentCta(PlanDomainAssessment assessment) =>
    switch (assessment.kind) {
      PlanDomainAssessmentKind.diagnostic => 'Faire mon diagnostic',
      PlanDomainAssessmentKind.production => 'Faire une production',
      PlanDomainAssessmentKind.moduleMockExam => 'Passer l\'examen blanc',
    };

/// Le repère factuel d'une ligne de mesure : sa nature et sa durée quand elle en
/// a une (ni le diagnostic ni une production ne sont chronométrés par épreuve —
/// on n'écrit alors aucune minute plutôt qu'un chiffre inventé).
String planAssessmentMeta(PlanDomainAssessment assessment) {
  final minutes = assessment.estimatedMinutes;
  final nature = planAssessmentNature(assessment);
  return minutes == null ? nature : '$nature · ≈ $minutes min';
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
const String kPlanSeriePending =
    'Votre maîtrise se met à jour dès que ce résultat est pris en compte : '
    'elle apparaîtra sur votre plan.';
const String kPlanSerieNote =
    'Une série ciblée entraîne une compétence ; elle ne mesure pas le domaine. '
    'Seul un examen blanc de l\'épreuve le fait.';

/* ------------------------------------------------------- la carte d'offre   */

/// Le titre de la carte d'offre du Plan (`CPaywallCard` de la maquette).
const String kPlanPaywallTitle = 'Débloquez votre plan complet';

/// Le lien discret sous le bouton. Sur mobile il ouvre **le même** écran que le
/// bouton — l'app n'a qu'une porte d'abonnement (`showTcfLockPaywall`), qui est
/// précisément la grille des passes. Deux affordances, une seule destination :
/// c'est ce que fait la maquette, et on n'ouvre surtout pas un second chemin
/// d'achat.
const String kPlanPaywallFormulas = 'Voir les formules';

/// Ce que l'abonnement ouvre, dans l'ordre de la maquette.
///
/// ⚠️ **Vouvoiement**, comme tout le Plan — et **distincts** des cinq arguments
/// du rapport de diagnostic, qui décrivent ce que ce rapport vient de laisser
/// entrevoir. Deux listes, deux moments ; ne pas les confondre ni les fondre.
/// Miroirs mot pour mot du web.
const List<String> kPlanPaywallBenefits = <String>[
  'Toute votre séance du jour, chaque jour',
  'Vos priorités et vos petits sujets ciblés',
  'La correction IA et la version au niveau supérieur',
  'Votre plan qui évolue automatiquement',
  'Le moment où vous êtes prêt pour un examen blanc',
];
