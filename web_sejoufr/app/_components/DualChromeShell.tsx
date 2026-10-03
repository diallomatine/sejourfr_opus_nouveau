"use client";

import { AppShell } from "./shell/AppShell";
import { useAuth } from "@/lib/auth-context";

/**
 * Wrap pour les routes "duales" (/entrainement, /examens-blancs, /sessions,
 * /diagnostic) : un compte y retrouve le même shell que les routes du groupe
 * `(app)/` (`AppShell`) ; les routes étant hors du groupe, son layout n'y est
 * pas accessible.
 *
 * Visiteur : pas de shell — le contenu est rendu tel quel sous le chrome
 * public (SiteHeader + Footer), qui reste visible sur les routes duales.
 */
export function DualChromeShell({ children }: { children: React.ReactNode }) {
  const { status } = useAuth();
  if (status !== "authenticated") {
    return (
      <div className="dual-shell-guest">
        {children}
        <style>{`
          .dual-shell-guest { min-height: 100vh; background: var(--color-paper); }
        `}</style>
      </div>
    );
  }
  return <AppShell>{children}</AppShell>;
}
