"use client";

import {usePathname, useSearchParams} from "next/navigation";
import {Suspense, useCallback, useEffect, useState, type ReactNode} from "react";
import {AppBarProvider} from "../AppBarTitle";
import {AppSidebar} from "./AppSidebar";
import {AppTopBar} from "./AppTopBar";
import styles from "./shell.module.css";

/**
 * **Le shell de l'espace connecté** (maquette « Navigation v2 ») — monté par
 * `app/(app)/layout.tsx` ET par `DualChromeShell` (routes duales) pour un
 * compte : un seul shell, deux points de montage.
 *
 * - > 1024 px : barre latérale fixe (292 px) + colonne de contenu ;
 * - ≤ 1024 px : la même barre devient un tiroir (burger, overlay flouté,
 *   bouton fermer, fermeture à la navigation et à Échap, scroll du body
 *   bloqué).
 *
 * 🛑 La classe globale `app-shell` est le marqueur que lisent les écrans
 * (`.app-shell .X`) : sous elle, un écran ne pose pas sa propre marge haute,
 * le contenu du shell (`.content`) porte celle de la maquette.
 */
export function AppShell({children}: {children: ReactNode}) {
    const [open, setOpen] = useState(false);
    const close = useCallback(() => setOpen(false), []);

    useBodyScrollLock(open);

    useEffect(() => {
        if (!open) return;
        const onKey = (e: KeyboardEvent) => {
            if (e.key === "Escape") setOpen(false);
        };
        // Revenu au-dessus de 1024 px, le tiroir n'existe plus : on le ferme
        // pour ne pas laisser le body figé.
        const desktop = window.matchMedia("(min-width: 1025px)");
        const onDesktop = () => {
            if (desktop.matches) setOpen(false);
        };
        window.addEventListener("keydown", onKey);
        desktop.addEventListener("change", onDesktop);
        return () => {
            window.removeEventListener("keydown", onKey);
            desktop.removeEventListener("change", onDesktop);
        };
    }, [open]);

    return (
        <div className={`app-shell ${styles.shell}`}>
            <AppSidebar open={open} onClose={close} />
            <div
                className={open ? styles.overlayShow : styles.overlay}
                onClick={close}
                aria-hidden
            />
            <div className={styles.main}>
                <AppBarProvider>
                    <Suspense fallback={null}>
                        <CloseOnNavigation onNavigate={close} />
                    </Suspense>
                    <AppTopBar open={open} onOpenMenu={() => setOpen(true)} />
                    <div className={styles.content}>{children}</div>
                </AppBarProvider>
            </div>
        </div>
    );
}

/** Ferme le tiroir à chaque changement d'adresse, paramètres compris. */
function CloseOnNavigation({onNavigate}: {onNavigate: () => void}) {
    const pathname = usePathname();
    const search = useSearchParams();
    const adresse = `${pathname}?${search?.toString() ?? ""}`;
    useEffect(() => {
        onNavigate();
    }, [adresse, onNavigate]);
    return null;
}

/**
 * `overflow: hidden` sur le body ne suffit PAS sur iOS Safari : on le fige en
 * `position: fixed` à la position courante, puis on restaure le défilement.
 */
function useBodyScrollLock(locked: boolean) {
    useEffect(() => {
        if (!locked) return;
        const body = document.body;
        const scrollY = window.scrollY;
        const prev = {
            position: body.style.position,
            top: body.style.top,
            left: body.style.left,
            right: body.style.right,
            width: body.style.width,
        };
        body.style.position = "fixed";
        body.style.top = `-${scrollY}px`;
        body.style.left = "0";
        body.style.right = "0";
        body.style.width = "100%";
        return () => {
            body.style.position = prev.position;
            body.style.top = prev.top;
            body.style.left = prev.left;
            body.style.right = prev.right;
            body.style.width = prev.width;
            window.scrollTo(0, scrollY);
        };
    }, [locked]);
}
