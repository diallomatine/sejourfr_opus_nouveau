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
import '../../core/router/app_router.dart';
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
/// penser : « Expression écrite · Tâche 1 », « Examen blanc ».
///
/// 🛑 **Un examen se dit « Examen blanc », quel que soit son `purpose`**
/// (D-69 ter, propriétaire, 2026-09-28) : la distinction « Évaluer mon niveau »
/// / « Vérifier mes progrès » a quitté l'affichage. Le titre porte l'épreuve.
String? journeyStepSubtitle(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Identifier vos premières priorités';
    case JourneyStepType.sectionExam:
      return kJourneyExamTitle;
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

/// **Les deux lignes d'une étape DANS LE CYCLE** — et là seulement.
///
/// 🛑 **Une troisième autorité aurait été une de trop** : elle vit donc ici, à
/// côté de [journeyStepTitle] / [journeyStepSubtitle], et ne compose rien de
/// neuf — elle **réordonne** les mêmes faits servis (`taskCode`, `unite.label` /
/// `skillTitle`). Miroir de `journeyCycleStepTitle` (`lib/journey.ts`).
///
/// 🛑 **La tâche passe en TITRE** (demande du propriétaire, 2026-09-20 : « comme
/// ça la personne voit qu'elle travaille telle tâche »). Le candidat lit donc
/// « Tâche 3 » puis « Développer un argument », dans la taille inchangée de
/// chacune des deux lignes.
///
/// 🛑 **L'ÉPREUVE DISPARAÎT de la ligne**, et uniquement ici : l'en-tête du bloc
/// qui la contient la nomme déjà (« EE · Expression écrite · 3 compétences
/// restantes »). Partout ailleurs — la carte isolée de l'Accueil, la carte d'une
/// épreuve, le bouton de fin d'étape — la ligne est **seule**, et
/// [journeyStepSubtitle] continue de porter l'épreuve : sans elle, ces surfaces
/// deviendraient muettes sur le domaine travaillé.
String journeyCycleStepTitle(JourneyStep step, [String? niveau]) {
  if (step.type != JourneyStepType.trainSkill) return journeyStepTitle(step);
  // 🛑 `taskCode` nul = compétence de COMPRÉHENSION : il n'y a **pas** de tâche
  // à promouvoir, et on ne lui en invente pas une. Elle porte en revanche un
  // **palier**, et c'est lui qui la situe — « B1 · Comprendre l'implicite… »
  // (demande du propriétaire, 2026-09-20).
  //
  // ⚠️ **Ce palier vient du PLAN** (`planSkillTargetLevelDeCode`), un fait
  // servi sur la compétence, et l'appelant le passe. [JourneyStep] n'en porte
  // aucun : le dériver ici en ferait une seconde autorité. `null` — pas de
  // plan, compétence absente, étape civique — ⇒ la ligne garde son seul
  // intitulé, jamais un palier inventé.
  final taskCode = step.taskCode;
  if (taskCode != null) return _tacheLabel(taskCode);
  final titre = journeyStepTitle(step);
  return niveau == null ? titre : '$niveau · $titre';
}

/// La seconde ligne d'une étape **dans le cycle**. Voir [journeyCycleStepTitle].
String? journeyCycleStepSubtitle(JourneyStep step) {
  if (step.type != JourneyStepType.trainSkill) return journeyStepSubtitle(step);
  // La tâche est montée en titre : l'intitulé descend sous elle. Sans tâche, il
  // reste en titre et la ligne n'a **rien** à mettre dessous — l'épreuve serait
  // la redite que cette composition existe pour supprimer.
  return step.taskCode != null ? journeyStepTitle(step) : null;
}

/// La pastille de fin de ligne. **Servie au kit**, qui ne compose aucune phrase.
String? journeyBadge(JourneyStep step) {
  if (step.status == JourneyStepStatus.current) return 'Maintenant';
  // Un cycle CLOS (« Mes cycles ») : l'étape est restée ouverte, et elle ne se
  // fera plus. Servi `NON_FAITE`, jamais déduit d'un `closedAt` nul.
  if (step.status == JourneyStepStatus.nonFaite) {
    return kJourneyArchiveStepNotDone;
  }
  if (step.status == JourneyStepStatus.skipped) return 'Fait';
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
    case JourneyStepStatus.nonFaite:
      return SfJourneyState.upcoming;
  }
}

/// Un examen porte un double cercle : c'est un checkpoint, pas une tâche de plus.
SfJourneyKind journeyKind(JourneyStep step) =>
    step.type == JourneyStepType.sectionExam
        ? SfJourneyKind.exam
        : SfJourneyKind.step;

/* ==========================================================================
   L'ÉCRAN D'UNE ÉTAPE DE SÉRIES (2026-09-20)

   🛑 **Une étape de COMPRÉHENSION ou CIVIQUE ne lance plus sa série depuis le
   cycle** : elle ouvre l'écran qui la déplie — sa compétence, son avancement,
   ses deux séries. Les libellés de cet écran vivent dans
   `journey_etape_labels.dart` (miroir de `lib/journey-etape.ts`) ; ce qui vit
   ICI, c'est **quelle étape y mène**, parce que c'est une lecture du parcours.
   ========================================================================== */

/// **Où mène une étape de séries.**
///
/// 🛑 **Une seule composition d'adresse** : un chemin recopié dans un écran
/// finirait par diverger du router. ⚠️ Pendant de `journeyEtapeHref`
/// (`web .../lib/journey.ts`), sans son `?module=` — le mobile a un écran par
/// parcours, l'adresse n'a pas à le porter.
String journeyEtapeRoute(String stepId) => AppRoutes.planEtapePath(stepId);

/// **Cette étape se travaille-t-elle par SÉRIES ?**
///
/// 🛑 **Le discriminant est `taskCode`**, le seul fait servi qui sépare les deux
/// grains d'une étape `TRAIN_SKILL` (cf. [JourneyStep.taskCode] : « `null` =
/// compétence de COMPRÉHENSION ») — et une étape civique n'en porte pas non
/// plus. `progress.unit` serait plus explicite, mais il n'est **pas servi** sur
/// une étape civique (`JourneyReadService.progression` rend `null` sans
/// compétence), donc s'appuyer dessus aurait laissé tout le civique de côté.
///
/// ⚠️ **Les étapes d'EXPRESSION (EE/EO) restent en dehors** : elles portent une
/// tâche, et leur chemin vers leurs petits sujets ne change pas.
///
/// 🛑 Miroir mot pour mot de `journeyEtapeASeries` (`web .../lib/journey.ts`).
bool journeyEtapeASeries(JourneyStep step) =>
    step.type == JourneyStepType.trainSkill && step.taskCode == null;

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
      // D-69 ter : aucune phrase sous un examen — miroir du web.
      return null;
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

/// Rien n'est exécutable : on le dit, au lieu de laisser un cycle sans étape
/// courante qui se lirait comme une panne.
///
/// 🛑 **Le pass DÉPEND DU PARCOURS, et c'est pourquoi cette phrase est une
/// fonction** : un cycle civique se débloque avec le pass **Civique**, un cycle
/// TCF avec l'**Intégral** (A108). La constante nommait l'Intégral en dur —
/// sans effet tant que le cycle civique n'était rendu qu'à un abonné (A89),
/// **faux** depuis que l'écran gratuit civique le rend aussi.
///
/// ⚠️ **Déclarée une fois par front**, miroir mot pour mot de
/// `journeyLockedCaption` (`web_sejoufr/lib/journey.ts`) : le nom d'un pass est
/// une phrase commerciale, pas un fait du référentiel — il reste au front (A58).
String journeyLockedCaption(AppModule module) {
  final pass = module == AppModule.civique ? 'Civique' : 'Intégral';
  return "Cette étape fait partie du pass $pass. Votre parcours, lui, "
      'reste entier.';
}

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
  // 🛑 **Cycle d'affinage** (D-64) : lu sur le fait SERVI `cycleDAffinage`,
  // jamais déduit du numéro du cycle. Ses compétences sont facultatives —
  // « toutes les compétences sont terminées » y serait faux.
  if (cycle.cycleDAffinage) {
    return cycle.complete
        ? 'Les examens blancs de toutes les épreuves sont faits. Actualisez '
            'votre plan pour recevoir les priorités qu\'ils ont identifiées.'
        : 'Premier cycle : passez l\'examen blanc de chaque épreuve pour '
            'affiner votre plan. Les compétences détectées par le diagnostic '
            'restent disponibles.';
  }
  // 🛑 **Cycle d'examens d'un compte sans diagnostic** (D-69) : il ne porte
  // aucune compétence — « toutes les compétences… » y serait faux.
  if (cycle.cycleDeMesure && cycle.complete) {
    return 'Les examens blancs de toutes les épreuves sont faits. Actualisez '
        'votre plan pour recevoir les priorités qu\'ils ont identifiées.';
  }
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
      // Un bloc d'un cycle CLOS resté incomplet (« Mes cycles »). Ton neutre :
      // l'archive constate, elle ne reproche rien.
      JourneyBlocStatus.inacheve => (label: 'INACHEVÉ', tone: SfTone.muted),
    };

/// **L'état du rond d'un bloc sur la timeline du cycle** (2026-09-27) — une
/// simple traduction du statut SERVI, rien n'est classé ici.
///
/// Miroir mot pour mot de `journeyBlocRailState` (`lib/journey.ts`).
SfRailState journeyBlocRailState(JourneyBlocStatus status) => switch (status) {
      JourneyBlocStatus.termine => SfRailState.done,
      JourneyBlocStatus.enCours => SfRailState.current,
      JourneyBlocStatus.aEvaluer => SfRailState.upcoming,
      JourneyBlocStatus.aVenir => SfRailState.upcoming,
      JourneyBlocStatus.inacheve => SfRailState.upcoming,
    };

/* ------------------------------ la dernière étape de la timeline du cycle --- */
// « Fin du cycle · Actualiser mon plan · 3 priorités identifiées · Encore 4
// étapes » (demande du propriétaire, 2026-09-27). Miroir mot pour mot de
// `JOURNEY_RAIL_END_*`.
//
// 🛑 **Une seule fin depuis D-66** : l'examen blanc complet a quitté la fin de
// cycle (il devient un jalon, `kJourneyJalon*`). La fin s'appelle donc toujours
// « Actualiser mon plan ».

const String kJourneyRailEndEyebrow = 'Fin du cycle';
const String kJourneyRailEndTitle = 'Actualiser mon plan';

/// « 3 priorités identifiées » — le nombre **servi** de priorités que le cycle
/// suivant portera ([JourneyCycle.prioritesCycleSuivant], D-67), jamais
/// recompté ici. `null` ⇒ rien.
String? journeyPrioritesIdentifiees(JourneyCycle cycle) {
  final n = cycle.prioritesCycleSuivant;
  if (n == null) return null;
  if (n == 0) return 'Aucune priorité identifiée pour l\'instant';
  return '$n priorité${n == 1 ? '' : 's'} identifiée${n == 1 ? '' : 's'}';
}

/// « Encore N étapes » : le **compteur servi**, lu à l'envers —
/// `etapesTotal - etapesTerminees`, la même arithmétique que la barre de
/// [SfCycleProgress]. ⚠️ En affinage, `etapesTotal` ne compte déjà que les
/// étapes obligatoires (plus les facultatives faites) : la différence est donc
/// exactement ce qui reste DÛ avant la fin. `null` ⇒ pas de pastille.
String? journeyRailEndRemaining(JourneyCycle cycle) {
  final restantes = cycle.etapesTotal - cycle.etapesTerminees;
  if (cycle.complete || restantes <= 0) return null;
  return 'Encore $restantes étape${restantes == 1 ? '' : 's'}';
}

/* ----------------------------------------- l'étape d'examen d'un bloc --- */
// 🛑 **Un seul rendu pour toutes les épreuves** (demande du propriétaire,
// 2026-09-26) : « Examen blanc », « Évaluez vos progrès », et le bouton à
// droite. Le nom de l'épreuve n'y est plus — l'en-tête du bloc le porte déjà —,
// et `purpose` ne change aucun libellé (D-69 ter).
//
// 🛑 **Un examen PASSÉ se lit comme dans « Mes cycles »** (D-69 ter) : « Passé
// le … » et son résultat servi à droite — une seule lecture, [JourneyExamLu].
//
// ⚠️ **Registre : le vouvoiement**, celui de tout le Plan. Le propriétaire avait
// écrit « Évalue tes progrès ».
//
// Miroir mot pour mot de `JOURNEY_EXAM_*` (`web_sejoufr/lib/journey.ts`).

const String kJourneyExamTitle = 'Examen blanc';
const String kJourneyExamSubtitle = 'Évaluez vos progrès';
const String kJourneyExamStart = 'Commencer';

/// Verrou `progression` (D-15) — le compte restant est déjà dans l'en-tête du
/// bloc.
const String kJourneyExamNoteProgression =
    'Terminez d\'abord les étapes ci-dessus.';

/// Verrou `access` — suivi du lien « Débloquer mon plan → ».
const String kJourneyExamNoteAccess = 'Réservé à l\'offre complète.';

/// L'examen est-il passé ? Lu sur le statut **servi**.
/// Ce que le lanceur d'examen de thème civique reçoit
/// (`launchCiviqueThemeExam`).
class JourneyExamenThemeLance {
  const JourneyExamenThemeLance({
    required this.themeId,
    required this.themeName,
    required this.slotNumber,
  });

  final String themeId;
  final String themeName;
  final int slotNumber;
}

/// **L'examen de thème qu'une étape civique LANCE** — thème et créneau servis
/// (`examenTheme`), l'intitulé du bloc pour la feuille d'information. `null`
/// quand rien n'est servi. 🛑 Une seule lecture pour la ligne du cycle et la
/// carte « À faire maintenant ». Miroir : `journeyExamenThemeLance`
/// (`lib/journey.ts`).
JourneyExamenThemeLance? journeyExamenThemeLance(JourneyStep step) {
  final examen = step.examenTheme;
  if (examen == null) return null;
  return JourneyExamenThemeLance(
    themeId: examen.themeId,
    themeName: step.bloc?.label ?? kJourneyExamTitle,
    slotNumber: examen.slotNumber,
  );
}

bool journeyExamDone(JourneyStep exam) =>
    exam.status == JourneyStepStatus.completed ||
    exam.status == JourneyStepStatus.skipped;

/// La phrase sous un bouton **inactif**. 🛑 Elle se lit sur `lockReason`
/// **servi**, jamais sur un nombre de compétences restantes : c'est le serveur
/// qui sait pourquoi l'examen est fermé. `null` quand il n'y a rien à dire.
String? journeyExamNote(JourneyStep exam) {
  if (journeyExamDone(exam) || !exam.locked) return null;
  return switch (exam.lockReason) {
    JourneyLockReason.progression => kJourneyExamNoteProgression,
    JourneyLockReason.access => kJourneyExamNoteAccess,
    null => null,
  };
}

/// Le lien d'action d'une ligne d'étape, dans le corps déplié d'un bloc.
///
/// 🛑 **Servi au kit** : [SfJourneyRow] ne compose aucune phrase, pas même
/// celle-ci. Miroir mot pour mot de `JOURNEY_STEP_ACTION_LINK`
/// (`web_sejoufr/lib/journey.ts`).
const String kJourneyStepActionLink = 'Faire cette étape →';

/// Le geste que porte une ligne d'étape **verrouillée**, à la place de
/// [kJourneyStepActionLink].
///
/// 🛑 **Un verrou n'est pas une absence d'action** (demande du propriétaire,
/// 2026-09-20 : « au lieu de verrouiller les actions, à la place du bouton faire
/// cette action etape, mettre débloquer mon plan »). Là où un abonné lit « Faire
/// cette étape », un compte gratuit lisait un cadenas et n'avait **rien à
/// toucher** : la ligne nommait ce qu'il ne pouvait pas faire sans jamais dire
/// comment l'ouvrir. Le cadenas reste — il code l'état —, le geste s'ajoute.
///
/// 🛑 **Le mot est celui de l'offre du Plan** (« Débloquer mon plan », la barre
/// basse sous le cycle) : une même destination ne s'annonce pas de deux façons
/// selon l'endroit où on la touche.
///
/// ⚠️ **Il vit ICI, pas dans l'écran** — c'est exactement le geste A85 : un
/// libellé qui décrit un `locked` **servi** appartient aux mots du parcours.
/// Miroir mot pour mot de `JOURNEY_STEP_UNLOCK_LINK`
/// (`web_sejoufr/lib/journey.ts`).
const String kJourneyStepUnlockLink = 'Débloquer mon plan →';

/// Le badge d'une étape **verrouillée**, sur la carte « À faire maintenant ».
///
/// 🛑 Déclaré ICI et pas dans l'écran : la carte civique et la carte TCF disent
/// le même verrou. Miroir mot pour mot de `JOURNEY_LOCKED_BADGE`
/// (`web_sejoufr/lib/journey.ts`).
const String kJourneyLockedBadge = 'Verrouillé';

/// La note de pied du cycle — la liberté d'ordre, et sa seule exception.
///
/// 🛑 **Conditionnelle au fait servi `cycleDAffinage`** (D-64) : au premier
/// cycle, les examens sont ouverts d'emblée — dire qu'ils attendent les étapes
/// serait faux. Miroir de `journeyCycleNote` (`web_sejoufr/lib/journey.ts`).
String journeyCycleNote(JourneyCycle cycle) => cycle.cycleDAffinage
    ? 'Dans ce premier cycle, les examens blancs sont ouverts d\'emblée. '
        'Travailler les compétences détectées par le diagnostic est facultatif.'
    : 'Vous pouvez travailler les compétences dans l\'ordre que vous voulez. '
        'Les examens d\'une épreuve s\'ouvrent seulement quand ses étapes sont '
        'terminées.';

/* -------------------------------------------------- fin de cycle (D-66) --- */
// 🛑 **Une seule issue** (décision du propriétaire, 2026-09-27) : « Actualiser
// mon plan ». Le choix « Passer l'examen blanc complet / Actualiser sans examen
// complet » est SUPPRIMÉ de la carte, avec ses repères et sa note.

const String kJourneyNextStepEyebrow = 'Cycle terminé';
const String kJourneyNextStepHeadline = 'Passez au cycle suivant';
const String kJourneyNextStepText =
    'Vous avez terminé ce cycle. Actualisez votre plan pour travailler les '
    'priorités que vos évaluations ont identifiées.';

/// Le repère de la carte : le nombre servi de priorités du cycle suivant.
List<SfNextStepFact> journeyNextStepFacts(JourneyCycle cycle) {
  final n = cycle.prioritesCycleSuivant;
  if (n == null) return const [];
  return [
    (
      value: '$n',
      label: 'priorité${n == 1 ? '' : 's'} identifiée${n == 1 ? '' : 's'} '
          'pour le prochain cycle',
    ),
  ];
}

const String kJourneyNextStepRefreshCta = 'Actualiser mon plan';

/// 🛑 **Un échec réseau se DIT** : un bouton muet laisserait croire à une panne
/// de l'application. Aucune promesse de délai, aucun jargon.
const String kJourneyNextStepError =
    'Votre plan n\'a pas pu être actualisé. Vérifiez votre connexion et '
    'réessayez.';

/// Pendant l'appel : l'action historise le cycle, on ne la rejoue pas par un
/// second appui.
const String kJourneyNextStepBusy = 'Un instant…';

/* ------------------------------ le jalon « examen blanc complet » (D-68) --- */
// Proposé au-dessus du Plan, sous « À faire maintenant », quand le serveur le
// sert ([Journey.examenComplet]). 🛑 Aucune condition recombinée ici : la
// raison et le compte sont SERVIS. Miroir mot pour mot de `JOURNEY_JALON_*`.

const String kJourneyJalonTitle = 'Examen blanc complet';
const String kJourneyJalonCta = 'Faire un examen blanc complet';
const String kJourneyJalonBusy = 'Préparation…';
const String kJourneyJalonError =
    'Votre examen blanc complet n\'a pas pu être préparé. Vérifiez votre '
    'connexion et réessayez.';

/// La phrase du jalon, sur la **raison servie**.
String journeyJalonText(JourneyExamenComplet jalon, AppModule module) {
  final civique = module == AppModule.civique;
  if (jalon.raison == JourneyJalonRaison.objectifAtteint) {
    return civique
        ? 'Vos examens de thème sont réussis sur toutes les thématiques. '
            'Confirmez-le dans les conditions de l\'examen.'
        : 'Vos examens blancs atteignent votre objectif sur les quatre '
            'épreuves. Confirmez-le dans les conditions de l\'examen.';
  }
  final n = jalon.cyclesDeTravail;
  return 'Vous avez terminé $n cycle${n == 1 ? '' : 's'} de travail depuis '
      'votre dernier examen blanc complet. Mesurez où vous en êtes '
      '${civique ? 'sur toutes les thématiques.' : 'sur les quatre épreuves.'}';
}

const String kJourneyJalonConfirmTitle = 'Faire un examen blanc complet ?';
const String kJourneyJalonConfirmCta = 'Commencer le cycle d\'examens';
const String kJourneyJalonConfirmCancel = 'Annuler';

/// Ce que le geste fait, **avant** de le faire. 🛑 Sur un cycle **terminé**
/// ([JourneyCycle.complete], servi), rien n'est interrompu.
String journeyJalonConfirmMessage(bool cycleTermine, AppModule module) {
  final examens = module == AppModule.civique
      ? 'un examen par thématique'
      : 'un examen blanc par épreuve';
  final debut = cycleTermine
      ? 'Votre cycle terminé sera archivé dans « Mes cycles ».'
      : 'Votre cycle en cours sera mis de côté : il apparaîtra dans « Mes '
          'cycles » comme interrompu.';
  return '$debut Un cycle d\'examens le remplace, avec $examens. Vos priorités '
      'non terminées ne sont pas perdues : les résultats de ces examens les '
      'recalculeront.';
}

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

/// **L'étape que le cycle propose APRÈS celle qu'on regarde.**
///
/// Sert la fin d'une étape d'expression : les cinq sujets faits, l'écran nomme
/// la suivante au lieu de renvoyer le candidat au Plan pour qu'il la cherche.
///
/// 🛑 **On ne propose jamais l'étape qu'on vient de finir.** Le serveur ne clôt
/// une étape qu'à l'arrivée des **évaluations**, qui sont asynchrones : entre
/// le 5ᵉ sujet rendu et la clôture, `current` désigne encore celle-ci. On
/// compare donc sur `skillCode` et on rend `null` tant qu'elle n'a pas bougé —
/// l'écran retombe alors sur « Revenir à mon plan ». **Ne jamais promettre une
/// étape qui n'existe pas encore.**
///
/// Miroir web : `journeyEtapeSuivante` (`lib/journey.ts`).
JourneyStep? journeyEtapeSuivante(Journey? journey, String? skillCodeCourant) {
  if (journey == null) return null;
  final step = journeyNowStep(journey);
  if (step == null || step.type != JourneyStepType.trainSkill) return null;
  if (skillCodeCourant != null && step.skillCode == skillCodeCourant) {
    return null;
  }
  return step;
}

/// « Continuer : Parler de son quotidien ». Le nom vient du parcours.
String journeyEtapeSuivanteCta(JourneyStep step) =>
    'Continuer : ${journeyStepTitle(step)}';

/* ==========================================================================
   L'HISTORIQUE DES CYCLES — « Mes cycles » (ex-« Ma progression », D16)
   Maquette `docs/progression/histo_cycle.html` (propriétaire, 2026-09-18)

   🛑 Miroir mot pour mot de la même section de `web_sejoufr/lib/journey.ts`.

   ⚠️ **Le mot « cycle » est celui de la maquette validée** — même raison
   qu'au-dessus : le propriétaire a écrit « Cycle 2 » / « TERMINÉ » lui-même.
   `lot`, `step` et `journey` n'apparaissent nulle part (D-21).
   ========================================================================== */

/// Le titre de l'écran, et le libellé du lien qui l'ouvre.
const String kJourneyHistoryTitle = 'Mes cycles';

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

/// La pastille d'un cycle archivé : « INTERROMPU » quand le jalon d'examen
/// complet l'a mis de côté ([JourneyFinDeCycle.interrompu], V078), « TERMINÉ »
/// sinon.
({String label, SfTone tone}) journeyHistoryPill(JourneyFinDeCycle? fin) =>
    fin == JourneyFinDeCycle.interrompu
        ? (label: 'INTERROMPU', tone: SfTone.warn)
        : (label: 'TERMINÉ', tone: SfTone.ok);

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

/// **La mesure d'un cycle, par parcours** (P8.9).
///
/// 🛑 **Deux axes, et un seul rempli par cycle** : le TCF mesure un **palier
/// CECRL** (`entryLevel` / `exitLevel`), le civique un **score sur 40**
/// (`entryScore` / `exitScore`). Le serveur sert les deux champs et n'en
/// remplit qu'un — `null` = inconnu **de ce module**, jamais zéro.
///
/// 🛑 **C'est dans « Mes cycles », et seulement là, que `entry_score` et
/// `exit_score` s'affichent** : D-50 §1 les interdit sur la bande objectif du
/// Plan, où un résultat d'examen blanc se lirait comme un niveau acquis.
({String? entree, String? sortie}) _mesure(
  JourneyCycleArchive cycle,
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

/// **La mesure d'un cycle clos, en une ligne** — « Niveau A2 → B1 », « Niveau
/// B1 », « Score 34/40 · seuil 32/40 ». 🛑 Une sortie nulle ne devient JAMAIS
/// une mesure : `null`, et l'écran n'écrit rien. Miroir de
/// `journeyArchiveLevel` (`lib/journey.ts`).
String? journeyArchiveLevel(
  JourneyCycleArchive cycle, [
  AppModule module = AppModule.tcf,
]) {
  final (:entree, :sortie) = _mesure(cycle, module);
  if (sortie == null) return null;
  final valeur =
      entree != null && entree != sortie ? '$entree → $sortie' : sortie;
  return module == AppModule.civique
      ? 'Score $valeur · seuil ${CivicExamFormat.seuil}/${CivicExamFormat.questions}'
      : 'Niveau $valeur';
}

/* ==========================================================================
   LA CONSULTATION D'UN CYCLE CLOS (« Mes cycles », 2026-09-27)

   🛑 Le cycle est servi comme le Plan (`JourneyCycleArchive` : le même
   `cycle`, les mêmes `blocs`), SANS verrou ni action. Ces libellés ne posent
   que les mots de la consultation. Miroir mot pour mot de `JOURNEY_ARCHIVE_*`
   (`web_sejoufr/lib/journey.ts`).
   ========================================================================== */

/// L'œil-de-bœuf de la page d'un cycle clos.
const String kJourneyArchiveKicker = 'Cycle terminé';

/// La pastille d'une étape restée ouverte dans un cycle clos.
const String kJourneyArchiveStepNotDone = 'Non travaillée';

/// La phrase sous la barre d'un cycle clos : sa date de fin, puis sa mesure.
String journeyArchiveHint(
  JourneyCycleArchive archive, [
  AppModule module = AppModule.tcf,
]) =>
    [
      'Terminé le ${formatLongDate(archive.fin.toLocal())}',
      journeyArchiveLevel(archive, module),
    ].whereType<String>().join(' · ');

/// La note de pied : ce que la page est, et où est le plan en cours.
const String kJourneyArchiveNote =
    'Ce cycle est terminé : il se consulte tel qu\'il était à sa clôture. '
    'Votre plan en cours est sur l\'écran Plan.';

/// Le sous-titre d'un examen lu sans geste — « Passé le 26 sept. 2026 ». Sert
/// un cycle clos **et** l'examen passé du Plan courant (D-69 ter).
String journeyArchiveExamSubtitle(JourneyStep exam) {
  if (!journeyExamDone(exam)) return 'Non passé';
  final quand = exam.closedAt;
  return quand == null ? 'Passé' : 'Passé le ${formatLongDate(quand.toLocal())}';
}

/// Ce que l'examen a donné, à droite de sa ligne — « Niveau B1 », « 17/20 ».
/// 🛑 **Lu sur `resultat` servi** — sur un cycle clos comme sur le Plan courant
/// (D-69 ter) ; absent ⇒ « Passé », jamais un niveau inventé. `null` quand
/// l'examen n'a pas été passé.
String? journeyArchiveExamResult(JourneyStep exam) {
  if (!journeyExamDone(exam)) return null;
  final resultat = exam.resultat;
  final niveau = resultat?.niveau;
  if (niveau != null) return 'Niveau ${niveau.shortName}';
  final score = resultat?.score;
  final max = resultat?.maxScore;
  if (score != null && max != null) return '$score/$max';
  return 'Passé';
}

/// Le titre de la fin d'un cycle clos : **le geste qui l'a clos**, servi
/// (`finDeCycle`, V077). `null` = inconnu ⇒ « Cycle terminé ».
String journeyArchiveEndTitle(JourneyFinDeCycle? fin) => switch (fin) {
      JourneyFinDeCycle.actualisation => 'Plan actualisé',
      JourneyFinDeCycle.examenComplet => 'Examen blanc complet',
      JourneyFinDeCycle.interrompu => 'Cycle interrompu',
      null => 'Cycle terminé',
    };

/// « Le 27 sept. 2026 » — la date de clôture, sous le titre de la fin.
String journeyArchiveEndNote(DateTime fin) =>
    'Le ${formatLongDate(fin.toLocal())}';

const String kJourneyArchiveError =
    'Ce cycle n\'a pas pu être chargé. Vérifiez votre connexion, puis réessayez.';

// ⚠️ `_initialeEpreuve` A ÉTÉ SUPPRIMÉE (P8.9, 2026-09-20) : l'historique lit
// désormais le bloc SERVI, donc `journeyBlocMark` — qui rend une chaîne vide
// pour une thématique. Deux tables d'initiales pour un même besoin, c'était une
// copie de trop.

