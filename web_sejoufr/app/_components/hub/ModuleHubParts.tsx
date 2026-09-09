"use client";

import Link from "next/link";
import { categoryBadge } from "@/lib/dashboard";
import styles from "./moduleHub.module.css";

/**
 * Briques du hub module (maquette sejour_fr.html) : header eyebrow + bande
 * de 4 stats + card catégorie (icône, donut, chips, badge statut, CTAs).
 * TcfHub et CiviqueHub assemblent ces briques avec leurs données.
 */

export function ModuleHubHeader({
  eyebrowIcon,
  eyebrow,
  title,
  subtitle,
  action,
}: {
  eyebrowIcon: React.ReactNode;
  eyebrow: string;
  title: string;
  subtitle: string;
  action?: React.ReactNode;
}) {
  return (
    <header className={styles.head}>
      <div className={styles.headText}>
        <div className={styles.eyebrow}>
          <span aria-hidden>{eyebrowIcon}</span>
          <span className={styles.eyebrowLabel}>{eyebrow}</span>
        </div>
        <h1 className={styles.title}>{title}</h1>
        <p className={styles.subtitle}>{subtitle}</p>
      </div>
      {action && <div className={styles.headActions}>{action}</div>}
    </header>
  );
}

export interface ModuleStatCell {
  label: string;
  value: string;
  hint: string;
  /** Met la valeur en bleu (maîtrise globale dans la maquette). */
  accent?: boolean;
}

export function ModuleStatsBand({ cells }: { cells: ModuleStatCell[] }) {
  return (
    <div className={styles.statsBand}>
      <div className={styles.statsGrid}>
        {cells.map((c) => (
          <div key={c.label} className={styles.statCell}>
            <div className={styles.statLabel}>{c.label}</div>
            <div className={styles.statValueRow}>
              <span
                className={`${styles.statValue} ${c.accent ? styles.statValueAccent : ""}`}
              >
                {c.value}
              </span>
              <span className={styles.statHint}>{c.hint}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

const DONUT_R = 23;
const DONUT_C = 2 * Math.PI * DONUT_R;

const DONUT_FILL = {
  blue: styles.donutFillBlue,
  green: styles.donutFillGreen,
  amber: styles.donutFillAmber,
} as const;

/** Donut 52px : teinte selon le statut de la catégorie, "—" si jamais travaillée. */
export function ProgressDonut({ percent }: { percent: number | null }) {
  const { tone } = categoryBadge(percent);
  const clamped = percent === null ? 0 : Math.min(100, Math.max(0, percent));
  return (
    <div className={styles.donut} role="presentation">
      <svg width="52" height="52" className={styles.donutSvg}>
        <circle
          cx="26"
          cy="26"
          r={DONUT_R}
          fill="none"
          strokeWidth="6"
          className={styles.donutTrack}
        />
        {percent !== null && (
          <circle
            cx="26"
            cy="26"
            r={DONUT_R}
            fill="none"
            strokeWidth="6"
            strokeLinecap="round"
            strokeDasharray={DONUT_C}
            strokeDashoffset={DONUT_C * (1 - clamped / 100)}
            className={tone === "none" ? styles.donutFillBlue : DONUT_FILL[tone]}
          />
        )}
      </svg>
      <div className={styles.donutCenter}>
        <span className={styles.donutValue}>
          {percent !== null ? `${percent}%` : "—"}
        </span>
      </div>
    </div>
  );
}

const BADGE_BY_TONE = {
  blue: styles.badgeBlue,
  green: styles.badgeGreen,
  amber: styles.badgeAmber,
  none: styles.badgeNone,
} as const;

export interface CategoryCta {
  label: string;
  href: string;
  icon?: React.ReactNode;
  variant: "soft" | "solid";
}

export type CategoryIconTone = "blue" | "green" | "amber" | "red" | "slate";

const ICON_TONES: Record<CategoryIconTone, string> = {
  blue: "",
  green: styles.cardIconGreen,
  amber: styles.cardIconAmber,
  red: styles.cardIconRed,
  slate: styles.cardIconSlate,
};

/**
 * Card catégorie : icône + titre + description + donut, chips de contenus,
 * badge de statut + méta ("4 examens blancs" / "Niveau estimé B1"), CTAs.
 */
export function CategoryCard({
  icon,
  iconTone = "blue",
  title,
  desc,
  percent,
  chips,
  meta,
  ctas,
}: {
  icon: React.ReactNode;
  iconTone?: CategoryIconTone;
  title: string;
  desc: string;
  percent: number | null;
  chips: string[];
  meta: string;
  ctas: CategoryCta[];
}) {
  const status = categoryBadge(percent);
  return (
    <article className={styles.card}>
      <div className={styles.cardTop}>
        <span className={`${styles.cardIcon} ${ICON_TONES[iconTone]}`} aria-hidden>
          {icon}
        </span>
        <div className={styles.cardTitles}>
          <h3 className={styles.cardTitle}>{title}</h3>
          <p className={styles.cardDesc}>{desc}</p>
        </div>
        <ProgressDonut percent={percent} />
      </div>

      <div className={styles.chips}>
        {chips.map((chip) => (
          <span key={chip} className={styles.chip}>
            {chip}
          </span>
        ))}
      </div>

      <div className={styles.statusRow}>
        <span className={`${styles.badge} ${BADGE_BY_TONE[status.tone]}`}>
          {status.label}
        </span>
        <span className={styles.statusMeta}>{meta}</span>
      </div>

      <div className={styles.ctaRow}>
        {ctas.map((cta) => (
          <Link
            key={cta.label}
            href={cta.href}
            className={`${styles.cta} ${cta.variant === "solid" ? styles.ctaSolid : styles.ctaSoft}`}
          >
            {cta.icon && <span aria-hidden>{cta.icon}</span>}
            {cta.label}
          </Link>
        ))}
      </div>
    </article>
  );
}
