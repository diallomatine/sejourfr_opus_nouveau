import type {
    JourneyBlocRefDto,
    EpreuveType,
    JourneyBlocDto,
    JourneyBlocStatus,
    JourneyCycleDto,
    JourneyDto,
    JourneyHistoryBlocDto,
    JourneyHistoryCycleDto,
    JourneyObjectifRefDto,
    JourneyProgressDto,
    JourneyStepDto,
    SkillSection,
    SkillTaskCode,
    TargetLevel,
} from "./types";
import {EPREUVE_PRESENTATION} from "./exam-durations";
import type {
    BarTone,
    JourneyKind,
    JourneyState as KitJourneyState,
    NextStepFact,
    Tone,
} from "../app/_components/sejour/SejourKit";

/**
 * **Les phrases du parcours TCF.** Le serveur sert des faits — type, purpose,
 * section, taskCode, skillTitle, progress, locked — et c'est ici qu'ils
 * deviennent du français.
 *
 * 🛑 **Miroir mot pour mot de `mobile_sejourfr/lib/screens/plan/journey_labels.dart`.**
 * Un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 **Rien ne se déduit ici d'un compteur ni d'une position.** Chaque fonction
 * pose un libellé sur un **état servi** : `status`, `locked`, `progress.unit`.
 * Un front qui recalculerait l'un d'eux finirait par désigner une autre étape
 * que le serveur.
 */

/**
 * Le titre de la section de cycle : « Votre parcours vers le B2 », « Votre
 * parcours — Naturalisation ».
 *
 * 🛑 **La tournure se choisit sur `kind`, jamais sur le module** (D-50). Un
 * palier se dit « vers le B2 » ; une démarche ne se dit pas « vers le
 * Naturalisation ». Le **libellé**, lui, arrive servi — aucun front ne fabrique
 * le mot du candidat.
 */
export function journeyTitle(objectif: JourneyObjectifRefDto | null): string {
    if (!objectif) return "Votre parcours";
    return objectif.kind === "NIVEAU"
        ? `Votre parcours vers le ${objectif.label}`
        : `Votre parcours — ${objectif.label}`;
}

/** Ce que porte la première ligne d'une étape. */
export function journeyStepTitle(step: JourneyStepDto): string {
    if (step.type === "DIAGNOSTIC") return "Diagnostic rapide";
    if (step.type === "SECTION_EXAM") return epreuveLabel(step);
    return step.skillTitle ?? step.skillCode ?? "Compétence";
}

/**
 * La seconde ligne. 🛑 **Elle dit ce que l'étape est**, jamais ce qu'il faut en
 * penser : « Expression écrite · Tâche 1 », « Vérifier mes progrès ».
 */
export function journeyStepSubtitle(step: JourneyStepDto): string | undefined {
    if (step.type === "DIAGNOSTIC") return "Identifier vos premières priorités";
    if (step.type === "SECTION_EXAM") {
        return step.purpose === "REASSESS" ? "Vérifier mes progrès" : "Évaluer mon niveau";
    }
    const domaine = step.section ? sectionLabel(step.section) : null;
    // 🛑 `taskCode` nul = compétence de COMPRÉHENSION : CO/CE n'ont ni tâche ni
    // petit sujet. On ne lui invente pas un « Tâche 1 » qui n'existe pas.
    const tache = step.taskCode ? tacheLabel(step.taskCode) : null;
    return [domaine, tache].filter(Boolean).join(" · ") || undefined;
}

/**
 * La pastille de fin de ligne. **Servie au kit**, qui ne compose aucune phrase.
 *
 * 🛑 « Déjà maîtrisée » ⇄ « Déjà travaillée » se décide sur la **résolution
 * servie**, pas sur un compteur : `SKIPPED` dit seulement qu'elle a été close
 * hors de son tour, et c'est le serveur qui sait pourquoi.
 */
export function journeyBadge(step: JourneyStepDto): string | undefined {
    if (step.status === "CURRENT") return "Maintenant";
    if (step.status === "SKIPPED") return "Déjà travaillée";
    if (step.status === "UPCOMING" && step.type === "SECTION_EXAM") return "Examen";
    return undefined;
}

/** L'état de rendu, tel que le kit l'attend. */
export function journeyKitState(step: JourneyStepDto): KitJourneyState {
    switch (step.status) {
        case "CURRENT":
            return "current";
        case "COMPLETED":
            return "done";
        case "SKIPPED":
            return "skipped";
        default:
            return "upcoming";
    }
}

/** Un examen porte un double cercle : c'est un checkpoint, pas une tâche de plus. */
export function journeyKind(step: JourneyStepDto): JourneyKind {
    return step.type === "SECTION_EXAM" ? "exam" : "step";
}

/**
 * L'avancement, dans **l'unité servie**.
 *
 * 🛑 L'unité ne se déduit **jamais** de la nullité de `taskCode` : ce serait
 * recopier une règle du référentiel dans les deux fronts. Une compétence de
 * compréhension se travaille par **séries ciblées**, une compétence
 * d'expression par **petits sujets**.
 */
export function journeyProgressLabel(progress: JourneyProgressDto | null): string | undefined {
    if (!progress || progress.quota <= 0) return undefined;
    return progress.unit === "SERIES"
        ? `${progress.done} série${progress.done > 1 ? "s" : ""} sur ${progress.quota}`
        : `${progress.done} / ${progress.quota} petits sujets`;
}

/** Ce que la carte « À faire maintenant » met sous son titre. */
export function journeyNowMeta(step: JourneyStepDto): string | undefined {
    if (step.type === "TRAIN_SKILL") return journeyProgressLabel(step.progress);
    if (step.type === "SECTION_EXAM") {
        return step.purpose === "REASSESS"
            ? "Cette épreuve mesure ce que vous venez de travailler."
            : "Cette épreuve complète votre niveau et identifie vos prochaines priorités.";
    }
    return "Quelques minutes pour identifier vos premières priorités.";
}

/** Le bouton de la carte « À faire maintenant ». */
export function journeyNowCta(step: JourneyStepDto, locked: boolean): string {
    if (locked) return "Débloquer cette étape";
    if (step.type === "DIAGNOSTIC") return "Commencer";
    if (step.type === "SECTION_EXAM") return "Passer l'épreuve";
    return "Continuer";
}

/**
 * Ce que l'écran dit quand il n'y a plus rien à faire (§8).
 *
 * 🛑 **Une suggestion n'est pas une étape** : elle n'a pas de position, elle ne
 * se clôt pas, et le candidat peut l'ignorer sans rien laisser « en attente ».
 */
export const JOURNEY_UP_TO_DATE_TITLE = "Votre parcours est à jour";
export const JOURNEY_UP_TO_DATE_TEXT =
    "Rien de nouveau à travailler pour l'instant : vos prochaines priorités viendront de votre prochaine évaluation.";
export const JOURNEY_SUGGESTION_MOCK_EXAM =
    "Vos 4 épreuves sont mesurées. Un examen blanc complet confirmera votre niveau global.";

/**
 * Aucune démarche déclarée (arbitrage D-3). 🛑 Ce n'est pas un parcours vide :
 * c'est l'absence de parcours, et le distinguer évite de féliciter un candidat
 * qui n'a rien commencé.
 */
export const JOURNEY_NEEDS_OBJECTIVE_TITLE = "Choisir mon objectif";
export const JOURNEY_NEEDS_OBJECTIVE_TEXT =
    "Votre parcours dépend de la démarche que vous visez.";
export const JOURNEY_NEEDS_OBJECTIVE_CTA = "Choisir ma démarche";

/** L'écran qui pose la question. 🛑 Une seule constante : un chemin recopié
 *  dans un composant finirait par diverger du router. */
export const JOURNEY_TARGET_PATH_HREF = "/parcours";

/** Rien n'est exécutable : la carte montre la première étape, verrouillée. */
export const JOURNEY_LOCKED_CAPTION =
    "Cette étape fait partie de l'abonnement Intégral. Votre parcours, lui, reste entier.";

/**
 * **La file entière, à plat** — les étapes de chaque bloc puis son examen,
 * **dans l'ordre servi**.
 *
 * 🛑 **C'est le remplaçant de `JourneyDto.steps`**, qui a quitté le contrat le
 * 2026-09-18 : les blocs portent *toutes* les étapes non obsolètes, sans
 * plafond d'affichage. Un écran qui a besoin de la file la lit **ici**, une
 * seule fois par front — l'Accueil et le Plan en dépendent tous les deux, et
 * deux aplatissements auraient fini par ne pas donner le même ordre.
 *
 * 🛑 **Rien n'est retrié.** L'ordre des blocs est celui du serveur (`CO, CE, EO,
 * EE`, autorité unique), et l'examen d'un bloc est toujours sa dernière étape.
 */
export function journeyEtapes(journey: JourneyDto): JourneyStepDto[] {
    const etapes: JourneyStepDto[] = [];
    for (const bloc of journey.blocs) {
        etapes.push(...bloc.steps);
        if (bloc.exam) etapes.push(bloc.exam);
    }
    return etapes;
}

/** L'étape que la carte « À faire maintenant » doit montrer (R16, D-1). */
export function journeyNowStep(journey: JourneyDto): JourneyStepDto | null {
    if (journey.current) return journey.current;
    // 🛑 `LOCKED` : la carte montre la PREMIÈRE étape ouverte, verrouillée, avec
    // son paywall. La masquer priverait le candidat de l'information la plus
    // utile qu'il possède.
    if (journey.state === "LOCKED") {
        return journeyEtapes(journey).find((step) => step.status === "UPCOMING") ?? null;
    }
    return null;
}

/* ==========================================================================
   LE CYCLE ET SES BLOCS — maquettes `docs/progression/plan_cycle.html` ⇄
   `cycle_termine.html` (propriétaire, 2026-09-18)

   🛑 Miroir mot pour mot de `mobile .../screens/plan/journey_labels.dart`.

   ⚠️ **Le mot « cycle » est celui de la maquette validée**, et il est écrit
   ici — une seule fois pour tout le front. D-21 interdit le vocabulaire
   INTERNE à l'écran (`lot`, `step`, `journey`) ; le propriétaire a lui-même
   écrit « Cycle 2 » / « Cycle terminé » dans ses deux maquettes, et c'est ce
   qu'on rend. Le jour où il préfère « Parcours 2 », ce sont ces trois
   fonctions qui changent, et elles seules.
   ========================================================================== */

/** Le compteur du cycle, en mots. Terminé, il dit l'état plutôt que le compte. */
export function journeyCycleLabel(cycle: JourneyCycleDto): string {
    if (cycle.complete) return "Cycle terminé";
    return `${cycle.etapesTerminees} étape${cycle.etapesTerminees === 1 ? "" : "s"} sur ${cycle.etapesTotal} terminée${cycle.etapesTerminees === 1 ? "" : "s"}`;
}

/** Le repère de cycle, à droite du compteur. `undefined` sur un cycle terminé —
 *  la brique y met le pourcentage à sa place. */
export function journeyCycleBadge(cycle: JourneyCycleDto): string | undefined {
    return cycle.complete ? undefined : `Cycle ${cycle.numero}`;
}

/** La phrase sous la barre. */
export function journeyCycleHint(cycle: JourneyCycleDto): string {
    if (cycle.complete) {
        return "Toutes les compétences et tous les examens d'épreuve prévus dans ce cycle sont terminés.";
    }
    if (cycle.cycleDeMesure) {
        return "Passez les épreuves dans l'ordre que vous voulez : ce cycle mesure votre niveau, il ne demande aucun entraînement.";
    }
    return "Travaillez les priorités identifiées. Le cycle reste stable jusqu'à sa prochaine actualisation.";
}

/** Le repère court d'une épreuve, en étiquette technique. 🛑 Une seule table. */
export function journeyBlocMark(bloc: JourneyBlocRefDto): string {
    /* 🛑 L'INITIALE À DEUX LETTRES N'EXISTE QUE POUR UNE ÉPREUVE (D-47).
       Une thématique civique n'en a pas — « Principes et valeurs de la
       République » ne se réduit pas à deux lettres, et en inventer une
       (« PR » ?) serait un libellé fabriqué par le front, ce que la doctrine
       interdit. On rend donc `null`, et c'est au kit de savoir afficher un
       en-tête de bloc SANS initiale. La brique manque encore des deux côtés :
       c'est P8.6. */
    if (bloc.kind !== "EPREUVE") return "";
    switch (bloc.code) {
        case "TCF_CO":
            return "CO";
        case "TCF_CE":
            return "CE";
        case "TCF_EE":
            return "EE";
        case "TCF_EO":
            return "EO";
        default:
            return "TCF";
    }
}

/** Le nom de l'épreuve **en clair** — ce que le candidat lit (D-21). */
/**
 * Le titre d'un bloc de l'HISTORIQUE, qui est encore TCF-only.
 *
 * ⚠️ `JourneyHistoryBlocDto` porte toujours `examType` et pas le bloc servi : il
 * passera au bloc en **P8.9**, avec l'historique civique. D'ici là ce helper
 * existe pour que l'écran d'historique ne dépende pas de `epreuveNom`, privée
 * ici — et pour que le jour du passage, il n'y ait **qu'un** appelant à changer.
 */
export function journeyHistoryBlocTitle(examType: EpreuveType): string {
    return epreuveNom(examType);
}

export function journeyBlocTitle(bloc: JourneyBlocRefDto): string {
    /* 🛑 LE LIBELLÉ EST SERVI (D-47). Il se lisait dans `epreuveNom()`, un miroir
       gelé côté front — qui reste pour ses autres emplois. Une thématique
       civique n'y a aucune entrée, et lui en ajouter une aurait fait de ce
       miroir une seconde autorité sur un nom que le serveur connaît déjà. */
    return bloc.label;
}

/**
 * La méta d'un bloc : ce qu'il reste à y faire.
 *
 * 🛑 **Composée de faits servis** (`status`, `competencesRestantes`, la présence
 * d'un examen), jamais d'un compteur recalculé.
 */
export function journeyBlocMeta(bloc: JourneyBlocDto): string {
    if (bloc.status === "TERMINE") {
        return bloc.steps.length === 0
            ? "Niveau évalué · examen blanc terminé"
            : "Compétences travaillées · examen blanc terminé";
    }
    if (bloc.status === "A_EVALUER") return "Niveau à évaluer";
    const reste = bloc.competencesRestantes;
    if (reste > 0) {
        const mot = `${reste} compétence${reste === 1 ? "" : "s"}`;
        return bloc.status === "EN_COURS"
            ? `${mot} restante${reste === 1 ? "" : "s"} · puis examen`
            : `${mot} · puis examen`;
    }
    if (bloc.exam) return "Examen à passer";
    return "Rien à travailler pour l'instant";
}

/** La pastille d'état d'un bloc : son libellé **et** son ton, tous deux servis
 *  au kit — qui ne classe rien. */
export function journeyBlocStatus(status: JourneyBlocStatus): {label: string; tone: Tone} {
    switch (status) {
        case "TERMINE":
            return {label: "TERMINÉ", tone: "ok"};
        case "EN_COURS":
            return {label: "EN COURS", tone: "hot"};
        case "A_EVALUER":
            return {label: "À ÉVALUER", tone: "warn"};
        case "A_VENIR":
            return {label: "À VENIR", tone: "muted"};
    }
}

/**
 * Le titre de l'encart d'examen d'un bloc.
 *
 * 🛑 **Deux intentions, un seul objet** : `INITIAL_ASSESSMENT` tant que
 * l'épreuve n'a jamais été mesurée, l'examen blanc ensuite. C'est `purpose` qui
 * tranche, jamais une déduction de l'état du bloc.
 */
export function journeyExamTitle(exam: JourneyStepDto): string {
    /* 🛑 LE NOM DU BLOC EST SERVI (D-47) : il vient de `bloc.label`, et il vaut
       aussi bien « Compréhension orale » qu'une thématique civique. Il se lisait
       dans `epreuveNom()`, qui ne connaît que les quatre épreuves du TCF. */
    const nom = exam.bloc ? exam.bloc.label : "cette épreuve";
    return exam.purpose === "INITIAL_ASSESSMENT"
        ? `Évaluer mon niveau en ${nom.toLowerCase()}`
        : `Examen blanc · ${nom}`;
}

/** L'état de l'encart d'examen. Le verrou est **servi** (`locked`). */
export function journeyExamState(exam: JourneyStepDto): {label: string; tone: BarTone} {
    if (exam.status === "COMPLETED" || exam.status === "SKIPPED") {
        return {label: "TERMINÉ", tone: "ok"};
    }
    return exam.locked
        ? {label: "VERROUILLÉ", tone: "muted"}
        : {label: "DISPONIBLE", tone: "now"};
}

/** La phrase de condition de l'encart d'examen. */
export function journeyExamNote(bloc: JourneyBlocDto, exam: JourneyStepDto): string {
    if (exam.status === "COMPLETED" || exam.status === "SKIPPED") {
        return "Cet examen est passé : son résultat a servi à construire vos priorités.";
    }
    if (exam.locked) {
        const reste = bloc.competencesRestantes;
        /* 🛑 L'accord se fait sur TOUTE la phrase, article compris : « les
           1 compétence … est terminée » se lisait comme une panne de gabarit. */
        if (reste === 1) return "Disponible dès que la compétence de cette épreuve est terminée.";
        return reste > 1
            ? `Disponible dès que les ${reste} compétences de cette épreuve sont terminées.`
            : "Disponible dès que les compétences de cette épreuve sont terminées.";
    }
    return bloc.competencesRestantes === 0 && bloc.steps.length === 0
        ? "Aucune compétence à travailler avant : l'examen est la prochaine action de cette épreuve."
        : "Les compétences de cette épreuve sont terminées : l'examen est la prochaine action.";
}

/**
 * Le lien d'action d'une ligne d'étape, dans le corps déplié d'un bloc.
 *
 * 🛑 **Servi au kit** : `JourneyRow` ne compose aucune phrase, pas même
 * celle-ci. Miroir mot pour mot de `kJourneyStepActionLink`
 * (`mobile .../screens/plan/journey_labels.dart`).
 */
export const JOURNEY_STEP_ACTION_LINK = "Faire cette étape →";

/** La note de pied du cycle — la liberté d'ordre, et sa seule exception. */
export const JOURNEY_CYCLE_NOTE =
    "Vous pouvez travailler les compétences dans l'ordre que vous voulez. " +
    "Les examens d'une épreuve s'ouvrent seulement quand ses étapes sont terminées.";

/* ---------------------------------------------------- fin de cycle (spec §6) */

/** L'intertitre qui introduit la carte finale. */
export const JOURNEY_NEXT_STEP_TITLE = "Prochaine étape";

export const JOURNEY_NEXT_STEP_EYEBROW = "Cycle terminé · mesure globale";
export const JOURNEY_NEXT_STEP_HEADLINE = "Voyez maintenant où vous en êtes vraiment";
export const JOURNEY_NEXT_STEP_TEXT =
    "Vous avez travaillé toutes les priorités identifiées. Passez un TCF blanc " +
    "complet pour mesurer votre niveau global et préparer votre prochain cycle.";

/** Le cas d'un **cycle de mesure** clos : enchaîner un second examen complet ne
 *  mesurerait rien de nouveau, donc la carte ne le propose pas. */
export const JOURNEY_NEXT_STEP_TEXT_MESURE =
    "Vos quatre épreuves viennent d'être mesurées. Actualisez votre plan pour " +
    "recevoir les priorités que ces résultats ont identifiées.";

/** Les trois repères de l'examen complet. 🛑 Aucun chiffre inventé : quatre
 *  épreuves est le format du TCF IRN, pas une donnée servie. */
export const JOURNEY_NEXT_STEP_FACTS: NextStepFact[] = [
    {value: "4 épreuves", label: "TCF IRN complet"},
    {value: "Conditions réelles", label: "simulation complète"},
    {value: "Nouveau bilan", label: "niveau actualisé"},
];

export const JOURNEY_NEXT_STEP_EXAM_CTA = "Passer l'examen blanc complet →";
export const JOURNEY_NEXT_STEP_REFRESH_CTA = "Actualiser mon plan sans examen complet";

/** 🛑 **Le même geste, dit autrement quand il est SEUL** : « sans examen
 *  complet » n'a de sens qu'en face de l'examen complet. À la fin d'un cycle de
 *  mesure, il n'y a rien à opposer. */
export const JOURNEY_NEXT_STEP_REFRESH_ONLY_CTA = "Actualiser mon plan";
export const JOURNEY_NEXT_STEP_NOTE =
    "L'examen complet est recommandé, mais pas obligatoire. Vous pouvez aussi " +
    "actualiser votre plan à partir des examens déjà réalisés.";

/** 🛑 **Un échec réseau se DIT** : un bouton muet laisserait croire à une panne
 *  de l'application. Aucune promesse de délai, aucun jargon. */
export const JOURNEY_NEXT_STEP_ERROR =
    "Votre plan n'a pas pu être actualisé. Vérifiez votre connexion et réessayez.";

/** Pendant l'appel : les deux actions historisent le cycle, on ne les rejoue
 *  pas par un second clic. */
export const JOURNEY_NEXT_STEP_BUSY = "Un instant…";

function epreuveLabel(step: JourneyStepDto): string {
    /* 🛑 Servi (D-47). Vaut pour une épreuve TCF comme pour une thématique. */
    return step.bloc ? step.bloc.label : "Épreuve";
}

/** 🛑 **Une seule table de noms d'épreuve** : `EPREUVE_PRESENTATION`. Elle
 *  couvre les quatre épreuves du TCF IRN et rien d'autre. */
function epreuveNom(examType: EpreuveType): string {
    if (
        examType === "TCF_CO"
        || examType === "TCF_CE"
        || examType === "TCF_EE"
        || examType === "TCF_EO"
    ) {
        return EPREUVE_PRESENTATION[examType].label;
    }
    return "Épreuve";
}

function sectionLabel(section: SkillSection): string {
    switch (section) {
        case "EE":
            return "Expression écrite";
        case "EO":
            return "Expression orale";
        case "CO":
            return "Compréhension orale";
        case "CE":
            return "Compréhension écrite";
    }
}

function tacheLabel(taskCode: SkillTaskCode): string {
    return `Tâche ${taskCode.slice(-1)}`;
}

/* ==========================================================================
   L'HISTORIQUE DES CYCLES — « Ma progression »
   Maquette `docs/progression/histo_cycle.html` (propriétaire, 2026-09-18)

   🛑 Miroir mot pour mot de `mobile .../screens/plan/journey_labels.dart`.

   ⚠️ **Le mot « cycle » est celui de la maquette validée** — même raison
   qu'au-dessus : le propriétaire a écrit « Cycle 2 » / « TERMINÉ » lui-même.
   `lot`, `step` et `journey` n'apparaissent nulle part (D-21).
   ========================================================================== */

/** La destination de « Voir ma progression ». 🛑 Une seule constante : un
 *  chemin recopié dans un composant finirait par diverger du router. */
export const JOURNEY_HISTORY_HREF = "/plan/progression";

/** Le titre de l'écran, et le libellé du lien qui l'ouvre. */
export const JOURNEY_HISTORY_TITLE = "Ma progression";

export const JOURNEY_HISTORY_EYEBROW = "Votre parcours";
export const JOURNEY_HISTORY_HEADLINE = "Tout ce que vous avez déjà travaillé";
export const JOURNEY_HISTORY_LEAD =
    "Vos anciens cycles restent ici, même lorsque votre plan évolue.";

/** Les libellés des trois compteurs. 🛑 **Le nombre vient du serveur** : ces
 *  fonctions ne posent que l'accord. */
export function journeyHistoryStatSkills(n: number): string {
    return `compétence${n === 1 ? "" : "s"} travaillée${n === 1 ? "" : "s"}`;
}

export function journeyHistoryStatExams(n: number): string {
    return `examen${n === 1 ? "" : "s"} passé${n === 1 ? "" : "s"}`;
}

export function journeyHistoryStatCycles(n: number): string {
    return `cycle${n === 1 ? "" : "s"} terminé${n === 1 ? "" : "s"}`;
}

export const JOURNEY_HISTORY_SECTION_TITLE = "Cycles terminés";
export const JOURNEY_HISTORY_SECTION_SUB = "Du plus récent au plus ancien";

/** La pastille d'un cycle archivé : un cycle historisé l'est toujours. */
export const JOURNEY_HISTORY_DONE_PILL = "TERMINÉ";

/**
 * 🛑 **`cycles` vide est un ÉTAT D'ÉCRAN, pas une erreur** : le bandeau et ses
 * compteurs restent vrais, et l'écran dit ce qui manque — sans bouton mort, il
 * n'y a rien à lancer d'ici.
 */
export const JOURNEY_HISTORY_EMPTY_TITLE = "Aucun cycle terminé pour l'instant";
export const JOURNEY_HISTORY_EMPTY_TEXT =
    "Votre cycle en cours apparaîtra ici dès qu'il sera terminé, avec les "
    + "compétences que vous y aurez travaillées et les examens que vous y aurez passés.";

/** 🛑 **Un échec de chargement n'est pas « aucun cycle »** : on ne range pas
 *  une panne dans le verdict le plus bas. */
export const JOURNEY_HISTORY_ERROR =
    "Votre progression n'a pas pu être chargée. Vérifiez votre connexion, puis réessayez.";
export const JOURNEY_HISTORY_LOADING = "Chargement…";
export const JOURNEY_HISTORY_RETRY = "Réessayer";

export const JOURNEY_HISTORY_FOOT_LEAD = "Rien n'est perdu :";
export const JOURNEY_HISTORY_FOOT_TEXT =
    " lorsqu'un nouveau plan est généré, vos cycles terminés et les compétences "
    + "travaillées restent visibles ici.";

/** Le titre d'un cycle archivé, et le repère de sa pastille ronde. */
export function journeyHistoryCycleTitle(numero: number): string {
    return `Cycle ${numero}`;
}

export function journeyHistoryCycleMark(numero: number): string {
    return String(numero);
}

/** « 4–16 sept. 2026 · 6 compétences · 3 examens ». */
export function journeyHistoryCycleMeta(cycle: JourneyHistoryCycleDto): string {
    return [
        journeyHistoryDates(cycle.debut, cycle.fin),
        `${cycle.competences} compétence${cycle.competences === 1 ? "" : "s"}`,
        `${cycle.examens} examen${cycle.examens === 1 ? "" : "s"}`,
    ].join(" · ");
}

/**
 * Les compétences travaillées sur une épreuve, jointes.
 *
 * 🛑 **`undefined` quand la liste est vide** : une épreuve peut n'avoir reçu
 * qu'un examen, et une ligne de sous-titre vide se lirait comme une donnée
 * manquante.
 */
export function journeyHistoryBlocSkills(bloc: JourneyHistoryBlocDto): string | undefined {
    return bloc.skillTitles.length > 0 ? bloc.skillTitles.join(" · ") : undefined;
}

/**
 * Le titre de l'encart de niveau d'un cycle.
 *
 * 🛑 **Deux lectures, et c'est la mesure qui tranche** : quand le niveau a
 * bougé, l'encart parle du niveau ; sinon il parle des examens.
 */
export function journeyHistoryLevelTitle(cycle: JourneyHistoryCycleDto): string {
    return journeyHistoryLevelMoved(cycle) ? "Niveau mesuré" : "Examens réalisés";
}

/**
 * La pastille de l'encart de niveau.
 *
 * 🛑 **`exitLevel` nul ne devient JAMAIS un palier** : rien n'a été mesuré, ou
 * la mesure est sous l'A2 que la colonne ne sait pas dire (A35). L'encart le
 * dit en clair, en ton `muted` — `null` = inconnu, jamais mauvais.
 */
export function journeyHistoryLevelState(
    cycle: JourneyHistoryCycleDto,
): {label: string; tone: BarTone} {
    if (!cycle.exitLevel) return {label: "Niveau non mesuré", tone: "muted"};
    return journeyHistoryLevelMoved(cycle)
        ? {label: `${cycle.entryLevel} → ${cycle.exitLevel}`, tone: "ok"}
        : {label: `Niveau ${cycle.exitLevel}`, tone: "ok"};
}

/**
 * La phrase sous la pastille.
 *
 * 🛑 **Les épreuves nommées sont celles qui ont REÇU un examen** (`examens > 0`
 * sur leur bloc), jamais la liste des quatre : annoncer une épreuve qui n'a
 * rien enregistré serait une mesure inventée.
 */
/** 🛑 L'initiale d'une épreuve TCF, pour le seul historique — voir `journeyHistoryLevelNote`. */
const EPREUVE_INITIALE: Record<string, string> = {
    TCF_CO: "CO",
    TCF_CE: "CE",
    TCF_EE: "EE",
    TCF_EO: "EO",
};

export function journeyHistoryLevelNote(cycle: JourneyHistoryCycleDto): string {
    const marks = cycle.blocs
        .filter((bloc) => bloc.examens > 0)
        /* ⚠️ L'HISTORIQUE EST ENCORE TCF-ONLY : `JourneyHistoryBlocDto` porte
           toujours `examType`, pas le bloc servi. Il passera au bloc en P8.9,
           avec l'historique civique. D'ici là on lit l'initiale depuis l'enum,
           sans passer par `journeyBlocMark`, qui attend un bloc servi. */
        .map((bloc) => EPREUVE_INITIALE[bloc.examType] ?? "TCF");
    if (!cycle.exitLevel) {
        return marks.length > 0
            ? `${marks.join(" · ")} — aucun niveau global n'a été mesuré pendant ce cycle.`
            : "Aucun examen n'a été enregistré pendant ce cycle.";
    }
    if (journeyHistoryLevelMoved(cycle)) {
        return "Cette évolution correspond aux examens enregistrés pendant ce cycle.";
    }
    return marks.length > 0
        ? `${marks.join(" · ")} — résultats enregistrés dans votre progression.`
        : "Ce niveau vient des examens enregistrés dans votre progression.";
}

/** Les deux niveaux diffèrent, et les deux sont connus. */
function journeyHistoryLevelMoved(cycle: JourneyHistoryCycleDto): boolean {
    return cycle.entryLevel !== null
        && cycle.exitLevel !== null
        && cycle.entryLevel !== cycle.exitLevel;
}

/**
 * L'intervalle d'un cycle — « 4–16 sept. 2026 », « 28 août – 3 sept. 2026 »,
 * « 18 déc. 2025 – 4 janv. 2026 ».
 *
 * 🛑 **Rien n'est écrit à la main** : `Intl` porte les noms de mois, comme
 * partout ailleurs sur ce front. L'année ne se répète pas quand elle est la
 * même des deux côtés, et le mois non plus.
 *
 * Miroir Flutter : `formatDateRange` (`core/utils/format_date.dart`).
 */
export function journeyHistoryDates(debut: string, fin: string): string {
    const a = new Date(debut);
    const b = new Date(fin);
    const memeAnnee = a.getFullYear() === b.getFullYear();
    if (memeAnnee && a.getMonth() === b.getMonth()) {
        return `${a.getDate()}–${jourCourt(b, true)}`;
    }
    return `${jourCourt(a, !memeAnnee)} – ${jourCourt(b, true)}`;
}

function jourCourt(quand: Date, avecAnnee: boolean): string {
    return quand.toLocaleDateString("fr-FR", avecAnnee
        ? {day: "numeric", month: "short", year: "numeric"}
        : {day: "numeric", month: "short"});
}
