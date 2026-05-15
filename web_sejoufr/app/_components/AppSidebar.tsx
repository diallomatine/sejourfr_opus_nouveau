"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth-context";

/**
 * Sidebar partagée par les pages "app" (utilisateur connecté) : /dashboard,
 * /entrainement, /examens-blancs, /paiement. Rendue par
 * `app/(app)/layout.tsx`, donc disponible automatiquement sur toutes les
 * routes du route group sans intervention par page.
 */
export function AppSidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
    router.push("/");
  };

  const initial =
    user?.firstName?.[0]?.toUpperCase() ??
    user?.email?.[0]?.toUpperCase() ??
    "?";

  return (
    <aside className="app-sidebar">
      <div className="app-sidebar__brand">
        <span className="app-cocarde" aria-hidden />
        <div>
          <div className="app-brand-name">
            Sejour<span className="app-brand-fr">FR</span>
          </div>
          <div className="app-brand-tag">ESPACE PERSONNEL</div>
        </div>
      </div>

      <nav className="app-nav">
        <span className="app-nav__section">Pilotage</span>
        <SideLink href="/dashboard" pathname={pathname}>
          ↳ Tableau de bord
        </SideLink>

        <span className="app-nav__section">Pratiquer</span>
        <SideLink href="/entrainement" pathname={pathname}>
          ↳ Entraînement
        </SideLink>
        <SideLink href="/examens-blancs" pathname={pathname}>
          ↳ Examens blancs
        </SideLink>

        <span className="app-nav__section">Compte</span>
        <SideLink href="/paiement" pathname={pathname}>
          ↳ Mon abonnement
        </SideLink>
      </nav>

      {user && (
        <div className="app-sidebar__foot">
          <div className="app-user">
            <span className="app-avatar">{initial}</span>
            <div className="app-user__info">
              <div className="app-user__name">
                {user.firstName ?? "Utilisateur"} {user.lastName ?? ""}
              </div>
              <div className="app-user__email">{user.email}</div>
            </div>
          </div>
          <button
            type="button"
            className="app-logout"
            onClick={handleLogout}
          >
            Se déconnecter
          </button>
        </div>
      )}

      <style>{sidebarStyles}</style>
    </aside>
  );
}

function SideLink({
  href,
  pathname,
  children,
}: {
  href: string;
  pathname: string | null;
  children: React.ReactNode;
}) {
  const isActive =
    pathname === href || (href !== "/dashboard" && pathname?.startsWith(`${href}/`));
  return (
    <Link href={href} className={`app-nav__item ${isActive ? "is-active" : ""}`}>
      {children}
    </Link>
  );
}

const sidebarStyles = `
  .app-sidebar {
    background: #fff;
    border-right: 1px solid var(--color-line);
    padding: 24px 18px 18px;
    display: flex; flex-direction: column;
    position: sticky;
    top: 110px;
    height: calc(100vh - 110px);
    overflow-y: auto;
  }

  .app-sidebar__brand {
    display: flex; gap: 12px; align-items: center;
    padding: 4px 8px 22px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 14px;
  }
  .app-cocarde {
    width: 28px; height: 28px;
    border-radius: 50%;
    background:
      radial-gradient(circle, var(--color-red) 0 22%, transparent 22%),
      radial-gradient(circle, #fff 0 55%, transparent 55%),
      var(--color-blue);
    flex-shrink: 0;
  }
  .app-brand-name {
    font-family: var(--font-display);
    font-weight: 600; font-size: 17px;
    color: var(--color-blue);
    letter-spacing: -0.015em; line-height: 1;
  }
  .app-brand-fr { color: var(--color-red); }
  .app-brand-tag {
    font-family: var(--font-mono);
    font-size: 9px; letter-spacing: 0.14em;
    color: var(--color-muted); margin-top: 2px;
  }

  .app-nav { flex: 1; display: flex; flex-direction: column; gap: 1px; }
  .app-nav__section {
    font-family: var(--font-mono);
    font-size: 9.5px; letter-spacing: 0.16em;
    color: var(--color-muted-2);
    text-transform: uppercase;
    padding: 14px 12px 6px;
  }
  .app-nav__item {
    text-decoration: none;
    display: block;
    padding: 9px 12px;
    border-radius: 8px;
    font-size: 13.5px;
    color: var(--color-ink-2);
    transition: background 0.1s;
  }
  .app-nav__item:hover { background: var(--color-blue-soft); color: var(--color-blue); }
  .app-nav__item.is-active {
    background: var(--color-blue-light);
    color: var(--color-blue);
    font-weight: 600;
  }

  .app-sidebar__foot {
    border-top: 1px solid var(--color-line-2);
    padding-top: 16px;
    margin-top: 16px;
  }
  .app-user {
    display: flex; align-items: center; gap: 10px;
    padding: 8px 6px 12px;
  }
  .app-avatar {
    width: 36px; height: 36px;
    border-radius: 50%;
    background: var(--color-blue); color: #fff;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 14px;
    flex-shrink: 0;
  }
  .app-user__name {
    font-size: 13px; font-weight: 600; color: var(--color-ink);
    line-height: 1.2;
  }
  .app-user__email {
    font-size: 11px; color: var(--color-muted);
    word-break: break-all;
    line-height: 1.3; margin-top: 2px;
  }
  .app-logout {
    width: 100%;
    padding: 10px 12px;
    background: none;
    border: 1px solid var(--color-line);
    border-radius: 8px;
    font-family: var(--font-sans);
    font-size: 12.5px;
    color: var(--color-muted);
    cursor: pointer;
    transition: all 0.15s;
  }
  .app-logout:hover {
    background: var(--color-red-light);
    color: var(--color-red);
    border-color: rgba(225, 55, 47, 0.3);
  }

  @media (max-width: 900px) {
    .app-sidebar {
      position: static;
      height: auto;
      flex-direction: row;
      align-items: center;
      padding: 12px 18px;
      border-right: none;
      border-bottom: 1px solid var(--color-line);
      gap: 16px;
    }
    .app-sidebar__brand {
      border-bottom: none; padding: 0; margin: 0; flex: 1;
    }
    .app-nav {
      display: flex; flex-direction: row;
      gap: 4px; overflow-x: auto;
      flex: none;
    }
    .app-nav__section { display: none; }
    .app-nav__item { padding: 7px 12px; font-size: 12.5px; white-space: nowrap; }
    .app-sidebar__foot {
      display: none;
    }
  }
`;
