"use client";

import { usePathname } from "next/navigation";
import { AppSidebar } from "../_components/AppSidebar";
import { MobileSidebarToggle } from "../_components/MobileSidebarToggle";
import { useAuth } from "@/lib/auth-context";

/**
 * Routes du groupe `(app)/` qui restent accessibles à un VISITEUR non
 * connecté — aujourd'hui la seule : `/diagnostic-civique`, dont le diagnostic
 * se joue avant la création de compte (V053, `docs/regles/diagnostic.md`).
 * Physiquement dans `(app)/` (pour partager `AppSidebar`/`MobileSidebarToggle`
 * avec un compte connecté, cf. règle des deux burgers ci-dessous), elle reste
 * la seule route du groupe qu'un invité rend réellement — les autres sont
 * soit protégées par `middleware.ts`, soit redirigent côté client via
 * `useAuth`, donc un invité n'y voit jamais ce layout longtemps.
 *
 * 🛑 N'ajouter ici QUE des routes explicitement duales (guest + connecté).
 * Une route ajoutée par erreur perdrait sa sidebar pour tout le monde tant
 * que `useAuth` n'a pas résolu.
 */
const GUEST_ACCESSIBLE_PREFIXES = ["/diagnostic-civique"];

function isGuestAccessibleRoute(pathname: string | null): boolean {
  if (!pathname) return false;
  return GUEST_ACCESSIBLE_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

/**
 * Layout des pages "espace personnel" (utilisateur connecté).
 *
 * - >= 900 px : grid 248px / 1fr, sidebar fixe à gauche.
 * - < 900 px  : sidebar fixe masquée, drawer mobile (bouton hamburger fixed
 *               top-left + drawer slide depuis la gauche). Cf. MobileSidebarToggle.
 *
 * La classe `app-shell--has-drawer` est ce qui dit aux styles globaux de
 * cacher la version "horizontale scrollable" de l'AppSidebar sous 900 px.
 *
 * 🛑 **Le menu latéral ne s'affiche JAMAIS à un invité sur une route duale**
 * (`GUEST_ACCESSIBLE_PREFIXES`) : `AppSidebar`/`MobileSidebarToggle` n'ont
 * aucune garde d'auth (ils s'affichent même sans `user`), donc sans ce test
 * un visiteur non connecté sur `/diagnostic-civique` voyait le menu de
 * l'espace personnel avant même d'avoir de compte. Comportement inchangé
 * pour toutes les autres routes du groupe : elles n'appellent jamais
 * `isGuestAccessibleRoute` à `true`, donc le rendu ne dépend toujours pas de
 * `useAuth` (pas de flash au chargement).
 */
export default function AppGroupLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { status } = useAuth();
  const hideAppShell = isGuestAccessibleRoute(pathname) && status !== "authenticated";

  if (hideAppShell) {
    return (
      <div className="app-shell-guest">
        {children}
        <style>{`
          .app-shell-guest {
            min-height: 100vh;
            background: #F7F8FC;
          }
        `}</style>
      </div>
    );
  }

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
