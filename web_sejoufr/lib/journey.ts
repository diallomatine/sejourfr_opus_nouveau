import type {
    JourneyDto,
    JourneyProgressDto,
    JourneyStepDto,
    SkillSection,
    SkillTaskCode,
    TargetLevel,
} from "./types";
import {EPREUVE_PRESENTATION} from "./exam-durations";
import type {JourneyKind, JourneyState as KitJourneyState} from "../app/_components/sejour/SejourKit";

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

/** Le titre de l'écran : « Votre parcours vers le B2 ». */
export function journeyTitle(targetLevel: TargetLevel | null): string {
    return targetLevel ? `Votre parcours vers le ${targetLevel}` : "Votre parcours";
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

/** Rien n'est exécutable : la carte montre la première étape, verrouillée. */
export const JOURNEY_LOCKED_CAPTION =
    "Cette étape fait partie de l'abonnement Intégral. Votre parcours, lui, reste entier.";

/** Le repli de « Voir les étapes suivantes ». */
export function journeyMoreLabel(hidden: number): string | undefined {
    if (hidden <= 0) return undefined;
    return `Voir les ${hidden} étape${hidden > 1 ? "s" : ""} suivante${hidden > 1 ? "s" : ""}`;
}

/** L'étape que la carte « À faire maintenant » doit montrer (R16, D-1). */
export function journeyNowStep(journey: JourneyDto): JourneyStepDto | null {
    if (journey.current) return journey.current;
    // 🛑 `LOCKED` : la carte montre la PREMIÈRE étape ouverte, verrouillée, avec
    // son paywall. La masquer priverait le candidat de l'information la plus
    // utile qu'il possède.
    if (journey.state === "LOCKED") {
        return journey.steps.find((step) => step.status === "UPCOMING") ?? null;
    }
    return null;
}

function epreuveLabel(step: JourneyStepDto): string {
    const epreuve = step.examType;
    if (epreuve === "TCF_CO" || epreuve === "TCF_CE" || epreuve === "TCF_EE" || epreuve === "TCF_EO") {
        return EPREUVE_PRESENTATION[epreuve].label;
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
