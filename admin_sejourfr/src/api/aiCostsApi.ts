import { apiRequest } from "./http";
import type { AdminAiCostResponse } from "../types/api";

/**
 * Le coût des appels IA (lot L12).
 *
 * 🛑 **Un seul appel pour tout l'écran** : toutes les sections se calculent sur
 * la MÊME fenêtre. Plusieurs appels, c'est plusieurs fenêtres à garder
 * cohérentes côté console — et le jour où l'une décale, deux blocs de la même
 * page racontent deux histoires.
 *
 * `from`/`to` l'emportent sur `days` côté serveur, et une borne seule est
 * refusée en 400 : on n'envoie donc jamais les deux formes à la fois.
 */
export const aiCostsApi = {
  get(days: number, signal?: AbortSignal) {
    return apiRequest<AdminAiCostResponse>("/api/admin/ai-costs", {
      query: { days: String(days) },
      signal,
    });
  },
};
