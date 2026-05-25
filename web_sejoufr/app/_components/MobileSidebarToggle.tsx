"use client";

import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { Menu, X } from "lucide-react";
import { AppSidebar } from "./AppSidebar";

/**
 * Drawer mobile pour l'espace connecté.
 *
 * Sur >= 900px : ne rend rien (la sidebar fixe à gauche du shell prend le relais).
 * Sur < 900px : affiche un bouton hamburger fixed top-left + un drawer slidable
 * depuis la gauche avec overlay cliquable et bouton X. Se ferme automatiquement
 * sur changement de route (usePathname).
 *
 * Le shell parent (AppShell ou DualChromeShell) ajoute la classe
 * `app-shell--has-drawer` sur son root, ce qui masque la sidebar fixe
 * directement en CSS via globals.css. Le drawer enveloppe une 2e instance
 * d'AppSidebar dans `.ms-drawer-inner` ; les overrides CSS sont dans
 * globals.css (sélecteurs `.ms-drawer-inner .app-sidebar ...`).
 */
export function MobileSidebarToggle() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  // Ferme le drawer dès que la route change.
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setOpen(false);
  }, [pathname]);

  // Lock le scroll de la page quand le drawer est ouvert. `overflow: hidden`
  // sur body ne suffit PAS sur iOS Safari (la page derrière scrolle quand même).
  // On fige le body en position: fixed à la position courante, puis on restaure
  // le scroll à la fermeture — technique fiable cross-navigateur, notamment iOS.
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

  // Échap = ferme
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
      <button
        type="button"
        className="ms-toggle"
        aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <Menu size={20} aria-hidden />
      </button>

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
            // usePathname() ignore les query params : cliquer un lien vers la
            // même route (ex. /revision?tab=favoris) ou la route courante ne
            // déclenche pas l'auto-close par pathname. On ferme donc dès qu'un
            // lien ou bouton du drawer est cliqué, quel que soit le cas.
            if ((e.target as HTMLElement).closest("a, button")) setOpen(false);
          }}
        >
          <AppSidebar />
        </div>
      </div>
    </>
  );
}
