/**
 * **Profondeur de l'historique INTERNE de l'onglet** — de quoi savoir si
 * `router.back()` ramène à l'écran précédent de SejourFR ou sort du site.
 *
 * `window.history.length` ne suffit pas : il compte aussi les pages visitées
 * AVANT d'arriver sur le site (moteur de recherche, e-mail, Stripe). On tient
 * donc un compteur par onglet (`sessionStorage`) :
 *
 * - une navigation client vers un autre chemin ⇒ +1 ;
 * - un `popstate` (bouton précédent du navigateur, `router.back()`) ⇒ −1 ;
 * - un repli par `router.replace` (`skipNextNavigation`) ⇒ inchangé.
 *
 * ⚠️ Un « suivant » du navigateur déclenche aussi `popstate` et décrémente :
 * le compteur sous-estime alors, et le retour retombe sur l'adresse parente —
 * l'erreur est toujours du côté sûr (jamais de sortie du site).
 *
 * Posé par `NavHistoryTracker` (layout racine), lu par `retourOuRepli`.
 */

const KEY = "sf:nav-depth";

let lastPath: string | null = null;
let popPending = false;
let skipNext = false;

function readDepth(): number {
  try {
    return Number(window.sessionStorage.getItem(KEY)) || 0;
  } catch {
    return 0;
  }
}

function writeDepth(n: number): void {
  try {
    window.sessionStorage.setItem(KEY, String(Math.max(0, n)));
  } catch {
    /* stockage indisponible (navigation privée) : repli sur l'adresse parente */
  }
}

/** `popstate` : le prochain changement de chemin est un retour, pas un aller. */
export function notePopState(): void {
  if (window.location.pathname !== lastPath) popPending = true;
}

/** Le prochain changement de chemin remplace l'entrée courante (repli). */
export function skipNextNavigation(): void {
  skipNext = true;
}

/** Appelé à chaque changement de `pathname` (1ᵉʳ rendu compris). */
export function recordPath(path: string): void {
  if (lastPath === null) {
    lastPath = path;
    return;
  }
  if (path === lastPath) return;
  lastPath = path;
  if (popPending) {
    popPending = false;
    skipNext = false;
    writeDepth(readDepth() - 1);
    return;
  }
  if (skipNext) {
    skipNext = false;
    return;
  }
  writeDepth(readDepth() + 1);
}

/** Vrai quand l'entrée précédente de l'onglet est un écran de SejourFR. */
export function hasInAppHistory(): boolean {
  if (typeof window === "undefined") return false;
  return readDepth() > 0 && window.history.length > 1;
}
