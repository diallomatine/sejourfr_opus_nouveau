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
import {niveauCecrlShort, type NiveauCecrl} from "./types";

/**
 * **L'échelle de la piste de niveau** : les cinq paliers du TCF IRN, du plus
 * bas au plus haut, sous leur forme AFFICHÉE (`A1_NON_ATTEINT` ⇒ « <A1 »,
 * jamais « A1 »).
 *
 * 🛑 C'est une échelle d'affichage, pas de classement : rien ici ne décide d'un
 * niveau, on place des paliers déjà servis. Miroir mot pour mot de
 * `cecrlTrack` (`mobile_sejourfr/lib/core/utils/cecrl_track.dart`).
 */
const ECHELLE: readonly NiveauCecrl[] = ["A1_NON_ATTEINT", "A1", "A2", "B1", "B2"];

/** Le moins de colonnes qu'une piste montre, quand l'échelle le permet. */
const COLONNES_MIN = 3;

/**
 * Où poser « Vous » et « Objectif » sur la piste — **la règle unique**, servie
 * au rapport du diagnostic rapide et au héros de l'écran de déblocage du Plan.
 *
 * - `null` — **aucune piste** — si le niveau ou l'objectif manque, ou si l'un
 *   des deux sort de l'échelle (`C1`, `C2`) : mieux vaut rien qu'un candidat
 *   rabattu sur un palier qui n'est pas le sien.
 * - la fenêtre va d'**un palier sous le plus bas des deux** jusqu'au **plus
 *   haut**, puis s'étend **vers le bas** jusqu'à trois colonnes si l'échelle le
 *   permet : B1 → B2 ⇒ A2 · B1 · B2 ; B2 → B2 ⇒ A2 · B1 · B2 ; A1 → A2 ⇒
 *   <A1 · A1 · A2.
 *
 * Jamais de pourcentage : la piste situe deux paliers, elle ne mesure rien.
 */
export function levelTrackPosition(
    niveau: NiveauCecrl | null,
    cible: string | null,
): {levels: readonly string[]; currentIndex: number; goalIndex: number} | null {
    if (!niveau || !cible) return null;
    const courant = ECHELLE.indexOf(niveau);
    const vise = ECHELLE.indexOf(cible as NiveauCecrl);
    if (courant < 0 || vise < 0) return null;
    const fin = Math.max(courant, vise);
    let debut = Math.max(Math.min(courant, vise) - 1, 0);
    while (fin - debut + 1 < COLONNES_MIN && debut > 0) debut -= 1;
    return {
        levels: ECHELLE.slice(debut, fin + 1).map((n) => niveauCecrlShort(n)),
        currentIndex: courant - debut,
        goalIndex: vise - debut,
    };
}
