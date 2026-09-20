"use client";

/**
 * **La carte « ce que votre plan recommande »**, partagée par les écrans qui
 * l'affichent : Réviser (la reprise du parcours) et chaque écran d'épreuve
 * (l'étape du cycle pour CETTE épreuve).
 *
 * ⚠️ Extraite à sa **deuxième** surface (2026-09-20). Elle vivait en privé dans
 * `ReviserScreen` ; la recopier dans les écrans d'épreuve aurait donné deux
 * cartes qui disent la même chose et divergent à la première retouche.
 *
 * 🛑 **Elle ne décide rien** : ni le titre, ni le libellé du bouton, ni le
 * geste. Tout lui arrive de l'autorité du Plan (`planNowCard`,
 * `planEpreuveCarte`, `civicNowCard`). Elle pose des mots servis sur la carte
 * du kit.
 *
 * Miroir mobile : `screens/plan/widgets/plan_reco_card.dart`.
 */

import type {ReactNode} from "react";
import {Card, Cta, Pad, sejourStyles} from "@/app/_components/sejour/SejourKit";
import styles from "./planReco.module.css";

export function PlanRecoCard({
    icon,
    label,
    title,
    subtitle,
    cta,
    href,
    onClick,
    busy,
    error,
    tone,
}: {
    /** Le pictogramme de ce qu'on reprend, **servi par l'écran** : lui seul
     *  sait de quoi il parle — le domaine, le thème, l'épreuve. */
    icon: ReactNode;
    label: string;
    title: string;
    subtitle: string | null;
    cta: string;
    href?: string;
    onClick?: () => void;
    busy?: boolean;
    error?: string | null;
    tone: "primary" | "blue";
}) {
    return (
        <Pad className={styles.wrap}>
            <Card variant="hero" className={styles.card}>
                <p className={sejourStyles.label}>{label}</p>
                <div className={styles.head}>
                    <span className={styles.ico} aria-hidden>
                        {icon}
                    </span>
                    <span>
                        <b>{title}</b>
                        {subtitle ? <span>{subtitle}</span> : null}
                    </span>
                </div>
                <Cta href={href} onClick={onClick} variant={tone} disabled={busy}>
                    {cta}
                </Cta>
                {error ? (
                    <p className={sejourStyles.tiny} role="alert">
                        {error}
                    </p>
                ) : null}
            </Card>
        </Pad>
    );
}
