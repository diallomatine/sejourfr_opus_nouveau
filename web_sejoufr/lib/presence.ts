import {presenceApi, tokenStorage} from "./api";

/**
 * Battement de présence d'un compte connecté (chantier « Activité », D1-D3) —
 * le seul du web. Miroir : `mobile_sejourfr/lib/core/presence/presence_heartbeat.dart`.
 *
 * - **Premier plan uniquement** : un battement immédiat quand l'onglet devient
 *   visible, puis toutes les 60 s ; arrêt dès qu'il est caché (`visibilitychange`,
 *   `pagehide`).
 * - **Compte connecté uniquement** : armé par `ActivityTracker` quand
 *   l'authentification est établie, et chaque battement vérifie encore qu'un
 *   jeton existe.
 * - **Best-effort** : un échec est silencieux et n'est jamais rejoué. Le
 *   rafraîchissement de jeton est celui de tout appel (`apiFetch`), jamais
 *   déclenché exprès ; un 401 définitif ne fait pas quitter la page.
 *
 * Rien n'est écrit sur le terminal.
 */

const PERIOD_MS = 60_000;

let armed = false;
let timer: ReturnType<typeof setInterval> | null = null;

function visible(): boolean {
  return document.visibilityState === "visible";
}

function beat(): void {
  if (!tokenStorage.getAccess()) return;
  presenceApi.beat().catch(() => undefined);
}

function resume(): void {
  if (timer !== null || !armed || !visible()) return;
  beat();
  timer = setInterval(beat, PERIOD_MS);
}

function pause(): void {
  if (timer === null) return;
  clearInterval(timer);
  timer = null;
}

function onVisibilityChange(): void {
  if (visible()) resume();
  else pause();
}

/** Arme le battement (compte connecté). Idempotent. */
export function startPresence(): void {
  if (typeof window === "undefined" || armed) return;
  armed = true;
  document.addEventListener("visibilitychange", onVisibilityChange);
  window.addEventListener("pagehide", pause);
  window.addEventListener("pageshow", onVisibilityChange);
  resume();
}

/** Désarme le battement (déconnexion, compte invité). Idempotent. */
export function stopPresence(): void {
  if (typeof window === "undefined" || !armed) return;
  armed = false;
  document.removeEventListener("visibilitychange", onVisibilityChange);
  window.removeEventListener("pagehide", pause);
  window.removeEventListener("pageshow", onVisibilityChange);
  pause();
}
