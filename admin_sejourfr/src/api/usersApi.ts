import { apiRequest } from "./http";
import type {
  AdminAccessOperationRequest,
  AdminAccessOperationResponse,
  AdminAccessProductDto,
  AdminUserDetailDto,
  AdminUserFilters,
  AdminUserListItemDto,
  PageResponse,
} from "../types/api";

export const usersApi = {
  list(filters: AdminUserFilters = {}) {
    return apiRequest<PageResponse<AdminUserListItemDto>>("/api/admin/users", {
      query: {
        q: filters.q,
        filter: filters.filter,
        page: filters.page,
        size: filters.size,
      },
    });
  },

  detail(id: string) {
    return apiRequest<AdminUserDetailDto>(`/api/admin/users/${id}`);
  },

  /** Produits sur lesquels l'admin peut agir (jamais codés en dur dans l'écran). */
  products() {
    return apiRequest<AdminAccessProductDto[]>("/api/admin/access-products");
  },

  /** Aperçu (`dryRun: true`) ou écriture d'une action d'accès. */
  accessOperation(id: string, request: AdminAccessOperationRequest) {
    return apiRequest<AdminAccessOperationResponse>(
      `/api/admin/users/${id}/access-operations`,
      { method: "POST", body: request },
    );
  },
};
