"use client";

import {useCallback, useEffect, useRef, useState} from "react";
import {ApiException} from "./api";
import {invalidateCache, peekCached} from "./data-cache";

/**
 * Branche un écran sur une donnée déjà chargée ailleurs — sans squelette, sans
 * appel réseau, et sans que le composant ait à savoir d'où elle vient.
 *
 * Le contrat, en une phrase : **`key` est la clé sous laquelle `loader` range sa
 * donnée** (`loadSectionSkills` range sous `skillsSectionKey`, etc.). C'est ce
 * qui permet de peindre la valeur dès la première image (`peek` est
 * synchrone) et de laisser le `loader` décider s'il y a un appel à faire.
 * Le hook ne met **rien** en cache lui-même : le loader en est seul
 * responsable, sinon la clé serait verrouillée deux fois et le chargement
 * s'attendrait lui-même.
 *
 * `key = null` désactive tout (utilisateur pas encore authentifié, paramètre de
 * route invalide) : ni appel, ni état de chargement.
 */
export interface CachedData<T> {
  /** `undefined` tant que rien n'est disponible — jamais un tableau vide qui
   *  ferait afficher « aucun résultat » sur une donnée en route. */
  data: T | undefined;
  /** Vrai **seulement** quand il n'y a rien à montrer. Une donnée déjà connue
   *  n'affiche jamais de squelette, même si un rechargement est en cours. */
  loading: boolean;
  error: string | null;
  /** Purge la clé et recharge. Pour un bouton « Réessayer », pas pour une
   *  revalidation d'arrière-plan : le cache n'expire pas tout seul. */
  reload: () => void;
}

export function useCachedData<T>(
  key: string | null,
  loader: () => Promise<T>,
  options: {errorMessage?: string} = {},
): CachedData<T> {
  const fallbackMessage = options.errorMessage ?? "Impossible de charger ces données.";

  // Le loader est ré-créé à chaque rendu par l'appelant : le garder dans une
  // ref évite de relancer le chargement pour une simple identité de fonction.
  // Mis à jour dans un effet **déclaré avant** celui qui charge, donc exécuté
  // avant lui : la ref est toujours à jour quand le chargement démarre.
  const loaderRef = useRef(loader);
  useEffect(() => {
    loaderRef.current = loader;
  });

  const [state, setState] = useState<{key: string | null; data: T | undefined; error: string | null}>(
    () => ({key, data: key ? peekCached<T>(key) : undefined, error: null}),
  );
  const [attempt, setAttempt] = useState(0);

  // Changement de clé : on repart de ce que le cache sait déjà, sans passer par
  // un état vide (dérivation pure — pas de setState pendant le rendu).
  const fresh = state.key === key;
  const data = fresh ? state.data : key ? peekCached<T>(key) : undefined;
  const error = fresh ? state.error : null;

  useEffect(() => {
    if (!key) return;
    let cancelled = false;
    loaderRef
      .current()
      .then((value) => {
        if (!cancelled) setState({key, data: value, error: null});
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setState({
          key,
          data: undefined,
          error: e instanceof ApiException ? e.message : fallbackMessage,
        });
      });
    return () => {
      cancelled = true;
    };
  }, [key, attempt, fallbackMessage]);

  const reload = useCallback(() => {
    if (key) invalidateCache(key);
    setAttempt((n) => n + 1);
  }, [key]);

  return {data, loading: key != null && data === undefined && error === null, error, reload};
}
