import { useMemo } from "react";
import { oneOf, useUrlListState } from "../../hooks/useUrlListState";
import type { AdminUserFilter, AdminUserFilters } from "../../types/api";

export { PAGE_SIZE_OPTIONS } from "../../hooks/useUrlListState";

/**
 * Les filtres servis par `GET /api/admin/users` (valeur inconnue ⇒ 400 côté
 * serveur, d'où le tri ici). Les libellés décrivent le filtre ; le calcul
 * (qui est « actif », « expiré »…) est entièrement serveur.
 */
export const USER_FILTERS: readonly { value: AdminUserFilter; label: string }[] = [
  { value: "ALL", label: "Tous" },
  { value: "TCF_ACTIVE", label: "Accès TCF actif" },
  { value: "CIVIQUE_ACTIVE", label: "Accès Civique actif" },
  { value: "NO_ACTIVE_ACCESS", label: "Sans accès actif" },
  { value: "EXPIRED", label: "Expiré" },
  { value: "MANUAL_ACCESS", label: "Accès manuel" },
];

const FILTER_VALUES = USER_FILTERS.map((f) => f.value);

/** `?q=…&filter=…&page=…&size=…` (mécanique commune : `hooks/useUrlListState`). */
export function useUserListParams() {
  const { params, page, size, setFilter, setPage, setSize, resetFilters } = useUrlListState();

  const filters = useMemo<Required<Pick<AdminUserFilters, "page" | "size">> & AdminUserFilters>(() => {
    const q = params.get("q")?.trim();
    const filter = oneOf(params.get("filter"), FILTER_VALUES);
    return {
      q: q ? q : undefined,
      filter: filter && filter !== "ALL" ? filter : undefined,
      page,
      size,
    };
  }, [params, page, size]);

  const hasActiveFilter = Boolean(filters.q || filters.filter);

  return {
    filters,
    hasActiveFilter,
    setFilter: setFilter as (
      key: "q" | "filter",
      value: string | undefined,
      options?: { replace?: boolean },
    ) => void,
    setPage,
    setSize,
    resetFilters,
  };
}
