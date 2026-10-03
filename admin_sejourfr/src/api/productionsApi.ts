import { apiRequest } from "./http";
import type {
  AdminProductionDetailDto,
  AdminProductionFilters,
  AdminProductionFlagDto,
  AdminProductionFlagRequest,
  AdminProductionListItemDto,
  PageResponse,
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
        periode: filters.periode,
        from: filters.from,
        to: filters.to,
        includeInternal: filters.includeInternal || undefined,
        sort: filters.sort,
        page: filters.page,
        size: filters.size,
      },
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
