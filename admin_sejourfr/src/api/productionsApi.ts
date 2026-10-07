import { apiRequest } from "./http";
import { rangeParams } from "../lib/period";
import type {
  AdminProductionDetailDto,
  AdminProductionFilters,
  AdminProductionFlagDto,
  AdminProductionFlagRequest,
  AdminProductionListItemDto,
  AdminProductionStatsDto,
  PageResponse,
  SuiviRange,
} from "../types/api";

export const productionsApi = {
  list(filters: AdminProductionFilters = {}) {
    return apiRequest<PageResponse<AdminProductionListItemDto>>("/api/admin/productions", {
      query: {
        q: filters.q,
        epreuve: filters.epreuve,
        tache: filters.tache,
        niveau: filters.niveau,
        statut: filters.statut,
        signalement: filters.signalement,
        annotation: filters.annotation,
        examinateur: filters.examinateur,
        preset: filters.preset,
        from: filters.from,
        to: filters.to,
        includeInternal: filters.includeInternal || undefined,
        sort: filters.sort,
        page: filters.page,
        size: filters.size,
      },
    });
  },

  /** Encart de la liste (DI-35) : période + comptes internes seulement. */
  stats(range: SuiviRange | null, includeInternal: boolean) {
    return apiRequest<AdminProductionStatsDto>("/api/admin/productions/stats", {
      query: { ...rangeParams(range), includeInternal: includeInternal || undefined },
    });
  },

  /** Lecture passive : aucune écriture, aucun appel IA côté serveur. */
  detail(id: string) {
    return apiRequest<AdminProductionDetailDto>(`/api/admin/productions/${id}`);
  },

  flag(id: string, body: AdminProductionFlagRequest) {
    return apiRequest<AdminProductionFlagDto>(`/api/admin/productions/${id}/flags`, {
      method: "POST",
      body,
    });
  },

  verifyFlag(flagId: string) {
    return apiRequest<AdminProductionFlagDto>(`/api/admin/productions/flags/${flagId}/verify`, {
      method: "POST",
    });
  },

  removeFlag(flagId: string) {
    return apiRequest<AdminProductionFlagDto>(`/api/admin/productions/flags/${flagId}/remove`, {
      method: "POST",
    });
  },
};
