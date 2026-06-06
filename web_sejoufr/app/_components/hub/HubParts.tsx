"use client";

import Link from "next/link";
import type {CSSProperties, ReactNode} from "react";
import {ChevronLeft, Play, Rocket} from "lucide-react";
import styles from "./hub.module.css";

// ============================================================================
// Briques résiduelles des pages détail / production (les hubs et pages
// d'entraînement utilisent désormais ModuleHubParts / DetailParts). Restent
// ici : ExamBlancHero (ProductionHub), SectionLabel/Counter/Link,
// HubDetailHeader.
// ============================================================================

// ---------- Hero examen blanc ----------

export function ExamBlancHero({
                                  eyebrow,
                                  title,
                                  description,
                                  ctaLabel,
                                  accent = "blue",
                                  onClick,
                              }: {
    eyebrow: string;
    title: string;
    description: string;
    ctaLabel: string;
    accent?: "blue" | "red";
    onClick: () => void;
}) {
    const vars =
        accent === "red"
            ? {
                "--accent-start": "var(--color-red)",
                "--accent-end": "var(--color-red-dark)",
                "--accent-shadow": "rgba(225, 55, 47, 0.45)",
            }
            : {
                "--accent-start": "var(--color-blue)",
                "--accent-end": "var(--color-blue-dark)",
                "--accent-shadow": "rgba(30, 58, 140, 0.5)",
            };
    return (
        <button type="button" className={styles.hero} style={vars as CSSProperties} onClick={onClick}>
      <span className={styles.heroEyebrow}>
        <Rocket size={13} strokeWidth={2.2}/>
          {eyebrow.toUpperCase()}
      </span>
            <span className={styles.heroTitle} style={{display: "block"}}>
        {title}
      </span>
            <span className={styles.heroDesc} style={{display: "block"}}>
        {description}
      </span>
            <span className={styles.heroCta}>
        <Play size={15} strokeWidth={2.4} fill="currentColor"/>
                {ctaLabel}
      </span>
        </button>
    );
}

// ---------- Section label ----------

export function SectionLabel({label, trailing}: { label: string; trailing?: ReactNode }) {
    return (
        <div className={styles.sectionRow}>
            <p className={styles.sectionLabel}>{label}</p>
            {trailing}
        </div>
    );
}

export function SectionCounter({text}: { text: string }) {
    return <span className={styles.sectionCounter}>{text}</span>;
}

export function SectionLink({label, onClick}: { label: string; onClick: () => void }) {
    return (
        <button type="button" className={styles.sectionLink} onClick={onClick}>
            {label}
        </button>
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
