import {funnelApi, tokenStorage, type FunnelEvent} from "./api";

export type {FunnelEvent} from "./api";

/**
 * Deux étapes du funnel d'acquisition que **seul le navigateur** peut
 * constater : l'écran d'abonnement affiché, et le clic qui engage l'achat.
 *
 * Tout le reste du funnel (inscription, diagnostic commencé, diagnostic
 * terminé, paiement) est déduit serveur des vraies tables — il n'y a rien à
 * instrumenter ici pour ces étapes-là, et `CHECKOUT_STARTED` est posé par le
 * serveur : ne jamais l'émettre depuis le web.
 *
 * Trois règles, dans le prolongement de `lib/audience.ts` :
 *
 * - **rien n'est écrit sur l'appareil du visiteur** : ni cookie, ni
 *   localStorage, ni sessionStorage. La déduplication ci-dessous vit en mémoire
 *   et meurt avec l'onglet ; le serveur, lui, est idempotent (première
 *   occurrence par compte), donc un doublon ne coûte rien ;
 * - **best-effort, jamais bloquant** : aucune erreur n'est remontée à
 *   l'utilisateur, aucun état d'attente n'est affiché, un événement perdu est
 *   sans conséquence ;
 * - **rien n'est émis pour un visiteur anonyme** : l'endpoint est authentifié,
 *   un appel sans jeton serait un 401 garanti (et déclencherait la redirection
 *   de `apiFetch`). On regarde donc le jeton avant d'appeler.
 */

/** Une émission par onglet et par événement. Aucune persistance. */
const sent = new Set<FunnelEvent>();

function post(event: FunnelEvent): void {
  if (typeof window === "undefined") return;
  // Pas de compte, pas d'événement : l'endpoint est authentifié.
  if (!tokenStorage.getAccess()) return;
  void funnelApi.record(event).catch(() => {
    // Une étape de funnel perdue ne doit jamais casser un parcours d'achat.
  });
}

/**
 * Écran d'abonnement réellement affiché. `once` par onglet : la page peut se
 * re-rendre (StrictMode, changement d'onglet de périodicité) sans que la
 * mesure se dédouble.
 */
export function trackPaywallViewed(): void {
  if (sent.has("PAYWALL_VIEWED")) return;
  sent.add("PAYWALL_VIEWED");
  post("PAYWALL_VIEWED");
}

/**
 * Clic sur un CTA qui **engage l'achat** (ouverture du paiement), pas un simple
 * lien de navigation vers l'offre — celui-là est mesuré à l'arrivée par
 * `trackPaywallViewed`.
 */
export function trackSubscribeClicked(): void {
  post("SUBSCRIBE_CLICKED");
}
