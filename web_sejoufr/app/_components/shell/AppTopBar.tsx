"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense} from "react";
import {appBarInfo} from "@/lib/app-bar";
import {useAuth} from "@/lib/auth-context";
import {retourOuRepli} from "@/lib/retour";
import {shellCrumb, shellInitials} from "@/lib/shell-nav";
import {useAppBarBackOverride, useAppBarOverride} from "../AppBarTitle";
import {IconArrowLeft, IconBurger} from "./ShellIcons";
import styles from "./shell.module.css";

/**
 * **La barre du haut de l'espace connecté** (maquette « Navigation v2 »),
 * sticky et visible à toutes les largeurs : burger (≤ 1024 px, ouvre le
 * tiroir), flèche de retour d'un sous-écran (`useAppBarBack`), fil d'Ariane
 * `SejourFR / {Section} / {Page}` (masqué ≤ 520 px), avatar → `/profil`.
 *
 * Page du fil : le libellé du menu sur l'adresse racine d'une entrée, sinon
 * le titre posé par la page (`useAppBarTitle`) ou celui de `lib/app-bar.ts`.
 * La page se colore au module (`--color-module-*`) : bleu TCF, rouge civique.
 */
export function AppTopBar({open, onOpenMenu}: {open: boolean; onOpenMenu: () => void}) {
    const router = useRouter();
    const back = useAppBarBackOverride();
    const {user} = useAuth();

    return (
        <header className={styles.topbar}>
            <button
                type="button"
                className={`${styles.iconButton} ${styles.burger}`}
                aria-label="Ouvrir le menu"
                aria-expanded={open}
                onClick={onOpenMenu}
            >
                <IconBurger />
            </button>
            {back ? (
                <button
                    type="button"
                    className={styles.iconButton}
                    aria-label="Retour"
                    onClick={() =>
                        back.onBack ? back.onBack() : retourOuRepli(router, back.fallbackHref)
                    }
                >
                    <IconArrowLeft />
                </button>
            ) : null}
            <Suspense fallback={null}>
                <Crumb />
            </Suspense>
            <span className={styles.spacer} />
            <Link href="/profil" className={styles.topAvatar} aria-label="Mon profil">
                {user ? shellInitials(user.firstName, user.lastName, user.email) : ""}
            </Link>
        </header>
    );
}

function Crumb() {
    const pathname = usePathname();
    const search = useSearchParams();
    const override = useAppBarOverride();
    const titre = (override ?? appBarInfo(pathname)).title;
    const {section, page, module} = shellCrumb(pathname, search, titre);
    const hereCls = [
        styles.here,
        module === "TCF" && styles.hereTcf,
        module === "CIVIQUE" && styles.hereCivique,
    ]
        .filter(Boolean)
        .join(" ");
    return (
        <nav className={styles.crumb} aria-label="Fil d'Ariane">
            <span>SejourFR</span>
            <span className={styles.sep} aria-hidden>
                /
            </span>
            {section ? (
                <>
                    <span>{section}</span>
                    <span className={styles.sep} aria-hidden>
                        /
                    </span>
                </>
            ) : null}
            <span className={hereCls} aria-current="page">
                {page}
            </span>
        </nav>
    );
}
