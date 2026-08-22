import { apiRequest } from "./http";
import type { AnalyticsFilters, AnalyticsRange, AnalyticsResponse } from "../types/api";

/**
 * `from`/`to` l'emportent sur `days` cote serveur, et une borne seule est
 * refusee en 400 : on n'envoie donc jamais les deux formes a la fois.
 */
function rangeParams(range: AnalyticsRange): Record<string, string> {
  return "days" in range
    ? { days: String(range.days) }
    : { from: range.from, to: range.to };
}

function filterParams(filters: AnalyticsFilters): Record<string, string> {
  const params: Record<string, string> = {};
  if (filters.source) params.source = filters.source;
  if (filters.country) params.country = filters.country;
  if (filters.device) params.device = filters.device;
  if (filters.platform) params.platform = filters.platform;
  return params;
}

export const analyticsApi = {
  /** Tout l'ecran vient d'un seul appel : une seule fenetre de temps a tenir. */
  get(range: AnalyticsRange, filters: AnalyticsFilters, signal?: AbortSignal) {
    return apiRequest<AnalyticsResponse>("/api/admin/analytics", {
      query: { ...rangeParams(range), ...filterParams(filters) },
      signal,
    });
  },
};
