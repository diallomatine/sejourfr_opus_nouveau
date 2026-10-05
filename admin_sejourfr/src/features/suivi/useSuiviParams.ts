import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import { readPeriod, writePeriod, type PeriodId, type PeriodPatch } from "../../lib/period";
import type { SuiviPlatformFilter, SuiviQuery, SuiviTypeFilter } from "../../types/api";

export const SUIVI_PERIODS: readonly PeriodId[] = [
  "today",
  "yesterday",
  "7d",
  "30d",
  "month",
  "custom",
];

const TYPES: Record<string, SuiviTypeFilter> = { tcf: "TCF", civique: "CIVIQUE" };
const PLATFORMS: Record<string, SuiviPlatformFilter> = {
  web: "WEB",
  ios: "IOS",
  android: "ANDROID",
};

function lookup<T>(table: Record<string, T>, raw: string | null): T | undefined {
  return raw != null && Object.hasOwn(table, raw) ? table[raw] : undefined;
}

export interface SuiviPatch extends PeriodPatch {
  type?: SuiviTypeFilter;
  platform?: SuiviPlatformFilter;
  source?: string;
  includeInternal?: boolean;
}

/**
 * L'etat de l'ecran vit dans l'URL (`?period&from&to&type&platform&source
 * &internal`) : le lien se partage et le bouton retour rejoue la vue. Une
 * valeur illisible est ignoree ; une valeur par defaut n'est pas ecrite. La
 * periode est lue et ecrite par `lib/period.ts`, partage avec Activite.
 */
export function useSuiviParams() {
  const [params, setParams] = useSearchParams();

  const state = useMemo(() => {
    const { period, from, to, month, range } = readPeriod(params, SUIVI_PERIODS);
    const query: SuiviQuery = {
      range,
      type: lookup(TYPES, params.get("type")) ?? "ALL",
      platform: lookup(PLATFORMS, params.get("platform")) ?? "ALL",
      source: params.get("source") || "ALL",
      includeInternal: params.get("internal") === "1",
    };
    return { period, from, to, month, query };
  }, [params]);

  const update = useCallback(
    (patch: SuiviPatch) => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        const write = (key: string, value: string | null) => {
          if (value) next.set(key, value);
          else next.delete(key);
        };
        writePeriod(next, patch);
        if (patch.type !== undefined) {
          write("type", patch.type === "ALL" ? null : patch.type.toLowerCase());
        }
        if (patch.platform !== undefined) {
          write("platform", patch.platform === "ALL" ? null : patch.platform.toLowerCase());
        }
        if (patch.source !== undefined) {
          write("source", patch.source === "ALL" ? null : patch.source);
        }
        if (patch.includeInternal !== undefined) {
          write("internal", patch.includeInternal ? "1" : null);
        }
        return next;
      });
    },
    [setParams],
  );

  return { ...state, update };
}
