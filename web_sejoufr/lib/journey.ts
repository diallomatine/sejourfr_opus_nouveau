import {niveauCecrlShort} from "./types";
import type {
    JourneyBlocRefDto,
    JourneyBlocStatus,
    JourneyCycleArchiveDto,
    JourneyCycleDto,
    JourneyDto,
    JourneyExamenCompletDto,
    JourneyFinDeCycle,
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
    JourneyKind,
    JourneyState as KitJourneyState,
    NextStepFact,
    RailState,
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
 * penser : « Expression écrite · Tâche 1 », « Examen blanc ».
 *
 * 🛑 **Un examen se dit « Examen blanc », quel que soit son `purpose`**
 * (D-69 ter, 2026-09-28) : la distinction « Évaluer mon niveau / Vérifier mes
 * progrès » a quitté l'affichage. Le titre porte l'épreuve (`bloc.label`).
 */
export function journeyStepSubtitle(step: JourneyStepDto): string | undefined {
    if (step.type === "DIAGNOSTIC") return "Identifier vos premières priorités";
    if (step.type === "SECTION_EXAM") {
        return JOURNEY_EXAM_TITLE;
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
 * 🛑 « Déjà maîtrisée » ⇄ « Fait » (ex-« Déjà travaillée », 2026-09-27) se décide sur la **résolution
 * servie**, pas sur un compteur : `SKIPPED` dit seulement qu'elle a été close
 * hors de son tour, et c'est le serveur qui sait pourquoi.
 */
export function journeyBadge(step: JourneyStepDto): string | undefined {
    if (step.status === "CURRENT") return "Maintenant";
    /* Un cycle CLOS (« Mes cycles ») : l'étape est restée ouverte, et elle ne
       se fera plus. Servi `NON_FAITE`, jamais déduit d'un `closedAt` nul. */
    if (step.status === "NON_FAITE") return JOURNEY_ARCHIVE_STEP_NOT_DONE;
    if (step.status === "SKIPPED") return "Fait";
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

/**
 * Ce que la carte « À faire maintenant » met sous son titre.
 *
 * 🛑 **Rien sous un examen** (D-69 ter) : « Compréhension orale » puis
 * « Examen blanc » disent déjà tout, et la phrase qui variait selon `purpose`
 * a disparu avec la distinction.
 */
export function journeyNowMeta(step: JourneyStepDto): string | undefined {
    if (step.type === "TRAIN_SKILL") return journeyProgressLabel(step.progress);
    if (step.type === "SECTION_EXAM") return undefined;
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
    return `Cette étape fait partie du pass ${pass}. Votre parcours, lui, reste entier.`;
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
 * Sert la fin d'une étape d'expression : tous ses sujets faits, l'écran nomme
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

   ⚠️ **À l'écran, un cycle s'appelle un « plan »** (demande du propriétaire,
   2026-10-03 : « Plan 2 », « Plan terminé », « Mes plans ») ; le code, les
   types, les routes et les DTO gardent « cycle ». Le mot est écrit ici — une
   seule fois pour tout le front. D-21 interdit le vocabulaire INTERNE à
   l'écran (`lot`, `step`, `journey`).
   🛑 **Plus de phrase sous la barre de la carte** (2026-10-03) : l'ancien
   `journeyCycleHint` est supprimé, ne pas le réintroduire.
   ========================================================================== */

/** Le compteur du cycle, en mots. Terminé, il dit l'état plutôt que le compte. */
export function journeyCycleLabel(cycle: JourneyCycleDto): string {
    if (cycle.complete) return "Plan terminé";
    return `${cycle.etapesTerminees} étape${cycle.etapesTerminees === 1 ? "" : "s"} sur ${cycle.etapesTotal} terminée${cycle.etapesTerminees === 1 ? "" : "s"}`;
}

/** Le repère de cycle, à droite du compteur. `undefined` sur un cycle terminé —
 *  la brique y met le pourcentage à sa place. */
export function journeyCycleBadge(cycle: JourneyCycleDto): string | undefined {
    return cycle.complete ? undefined : `Plan ${cycle.numero}`;
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
        /* Un bloc d'un cycle CLOS resté incomplet (« Mes cycles »). Ton neutre :
           l'archive constate, elle ne reproche rien. */
        case "INACHEVE":
            return {label: "INACHEVÉ", tone: "muted"};
    }
}

/**
 * **L'état du rond d'un bloc sur la timeline du cycle** (2026-09-27) — une
 * simple traduction du statut SERVI, rien n'est classé ici : `TERMINE` ⇒ fait,
 * `EN_COURS` ⇒ en cours (le même fait que la prop `current` de l'accordéon),
 * tout le reste ⇒ à venir.
 *
 * Miroir mot pour mot de `journeyBlocRailState` (`journey_labels.dart`).
 */
export function journeyBlocRailState(status: JourneyBlocStatus): RailState {
    switch (status) {
        case "TERMINE":
            return "done";
        case "EN_COURS":
            return "current";
        case "A_EVALUER":
        case "A_VENIR":
        case "INACHEVE":
            return "upcoming";
    }
}

/* -------------------------------- la dernière étape de la timeline du cycle ---
 * « Fin du cycle · Actualiser mon plan · 3 priorités identifiées · Encore 4
 * étapes » (demande du propriétaire, 2026-09-27). Miroir mot pour mot de
 * `kJourneyRailEnd*`.
 *
 * 🛑 **Une seule fin depuis D-66** : l'examen blanc complet a quitté la fin de
 * cycle (il devient un jalon, `JOURNEY_JALON_*`). La fin s'appelle donc
 * toujours « Actualiser mon plan » — `cycle.finDeCycle`, qui la servait, est
 * supprimé avec son autorité.
 */
/** « Priorités actuelles » — le cycle en blocs (Navigation v2). Miroir : `kJourneyPrioritesTitle`. */
export const JOURNEY_PRIORITES_TITLE = "Priorités actuelles";

export const JOURNEY_RAIL_END_EYEBROW = "Fin du plan";
export const JOURNEY_RAIL_END_TITLE = "Actualiser mon plan";

/**
 * « 3 priorités identifiées » — le nombre **servi** de priorités que le cycle
 * suivant portera (`cycle.prioritesCycleSuivant`, D-67), jamais recompté ici.
 * `null` (backend antérieur, consultation) ⇒ rien.
 */
export function journeyPrioritesIdentifiees(cycle: JourneyCycleDto): string | undefined {
    const n = cycle.prioritesCycleSuivant;
    if (n === null || n === undefined) return undefined;
    if (n === 0) return "Aucune priorité identifiée pour l'instant";
    return `${n} priorité${n === 1 ? "" : "s"} identifiée${n === 1 ? "" : "s"}`;
}

/**
 * « Encore N étapes » : le **compteur servi**, lu à l'envers — `etapesTotal -
 * etapesTerminees`, la même arithmétique que la barre de `CycleProgress`.
 * ⚠️ En affinage, `etapesTotal` ne compte déjà que les étapes obligatoires
 * (plus les facultatives faites) : la différence est donc exactement ce qui
 * reste DÛ avant la fin, sans rien reclasser ici. `undefined` ⇒ pas de pastille.
 */
export function journeyRailEndRemaining(cycle: JourneyCycleDto): string | undefined {
    const restantes = cycle.etapesTotal - cycle.etapesTerminees;
    if (cycle.complete || restantes <= 0) return undefined;
    return `Encore ${restantes} étape${restantes === 1 ? "" : "s"}`;
}

/* ------------------------------------------ l'étape d'examen d'un bloc ---
 * 🛑 **Un seul rendu pour toutes les épreuves** (demande du propriétaire,
 * 2026-09-26) : « Examen blanc », « Évaluez vos progrès », et le bouton à
 * droite. Le nom de l'épreuve n'y est plus — l'en-tête du bloc le porte déjà —,
 * et `purpose` (`INITIAL_ASSESSMENT` / `REASSESS`) ne change plus le titre.
 *
 * ⚠️ **Registre : le vouvoiement**, celui de tout le Plan. Le propriétaire avait
 * écrit « Évalue tes progrès ».
 *
 * Miroir mot pour mot de `kJourneyExam*` (`mobile .../screens/plan/journey_labels.dart`).
 */
export const JOURNEY_EXAM_TITLE = "Examen blanc";
export const JOURNEY_EXAM_SUBTITLE = "Évaluez vos progrès";
export const JOURNEY_EXAM_START = "Commencer";
/** Verrou `PROGRESSION` (D-15) — le compte restant est déjà dans l'en-tête du bloc. */
export const JOURNEY_EXAM_NOTE_PROGRESSION = "Terminez d'abord les étapes ci-dessus.";
/** Verrou `ACCESS` — suivi du lien « Débloquer mon plan → ». */
export const JOURNEY_EXAM_NOTE_ACCESS = "Réservé à l'offre complète.";

/* --------------------------------- « Mesurer mon niveau » (cycle de mesure) ---
 * Sur un cycle d'EXAMENS (`cycle.cycleDeMesure` servi, D-69), la carte
 * « À faire maintenant » dit ce que l'examen fait pour le candidat : il mesure
 * son niveau, et le plan suivant se construit dessus. Seuls les mots changent :
 * le lanceur et le créneau restent ceux de la ligne du cycle.
 *
 * 🛑 « Premier examen » se lit sur `purpose === "INITIAL_ASSESSMENT"` servi
 * (l'épreuve n'a jamais été mesurée), jamais sur un rang de cycle.
 *
 * Miroir mot pour mot de `kJourneyMesure*` (`journey_labels.dart`).
 */
export const JOURNEY_MESURE_KIND = "Mesurer mon niveau";
export const JOURNEY_MESURE_NOTE_TCF =
    "Premier examen : il mesure votre niveau de départ, votre plan se construit sur ses résultats.";
export const JOURNEY_MESURE_NOTE_CIVIQUE =
    "Premier examen de ce thème : il mesure votre niveau de départ, votre plan se construit sur ses résultats.";
export const JOURNEY_MESURE_NOTE_REMESURE =
    "Cet examen mesure votre niveau actuel : votre prochain plan se construit sur ses résultats.";

/** Les mots d'un examen de cycle de mesure, `null` hors de ce cas. */
export interface JourneyMesureMots {
    kind: string;
    note: string;
}

export function journeyMesureMots(
    journey: JourneyDto | null,
    etape: JourneyStepDto,
    module: ParcoursModule,
): JourneyMesureMots | null {
    if (etape.type !== "SECTION_EXAM" || journey?.cycle?.cycleDeMesure !== true) return null;
    const note = etape.purpose !== "INITIAL_ASSESSMENT"
        ? JOURNEY_MESURE_NOTE_REMESURE
        : module === "CIVIQUE" ? JOURNEY_MESURE_NOTE_CIVIQUE : JOURNEY_MESURE_NOTE_TCF;
    return {kind: JOURNEY_MESURE_KIND, note};
}

/** Ce que le lanceur d'examen de thème civique reçoit (`useMockExamLauncher`,
 *  `kind: "CIVIQUE"`). */
export interface JourneyExamenThemeLance {
    themeId: string;
    themeName: string;
    slotNumber: number;
}

/**
 * **L'examen de thème qu'une étape civique LANCE** — thème et créneau servis
 * (`examenTheme`), l'intitulé du bloc pour la feuille d'information. `null`
 * quand rien n'est servi. 🛑 Une seule lecture pour la ligne du cycle et la
 * carte « À faire maintenant ». Miroir : `journeyExamenThemeLance`
 * (`journey_labels.dart`).
 */
export function journeyExamenThemeLance(step: JourneyStepDto): JourneyExamenThemeLance | null {
    const examen = step.examenTheme;
    if (!examen) return null;
    return {
        themeId: examen.themeId,
        themeName: step.bloc?.label ?? JOURNEY_EXAM_TITLE,
        slotNumber: examen.slotNumber,
    };
}

/** L'examen est-il passé ? Lu sur le statut **servi**. */
export function journeyExamDone(exam: JourneyStepDto): boolean {
    return exam.status === "COMPLETED" || exam.status === "SKIPPED";
}

/**
 * La phrase sous un bouton **inactif**. 🛑 Elle se lit sur `lockReason`
 * **servi**, jamais sur un nombre de compétences restantes : c'est le serveur
 * qui sait pourquoi l'examen est fermé. `undefined` quand il n'y a rien à dire.
 */
export function journeyExamNote(exam: JourneyStepDto): string | undefined {
    if (journeyExamDone(exam) || !exam.locked) return undefined;
    switch (exam.lockReason) {
        case "PROGRESSION":
            return JOURNEY_EXAM_NOTE_PROGRESSION;
        case "ACCESS":
            return JOURNEY_EXAM_NOTE_ACCESS;
        default:
            return undefined;
    }
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

/**
 * La note de pied du cycle — la liberté d'ordre, et sa seule exception.
 *
 * 🛑 **Conditionnelle au fait servi `cycleDAffinage`** (D-64) : au premier
 * cycle, les examens sont ouverts d'emblée — dire qu'ils attendent les étapes
 * serait faux. Miroir de `journeyCycleNote` (`journey_labels.dart`).
 */
export function journeyCycleNote(cycle: JourneyCycleDto): string {
    return cycle.cycleDAffinage
        ? "Dans ce premier plan, les examens blancs sont ouverts d'emblée. " +
              "Travailler les compétences détectées par le diagnostic est facultatif."
        : "Vous pouvez travailler les compétences dans l'ordre que vous voulez. " +
              "Les examens d'une épreuve s'ouvrent seulement quand ses étapes sont terminées.";
}

/* ------------------------------------------------ fin de cycle (D-66) */

/* 🛑 **Une seule issue** (décision du propriétaire, 2026-09-27) : « Actualiser
 * mon plan ». Le choix « Passer l'examen blanc complet / Actualiser sans examen
 * complet » est SUPPRIMÉ de la carte, avec ses repères et sa note. */
export const JOURNEY_NEXT_STEP_EYEBROW = "Plan terminé";
export const JOURNEY_NEXT_STEP_HEADLINE = "Passez au plan suivant";
export const JOURNEY_NEXT_STEP_TEXT =
    "Vous avez terminé ce plan. Actualisez-le pour travailler les " +
    "priorités que vos évaluations ont identifiées.";

/** Le repère de la carte : le nombre servi de priorités du cycle suivant. */
export function journeyNextStepFacts(cycle: JourneyCycleDto): NextStepFact[] {
    const n = cycle.prioritesCycleSuivant;
    if (n === null || n === undefined) return [];
    return [{
        value: String(n),
        label: `priorité${n === 1 ? "" : "s"} identifiée${n === 1 ? "" : "s"} pour le prochain plan`,
    }];
}

export const JOURNEY_NEXT_STEP_REFRESH_CTA = "Actualiser mon plan";

/** 🛑 **Un échec réseau se DIT** : un bouton muet laisserait croire à une panne
 *  de l'application. Aucune promesse de délai, aucun jargon. */
export const JOURNEY_NEXT_STEP_ERROR =
    "Votre plan n'a pas pu être actualisé. Vérifiez votre connexion et réessayez.";

/** Pendant l'appel : l'action historise le cycle, on ne la rejoue pas par un
 *  second clic. */
export const JOURNEY_NEXT_STEP_BUSY = "Un instant…";

/* ----------------------------------- le jalon « examen blanc complet » (D-68)
 * Proposé au-dessus du Plan, sous « À faire maintenant », quand le serveur le
 * sert (`journey.examenComplet`). 🛑 Aucune condition recombinée ici : la
 * raison et le compte sont SERVIS. Miroir mot pour mot de `kJourneyJalon*`.
 */
export const JOURNEY_JALON_TITLE = "Examen blanc complet";
export const JOURNEY_JALON_CTA = "Faire un examen blanc complet";
export const JOURNEY_JALON_BUSY = "Préparation…";
export const JOURNEY_JALON_ERROR =
    "Votre examen blanc complet n'a pas pu être préparé. Vérifiez votre connexion et réessayez.";

/** La phrase du jalon, sur la **raison servie**. */
export function journeyJalonText(jalon: JourneyExamenCompletDto, module: ParcoursModule): string {
    if (jalon.raison === "OBJECTIF_ATTEINT") {
        return module === "CIVIQUE"
            ? "Vos examens de thème sont réussis sur toutes les thématiques. Confirmez-le " +
                  "dans les conditions de l'examen."
            : "Vos examens blancs atteignent votre objectif sur les quatre épreuves. " +
                  "Confirmez-le dans les conditions de l'examen.";
    }
    const n = jalon.cyclesDeTravail;
    return `Vous avez terminé ${n} plan${n === 1 ? "" : "s"} de travail depuis votre ` +
        "dernier examen blanc complet. Mesurez où vous en êtes " +
        (module === "CIVIQUE" ? "sur toutes les thématiques." : "sur les quatre épreuves.");
}

export const JOURNEY_JALON_CONFIRM_TITLE = "Faire un examen blanc complet ?";
export const JOURNEY_JALON_CONFIRM_CTA = "Commencer le plan d'examens";
export const JOURNEY_JALON_CONFIRM_CANCEL = "Annuler";

/**
 * Ce que le geste fait, **avant** de le faire. 🛑 Sur un cycle **terminé**
 * (`cycle.complete`, servi), rien n'est interrompu : le serveur l'archive
 * « examen blanc complet », et la phrase le dit.
 */
export function journeyJalonConfirmMessage(cycleTermine: boolean, module: ParcoursModule): string {
    const examens = module === "CIVIQUE"
        ? "un examen par thématique"
        : "un examen blanc par épreuve";
    const debut = cycleTermine
        ? "Votre plan terminé sera archivé dans « Mes plans »."
        : "Votre plan en cours sera mis de côté : il apparaîtra dans « Mes plans » " +
            "comme interrompu.";
    return `${debut} Un plan d'examens le remplace, avec ${examens}. Vos priorités ` +
        "non terminées ne sont pas perdues : les résultats de ces examens les recalculeront.";
}

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

   ⚠️ **À l'écran, « cycle » se dit « plan »** — même raison qu'au-dessus
   (2026-10-03).
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
export const JOURNEY_HISTORY_TITLE = "Mes plans";

/** Le sous-titre du lien, sur le Plan : ce que l'écran **contient**.
 *  Miroir de `journeyHistorySub` (`journey_labels.dart`). */
export function journeyHistorySub(module: ParcoursModule = "TCF"): string {
    return `Vos plans terminés et les ${uniteMot(module, 2)} travaillées`;
}

/** Le lien « Mon diagnostic » du Plan. Miroir de `kPlanDiagnosticTitle` /
 *  `kPlanDiagnosticSub` (`plan_labels.dart`). */
export const PLAN_DIAGNOSTIC_TITLE = "Mon diagnostic";
export const PLAN_DIAGNOSTIC_SUB = "Résultat de départ et priorités initiales";

export const JOURNEY_HISTORY_EYEBROW = "Votre parcours";
export const JOURNEY_HISTORY_HEADLINE = "Tout ce que vous avez déjà travaillé";
export const JOURNEY_HISTORY_LEAD =
    "Vos anciens plans restent ici, même lorsque votre plan en cours évolue.";

/** Les libellés des trois compteurs. 🛑 **Le nombre vient du serveur** : ces
 *  fonctions ne posent que l'accord. */
export function journeyHistoryStatSkills(n: number, module: ParcoursModule = "TCF"): string {
    return `${uniteMot(module, n)} travaillée${n === 1 ? "" : "s"}`;
}

export function journeyHistoryStatExams(n: number): string {
    return `examen${n === 1 ? "" : "s"} passé${n === 1 ? "" : "s"}`;
}

export function journeyHistoryStatCycles(n: number): string {
    return `plan${n === 1 ? "" : "s"} terminé${n === 1 ? "" : "s"}`;
}

export const JOURNEY_HISTORY_SECTION_TITLE = "Plans terminés";
export const JOURNEY_HISTORY_SECTION_SUB = "Du plus récent au plus ancien";

/** La pastille d'un cycle archivé : « INTERROMPU » quand le jalon d'examen
 *  complet l'a mis de côté (`finDeCycle` servi, V078), « TERMINÉ » sinon. */
export function journeyHistoryPill(
    fin: JourneyFinDeCycle | null,
): {label: string; tone: "ok" | "warn"} {
    return fin === "INTERROMPU"
        ? {label: "INTERROMPU", tone: "warn"}
        : {label: "TERMINÉ", tone: "ok"};
}

/**
 * 🛑 **`cycles` vide est un ÉTAT D'ÉCRAN, pas une erreur** : le bandeau et ses
 * compteurs restent vrais, et l'écran dit ce qui manque — sans bouton mort, il
 * n'y a rien à lancer d'ici.
 */
export const JOURNEY_HISTORY_EMPTY_TITLE = "Aucun plan terminé pour l'instant";

export function journeyHistoryEmptyText(module: ParcoursModule = "TCF"): string {
    return "Votre plan en cours apparaîtra ici dès qu'il sera terminé, avec les "
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
    return " lorsqu'un nouveau plan est généré, vos plans terminés et les "
        + `${uniteMot(module, 2)} travaillées restent visibles ici.`;
}

/** Le titre d'un cycle archivé, et le repère de sa pastille ronde. */
export function journeyHistoryCycleTitle(numero: number): string {
    return `Plan ${numero}`;
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

/** Les quatre mesures d'un cycle, telles que le serveur les sert — la liste
 *  « Mes cycles » et la consultation d'un cycle les portent toutes les deux. */
type MesureDeCycle = Pick<
    JourneyHistoryCycleDto,
    "entryLevel" | "exitLevel" | "entryScore" | "exitScore"
>;

/**
 * **La mesure d'un cycle, par parcours** (P8.9).
 *
 * 🛑 **Deux axes, et un seul rempli par cycle** : le TCF mesure un **palier
 * CECRL** (`entryLevel` / `exitLevel`), le civique un **score sur 40**
 * (`entryScore` / `exitScore`). Le serveur sert les deux champs et n'en remplit
 * qu'un — `null` = inconnu **de ce module**, jamais zéro.
 *
 * 🛑 **C'est dans « Mes cycles », et seulement là, que `entry_score` et
 * `exit_score` s'affichent** : D-50 §1 les interdit sur la bande objectif du
 * Plan, où un résultat d'examen blanc se lirait comme un niveau acquis. Dans
 * une archive datée, un résultat d'examen est exactement à sa place.
 */
function mesure(
    cycle: MesureDeCycle,
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
 * **La mesure d'un cycle clos, en une ligne** — « Niveau A2 → B1 », « Niveau
 * B1 », « Score 34/40 · seuil 32/40 ».
 *
 * 🛑 **Une sortie nulle ne devient JAMAIS une mesure** : `undefined`, et
 * l'écran n'écrit rien. `null` = inconnu, jamais mauvais — et surtout jamais
 * « Niveau A2 » par défaut.
 */
export function journeyArchiveLevel(
    cycle: MesureDeCycle,
    module: ParcoursModule = "TCF",
): string | undefined {
    const {entree, sortie} = mesure(cycle, module);
    if (!sortie) return undefined;
    const mot = module === "CIVIQUE" ? "Score" : "Niveau";
    const valeur = entree !== null && entree !== sortie ? `${entree} → ${sortie}` : sortie;
    return module === "CIVIQUE"
        ? `${mot} ${valeur} · seuil ${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`
        : `${mot} ${valeur}`;
}

/* ==========================================================================
   LA CONSULTATION D'UN CYCLE CLOS (« Mes cycles », 2026-09-27)

   🛑 Le cycle est servi comme le Plan (`JourneyCycleArchiveDto` : le même
   `cycle`, les mêmes `blocs`), SANS verrou ni action. Ces libellés ne posent
   que les mots de la consultation. Miroir mot pour mot de `kJourneyArchive*`
   (`mobile .../screens/plan/journey_labels.dart`).
   ========================================================================== */

/** L'adresse d'un cycle clos. 🛑 Une seule constante. */
export const JOURNEY_ARCHIVE_HREF = "/plan/progression/cycle";

/** La page d'un cycle clos, **scopée au parcours** (`?module=`, comme « Mes
 *  cycles ») : le retour y ramène sur la bonne liste. */
export function journeyArchiveHref(journeyId: string, module: ParcoursModule): string {
    const base = `${JOURNEY_ARCHIVE_HREF}/${encodeURIComponent(journeyId)}`;
    return module === "TCF" ? base : `${base}?module=${module}`;
}

/** L'œil-de-bœuf de la page d'un cycle clos. */
export const JOURNEY_ARCHIVE_KICKER = "Plan terminé";

/** La pastille d'une étape restée ouverte dans un cycle clos. */
export const JOURNEY_ARCHIVE_STEP_NOT_DONE = "Non travaillée";

/** La phrase sous la barre d'un cycle clos : sa date de fin, puis sa mesure. */
export function journeyArchiveHint(
    archive: JourneyCycleArchiveDto,
    module: ParcoursModule = "TCF",
): string {
    return [`Terminé le ${jourCourt(new Date(archive.fin), true)}`, journeyArchiveLevel(archive, module)]
        .filter(Boolean)
        .join(" · ");
}

/** La note de pied : ce que la page est, et où est le plan en cours. */
export const JOURNEY_ARCHIVE_NOTE =
    "Ce plan est terminé : il se consulte tel qu'il était à sa clôture. "
    + "Votre plan en cours est sur l'écran Plan.";

/**
 * Le sous-titre d'un examen de bloc **clos** — « Passé le 26 sept. 2026 ».
 *
 * 🛑 **Le Plan courant et la consultation d'un cycle clos le lisent tous les
 * deux** (D-69 ter) : un examen passé pendant le cycle montre la même ligne
 * que dans « Mes cycles ». « Non passé » ne se lit qu'en consultation — sur le
 * Plan, un examen ouvert garde son bouton.
 */
export function journeyClosedExamSubtitle(exam: JourneyStepDto): string {
    if (!journeyExamDone(exam)) return "Non passé";
    return exam.closedAt ? `Passé le ${jourCourt(new Date(exam.closedAt), true)}` : "Passé";
}

/**
 * Ce que l'examen a donné, à droite de sa ligne — « Niveau B1 », « 17/20 ».
 * Servi sur le Plan courant comme sur un cycle clos (D-69 ter).
 * 🛑 **Lu sur `resultat` servi** ; absent ⇒ « Passé », jamais un niveau
 * inventé. `undefined` quand l'examen n'a pas été passé.
 */
export function journeyClosedExamResult(exam: JourneyStepDto): string | undefined {
    if (!journeyExamDone(exam)) return undefined;
    const resultat = exam.resultat;
    if (resultat?.niveau) return `Niveau ${niveauCecrlShort(resultat.niveau)}`;
    if (resultat && resultat.score !== null && resultat.maxScore !== null) {
        return `${resultat.score}/${resultat.maxScore}`;
    }
    return "Passé";
}

/**
 * Le titre de la fin d'un cycle clos : **le geste qui l'a clos**, servi
 * (`finDeCycle`, V077). `null` = inconnu (cycle clos avant) ⇒ « Cycle
 * terminé », sans inventer l'issue.
 */
export function journeyArchiveEndTitle(fin: JourneyFinDeCycle | null): string {
    switch (fin) {
        case "ACTUALISATION":
            return "Plan actualisé";
        case "EXAMEN_COMPLET":
            return "Examen blanc complet";
        case "INTERROMPU":
            return "Plan interrompu";
        default:
            return "Plan terminé";
    }
}

/** « Le 27 sept. 2026 » — la date de clôture, sous le titre de la fin. */
export function journeyArchiveEndNote(fin: string): string {
    return `Le ${jourCourt(new Date(fin), true)}`;
}

export const JOURNEY_ARCHIVE_ERROR =
    "Ce plan n'a pas pu être chargé. Vérifiez votre connexion, puis réessayez.";

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
