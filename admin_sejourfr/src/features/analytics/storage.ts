import type { AnalyticsFilters } from "../../types/api";
import { DEFAULT_PERIOD, type PeriodChoice } from "./period";
import type { TabId } from "./labels";

const KEY = "sejourfr.admin.analytics.v1";

export interface ScreenState {
  tab: TabId;
  period: PeriodChoice;
  compare: boolean;
  filters: AnalyticsFilters;
}

export const EMPTY_FILTERS: AnalyticsFilters = {
  source: null,
  country: null,
  device: null,
  platform: null,
};

export const DEFAULT_STATE: ScreenState = {
  tab: "overview",
  period: DEFAULT_PERIOD,
  compare: true,
  filters: EMPTY_FILTERS,
};

/**
 * L'etat de l'ecran survit au rechargement : on revient sur l'onglet et la
 * periode qu'on regardait. Tout acces au stockage est garde — navigation
 * privee, quota plein, stockage bloque : on repart des valeurs par defaut
 * plutot que de casser la page.
 */
export function readState(): ScreenState {
  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return DEFAULT_STATE;
    const parsed = JSON.parse(raw) as Partial<ScreenState>;
    return {
      tab: parsed.tab ?? DEFAULT_STATE.tab,
      period: parsed.period ?? DEFAULT_STATE.period,
      compare: parsed.compare ?? DEFAULT_STATE.compare,
      filters: { ...EMPTY_FILTERS, ...(parsed.filters ?? {}) },
    };
  } catch {
    return DEFAULT_STATE;
  }
}

export function writeState(state: ScreenState): void {
  try {
    window.localStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    /* Stockage indisponible : l'ecran fonctionne, il ne se souvient juste pas. */
  }
}
