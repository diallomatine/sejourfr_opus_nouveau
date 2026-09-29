import { apiRequest } from "./http";
import type { DashboardDto } from "../types/api";

export const dashboardApi = {
  get() {
    return apiRequest<DashboardDto>("/api/admin/dashboard");
  },
};
