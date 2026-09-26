/**
 * Ce qui reste des règles d'affichage du diagnostic TCF 4 épreuves — **pures**.
 *
 * 🛑 **Le PARCOURS du diagnostic complet est retiré des fronts depuis le
 * 2026-09-26** (décision du propriétaire) : plus de hub, plus d'écran de
 * section, plus d'écran de résultat. Les épreuves que le diagnostic rapide ne
 * mesure pas se mesurent par l'**examen blanc** que propose le Plan. Ne pas
 * recréer ces écrans.
 *
 * Ne subsiste ici que ce que lisent encore des écrans vivants :
 * - la piste de niveau (`levelTrackPosition`), partagée avec le rapport du
 *   diagnostic rapide ;
 * - les libellés de priorité de l'écran de déblocage du Plan
 *   (`PlanUnlockScreen`), qui relit un résultat de complet **déjà obtenu**.
 *
 * Miroir : `mobile_sejourfr/lib/screens/diagnostic_tcf/tcf_diagnostic_labels.dart`.
 * Aucun état pédagogique n'est dérivé ici : les paliers arrivent servis.
 */
import type {NiveauCecrl} from "./types";

/**
 * Les trois paliers de la piste de niveau du kit (`LevelTrack`).
 *
 * 🛑 C'est l'échelle du TCF IRN telle qu'elle est **affichée**, pas une échelle
 * de classement : rien ici ne décide d'un niveau, on place un palier déjà servi.
 */
const NIVEAU_TRACK: readonly string[] = ["A2", "B1", "B2"];

/** Le palier sur l'échelle affichée, ou `null` s'il en sort (A1, C1…). */
function railLevel(niveau: NiveauCecrl | null): "A2" | "B1" | "B2" | null {
    switch (niveau) {
        case "A2":
        case "B1":
        case "B2":
            return niveau;
        default:
            return null;
    }
}

/**
 * Où poser « Vous » et « Objectif » sur la piste.
 *
 * `null` — donc **aucune piste dessinée** — dès que l'un des deux paliers sort
 * de l'échelle A2/B1/B2 (`A1`, `A1_NON_ATTEINT`, `C1`, `C2`, ou aucun objectif
 * déclaré) : on préfère ne rien montrer plutôt que de rabattre le candidat sur
 * un palier qui n'est pas le sien.
 */
export function levelTrackPosition(
    niveau: NiveauCecrl | null,
    cible: string | null,
): {levels: readonly string[]; currentIndex: number; goalIndex: number} | null {
    const current = railLevel(niveau);
    if (!current || !cible) return null;
    const goalIndex = NIVEAU_TRACK.indexOf(cible);
    if (goalIndex < 0) return null;
    return {levels: NIVEAU_TRACK, currentIndex: NIVEAU_TRACK.indexOf(current), goalIndex};
}

/** « Expression orale — Tâche 3 ». La tâche est nommée, jamais la compétence. */
export function prioriteLibelle(epreuveLabel: string, taskCode: string | null): string {
    return taskCode ? `${epreuveLabel} — Tâche ${taskCode.slice(-1)}` : epreuveLabel;
}

/** Le ton d'une mention. `hot` = ce qui bloque le plus. */
export type EpreuveMentionTone = "ok" | "warn" | "hot";

export interface EpreuveMention {
    label: string;
    tone: EpreuveMentionTone;
}

/** La pastille d'une ligne du mini-plan : le rang 1 est le seul « Prioritaire ». */
export function prioritePastille(rang: number): EpreuveMention {
    return rang === 1
        ? {label: "Prioritaire", tone: "hot"}
        : {label: "À renforcer", tone: "warn"};
}
