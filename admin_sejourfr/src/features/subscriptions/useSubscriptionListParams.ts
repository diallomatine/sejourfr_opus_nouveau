import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import type {
  AdminSubscriptionFilters,
  ModuleAccess,
  SubscriptionSource,
  SubscriptionStatus,
} from "../../types/api";

export const PAGE_SIZE_OPTIONS = [10, 25, 50, 100] as const;
export const DEFAULT_PAGE_SIZE = 25;

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

function oneOf<T extends string>(raw: string | null, allowed: readonly T[]): T | undefined {
  return allowed.find((v) => v === raw);
}

export type SubscriptionFilterKey = "source" | "status" | "moduleAccess" | "search";

/**
 * L'état de la liste vit dans l'URL : `?source=…&status=…&moduleAccess=…&search=…
 * &page=…&size=…`. Le lien se partage, le bouton retour rejoue la page précédente.
 * `page` est compté à partir de 1 dans l'URL (lisible), à partir de 0 vers l'API.
 * Une valeur illisible est ignorée, jamais propagée au serveur ; une valeur par
 * défaut n'est pas écrite, pour garder des liens courts.
 */
export function useSubscriptionListParams() {
  const [params, setParams] = useSearchParams();

  const filters = useMemo<Required<Pick<AdminSubscriptionFilters, "page" | "size">> &
    AdminSubscriptionFilters>(() => {
    const rawPage = Number.parseInt(params.get("page") ?? "", 10);
    const rawSize = Number.parseInt(params.get("size") ?? "", 10);
    const search = params.get("search")?.trim();
    return {
      source: oneOf(params.get("source"), SOURCES),
      status: oneOf(params.get("status"), STATUSES),
      moduleAccess: oneOf(params.get("moduleAccess"), MODULES),
      search: search ? search : undefined,
      page: Number.isFinite(rawPage) && rawPage > 1 ? rawPage - 1 : 0,
      size: PAGE_SIZE_OPTIONS.find((s) => s === rawSize) ?? DEFAULT_PAGE_SIZE,
    };
  }, [params]);

  /** Poser un filtre ramène toujours en page 1 : l'ancienne page n'a plus de sens. */
  const setFilter = useCallback(
    (key: SubscriptionFilterKey, value: string | undefined, options?: { replace?: boolean }) => {
      setParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (value) next.set(key, value);
          else next.delete(key);
          next.delete("page");
          return next;
        },
        { replace: options?.replace ?? false },
      );
    },
    [setParams],
  );

  const setPage = useCallback(
    (page: number, options?: { replace?: boolean }) => {
      setParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (page > 0) next.set("page", String(page + 1));
          else next.delete("page");
          return next;
        },
        { replace: options?.replace ?? false },
      );
    },
    [setParams],
  );

  const setSize = useCallback(
    (size: number) => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        if (size === DEFAULT_PAGE_SIZE) next.delete("size");
        else next.set("size", String(size));
        next.delete("page");
        return next;
      });
    },
    [setParams],
  );

  const resetFilters = useCallback(() => {
    setParams((prev) => {
      const next = new URLSearchParams();
      const size = prev.get("size");
      if (size) next.set("size", size);
      return next;
    });
  }, [setParams]);

  const hasActiveFilter = Boolean(
    filters.source || filters.status || filters.moduleAccess || filters.search,
  );

  return { filters, hasActiveFilter, setFilter, setPage, setSize, resetFilters };
}
