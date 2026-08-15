import type {EpreuveType, FullTcfExamResponse, FullTcfExamSubAttempt} from "./types";

/**
 * Sortir d'un examen blanc TCF complet — la règle et ses libellés, déclarés
 * **une seule fois** pour tout le web.
 *
 * > **Une épreuve COMMENCÉE ne se reprend jamais. Une épreuve JAMAIS COMMENCÉE
 * > attend le candidat aussi longtemps qu'il faut.**
 *
 * Deux conséquences, appliquées partout de la même façon :
 * - **suspendre** un examen depuis son hub clôture sur-le-champ l'épreuve
 *   commencée (s'il y en a une) et **épargne** celles qui n'ont jamais été
 *   ouvertes — l'examen reste « en cours », sans résultat, indéfiniment
 *   reprenable ;
 * - **quitter une épreuve** en cours la clôture aussi, avec ce qui a déjà été
 *   fait.
 *
 * Aucun de ces gestes ne finalise l'examen ni n'ouvre le bilan : **il n'y a pas
 * de résultat tant que les 4 épreuves ne sont pas terminées.**
 *
 * Miroir mot pour mot du mobile :
 * `mobile_sejourfr/lib/screens/tcf_full_exam/full_exam_exit_labels.dart`.
 */

/** « Commencée » = le serveur a posé l'ancre du chrono au `POST /begin`. C'est
 *  le même discriminant que l'état `not_taken` de `subAttemptView`. */
export function epreuveCommencee(sa: FullTcfExamSubAttempt): boolean {
    return sa.timerStartedAt != null;
}

/**
 * Les épreuves que « suspendre » va clôturer : commencées et pas encore
 * terminées. Les autres ne sont **jamais** touchées par un geste de sortie.
 *
 * En pratique il y en a au plus une (le hub ne laisse démarrer que l'épreuve
 * courante), mais rien n'oblige le serveur à le garantir : on raisonne en liste.
 */
export function epreuvesAClore(
    exam: Pick<FullTcfExamResponse, "subAttempts">,
): FullTcfExamSubAttempt[] {
    return exam.subAttempts.filter((sa) => !sa.finishedAt && epreuveCommencee(sa));
}

/** Le nom d'une épreuve **avec son article**, pour l'insérer dans une phrase. */
const EPREUVE_AVEC_ARTICLE: Partial<Record<EpreuveType, string>> = {
    TCF_CO: "la compréhension orale",
    TCF_CE: "la compréhension écrite",
    TCF_EE: "l'expression écrite",
    TCF_EO: "l'expression orale",
};

/** Épreuve inconnue ⇒ « cette épreuve » : on ne devine jamais un nom. */
export function epreuveAvecArticle(epreuve: EpreuveType | null | undefined): string {
    return (epreuve && EPREUVE_AVEC_ARTICLE[epreuve]) ?? "cette épreuve";
}

function capitalize(phrase: string): string {
    return phrase.charAt(0).toUpperCase() + phrase.slice(1);
}

/** « la compréhension orale et l'expression écrite ». */
function enumerer(phrases: readonly string[]): string {
    if (phrases.length <= 1) return phrases[0] ?? "";
    return `${phrases.slice(0, -1).join(", ")} et ${phrases[phrases.length - 1]}`;
}

// ---------------------------------------------------------------------------
// Suspendre l'examen (hub de progression)
// ---------------------------------------------------------------------------

export const FULL_EXAM_SUSPEND_TITLE = "Suspendre l'examen ?";
export const FULL_EXAM_SUSPEND_CONFIRM = "Suspendre et reprendre plus tard";
export const FULL_EXAM_SUSPEND_CANCEL = "Continuer l'examen";

/**
 * Ce que la suspension va coûter, **épreuve par épreuve**, dit avant l'action.
 *
 * Sans épreuve commencée, il n'y a rien à perdre : on ne fait pas peur pour
 * rien.
 */
export function fullExamSuspendMessage(aClore: readonly FullTcfExamSubAttempt[]): string {
    if (aClore.length === 0) {
        return (
            "Votre progression est conservée : aucune épreuve n'est commencée, " +
            "et vous reprendrez cet examen là où vous en êtes."
        );
    }
    const noms = enumerer(aClore.map((sa) => epreuveAvecArticle(sa.epreuve)));
    const suite =
        aClore.length === 1
            ? `${capitalize(noms)} est déjà commencée : elle sera clôturée maintenant, ` +
              "avec ce que vous avez déjà fait, et ne pourra plus être reprise."
            : `${capitalize(noms)} sont déjà commencées : elles seront clôturées ` +
              "maintenant, avec ce que vous avez déjà fait, et ne pourront plus être reprises.";
    return `Vous reprendrez aux épreuves que vous n'avez pas encore commencées. ${suite}`;
}

// ---------------------------------------------------------------------------
// Quitter une épreuve en cours (runner CO/CE, session EE/EO)
// ---------------------------------------------------------------------------

export const EPREUVE_EXIT_TITLE = "Quitter cette épreuve ?";
export const EPREUVE_EXIT_CONFIRM = "Quitter et clôturer l'épreuve";
export const EPREUVE_EXIT_CANCEL = "Continuer l'épreuve";

/**
 * `perteEnregistrement` : l'oral seulement — une capture en cours n'est jamais
 * envoyée, et le taire serait mentir.
 */
export function epreuveExitMessage(
    epreuve: EpreuveType | null | undefined,
    opts: {perteEnregistrement?: boolean} = {},
): string {
    const perte = opts.perteEnregistrement ? " Votre enregistrement en cours sera perdu." : "";
    return (
        `${capitalize(epreuveAvecArticle(epreuve))} sera clôturée maintenant, avec ce que ` +
        `vous avez déjà fait, et ne pourra plus être reprise.${perte} ` +
        "Les épreuves suivantes, elles, vous attendent."
    );
}
