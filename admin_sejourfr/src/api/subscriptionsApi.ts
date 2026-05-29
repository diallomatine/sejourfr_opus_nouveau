import { apiRequest } from "./http";
import type {
  AdminSubscriptionFilters,
  AdminSubscriptionListResponse,
  CancelSubscriptionResponse,
} from "../types/api";

export const subscriptionsApi = {
  list(filters: AdminSubscriptionFilters = {}) {
    return apiRequest<AdminSubscriptionListResponse>("/api/admin/subscriptions", {
      query: {
        source: filters.source,
        status: filters.status,
        moduleAccess: filters.moduleAccess,
        search: filters.search,
        page: filters.page,
        size: filters.size,
      },
    });
  },

  cancel(id: string) {
    return apiRequest<CancelSubscriptionResponse>(
      `/api/admin/subscriptions/${id}/cancel`,
      { method: "POST" },
    );
  },
};
