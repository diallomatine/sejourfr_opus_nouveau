import { AppSidebar } from "../_components/AppSidebar";

/**
 * Layout des pages "espace personnel" (utilisateur connecté).
 * Le SiteHeader global est masqué sur ces routes (cf. SiteHeader.tsx) :
 * la sidebar à gauche devient l'unique navigation, en pleine hauteur,
 * comme dans la maquette dashboard.
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
          grid-template-columns: 248px 1fr;
          min-height: 100vh;
          background: #F7F8FC;
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
