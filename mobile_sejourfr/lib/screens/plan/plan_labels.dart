
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

/// Le palier que le référentiel porte sur une compétence.
///
/// Lu sur `domaines[].skills[]` — la liste **uniforme** des quatre domaines —,
/// avec repli sur les paliers de compréhension. `null` quand rien ne le
/// publie : *null = inconnu, jamais mauvais*, et aucun palier n'est fabriqué.
///
/// 🛑 **Jamais de repli sur `cycle.targetLevel`.** C'est le palier GLOBAL, et
/// depuis que chaque domaine construit le sien (2026-08-26) il affiche un
/// palier faux dès que deux domaines divergent.
///
/// ⚠️ Miroir mot pour mot du web (`planSkillTargetLevel`, `lib/plan-domain.ts`).
TargetLevel? planSkillTargetLevel(LearningPlan plan, String skillId) {
  for (final domain in plan.domaines) {
    for (final competence in domain.skills) {
      if (competence.skillId == skillId) return competence.targetLevel;
    }
  }
  return planSkillLevel(plan, skillId);
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

/* ------------------------------------------------------- l'action du jour   */

const String kPlanSeanceEmpty =
    'Rien à faire pour le moment : votre prochaine étape se décide à votre '
    'prochaine production.';

/// **Ce qu'est une action du Plan**, en une formule — déclarée ici parce que
/// deux surfaces la demandent : une ligne de séance et la carte « À faire
/// maintenant », qui ne porte pas de `PlanSeanceItem`. `null` quand la nature
/// de l'exercice n'est pas connue : l'appelant dit alors autre chose plutôt
/// qu'un libellé deviné.
String? planExerciseKindLabel(PlanExerciseKind? kind, {int? questionCount}) =>
    switch (kind) {
      PlanExerciseKind.microTraining => 'Petit sujet ciblé',
      PlanExerciseKind.reassessment => 'Vérification en situation',
      PlanExerciseKind.targetedQcmSeries => planSeriesLabel(questionCount),
      // Deux jalons, deux périmètres : une épreuve (3 tâches) n'est pas un TCF
      // complet (4 épreuves). Miroir mot pour mot du web (`planItemNature`).
      PlanExerciseKind.epreuveMockExam => 'Examen blanc d\'épreuve',
      PlanExerciseKind.fullTcfMockExam => 'Examen blanc TCF complet',
      null => null,
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

/* ------------------------------------------- les encarts « épreuve → tâche » */

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

/// « + 3 autres compétences » — le reste d'un encart, **compté pour de vrai**
/// sur ce que le groupe contient. Jamais une constante recopiée d'une maquette.
String planGroupMoreLabel(int count) =>
    '+ $count autre${count > 1 ? 's' : ''} '
    'compétence${count > 1 ? 's' : ''}';

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

const String kPlanCompleteProfileTitle = 'Compléter mon profil';
const String kPlanCompleteProfileText =
    'Votre diagnostic portait sur une production écrite et une production '
    'orale. Les domaines ci-dessous n\'ont encore jamais été mesurés — voici '
    'par quoi les mesurer.';
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
/// « Priorité → En consolidation ». `before == null` veut dire « jamais
/// observée » : on le dit, on n'invente pas d'état de départ.
String planTransitionLabel(PlanMasteryTransition transition) {
  final before = transition.before?.label ?? 'Jamais observée';
  return '$before → ${transition.after.label}';
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

/* --------------------------------------------- l'écran « Mon plan » (kit)   */

/// Le kicker de l'en-tête d'un compte **abonné**. L'objectif est nullable et le
/// reste : sans démarche déclarée, la phrase ne nomme aucun palier plutôt que
/// d'en inventer un.
String planTopKicker(TargetLevel? objective) => objective == null
    ? 'Votre parcours personnalisé'
    : 'Votre parcours personnalisé vers le ${objective.wire}';

/// Le kicker d'un compte **sans accès** : son plan vient de son diagnostic.
const String kPlanTopKickerFree = 'Créé à partir de votre diagnostic';

const String kPlanTitle = 'Mon plan';

/// Le titre d'un compte sans accès nomme le palier visé quand il est connu.
String planTitleFree(TargetLevel? objective) =>
    objective == null ? kPlanTitle : '$kPlanTitle ${objective.wire}';

/// Ce que fait le moteur, sous le bandeau d'objectif. Miroir mot pour mot de la
/// maquette.
const String kPlanEngineLine =
    'Le plan choisit la prochaine action selon vos priorités, puis réévalue '
    'après chaque séance.';

/// Le palier de repli du bandeau d'objectif. *null = inconnu, jamais mauvais* :
/// on n'écrit ni A1 ni B2 par défaut.
const String kPlanGoalUnknown = '—';

const String kPlanGoalPick = 'Choisir mon objectif';

const String kPlanNowTitle = 'À faire maintenant';
const String kPlanNowStartCta = 'Commencer';
const String kPlanNowValidateCta = 'Commencer la validation';
const String kPlanNowLockedCta = 'Débloquer cet entraînement';

/// Le libellé de l'encart bleu de la carte d'action. Une **vérification** ne se
/// présente pas comme un exercice de plus : elle dit ce qu'elle est.
String planNowObjectiveLabel(PlanRecommendedExercise? exercise) =>
    exercise?.kind == PlanExerciseKind.reassessment
        ? 'Vérification en situation'
        : 'Compétence actuelle';

/// Le repère « Tâche 3 · Donner son opinion » sous le domaine. `null` en
/// compréhension, où il n'y a pas de tâche — le palier prend sa place.
String planNowSubtitle({SkillTaskCode? task, TargetLevel? level}) {
  if (task != null) return 'Tâche ${task.tacheNumero} · ${task.title}';
  return level == null ? '' : 'Niveau ${level.wire}';
}

const String kPlanNowEmptyTitle = 'Rien à faire pour le moment';

/// Le titre de la section « parcours », qui nomme la tâche travaillée.
String planPathSectionTitle(SkillTaskCode task) =>
    'Votre parcours — Tâche ${task.tacheNumero}';

/// « Étape 3 / 8 » — **lu** sur `domaines[].taches[]`, jamais compté ici.
String planPathCounter(PlanDomainTask task) =>
    'Étape ${task.observedSkills} / ${task.totalSkills}';

/// Le titre de la section des priorités. Il nomme l'objectif quand il est
/// connu, et se tait sinon.
String planPrioritiesSectionTitle(TargetLevel? objective) => objective == null
    ? 'Vos priorités'
    : 'Vos priorités pour atteindre le ${objective.wire}';

/// Le titre d'une carte de priorité : son domaine, et sa tâche quand il y en a
/// une.
String planPriorityGroupTitle({
  required EpreuveType? epreuve,
  SkillTaskCode? task,
  String? context,
}) {
  final domain = epreuve == null ? 'TCF' : planDomainLabel(epreuve);
  if (task != null) return '$domain — Tâche ${task.tacheNumero}';
  return context == null ? domain : '$domain — $context';
}

String planPriorityRankTag(int rank) => 'Priorité $rank';

const String kPlanDoneTitle = 'Déjà travaillé et validé';

/// La ligne cochée d'une étape franchie : la compétence et son repère.
String planDoneRowLabel(LearningPlanCompletedStep step) =>
    '${step.title} — ${planSkillMeta(step.skillCode, step.section)}';

const String kPlanChangesTitle = 'Progression détectée';

/// La phrase sous le titre de l'encart vert : ce que le plan fait ensuite.
/// `null` quand aucune nouvelle priorité n'a été désignée — on n'annonce alors
/// aucune suite.
String? planChangesNext(PlanRecentChanges changes) {
  final next = changes.newPriority;
  return next == null ? null : 'Prochaine action : ${next.title}.';
}

/* ----------------------------------------------- le plan d'un compte libre  */

const String kPlanFreeFirstStepTitle = 'Votre première étape est prête';

/// Ce que l'abonnement ouvre **sur cette étape**, dans l'ordre de la maquette.
const List<String> kPlanFreeStepLocks = <String>[
  'Exercice recommandé',
  'Correction personnalisée',
  'Suivi de cette compétence',
];

const String kPlanFreePathTitle = 'Le parcours de cette tâche';

const String kPlanUnlockHeroTitle = 'Passez du diagnostic à la progression';
const String kPlanUnlockHeroText =
    'Votre diagnostic vous montre quoi améliorer. Avec l\'accès Intégral, '
    'SejourFR vous accompagne étape par étape pour le travailler.';
const List<String> kPlanUnlockHeroChecks = <String>[
  'entraînements choisis selon vos difficultés',
  'corrections et conseils personnalisés',
  'plan adapté à vos progrès',
];

/// Le rappel sous le bouton de déblocage. **Aucun prix** : ils viennent du
/// store, sur l'écran d'offre.
const String kPlanUnlockCaption = 'Accès Intégral · paiement unique';

/* ---------------------------------------------- les accès secondaires ----- */

const String kPlanExamsTitle = 'Mes examens blancs';
const String kPlanExamsSub = 'TCF et civique';
const String kPlanDiagnosticTitle = 'Mon diagnostic';
const String kPlanDiagnosticSub = 'Résultat de départ et priorités initiales';

/* ------------------------------------------- le plan qui n'existe pas encore */

/// Le kicker d'un plan qui n'est pas encore constructible. Il ne promet aucun
/// palier : rien n'a encore été mesuré.
const String kPlanEmptyKicker = 'Votre parcours personnalisé';

const String kPlanNeedsDiagnosticTitle =
    'Votre plan commence par un diagnostic';
const String kPlanNeedsDiagnosticText =
    'Une production écrite et une production orale : c\'est ce qui permet de '
    'savoir quoi travailler en premier.';
const String kPlanNeedsDiagnosticCta = 'Faire mon diagnostic';

const String kPlanDiagnosticRunningTitle = 'Votre diagnostic est en cours';
const String kPlanDiagnosticRunningText =
    'Reprenez là où vous vous êtes arrêté. Vos réponses déjà envoyées sont '
    'conservées sur votre compte.';
const String kPlanDiagnosticRunningCta = 'Reprendre le diagnostic';

const String kPlanErrorTitle = 'Votre plan n\'a pas pu être chargé';
const String kPlanErrorRetry = 'Réessayer';

/// Le titre court du bloc des priorités, pour un compte qui n'a pas encore
/// d'objectif chiffré à l'écran.
const String kPlanPrioritiesShort = 'Vos priorités';
