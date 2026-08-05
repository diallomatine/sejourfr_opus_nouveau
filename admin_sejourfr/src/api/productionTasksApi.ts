import { apiRequest } from "./http";
import type { EpreuveType, ProductionTaskDto } from "../types/api";

/**
 * Catalogue des sujets EO/EE. Seules les tasks actives sont exposées : un sujet
 * désactivé depuis la soumission ne sera pas retrouvé, d'où les libellés de
 * repli côté écran de calibration.
 */
export const productionTasksApi = {
  list(epreuve: EpreuveType) {
    return apiRequest<ProductionTaskDto[]>("/api/production-tasks", {
      query: { epreuve },
    });
  },
};
