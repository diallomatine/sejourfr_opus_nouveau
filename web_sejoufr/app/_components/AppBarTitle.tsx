"use client";

import {
  createContext,
  useCallback,
  useContext,
  useId,
  useLayoutEffect,
  useState,
  type ReactNode,
} from "react";
import type { AppBarInfo } from "@/lib/app-bar";

/**
 * **Le titre de la barre du haut fourni PAR LA PAGE** (`AppTopBar`, ≤ 900 px).
 *
 * 🛑 `lib/app-bar.ts` reste l'autorité par défaut : une route, un titre. Ce
 * relais ne sert qu'aux titres **dynamiques**, portés par une donnée servie
 * (l'objectif du Plan, qui change avec la bascule TCF / civique). Une page qui
 * ne dit rien garde le titre de la table.
 *
 * Monté par les deux shells connectés (`app/(app)/layout.tsx`,
 * `DualChromeShell`) : hors shell, `useAppBarTitle` ne fait rien et rend
 * `false` — la page garde alors son propre en-tête, il n'y a pas de barre.
 */
type Setter = (id: string, info: AppBarInfo | null) => void;
type Entry = { id: string; info: AppBarInfo };

const SetterContext = createContext<Setter | null>(null);
const ValueContext = createContext<AppBarInfo | null>(null);

export function AppBarProvider({ children }: { children: ReactNode }) {
  const [entry, setEntry] = useState<Entry | null>(null);

  const set = useCallback<Setter>((id, info) => {
    setEntry((cur) => {
      if (!info) return cur?.id === id ? null : cur;
      if (
        cur?.id === id &&
        cur.info.title === info.title &&
        cur.info.subtitle === info.subtitle
      ) {
        return cur;
      }
      return { id, info };
    });
  }, []);

  return (
    <SetterContext.Provider value={set}>
      <ValueContext.Provider value={entry?.info ?? null}>{children}</ValueContext.Provider>
    </SetterContext.Provider>
  );
}

/** Le titre posé par la page, `null` si elle n'en pose pas. Lu par `AppTopBar`. */
export function useAppBarOverride(): AppBarInfo | null {
  return useContext(ValueContext);
}

/**
 * La page donne son titre à la barre. `info: null` ⇒ elle ne dit rien.
 *
 * Rend `true` quand une barre est là pour le porter (shell connecté) : la page
 * peut alors effacer à l'œil son propre en-tête sous 900 px. La valeur est
 * connue dès le rendu serveur (présence du provider), donc sans décalage
 * d'hydratation ; seul le texte de la barre part du titre de la table, puis
 * bascule avant la première peinture côté client (`useLayoutEffect`).
 */
export function useAppBarTitle(info: AppBarInfo | null): boolean {
  const set = useContext(SetterContext);
  const id = useId();
  const title = info?.title;
  const subtitle = info?.subtitle;

  useLayoutEffect(() => {
    if (!set || !title) return;
    set(id, { title, subtitle });
    return () => set(id, null);
  }, [set, id, title, subtitle]);

  return set !== null && Boolean(title);
}
