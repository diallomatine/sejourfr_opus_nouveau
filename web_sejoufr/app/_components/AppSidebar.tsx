"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";

/**
 * Sidebar de l'espace personnel. Sticky pleine hauteur (le SiteHeader global
 * est masqué sur les routes (app)), avec icônes par item, badges dynamiques
 * sur "Mes erreurs" et "Favoris", carte upgrade pour les non-Premium, et
 * mini-carte utilisateur en bas. Calée sur la maquette dashboard-sejourfr.html.
 */
export function AppSidebar() {
  return (
    <Suspense fallback={<aside className="app-sidebar" aria-hidden />}>
      <AppSidebarInner />
    </Suspense>
  );
}

function AppSidebarInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const router = useRouter();
  const { user, status, logout } = useAuth();

  // Onglet courant de /revision pour différencier les deux entrées de sidebar
  // ("Mes erreurs" et "Favoris") qui pointent sur la même route.
  const revisionTab = searchParams?.get("tab") === "favoris" ? "favoris" : "erreurs";
  const isOnRevision = pathname === "/revision" || pathname?.startsWith("/revision/");

  // Module courant sur /entrainement, pour différencier les entrées
  // "TCF IRN" et "Examen civique" qui pointent sur la même route.
  const currentModule = searchParams?.get("module");
  const isOnEntrainement = pathname === "/entrainement";

  const [wrongCount, setWrongCount] = useState<number | null>(null);
  const [favCount, setFavCount] = useState<number | null>(null);

  // Compte le total des erreurs et favoris (tous modules). Best-effort,
  // silencieux si l'API tombe. Les badges disparaissent si compteur null.
  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    Promise.allSettled([
      userContentApi.wrong(),
      userContentApi.favorites(),
    ]).then(([w, f]) => {
      if (cancelled) return;
      if (w.status === "fulfilled") setWrongCount(w.value.length);
      if (f.status === "fulfilled") setFavCount(f.value.length);
    });
    return () => {
      cancelled = true;
    };
  }, [status]);

  const handleLogout = () => {
    logout();
    router.push("/");
  };

  const initial =
    user?.firstName?.[0]?.toUpperCase() ??
    user?.email?.[0]?.toUpperCase() ??
    "?";

  const fullName = user
    ? `${user.firstName ?? "Utilisateur"} ${user.lastName ?? ""}`.trim()
    : "";

  const showUpgrade = user && !user.isPremium;

  return (
    <aside className="app-sidebar">
      <Link href={user ? "/dashboard" : "/"} className="app-brand">
        <span className="app-cocarde" aria-hidden />
        <span className="app-brand-name">
          Sejour<span className="app-brand-fr">FR</span>
        </span>
      </Link>

      <nav className="app-nav" aria-label="Espace personnel">
        <span className="app-nav-section">Principal</span>
        <SideLink href="/dashboard" pathname={pathname} icon={<GridIcon />}>
          Tableau de bord
        </SideLink>
        <SideLink
          href="/entrainement?module=TCF"
          pathname={pathname}
          icon={<HeadphonesIcon />}
          activeWhen={() => isOnEntrainement && currentModule === "TCF"}
        >
          TCF IRN
        </SideLink>
        <SideLink
          href="/entrainement?module=CIVIQUE"
          pathname={pathname}
          icon={<LandmarkIcon />}
          activeWhen={() => isOnEntrainement && currentModule === "CIVIQUE"}
        >
          Examen civique
        </SideLink>
        <SideLink
          href="/examens-blancs"
          pathname={pathname}
          icon={<ClockCircleIcon />}
        >
          Examens blancs
        </SideLink>
        <SideLink href="/historique" pathname={pathname} icon={<HistoryIcon />}>
          Historique
        </SideLink>
        <SideLink href="/statistiques" pathname={pathname} icon={<BarsIcon />}>
          Statistiques
        </SideLink>

        <span className="app-nav-section">Révision</span>
        <SideLink
          href="/revision?tab=erreurs"
          activeWhen={() => isOnRevision && revisionTab === "erreurs"}
          pathname={pathname}
          icon={<XCircleIcon />}
          badge={wrongCount}
        >
          Mes erreurs
        </SideLink>
        <SideLink
          href="/revision?tab=favoris"
          activeWhen={() => isOnRevision && revisionTab === "favoris"}
          pathname={pathname}
          icon={<StarIcon />}
          badge={favCount}
        >
          Favoris
        </SideLink>

        <span className="app-nav-section">Compte</span>
        <SideLink href="/profil" pathname={pathname} icon={<UserIcon />}>
          Profil
        </SideLink>
      </nav>

      <div className="app-sidebar-foot">
        {showUpgrade && (
          <div className="upgrade-card">
            <h4>Passez Premium</h4>
            <p>Banque complète, examens illimités, révision ciblée.</p>
            <Link href="/paiement" className="upgrade-cta">
              Découvrir →
            </Link>
          </div>
        )}

        {user && (
          <button
            type="button"
            className="user-mini"
            onClick={handleLogout}
            title="Se déconnecter"
          >
            <span className="user-avatar">{initial}</span>
            <span className="user-info">
              <span className="user-name">{fullName || "Utilisateur"}</span>
              <span className="user-mail">{user.email}</span>
            </span>
            <span className="user-arrow" aria-hidden>
              ⏻
            </span>
          </button>
        )}
      </div>

      <style>{sidebarStyles}</style>
    </aside>
  );
}

function SideLink({
  href,
  pathname,
  icon,
  children,
  badge,
  activeWhen,
}: {
  href: string;
  pathname: string | null;
  icon: React.ReactNode;
  children: React.ReactNode;
  badge?: number | null;
  activeWhen?: (pathname: string | null) => boolean;
}) {
  const path = href.split("?")[0];
  const isActive = activeWhen
    ? activeWhen(pathname)
    : pathname === path ||
      (path !== "/dashboard" && pathname?.startsWith(`${path}/`));
  return (
    <Link href={href} className={`nav-item ${isActive ? "is-active" : ""}`}>
      <span className="nav-icon" aria-hidden>
        {icon}
      </span>
      <span className="nav-label">{children}</span>
      {badge !== null && badge !== undefined && badge > 0 && (
        <span className="nav-badge">{badge}</span>
      )}
    </Link>
  );
}

// ============================================================================
// Icons (lucide-style, 18×18)
// ============================================================================
const IconBase = (props: React.SVGProps<SVGSVGElement>) => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    {...props}
  />
);
const GridIcon = () => (
  <IconBase>
    <rect x="3" y="3" width="7" height="9" />
    <rect x="14" y="3" width="7" height="5" />
    <rect x="14" y="12" width="7" height="9" />
    <rect x="3" y="16" width="7" height="5" />
  </IconBase>
);
const HeadphonesIcon = () => (
  <IconBase>
    <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
    <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
  </IconBase>
);
const LandmarkIcon = () => (
  <IconBase>
    <line x1="3" y1="22" x2="21" y2="22" />
    <line x1="6" y1="18" x2="6" y2="11" />
    <line x1="10" y1="18" x2="10" y2="11" />
    <line x1="14" y1="18" x2="14" y2="11" />
    <line x1="18" y1="18" x2="18" y2="11" />
    <polygon points="12 2 20 7 4 7" />
  </IconBase>
);
const ClockCircleIcon = () => (
  <IconBase>
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </IconBase>
);
const HistoryIcon = () => (
  <IconBase>
    <path d="M3 12a9 9 0 1 0 9-9" />
    <polyline points="3 5 3 12 10 12" />
  </IconBase>
);
const BarsIcon = () => (
  <IconBase>
    <line x1="18" y1="20" x2="18" y2="10" />
    <line x1="12" y1="20" x2="12" y2="4" />
    <line x1="6" y1="20" x2="6" y2="14" />
  </IconBase>
);
const XCircleIcon = () => (
  <IconBase>
    <circle cx="12" cy="12" r="10" />
    <line x1="15" y1="9" x2="9" y2="15" />
    <line x1="9" y1="9" x2="15" y2="15" />
  </IconBase>
);
const StarIcon = () => (
  <IconBase>
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
  </IconBase>
);
const UserIcon = () => (
  <IconBase>
    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
    <circle cx="12" cy="7" r="4" />
  </IconBase>
);
const sidebarStyles = `
  .app-sidebar {
    background: #fff;
    border-right: 1px solid var(--color-line);
    padding: 22px 16px 16px;
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
  }
  .app-brand {
    display: flex; align-items: center; gap: 11px;
    padding: 6px 8px 22px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 20px;
    text-decoration: none;
  }
  .app-cocarde {
    width: 30px; height: 30px;
    border-radius: 50%;
    flex-shrink: 0;
    background:
      radial-gradient(circle, var(--color-red) 0 28%, transparent 28%),
      radial-gradient(circle, #fff 0 60%, transparent 60%),
      var(--color-blue);
  }
  .app-brand-name {
    font-family: var(--font-sans);
    font-weight: 800;
    font-size: 20px;
    letter-spacing: -0.02em;
    color: var(--color-blue);
  }
  .app-brand-fr { color: var(--color-red); }

  .app-nav { flex: 1; display: flex; flex-direction: column; }
  .app-nav-section {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--color-muted-2);
    letter-spacing: 0.15em;
    text-transform: uppercase;
    padding: 0 10px;
    margin: 16px 0 6px;
    font-weight: 600;
  }
  .app-nav-section:first-child { margin-top: 0; }

  .nav-item {
    display: flex; align-items: center; gap: 11px;
    padding: 10px 11px;
    border-radius: 10px;
    color: var(--color-ink-2);
    font-size: 14px;
    font-weight: 500;
    text-decoration: none;
    margin-bottom: 2px;
    transition: background 0.15s, color 0.15s;
  }
  .nav-item:hover { background: var(--color-blue-soft); }
  .nav-item.is-active {
    background: var(--color-blue);
    color: #fff;
  }
  .nav-icon {
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
    transition: color 0.15s;
  }
  .nav-item:hover .nav-icon { color: var(--color-blue); }
  .nav-item.is-active .nav-icon { color: #fff; }
  .nav-label { flex: 1; min-width: 0; }
  .nav-badge {
    background: var(--color-red);
    color: #fff;
    font-family: var(--font-mono);
    font-size: 10px;
    padding: 2px 6px;
    border-radius: 5px;
    font-weight: 700;
  }
  .nav-item.is-active .nav-badge {
    background: rgba(255, 255, 255, 0.22);
  }

  /* === footer === */
  .app-sidebar-foot {
    margin-top: auto;
    padding-top: 16px;
    border-top: 1px solid var(--color-line-2);
  }
  .upgrade-card {
    background: linear-gradient(135deg, var(--color-blue), var(--color-blue-dark));
    border-radius: 14px;
    padding: 16px;
    color: #fff;
    margin-bottom: 12px;
    position: relative;
    overflow: hidden;
  }
  .upgrade-card::after {
    content: '';
    position: absolute;
    width: 100px; height: 100px;
    border-radius: 50%;
    background: var(--color-red);
    opacity: 0.2;
    top: -40px; right: -40px;
  }
  .upgrade-card h4 {
    margin: 0 0 4px;
    font-family: var(--font-display);
    font-size: 16px;
    font-weight: 600;
    position: relative;
    z-index: 1;
  }
  .upgrade-card p {
    margin: 0 0 12px;
    font-size: 12px;
    opacity: 0.85;
    line-height: 1.4;
    position: relative;
    z-index: 1;
  }
  .upgrade-cta {
    display: block;
    background: #fff;
    color: var(--color-blue);
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 12px;
    font-weight: 700;
    text-align: center;
    text-decoration: none;
    position: relative;
    z-index: 1;
    transition: background 0.15s;
  }
  .upgrade-cta:hover { background: var(--color-paper); }

  .user-mini {
    display: flex; align-items: center; gap: 10px;
    padding: 8px;
    background: none;
    border: 1px solid transparent;
    border-radius: 10px;
    width: 100%;
    cursor: pointer;
    font-family: inherit;
    text-align: left;
    transition: background 0.15s, border-color 0.15s;
  }
  .user-mini:hover {
    background: var(--color-blue-soft);
    border-color: var(--color-line);
  }
  .user-avatar {
    width: 36px; height: 36px; border-radius: 50%;
    background: linear-gradient(135deg, var(--color-blue), var(--color-red));
    color: #fff;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 13px;
    flex-shrink: 0;
  }
  .user-info {
    flex: 1; min-width: 0;
    display: flex; flex-direction: column;
  }
  .user-name {
    font-size: 13px; font-weight: 700;
    color: var(--color-ink);
    line-height: 1.2;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .user-mail {
    font-size: 11px; color: var(--color-muted);
    line-height: 1.3;
    margin-top: 2px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .user-arrow {
    color: var(--color-muted);
    font-size: 14px;
    transition: color 0.15s;
  }
  .user-mini:hover .user-arrow { color: var(--color-red); }

  /* ===== mobile : sidebar horizontale en haut ===== */
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
      overflow-x: auto;
      overflow-y: hidden;
    }
    .app-brand {
      border-bottom: none;
      padding: 0; margin: 0;
      flex-shrink: 0;
    }
    .app-nav {
      display: flex; flex-direction: row;
      flex: 1; gap: 4px;
      overflow-x: auto;
    }
    .app-nav-section { display: none; }
    .nav-item {
      padding: 7px 12px;
      font-size: 12.5px;
      white-space: nowrap;
      margin-bottom: 0;
    }
    .nav-label { display: none; }
    .nav-item .nav-icon { display: flex; }
    .app-sidebar-foot {
      margin-top: 0;
      padding-top: 0;
      border-top: none;
      flex-shrink: 0;
    }
    .upgrade-card { display: none; }
    .user-mini { padding: 4px 8px; }
    .user-info { display: none; }
    .user-arrow { display: none; }
  }
`;
