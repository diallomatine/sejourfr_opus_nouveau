import { useCallback, useEffect, useRef, useState } from "react";
import type { KeyboardEvent as ReactKeyboardEvent } from "react";
import { Link, NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../../auth/AuthContext";
import { audioDraftsApi } from "../../api/audioDraftsApi";
import { exampleAudioApi } from "../../api/exampleAudioApi";
import { conversationsApi } from "../../api/conversationsApi";
import { dashboardApi } from "../../api/dashboardApi";
import { useBodyScrollLock } from "../../hooks/useBodyScrollLock";
import { Avatar } from "../ui/Avatar";
import { Icon } from "../ui/Icon";
import { useToast } from "../ui/Toast";
import { NAVIGATION, navEntryFor } from "./navigation";
import type { NavBadge, NavEntry } from "./navigation";
import styles from "./AppLayout.module.css";

/** Palier du tiroir : au-dessous, la barre latérale disparaît derrière le bouton burger. */
const DRAWER_QUERY = "(max-width: 720px)";
const FOCUSABLE = 'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])';

/**
 * Coquille de la console (maquette `docs/admin/utilisateurs/maquette-admin-utilisateurs-mvp.html`) :
 * barre latérale complète ≥ 1180 px, réduite aux icônes de 721 à 1179 px, tiroir
 * ouvert par le bouton burger ≤ 720 px.
 */
export function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const queryClient = useQueryClient();
  const toast = useToast();

  const [drawerOpen, setDrawerOpen] = useState(false);
  const burgerRef = useRef<HTMLButtonElement>(null);
  const drawerRef = useRef<HTMLElement>(null);
  const closeBtnRef = useRef<HTMLButtonElement>(null);

  useBodyScrollLock(drawerOpen);

  const closeDrawer = useCallback((restoreFocus: boolean) => {
    setDrawerOpen(false);
    if (restoreFocus) burgerRef.current?.focus();
  }, []);

  const [drawerPath, setDrawerPath] = useState(location.pathname);
  if (drawerPath !== location.pathname) {
    setDrawerPath(location.pathname);
    setDrawerOpen(false);
  }

  useEffect(() => {
    const media = window.matchMedia(DRAWER_QUERY);
    const onChange = () => {
      if (!media.matches) setDrawerOpen(false);
    };
    media.addEventListener("change", onChange);
    return () => media.removeEventListener("change", onChange);
  }, []);

  useEffect(() => {
    if (!drawerOpen) return;
    closeBtnRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") closeDrawer(true);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [drawerOpen, closeDrawer]);

  const trapFocus = (e: ReactKeyboardEvent<HTMLElement>) => {
    if (!drawerOpen || e.key !== "Tab" || !drawerRef.current) return;
    const focusables = Array.from(drawerRef.current.querySelectorAll<HTMLElement>(FOCUSABLE));
    if (focusables.length === 0) return;
    const first = focusables[0];
    const last = focusables[focusables.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  };

  const dashboardQuery = useQuery({
    queryKey: ["dashboard"],
    queryFn: () => dashboardApi.get(),
    staleTime: 60_000,
  });

  const unreadQuery = useQuery({
    queryKey: ["conversations", "unread-count"],
    queryFn: () => conversationsApi.unreadCount(),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const draftsPendingQuery = useQuery({
    queryKey: ["audioDrafts", "pendingReview", "count"],
    queryFn: () => audioDraftsApi.pendingReviewCount(),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const exampleAudioPendingQuery = useQuery({
    queryKey: ["exampleAudio", "pending", "count"],
    queryFn: () => exampleAudioApi.pendingCount(),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const badges: Record<NavBadge, number | undefined> = {
    questionsCivique: dashboardQuery.data?.questionsCivique,
    questionsTcf: dashboardQuery.data?.questionsTcf,
    audioDrafts: draftsPendingQuery.data?.count,
    exampleAudio: exampleAudioPendingQuery.data?.count,
    unreadConversations: unreadQuery.data?.count,
  };

  const handleLogout = () => {
    logout();
    navigate("/login", { replace: true });
  };

  const [refreshing, setRefreshing] = useState(false);
  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await queryClient.refetchQueries({ type: "active" });
      toast.show("Actualisé", "success", "Les données de la page sont relues sur le serveur.");
    } finally {
      setRefreshing(false);
    }
  };

  const current = navEntryFor(location.pathname);
  const isDetail = current !== null && location.pathname !== current.to;
  const adminName = user?.firstName ? `${user.firstName} ${user.lastName ?? ""}`.trim() : "Administrateur";

  return (
    <div className={styles.app}>
      <div
        className={`${styles.overlay} ${drawerOpen ? styles.overlayVisible : ""}`}
        onClick={() => closeDrawer(true)}
        aria-hidden="true"
      />

      <aside
        id="admin-navigation"
        ref={drawerRef}
        className={`${styles.sidebar} ${drawerOpen ? styles.sidebarOpen : ""}`}
        aria-label="Navigation de la console"
        onKeyDown={trapFocus}
      >
        <div className={styles.brand}>
          <span className={styles.brandMark} aria-hidden="true" />
          <span className={styles.brandName}>
            Sejour<b>FR</b>
          </span>
          <button
            ref={closeBtnRef}
            type="button"
            className={styles.drawerClose}
            onClick={() => closeDrawer(true)}
            aria-label="Fermer le menu"
          >
            <Icon name="close" size={18} />
          </button>
        </div>

        <nav className={styles.nav}>
          {NAVIGATION.map((section) => (
            <div key={section.label} className={styles.navSection}>
              <div className={styles.navLabel}>{section.label}</div>
              <div className={styles.navItems}>
                {section.items.map((item) => (
                  <NavItem
                    key={item.to}
                    item={item}
                    count={item.badge ? badges[item.badge] : undefined}
                    onNavigate={() => setDrawerOpen(false)}
                  />
                ))}
              </div>
            </div>
          ))}
        </nav>

        <div className={styles.adminCard}>
          <Avatar name={user?.firstName ? adminName : "Admin"} email={user?.email ?? "admin"} />
          <div className={styles.adminMeta}>
            <strong>{adminName}</strong>
            <span>{user?.email}</span>
          </div>
          <button
            type="button"
            className={styles.logout}
            onClick={handleLogout}
            aria-label="Déconnexion"
            title="Déconnexion"
          >
            <Icon name="logout" size={17} />
          </button>
        </div>
      </aside>

      <div className={styles.workspace}>
        <header className={styles.topbar}>
          <div className={styles.topLeft}>
            <button
              ref={burgerRef}
              type="button"
              className={styles.burger}
              onClick={() => setDrawerOpen(true)}
              aria-label="Ouvrir le menu"
              aria-expanded={drawerOpen}
              aria-controls="admin-navigation"
            >
              <Icon name="menu" size={20} />
            </button>
            <nav className={styles.breadcrumb} aria-label="Fil d'Ariane">
              <span className={styles.crumbRoot}>Admin</span>
              {current && (
                <>
                  <span className={styles.crumbSep} aria-hidden="true">
                    /
                  </span>
                  {isDetail ? (
                    <Link to={current.to} className={styles.crumbLink}>
                      {current.label}
                    </Link>
                  ) : (
                    <strong aria-current="page">{current.label}</strong>
                  )}
                </>
              )}
              {isDetail && current && (
                <>
                  <span className={styles.crumbSep} aria-hidden="true">
                    /
                  </span>
                  <strong aria-current="page">{current.detailLabel ?? "Détail"}</strong>
                </>
              )}
            </nav>
          </div>
          <div className={styles.topActions}>
            <button
              type="button"
              className={styles.refresh}
              onClick={handleRefresh}
              disabled={refreshing}
              aria-label="Actualiser les données de la page"
            >
              <Icon name="refresh" size={16} className={refreshing ? styles.spinning : undefined} />
              <span className={styles.refreshLabel}>Actualiser</span>
            </button>
          </div>
        </header>

        <main className={styles.main}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function NavItem({ item, count, onNavigate }: { item: NavEntry; count?: number; onNavigate: () => void }) {
  return (
    <NavLink
      to={item.to}
      title={item.label}
      onClick={onNavigate}
      className={({ isActive }) => `${styles.navItem} ${isActive ? styles.navItemActive : ""}`}
    >
      <Icon name={item.icon} size={19} className={styles.navIcon} />
      <span className={styles.navText}>{item.label}</span>
      {count !== undefined && count > 0 && <span className={styles.badge}>{count}</span>}
    </NavLink>
  );
}
