import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { suiviApi } from "../../api/suiviApi";
import type { SuiviQuery } from "../../types/api";

/** Un seul appel nourrit tout l'ecran ; la cle porte la periode et tous les filtres. */
export function useSuivi(query: SuiviQuery) {
  return useQuery({
    queryKey: ["adminSuivi", query],
    queryFn: ({ signal }) => suiviApi.get(query, signal),
    placeholderData: keepPreviousData,
    staleTime: 60_000,
  });
}
