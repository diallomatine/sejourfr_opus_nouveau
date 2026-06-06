"use client";

import Link from "next/link";
import { Lightbulb, Waves } from "lucide-react";
import { barTone, categoryHref } from "@/lib/dashboard";
import type { DashboardCategoryStat } from "@/lib/types";
import styles from "./ReinforceRow.module.css";

const FILL_BY_TONE = {
  blue: styles.fillBlue,
  green: styles.fillGreen,
  amber: styles.fillAmber,
} as const;

/**
 * Barre de progression d'une catégorie (teinte selon le score : vert ≥ 80,
 * ambre < 60, bleu sinon) + pourcentage. `fallback` s'affiche à la place du
 * pourcentage quand percent est null (ex: niveau CECRL pour EE/EO, ou "—").
 */
export function CategoryBarLine({
  percent,
  fallback,
}: {
  percent: number | null;
  fallback?: string;
}) {
  return (
    <div className={styles.barRow}>
      <div className={styles.bar} role="presentation">
        {percent !== null && (
          <span
            className={`${styles.fill} ${FILL_BY_TONE[barTone(percent)]}`}
            style={{ width: `${Math.min(100, Math.max(0, percent))}%` }}
          />
        )}
      </div>
      <span className={styles.pct}>
        {percent !== null ? `${percent}%` : (fallback ?? "—")}
      </span>
    </div>
  );
}

/**
 * Ligne "catégorie à renforcer" : icône module, label (+ tag module
 * optionnel), barre + score, CTA Réviser vers l'entraînement ciblé.
 */
export function ReinforceRow({
  cat,
  showModuleTag = false,
}: {
  cat: DashboardCategoryStat;
  showModuleTag?: boolean;
}) {
  const isTcf = cat.code.startsWith("TCF");
  return (
    <li className={styles.row}>
      <span className={`${styles.icon} ${isTcf ? styles.iconRed : ""}`} aria-hidden>
        {isTcf ? <Waves size={17} /> : <Lightbulb size={17} />}
      </span>
      <div className={styles.body}>
        <div className={styles.labelRow}>
          <span className={styles.label}>{cat.label}</span>
          {showModuleTag && (
            <span className={`${styles.tag} ${isTcf ? styles.tagRed : styles.tagBlue}`}>
              {isTcf ? "TCF" : "Civique"}
            </span>
          )}
        </div>
        <CategoryBarLine
          percent={cat.percent}
          fallback={cat.level ?? "À découvrir"}
        />
      </div>
      <Link href={categoryHref(cat)} className={styles.cta}>
        Réviser
      </Link>
    </li>
  );
}
