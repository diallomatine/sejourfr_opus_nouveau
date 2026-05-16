"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { Brand } from "./Brand";
import { useAuth } from "@/lib/auth-context";

/** Routes utilisateur connecté qui ont leur propre sidebar — le SiteHeader
 *  global n'apparaît pas pour éviter une double-navigation. */
const APP_PREFIXES = [
  "/dashboard",
  "/entrainement",
  "/examens-blancs",
  "/historique",
  "/paiement",
  "/parcours",
  "/profil",
  "/revision",
  "/sessions",
  "/statistiques",
];

export function SiteHeader() {
  const { status, user, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!menuOpen) return;
    const onClick = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, [menuOpen]);

  const isAppRoute = pathname
    ? APP_PREFIXES.some((p) => pathname === p || pathname.startsWith(`${p}/`))
    : false;
  if (isAppRoute) return null;

  const handleLogout = () => {
    logout();
    setMenuOpen(false);
    router.push("/");
  };

  const isAuth = status === "authenticated" && user !== null;
  const isLoading = status === "loading";
  const homeHref = isAuth ? "/dashboard" : "/";

  return (
    <nav className="site-header" aria-label="Navigation principale">
      <div className="site-header__inner">
        <Brand href={homeHref} />

        <div className="site-header__links">
          <Link href="/#examens">Examen civique</Link>
          <Link href="/#tcf">TCF IRN</Link>
          <Link href="/#fonctionnalites">Fonctionnalités</Link>
          <Link href="/#tarifs">Tarifs</Link>
          <Link href="/#faq">FAQ</Link>
        </div>

        <div className="site-header__ctas">
          {isLoading ? (
            <span className="site-header__ctaPlaceholder" aria-hidden />
          ) : isAuth ? (
            <div className="site-header__user" ref={menuRef}>
              <button
                type="button"
                className="site-header__userBtn"
                onClick={() => setMenuOpen((v) => !v)}
                aria-haspopup="menu"
                aria-expanded={menuOpen}
              >
                <span className="site-header__avatar">
                  {user.firstName?.[0]?.toUpperCase() ??
                    user.email[0].toUpperCase()}
                </span>
                <span className="site-header__userName">
                  {user.firstName ?? user.email}
                </span>
                <span className="site-header__caret" aria-hidden>
                  ▾
                </span>
              </button>

              {menuOpen && (
                <div className="site-header__menu" role="menu">
                  <div className="site-header__menuHead">
                    <div className="site-header__menuName">
                      {user.firstName} {user.lastName}
                    </div>
                    <div className="site-header__menuEmail">{user.email}</div>
                  </div>
                  <Link
                    href="/dashboard"
                    className="site-header__menuItem"
                    onClick={() => setMenuOpen(false)}
                  >
                    Tableau de bord
                  </Link>
                  <Link
                    href="/examens-blancs"
                    className="site-header__menuItem"
                    onClick={() => setMenuOpen(false)}
                  >
                    Examens blancs
                  </Link>
                  <Link
                    href="/profil"
                    className="site-header__menuItem"
                    onClick={() => setMenuOpen(false)}
                  >
                    Mon profil
                  </Link>
                  <button
                    type="button"
                    className="site-header__menuItem site-header__menuItem--danger"
                    onClick={handleLogout}
                  >
                    Se déconnecter
                  </button>
                </div>
              )}
            </div>
          ) : (
            <>
              <Link
                href="/connexion"
                className="site-header__ghost site-header__hideMobile"
              >
                Se connecter
              </Link>
              <Link href="/inscription" className="btn site-header__primary">
                Commencer
              </Link>
            </>
          )}
        </div>
      </div>

      <style>{`
        .site-header {
          position: sticky; top: 0; z-index: 50;
          background: rgba(255, 255, 255, 0.85);
          backdrop-filter: saturate(180%) blur(14px);
          -webkit-backdrop-filter: saturate(180%) blur(14px);
          border-bottom: 1px solid var(--color-line);
        }
        .site-header__inner {
          max-width: 1180px; margin: 0 auto;
          padding: 0 28px;
          height: 68px;
          display: flex; align-items: center; justify-content: space-between;
          gap: 24px;
        }
        .site-header__ctaPlaceholder {
          display: inline-block;
          width: 200px; height: 36px;
          border-radius: 100px;
          background: var(--color-line-2);
          opacity: 0.5;
        }
        .site-header__links {
          display: flex; align-items: center; gap: 32px;
          font-size: 14px; font-weight: 500; color: var(--color-ink-2);
        }
        .site-header__links a { color: inherit; text-decoration: none; transition: color 0.15s; }
        .site-header__links a:hover { color: var(--color-blue); }
        .site-header__ctas {
          display: flex; align-items: center; gap: 10px;
        }

        .site-header__ghost {
          font-size: 14px; font-weight: 600;
          color: var(--color-ink-2);
          padding: 10px 16px;
          border-radius: 10px;
          transition: background 0.15s, color 0.15s;
        }
        .site-header__ghost:hover {
          background: var(--color-blue-soft);
          color: var(--color-blue);
        }
        .site-header__primary {
          padding: 11px 20px;
          border-radius: 12px;
          font-size: 14px;
        }

        .site-header__user { position: relative; }
        .site-header__userBtn {
          display: flex; align-items: center; gap: 8px;
          padding: 6px 10px 6px 6px;
          border: 1px solid var(--color-line);
          background: #fff; border-radius: 100px;
          cursor: pointer;
          font-family: var(--font-sans);
          font-size: 13.5px; color: var(--color-ink);
          transition: all 0.15s;
        }
        .site-header__userBtn:hover { border-color: var(--color-blue); }
        .site-header__avatar {
          width: 28px; height: 28px; border-radius: 50%;
          background: linear-gradient(135deg, var(--color-blue), var(--color-red));
          color: #fff;
          display: flex; align-items: center; justify-content: center;
          font-weight: 700; font-size: 12px;
        }
        .site-header__userName { font-weight: 600; }
        .site-header__caret { color: var(--color-muted); font-size: 10px; }

        .site-header__menu {
          position: absolute; right: 0; top: calc(100% + 8px);
          min-width: 240px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 12px;
          box-shadow: 0 30px 60px -20px rgba(15, 24, 57, 0.18);
          overflow: hidden;
        }
        .site-header__menuHead {
          padding: 14px 16px;
          border-bottom: 1px solid var(--color-line-2);
          background: var(--color-paper);
        }
        .site-header__menuName {
          font-weight: 700; font-size: 13.5px; color: var(--color-ink);
        }
        .site-header__menuEmail {
          font-size: 12px; color: var(--color-muted);
          margin-top: 2px;
          word-break: break-all;
        }
        .site-header__menuItem {
          display: block;
          padding: 11px 16px;
          font-size: 13.5px; color: var(--color-ink-2);
          text-decoration: none;
          background: none; border: none; width: 100%; text-align: left;
          font-family: var(--font-sans); cursor: pointer;
          transition: background 0.1s;
        }
        .site-header__menuItem:hover { background: var(--color-blue-soft); }
        .site-header__menuItem--danger {
          color: var(--color-red);
          border-top: 1px solid var(--color-line-2);
        }
        .site-header__menuItem--danger:hover { background: var(--color-red-light); }

        @media (max-width: 960px) {
          .site-header__links { display: none; }
        }
        @media (max-width: 480px) {
          .site-header__hideMobile { display: none; }
          .site-header__userName { display: none; }
        }
      `}</style>
    </nav>
  );
}
