/**
 * Provenance sociale du visiteur — dimension **fermée** et non personnelle.
 *
 * Ce module vit à part, et **n'importe rien** : `lib/api.ts` en a besoin pour
 * poser l'en-tête `X-Sejourfr-Source` sur chaque requête, et `lib/analytics.ts`
 * pour composer le premier contact. Les faire cohabiter dans un seul fichier
 * créerait un cycle d'import (`api` → `analytics` → `api`).
 *
 * Aucune fonction d'ici n'écrit quoi que ce soit sur l'appareil du visiteur :
 * la provenance est relue de l'URL (ou du referrer) à chaque appel.
 */

export const TRAFFIC_SOURCES = [
  "tiktok",
  "instagram",
  "whatsapp",
  "facebook",
  "youtube",
] as const;

export type TrafficSource = (typeof TRAFFIC_SOURCES)[number];

/** Réduit toute provenance à la liste blanche du backend. Une chaîne inconnue
 *  ne traverse jamais le funnel sous forme de nouvelle dimension. */
export function trafficSourceFromRaw(raw: string | null | undefined): TrafficSource | null {
  const normalized = raw?.trim().toLowerCase() ?? "";
  if (!normalized) return null;
  if (normalized.includes("tiktok")) return "tiktok";
  if (normalized.includes("instagram")) return "instagram";
  if (normalized.includes("whatsapp") || normalized.includes("wa.me") || normalized === "wa") {
    return "whatsapp";
  }
  if (normalized.includes("facebook") || normalized.includes("fb.") || normalized === "fb") {
    return "facebook";
  }
  if (normalized.includes("youtube") || normalized.includes("youtu.be")) return "youtube";
  return null;
}

/**
 * Provenance du visiteur. `?utm_source=` / `?src=` d'abord — c'est nous qui
 * posons le paramètre dans le lien de la bio, donc c'est fiable ; le referrer
 * ensuite, en repli (les apps mobiles ne le transmettent pas toujours).
 * `null` = accès direct, source non reconnue, ou rendu serveur.
 *
 * Elle ne lève jamais — un appel HTTP ne doit pas échouer parce qu'une
 * provenance est illisible.
 */
export function detectTrafficSource(): TrafficSource | null {
  if (typeof window === "undefined") return null;
  try {
    const params = new URLSearchParams(window.location.search);
    return trafficSourceFromRaw(params.get("utm_source") || params.get("src")) ??
      trafficSourceFromRaw(document.referrer);
  } catch {
    return null;
  }
}

/** Transporte une provenance non personnelle dans un chemin interne. Le garde
 *  local interdit qu'un futur appelant transforme ce helper en open redirect. */
export function withTrafficSource(
  path: string,
  source: TrafficSource | null | undefined,
): string {
  if (!path.startsWith("/") || path.startsWith("//") || path.startsWith("/\\")) return "/";
  if (!source) return path;
  const url = new URL(path, "https://internal.sejourfr.invalid");
  url.searchParams.set("src", source);
  return `${url.pathname}${url.search}${url.hash}`;
}
