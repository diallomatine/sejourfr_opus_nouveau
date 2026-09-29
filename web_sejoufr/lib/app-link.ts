import {SITE} from "./site";

/**
 * **Le lien « Continuer sur l'application »** (chantier « Suivi », lot 3b,
 * scénario 4) — l'autorité unique de sa forme côté web. Miroir mobile :
 * `AppLinkClaim.fromUri` (`diagnostic_run_models.dart`), qui le relit.
 *
 * Forme : `<base>/continuer-sur-app#run=<diagnosticRunId>&token=<claimToken>`.
 *
 * - 🛑 **Le jeton voyage dans le FRAGMENT**, jamais en query string : un
 *   fragment n'est envoyé à aucun serveur (journaux d'accès, `Referer`), même
 *   quand l'app n'est pas installée et que le navigateur ouvre la page de
 *   repli (D24, D82). Il ne part jamais non plus dans un événement.
 * - L'app installée intercepte l'adresse (universal link iOS, App Link
 *   Android) ; sinon le navigateur ouvre `/continuer-sur-app`, qui propose
 *   l'installation. Le deferred deep link est **hors MVP**.
 * - `NEXT_PUBLIC_APP_LINK_BASE_URL` : hôte dédié au lien (ex.
 *   `https://app.sejourfr.fr`). iOS n'ouvre pas l'app pour un lien vers le
 *   **même domaine** que la page affichée : tant que cet hôte n'est pas
 *   configuré, le lien part sur `SITE.url` et retombe sur la page web sur
 *   iPhone (D83).
 */
export const APP_LINK_PATH = "/continuer-sur-app";

const APP_LINK_BASE = (process.env.NEXT_PUBLIC_APP_LINK_BASE_URL || SITE.url).replace(/\/+$/, "");

export function continueOnAppHref(diagnosticRunId: string, claimToken: string): string {
  const fragment = new URLSearchParams({run: diagnosticRunId, token: claimToken}).toString();
  return `${APP_LINK_BASE}${APP_LINK_PATH}#${fragment}`;
}

export type MobilePlatform = "ios" | "android";

/** Le système du téléphone qui affiche la page, `null` hors téléphone (ou côté serveur). */
export function detectMobilePlatform(): MobilePlatform | null {
  if (typeof navigator === "undefined") return null;
  const ua = navigator.userAgent;
  if (/android/i.test(ua)) return "android";
  if (/iphone|ipad|ipod/i.test(ua)) return "ios";
  // iPadOS se déclare « Macintosh » : un écran tactile le trahit.
  if (/macintosh/i.test(ua) && navigator.maxTouchPoints > 1) return "ios";
  return null;
}
