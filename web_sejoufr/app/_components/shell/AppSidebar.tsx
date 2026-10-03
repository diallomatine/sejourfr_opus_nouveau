"use client";

import Link from "next/link";
import {usePathname, useSearchParams} from "next/navigation";
import {Suspense, type ReactNode} from "react";
import {Cocarde, Wordmark} from "../Brand";
import {useAuth} from "@/lib/auth-context";
import type {ParcoursModule} from "@/lib/module-switch";
import {passAccessName} from "@/lib/passes";
import {
    SHELL_BRAND_TAG,
    SHELL_GROUP_ACCOUNT,
    SHELL_GROUP_OVERVIEW,
    SHELL_MODULE_ITEMS,
    SHELL_MODULE_TITLE,
    shellActive,
    shellInitials,
    shellItemLabel,
    shellModuleHref,
    type ShellActive,
    type ShellItem,
} from "@/lib/shell-nav";
import {useShellNav} from "@/lib/use-shell-nav";
import {
    IconBook,
    IconChart,
    IconChevronRight,
    IconClock,
    IconClose,
    IconHome,
    IconMap,
    IconSheet,
    IconShield,
    IconTarget,
    IconUser,
} from "./ShellIcons";
import styles from "./shell.module.css";

/**
 * **La barre latérale de l'espace connecté** — maquette « Navigation v2 ».
 *
 * Marque (cocarde + « Sejour**FR** », FR rouge) · « Vue d'ensemble » (Accueil)
 * · bloc TCF IRN · bloc Examen civique (sous-menus en escalier) · « Compte »
 * (Profil) · carte utilisateur vers `/profil`.
 *
 * 🛑 **Une seule instance par écran** : au-dessus de 1024 px elle est fixe,
 * en dessous la MÊME barre devient le tiroir (`open`) — desktop et tiroir
 * partagent donc une seule source de données (`useShellNav`).
 * `embedded` : rendue dans le tiroir de l'en-tête public (`SiteHeader`, un
 * compte sur une page publique), statique, avec son bouton de fermeture.
 *
 * L'entrée active se lit sur l'adresse (`shellActive`, `lib/shell-nav.ts`) ;
 * les tails ne viennent que de caches partagés. La déconnexion vit sur le
 * Profil ; la série de jours aussi (« Votre semaine », phase 4).
 */
export function AppSidebar(props: {open?: boolean; onClose?: () => void; embedded?: boolean}) {
    return (
        <Suspense fallback={<SidebarBody {...props} active={{module: null, item: null}} />}>
            <SidebarWithQuery {...props} />
        </Suspense>
    );
}

function SidebarWithQuery(props: {open?: boolean; onClose?: () => void; embedded?: boolean}) {
    const pathname = usePathname();
    const search = useSearchParams();
    return <SidebarBody {...props} active={shellActive(pathname, search)} />;
}

const MODULE_ICON: Record<ParcoursModule, Record<ShellItem, () => ReactNode>> = {
    TCF: {
        accueil: IconHome,
        plan: IconMap,
        entrainement: IconTarget,
        examens: IconSheet,
        progression: IconChart,
        profil: IconUser,
    },
    CIVIQUE: {
        accueil: IconHome,
        plan: IconShield,
        entrainement: IconBook,
        examens: IconClock,
        progression: IconChart,
        profil: IconUser,
    },
};

function SidebarBody({
    open = false,
    onClose,
    embedded = false,
    active,
}: {
    open?: boolean;
    onClose?: () => void;
    embedded?: boolean;
    active: ShellActive;
}) {
    const {user} = useAuth();
    const nav = useShellNav();

    const cls = [styles.sidebar, open && styles.open, embedded && styles.embedded]
        .filter(Boolean)
        .join(" ");

    return (
        <aside
            className={cls}
            aria-label="Navigation de l'espace personnel"
            onClick={(e) => {
                // Un lien suivi ferme le tiroir, même vers la même route
                // (`/plan?module=TCF` → `?module=CIVIQUE` ne change pas de chemin).
                if (onClose && (e.target as HTMLElement).closest("a")) onClose();
            }}
        >
            <Link href="/dashboard" className={styles.brand} aria-label="SejourFR — accueil">
                <Cocarde />
                <span className={styles.brandText}>
                    <Wordmark />
                    <span className={styles.brandTag}>{SHELL_BRAND_TAG}</span>
                </span>
            </Link>
            {onClose ? (
                <button
                    type="button"
                    className={styles.drawerClose}
                    onClick={onClose}
                    aria-label="Fermer le menu"
                >
                    <IconClose />
                </button>
            ) : null}

            <nav className={styles.nav}>
                <div className={styles.group}>
                    <p className={styles.groupLabel}>{SHELL_GROUP_OVERVIEW}</p>
                    <NavItem href="/dashboard" active={active.item === "accueil"} icon={<IconHome />}>
                        Accueil
                    </NavItem>
                </div>

                <ModuleBlock module="TCF" sub={nav.tcfSub} tails={nav.tails.TCF} active={active} />
                <ModuleBlock module="CIVIQUE" sub={nav.civiqueSub} tails={nav.tails.CIVIQUE} active={active} />

                <div className={styles.group}>
                    <p className={styles.groupLabel}>{SHELL_GROUP_ACCOUNT}</p>
                    <NavItem href="/profil" active={active.item === "profil"} icon={<IconUser />}>
                        Profil
                    </NavItem>
                </div>
            </nav>

            {user ? (
                <Link href="/profil" className={styles.user}>
                    <span className={styles.avatar} aria-hidden>
                        {shellInitials(user.firstName, user.lastName, user.email)}
                    </span>
                    <span className={styles.userText}>
                        <span className={styles.userName}>
                            {`${user.firstName ?? ""} ${user.lastName ?? ""}`.trim() || user.email}
                        </span>
                        <UserPass premium={user.isPremium ?? false} integral={user.hasTcf ?? false} />
                    </span>
                    <span className={styles.chev} aria-hidden>
                        <IconChevronRight />
                    </span>
                </Link>
            ) : null}
        </aside>
    );
}

function UserPass({premium, integral}: {premium: boolean; integral: boolean}) {
    const nom = passAccessName(premium, integral);
    return (
        <span className={styles.userPlan}>
            <b>{nom}</b> · {premium ? "actif" : "accès gratuit"}
        </span>
    );
}

function ModuleBlock({
    module,
    sub,
    tails,
    active,
}: {
    module: ParcoursModule;
    sub: string;
    tails: Partial<Record<ShellItem, string>>;
    active: ShellActive;
}) {
    const icons = MODULE_ICON[module];
    const ModuleIcon = icons.plan;
    return (
        <section
            className={[styles.module, module === "CIVIQUE" && styles.moduleCivique]
                .filter(Boolean)
                .join(" ")}
            aria-label={SHELL_MODULE_TITLE[module]}
        >
            <div className={styles.moduleHead}>
                <span className={styles.moduleIcon} aria-hidden>
                    <ModuleIcon />
                </span>
                <div>
                    <p className={styles.moduleTitle}>{SHELL_MODULE_TITLE[module]}</p>
                    <p className={styles.moduleSub}>{sub}</p>
                </div>
            </div>
            <div className={styles.moduleItems}>
                {SHELL_MODULE_ITEMS.map((item) => {
                    const Icon = icons[item];
                    return (
                        <NavItem
                            key={item}
                            href={shellModuleHref(item, module)}
                            active={active.module === module && active.item === item}
                            icon={<Icon />}
                            tail={tails[item]}
                        >
                            {shellItemLabel(item, module)}
                        </NavItem>
                    );
                })}
            </div>
        </section>
    );
}

function NavItem({
    href,
    active,
    icon,
    tail,
    children,
}: {
    href: string;
    active: boolean;
    icon: ReactNode;
    tail?: string;
    children: ReactNode;
}) {
    return (
        <Link
            href={href}
            className={[styles.item, active && styles.active].filter(Boolean).join(" ")}
            aria-current={active ? "page" : undefined}
        >
            {icon}
            <span className={styles.itemLabel}>{children}</span>
            {tail ? <span className={styles.tail}>{tail}</span> : null}
        </Link>
    );
}
