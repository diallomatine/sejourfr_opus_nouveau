import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { activityApi } from "../../api/activityApi";
import type { ActivityQuery } from "../../types/api";

/** Un seul appel pour la période ; la clé porte la période et `includeInternal`. */
export function useActivity(query: ActivityQuery) {
  return useQuery({
    queryKey: ["adminActivity", query],
    queryFn: ({ signal }) => activityApi.get(query, signal),
    placeholderData: keepPreviousData,
    staleTime: 60_000,
  });
}

const LIVE_REFRESH_MS = 30_000;

/**
 * Le direct, second appel assumé (D11) : relu toutes les 30 s, jamais quand
 * l'onglet est caché (`refetchIntervalInBackground` faux par défaut).
 */
export function useActivityLive(includeInternal: boolean) {
  return useQuery({
    queryKey: ["adminActivityLive", includeInternal],
    queryFn: ({ signal }) => activityApi.live(includeInternal, signal),
    placeholderData: keepPreviousData,
    refetchInterval: LIVE_REFRESH_MS,
    staleTime: LIVE_REFRESH_MS,
  });
}
