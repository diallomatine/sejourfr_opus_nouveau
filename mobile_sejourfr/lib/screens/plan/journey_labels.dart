/// **Les phrases du parcours TCF.** Le serveur sert des faits — type, purpose,
/// section, taskCode, skillTitle, progress, locked — et c'est ici qu'ils
/// deviennent du français.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/journey.ts`.** Un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Rien ne se déduit ici d'un compteur ni d'une position.** Chaque fonction
/// pose un libellé sur un **état servi** : `status`, `locked`, `progress.unit`.
/// Un front qui recalculerait l'un d'eux finirait par désigner une autre étape
/// que le serveur.
library;

import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/utils/civique_examen.dart';
import '../../core/utils/format_date.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

/// Le titre de la section de cycle : « Votre parcours vers le B2 », « Votre
/// parcours — Naturalisation ».
///
/// 🛑 **La tournure se choisit sur le [JourneyObjectifKind], jamais sur le
/// module** (D-50). Un palier se dit « vers le B2 » ; une démarche ne se dit pas
/// « vers le Naturalisation ». Le **libellé**, lui, arrive servi — aucun front
/// ne fabrique le mot du candidat. Miroir de `journeyTitle` (`lib/journey.ts`).
String journeyTitle(JourneyObjectifRef? objectif) {
  if (objectif == null) return 'Votre parcours';
  return objectif.kind == JourneyObjectifKind.niveau
      ? 'Votre parcours vers le ${objectif.label}'
      : 'Votre parcours — ${objectif.label}';
}

/// Ce que porte la première ligne d'une étape.
String journeyStepTitle(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Diagnostic rapide';
    case JourneyStepType.sectionExam:
      // 🛑 Servi (D-47) : vaut pour une épreuve TCF comme pour une thématique.
      return step.bloc?.label ?? 'Épreuve';
    case JourneyStepType.trainSkill:
      // 🛑 L'UNITÉ EST SERVIE (D-50) : compétence TCF ou unité officielle
      // civique, même chemin. `skillTitle` reste pour ce qu'il porte d'autre.
      return step.unite?.label ?? step.skillTitle ?? step.skillCode ?? 'À travailler';
  }
}

/// La seconde ligne. 🛑 **Elle dit ce que l'étape est**, jamais ce qu'il faut en
/// penser : « Expression écrite · Tâche 1 », « Vérifier mes progrès ».
String? journeyStepSubtitle(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Identifier vos premières priorités';
    case JourneyStepType.sectionExam:
      return step.purpose == JourneyStepPurpose.reassess
          ? 'Vérifier mes progrès'
          : 'Évaluer mon niveau';
    case JourneyStepType.trainSkill:
      final parts = <String>[
        if (step.section != null) _sectionLabel(step.section!),
        // 🛑 `taskCode` nul = compétence de COMPRÉHENSION : CO/CE n'ont ni tâche
        // ni petit sujet. On ne lui invente pas un « Tâche 1 » qui n'existe pas.
        if (step.taskCode != null) _tacheLabel(step.taskCode!),
      ];
      return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// La pastille de fin de ligne. **Servie au kit**, qui ne compose aucune phrase.
String? journeyBadge(JourneyStep step) {
  if (step.status == JourneyStepStatus.current) return 'Maintenant';
  if (step.status == JourneyStepStatus.skipped) return 'Déjà travaillée';
  if (step.status == JourneyStepStatus.upcoming &&
      step.type == JourneyStepType.sectionExam) {
    return 'Examen';
  }
  return null;
}

/// L'état de rendu, tel que le kit l'attend.
SfJourneyState journeyKitState(JourneyStep step) {
  switch (step.status) {
    case JourneyStepStatus.current:
      return SfJourneyState.current;
    case JourneyStepStatus.completed:
      return SfJourneyState.done;
    case JourneyStepStatus.skipped:
      return SfJourneyState.skipped;
    case JourneyStepStatus.upcoming:
    case JourneyStepStatus.obsolete:
      return SfJourneyState.upcoming;
  }
}

/// Un examen porte un double cercle : c'est un checkpoint, pas une tâche de plus.
SfJourneyKind journeyKind(JourneyStep step) =>
    step.type == JourneyStepType.sectionExam
        ? SfJourneyKind.exam
        : SfJourneyKind.step;

/// L'avancement, dans **l'unité servie**.
///
/// 🛑 L'unité ne se déduit **jamais** de la nullité de `taskCode` : ce serait
/// recopier une règle du référentiel dans les deux fronts.
String? journeyProgressLabel(JourneyProgress? progress) {
  if (progress == null || progress.quota <= 0) return null;
  if (progress.unit == JourneyProgressUnit.series) {
    final s = progress.done > 1 ? 's' : '';
    return '${progress.done} série$s sur ${progress.quota}';
  }
  return '${progress.done} / ${progress.quota} petits sujets';
}

/// Ce que la carte « À faire maintenant » met sous son titre.
String? journeyNowMeta(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.trainSkill:
      return journeyProgressLabel(step.progress);
    case JourneyStepType.sectionExam:
      return step.purpose == JourneyStepPurpose.reassess
          ? 'Cette épreuve mesure ce que vous venez de travailler.'
          : 'Cette épreuve complète votre niveau et identifie vos prochaines priorités.';
    case JourneyStepType.diagnostic:
      return 'Quelques minutes pour identifier vos premières priorités.';
  }
}

/// Le bouton de la carte « À faire maintenant ».
String journeyNowCta(JourneyStep step, bool locked) {
  if (locked) return 'Débloquer cette étape';
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Commencer';
    case JourneyStepType.sectionExam:
      return "Passer l'épreuve";
    case JourneyStepType.trainSkill:
      return 'Continuer';
  }
}

/// Ce que l'écran dit quand il n'y a plus rien à faire (§8).
///
/// 🛑 **Une suggestion n'est pas une étape** : elle n'a pas de position, elle ne
/// se clôt pas, et le candidat peut l'ignorer sans rien laisser « en attente ».
const String kJourneyUpToDateTitle = 'Votre parcours est à jour';
const String kJourneyUpToDateText =
    "Rien de nouveau à travailler pour l'instant : vos prochaines priorités "
    'viendront de votre prochaine évaluation.';
const String kJourneySuggestionMockExam =
    'Vos 4 épreuves sont mesurées. Un examen blanc complet confirmera votre '
    'niveau global.';

/// Aucune démarche déclarée (arbitrage D-3). 🛑 Ce n'est pas un parcours vide :
/// c'est l'absence de parcours.
const String kJourneyNeedsObjectiveTitle = 'Choisir mon objectif';
const String kJourneyNeedsObjectiveText =
    'Votre parcours dépend de la démarche que vous visez.';
const String kJourneyNeedsObjectiveCta = 'Choisir ma démarche';

/// Rien n'est exécutable : la carte montre la première étape, verrouillée.
const String kJourneyLockedCaption =
    "Cette étape fait partie de l'abonnement Intégral. Votre parcours, lui, "
    'reste entier.';

/// **La file entière, à plat** — les étapes de chaque bloc puis son examen,
/// **dans l'ordre servi**.
///
/// 🛑 **C'est le remplaçant de `Journey.steps`**, qui a quitté le contrat le
/// 2026-09-18 : les blocs portent *toutes* les étapes non obsolètes, sans
/// plafond d'affichage. Un écran qui a besoin de la file la lit **ici**, une
/// seule fois par front — l'Accueil et le Plan en dépendent tous les deux, et
/// deux aplatissements auraient fini par ne pas donner le même ordre.
///
/// 🛑 **Rien n'est retrié.** L'ordre des blocs est celui du serveur (`CO, CE,
/// EO, EE`, autorité unique), et l'examen d'un bloc est toujours sa dernière
/// étape.
List<JourneyStep> journeyEtapes(Journey journey) {
  final etapes = <JourneyStep>[];
  for (final bloc in journey.blocs) {
    etapes.addAll(bloc.steps);
    final exam = bloc.exam;
    if (exam != null) etapes.add(exam);
  }
  return etapes;
}

/// L'étape que la carte « À faire maintenant » doit montrer (R16, D-1).
JourneyStep? journeyNowStep(Journey journey) {
  if (journey.current != null) return journey.current;
  // 🛑 `LOCKED` : la carte montre la PREMIÈRE étape ouverte, verrouillée, avec
  // son paywall. La masquer priverait le candidat de l'information la plus
  // utile qu'il possède.
  if (journey.state == JourneyState.locked) {
    for (final step in journeyEtapes(journey)) {
      if (step.status == JourneyStepStatus.upcoming) return step;
    }
  }
  return null;
}

// ===========================================================================
// LE CYCLE ET SES BLOCS — maquettes `docs/progression/plan_cycle.html` ⇄
// `cycle_termine.html` (propriétaire, 2026-09-18)
//
// 🛑 Miroir mot pour mot de `web_sejoufr/lib/journey.ts`.
//
// ⚠️ **Le mot « cycle » est celui de la maquette validée**, et il est écrit
// ici — une seule fois pour tout le front. D-21 interdit le vocabulaire
// INTERNE à l'écran (`lot`, `step`, `journey`) ; le propriétaire a lui-même
// écrit « Cycle 2 » / « Cycle terminé » dans ses deux maquettes, et c'est ce
// qu'on rend. Le jour où il préfère « Parcours 2 », ce sont ces trois
// fonctions qui changent, et elles seules.
// ===========================================================================

/// Le compteur du cycle, en mots. Terminé, il dit l'état plutôt que le compte.
String journeyCycleLabel(JourneyCycle cycle) {
  if (cycle.complete) return 'Cycle terminé';
  final s = cycle.etapesTerminees == 1 ? '' : 's';
  return '${cycle.etapesTerminees} étape$s sur ${cycle.etapesTotal} terminée$s';
}

/// Le repère de cycle, à droite du compteur. `null` sur un cycle terminé — la
/// brique y met le pourcentage à sa place.
String? journeyCycleBadge(JourneyCycle cycle) =>
    cycle.complete ? null : 'Cycle ${cycle.numero}';

/// La phrase sous la barre.
String journeyCycleHint(JourneyCycle cycle) {
  if (cycle.complete) {
    return 'Toutes les compétences et tous les examens d\'épreuve prévus dans '
        'ce cycle sont terminés.';
  }
  if (cycle.cycleDeMesure) {
    return 'Passez les épreuves dans l\'ordre que vous voulez : ce cycle '
        'mesure votre niveau, il ne demande aucun entraînement.';
  }
  return 'Travaillez les priorités identifiées. Le cycle reste stable '
      'jusqu\'à sa prochaine actualisation.';
}

/// Le repère court d'un bloc, en étiquette technique. 🛑 Une seule table.
///
/// 🛑 **L'INITIALE À DEUX LETTRES N'EXISTE QUE POUR UNE ÉPREUVE** (D-47). Une
/// thématique civique n'en a pas — « Principes et valeurs de la République » ne
/// se réduit pas à deux lettres, et en inventer une serait un libellé fabriqué
/// par le front, ce que la doctrine interdit. On rend donc une chaîne vide, et
/// c'est au kit de savoir afficher un en-tête de bloc **sans** initiale. La
/// brique manque encore des deux côtés : c'est P8.6.
String journeyBlocMark(JourneyBlocRef bloc) {
  if (!bloc.estEpreuve) return '';
  return switch (bloc.code) {
    'TCF_CO' => 'CO',
    'TCF_CE' => 'CE',
    'TCF_EE' => 'EE',
    'TCF_EO' => 'EO',
    _ => 'TCF',
  };
}

/// Le nom du bloc **en clair** — ce que le candidat lit (D-21).
///
/// 🛑 **Servi** (D-47). Il se lisait dans `EpreuveType.displayLabel`, un miroir
/// gelé côté front — qui reste pour ses autres emplois. Une thématique civique
/// n'y a aucune entrée, et lui en ajouter une aurait fait de ce miroir une
/// seconde autorité sur un nom que le serveur connaît déjà.
String journeyBlocTitle(JourneyBlocRef bloc) => bloc.label;

/// Le titre d'un bloc de l'HISTORIQUE.
///
/// ✅ **Le passage annoncé a eu lieu** (P8.9, 2026-09-20) : `JourneyHistoryBloc`
/// porte le **bloc servi**, plus `examType`. Il n'y a bien eu **qu'un** appelant
/// à changer — c'était le but de ce helper.
String journeyHistoryBlocTitle(JourneyHistoryBloc bloc) => bloc.bloc.label;

// ⚠️ `journeyBlocMeta` A ÉTÉ SUPPRIMÉE (P8.7, chantier `DETTE-P1`).
// Elle composait « 3 compétences restantes · puis examen » à la main, ICI et
// dans son jumeau TypeScript — deux copies d'une phrase dont le MOT dépend du
// grain du module (« compétence » / « unité »). Le serveur la sert désormais :
// `bloc.meta`. Un fait de moins à tenir des deux côtés.


/// La pastille d'état d'un bloc : son libellé **et** son ton, tous deux servis
/// au kit — qui ne classe rien.
({String label, SfTone tone}) journeyBlocStatus(JourneyBlocStatus status) =>
    switch (status) {
      JourneyBlocStatus.termine => (label: 'TERMINÉ', tone: SfTone.ok),
      JourneyBlocStatus.enCours => (label: 'EN COURS', tone: SfTone.hot),
      JourneyBlocStatus.aEvaluer => (label: 'À ÉVALUER', tone: SfTone.warn),
      JourneyBlocStatus.aVenir => (label: 'À VENIR', tone: SfTone.muted),
    };

/// Le titre de l'encart d'examen d'un bloc.
///
/// 🛑 **Deux intentions, un seul objet** : `initialAssessment` tant que
/// l'épreuve n'a jamais été mesurée, l'examen blanc ensuite. C'est `purpose`
/// qui tranche, jamais une déduction de l'état du bloc.
String journeyExamTitle(JourneyStep exam) {
  // 🛑 Servi (D-47) : vaut pour une épreuve TCF comme pour une thématique.
  final nom = exam.bloc?.label ?? 'cette épreuve';
  return exam.purpose == JourneyStepPurpose.initialAssessment
      ? 'Évaluer mon niveau en ${nom.toLowerCase()}'
      : 'Examen blanc · $nom';
}

/// L'état de l'encart d'examen. Le verrou est **servi** (`locked`).
({String label, SfBarTone tone}) journeyExamState(JourneyStep exam) {
  if (exam.status == JourneyStepStatus.completed ||
      exam.status == JourneyStepStatus.skipped) {
    return (label: 'TERMINÉ', tone: SfBarTone.ok);
  }
  return exam.locked
      ? (label: 'VERROUILLÉ', tone: SfBarTone.muted)
      : (label: 'DISPONIBLE', tone: SfBarTone.now);
}

/// La phrase de condition de l'encart d'examen.
String journeyExamNote(JourneyBloc bloc, JourneyStep exam) {
  if (exam.status == JourneyStepStatus.completed ||
      exam.status == JourneyStepStatus.skipped) {
    return 'Cet examen est passé : son résultat a servi à construire vos '
        'priorités.';
  }
  if (exam.locked) {
    final reste = bloc.etapesRestantes;
    // 🛑 L'accord se fait sur TOUTE la phrase, article compris : « les
    // 1 competence … est terminee » se lisait comme une panne de gabarit.
    if (reste == 1) {
      return 'Disponible dès que la compétence de cette épreuve est terminée.';
    }
    if (reste > 1) {
      return 'Disponible dès que les $reste compétences de cette épreuve '
          'sont terminées.';
    }
    return 'Disponible dès que les compétences de cette épreuve sont '
        'terminées.';
  }
  return bloc.etapesRestantes == 0 && bloc.steps.isEmpty
      ? 'Aucune compétence à travailler avant : l\'examen est la prochaine '
          'action de cette épreuve.'
      : 'Les compétences de cette épreuve sont terminées : l\'examen est la '
          'prochaine action.';
}

/// Le lien d'action d'une ligne d'étape, dans le corps déplié d'un bloc.
///
/// 🛑 **Servi au kit** : [SfJourneyRow] ne compose aucune phrase, pas même
/// celle-ci. Miroir mot pour mot de `JOURNEY_STEP_ACTION_LINK`
/// (`web_sejoufr/lib/journey.ts`).
const String kJourneyStepActionLink = 'Faire cette étape →';

/// Le badge d'une étape **verrouillée**, sur la carte « À faire maintenant ».
///
/// 🛑 Déclaré ICI et pas dans l'écran : la carte civique et la carte TCF disent
/// le même verrou. Miroir mot pour mot de `JOURNEY_LOCKED_BADGE`
/// (`web_sejoufr/lib/journey.ts`).
const String kJourneyLockedBadge = 'Verrouillé';

/// La note de pied du cycle — la liberté d'ordre, et sa seule exception.
const String kJourneyCycleNote =
    'Vous pouvez travailler les compétences dans l\'ordre que vous voulez. '
    'Les examens d\'une épreuve s\'ouvrent seulement quand ses étapes sont '
    'terminées.';

/* ----------------------------------------------------- fin de cycle (§6) --- */

/// L'intertitre qui introduit la carte finale.
const String kJourneyNextStepTitle = 'Prochaine étape';

const String kJourneyNextStepEyebrow = 'Cycle terminé · mesure globale';
const String kJourneyNextStepHeadline =
    'Voyez maintenant où vous en êtes vraiment';
const String kJourneyNextStepText =
    'Vous avez travaillé toutes les priorités identifiées. Passez un TCF blanc '
    'complet pour mesurer votre niveau global et préparer votre prochain cycle.';

/// Le cas d'un **cycle de mesure** clos : enchaîner un second examen complet ne
/// mesurerait rien de nouveau, donc la carte ne le propose pas.
const String kJourneyNextStepTextMesure =
    'Vos quatre épreuves viennent d\'être mesurées. Actualisez votre plan pour '
    'recevoir les priorités que ces résultats ont identifiées.';

/// Les trois repères de l'examen complet. 🛑 Aucun chiffre inventé : quatre
/// épreuves est le format du TCF IRN, pas une donnée servie.
const List<SfNextStepFact> kJourneyNextStepFacts = [
  (value: '4 épreuves', label: 'TCF IRN complet'),
  (value: 'Conditions réelles', label: 'simulation complète'),
  (value: 'Nouveau bilan', label: 'niveau actualisé'),
];

const String kJourneyNextStepExamCta = 'Passer l\'examen blanc complet →';
const String kJourneyNextStepRefreshCta =
    'Actualiser mon plan sans examen complet';

/// 🛑 **Le même geste, dit autrement quand il est SEUL** : « sans examen
/// complet » n'a de sens qu'en face de l'examen complet. À la fin d'un cycle de
/// mesure, il n'y a rien à opposer.
const String kJourneyNextStepRefreshOnlyCta = 'Actualiser mon plan';

const String kJourneyNextStepNote =
    'L\'examen complet est recommandé, mais pas obligatoire. Vous pouvez aussi '
    'actualiser votre plan à partir des examens déjà réalisés.';

/// 🛑 **Un échec réseau se DIT** : un bouton muet laisserait croire à une panne
/// de l'application. Aucune promesse de délai, aucun jargon.
const String kJourneyNextStepError =
    'Votre plan n\'a pas pu être actualisé. Vérifiez votre connexion et '
    'réessayez.';

/// Pendant l'appel : les deux actions historisent le cycle, on ne les rejoue
/// pas par un second appui.
const String kJourneyNextStepBusy = 'Un instant…';

String _sectionLabel(SkillSection section) {
  switch (section) {
    case SkillSection.ee:
      return 'Expression écrite';
    case SkillSection.eo:
      return 'Expression orale';
    case SkillSection.co:
      return 'Compréhension orale';
    case SkillSection.ce:
      return 'Compréhension écrite';
  }
}

String _tacheLabel(SkillTaskCode taskCode) =>
    'Tâche ${taskCode.wire.substring(taskCode.wire.length - 1)}';

/* ==========================================================================
   L'HISTORIQUE DES CYCLES — « Ma progression »
   Maquette `docs/progression/histo_cycle.html` (propriétaire, 2026-09-18)

   🛑 Miroir mot pour mot de la même section de `web_sejoufr/lib/journey.ts`.

   ⚠️ **Le mot « cycle » est celui de la maquette validée** — même raison
   qu'au-dessus : le propriétaire a écrit « Cycle 2 » / « TERMINÉ » lui-même.
   `lot`, `step` et `journey` n'apparaissent nulle part (D-21).
   ========================================================================== */

/// Le titre de l'écran, et le libellé du lien qui l'ouvre.
const String kJourneyHistoryTitle = 'Ma progression';

/// Le sous-titre du lien, sur le Plan. 🛑 Il dit ce que l'écran **contient**,
/// pas ce qu'il prétend expliquer.
String journeyHistorySub([AppModule module = AppModule.tcf]) =>
    'Vos cycles terminés et les ${_uniteMot(module, 2)} travaillées';

/// **Le mot de l'unité travaillable, par parcours** (D-48).
///
/// 🛑 Une **compétence** en TCF, une **unité officielle** en civique. C'est le
/// seul endroit qui le décide pour cet écran : six phrases le répétaient, elles
/// l'appellent toutes. Miroir de `uniteMot` (`web_sejoufr/lib/journey.ts`).
String _uniteMot(AppModule module, int n) => module == AppModule.civique
    ? 'unité${n == 1 ? '' : 's'}'
    : 'compétence${n == 1 ? '' : 's'}';

const String kJourneyHistoryEyebrow = 'Votre parcours';
const String kJourneyHistoryHeadline = 'Tout ce que vous avez déjà travaillé';
const String kJourneyHistoryLead =
    'Vos anciens cycles restent ici, même lorsque votre plan évolue.';

/// Les libellés des trois compteurs. 🛑 **Le nombre vient du serveur** : ces
/// fonctions ne posent que l'accord.
String journeyHistoryStatSkills(int n, [AppModule module = AppModule.tcf]) =>
    '${_uniteMot(module, n)} travaillée${n == 1 ? '' : 's'}';

String journeyHistoryStatExams(int n) =>
    'examen${n == 1 ? '' : 's'} passé${n == 1 ? '' : 's'}';

String journeyHistoryStatCycles(int n) =>
    'cycle${n == 1 ? '' : 's'} terminé${n == 1 ? '' : 's'}';

const String kJourneyHistorySectionTitle = 'Cycles terminés';
const String kJourneyHistorySectionSub = 'Du plus récent au plus ancien';

/// La pastille d'un cycle archivé : un cycle historisé l'est toujours.
const String kJourneyHistoryDonePill = 'TERMINÉ';

/// 🛑 **`cycles` vide est un ÉTAT D'ÉCRAN, pas une erreur** : le bandeau et ses
/// compteurs restent vrais, et l'écran dit ce qui manque — sans bouton mort, il
/// n'y a rien à lancer d'ici.
const String kJourneyHistoryEmptyTitle = 'Aucun cycle terminé pour l\'instant';
String journeyHistoryEmptyText([AppModule module = AppModule.tcf]) =>
    'Votre cycle en cours apparaîtra ici dès qu\'il sera terminé, avec les '
    '${_uniteMot(module, 2)} que vous y aurez travaillées et les examens que '
    'vous y aurez passés.';

/// 🛑 **Un échec de chargement n'est pas « aucun cycle »** : on ne range pas
/// une panne dans le verdict le plus bas.
const String kJourneyHistoryError =
    'Votre progression n\'a pas pu être chargée. Vérifiez votre connexion, puis réessayez.';
const String kJourneyHistoryLoading = 'Chargement…';
const String kJourneyHistoryRetry = 'Réessayer';

const String kJourneyHistoryFootLead = 'Rien n\'est perdu :';
String journeyHistoryFootText([AppModule module = AppModule.tcf]) =>
    ' lorsqu\'un nouveau plan est généré, vos cycles terminés et les '
    '${_uniteMot(module, 2)} travaillées restent visibles ici.';

/// Le titre d'un cycle archivé, et le repère de sa pastille ronde.
String journeyHistoryCycleTitle(int numero) => 'Cycle $numero';

String journeyHistoryCycleMark(int numero) => '$numero';

/// « 4–16 sept. 2026 · 6 compétences · 3 examens » — « 6 unités » en civique.
String journeyHistoryCycleMeta(
  JourneyHistoryCycle cycle, [
  AppModule module = AppModule.tcf,
]) =>
    [
      formatDateRange(cycle.debut, cycle.fin),
      '${cycle.competences} ${_uniteMot(module, cycle.competences)}',
      '${cycle.examens} examen${cycle.examens == 1 ? '' : 's'}',
    ].join(' · ');

/// Les unités travaillées sur un bloc, jointes — des compétences en TCF, des
/// unités officielles en civique (D-48). 🛑 **Les titres sont SERVIS**, cette
/// fonction ne fait que les joindre : aucun mot de parcours n'entre ici.
///
/// 🛑 **`null` quand la liste est vide** : un bloc peut n'avoir reçu qu'un
/// examen, et une ligne de sous-titre vide se lirait comme une donnée
/// manquante.
String? journeyHistoryBlocSkills(JourneyHistoryBloc bloc) =>
    bloc.skillTitles.isEmpty ? null : bloc.skillTitles.join(' · ');

/// **La mesure d'un cycle, par parcours** (P8.9).
///
/// 🛑 **Deux axes, et un seul rempli par cycle** : le TCF mesure un **palier
/// CECRL** (`entryLevel` / `exitLevel`), le civique un **score sur 40**
/// (`entryScore` / `exitScore`). Le serveur sert les deux champs et n'en
/// remplit qu'un — `null` = inconnu **de ce module**, jamais zéro.
///
/// 🛑 **C'est ICI, et seulement ici, que `entry_score` et `exit_score`
/// s'affichent** : D-50 §1 les interdit sur la bande objectif du Plan, où un
/// résultat d'examen blanc se lirait comme un niveau acquis. Dans une archive
/// datée, un résultat d'examen est exactement à sa place.
({String? entree, String? sortie}) _mesure(
  JourneyHistoryCycle cycle,
  AppModule module,
) {
  if (module == AppModule.civique) {
    final entree = cycle.entryScore;
    final sortie = cycle.exitScore;
    return (
      entree: entree == null ? null : _scoreCivique(entree),
      sortie: sortie == null ? null : _scoreCivique(sortie),
    );
  }
  return (entree: cycle.entryLevel?.wire, sortie: cycle.exitLevel?.wire);
}

/// « 34/40 ». 🛑 Le dénominateur vient de [CivicExamFormat], l'autorité du
/// format (arrêté du 10 octobre 2025) — jamais un 40 écrit ici.
String _scoreCivique(int score) => '$score/${CivicExamFormat.questions}';

/// Le titre de l'encart de mesure d'un cycle.
///
/// 🛑 **Deux lectures, et c'est la mesure qui tranche** : quand elle a bougé,
/// l'encart parle de la mesure ; sinon il parle des examens. Le **mot** de la
/// mesure suit le parcours — un niveau en TCF, un score en civique.
String journeyHistoryLevelTitle(
  JourneyHistoryCycle cycle, [
  AppModule module = AppModule.tcf,
]) {
  if (!_journeyHistoryLevelMoved(cycle, module)) return 'Examens réalisés';
  return module == AppModule.civique ? 'Score mesuré' : 'Niveau mesuré';
}

/// La pastille de l'encart de mesure.
///
/// 🛑 **Une sortie nulle ne devient JAMAIS une mesure** : rien n'a été mesuré,
/// ou la mesure est sous l'A2 que la colonne ne sait pas dire (A35). L'encart
/// le dit en clair, en ton [SfBarTone.muted] — `null` = inconnu, jamais mauvais.
///
/// ⚠️ **Le ton reste `ok` dès qu'une mesure existe, y compris sous le seuil
/// civique** : cet encart **constate** un résultat daté, il ne le juge pas —
/// c'est déjà la règle de l'écran TCF, et le seuil se lit dans la note.
({String label, SfBarTone tone}) journeyHistoryLevelState(
  JourneyHistoryCycle cycle, [
  AppModule module = AppModule.tcf,
]) {
  final (:entree, :sortie) = _mesure(cycle, module);
  if (sortie == null) {
    return (
      label: module == AppModule.civique
          ? 'Score non mesuré'
          : 'Niveau non mesuré',
      tone: SfBarTone.muted,
    );
  }
  if (_journeyHistoryLevelMoved(cycle, module)) {
    return (label: '$entree → $sortie', tone: SfBarTone.ok);
  }
  return (
    label: module == AppModule.civique ? sortie : 'Niveau $sortie',
    tone: SfBarTone.ok,
  );
}

/// La phrase sous la pastille.
///
/// 🛑 **Les blocs nommés sont ceux qui ont REÇU un examen** (`examens > 0`),
/// jamais la liste entière : annoncer une épreuve qui n'a rien enregistré
/// serait une mesure inventée.
///
/// ⚠️ **Le civique les COMPTE au lieu de les nommer** : une thématique n'a pas
/// d'initiale (A49), et répéter cinq noms complets ici redirait ce que le corps
/// du cycle liste déjà juste au-dessus. Le compte, lui, est un fait servi.
///
/// 🛑 **Le seuil accompagne toute mesure civique** : un score sur 40 ne veut
/// rien dire sans les 32 qui le rendent suffisant.
String journeyHistoryLevelNote(
  JourneyHistoryCycle cycle, [
  AppModule module = AppModule.tcf,
]) {
  final (entree: _, :sortie) = _mesure(cycle, module);
  final examens = [for (final b in cycle.blocs) if (b.examens > 0) b];
  if (module == AppModule.civique) {
    final combien = examens.length;
    final s = combien == 1 ? '' : 's';
    if (sortie == null) {
      return combien == 0
          ? 'Aucun examen n\'a été enregistré pendant ce cycle.'
          : '$combien examen$s de thème enregistré$s — aucun score global '
              'n\'a été mesuré pendant ce cycle.';
    }
    return _journeyHistoryLevelMoved(cycle, module)
        ? '$_kSeuilCivique Cette évolution correspond aux examens enregistrés '
            'pendant ce cycle.'
        : '$_kSeuilCivique Résultat enregistré dans votre progression.';
  }
  final marks = [
    // ✅ Le bloc est SERVI ici aussi (P8.9) : `journeyBlocMark` rend son
    // initiale pour une épreuve.
    for (final bloc in examens)
      if (journeyBlocMark(bloc.bloc).isNotEmpty) journeyBlocMark(bloc.bloc),
  ];
  if (sortie == null) {
    return marks.isEmpty
        ? 'Aucun examen n\'a été enregistré pendant ce cycle.'
        : '${marks.join(' · ')} — aucun niveau global n\'a été mesuré pendant ce cycle.';
  }
  if (_journeyHistoryLevelMoved(cycle, module)) {
    return 'Cette évolution correspond aux examens enregistrés pendant ce cycle.';
  }
  return marks.isEmpty
      ? 'Ce niveau vient des examens enregistrés dans votre progression.'
      : '${marks.join(' · ')} — résultats enregistrés dans votre progression.';
}

/// 🛑 Le seuil vient de [CivicExamFormat] (arrêté du 10 octobre 2025), jamais
/// d'un 32 écrit dans une phrase.
const String _kSeuilCivique =
    'Seuil de réussite : ${CivicExamFormat.seuil}/${CivicExamFormat.questions}.';

/// Les deux mesures diffèrent, et les deux sont connues.
bool _journeyHistoryLevelMoved(JourneyHistoryCycle cycle, AppModule module) {
  final (:entree, :sortie) = _mesure(cycle, module);
  return entree != null && sortie != null && entree != sortie;
}

// ⚠️ `_initialeEpreuve` A ÉTÉ SUPPRIMÉE (P8.9, 2026-09-20) : l'historique lit
// désormais le bloc SERVI, donc `journeyBlocMark` — qui rend une chaîne vide
// pour une thématique. Deux tables d'initiales pour un même besoin, c'était une
// copie de trop.

