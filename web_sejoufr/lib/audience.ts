import { API_BASE_URL } from "./api";
import {
  detectTrafficSource,
  isAudienceEventAllowed,
  type AudienceEvent,
  type AudienceEventFor,
  type AudiencePath,
} from "./audience-events";

export {
  AUDIENCE_EVENTS_BY_PATH,
  detectTrafficSource,
  isAudienceEventAllowed,
  trafficSourceFromRaw,
  withTrafficSource,
  type AudienceEvent,
  type AudienceEventFor,
  type AudiencePath,
  type TrafficSource,
} from "./audience-events";

/**
 * Mesure d'audience ANONYME des pages publiques : landing de campagne
 * (`/reussir`), funnel du diagnostic et du Plan, et pages d'achat
 * (`/tarifs`, `/paiement`) — là, elle compte les visiteurs qui regardent les
 * prix sans jamais créer de compte, ce qu'aucune table ne peut dire.
 *
 * À ne pas confondre avec `lib/funnel-events.ts`, qui pose des étapes de
 * funnel **rattachées à un compte** et exige donc une session authentifiée.
 *
 * Ce module n'écrit **rien** dans le navigateur : ni cookie, ni localStorage,
 * ni sessionStorage. Il n'envoie ni identifiant, ni horodatage client, ni
 * user-agent — juste « telle page a été vue, depuis tel réseau ». C'est cette
 * absence qui permet à `/confidentialite` de continuer d'affirmer qu'aucun
 * traceur n'est déposé et de se passer de bandeau de consentement. Ne pas
 * ajouter de déduplication persistante ici sans repasser sur la page légale.
 *
 * Conséquence assumée : on compte des **vues**, pas des visiteurs uniques.
 */

/** Une vue par chargement de page, quoi qu'il arrive (StrictMode, re-render). */
const sent = new Set<string>();

function send(path: AudiencePath, event: AudienceEvent) {
  if (typeof window === "undefined") return;

  const body = JSON.stringify({
    path,
    source: detectTrafficSource() ?? "direct",
    event,
  });
  const url = `${API_BASE_URL}/api/public/page-views`;

  // sendBeacon survit à la navigation : indispensable sur le clic du CTA, où
  // la page est en train d'être quittée quand la requête part. Repli fetch
  // keepalive pour les navigateurs qui refusent le beacon (Content-Type non
  // simple bloqué par certaines politiques).
  try {
    const blob = new Blob([body], { type: "application/json" });
    if (navigator.sendBeacon?.(url, blob)) return;
  } catch {
    // on tombe sur le repli ci-dessous
  }

  void fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
    keepalive: true,
  }).catch(() => {
    // La mesure d'audience ne doit jamais casser la page ni remonter d'erreur
    // à l'utilisateur : un compteur perdu est sans conséquence.
  });
}

/** À appeler une fois au montage de la landing. Les appels suivants sont ignorés. */
export function trackPageView(path: string) {
  if (!isAudienceEventAllowed(path, "VIEW")) return;
  const key = `VIEW:${path}`;
  if (sent.has(key)) return;
  sent.add(key);
  send(path, "VIEW");
}

/** Clic sur l'appel à l'action principal. Compté à chaque clic. */
export function trackCtaClick(path: string) {
  if (!isAudienceEventAllowed(path, "CTA")) return;
  send(path, "CTA");
}

/** Événement de funnel agrégé. `once` déduplique seulement pendant la vie de
 *  l'onglet : aucune donnée n'est écrite dans le navigateur. */
export function trackAudienceEvent<Path extends AudiencePath>(
  path: Path,
  event: AudienceEventFor<Path>,
  options: {once?: boolean} = {},
) {
  if (!isAudienceEventAllowed(path, event)) return;
  const key = `${event}:${path}`;
  if (options.once && sent.has(key)) return;
  if (options.once) sent.add(key);
  send(path, event);
}
