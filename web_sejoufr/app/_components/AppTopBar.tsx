"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { Menu, X } from "lucide-react";
import { AppSidebar } from "./AppSidebar";
import { appBarInfo } from "@/lib/app-bar";

/**
 * **La barre du haut de l'espace connecté, sous 900 px** — le pendant web de
 * l'en-tête des écrans Flutter : burger à gauche (ouvre le tiroir de
 * navigation), titre de la page, et une ligne de contexte courte.
 *
 * - ≥ 901 px : ne rend rien de visible (la barre latérale du shell prend le
 *   relais) ;
 * - ≤ 900 px : barre `position: sticky` en tête de la colonne de contenu —
 *   elle occupe sa place dans le flux, aucune page n'a donc à « dégager » de
 *   gouttière pour elle.
 *
 * 🛑 Titre : `appBarInfo` (`lib/app-bar.ts`), et rien d'autre.
 * 🛑 Montée par `app/(app)/layout.tsx` et `DualChromeShell` **uniquement**,
 * sous la garde de `isAppShellMounted` : un seul burger par écran.
 *
 * Le tiroir enveloppe une 2ᵉ instance d'`AppSidebar` dans `.ms-drawer-inner`
 * (overrides dans `globals.css`, partagés avec le tiroir du `SiteHeader`).
 * Il se ferme au changement de route, à Échap, au clic sur l'overlay ou sur un
 * lien.
 */
export function AppTopBar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setOpen(false);
  }, [pathname]);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 4);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // `overflow: hidden` sur body ne suffit PAS sur iOS Safari : on fige le body
  // en position: fixed à la position courante, puis on restaure le scroll.
  useEffect(() => {
    if (typeof document === "undefined" || !open) return;
    const body = document.body;
    const scrollY = window.scrollY;
    const prev = {
      position: body.style.position,
      top: body.style.top,
      left: body.style.left,
      right: body.style.right,
      width: body.style.width,
    };
    body.style.position = "fixed";
    body.style.top = `-${scrollY}px`;
    body.style.left = "0";
    body.style.right = "0";
    body.style.width = "100%";
    return () => {
      body.style.position = prev.position;
      body.style.top = prev.top;
      body.style.left = prev.left;
      body.style.right = prev.right;
      body.style.width = prev.width;
      window.scrollTo(0, scrollY);
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  return (
    <>
      <header className={`atb${scrolled ? " is-scrolled" : ""}`}>
        <button
          type="button"
          className="atb-burger"
          aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          <Menu size={20} aria-hidden />
        </button>
        <Suspense fallback={<AppTopBarTitle pathname={pathname} />}>
          <AppTopBarTitleWithQuery pathname={pathname} />
        </Suspense>
      </header>

      {open && (
        <div
          className="ms-overlay"
          onClick={() => setOpen(false)}
          aria-hidden
        />
      )}

      <div
        className={`ms-drawer${open ? " is-open" : ""}`}
        role="dialog"
        aria-modal={open ? "true" : undefined}
        aria-hidden={!open}
      >
        <button
          type="button"
          className="ms-close"
          onClick={() => setOpen(false)}
          aria-label="Fermer le menu"
        >
          <X size={18} aria-hidden />
        </button>
        <div
          className="ms-drawer-inner"
          onClick={(e) => {
            // usePathname() ignore les query params : un lien vers la même
            // route (ex. /entrainement?module=TCF) ne ferme pas le tiroir par
            // changement de chemin. On ferme donc dès qu'un lien ou bouton est
            // cliqué.
            if ((e.target as HTMLElement).closest("a, button")) setOpen(false);
          }}
        >
          <AppSidebar />
        </div>
      </div>
    </>
  );
}

/** `useSearchParams` exige une frontière Suspense : seul Réviser le lit. */
function AppTopBarTitleWithQuery({ pathname }: { pathname: string | null }) {
  const searchParams = useSearchParams();
  return <AppTopBarTitle pathname={pathname} searchParams={searchParams} />;
}

function AppTopBarTitle({
  pathname,
  searchParams,
}: {
  pathname: string | null;
  searchParams?: { get(name: string): string | null } | null;
}) {
  const { title, subtitle } = appBarInfo(pathname, searchParams);
  return (
    <div className="atb-titles">
      <span className="atb-title">{title}</span>
      {subtitle ? <span className="atb-sub">{subtitle}</span> : null}
    </div>
  );
}
