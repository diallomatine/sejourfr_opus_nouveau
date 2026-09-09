/**
 * **Le contrat de rendu du moteur de progression V4.2, côté web** (§25 bis).
 *
 * 🛑 **Le front ne calcule aucun état, aucun niveau CECRL, aucun seuil**
 * (invariant I42). Ce fichier ne contient donc **aucune comparaison de nombre**
 * — c'est le point : toute logique qui classerait un pourcentage en état
 * pédagogique serait une seconde copie du moteur, et deux copies d'une même
 * règle finissent toujours par désigner autre chose.
 *
 * Le serveur envoie `status`, `statusLabel`, `visibleProgress` et les booléens
 * dérivés. Il n'envoie **jamais** `masteryScore`, `confidence` ni les
 * accumulateurs epoch : ces valeurs sont internes au moteur et n'existent que
 * pour la console admin et le journal de prédictions.
 */

/** Les six états de §13. Une UI qui n'en gère que quatre est non conforme. */
export type ProgressionStatus =
    | "NOT_EVALUATED"
    | "FRAGILE"
    | "PROGRESSING"
    | "READY_FOR_REASSESSMENT"
    | "SOLID"
    | "WATCH";

/** Le ton visuel — dérivé de l'état, jamais d'un nombre. */
export type ProgressionTone =
    | "neutral" | "danger" | "primary" | "accent" | "success" | "warn";

/**
 * Libellés FR de repli — contrat gelé, à recopier au caractère près côté
 * mobile. Le libellé **servi** (`statusLabel`) fait foi ; celui-ci ne couvre
 * qu'un rendu sans réponse serveur.
 */
export const PROGRESSION_STATUS_LABEL: Record<ProgressionStatus, string> = {
    NOT_EVALUATED: "À évaluer",
    FRAGILE: "À renforcer",
    PROGRESSING: "En progression",
    READY_FOR_REASSESSMENT: "Prêt à vérifier",
    SOLID: "Acquis",
    WATCH: "À vérifier",
};

/**
 * Ton visuel par état. Rappel charte : le rouge ne sert qu'aux CTA critiques et
 * aux signaux d'urgence — seul `FRAGILE` le prend.
 */
export const PROGRESSION_STATUS_TONE: Record<ProgressionStatus, ProgressionTone> = {
    NOT_EVALUATED: "neutral",
    FRAGILE: "danger",
    PROGRESSING: "primary",
    READY_FOR_REASSESSMENT: "accent",
    SOLID: "success",
    WATCH: "warn",
};

/**
 * **Le nom du pourcentage, à ne jamais reformuler.**
 *
 * Il ne doit jamais être présenté comme un score TCF, un niveau CECRL ou une
 * probabilité de réussite (§25). Et il ne partage jamais un bloc visuel avec un
 * libellé de niveau CECRL (invariant I44) : un pourcentage accolé à un niveau
 * se lit comme un score officiel.
 */
export const PROGRESSION_PROGRESS_LABEL = "Progression du parcours";

/**
 * L'état d'une clé, tel que le serveur le sert (§25 bis.2).
 *
 * `visibleProgress` vaut `null` pour un palier sans la moindre preuve directe
 * (§18.6) — **jamais 0**. `null` veut dire « jamais mesuré », et le front
 * n'affiche alors aucun pourcentage, seulement l'état textuel.
 */
export interface ProgressionStateDto {
    stateKey: string;
    stateType: "RECEPTIVE_LEVEL" | "PRODUCTIVE_SKILL";
    status: ProgressionStatus;
    statusLabel: string;
    visibleProgress: number | null;
    directQualification: boolean;
    prerequisiteSatisfied: boolean;
    prerequisiteSatisfiedByLevel: "A2" | "B1" | "B2" | null;
    levelCycleId: string;
}

/**
 * Le libellé d'un palier acquis par prérequis : « Validé via B1 » (§18.5).
 * Le pourcentage de ce palier reste masqué — ce n'est pas un score TCF.
 */
export function prerequisiteLabel(state: ProgressionStateDto): string | null {
    return state.prerequisiteSatisfiedByLevel
        ? `Validé via ${state.prerequisiteSatisfiedByLevel}`
        : null;
}
