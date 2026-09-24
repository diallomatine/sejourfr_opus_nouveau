import type {
    JourneyBlocRefDto,
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
} from "./types";
import type {ParcoursModule} from "./module-switch";
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "./civique-examen";
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
    /* 🛑 L'UNITÉ EST SERVIE (D-50) : compétence TCF ou unité officielle
       civique, même chemin. `skillTitle` reste pour ce qu'il porte d'autre. */
    return step.unite?.label ?? step.skillTitle ?? step.skillCode ?? "À travailler";
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
 * **Les deux lignes d'une étape DANS LE CYCLE** — et là seulement.
 *
 * 🛑 **Une troisième autorité aurait été une de trop** : elle vit donc ici,
 * à côté de {@link journeyStepTitle} / {@link journeyStepSubtitle}, et ne
 * compose rien de neuf — elle **réordonne** les mêmes faits servis
 * (`taskCode`, `unite.label` / `skillTitle`). Son miroir Flutter
 * (`journeyCycleStepTitle`, `journey_labels.dart`) change dans la même passe.
 *
 * 🛑 **La tâche passe en TITRE** (demande du propriétaire, 2026-09-20 : « comme
 * ça la personne voit qu'elle travaille telle tâche »). Le candidat lit donc
 * « Tâche 3 » puis « Développer un argument », dans la taille inchangée de
 * chacune des deux lignes.
 *
 * 🛑 **L'ÉPREUVE DISPARAÎT de la ligne**, et uniquement ici : l'en-tête du bloc
 * qui la contient la nomme déjà (« EE · Expression écrite · 3 compétences
 * restantes »). Partout ailleurs — la carte isolée de l'Accueil, la carte d'une
 * épreuve, le bouton de fin d'étape — la ligne est **seule**, et
 * `journeyStepSubtitle` continue de porter l'épreuve : sans elle, ces surfaces
 * deviendraient muettes sur le domaine travaillé.
 */
export function journeyCycleStepTitle(
    step: JourneyStepDto,
    niveau?: string | null,
): string {
    if (step.type !== "TRAIN_SKILL") return journeyStepTitle(step);
    /* 🛑 `taskCode` nul = compétence de COMPRÉHENSION : il n'y a **pas** de
       tâche à promouvoir, et on ne lui en invente pas une. Elle porte en
       revanche un **palier**, et c'est lui qui la situe — « B1 · Comprendre
       l'implicite… » (demande du propriétaire, 2026-09-20).

       ⚠️ **Ce palier vient du PLAN** (`planSkillTargetLevel`), un fait servi
       sur la compétence, et l'appelant le passe. `JourneyStepDto` n'en porte
       aucun : le dériver ici en ferait une seconde autorité. `null` — pas de
       plan, compétence absente, étape civique — ⇒ la ligne garde son seul
       intitulé, jamais un palier inventé. */
    if (step.taskCode) return tacheLabel(step.taskCode);
    return niveau ? `${niveau} · ${journeyStepTitle(step)}` : journeyStepTitle(step);
}

/** La seconde ligne d'une étape **dans le cycle**. Voir {@link journeyCycleStepTitle}. */
export function journeyCycleStepSubtitle(step: JourneyStepDto): string | undefined {
    if (step.type !== "TRAIN_SKILL") return journeyStepSubtitle(step);
    /* La tâche est montée en titre : l'intitulé descend sous elle. Sans tâche,
       il reste en titre et la ligne n'a **rien** à mettre dessous — l'épreuve
       serait la redite que cette composition existe pour supprimer. */
    return step.taskCode ? journeyStepTitle(step) : undefined;
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

/* ==========================================================================
   L'ÉCRAN D'UNE ÉTAPE DE SÉRIES (2026-09-20)

   🛑 **Une étape de COMPRÉHENSION ou CIVIQUE ne lance plus sa série depuis le
   cycle** : elle ouvre l'écran qui la déplie — sa compétence, son avancement,
   ses deux séries. Les libellés de cet écran vivent dans `lib/journey-etape.ts`
   (miroir de `journey_etape_labels.dart`) ; ce qui vit ICI, c'est **quelle
   étape y mène**, parce que c'est une lecture du parcours.
   ========================================================================== */

/** L'adresse de l'écran d'une étape. 🛑 Une seule constante : un chemin recopié
 *  dans un composant finirait par diverger du router. */
export const JOURNEY_ETAPE_HREF = "/plan/etape";

/**
 * **Où mène une étape de séries**, module compris.
 *
 * 🛑 **`?module=` est le seul mécanisme de sélection de module du web** : le
 * cycle sait dans quel parcours il est, l'écran d'étape le lit pour savoir où
 * son retour remonte. Le TCF garde l'adresse nue.
 */
export function journeyEtapeHref(stepId: string, module: ParcoursModule): string {
    const base = `${JOURNEY_ETAPE_HREF}/${stepId}`;
    return module === "TCF" ? base : `${base}?module=${module}`;
}

/**
 * **Cette étape se travaille-t-elle par SÉRIES ?**
 *
 * 🛑 **Le discriminant est `taskCode`**, le seul fait servi qui sépare les deux
 * grains d'une étape `TRAIN_SKILL` (cf. `JourneyStepDto.taskCode` : « `null` =
 * compétence de COMPRÉHENSION ») — et une étape civique n'en porte pas non
 * plus. `progress.unit` serait plus explicite, mais il n'est **pas servi** sur
 * une étape civique (`JourneyReadService.progression` rend `null` sans
 * compétence), donc s'appuyer dessus aurait laissé tout le civique de côté.
 *
 * ⚠️ **Les étapes d'EXPRESSION (EE/EO) restent en dehors** : elles portent une
 * tâche, et leur chemin vers leurs petits sujets ne change pas.
 */
export function journeyEtapeASeries(step: JourneyStepDto): boolean {
    return step.type === "TRAIN_SKILL" && step.taskCode === null;
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

/** L'écran qui pose la question, et **où revenir** une fois l'objectif changé.
 *  🛑 Un seul constructeur : un chemin recopié dans un composant finirait par
 *  diverger du router — et sans `from`, `/parcours` renvoyait au Profil le
 *  candidat venu du Plan. Miroir mobile : `AppRoutes.targetPathFrom`. */
export function journeyTargetPathHref(from: string): string {
    return `/parcours?from=${encodeURIComponent(from)}`;
}

/**
 * Rien n'est exécutable : on le dit, au lieu de laisser un cycle sans étape
 * courante qui se lirait comme une panne.
 *
 * 🛑 **Le pass DÉPEND DU PARCOURS, et c'est pourquoi cette phrase est une
 * fonction** : un cycle civique se débloque avec le pass **Civique**, un cycle
 * TCF avec l'**Intégral** (A108). La constante nommait l'Intégral en dur —
 * sans effet tant que le cycle civique n'était rendu qu'à un abonné (A89),
 * **faux** depuis que l'écran gratuit civique le rend aussi.
 *
 * ⚠️ **Déclarée une fois par front**, miroir mot pour mot de
 * `journeyLockedCaption` (`journey_labels.dart`) : le nom d'un pass est une
 * phrase commerciale, pas un fait du référentiel — il reste au front (A58).
 */
export function journeyLockedCaption(module: ParcoursModule): string {
    const pass = module === "CIVIQUE" ? "Civique" : "Intégral";
    return `Cette étape fait partie de l'abonnement ${pass}. Votre parcours, lui, reste entier.`;
}

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

/**
 * **L'étape que le cycle propose APRÈS celle qu'on regarde.**
 *
 * Sert la fin d'une étape d'expression : les cinq sujets faits, l'écran nomme
 * la suivante au lieu de renvoyer le candidat au Plan pour qu'il la cherche.
 *
 * 🛑 **On ne propose jamais l'étape qu'on vient de finir.** Le serveur ne clôt
 * une étape qu'à l'arrivée des **évaluations**, qui sont asynchrones : entre le
 * 5ᵉ sujet rendu et la clôture, `current` désigne encore celle-ci. On compare
 * donc sur `skillCode` et on rend `null` tant qu'elle n'a pas bougé — l'écran
 * retombe alors sur « Revenir à mon plan ». **Ne jamais promettre une étape qui
 * n'existe pas encore.**
 *
 * Miroir mobile : `journeyEtapeSuivante` (`journey_labels.dart`).
 */
export function journeyEtapeSuivante(
    journey: JourneyDto | null,
    skillCodeCourant: string | null,
): JourneyStepDto | null {
    if (!journey) return null;
    const step = journeyNowStep(journey);
    if (!step || step.type !== "TRAIN_SKILL") return null;
    if (skillCodeCourant && step.skillCode === skillCodeCourant) return null;
    return step;
}

/** « Continuer : Parler de son quotidien ». Le nom vient du parcours. */
export function journeyEtapeSuivanteCta(step: JourneyStepDto): string {
    return `Continuer : ${journeyStepTitle(step)}`;
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
 * Le titre d'un bloc de l'HISTORIQUE.
 *
 * ✅ **Le passage annoncé a eu lieu** (P8.9, 2026-09-20) :
 * `JourneyHistoryBlocDto` porte le **bloc servi**, plus `examType`. Il n'y a
 * bien eu **qu'un** appelant à changer — c'était le but de ce helper.
 */
export function journeyHistoryBlocTitle(bloc: JourneyHistoryBlocDto): string {
    return bloc.bloc.label;
}

export function journeyBlocTitle(bloc: JourneyBlocRefDto): string {
    /* 🛑 LE LIBELLÉ EST SERVI (D-47). Il se lisait dans `epreuveNom()`, un miroir
       gelé côté front — qui reste pour ses autres emplois. Une thématique
       civique n'y a aucune entrée, et lui en ajouter une aurait fait de ce
       miroir une seconde autorité sur un nom que le serveur connaît déjà. */
    return bloc.label;
}

/* ⚠️ `journeyBlocMeta` A ÉTÉ SUPPRIMÉE (P8.7, chantier `DETTE-P1`).
   Elle composait « 3 compétences restantes · puis examen » à la main, ICI et
   dans son jumeau Flutter — deux copies d'une phrase dont le MOT dépend du
   grain du module (« compétence » / « unité »). Le serveur la sert désormais :
   `bloc.meta`. Un fait de moins à tenir des deux côtés. */


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
        const reste = bloc.etapesRestantes;
        /* 🛑 L'accord se fait sur TOUTE la phrase, article compris : « les
           1 compétence … est terminée » se lisait comme une panne de gabarit. */
        if (reste === 1) return "Disponible dès que la compétence de cette épreuve est terminée.";
        return reste > 1
            ? `Disponible dès que les ${reste} compétences de cette épreuve sont terminées.`
            : "Disponible dès que les compétences de cette épreuve sont terminées.";
    }
    return bloc.etapesRestantes === 0 && bloc.steps.length === 0
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

/**
 * Le geste que porte une ligne d'étape **verrouillée**, à la place de
 * {@link JOURNEY_STEP_ACTION_LINK}.
 *
 * 🛑 **Un verrou n'est pas une absence d'action** (demande du propriétaire,
 * 2026-09-20 : « au lieu de verrouiller les actions, à la place du bouton faire
 * cette action etape, mettre débloquer mon plan »). Là où un abonné lit « Faire
 * cette étape », un compte gratuit lisait un cadenas et n'avait **rien à
 * toucher** : la ligne nommait ce qu'il ne pouvait pas faire sans jamais dire
 * comment l'ouvrir. Le cadenas reste — il code l'état —, le geste s'ajoute.
 *
 * 🛑 **Le mot est celui de l'offre du Plan** (« Débloquer mon plan », le bouton
 * ancré sous le cycle) : une même destination ne s'annonce pas de deux façons
 * selon l'endroit où on la touche.
 *
 * ⚠️ **Il vit ICI, pas dans l'écran** — c'est exactement le geste A85 : un
 * libellé qui décrit un `locked` **servi** appartient aux mots du parcours.
 * Miroir mot pour mot de `kJourneyStepUnlockLink`
 * (`mobile .../screens/plan/journey_labels.dart`).
 */
export const JOURNEY_STEP_UNLOCK_LINK = "Débloquer mon plan →";

/**
 * Le badge d'une étape **verrouillée**, sur la carte « À faire maintenant ».
 *
 * 🛑 Déclaré ICI et pas dans l'écran : la carte civique et la carte TCF disent
 * le même verrou, et il était écrit en dur dans le panneau civique. Miroir mot
 * pour mot de `kJourneyLockedBadge`
 * (`mobile .../screens/plan/journey_labels.dart`).
 */
export const JOURNEY_LOCKED_BADGE = "Verrouillé";

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
   L'HISTORIQUE DES CYCLES — « Mes cycles » (ex-« Ma progression », D16)
   Maquette `docs/progression/histo_cycle.html` (propriétaire, 2026-09-18)

   🛑 Miroir mot pour mot de `mobile .../screens/plan/journey_labels.dart`.

   ⚠️ **Le mot « cycle » est celui de la maquette validée** — même raison
   qu'au-dessus : le propriétaire a écrit « Cycle 2 » / « TERMINÉ » lui-même.
   `lot`, `step` et `journey` n'apparaissent nulle part (D-21).
   ========================================================================== */

/** La destination de « Mes cycles ». 🛑 Une seule constante : un
 *  chemin recopié dans un composant finirait par diverger du router. */
export const JOURNEY_HISTORY_HREF = "/plan/progression";

/**
 * La destination de « Mes cycles », **scopée au parcours** (P8.9).
 *
 * 🛑 **`?module=` est le seul mécanisme de sélection de module du web**, et
 * l'écran d'historique n'y fait pas exception : un second chemin
 * (`/plan/progression-civique`) aurait été une deuxième façon de dire la même
 * chose. Le TCF garde l'adresse nue — un lien déjà partagé continue d'aboutir.
 */
export function journeyHistoryHref(module: ParcoursModule): string {
    return module === "TCF"
        ? JOURNEY_HISTORY_HREF
        : `${JOURNEY_HISTORY_HREF}?module=${module}`;
}

/**
 * **Le mot de l'unité travaillable, par parcours** (D-48).
 *
 * 🛑 Une **compétence** en TCF, une **unité officielle** en civique. C'est le
 * seul endroit qui le décide pour cet écran : six phrases le répétaient, elles
 * l'appellent toutes.
 */
function uniteMot(module: ParcoursModule, n: number): string {
    return module === "CIVIQUE"
        ? `unité${n === 1 ? "" : "s"}`
        : `compétence${n === 1 ? "" : "s"}`;
}

/** Le titre de l'écran, et le libellé du lien qui l'ouvre. */
export const JOURNEY_HISTORY_TITLE = "Mes cycles";

export const JOURNEY_HISTORY_EYEBROW = "Votre parcours";
export const JOURNEY_HISTORY_HEADLINE = "Tout ce que vous avez déjà travaillé";
export const JOURNEY_HISTORY_LEAD =
    "Vos anciens cycles restent ici, même lorsque votre plan évolue.";

/** Les libellés des trois compteurs. 🛑 **Le nombre vient du serveur** : ces
 *  fonctions ne posent que l'accord. */
export function journeyHistoryStatSkills(n: number, module: ParcoursModule = "TCF"): string {
    return `${uniteMot(module, n)} travaillée${n === 1 ? "" : "s"}`;
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

export function journeyHistoryEmptyText(module: ParcoursModule = "TCF"): string {
    return "Votre cycle en cours apparaîtra ici dès qu'il sera terminé, avec les "
        + `${uniteMot(module, 2)} que vous y aurez travaillées et les examens que `
        + "vous y aurez passés.";
}

/** 🛑 **Un échec de chargement n'est pas « aucun cycle »** : on ne range pas
 *  une panne dans le verdict le plus bas. */
export const JOURNEY_HISTORY_ERROR =
    "Votre progression n'a pas pu être chargée. Vérifiez votre connexion, puis réessayez.";
export const JOURNEY_HISTORY_LOADING = "Chargement…";
export const JOURNEY_HISTORY_RETRY = "Réessayer";

export const JOURNEY_HISTORY_FOOT_LEAD = "Rien n'est perdu :";

export function journeyHistoryFootText(module: ParcoursModule = "TCF"): string {
    return " lorsqu'un nouveau plan est généré, vos cycles terminés et les "
        + `${uniteMot(module, 2)} travaillées restent visibles ici.`;
}

/** Le titre d'un cycle archivé, et le repère de sa pastille ronde. */
export function journeyHistoryCycleTitle(numero: number): string {
    return `Cycle ${numero}`;
}

export function journeyHistoryCycleMark(numero: number): string {
    return String(numero);
}

/** « 4–16 sept. 2026 · 6 compétences · 3 examens » — « 6 unités » en civique. */
export function journeyHistoryCycleMeta(
    cycle: JourneyHistoryCycleDto,
    module: ParcoursModule = "TCF",
): string {
    return [
        journeyHistoryDates(cycle.debut, cycle.fin),
        `${cycle.competences} ${uniteMot(module, cycle.competences)}`,
        `${cycle.examens} examen${cycle.examens === 1 ? "" : "s"}`,
    ].join(" · ");
}

/**
 * Les unités travaillées sur un bloc, jointes — des compétences en TCF, des
 * unités officielles en civique (D-48). 🛑 **Les titres sont SERVIS**, cette
 * fonction ne fait que les joindre : aucun mot de parcours n'entre ici.
 *
 * 🛑 **`undefined` quand la liste est vide** : un bloc peut n'avoir reçu qu'un
 * examen, et une ligne de sous-titre vide se lirait comme une donnée
 * manquante.
 */
export function journeyHistoryBlocSkills(bloc: JourneyHistoryBlocDto): string | undefined {
    return bloc.skillTitles.length > 0 ? bloc.skillTitles.join(" · ") : undefined;
}

/**
 * **La mesure d'un cycle, par parcours** (P8.9).
 *
 * 🛑 **Deux axes, et un seul rempli par cycle** : le TCF mesure un **palier
 * CECRL** (`entryLevel` / `exitLevel`), le civique un **score sur 40**
 * (`entryScore` / `exitScore`). Le serveur sert les deux champs et n'en remplit
 * qu'un — `null` = inconnu **de ce module**, jamais zéro.
 *
 * 🛑 **C'est ICI, et seulement ici, que `entry_score` et `exit_score`
 * s'affichent** : D-50 §1 les interdit sur la bande objectif du Plan, où un
 * résultat d'examen blanc se lirait comme un niveau acquis. Dans une archive
 * datée, un résultat d'examen est exactement à sa place.
 */
function mesure(
    cycle: JourneyHistoryCycleDto,
    module: ParcoursModule,
): {entree: string | null; sortie: string | null} {
    if (module === "CIVIQUE") {
        return {
            entree: cycle.entryScore === null ? null : scoreCivique(cycle.entryScore),
            sortie: cycle.exitScore === null ? null : scoreCivique(cycle.exitScore),
        };
    }
    return {entree: cycle.entryLevel, sortie: cycle.exitLevel};
}

/** « 34/40 ». 🛑 Le dénominateur vient de `CivicExamFormat`, l'autorité du
 *  format (arrêté du 10 octobre 2025) — jamais un 40 écrit ici. */
function scoreCivique(score: number): string {
    return `${score}/${CIVIQUE_EXAM_QUESTIONS}`;
}

/**
 * Le titre de l'encart de mesure d'un cycle.
 *
 * 🛑 **Deux lectures, et c'est la mesure qui tranche** : quand elle a bougé,
 * l'encart parle de la mesure ; sinon il parle des examens. Le **mot** de la
 * mesure suit le parcours — un niveau en TCF, un score en civique.
 */
export function journeyHistoryLevelTitle(
    cycle: JourneyHistoryCycleDto,
    module: ParcoursModule = "TCF",
): string {
    if (!journeyHistoryLevelMoved(cycle, module)) return "Examens réalisés";
    return module === "CIVIQUE" ? "Score mesuré" : "Niveau mesuré";
}

/**
 * La pastille de l'encart de mesure.
 *
 * 🛑 **Une sortie nulle ne devient JAMAIS une mesure** : rien n'a été mesuré,
 * ou la mesure est sous l'A2 que la colonne ne sait pas dire (A35). L'encart le
 * dit en clair, en ton `muted` — `null` = inconnu, jamais mauvais.
 *
 * ⚠️ **Le ton reste `ok` dès qu'une mesure existe, y compris sous le seuil
 * civique** : cet encart **constate** un résultat daté, il ne le juge pas —
 * c'est déjà la règle de l'écran TCF, et le seuil se lit dans la note.
 */
export function journeyHistoryLevelState(
    cycle: JourneyHistoryCycleDto,
    module: ParcoursModule = "TCF",
): {label: string; tone: BarTone} {
    const {entree, sortie} = mesure(cycle, module);
    if (!sortie) {
        return {
            label: module === "CIVIQUE" ? "Score non mesuré" : "Niveau non mesuré",
            tone: "muted",
        };
    }
    if (journeyHistoryLevelMoved(cycle, module)) {
        return {label: `${entree} → ${sortie}`, tone: "ok"};
    }
    return {label: module === "CIVIQUE" ? sortie : `Niveau ${sortie}`, tone: "ok"};
}

/**
 * La phrase sous la pastille.
 *
 * 🛑 **Les blocs nommés sont ceux qui ont REÇU un examen** (`examens > 0`),
 * jamais la liste entière : annoncer une épreuve qui n'a rien enregistré serait
 * une mesure inventée.
 *
 * ⚠️ **Le civique les COMPTE au lieu de les nommer** : une thématique n'a pas
 * d'initiale (A49), et répéter cinq noms complets ici redirait ce que le corps
 * du cycle liste déjà juste au-dessus. Le compte, lui, est un fait servi.
 *
 * 🛑 **Le seuil accompagne toute mesure civique** : un score sur 40 ne veut
 * rien dire sans les 32 qui le rendent suffisant.
 */
export function journeyHistoryLevelNote(
    cycle: JourneyHistoryCycleDto,
    module: ParcoursModule = "TCF",
): string {
    const {sortie} = mesure(cycle, module);
    const examens = cycle.blocs.filter((bloc) => bloc.examens > 0);
    if (module === "CIVIQUE") {
        const combien = examens.length;
        const passes = combien > 0
            ? `${combien} examen${combien === 1 ? "" : "s"} de thème enregistré${combien === 1 ? "" : "s"}`
            : null;
        if (!sortie) {
            return passes
                ? `${passes} — aucun score global n'a été mesuré pendant ce cycle.`
                : "Aucun examen n'a été enregistré pendant ce cycle.";
        }
        return `${SEUIL_CIVIQUE}${journeyHistoryLevelMoved(cycle, module)
            ? " Cette évolution correspond aux examens enregistrés pendant ce cycle."
            : " Résultat enregistré dans votre progression."}`;
    }
    const marks = examens
        /* ✅ Le bloc est SERVI ici aussi (P8.9) : `journeyBlocMark` rend son
           initiale pour une épreuve. */
        .map((bloc) => journeyBlocMark(bloc.bloc))
        .filter((mark) => mark.length > 0);
    if (!sortie) {
        return marks.length > 0
            ? `${marks.join(" · ")} — aucun niveau global n'a été mesuré pendant ce cycle.`
            : "Aucun examen n'a été enregistré pendant ce cycle.";
    }
    if (journeyHistoryLevelMoved(cycle, module)) {
        return "Cette évolution correspond aux examens enregistrés pendant ce cycle.";
    }
    return marks.length > 0
        ? `${marks.join(" · ")} — résultats enregistrés dans votre progression.`
        : "Ce niveau vient des examens enregistrés dans votre progression.";
}

/** 🛑 Le seuil vient de `CivicExamFormat` (arrêté du 10 octobre 2025), jamais
 *  d'un 32 écrit dans une phrase. */
const SEUIL_CIVIQUE =
    `Seuil de réussite : ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}.`;

/** Les deux mesures diffèrent, et les deux sont connues. */
function journeyHistoryLevelMoved(
    cycle: JourneyHistoryCycleDto,
    module: ParcoursModule,
): boolean {
    const {entree, sortie} = mesure(cycle, module);
    return entree !== null && sortie !== null && entree !== sortie;
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
