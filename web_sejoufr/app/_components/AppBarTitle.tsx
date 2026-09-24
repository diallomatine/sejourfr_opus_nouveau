"use client";

import {
  createContext,
  useCallback,
  useContext,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import type { AppBarInfo } from "@/lib/app-bar";

/**
 * **Le titre de la barre du haut fourni PAR LA PAGE** (`AppTopBar`, ≤ 900 px).
 *
 * 🛑 `lib/app-bar.ts` reste l'autorité par défaut : une route, un titre. Ce
 * relais sert aux titres **portés par la page** : l'objectif du Plan, et le
 * titre + contexte du `ScreenHeader` Flutter d'un sous-écran (`DetailShell`,
 * `SkillShell`). Une page qui ne dit rien garde le titre de la table.
 *
 * Il porte aussi la **flèche de retour** d'un sous-écran (`useAppBarBack`),
 * qui remplace le burger de la barre.
 *
 * Monté par les deux shells connectés (`app/(app)/layout.tsx`,
 * `DualChromeShell`) : hors shell, `useAppBarTitle` ne fait rien et rend
 * `false` — la page garde alors son propre en-tête, il n'y a pas de barre.
 */
type Setter = (id: string, info: AppBarInfo | null) => void;
type Entry = { id: string; info: AppBarInfo };

const SetterContext = createContext<Setter | null>(null);
const ValueContext = createContext<AppBarInfo | null>(null);

/**
 * **La flèche de retour de la barre**, posée par un sous-écran.
 *
 * `fallbackHref` : l'adresse parente, celle du lien de retour de la page —
 * rejointe seulement quand l'onglet n'a pas d'écran SejourFR précédent
 * (`retourOuRepli`). `onBack` : la page intercepte le retour (confirmation
 * avant de quitter une session), comme son propre bouton le faisait.
 */
export type AppBarBack = { fallbackHref: string; onBack?: () => void };
type BackSetter = (id: string, back: AppBarBack | null, hasHandler: boolean) => void;
type BackEntry = { id: string; back: AppBarBack; hasHandler: boolean };

const BackSetterContext = createContext<BackSetter | null>(null);
const BackValueContext = createContext<AppBarBack | null>(null);

export function AppBarProvider({ children }: { children: ReactNode }) {
  const [entry, setEntry] = useState<Entry | null>(null);
  const [backEntry, setBackEntry] = useState<BackEntry | null>(null);

  const setBack = useCallback<BackSetter>((id, back, hasHandler) => {
    setBackEntry((cur) => {
      if (!back) return cur?.id === id ? null : cur;
      if (
        cur?.id === id &&
        cur.back.fallbackHref === back.fallbackHref &&
        cur.hasHandler === hasHandler
      ) {
        return cur;
      }
      return { id, back, hasHandler };
    });
  }, []);

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
      <BackSetterContext.Provider value={setBack}>
        <ValueContext.Provider value={entry?.info ?? null}>
          <BackValueContext.Provider value={backEntry?.back ?? null}>
            {children}
          </BackValueContext.Provider>
        </ValueContext.Provider>
      </BackSetterContext.Provider>
    </SetterContext.Provider>
  );
}

/** La flèche posée par la page, `null` ⇒ burger. Lu par `AppTopBar`. */
export function useAppBarBackOverride(): AppBarBack | null {
  return useContext(BackValueContext);
}

/**
 * **Le sous-écran met une flèche de retour à la place du burger** (≤ 900 px),
 * comme l'`AppBar` Flutter d'un écran poussé. `back: null` ⇒ burger.
 *
 * Rend `true` quand une barre porte la flèche (shell connecté) : la page
 * masque alors son propre lien de retour sous 900 px (classe globale
 * `in-bar-back`). Desktop et visiteur : aucune barre, le lien reste.
 */
export function useAppBarBack(back: AppBarBack | null): boolean {
  const set = useContext(BackSetterContext);
  const id = useId();
  const fallbackHref = back?.fallbackHref;
  const onBack = back?.onBack;
  const hasHandler = Boolean(onBack);
  const onBackRef = useRef(onBack);

  useLayoutEffect(() => {
    onBackRef.current = onBack;
  });

  useLayoutEffect(() => {
    if (!set || !fallbackHref) return;
    set(
      id,
      {
        fallbackHref,
        onBack: hasHandler ? () => onBackRef.current?.() : undefined,
      },
      hasHandler,
    );
    return () => set(id, null, false);
  }, [set, id, fallbackHref, hasHandler]);

  return set !== null && Boolean(fallbackHref);
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
