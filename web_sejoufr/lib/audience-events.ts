export type AudienceEvent =
  | "VIEW"
  | "CTA"
  | "DIAGNOSTIC_VIEWED"
  | "DIAGNOSTIC_STARTED"
  | "DIAGNOSTIC_WRITTEN_COMPLETED"
  | "DIAGNOSTIC_ORAL_COMPLETED"
  | "DIAGNOSTIC_ACCOUNT_REQUIRED"
  | "DIAGNOSTIC_COMPLETED"
  | "DIAGNOSTIC_RESULT_VIEWED"
  | "PLAN_OPENED"
  | "PLAN_RECOMMENDED_EXERCISE_STARTED"
  | "SOCIAL_LANDING_DIAGNOSTIC_CLICKED"
  | "DIAGNOSTIC_TO_PREMIUM_CLICKED";

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

/** Miroir fermé de `PageViewService.EVENTS_BY_PATH`. L'endpoint est public :
 *  le client ne doit jamais lui inventer de dimension, même par erreur. */
export const AUDIENCE_EVENTS_BY_PATH = {
  "/reussir": ["VIEW", "CTA", "SOCIAL_LANDING_DIAGNOSTIC_CLICKED"],
  "/diagnostic": [
    "DIAGNOSTIC_VIEWED",
    "DIAGNOSTIC_STARTED",
    "DIAGNOSTIC_WRITTEN_COMPLETED",
    "DIAGNOSTIC_ORAL_COMPLETED",
    // Écran de demande de compte : c'est LA mesure de conversion du parcours
    // invité — deux productions faites, il ne manque que le compte.
    "DIAGNOSTIC_ACCOUNT_REQUIRED",
    "DIAGNOSTIC_COMPLETED",
    "DIAGNOSTIC_RESULT_VIEWED",
    "DIAGNOSTIC_TO_PREMIUM_CLICKED",
  ],
  "/plan": [
    "PLAN_OPENED",
    "PLAN_RECOMMENDED_EXERCISE_STARTED",
    "DIAGNOSTIC_TO_PREMIUM_CLICKED",
  ],
} as const satisfies Record<string, readonly AudienceEvent[]>;

export type AudiencePath = keyof typeof AUDIENCE_EVENTS_BY_PATH;
export type AudienceEventFor<Path extends AudiencePath> =
  (typeof AUDIENCE_EVENTS_BY_PATH)[Path][number];

export function isAudienceEventAllowed(path: string, event: AudienceEvent): path is AudiencePath {
  return Object.prototype.hasOwnProperty.call(AUDIENCE_EVENTS_BY_PATH, path) &&
    (AUDIENCE_EVENTS_BY_PATH[path as AudiencePath] as readonly AudienceEvent[]).includes(event);
}
