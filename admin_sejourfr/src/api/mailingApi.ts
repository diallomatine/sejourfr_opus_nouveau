import { apiRequest } from "./http";
import type { LegacyCompensationMailingResponse } from "../types/api";

export const mailingApi = {
  /**
   * Annonce des nouveautés aux acheteurs de l'ancien catalogue Intégral
   * (compensés par la migration V038).
   *
   * `dryRun` vaut `true` côté serveur par défaut : on l'envoie explicitement
   * dans les deux sens pour que l'intention soit lisible ici, jamais implicite.
   */
  anciensAcheteurs(dryRun: boolean) {
    return apiRequest<LegacyCompensationMailingResponse>(
      "/api/admin/mailing/anciens-acheteurs",
      { method: "POST", query: { dryRun } },
    );
  },
};
