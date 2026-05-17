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
    setOpen(false);
  }, [pathname]);

  // Lock le scroll body quand le drawer est ouvert.
  useEffect(() => {
    if (typeof document === "undefined") return;
    if (open) {
      const prev = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      return () => {
        document.body.style.overflow = prev;
      };
    }
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
        <div className="ms-drawer-inner">
          <AppSidebar />
        </div>
      </div>
    </>
  );
}
