import { apiRequest } from "./http";
import type { AdminSuiviResponse, SuiviQuery } from "../types/api";

/**
 * `preset` et `from`/`to` s'excluent (400 si les deux) : la forme de
 * `SuiviRange` garantit qu'on n'envoie jamais que l'une des deux. Les filtres
 * a leur valeur par defaut ne sont pas envoyes.
 */
function toParams(query: SuiviQuery): Record<string, string> {
  const params: Record<string, string> =
    "preset" in query.range
      ? { preset: query.range.preset }
      : { from: query.range.from, to: query.range.to };
  if (query.type !== "ALL") params.type = query.type;
  if (query.platform !== "ALL") params.platform = query.platform;
  if (query.source !== "ALL") params.source = query.source;
  if (query.includeInternal) params.includeInternal = "true";
  return params;
}

export const suiviApi = {
  get(query: SuiviQuery, signal?: AbortSignal) {
    return apiRequest<AdminSuiviResponse>("/api/admin/analytics/suivi", {
      query: toParams(query),
      signal,
    });
  },
};
