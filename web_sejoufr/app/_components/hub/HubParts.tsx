"use client";

import Link from "next/link";
import type {ReactNode} from "react";
import {ChevronLeft} from "lucide-react";
import styles from "./hub.module.css";

// ============================================================================
// Briques résiduelles des écrans production (les hubs et pages
// d'entraînement utilisent ModuleHubParts / DetailParts). Restent ici :
// SectionLabel et HubDetailHeader.
// ============================================================================

// ---------- Section label ----------

export function SectionLabel({label, trailing}: { label: string; trailing?: ReactNode }) {
    return (
        <div className={styles.sectionRow}>
            <p className={styles.sectionLabel}>{label}</p>
            {trailing}
        </div>
    );
}

// ---------- En-tête de page détail (back + titre) ----------

export function HubDetailHeader({
                                    backHref,
                                    title,
                                    subtitle,
                                }: {
    backHref: string;
    title: string;
    subtitle: string;
}) {
    return (
        <div className={styles.detailHeader}>
            <Link href={backHref} className={styles.backBtn} aria-label="Retour">
                <ChevronLeft size={20}/>
            </Link>
            <div>
                <h1 className={styles.headerTitle}>{title}</h1>
                <p className={styles.headerSub}>{subtitle}</p>
            </div>
        </div>
    );
}
