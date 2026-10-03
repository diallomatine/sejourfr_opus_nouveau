import { useCallback, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";

export const PAGE_SIZE_OPTIONS = [10, 25, 50, 100] as const;
export const DEFAULT_PAGE_SIZE = 25;

export function oneOf<T extends string>(raw: string | null, allowed: readonly T[]): T | undefined {
  return allowed.find((v) => v === raw);
}

/**
 * L'état d'une liste paginée serveur vit dans l'URL : le lien se partage, le
 * bouton retour rejoue la page précédente. `page` est compté à partir de 1 dans
 * l'URL (lisible), à partir de 0 vers l'API. Une valeur illisible est ignorée ;
 * une valeur par défaut n'est pas écrite. Poser un filtre, la recherche ou la
 * taille ramène en page 1 DANS LA MÊME écriture d'URL (jamais un effet qui
 * remettrait la page à 0 après coup : une requête partirait avec l'ancienne).
 * Chaque feature lit ses propres filtres dans `params` ; `defaultSize` est le
 * réglage d'écran (non écrit dans l'URL quand il est en vigueur).
 */
export function useUrlListState(defaultSize: number = DEFAULT_PAGE_SIZE) {
  const [params, setParams] = useSearchParams();

  const { page, size } = useMemo(() => {
    const rawPage = Number.parseInt(params.get("page") ?? "", 10);
    const rawSize = Number.parseInt(params.get("size") ?? "", 10);
    return {
      page: Number.isFinite(rawPage) && rawPage > 1 ? rawPage - 1 : 0,
      size: PAGE_SIZE_OPTIONS.find((s) => s === rawSize) ?? defaultSize,
    };
  }, [params, defaultSize]);

  const setFilters = useCallback(
    (patch: Record<string, string | undefined>, options?: { replace?: boolean }) => {
      setParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          for (const [key, value] of Object.entries(patch)) {
            if (value) next.set(key, value);
            else next.delete(key);
          }
          next.delete("page");
          return next;
        },
        { replace: options?.replace ?? false },
      );
    },
    [setParams],
  );

  const setFilter = useCallback(
    (key: string, value: string | undefined, options?: { replace?: boolean }) =>
      setFilters({ [key]: value }, options),
    [setFilters],
  );

  const setPage = useCallback(
    (nextPage: number, options?: { replace?: boolean }) => {
      setParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (nextPage > 0) next.set("page", String(nextPage + 1));
          else next.delete("page");
          return next;
        },
        { replace: options?.replace ?? false },
      );
    },
    [setParams],
  );

  const setSize = useCallback(
    (nextSize: number) => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        if (nextSize === defaultSize) next.delete("size");
        else next.set("size", String(nextSize));
        next.delete("page");
        return next;
      });
    },
    [setParams, defaultSize],
  );

  const resetFilters = useCallback(() => {
    setParams((prev) => {
      const next = new URLSearchParams();
      const keptSize = prev.get("size");
      if (keptSize) next.set("size", keptSize);
      return next;
    });
  }, [setParams]);

  return { params, page, size, setFilter, setFilters, setPage, setSize, resetFilters };
}

/**
 * Champ de recherche branché sur un paramètre d'URL : la frappe est debouncée
 * (300 ms) puis écrite en `replace` (une lettre n'est pas une entrée
 * d'historique) ; l'URL fait foi, un retour arrière ou un lien partagé repose
 * le champ. La comparaison se fait sur la valeur rognée, pour ne pas effacer
 * l'espace qu'on est en train de taper.
 */
export function useUrlSearchInput(
  urlValue: string,
  commit: (value: string | undefined) => void,
): [string, (value: string) => void] {
  const [input, setInput] = useState(urlValue);
  const [synced, setSynced] = useState(urlValue);

  if (synced !== urlValue) {
    setSynced(urlValue);
    if (input.trim() !== urlValue) setInput(urlValue);
  }

  useEffect(() => {
    const typed = input.trim();
    if (typed === urlValue) return;
    const t = setTimeout(() => commit(typed || undefined), 300);
    return () => clearTimeout(t);
  }, [input, urlValue, commit]);

  return [input, setInput];
}

/**
 * Page devenue hors bornes (lien ancien, action qui vide la dernière page) :
 * recalage sur la dernière page existante plutôt qu'un faux vide.
 */
export function useClampPage(
  totalPages: number | undefined,
  isStale: boolean,
  page: number,
  setPage: (page: number, options?: { replace?: boolean }) => void,
) {
  useEffect(() => {
    if (totalPages === undefined || isStale) return;
    const lastPage = Math.max(0, totalPages - 1);
    if (page > lastPage) setPage(lastPage, { replace: true });
  }, [totalPages, isStale, page, setPage]);
}
