/**
 * Ce qui reste des règles d'affichage du diagnostic TCF 4 épreuves — **pures**.
 *
 * 🛑 **Le PARCOURS du diagnostic complet est retiré des fronts depuis le
 * 2026-09-26** (décision du propriétaire) : plus de hub, plus d'écran de
 * section, plus d'écran de résultat. Les épreuves que le diagnostic rapide ne
 * mesure pas se mesurent par l'**examen blanc** que propose le Plan. Ne pas
 * recréer ces écrans.
 *
 * Ne subsiste ici que la piste de niveau (`levelTrackPosition`), partagée
 * entre le rapport du diagnostic rapide et le héros de l'écran de déblocage
 * du Plan (qui relit un résultat de complet **déjà obtenu**).
 *
 * ⚠️ `prioriteLibelle` / `prioritePastille` sont SUPPRIMÉES (2026-09-26) avec
 * leur dernier lecteur : l'écran de déblocage range désormais ses priorités
 * par épreuve, lues sur le Plan. Leur miroir Dart est supprimé dans la même
 * passe. Aucun état pédagogique n'est dérivé ici : les paliers arrivent servis.
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
