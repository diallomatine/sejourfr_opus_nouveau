import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import type {
  SuiviPeriodPreset,
  SuiviPlatformFilter,
  SuiviQuery,
  SuiviTypeFilter,
} from "../../types/api";

export type PeriodId = "today" | "yesterday" | "7d" | "month" | "custom";

export const PERIOD_OPTIONS: { id: PeriodId; label: string }[] = [
  { id: "today", label: "Aujourd’hui" },
  { id: "yesterday", label: "Hier" },
  { id: "7d", label: "7 jours" },
  { id: "month", label: "Mois" },
  { id: "custom", label: "Personnalisé" },
];

const PRESETS: Record<Exclude<PeriodId, "custom">, SuiviPeriodPreset> = {
  today: "TODAY",
  yesterday: "YESTERDAY",
  "7d": "LAST_7_DAYS",
  month: "MONTH",
};

const TYPES: Record<string, SuiviTypeFilter> = { tcf: "TCF", civique: "CIVIQUE" };
const PLATFORMS: Record<string, SuiviPlatformFilter> = {
  web: "WEB",
  ios: "IOS",
  android: "ANDROID",
};

const ISO_DAY = /^\d{4}-\d{2}-\d{2}$/;

function lookup<T>(table: Record<string, T>, raw: string | null): T | undefined {
  return raw != null && Object.hasOwn(table, raw) ? table[raw] : undefined;
}

export interface SuiviPatch {
  period?: PeriodId;
  from?: string;
  to?: string;
  type?: SuiviTypeFilter;
  platform?: SuiviPlatformFilter;
  source?: string;
  includeInternal?: boolean;
}

/**
 * L'etat de l'ecran vit dans l'URL (`?period&from&to&type&platform&source
 * &internal`) : le lien se partage et le bouton retour rejoue la vue. Une
 * valeur illisible est ignoree ; une valeur par defaut n'est pas ecrite. Une
 * plage personnalisee incomplete ou inversee retombe sur « Aujourd'hui » :
 * elle partirait en 400.
 */
export function useSuiviParams() {
  const [params, setParams] = useSearchParams();

  const state = useMemo(() => {
    const rawPeriod = params.get("period");
    const from = params.get("from") ?? "";
    const to = params.get("to") ?? "";
    const customValid =
      rawPeriod === "custom" && ISO_DAY.test(from) && ISO_DAY.test(to) && from <= to;
    const period: PeriodId = customValid
      ? "custom"
      : lookup(PRESETS, rawPeriod)
        ? (rawPeriod as PeriodId)
        : "today";

    const query: SuiviQuery = {
      range:
        period === "custom" ? { from, to } : { preset: PRESETS[period as keyof typeof PRESETS] },
      type: lookup(TYPES, params.get("type")) ?? "ALL",
      platform: lookup(PLATFORMS, params.get("platform")) ?? "ALL",
      source: params.get("source") || "ALL",
      includeInternal: params.get("internal") === "1",
    };
    return { period, from, to, query };
  }, [params]);

  const update = useCallback(
    (patch: SuiviPatch) => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        const write = (key: string, value: string | null) => {
          if (value) next.set(key, value);
          else next.delete(key);
        };
        if (patch.period !== undefined) {
          write("period", patch.period === "today" ? null : patch.period);
          if (patch.period !== "custom") {
            next.delete("from");
            next.delete("to");
          }
        }
        if (patch.from !== undefined) write("from", patch.from);
        if (patch.to !== undefined) write("to", patch.to);
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
