import type { AnalyticsFilters, AnalyticsResponse } from "../../types/api";
import type { TabId } from "./labels";

/** Ce qu'un onglet peut ouvrir dans le panneau de detail. */
export type DetailTarget = { kind: "step"; stepKey: string; label?: string };

export interface TabProps {
  data: AnalyticsResponse;
  /** `null` quand la comparaison est desactivee : aucun delta ne s'affiche. */
  prev: AnalyticsResponse["prev"] | null;
  compare: boolean;
  filters: AnalyticsFilters;
  setFilter: (key: keyof AnalyticsFilters, value: string | null) => void;
  go: (tab: TabId) => void;
  openDetail: (target: DetailTarget) => void;
}
