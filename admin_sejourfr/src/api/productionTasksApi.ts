import { apiRequest } from "./http";
import type {
  AdminProductionTaskDto,
  AdminProductionTaskTitreRequest,
  EpreuveType,
  ProductionTaskDto,
} from "../types/api";

/**
 * Catalogue des sujets EO/EE.
 *
 * Deux vues, volontairement distinctes :
 * - `list` (route candidat `/api/production-tasks`) ne rend que les sujets
 *   ACTIFS — un sujet désactivé depuis la soumission ne sera pas retrouvé,
 *   d'où les libellés de repli côté écran de calibration ;
 * - `listAdmin` (route `/api/admin/production-tasks`) rend TOUT, désactivés
 *   compris : la console d'édition des titres doit voir ce qu'elle édite.
 */
export const productionTasksApi = {
  list(epreuve: EpreuveType) {
    return apiRequest<ProductionTaskDto[]>("/api/production-tasks", {
      query: { epreuve },
    });
  },

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
