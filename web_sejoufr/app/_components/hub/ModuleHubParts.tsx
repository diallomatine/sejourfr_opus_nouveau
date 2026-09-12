"use client";

import { categoryBadge } from "@/lib/dashboard";
import styles from "./moduleHub.module.css";

/**
 * **L'anneau de maîtrise d'une catégorie**, et plus rien d'autre.
 *
 * ⚠️ Ce fichier portait les briques du hub module (en-tête eyebrow, bande de
 * quatre stats, carte catégorie à chips et double CTA). Les hubs
 * `/entrainement` ont été **refaits sur la maquette** (`ReviserScreen`,
 * 2026-09-12) et ces briques n'ont plus d'appelant : elles sont supprimées —
 * refonte = suppression immédiate de l'ancien. Seul `ProgressDonut` reste, lu
 * par `/statistiques` et par `DetailParts`.
 */

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
