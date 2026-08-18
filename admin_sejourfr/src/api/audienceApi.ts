import { apiRequest } from "./http";
import type {
  AudienceRange,
  FunnelStatsResponse,
  PageViewStatsResponse,
} from "../types/api";

/**
 * `from`/`to` l'emportent sur `days` côté serveur, et une borne seule est
 * refusée en 400 : on n'envoie donc jamais les deux formes à la fois.
 */
function rangeParams(range: AudienceRange): URLSearchParams {
  return "days" in range
    ? new URLSearchParams({ days: String(range.days) })
    : new URLSearchParams({ from: range.from, to: range.to });
}

export const audienceApi = {
  /** Funnel réel de la cohorte des comptes créés sur la période. */
  funnel(range: AudienceRange) {
    return apiRequest<FunnelStatsResponse>(
      `/api/admin/audience/funnel?${rangeParams(range)}`,
    );
  },

  /** Chemins suivis par le compteur agrégé anonyme. */
  trackedPaths() {
    return apiRequest<string[]>("/api/admin/page-views/paths");
  },

  /** Audience anonyme d'une landing (vues de pages, pas des comptes). */
  landing(path: string, range: AudienceRange) {
    const params = rangeParams(range);
    params.set("path", path);
    return apiRequest<PageViewStatsResponse>(`/api/admin/page-views?${params}`);
  },
};
