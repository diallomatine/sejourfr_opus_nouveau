import { AppSidebar } from "../_components/AppSidebar";
import { MobileSidebarToggle } from "../_components/MobileSidebarToggle";

/**
 * Layout des pages "espace personnel" (utilisateur connecté).
 *
 * - >= 900 px : grid 248px / 1fr, sidebar fixe à gauche.
 * - < 900 px  : sidebar fixe masquée, drawer mobile (bouton hamburger fixed
 *               top-left + drawer slide depuis la gauche). Cf. MobileSidebarToggle.
 *
 * La classe `app-shell--has-drawer` est ce qui dit aux styles globaux de
 * cacher la version "horizontale scrollable" de l'AppSidebar sous 900 px.
 */
export default function AppGroupLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="app-shell app-shell--has-drawer">
      <AppSidebar />
      <MobileSidebarToggle />
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
          /* Filet de sécurité : aucune page ne doit déclencher de scroll
             horizontal. Si un enfant déborde (table, image, etc.), il est
             clippé sans afficher de barre de scroll. */
          overflow-x: clip;
        }
        @media (max-width: 900px) {
          .app-shell {
            grid-template-columns: 1fr;
          }
          /* Le burger flottant (.ms-toggle) est z-index 70, au-dessus du
             SiteHeader sticky (z-index 50). Pas besoin de padding-top : le
             main reprend directement sous le SiteHeader. */
        }
      `}</style>
    </div>
  );
}
