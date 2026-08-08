/**
 * Cache mémoire de données, partagé par toute la session de navigation.
 *
 * Motif : le parcours TCF EE/EO est routé écran par écran (un mode = une route,
 * une tâche = une route). Chaque bascule remontait les composants et relançait
 * les mêmes `fetch` — alors que les compétences, les sujets et les exemples sont
 * du **contenu éditorial stable** : une fois par session suffit.
 *
 * Ce module ne dépend de rien (ni React, ni `lib/api`) : il est testable au
 * runner natif de Node (`data-cache.test.ts`) et ne peut pas entraîner de cycle
 * d'import. **Aucune librairie de cache n'a été ajoutée au projet** — le besoin
 * tient en une `Map` et une règle d'invalidation.
 *
 * Trois règles à ne pas défaire :
 *
 * 1. **Rien n'expire tout seul.** Pas de TTL, pas de revalidation d'arrière-plan :
 *    une donnée périmée le devient parce qu'on a écrit quelque chose, et on
 *    l'invalide alors **explicitement** (cf. `lib/api.ts`, où chaque mutation de
 *    production / de compétence purge ce qu'elle vient de rendre faux). Un TTL
 *    ramènerait exactement les appels réseau que ce cache supprime.
 * 2. **Une erreur ne se met pas en cache.** Un échec efface l'entrée : le prochain
 *    écran retente, au lieu de rejouer indéfiniment la même panne.
 * 3. **Le cache est un objet de navigateur.** Le singleton exporté est
 *    **désactivé côté serveur** : une `Map` de module y serait partagée entre les
 *    requêtes de tous les utilisateurs, donc entre leurs progressions.
 */

export interface DataCache {
  /**
   * Valeur de `key`, chargée au plus une fois. Un chargement déjà en vol est
   * **partagé** (deux écrans montés en même temps ne font qu'un appel).
   */
  cached<T>(key: string, loader: () => Promise<T>): Promise<T>;
  /**
   * Valeur déjà résolue, **synchronement** — c'est ce qui permet à un écran de
   * peindre sa donnée dès la première image, sans squelette. `undefined` quand
   * rien n'est chargé (ou qu'un chargement est encore en vol).
   */
  peek<T>(key: string): T | undefined;
  /** Purge toutes les clés commençant par `prefix`. Renvoie le nombre d'entrées
   *  retirées (les chargements en vol sont détachés : leur résultat ne
   *  reviendra pas s'écrire par-dessus). */
  invalidate(prefix: string): number;
  /** Vide tout — au changement d'utilisateur, jamais « au cas où ». */
  clear(): void;
  /** Nombre d'entrées connues (chargées ou en vol). Sert aux tests. */
  size(): number;
}

interface Entry {
  value?: unknown;
  resolved: boolean;
  promise?: Promise<unknown>;
}

/**
 * Fabrique une instance isolée. Les tests s'en servent pour compter les appels
 * d'un client factice sans toucher au cache de l'application.
 *
 * `enabled: false` rend un cache **transparent** : chaque `cached()` appelle son
 * loader et rien n'est retenu. C'est le mode du rendu serveur.
 */
export function createDataCache(options: {enabled?: boolean} = {}): DataCache {
  const enabled = options.enabled ?? true;
  const store = new Map<string, Entry>();

  function cached<T>(key: string, loader: () => Promise<T>): Promise<T> {
    if (!enabled) return loader();

    const hit = store.get(key);
    if (hit?.resolved) return Promise.resolve(hit.value as T);
    if (hit?.promise) return hit.promise as Promise<T>;

    const entry: Entry = {resolved: false};
    const promise = loader().then(
      (value) => {
        // L'entrée a pu être invalidée pendant le vol : on ne réécrit alors
        // rien, sinon une invalidation explicite serait silencieusement annulée
        // par la réponse qu'elle venait de rendre caduque.
        if (store.get(key) === entry) {
          entry.value = value;
          entry.resolved = true;
          entry.promise = undefined;
        }
        return value;
      },
      (err: unknown) => {
        if (store.get(key) === entry) store.delete(key);
        throw err;
      },
    );
    entry.promise = promise;
    store.set(key, entry);
    return promise;
  }

  function peek<T>(key: string): T | undefined {
    const hit = store.get(key);
    return hit?.resolved ? (hit.value as T) : undefined;
  }

  function invalidate(prefix: string): number {
    let removed = 0;
    for (const key of [...store.keys()]) {
      if (key.startsWith(prefix)) {
        store.delete(key);
        removed += 1;
      }
    }
    return removed;
  }

  return {
    cached,
    peek,
    invalidate,
    clear: () => store.clear(),
    size: () => store.size,
  };
}

/** Cache de l'application. Inerte au rendu serveur (cf. règle 3 en tête). */
export const dataCache: DataCache = createDataCache({
  enabled: typeof window !== "undefined",
});

export const cached: DataCache["cached"] = (key, loader) => dataCache.cached(key, loader);
export const peekCached: DataCache["peek"] = (key) => dataCache.peek(key);
export const invalidateCache: DataCache["invalidate"] = (prefix) => dataCache.invalidate(prefix);
export const clearDataCache: DataCache["clear"] = () => dataCache.clear();
