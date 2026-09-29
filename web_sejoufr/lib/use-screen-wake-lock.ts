"use client";

import {useEffect} from "react";
import {holdScreenWakeLock} from "./wake-lock";

/**
 * Maintient l'écran allumé tant que [active] vaut `true` (Screen Wake Lock API).
 *
 * **Déclaratif, pas impératif** : un enregistrement qui se termine par un
 * démontage (soumission, navigation, chrono d'épreuve à 0:00) relâche le verrou
 * par le nettoyage du `useEffect` — il n'existe aucun chemin où un `release()`
 * manqué laisserait l'écran allumé. Dégradation silencieuse et ré-acquisition
 * au retour de visibilité : `lib/wake-lock.ts`.
 */
export function useScreenWakeLock(active: boolean): void {
  useEffect(() => {
    if (!active) return;
    return holdScreenWakeLock();
  }, [active]);
}
