import { apiRequest } from "./http";
import type { AdminPlanDto, AdminPlanUpdateRequest } from "../types/api";

export const plansApi = {
  list() {
    return apiRequest<AdminPlanDto[]>("/api/admin/plans");
  },

  update(id: string, req: AdminPlanUpdateRequest) {
    return apiRequest<AdminPlanDto>(`/api/admin/plans/${id}`, {
      method: "PATCH",
      body: req,
    });
  },
};
