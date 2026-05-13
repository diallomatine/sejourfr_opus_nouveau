import { apiRequest } from "./http";
import type { Module, ThemeDto, ThemeWriteRequest } from "../types/api";

export const themesApi = {
  list(module?: Module) {
    return apiRequest<ThemeDto[]>("/api/admin/themes", {
      query: { module },
    });
  },

  getById(id: string) {
    return apiRequest<ThemeDto>(`/api/admin/themes/${id}`);
  },

  create(req: ThemeWriteRequest) {
    return apiRequest<ThemeDto>("/api/admin/themes", {
      method: "POST",
      body: req,
    });
  },

  update(id: string, req: ThemeWriteRequest) {
    return apiRequest<ThemeDto>(`/api/admin/themes/${id}`, {
      method: "PUT",
      body: req,
    });
  },

  delete(id: string) {
    return apiRequest<void>(`/api/admin/themes/${id}`, { method: "DELETE" });
  },
};
