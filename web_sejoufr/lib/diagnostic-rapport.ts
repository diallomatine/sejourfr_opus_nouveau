/**
 * **Les phrases du rapport du diagnostic rapide TCF, de sa transition
 * « Votre plan commence ici » et de « Revoir ma réponse »** (2026-10-04,
 * `docs/diagnostic/maquette-rapport-diagnostic-premium.html`).
 *
 * 🛑 **Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/diagnostic/diagnostic_rapport_labels.dart`** :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * Le serveur sert des **faits** — niveau estimé, objectif, situation par
 * rapport à l'objectif, priorités du lot du Plan, statut de communication,
 * état des épreuves. Ici, ils deviennent du français ; rien n'y est classé,
 * trié ni recalculé.
 *
 * 🛑 **Les priorités affichées sont `result.planPriorities`, et rien d'autre** :
 * jamais `result.priorities` / `mainPriorityExplanation` (les priorités du
 * diagnostic, qui ne coïncident pas avec le Plan), jamais triées, jamais
 * tronquées (`docs/regles/diagnostic.md`).
 */
import {
    SKILL_SECTION_LABEL,
    type DiagnosticCommunicationStatus,
    type DiagnosticPlanPriorityDto,
    type DiagnosticResultDto,
    type JourneyDto,
    type PlanDomainDto,
    type SituationObjectif,
} from "./types";
import type {EpreuveTile} from "../app/_components/sejour/SejourKit";
import {diagnosticRapportHref} from "./preparation";
import {journeyMesureMots, journeyStepSubtitle, journeyStepTitle} from "./journey";

/* ---------------------------------------------------------------- les routes
 * Le rapport d'une session close est `diagnosticRapportHref` (`preparation.ts`,
 * la seule autorité de l'adresse) ; ses deux sous-écrans s'y accrochent. */

/** La transition « Votre plan commence ici ». */
export function diagnosticTransitionHref(sessionId: string): string {
    return `${diagnosticRapportHref(sessionId)}/plan`;
}

/** « Revoir ma réponse ». */
export function diagnosticReponseHref(sessionId: string): string {
    return `${diagnosticRapportHref(sessionId)}/reponse`;
}

/* ================================================================ ÉCRAN 1 */

/** Le retour du rapport au sortir du tunnel : sans écran précédent, l'Accueil. */
export const DIAGNOSTIC_REPORT_BACK_HREF = "/dashboard";
export const DIAGNOSTIC_REPORT_KICKER = "Diagnostic rapide terminé";
/** 🛑 « Votre estimation », pas « Votre niveau TCF ». */
export const DIAGNOSTIC_REPORT_TITLE = "Votre estimation";

/**
 * 🛑 **Wording imposé** : « Niveau estimé **sur cet exercice** », jamais « votre
 * niveau TCF ». Trois épreuves sur quatre n'ont pas été mesurées.
 */
export const DIAGNOSTIC_LEVEL_EYEBROW = "Niveau estimé sur cet exercice";
export const DIAGNOSTIC_GOAL_LABEL = "Votre objectif";
/** Ce qu'on affiche à la place d'un niveau qui n'existe pas. */
export const DIAGNOSTIC_LEVEL_UNKNOWN = "—";
/** 🛑 « Rendue, rien à observer » ≠ « faible » : la pastille ne juge pas. */
export const DIAGNOSTIC_INCOMPLETE_TAG = "Évaluation incomplète";
export const DIAGNOSTIC_TRACK_YOU = "Vous";
export const DIAGNOSTIC_TRACK_GOAL = "Objectif";
export const DIAGNOSTIC_TRACK_CAPTION = "Votre progression vers l'objectif";

/** Les libellés des colonnes de la piste : celle du candidat devient
 *  « {N} · Vous », les autres gardent leur palier. */
export function diagnosticTrackLevels(track: {levels: readonly string[]; currentIndex: number}): string[] {
    return track.levels.map((lvl, i) => (i === track.currentIndex ? `${lvl} · ${DIAGNOSTIC_TRACK_YOU}` : lvl));
}

/**
 * **La phrase de situation**, sur `situationObjectif` SERVI. `null` (niveau ou
 * objectif inconnu) ⇒ aucune phrase : on ne devine pas un écart.
 */
export function diagnosticSituationPhrase(
    situation: SituationObjectif | null | undefined,
    objectif: string | null | undefined,
): string | null {
    if (!situation || !objectif) return null;
    switch (situation) {
        case "UN_PALIER_SOUS_OBJECTIF":
            return `Vous avez déjà les bases pour viser le niveau ${objectif}.`;
        case "PLUSIEURS_PALIERS_SOUS_OBJECTIF":
            return `Votre plan va vous faire progresser étape par étape vers le niveau ${objectif}.`;
        case "OBJECTIF_ATTEINT":
            return `Votre estimation atteint déjà votre objectif ${objectif} sur cet exercice.`;
    }
}

/** La phrase 1 de la synthèse, sur `written.communicationStatus` servi (AR-4). */
const COMMUNICATION_PHRASE: Record<DiagnosticCommunicationStatus, string> = {
    EFFECTIVE: "Votre production est claire et efficace.",
    PARTIAL: "Votre production transmet l'essentiel, avec encore quelques points à clarifier.",
    INEFFECTIVE: "Votre production reste encore difficile à suivre par endroits.",
};

/** Un intitulé de compétence repris au fil d'une phrase : initiale en minuscule. */
function auFilDeLaPhrase(titre: string): string {
    return titre.charAt(0).toLocaleLowerCase("fr-FR") + titre.slice(1);
}

/**
 * **La synthèse, composée sans IA** (AR-4) : la phrase de communication, puis
 * ce qui sépare de l'objectif — la priorité n°1 **du lot du Plan**. Le résumé
 * du correcteur (`summary`) n'est plus affiché.
 *
 * `inexploitable` (production `NON_EVALUABLE`) ⇒ pas de phrase 1. `null` quand
 * il n'y a rien à dire.
 */
export function diagnosticSynthese(
    result: DiagnosticResultDto | null,
    inexploitable: boolean,
): string | null {
    const status = result?.written?.communicationStatus ?? null;
    const phrase1 = !inexploitable && status ? COMMUNICATION_PHRASE[status] : null;
    const premiere = result?.planPriorities?.[0] ?? null;
    const objectif = result?.objectiveLevel ?? null;
    const phrase2 = !premiere
        ? null
        : objectif && result?.situationObjectif !== "OBJECTIF_ATTEINT"
            ? `Ce qui vous sépare principalement du ${objectif} : ${auFilDeLaPhrase(premiere.skillTitle)}.`
            : `Votre priorité principale : ${auFilDeLaPhrase(premiere.skillTitle)}.`;
    const phrases = [phrase1, phrase2].filter((p): p is string => p !== null);
    return phrases.length > 0 ? phrases.join(" ") : null;
}

/* --------------------------------------------- ce que nous avons observé */

export const DIAGNOSTIC_OBSERVE_TITLE = "Ce que nous avons observé";
/* Le kit les écrit en petites capitales (CSS) : le texte reste celui du mobile. */
export const DIAGNOSTIC_OBSERVE_STRENGTH = "Point fort";
export const DIAGNOSTIC_OBSERVE_PRIORITY = "Priorité";
/** Au plus un point fort (même source qu'avant le 2026-10-04). */
const DIAGNOSTIC_OBSERVE_MAX_POSITIVE = 1;

export interface ObservationLine {
    tone: "ok" | "up";
    kicker: string;
    title: string;
    text: string | null;
}

/**
 * Le point fort, puis **toutes** les priorités du lot du Plan — dans cet ordre.
 *
 * 🛑 **Rien n'est dérivé.** Le point fort est la première observation que le
 * serveur a marquée `SOLID` (repli : la première phrase de `strengths`, quand
 * il n'a nommé aucune compétence) ; les priorités sont `planPriorities`, dans
 * l'ordre servi, sans plafond. Aucun flou : un constat mesuré se montre.
 */
export function observationLines(result: DiagnosticResultDto | null): ObservationLine[] {
    const solide = (result?.written?.skills ?? []).find(
        (skill) => skill.observed && skill.status === "SOLID",
    );
    const positive: ObservationLine[] = solide
        ? [{
            tone: "ok",
            kicker: DIAGNOSTIC_OBSERVE_STRENGTH,
            title: solide.skillTitle,
            text: solide.explanation,
        }]
        : (result?.strengths ?? []).slice(0, DIAGNOSTIC_OBSERVE_MAX_POSITIVE).map((phrase) => ({
            tone: "ok" as const,
            kicker: DIAGNOSTIC_OBSERVE_STRENGTH,
            title: phrase,
            text: null,
        }));
    return [
        ...positive,
        ...(result?.planPriorities ?? []).map((priorite) => ({
            tone: "up" as const,
            kicker: DIAGNOSTIC_OBSERVE_PRIORITY,
            title: priorite.skillTitle,
            text: priorite.explanation,
        })),
    ];
}

/* ------------------------------------------------------- l'encart d'honnêteté */

export const DIAGNOSTIC_NOTE_TITLE = "Une première estimation, pas encore votre niveau TCF complet";
export const DIAGNOSTIC_NOTE_TEXT =
    "Votre niveau final dépend également de la compréhension orale, de la "
    + "compréhension écrite et de l'expression orale.";

export const DIAGNOSTIC_REPORT_PLAN_CTA = "Découvrir mon plan";
export const DIAGNOSTIC_REPORT_REPONSE_LINK = "Revoir ma réponse";

/* ================================================================ ÉCRAN 2 */

export const DIAGNOSTIC_TRANSITION_KICKER = "Votre diagnostic est analysé";
export const DIAGNOSTIC_TRANSITION_TITLE = "Votre plan commence ici";

export function diagnosticTransitionLead(objectif: string | null | undefined): string {
    return objectif
        ? `Nous avons transformé vos résultats en priorités concrètes pour vous rapprocher de votre objectif ${objectif}.`
        : "Nous avons transformé vos résultats en priorités concrètes pour vous faire progresser.";
}

/** « Vos 3 priorités identifiées » — le nombre est celui du lot, jamais un « 3 » en dur. */
export function diagnosticPrioritiesTitle(n: number): string {
    return n === 1 ? "Votre priorité identifiée" : `Vos ${n} priorités identifiées`;
}

export const DIAGNOSTIC_PRIORITIES_SUB = "À travailler pendant votre parcours";

/**
 * La pastille d'épreuve de la carte : le nom de l'épreuve **si toutes les
 * priorités sont de la même**, sinon aucune (un ancien lot peut mêler EE et EO).
 */
export function diagnosticPrioritiesPill(priorites: DiagnosticPlanPriorityDto[]): string | null {
    const section = priorites[0]?.section;
    if (!section || priorites.some((p) => p.section !== section)) return null;
    return SKILL_SECTION_LABEL[section];
}

/**
 * La note sous la liste, sur `inCurrentCycle` SERVI de la première priorité :
 * « déjà intégrées » seulement quand le lot est dans le cycle en cours.
 */
export function diagnosticPrioritiesNote(priorites: DiagnosticPlanPriorityDto[]): string | null {
    const premiere = priorites[0];
    if (!premiere) return null;
    const une = priorites.length === 1;
    if (premiere.inCurrentCycle) {
        return une ? "Elle est déjà intégrée à votre plan." : "Elles sont déjà intégrées à votre plan.";
    }
    return une
        ? "Elle rejoindra votre plan au prochain cycle."
        : "Elles rejoindront votre plan au prochain cycle.";
}

export const DIAGNOSTIC_BRIDGE_TITLE = "Et pour connaître votre niveau réel au TCF ?";
export const DIAGNOSTIC_BRIDGE_TEXT =
    "Votre plan vous fera passer un examen blanc dans chaque épreuve encore à mesurer.";

export const DIAGNOSTIC_EPREUVE_EVALUEE = "Évaluée";
export const DIAGNOSTIC_EPREUVE_A_MESURER = "À mesurer";

/** Les quatre épreuves du TCF IRN, dans l'ordre de l'examen (jamais `TCF_STRUCTURE`). */
const EPREUVES_TUILES: ReadonlyArray<{epreuve: PlanDomainDto["epreuve"]; code: "CO" | "CE" | "EE" | "EO"}> = [
    {epreuve: "TCF_CO", code: "CO"},
    {epreuve: "TCF_CE", code: "CE"},
    {epreuve: "TCF_EE", code: "EE"},
    {epreuve: "TCF_EO", code: "EO"},
];

/**
 * **Les quatre tuiles**, l'état lu sur `plan.domaines[].evaluated` SERVI
 * (`GET /api/me/plan`) — jamais sur `journey.blocs[].status` : un bloc
 * `EN_COURS` peut n'avoir jamais été mesuré. Plan pas chargé (`null`), ou
 * épreuve absente des domaines ⇒ **aucun état** : `null` = inconnu.
 */
export function diagnosticEpreuveTiles(domaines: PlanDomainDto[] | null): EpreuveTile[] {
    return EPREUVES_TUILES.map(({epreuve, code}) => {
        const evaluated = domaines?.find((d) => d.epreuve === epreuve)?.evaluated ?? null;
        return {
            code,
            name: SKILL_SECTION_LABEL[code],
            state: evaluated === null ? null : evaluated ? DIAGNOSTIC_EPREUVE_EVALUEE : DIAGNOSTIC_EPREUVE_A_MESURER,
            done: evaluated === true,
        };
    });
}

export const DIAGNOSTIC_NEXT_STEP_EYEBROW = "Votre prochaine étape";
export const DIAGNOSTIC_NEXT_STEP_TEXT =
    "Les prochaines évaluations viendront affiner votre plan progressivement.";

/**
 * **Le titre de « Votre prochaine étape »** : l'étape courante du parcours
 * (`journey.current`, servie), nommée comme le Plan la nomme. Un examen ⇒
 * « {épreuve} · {nature} », la nature étant « Mesurer mon niveau » sur un cycle
 * de mesure (`journeyMesureMots`), sinon « Examen blanc » ; une compétence ⇒ le
 * titre de l'étape. `null` = pas d'étape courante ⇒ la carte disparaît.
 */
export function diagnosticNextStepTitle(journey: JourneyDto | null): string | null {
    const etape = journey?.current ?? null;
    if (!etape) return null;
    const titre = journeyStepTitle(etape);
    if (etape.type !== "SECTION_EXAM") return titre;
    const nature = journeyMesureMots(journey, etape, "TCF")?.kind ?? journeyStepSubtitle(etape);
    return nature ? `${titre} · ${nature}` : titre;
}

export const DIAGNOSTIC_TRANSITION_PLAN_CTA = "Voir mon plan";
export const DIAGNOSTIC_BACK_TO_REPORT = "← Revenir au rapport";

/* ================================================================ ÉCRAN 3 */

export const DIAGNOSTIC_REPONSE_KICKER = "Diagnostic rapide";
export const DIAGNOSTIC_REPONSE_TITLE = "Votre réponse";
export const DIAGNOSTIC_REPONSE_SUBJECT = "Le sujet";
export const DIAGNOSTIC_REPONSE_TEXT_TITLE = "Votre réponse";
export const DIAGNOSTIC_REPONSE_ERROR = "Impossible de charger votre réponse.";

/* Les états communs aux trois écrans d'une session (chargement, porte). */
export const DIAGNOSTIC_RAPPORT_LOAD_ERROR = "Impossible de charger votre diagnostic.";
export const DIAGNOSTIC_RAPPORT_INDISPONIBLE =
    "Ce diagnostic n'a pas de rapport à relire pour l'instant.";

export function diagnosticReponseWords(n: number): string {
    return `${n} mot${n > 1 ? "s" : ""}`;
}
