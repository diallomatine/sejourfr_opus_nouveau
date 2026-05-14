import { apiRequest } from "./http";
import type { PassageDto, PassageWriteRequest } from "../types/api";

export const passagesApi = {
  list(themeId?: string) {
    return apiRequest<PassageDto[]>("/api/admin/passages", {
      query: { themeId: themeId ?? undefined },
    });
  },

  getById(id: string) {
    return apiRequest<PassageDto>(`/api/admin/passages/${id}`);
  },

  create(req: PassageWriteRequest) {
    return apiRequest<PassageDto>("/api/admin/passages", {
      method: "POST",
      body: req,
    });
  },

  update(id: string, req: PassageWriteRequest) {
    return apiRequest<PassageDto>(`/api/admin/passages/${id}`, {
      method: "PUT",
      body: req,
    });
  },

  delete(id: string) {
    return apiRequest<void>(`/api/admin/passages/${id}`, { method: "DELETE" });
  },
};
