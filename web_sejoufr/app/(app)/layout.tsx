"use client";

import { usePathname } from "next/navigation";
import { AppShell } from "../_components/shell/AppShell";
import { useAuth } from "@/lib/auth-context";
import { isAppShellMounted } from "@/lib/chrome-routes";

/**
 * Layout des pages "espace personnel" (utilisateur connecté) : le shell de la
 * Navigation v2 (`AppShell` — barre latérale, barre du haut, tiroir ≤ 1024 px).
 *
 * 🛑 **Shell monté ou non : `isAppShellMounted` (`lib/chrome-routes.ts`),
 * et rien d'autre.** `SiteHeader` lit la même fonction pour cacher son propre
 * burger — un invité ne voit jamais le menu de l'espace personnel, et les deux
 * burgers ne s'empilent plus (ni pour un invité, ni pendant le chargement).
 */
export default function AppGroupLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { status } = useAuth();

  if (!isAppShellMounted(pathname, status)) {
    return (
      <div className="app-shell-guest">
        {children}
        <style>{`
          .app-shell-guest {
            min-height: 100vh;
            background: var(--color-paper);
          }
        `}</style>
      </div>
    );
  }

  return <AppShell>{children}</AppShell>;
}
