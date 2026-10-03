import { apiRequest } from "./http";
import { rangeParams } from "../lib/period";
import type {
  ActivityQuery,
  AdminActivityLiveResponse,
  AdminActivityResponse,
} from "../types/api";

export const activityApi = {
  /** Lecture de la période : un seul appel nourrit l'écran Activité. */
  get(query: ActivityQuery, signal?: AbortSignal) {
    const params = rangeParams(query.range);
    if (query.includeInternal) params.includeInternal = "true";
    return apiRequest<AdminActivityResponse>("/api/admin/analytics/activity", {
      query: params,
      signal,
    });
  },

  /** Comptes en ligne maintenant ; indépendant de la période. */
  live(includeInternal: boolean, signal?: AbortSignal) {
    return apiRequest<AdminActivityLiveResponse>("/api/admin/analytics/activity/live", {
      query: includeInternal ? { includeInternal: "true" } : {},
      signal,
    });
  },
};
