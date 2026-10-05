import { useMemo } from "react";
import { MONTH_PATTERN } from "../../lib/dates";
import { oneOf, useUrlListState } from "../../hooks/useUrlListState";
import type {
  AdminSubscriptionFilters,
  ModuleAccess,
  SubscriptionSource,
  SubscriptionStatus,
} from "../../types/api";

export { PAGE_SIZE_OPTIONS } from "../../hooks/useUrlListState";

const SOURCES: readonly SubscriptionSource[] = ["STRIPE", "APPLE", "GOOGLE"];
const STATUSES: readonly SubscriptionStatus[] = [
  "ACTIVE",
  "TRIAL",
  "IN_GRACE",
  "PENDING",
  "CANCELED",
  "EXPIRED",
  "REFUNDED",
];
const MODULES: readonly ModuleAccess[] = ["CIVIQUE", "INTEGRAL"];


export type SubscriptionFilterKey =
  | "source"
  | "status"
  | "moduleAccess"
  | "search"
  | "purchasedMonth";

/**
 * `?source=…&status=…&moduleAccess=…&search=…&purchasedMonth=yyyy-MM&page=…&size=…`
 * (mécanique commune : `hooks/useUrlListState`).
 */
export function useSubscriptionListParams() {
  const { params, page, size, setFilter, setPage, setSize, resetFilters } = useUrlListState();

  const filters = useMemo<Required<Pick<AdminSubscriptionFilters, "page" | "size">> &
    AdminSubscriptionFilters>(() => {
    const search = params.get("search")?.trim();
    const month = params.get("purchasedMonth");
    return {
      source: oneOf(params.get("source"), SOURCES),
      status: oneOf(params.get("status"), STATUSES),
      moduleAccess: oneOf(params.get("moduleAccess"), MODULES),
      search: search ? search : undefined,
      purchasedMonth: month && MONTH_PATTERN.test(month) ? month : undefined,
      page,
      size,
    };
  }, [params, page, size]);

  const hasActiveFilter = Boolean(
    filters.source ||
      filters.status ||
      filters.moduleAccess ||
      filters.search ||
      filters.purchasedMonth,
  );

  return {
    filters,
    hasActiveFilter,
    setFilter: setFilter as (
      key: SubscriptionFilterKey,
      value: string | undefined,
      options?: { replace?: boolean },
    ) => void,
    setPage,
    setSize,
    resetFilters,
  };
}
