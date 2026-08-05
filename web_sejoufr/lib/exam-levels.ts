// Règles de LECTURE des niveaux et des états d'un examen à plusieurs épreuves —
// bilan de l'examen blanc TCF complet (`/examens-blancs/tcf/[id]/bilan`), hub de
// progression et carte « Votre niveau par épreuve » du rapport d'examen.
//
// Volontairement pures et sans dépendance React : ce sont elles qui décident ce
// que l'écran ose affirmer (quelle teinte pour un palier, quelle épreuve tire le
// résultat vers le bas, ce qui tourne encore et ce qui est mort), et elles
// doivent être testables seules.
//
// Miroir mobile : `mobile_sejourfr/lib/screens/tcf_full_exam/tcf_full_exam_bilan_screen.dart`.

import {tcfNiveauTone, type TcfNoteTone} from "./production-feedback.ts";
import type {
    FullTcfExamResponse,
    FullTcfExamStatus,
    FullTcfExamSubAttempt,
    NiveauCecrl,
} from "./types.ts";

// ---------------------------------------------------------------------------
// Teinte d'un palier
// ---------------------------------------------------------------------------

/**
 * Teinte d'un niveau d'épreuve. Dérivée du **palier CECRL** et de rien d'autre,
 * via l'unique table `tcfNiveauTone` — il n'existe pas de seconde table.
 *
 * **Aucun niveau ne produit du rouge** : le Rouge France est réservé aux CTA
 * critiques, et un palier atteint n'est jamais une faute. L'ancien test
 * « niveau == plancher ⇒ rouge » peignait les quatre épreuves d'un candidat B2
 * en signal d'échec.
 *
 * `"neutral"` quand il n'y a pas (encore) de niveau à teinter — une épreuve non
 * évaluée, ou verrouillée, est grise.
 */
export function epreuveLevelTone(niveau: NiveauCecrl | null | undefined): TcfNoteTone {
    return niveau == null ? "neutral" : tcfNiveauTone(niveau);
}

/**
 * Quelles épreuves signaler comme « niveau retenu » (celles qui tirent le
 * résultat global vers le bas), par une **mention textuelle** — jamais par la
 * couleur.
 *
 * Le repère n'est informatif que s'il distingue : quand toutes les épreuves
 * partagent le même palier, il n'y a pas de point faible à désigner et on ne
 * marque rien. C'est exactement le cas qui rendait l'ancien badge absurde.
 */
export function floorMarks(
    levels: readonly (NiveauCecrl | null | undefined)[],
    floor: NiveauCecrl | null | undefined,
): boolean[] {
    const informative =
        floor != null && levels.some((l) => l != null && l !== floor);
    return levels.map((l) => informative && l === floor);
}

// ---------------------------------------------------------------------------
// La phrase de la règle du plancher
// ---------------------------------------------------------------------------

/** Périmètre réel du niveau plancher, tel que le serveur le publie. */
export interface FloorScope {
    /** Épreuves qui portent un niveau et entrent vraiment dans le plancher.
     *  `null` = le serveur ne l'a pas dit (réponse d'un backend antérieur). */
    counted: number | null;
    /** Épreuves attendues dans un examen complet (4). `null` si non publié. */
    expected: number | null;
    /** Le plancher ne porte pas sur toutes les épreuves : bilan **partiel**. */
    partial: boolean;
}

/** Champs du contrat backend (`FullTcfExamResponse`) qui décrivent le périmètre.
 *  `Partial` volontaire : une réponse d'un backend antérieur ne les porte pas,
 *  et on préfère alors ne rien affirmer plutôt que de supposer un décompte. */
type FloorScopeSource = Partial<
    Pick<
        FullTcfExamResponse,
        "epreuvesCountedInFinalLevel" | "epreuvesExpected" | "finalLevelPartial"
    >
>;

/**
 * Sur combien d'épreuves porte réellement `finalCecrlLevel`.
 *
 * Une épreuve verrouillée par le freemium ou dont les évaluations ont échoué
 * n'entre pas dans le plancher : affirmer « le plus bas de tes 4 épreuves »
 * serait faux — c'est précisément ce que ces champs servent à corriger.
 */
export function floorScope(exam: FloorScopeSource): FloorScope {
    const counted = exam.epreuvesCountedInFinalLevel;
    const expected = exam.epreuvesExpected;
    return {
        counted: Number.isFinite(counted) && (counted as number) > 0 ? (counted as number) : null,
        expected: Number.isFinite(expected) && (expected as number) > 0 ? (expected as number) : null,
        partial: exam.finalLevelPartial === true,
    };
}

/** La règle du plancher, dite exactement — jamais un décompte supposé. */
export function floorRuleSentence(scope: FloorScope): string {
    const tail = "Fais monter ton épreuve la plus faible pour faire monter l'ensemble.";
    const {counted, expected, partial} = scope;

    if (counted == null) {
        // Aucun chiffre : on ne sait pas sur quoi porte le plancher.
        return (
            "Ton niveau correspond à ta plus faible épreuve prise en compte : il n'y " +
            `a ni moyenne ni compensation. ${tail}`
        );
    }
    if (partial) {
        const sur = expected != null ? ` sur ${expected}` : "";
        if (counted === 1) {
            return (
                `Bilan partiel : une seule épreuve${sur} a pu être prise en compte, ton ` +
                "niveau est le sien. Ce n'est pas le résultat d'un examen complet."
            );
        }
        return (
            `Bilan partiel : ton niveau correspond au plus bas de ${counted} épreuves` +
            `${sur} — les autres n'ont pas pu être prises en compte. Ce n'est pas le ` +
            "résultat d'un examen complet."
        );
    }
    if (counted === 1) {
        return "Une seule épreuve a été prise en compte : ton niveau est le sien.";
    }
    return (
        `Ton niveau correspond au plus bas de tes ${counted} épreuves : il n'y a ni ` +
        `moyenne ni compensation. ${tail}`
    );
}

/**
 * Un bilan partiel n'est pas un résultat d'examen complet : il ne doit alimenter
 * ni « Meilleur niveau », ni « Dernier examen », ni passer pour une réussite
 * dans la grille des slots. Le niveau d'un examen amputé de son EE/EO
 * verrouillée se lirait sinon comme un vrai résultat.
 */
export function isCompleteExamResult(
    exam: {status: FullTcfExamStatus; finalLevelPartial?: boolean},
): boolean {
    return exam.status === "COMPLETED" && exam.finalLevelPartial !== true;
}

// ---------------------------------------------------------------------------
// Ce qui tourne encore, et ce qui est mort
// ---------------------------------------------------------------------------

/**
 * Au-delà de ce délai après la finalisation de l'examen, une évaluation qui
 * n'est pas revenue ne reviendra pas (jamais dépilée par l'`@Async`, ou
 * exception silencieuse). Continuer à faire tourner un spinner serait mentir.
 * Même seuil que le mobile (`_staleThreshold`).
 */
export const EXAM_STALE_THRESHOLD_MS = 2 * 60 * 1_000;

/** Examen finalisé depuis trop longtemps sans être `COMPLETED` : plus rien ne
 *  tourne derrière, il faut couper le spinner et proposer une relance. */
export function examIsStale(
    exam: Pick<FullTcfExamResponse, "status" | "finishedAt">,
    now: number = Date.now(),
): boolean {
    if (exam.status === "COMPLETED") return false;
    if (!exam.finishedAt) return false;
    const finished = new Date(exam.finishedAt).getTime();
    if (Number.isNaN(finished)) return false;
    return now - finished > EXAM_STALE_THRESHOLD_MS;
}

/** Nombre de tâches d'une épreuve d'expression (T1/T2/T3). */
const PRODUCTION_TASKS = 3;

export type SubAttemptState =
    /** Freemium : épreuve non passée, réservée à l'abonnement. Aucun niveau. */
    | "locked"
    /** Pas de `finishedAt` : l'épreuve n'a pas été terminée. */
    | "not_started"
    /** Niveau connu. */
    | "evaluated"
    /** Terminée, l'IA travaille encore. */
    | "evaluating"
    /** Terminée, au moins une évaluation en échec : relance possible. */
    | "failed"
    /** Terminée, en attente, mais plus rien ne tourne : relance manuelle. */
    | "stalled";

export interface SubAttemptView {
    state: SubAttemptState;
    /** Niveau à afficher. **Toujours `null` sur une épreuve verrouillée** : elle
     *  n'a pas été passée et ne doit surtout pas se lire « A1 non atteint ». */
    level: NiveauCecrl | null;
    tone: TcfNoteTone;
    /** Évaluations IA en échec, à relancer (`failedSubmissionIds`). */
    failedSubmissionIds: readonly string[];
    /** Un spinner ne tourne que si quelque chose tourne vraiment derrière. */
    showSpinner: boolean;
    subtitle: string;
}

/**
 * Tout ce que la carte d'une épreuve a le droit d'affirmer, en une passe.
 *
 * L'ancien calcul (`finishedAt && !evaluated ⇒ en cours`) rangeait les
 * évaluations **en échec** dans « en cours » : l'écran affichait un spinner et
 * « … » indéfiniment, sans issue.
 */
export function subAttemptView(
    sa: FullTcfExamSubAttempt,
    opts: {stale: boolean} = {stale: false},
): SubAttemptView {
    if (sa.locked) {
        return {
            state: "locked",
            level: null,
            tone: "neutral",
            failedSubmissionIds: [],
            showSpinner: false,
            subtitle: "Réservé à l'abonnement Intégral",
        };
    }

    const failed = sa.failedSubmissionIds ?? [];
    const level = sa.cecrlLevel;
    const state: SubAttemptState = !sa.finishedAt
        ? "not_started"
        : level != null
          ? "evaluated"
          : failed.length > 0
            ? "failed"
            : opts.stale
              ? "stalled"
              : "evaluating";

    return {
        state,
        level,
        tone: epreuveLevelTone(level),
        failedSubmissionIds: failed,
        showSpinner: state === "evaluating",
        subtitle: subAttemptSubtitle(sa, state),
    };
}

function subAttemptSubtitle(sa: FullTcfExamSubAttempt, state: SubAttemptState): string {
    if (state === "not_started") return "Non terminée";
    if (sa.score != null && sa.maxScore != null) return `Score ${sa.score}/${sa.maxScore}`;

    const ko = (sa.failedSubmissionIds ?? []).length;
    const ok = sa.submissionsCount ?? 0;
    if (sa.submissionsCount != null || ko > 0) {
        const waiting = PRODUCTION_TASKS - ok - ko;
        if (waiting > 0) {
            // « en cours » quand le pipeline tourne, « en attente » quand plus
            // rien ne bouge : le sous-titre ne doit pas contredire le badge. Un
            // échec déjà constaté se dit, même s'il reste une tâche en vol.
            const qualifier = state === "evaluating" ? "en cours" : "en attente";
            const echec = ko > 0 ? ` · ${ko} en échec` : "";
            return `${ok}/3 évaluées · ${waiting} ${qualifier}${echec}`;
        }
        if (ko > 0 && ok === 0) return `${ko} évaluation${ko > 1 ? "s" : ""} en échec`;
        if (ko > 0) return `${ok}/3 réussies · ${ko} à relancer`;
        return "3 productions évaluées";
    }

    if (state === "evaluating") return "Évaluation en cours…";
    if (state === "failed") return "Évaluation en échec";
    if (state === "stalled") return "Évaluation interrompue";
    return "Terminée";
}
