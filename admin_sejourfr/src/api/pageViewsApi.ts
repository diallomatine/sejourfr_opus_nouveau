import { apiRequest } from "./http";
import type { PageViewStatsResponse } from "../types/api";

export const pageViewsApi = {
  trackedPaths() {
    return apiRequest<string[]>("/api/admin/page-views/paths");
  },

  stats(path: string, days: number) {
    const params = new URLSearchParams({ path, days: String(days) });
    return apiRequest<PageViewStatsResponse>(`/api/admin/page-views?${params}`);
  },
};
