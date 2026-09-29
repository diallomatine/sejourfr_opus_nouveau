/**
 * Maintien de l'écran allumé (Screen Wake Lock API), **sans React** : la seule
 * implémentation du dépôt. `useScreenWakeLock` (enregistrement EO, temps réel)
 * et l'élément audio partagé de la CO (`lib/co-audio.ts`) passent par elle.
 *
 * `holdScreenWakeLock()` demande le verrou et rend la fonction qui le relâche.
 *
 * Deux invariants à ne pas casser :
 * - **dégradation silencieuse** : l'API n'existe ni sur Firefox ni sur Safari
 *   iOS < 16.4, ni hors contexte sécurisé (HTTPS ou localhost — donc pas sur
 *   `http://192.168.x.x` en test local), et `request()` échoue légitimement
 *   (onglet caché, batterie faible, politique de l'OS). Rien ne remonte à
 *   l'UI : un verrou perdu est un confort perdu, jamais une écoute cassée.
 * - **ré-acquisition sur `visibilitychange`** : le navigateur relâche le verrou
 *   dès que l'onglet passe en arrière-plan. Sans ce ré-armement, revenir sur
 *   l'onglet reprendrait l'écoute avec un écran qui s'éteint.
 */
export function holdScreenWakeLock(): () => void {
  if (typeof navigator === "undefined" || typeof document === "undefined") {
    return () => undefined;
  }
  const api = navigator.wakeLock;
  if (!api) return () => undefined;

  let released = false;
  let sentinel: WakeLockSentinel | null = null;

  // Le navigateur relâche de son côté (onglet caché, veille système) : on
  // oublie la sentinelle pour pouvoir en redemander une au retour.
  const onRelease = () => {
    sentinel = null;
  };

  const request = async () => {
    if (released || sentinel) return;
    if (document.visibilityState !== "visible") return;
    try {
      const next = await api.request("screen");
      if (released) {
        void next.release().catch(() => undefined);
        return;
      }
      sentinel = next;
      next.addEventListener("release", onRelease);
    } catch {
      // Refus normal : on réessaiera au prochain retour de visibilité.
    }
  };

  const onVisibility = () => {
    if (document.visibilityState === "visible") void request();
  };

  void request();
  document.addEventListener("visibilitychange", onVisibility);

  return () => {
    if (released) return;
    released = true;
    document.removeEventListener("visibilitychange", onVisibility);
    const held = sentinel;
    sentinel = null;
    if (!held) return;
    held.removeEventListener("release", onRelease);
    void held.release().catch(() => undefined);
  };
}
