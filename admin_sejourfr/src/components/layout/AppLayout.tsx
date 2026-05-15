import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../../auth/AuthContext";
import { conversationsApi } from "../../api/conversationsApi";
import { dashboardApi } from "../../api/dashboardApi";
import styles from "./AppLayout.module.css";

export function AppLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  // Badges sidebar : on tape les memes endpoints que le dashboard
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

  const handleLogout = () => {
    logout();
    navigate("/login", { replace: true });
  };

  return (
    <div className={styles.app}>
      <aside className={styles.sidebar}>
        <div className={styles.brand}>
          <div className={styles.cocarde} />
          <div>
            <div className={styles.brandName}>
              Sejour<span className={styles.fr}>FR</span>
            </div>
            <div className={styles.brandTag}>Console admin · v0.1</div>
          </div>
        </div>

        <div className={styles.navSection}>Pilotage</div>
        <NavItem to="/dashboard">↳ Tableau de bord</NavItem>

        <div className={styles.navSection}>Contenu</div>
        <NavItem
          to="/questions/civique"
          badge={dashboardQuery.data?.questionsCivique}
        >
          ↳ Questions · Civique
        </NavItem>
        <NavItem
          to="/questions/tcf"
          badge={dashboardQuery.data?.questionsTcf}
        >
          ↳ Questions · TCF
        </NavItem>
        <NavItem to="/themes">↳ Thématiques</NavItem>
        <NavItem to="/exams">↳ Examens blancs</NavItem>

        <div className={styles.navSection}>Echanges</div>
        <NavItem to="/conversations" badge={unreadQuery.data?.count}>
          ↳ Conversations
        </NavItem>

        <div className={styles.sidebarFooter}>
          <div className={styles.userName}>
            {user?.firstName ? `${user.firstName} ${user.lastName ?? ""}`.trim() : user?.email}
          </div>
          <div className={styles.userRole}>Administrateur</div>
          <button
            type="button"
            className={styles.logoutBtn}
            onClick={handleLogout}
          >
            Deconnexion
          </button>
        </div>
      </aside>

      <main className={styles.main}>
        <Outlet />
      </main>
    </div>
  );
}

function NavItem({
  to,
  children,
  badge,
}: {
  to: string;
  children: React.ReactNode;
  badge?: number;
}) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        `${styles.navItem} ${isActive ? styles.navItemActive : ""}`
      }
    >
      <span>{children}</span>
      {badge !== undefined && badge > 0 && (
        <span className={styles.badge}>{badge}</span>
      )}
    </NavLink>
  );
}
