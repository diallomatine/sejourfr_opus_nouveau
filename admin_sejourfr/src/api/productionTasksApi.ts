import { apiRequest } from "./http";
import type {
  AdminProductionTaskDto,
  AdminProductionTaskTitreRequest,
  EpreuveType,
} from "../types/api";

/**
 * Catalogue des sujets EO/EE, vue admin (`/api/admin/production-tasks`) :
 * TOUT, désactivés compris — la console d'édition des titres doit voir ce
 * qu'elle édite.
 */
export const productionTasksApi = {
  listAdmin(epreuve: EpreuveType, tacheNumero?: number) {
    return apiRequest<AdminProductionTaskDto[]>("/api/admin/production-tasks", {
      query: { epreuve, tacheNumero },
    });
  },

  /** `titre: null` (ou blanc) retire le titre et rétablit le repli « Sujet N ». */
  updateTitre(id: string, req: AdminProductionTaskTitreRequest) {
    return apiRequest<AdminProductionTaskDto>(
      `/api/admin/production-tasks/${id}/titre`,
      { method: "PATCH", body: req },
    );
  },
};
