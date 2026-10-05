import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import { readPeriod, writePeriod, type PeriodId, type PeriodPatch } from "../../lib/period";
import type { ActivityQuery } from "../../types/api";

export const ACTIVITY_PERIODS: readonly PeriodId[] = ["today", "yesterday", "7d", "30d", "month", "custom"];

export interface ActivityPatch extends PeriodPatch {
  includeInternal?: boolean;
}

/**
 * L'état de l'écran vit dans l'URL (`?period&from&to&internal`), mêmes clés
 * que Suivi : la case « internes » se transmet d'un écran à l'autre. Défaut
 * non écrit, valeur illisible ignorée.
 */
export function useActivityParams() {
  const [params, setParams] = useSearchParams();

  const state = useMemo(() => {
    const { period, from, to, month, range } = readPeriod(params, ACTIVITY_PERIODS);
    const query: ActivityQuery = { range, includeInternal: params.get("internal") === "1" };
    return { period, from, to, month, query };
  }, [params]);

  const update = useCallback(
    (patch: ActivityPatch) => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        writePeriod(next, patch);
        if (patch.includeInternal !== undefined) {
          if (patch.includeInternal) next.set("internal", "1");
          else next.delete("internal");
        }
        return next;
      });
    },
    [setParams],
  );

  return { ...state, update };
}
