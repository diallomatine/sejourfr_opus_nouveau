import { useMemo } from "react";
import { oneOf, useUrlListState } from "../../hooks/useUrlListState";
import { readOpenPeriod, writePeriod, type PeriodId, type PeriodPatch } from "../../lib/period";
import type { AdminProductionFilters, AdminProductionTri } from "../../types/api";
import {
  ANNOTATION_OPTIONS,
  EPREUVE_OPTIONS,
  EXAMINATEUR_OPTIONS,
  NIVEAU_OPTIONS,
  SIGNALEMENT_OPTIONS,
  SORT_OPTIONS,
  STATUT_OPTIONS,
  TACHE_OPTIONS,
} from "./productionLabels";

export { PAGE_SIZE_OPTIONS } from "../../hooks/useUrlListState";

/** 25 par page, comme le défaut du serveur (F-9 révisé le 2026-10-03). */
export const PRODUCTIONS_PAGE_SIZE = 25;

/** Mêmes presets que Suivi, précédés de « Tout », le défaut de l'écran (DI-35). */
export const PRODUCTION_PERIODS: readonly PeriodId[] = [
  "all",
  "today",
  "yesterday",
  "7d",
  "30d",
  "month",
  "custom",
];

const DEFAULT_SORT: AdminProductionTri = "DATE_DESC";

const values = <T extends string>(options: readonly { value: T }[]) => options.map((o) => o.value);

export type ProductionFilterKey =
  | "q"
  | "epreuve"
  | "tache"
  | "niveau"
  | "statut"
  | "signalement"
  | "annotation"
  | "examinateur"
  | "internes"
  | "sort";

export type ListFilters = Required<Pick<AdminProductionFilters, "page" | "size" | "sort">> &
  AdminProductionFilters;

/**
 * `?q&epreuve&tache&niveau&statut&signalement&annotation&examinateur&period&from&to&month&internes&sort&page&size`
 * (mécanique commune : `hooks/useUrlListState`). La période est lue et écrite
 * par `lib/period.ts` (autorité partagée avec Suivi et Activité) ; sans
 * `period` = « Tout », aucune borne envoyée.
 */
export function useProductionListParams() {
  const { params, page, size, setFilter, updateFilters, setPage, setSize, resetFilters } =
    useUrlListState(PRODUCTIONS_PAGE_SIZE);

  const periodState = useMemo(() => readOpenPeriod(params, PRODUCTION_PERIODS), [params]);

  const filters = useMemo<ListFilters>(() => {
    const q = params.get("q")?.trim();
    const tache = oneOf(params.get("tache"), values(TACHE_OPTIONS));
    const range = periodState.range;
    return {
      q: q ? q : undefined,
      epreuve: oneOf(params.get("epreuve"), values(EPREUVE_OPTIONS)),
      tache: tache ? (Number(tache) as 1 | 2 | 3) : undefined,
      niveau: oneOf(params.get("niveau"), values(NIVEAU_OPTIONS)),
      statut: oneOf(params.get("statut"), values(STATUT_OPTIONS)),
      signalement: oneOf(params.get("signalement"), values(SIGNALEMENT_OPTIONS)),
      annotation: oneOf(params.get("annotation"), values(ANNOTATION_OPTIONS)),
      examinateur: oneOf(params.get("examinateur"), values(EXAMINATEUR_OPTIONS)),
      preset: range && "preset" in range ? range.preset : undefined,
      from: range && "from" in range ? range.from : undefined,
      to: range && "to" in range ? range.to : undefined,
      includeInternal: params.get("internes") === "1" ? true : undefined,
      sort: oneOf(params.get("sort"), values(SORT_OPTIONS)) ?? DEFAULT_SORT,
      page,
      size,
    };
  }, [params, page, size, periodState]);

  const hasActiveFilter = Boolean(
    filters.q ||
      filters.epreuve ||
      filters.tache ||
      filters.niveau ||
      filters.statut ||
      filters.signalement ||
      filters.annotation ||
      filters.examinateur ||
      periodState.period !== "all" ||
      filters.includeInternal,
  );

  const setPeriod = (patch: PeriodPatch) => updateFilters((next) => writePeriod(next, patch, "all"));

  return {
    filters,
    period: periodState,
    hasActiveFilter,
    setFilter: setFilter as (
      key: ProductionFilterKey,
      value: string | undefined,
      options?: { replace?: boolean },
    ) => void,
    setPeriod,
    setPage,
    setSize,
    resetFilters,
  };
}
