"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useRef, useState} from "react";
import {ChevronDown, Menu, X} from "lucide-react";
import {Brand} from "./Brand";
import {AppSidebar} from "./AppSidebar";
import {track} from "@/lib/analytics";
import {useAuth} from "@/lib/auth-context";
import {isAppShellMounted, isDualChromeRoute, shouldHideGlobalChrome} from "@/lib/chrome-routes";
import {DIAGNOSTIC_RAPIDE_HREF} from "@/lib/preparation";
import styles from "./SiteHeader.module.css";

/**
 * En-tête public du site (maquette « accueil v3 », 2026-09-26) : logo, liens de
 * navigation, « Connexion » + « Tester mon niveau » pour un visiteur, menu
 * avatar pour un compte. Monté une fois par le layout racine, masqué sur les
 * routes applicatives d'un compte et sur les landings autoportantes
 * (`shouldHideGlobalChrome`).
 */
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
    const base = variant === "desktop" ? styles.link : styles.drawerLink;
    return NAV_LINKS.map((l) => {
        const active = isActive(l.href);
        return (
            <Link
                key={l.href}
                href={l.href}
                className={`${base} ${active ? styles.isActive : ""}`}
                aria-current={active ? "page" : undefined}
                onClick={onNavigate}
            >
                {l.label}
            </Link>
        );
    });
}

/** Liens de nav avec marquage de l'onglet courant. Isolé dans son propre
 *  <Suspense> car `useSearchParams` y est lu — on évite ainsi de différer
 *  l'hydratation du reste de l'en-tête. */
function ActiveNavLinks({variant, onNavigate}: {variant: NavVariant; onNavigate?: () => void}) {
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const currentModule = searchParams.get("module");
    const isActive = (href: string) => {
        const {path, module} = parseNavHref(href);
        if (pathname !== path && !pathname.startsWith(`${path}/`)) return false;
        // /entrainement : on départage TCF / Civique. Sur les sous-routes le
        // module est dans le chemin (/entrainement/tcf/…).
        if (module) return (moduleFromPath(pathname) ?? currentModule ?? "CIVIQUE") === module;
        return true;
    };
    return <>{renderNavLinks(variant, isActive, onNavigate)}</>;
}

/** « Tester mon niveau » : la porte du diagnostic, mesurée comme telle. */
function trackDiagnosticCta(ctaLocation: "HERO" | "STICKY") {
    track("DIAGNOSTIC_CTA_CLICKED", {ctaLocation, diagnosticType: "UNKNOWN"});
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

    // Ferme le tiroir mobile quand on change de route (remise à zéro au rendu,
    // pas dans un effet : pas de rendu en cascade).
    const [navPath, setNavPath] = useState(pathname);
    if (navPath !== pathname) {
        setNavPath(pathname);
        setMobileNavOpen(false);
    }

    // Verrou du scroll de la page tant que le tiroir est ouvert, et Échap le ferme.
    useEffect(() => {
        if (!mobileNavOpen) return;
        const prev = document.body.style.overflow;
        document.body.style.overflow = "hidden";
        const onKey = (e: KeyboardEvent) => {
            if (e.key === "Escape") setMobileNavOpen(false);
        };
        document.addEventListener("keydown", onKey);
        return () => {
            document.body.style.overflow = prev;
            document.removeEventListener("keydown", onKey);
        };
    }, [mobileNavOpen]);

    const isAuth = status === "authenticated" && user !== null;
    if (shouldHideGlobalChrome(pathname, isAuth)) return null;

    /** Dans le parcours du diagnostic (TCF ou civique), l'invitation à le
     *  commencer n'a plus lieu d'être : elle détourne du geste en cours. */
    const inDiagnostic = pathname === "/diagnostic" || pathname.startsWith("/diagnostic/")
        || pathname === "/diagnostic-civique" || pathname.startsWith("/diagnostic-civique/");

    /** Sur les routes qui montent déjà `AppTopBar` (tiroir dédié), on cache
     *  notre propre bouton de menu pour ne pas en empiler deux. */
    const hideMobileBurger =
        isAppShellMounted(pathname, status) || (isAuth && isDualChromeRoute(pathname));

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
            <header className={styles.header}>
                <nav className={styles.nav} aria-label="Navigation principale">
                    <div className={styles.start}>
                        {!hideMobileBurger && (
                            <button
                                type="button"
                                className={styles.burger}
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
                        <Brand href={homeHref}/>
                    </div>

                    <div className={styles.links}>
                        <Suspense fallback={renderNavLinks("desktop", () => false)}>
                            <ActiveNavLinks variant="desktop"/>
                        </Suspense>
                    </div>

                    <div className={styles.actions}>
                        {isLoading ? (
                            <span className={styles.placeholder} aria-hidden/>
                        ) : isAuth ? (
                            <div className={styles.user} ref={menuRef}>
                                <button
                                    type="button"
                                    className={styles.userBtn}
                                    onClick={() => setMenuOpen((v) => !v)}
                                    aria-haspopup="menu"
                                    aria-expanded={menuOpen}
                                >
                                    <span className={styles.avatar}>
                                        {user.firstName?.[0]?.toUpperCase() ?? user.email[0].toUpperCase()}
                                    </span>
                                    <span className={styles.userName}>{user.firstName ?? user.email}</span>
                                    <ChevronDown size={14} className={styles.caret} aria-hidden/>
                                </button>

                                {menuOpen && (
                                    <div className={styles.menu} role="menu">
                                        <div className={styles.menuHead}>
                                            <div className={styles.menuName}>
                                                {user.firstName} {user.lastName}
                                            </div>
                                            <div className={styles.menuEmail}>{user.email}</div>
                                        </div>
                                        <Link href="/dashboard" className={styles.menuItem}
                                              onClick={() => setMenuOpen(false)}>
                                            Accueil
                                        </Link>
                                        <Link href="/entrainement" className={styles.menuItem}
                                              onClick={() => setMenuOpen(false)}>
                                            Entrainements
                                        </Link>
                                        <Link href="/profil" className={styles.menuItem}
                                              onClick={() => setMenuOpen(false)}>
                                            Mon profil
                                        </Link>
                                        <button
                                            type="button"
                                            className={`${styles.menuItem} ${styles.menuItemDanger}`}
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
                                    className={`${styles.btn} ${styles.btnLight}`}
                                    onClick={() => track("LOGIN_CLICKED", {})}
                                >
                                    Connexion
                                </Link>
                                {!inDiagnostic && (
                                    <Link
                                        href={DIAGNOSTIC_RAPIDE_HREF}
                                        className={`${styles.btn} ${styles.btnRed}`}
                                        onClick={() => trackDiagnosticCta("HERO")}
                                    >
                                        Tester mon niveau
                                    </Link>
                                )}
                            </>
                        )}

                    </div>
                </nav>
            </header>

            {/* Tiroir rendu HORS de l'en-tête : le backdrop-filter de l'en-tête
                crée un containing block qui contraindrait un `fixed` enfant. */}
            {mobileNavOpen && (
                <>
                    <div className={styles.overlay} onClick={() => setMobileNavOpen(false)} aria-hidden/>
                    {isAuth ? (
                        /* Compte : le tiroir rend la même AppSidebar que l'espace
                           perso (overrides globaux `.ms-drawer-inner` + `.ms-close`). */
                        <aside
                            className={`${styles.panel} ${styles.panelApp}`}
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
                        <aside className={styles.panel} role="dialog" aria-modal="true" aria-label="Menu">
                            <div className={styles.panelHead}>
                                <Brand href={homeHref}/>
                                <button
                                    type="button"
                                    className={styles.panelClose}
                                    onClick={() => setMobileNavOpen(false)}
                                    aria-label="Fermer le menu"
                                >
                                    <X size={18} aria-hidden/>
                                </button>
                            </div>

                            <Suspense
                                fallback={renderNavLinks("mobile", () => false, () => setMobileNavOpen(false))}
                            >
                                <ActiveNavLinks variant="mobile" onNavigate={() => setMobileNavOpen(false)}/>
                            </Suspense>

                            <div className={styles.panelCtas}>
                                <Link
                                    href="/connexion"
                                    className={`${styles.btn} ${styles.btnLight} ${styles.btnFull}`}
                                    onClick={() => {
                                        track("LOGIN_CLICKED", {});
                                        setMobileNavOpen(false);
                                    }}
                                >
                                    Connexion
                                </Link>
                                {!inDiagnostic && (
                                    <Link
                                        href={DIAGNOSTIC_RAPIDE_HREF}
                                        className={`${styles.btn} ${styles.btnRed} ${styles.btnFull}`}
                                        onClick={() => {
                                            trackDiagnosticCta("STICKY");
                                            setMobileNavOpen(false);
                                        }}
                                    >
                                        Tester mon niveau
                                    </Link>
                                )}
                            </div>
                        </aside>
                    )}
                </>
            )}
        </>
    );
}
