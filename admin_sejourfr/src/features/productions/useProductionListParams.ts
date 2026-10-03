import { useMemo } from "react";
import { oneOf, useUrlListState } from "../../hooks/useUrlListState";
import type { AdminProductionFilters, AdminProductionPeriode, AdminProductionTri } from "../../types/api";
import {
  ANNOTATION_OPTIONS,
  EPREUVE_OPTIONS,
  NIVEAU_OPTIONS,
  SIGNALEMENT_OPTIONS,
  SORT_OPTIONS,
  STATUT_OPTIONS,
  TACHE_OPTIONS,
} from "./productionLabels";
import type { PeriodChoice } from "./productionLabels";

export { PAGE_SIZE_OPTIONS } from "../../hooks/useUrlListState";

/** F-9 : 50 par page, comme le défaut du serveur. */
export const PRODUCTIONS_PAGE_SIZE = 50;

const DEFAULT_SORT: AdminProductionTri = "DATE_DESC";
const PERIODES: readonly AdminProductionPeriode[] = ["TODAY", "LAST_7_DAYS", "LAST_30_DAYS"];
const ISO_DAY = /^\d{4}-\d{2}-\d{2}$/;

const values = <T extends string>(options: readonly { value: T }[]) => options.map((o) => o.value);

export type ProductionFilterKey =
  | "q"
  | "epreuve"
  | "tache"
  | "niveau"
  | "statut"
  | "signalement"
  | "annotation"
  | "internes"
  | "sort";

export type ListFilters = Required<Pick<AdminProductionFilters, "page" | "size" | "sort">> &
  AdminProductionFilters;

/**
 * `?q&epreuve&tache&niveau&statut&signalement&annotation&periode|from+to&internes&sort&page&size`
 * (mécanique commune : `hooks/useUrlListState`). Une plage personnalisée vit
 * dans `from`/`to` ; elle n'est envoyée que si les deux bornes sont lisibles
 * et ordonnées — sinon ignorée, jamais complétée.
 */
export function useProductionListParams() {
  const { params, page, size, setFilter, setFilters, setPage, setSize, resetFilters } =
    useUrlListState(PRODUCTIONS_PAGE_SIZE);

  const filters = useMemo<ListFilters>(() => {
    const q = params.get("q")?.trim();
    const tache = oneOf(params.get("tache"), values(TACHE_OPTIONS));
    const periode = oneOf(params.get("periode"), PERIODES);
    const from = params.get("from") ?? "";
    const to = params.get("to") ?? "";
    const customValid = ISO_DAY.test(from) && ISO_DAY.test(to) && from <= to;
    return {
      q: q ? q : undefined,
      epreuve: oneOf(params.get("epreuve"), values(EPREUVE_OPTIONS)),
      tache: tache ? (Number(tache) as 1 | 2 | 3) : undefined,
      niveau: oneOf(params.get("niveau"), values(NIVEAU_OPTIONS)),
      statut: oneOf(params.get("statut"), values(STATUT_OPTIONS)),
      signalement: oneOf(params.get("signalement"), values(SIGNALEMENT_OPTIONS)),
      annotation: oneOf(params.get("annotation"), values(ANNOTATION_OPTIONS)),
      periode: customValid ? undefined : periode,
      from: customValid ? from : undefined,
      to: customValid ? to : undefined,
      includeInternal: params.get("internes") === "1" ? true : undefined,
      sort: oneOf(params.get("sort"), values(SORT_OPTIONS)) ?? DEFAULT_SORT,
      page,
      size,
    };
  }, [params, page, size]);

  const period: PeriodChoice | "" = filters.from ? "CUSTOM" : (filters.periode ?? "");

  const hasActiveFilter = Boolean(
    filters.q ||
      filters.epreuve ||
      filters.tache ||
      filters.niveau ||
      filters.statut ||
      filters.signalement ||
      filters.annotation ||
      filters.periode ||
      filters.from ||
      filters.includeInternal,
  );

  const setPeriod = (choice: PeriodChoice | "", today: string) => {
    if (choice === "CUSTOM") {
      setFilters({ periode: undefined, from: filters.from ?? today, to: filters.to ?? today });
      return;
    }
    setFilters({ periode: choice || undefined, from: undefined, to: undefined });
  };

  const setRange = (from: string, to: string) => setFilters({ periode: undefined, from, to });

  return {
    filters,
    period,
    hasActiveFilter,
    setFilter: setFilter as (
      key: ProductionFilterKey,
      value: string | undefined,
      options?: { replace?: boolean },
    ) => void,
    setPeriod,
    setRange,
    setPage,
    setSize,
    resetFilters,
  };
}
