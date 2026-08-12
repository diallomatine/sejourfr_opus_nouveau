"use client";

import {useEffect} from "react";

/**
 * Maintient l'écran allumé tant que [active] vaut `true` (Screen Wake Lock API).
 *
 * **Déclaratif, pas impératif** : un enregistrement qui se termine par un
 * démontage (soumission, navigation, chrono d'épreuve à 0:00) relâche le verrou
 * par le nettoyage du `useEffect` — il n'existe aucun chemin où un `release()`
 * manqué laisserait l'écran allumé.
 *
 * Deux invariants à ne pas casser :
 * - **dégradation silencieuse** : l'API n'existe ni sur Firefox ni sur Safari
 *   iOS < 16.4, et `request()` échoue légitimement (onglet caché, batterie
 *   faible, politique de l'OS). Rien ne remonte à l'UI : un verrou perdu est un
 *   confort perdu, jamais un enregistrement cassé.
 * - **ré-acquisition sur `visibilitychange`** : le navigateur relâche le verrou
 *   dès que l'onglet passe en arrière-plan. Sans ce ré-armement, revenir sur
 *   l'onglet reprendrait l'enregistrement avec un écran qui s'éteint.
 */
export function useScreenWakeLock(active: boolean): void {
  useEffect(() => {
    if (!active) return;
    if (typeof navigator === "undefined" || typeof document === "undefined") return;
    const api = navigator.wakeLock;
    if (!api) return;

    let cancelled = false;
    let sentinel: WakeLockSentinel | null = null;

    // Le navigateur relâche de son côté (onglet caché, veille système) : on
    // oublie la sentinelle pour pouvoir en redemander une au retour.
    const onRelease = () => {
      sentinel = null;
    };

    const request = async () => {
      if (cancelled || sentinel) return;
      if (document.visibilityState !== "visible") return;
      try {
        const next = await api.request("screen");
        if (cancelled) {
          void next.release().catch(() => undefined);
          return;
        }
        sentinel = next;
        next.addEventListener("release", onRelease);
      } catch {
        // Refus normal (onglet caché entre-temps, politique navigateur) : on
        // réessaiera au prochain retour de visibilité.
      }
    };

    const onVisibility = () => {
      if (document.visibilityState === "visible") void request();
    };

    void request();
    document.addEventListener("visibilitychange", onVisibility);

    return () => {
      cancelled = true;
      document.removeEventListener("visibilitychange", onVisibility);
      const held = sentinel;
      sentinel = null;
      if (!held) return;
      held.removeEventListener("release", onRelease);
      void held.release().catch(() => undefined);
    };
  }, [active]);
}
