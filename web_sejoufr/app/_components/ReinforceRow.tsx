"use client";

import Link from "next/link";
import { Lightbulb, Waves } from "lucide-react";
import { barTone, categoryHref } from "@/lib/dashboard";
import { niveauActuelEpreuve } from "@/lib/progres";
import { niveauCecrlLabel, type DashboardCategoryStat, type TcfDomainProfileDto } from "@/lib/types";
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
            className={`${styles.fill} ${FILL_BY_TONE[barTone()]}`}
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
 *
 * 🛑 **Le palier de repli vient de l'AUTORITÉ D'AFFICHAGE** (`tcfDomainProfile`,
 * par `niveauActuelEpreuve`) — jamais de `DashboardCategoryStat.level`, qui
 * voyait le dernier niveau de **n'importe quelle** soumission, entraînements
 * compris. → `docs/decisions/diagnostic.md`, 2026-09-16.
 *
 * 🛑 **Seules les 4 épreuves TCF ont un palier.** Thème civique et
 * `TCF_STRUCTURE` rendent `null` ⇒ la ligne garde son « À découvrir », jamais
 * un palier fabriqué.
 */
export function ReinforceRow({
  cat,
  showModuleTag = false,
  profil = null,
}: {
  cat: DashboardCategoryStat;
  showModuleTag?: boolean;
  /** Servi par le **même** appel que `cat` (`GET /api/me/dashboard`). */
  profil?: TcfDomainProfileDto | null;
}) {
  const isTcf = cat.code.startsWith("TCF");
  const niveau = niveauActuelEpreuve(profil, cat.code);
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
          fallback={niveau ? niveauCecrlLabel(niveau) : "À découvrir"}
        />
      </div>
      <Link href={categoryHref(cat)} className={styles.cta}>
        Réviser
      </Link>
    </li>
  );
}
