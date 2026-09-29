"use client";

import Link from "next/link";
import {usePathname} from "next/navigation";
import {Cocarde, Wordmark} from "./Brand";
import {useAuth} from "@/lib/auth-context";
import {shouldHideGlobalChrome} from "@/lib/chrome-routes";
import styles from "./Footer.module.css";

/**
 * Pied de page public (maquette « accueil v3 », 2026-09-26) : marque + trois
 * colonnes de liens. Masqué exactement comme l'en-tête (`shouldHideGlobalChrome`).
 */
const COLUMNS: {title: string; links: {href: string; label: string}[]}[] = [
    {
        title: "Produit",
        links: [
            {href: "/entrainement?module=TCF", label: "TCF IRN"},
            {href: "/entrainement?module=CIVIQUE", label: "Examen civique"},
            {href: "/tarifs", label: "Tarifs"},
        ],
    },
    {
        title: "Ressources",
        links: [
            {href: "/blog", label: "Blog"},
            {href: "/faq", label: "FAQ"},
            {href: "/blog/demande-naturalisation-francaise-guide-complet", label: "Guide naturalisation"},
        ],
    },
    {
        title: "Légal",
        links: [
            {href: "/a-propos", label: "À propos"},
            {href: "/cgu", label: "CGU"},
            {href: "/mentions-legales", label: "Mentions légales"},
            {href: "/confidentialite", label: "Confidentialité"},
            {href: "/confidentialite#article-8", label: "Cookies"},
            {href: "/contact", label: "Contact"},
        ],
    },
];

export function Footer() {
    const pathname = usePathname();
    const {status, user} = useAuth();
    const isAuth = status === "authenticated" && user !== null;
    if (shouldHideGlobalChrome(pathname, isAuth)) return null;

    return (
        <footer className={styles.footer}>
            <div className={styles.wrap}>
                <div className={styles.main}>
                    <div className={styles.brandCol}>
                        <Link href="/" className={styles.brand} aria-label="SejourFR — accueil">
                            <Cocarde/>
                            <Wordmark/>
                        </Link>
                        <p className={styles.pitch}>
                            Préparez sereinement votre examen civique pour le titre de séjour et votre
                            entretien de naturalisation.
                        </p>
                    </div>

                    {COLUMNS.map((col) => (
                        <div key={col.title} className={styles.col}>
                            <h2 className={styles.colTitle}>{col.title}</h2>
                            {col.links.map((l) => (
                                <Link key={l.label} href={l.href} className={styles.colLink}>
                                    {l.label}
                                </Link>
                            ))}
                        </div>
                    ))}
                </div>
            </div>
        </footer>
    );
}
