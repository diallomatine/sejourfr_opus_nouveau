"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useRef, useState} from "react";
import {Menu, X} from "lucide-react";
import {Brand} from "./Brand";
import {AppSidebar} from "./AppSidebar";
import {track} from "@/lib/analytics";
import {useAuth} from "@/lib/auth-context";
import {isAppGroupRoute, isDualChromeRoute, shouldHideGlobalChrome,} from "@/lib/chrome-routes";

// Miroir public de la sidebar connectée : les guests naviguent librement les
// hubs et la page examens blancs (série 1 / examen 1 offerts, le reste gated).
const NAV_LINKS = [
    {href: "/", label: "Accueil"},
    {href: "/entrainement?module=TCF", label: "TCF IRN"},
    {href: "/entrainement?module=CIVIQUE", label: "Examen civique"},
    {href: "/examens-blancs", label: "Examens blancs"},
    {href: "/tarifs", label: "Tarifs"},
];

/** Décompose un href de nav en path + module (les liens /entrainement ne
 *  diffèrent que par `?module=`). */
function parseNavHref(href: string): {path: string; module: string | null} {
    const [path, query] = href.split("?");
    return {path, module: query ? new URLSearchParams(query).get("module") : null};
}

/** Module porté par le chemin lui-même (`/entrainement/tcf/…`), null sur
 *  `/entrainement` où seul le `?module=` tranche. */
function moduleFromPath(pathname: string): string | null {
    if (pathname.startsWith("/entrainement/tcf")) return "TCF";
    if (pathname.startsWith("/entrainement/civique")) return "CIVIQUE";
    return null;
}

type NavVariant = "desktop" | "mobile";

function renderNavLinks(
    variant: NavVariant,
    isActive: (href: string) => boolean,
    onNavigate?: () => void,
) {
    return NAV_LINKS.map((l) => {
        const active = isActive(l.href);
        if (variant === "desktop") {
            return (
                <Link
                    key={l.href}
                    href={l.href}
                    className={active ? "is-active" : undefined}
                    aria-current={active ? "page" : undefined}
                >
                    {l.label}
                </Link>
            );
        }
        return (
            <Link
                key={l.href}
                href={l.href}
                className={active ? "site-header__mobileLink is-active" : "site-header__mobileLink"}
                aria-current={active ? "page" : undefined}
                onClick={onNavigate}
            >
                {l.label}
            </Link>
        );
    });
}

/** Liens de nav avec marquage de l'onglet courant. Isolé dans son propre
 *  <Suspense> (cf. usages) car `useSearchParams` y est lu — on évite ainsi de
 *  différer l'hydratation du reste du header (sinon les CTAs auth flashent un
 *  mismatch loading/guest). */
function ActiveNavLinks({variant, onNavigate}: {variant: NavVariant; onNavigate?: () => void}) {
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const currentModule = searchParams.get("module");
    const isActive = (href: string) => {
        const {path, module} = parseNavHref(href);
        if (path === "/") return pathname === "/";
        if (pathname !== path && !pathname.startsWith(`${path}/`)) return false;
        // /entrainement : on départage TCF / Civique. Sur les sous-routes le
        // module est dans le chemin (/entrainement/tcf/…) — s'en remettre au
        // `?module=` absent y allumait « Examen civique » sur tout le TCF.
        if (module) return (moduleFromPath(pathname) ?? currentModule ?? "CIVIQUE") === module;
        return true;
    };
    return <>{renderNavLinks(variant, isActive, onNavigate)}</>;
}

export function SiteHeader() {
    const {status, user, logout} = useAuth();
    const router = useRouter();
    const pathname = usePathname();
    const [menuOpen, setMenuOpen] = useState(false);
    const [mobileNavOpen, setMobileNavOpen] = useState(false);
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

    // Ferme le drawer mobile quand on change de route.
    useEffect(() => {
        setMobileNavOpen(false);
    }, [pathname]);

    // Lock du scroll body quand le drawer mobile est ouvert.
    useEffect(() => {
        if (typeof document === "undefined") return;
        if (mobileNavOpen) {
            const prev = document.body.style.overflow;
            document.body.style.overflow = "hidden";
            return () => {
                document.body.style.overflow = prev;
            };
        }
    }, [mobileNavOpen]);

    const isAuth = status === "authenticated" && user !== null;
    if (shouldHideGlobalChrome(pathname, isAuth)) return null;

    /** Sur les routes connectées qui montent déjà MobileSidebarToggle (sidebar
     *  drawer dédié), on cache notre propre burger pour ne pas en empiler deux. */
    const hideMobileBurger =
        isAuth && (isAppGroupRoute(pathname) || isDualChromeRoute(pathname));

    const handleLogout = () => {
        logout();
        setMenuOpen(false);
        setMobileNavOpen(false);
        router.push("/");
    };

    const isLoading = status === "loading";
    const homeHref = isAuth ? "/dashboard" : "/";

    return (
        <>
            <nav className="site-header" aria-label="Navigation principale">
                <div className="site-header__inner">
                    <Brand href={homeHref}/>

                    <div className="site-header__links">
                        <Suspense fallback={renderNavLinks("desktop", () => false)}>
                            <ActiveNavLinks variant="desktop"/>
                        </Suspense>
                    </div>

                    {!hideMobileBurger && (
                        <button
                            type="button"
                            className="site-header__burger"
                            aria-label={mobileNavOpen ? "Fermer le menu" : "Ouvrir le menu"}
                            aria-expanded={mobileNavOpen}
                            onClick={(e) => {
                                e.preventDefault();
                                e.stopPropagation();
                                setMobileNavOpen((v) => !v);
                            }}
                        >
                            {mobileNavOpen ? <X size={20} aria-hidden/> : <Menu size={20} aria-hidden/>}
                        </button>
                    )}

                    <div className="site-header__ctas">
                        {isLoading ? (
                            <span className="site-header__ctaPlaceholder" aria-hidden/>
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
                                            href="/entrainement"
                                            className="site-header__menuItem"
                                            onClick={() => setMenuOpen(false)}
                                        >
                                            Entrainements
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
                                    onClick={() => track("LOGIN_CLICKED", {})}
                                >
                                    Se connecter
                                </Link>
                                <Link
                                    href="/inscription"
                                    className="btn site-header__primary"
                                    onClick={() => track("SIGNUP_CTA_CLICKED", {ctaLocation: "HERO"})}
                                >
                                    Commencer
                                </Link>
                            </>
                        )}
                    </div>
                </div>

                <style>{`
        .site-header {
          position: sticky; top: 0; z-index: 50;
          /* Fond opaque blanc sur mobile pour éviter les bugs de hit-testing
             d'iOS Safari liés au backdrop-filter sur élément sticky. */
          background: #fff;
          border-bottom: 1px solid var(--color-line);
          isolation: isolate;
        }
        /* Effet blur translucide réservé aux devices avec pointeur fin
           (desktop) où le bug iOS n'existe pas. */
        @media (hover: hover) and (min-width: 961px) {
          .site-header {
            background: rgba(255, 255, 255, 0.85);
            backdrop-filter: saturate(180%) blur(14px);
            -webkit-backdrop-filter: saturate(180%) blur(14px);
          }
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
        .site-header__links a {
          position: relative;
          color: inherit; text-decoration: none;
          padding: 4px 1px;
          transition: color 0.15s;
        }
        .site-header__links a:hover { color: var(--color-blue); }
        .site-header__links a.is-active { color: var(--color-blue); }
        .site-header__links a.is-active::after {
          content: "";
          position: absolute;
          left: 1px; right: 1px; bottom: -5px;
          height: 2px; border-radius: 2px;
          background: var(--color-blue);
        }
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

        /* Burger : visible uniquement sous 960px, premier élément à gauche */
        .site-header__burger {
          display: none;
          width: 44px; height: 44px;
          align-items: center; justify-content: center;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 10px;
          color: var(--color-ink);
          cursor: pointer;
          font-family: inherit;
          transition: background 0.15s, border-color 0.15s;
          flex-shrink: 0;
          /* iOS / Android : supprime le délai 300ms et le highlight bleu au tap. */
          touch-action: manipulation;
          -webkit-tap-highlight-color: transparent;
          -webkit-touch-callout: none;
          /* Stacking context explicite pour s'assurer que le button est
             cliquable au-dessus de tous les éléments décoratifs du header. */
          position: relative;
          z-index: 2;
          -webkit-appearance: none;
          appearance: none;
        }
        /* :hover uniquement sur device pointeur fin (souris) — sinon iOS
           "colle" le hover et la première tap ne déclenche pas onClick. */
        @media (hover: hover) {
          .site-header__burger:hover {
            background: var(--color-blue-soft);
            border-color: var(--color-blue);
          }
        }
        .site-header__burger:active {
          background: var(--color-blue-soft);
          border-color: var(--color-blue);
        }

        /* Mobile drawer (left-slide, style Flutter) */
        .site-header__mobileOverlay {
          position: fixed; inset: 0;
          background: rgba(15, 24, 57, 0.5);
          -webkit-backdrop-filter: blur(2px);
          backdrop-filter: blur(2px);
          z-index: 80;
          animation: site-mobile-overlay-in 0.18s ease-out;
        }
        @keyframes site-mobile-overlay-in {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        .site-header__mobilePanel {
          position: fixed;
          top: 0; left: 0; bottom: 0;
          width: min(86vw, 320px);
          background: #fff;
          z-index: 90;
          padding: 20px 22px;
          display: flex; flex-direction: column;
          gap: 6px;
          overflow-y: auto;
          box-shadow: 18px 0 40px -20px rgba(15, 24, 57, 0.35);
          animation: site-mobile-panel-in 0.22s ease-out;
        }
        @keyframes site-mobile-panel-in {
          from { transform: translateX(-100%); }
          to { transform: translateX(0); }
        }
        /* Variante connectée : l'AppSidebar (via .ms-drawer-inner) porte son
           propre padding/scroll, le panneau ne fait que le cadre fixe. */
        .site-header__mobilePanel--app {
          padding: 0;
          gap: 0;
          overflow: hidden;
          width: min(86vw, 300px);
        }
        .site-header__mobileHead {
          display: flex; align-items: center; justify-content: space-between;
          padding-bottom: 14px;
          border-bottom: 1px solid var(--color-line-2);
          margin-bottom: 14px;
        }
        .site-header__mobileClose {
          width: 36px; height: 36px;
          display: inline-flex; align-items: center; justify-content: center;
          background: var(--color-paper);
          border: 1px solid var(--color-line);
          border-radius: 10px;
          color: var(--color-ink);
          cursor: pointer;
          font-family: inherit;
        }
        .site-header__mobileLink {
          padding: 12px 6px;
          font-size: 16px; font-weight: 600;
          color: var(--color-ink);
          text-decoration: none;
          border-radius: 8px;
          transition: background 0.15s, color 0.15s;
        }
        .site-header__mobileLink:hover {
          background: var(--color-blue-soft);
          color: var(--color-blue);
        }
        .site-header__mobileLink.is-active {
          background: var(--color-blue-soft);
          color: var(--color-blue);
        }
        .site-header__mobileCtas {
          display: flex; flex-direction: column; gap: 10px;
          margin-top: 18px;
          padding-top: 18px;
          border-top: 1px solid var(--color-line-2);
        }
        .site-header__mobileGhost {
          padding: 12px 16px;
          border: 1px solid var(--color-line);
          border-radius: 10px;
          text-align: center;
          font-weight: 600; font-size: 14.5px;
          color: var(--color-ink);
          text-decoration: none;
        }
        .site-header__mobilePrimary {
          width: 100%;
          text-align: center;
        }

        @media (max-width: 960px) {
          /* Sur mobile : burger à gauche (order: -1), nav links + CTAs desktop
             cachés (accessibles depuis le drawer uniquement). */
          .site-header__inner {
            justify-content: flex-start;
            gap: 14px;
            padding: 0 16px;
          }
          .site-header__links { display: none; }
          .site-header__ctas { display: none; }
          .site-header__burger {
            display: inline-flex;
            order: -1;
          }
        }
        @media (max-width: 480px) {
          .site-header__hideMobile { display: none; }
          .site-header__userName { display: none; }
        }
      `}</style>
            </nav>

            {/* Drawer rendu HORS du <nav> : backdrop-filter sur .site-header
            crée un containing block qui contraindrait un fixed enfant. */}
            {mobileNavOpen && (
                <>
                    <div
                        className="site-header__mobileOverlay"
                        onClick={() => setMobileNavOpen(false)}
                        aria-hidden
                    />
                    {isAuth ? (
                        /* Connecté (accueil + autres routes vitrine) : le drawer
                           rend la même AppSidebar que l'espace perso, pour que le
                           burger soit identique partout. Réutilise les overrides
                           globaux `.ms-drawer-inner .app-sidebar` + `.ms-close`. */
                        <aside
                            className="site-header__mobilePanel site-header__mobilePanel--app"
                            role="dialog"
                            aria-modal="true"
                            aria-label="Menu"
                        >
                            <button
                                type="button"
                                className="ms-close"
                                onClick={() => setMobileNavOpen(false)}
                                aria-label="Fermer le menu"
                            >
                                <X size={18} aria-hidden/>
                            </button>
                            <div
                                className="ms-drawer-inner"
                                onClick={(e) => {
                                    if ((e.target as HTMLElement).closest("a, button")) {
                                        setMobileNavOpen(false);
                                    }
                                }}
                            >
                                <AppSidebar/>
                            </div>
                        </aside>
                    ) : (
                        <aside
                            className="site-header__mobilePanel"
                            role="dialog"
                            aria-modal="true"
                            aria-label="Menu"
                        >
                            <div className="site-header__mobileHead">
                                <Brand href={homeHref}/>
                                <button
                                    type="button"
                                    className="site-header__mobileClose"
                                    onClick={() => setMobileNavOpen(false)}
                                    aria-label="Fermer le menu"
                                >
                                    <X size={18} aria-hidden/>
                                </button>
                            </div>

                            <Suspense
                                fallback={renderNavLinks("mobile", () => false, () =>
                                    setMobileNavOpen(false),
                                )}
                            >
                                <ActiveNavLinks
                                    variant="mobile"
                                    onNavigate={() => setMobileNavOpen(false)}
                                />
                            </Suspense>

                            <div className="site-header__mobileCtas">
                                <Link href="/connexion" className="site-header__mobileGhost"
                                      onClick={() => {
                                          track("LOGIN_CLICKED", {});
                                          setMobileNavOpen(false);
                                      }}>
                                    Se connecter
                                </Link>
                                <Link href="/inscription" className="btn site-header__mobilePrimary"
                                      onClick={() => {
                                          track("SIGNUP_CTA_CLICKED", {ctaLocation: "STICKY"});
                                          setMobileNavOpen(false);
                                      }}>
                                    Commencer
                                </Link>
                            </div>
                        </aside>
                    )}
                </>
            )}
        </>
    );
}
