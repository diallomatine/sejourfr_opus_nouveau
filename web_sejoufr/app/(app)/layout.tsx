import { AppSidebar } from "../_components/AppSidebar";

/**
 * Layout des pages "espace personnel" (utilisateur connecté) :
 *   /dashboard, /entrainement, /examens-blancs, /paiement, /paiement/succes.
 *
 * Injecte une sidebar à gauche + main à droite, en plus du SiteHeader rendu
 * par le root layout. Le middleware redirige déjà vers /connexion si le
 * cookie d'auth est absent, donc on peut considérer que le user est connecté
 * à ce niveau (mais AppSidebar lit useAuth pour gérer le rendu pendant
 * l'hydratation).
 */
export default function AppGroupLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="app-shell">
      <AppSidebar />
      <div className="app-shell__main">{children}</div>

      <style>{`
        .app-shell {
          display: grid;
          grid-template-columns: 260px 1fr;
          min-height: calc(100vh - 110px);
          background: var(--color-paper);
        }
        .app-shell__main {
          min-width: 0;
        }
        @media (max-width: 900px) {
          .app-shell {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </div>
  );
}
