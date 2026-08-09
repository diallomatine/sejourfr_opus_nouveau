import { API_BASE_URL } from "./api";
import {
  isAudienceEventAllowed,
  trafficSourceFromRaw,
  type AudienceEvent,
  type AudienceEventFor,
  type AudiencePath,
  type TrafficSource,
} from "./audience-events";

export {
  AUDIENCE_EVENTS_BY_PATH,
  isAudienceEventAllowed,
  trafficSourceFromRaw,
  withTrafficSource,
  type AudienceEvent,
  type AudienceEventFor,
  type AudiencePath,
  type TrafficSource,
} from "./audience-events";

/**
 * Mesure d'audience des landings de campagne (`/reussir`).
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

/**
 * Provenance du visiteur. `?utm_source=` / `?src=` d'abord — c'est nous qui
 * posons le paramètre dans le lien de la bio, donc c'est fiable ; le referrer
 * ensuite, en repli (les apps mobiles ne le transmettent pas toujours).
 * `null` = accès direct ou source non reconnue.
 */
export function detectTrafficSource(): TrafficSource | null {
  if (typeof window === "undefined") return null;
  const params = new URLSearchParams(window.location.search);
  return trafficSourceFromRaw(params.get("utm_source") || params.get("src")) ??
    trafficSourceFromRaw(document.referrer);
}

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
