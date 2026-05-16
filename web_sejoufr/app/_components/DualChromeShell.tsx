"use client";

import { AppSidebar } from "./AppSidebar";

/**
 * Wrap pour les routes "duales" (/entrainement, /examens-blancs, /sessions)
 * quand l'utilisateur est connecté : restaure le même app-shell que les
 * routes du group `(app)/` (sidebar 248px + main). Les routes étant hors du
 * group, le layout `(app)/layout.tsx` n'est pas accessible — on duplique sa
 * structure inline ici.
 *
 * NB : à utiliser uniquement quand `useAuth().status === "authenticated"`.
 * Le rendu guest doit rester sous le chrome public (SiteHeader + Footer).
 */
export function DualChromeShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="dual-shell">
      <AppSidebar />
      <div className="dual-shell__main">{children}</div>
      <style>{`
        .dual-shell {
          display: grid;
          grid-template-columns: 248px 1fr;
          min-height: 100vh;
          background: #F7F8FC;
        }
        .dual-shell__main { min-width: 0; }
        @media (max-width: 900px) {
          .dual-shell { grid-template-columns: 1fr; }
        }
      `}</style>
    </div>
  );
}
