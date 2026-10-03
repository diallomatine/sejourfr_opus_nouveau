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
 * **Le titre fourni PAR LA PAGE à la barre du haut du shell** (`AppTopBar`) —
 * il nomme la page du fil d'Ariane sur un sous-écran.
 *
 * 🛑 `lib/app-bar.ts` reste l'autorité par défaut : une route, un titre. Ce
 * relais sert aux titres **portés par la page** : le titre du `ScreenHeader`
 * Flutter d'un sous-écran (`DetailShell`, `SkillShell`) et la nature d'une
 * session (`/sessions/[attemptId]`). Une page qui ne dit rien garde le titre
 * de la table. L'en-tête de la page, lui, reste affiché.
 *
 * Il porte aussi la **flèche de retour** d'un sous-écran (`useAppBarBack`),
 * posée dans la barre à côté du burger (2026-09-27).
 *
 * Monté par le shell connecté (`AppShell`) : hors shell, les deux hooks ne
 * font rien — la page garde alors son propre lien de retour.
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
      if (cur?.id === id && cur.info.title === info.title) {
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

/** La flèche posée par la page, `null` ⇒ aucune. Lu par `AppTopBar`. */
export function useAppBarBackOverride(): AppBarBack | null {
  return useContext(BackValueContext);
}

/**
 * **Le sous-écran pose une flèche de retour dans la barre du haut**, à côté du
 * burger (≤ 1024 px). `back: null` ⇒ pas de flèche.
 *
 * Rend `true` quand une barre porte la flèche (shell connecté) : la page
 * masque alors son propre lien de retour (classe globale `in-bar-back`).
 * Visiteur : aucune barre, le lien reste.
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

/** La page donne son titre à la barre. `info: null` ⇒ elle ne dit rien. */
export function useAppBarTitle(info: AppBarInfo | null): void {
  const set = useContext(SetterContext);
  const id = useId();
  const title = info?.title;

  useLayoutEffect(() => {
    if (!set || !title) return;
    set(id, { title });
    return () => set(id, null);
  }, [set, id, title]);
}
