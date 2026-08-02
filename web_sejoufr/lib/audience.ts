import { API_BASE_URL } from "./api";

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

export type TrafficSource =
  | "tiktok"
  | "instagram"
  | "whatsapp"
  | "facebook"
  | "youtube";

/**
 * Provenance du visiteur. `?utm_source=` / `?src=` d'abord — c'est nous qui
 * posons le paramètre dans le lien de la bio, donc c'est fiable ; le referrer
 * ensuite, en repli (les apps mobiles ne le transmettent pas toujours).
 * `null` = accès direct ou source non reconnue.
 */
export function detectTrafficSource(): TrafficSource | null {
  if (typeof window === "undefined") return null;
  const params = new URLSearchParams(window.location.search);
  const raw = (
    params.get("utm_source") ||
    params.get("src") ||
    document.referrer ||
    ""
  ).toLowerCase();
  if (!raw) return null;
  if (raw.includes("tiktok")) return "tiktok";
  if (raw.includes("instagram")) return "instagram";
  if (raw.includes("whatsapp") || raw.includes("wa.me") || raw === "wa") return "whatsapp";
  if (raw.includes("facebook") || raw.includes("fb.") || raw === "fb") return "facebook";
  if (raw.includes("youtube") || raw.includes("youtu.be")) return "youtube";
  return null;
}

type AudienceEvent = "VIEW" | "CTA";

/** Une vue par chargement de page, quoi qu'il arrive (StrictMode, re-render). */
const sent = new Set<string>();

function send(path: string, event: AudienceEvent) {
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
  const key = `VIEW:${path}`;
  if (sent.has(key)) return;
  sent.add(key);
  send(path, "VIEW");
}

/** Clic sur l'appel à l'action principal. Compté à chaque clic. */
export function trackCtaClick(path: string) {
  send(path, "CTA");
}
