"use client";

import {cecrlIndex, niveauCecrlLabel, type NiveauCecrl} from "@/lib/types";
import styles from "./production.module.css";

const SCALE: NiveauCecrl[] = ["A1", "A2", "B1", "B2", "C1", "C2"];

/**
 * Carte score d'une production évaluée : donut note/20 + pastille niveau CECRL
 * + échelle A1→C2, calquée sur `DonutChartScore` mobile. La couleur du donut
 * suit le pourcentage (rouge < 40 %, ambre 40–70 %, vert ≥ 70 %).
 */
export function CecrlScoreDonut({
  noteSurVingt,
  niveauCecrl,
  justification,
}: {
  noteSurVingt: number | null;
  niveauCecrl: NiveauCecrl | null;
  justification?: string | null;
}) {
  const note = noteSurVingt ?? 0;
  const pct = Math.max(0, Math.min(100, Math.round((note / 20) * 100)));
  const color =
    pct >= 70 ? "var(--color-green)" : pct >= 40 ? "var(--color-amber)" : "var(--color-red)";

  const r = 52;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - pct / 100);
  const targetIdx = cecrlIndex(niveauCecrl);

  return (
    <div className={styles.scoreCard}>
      <div className={styles.donut}>
        <svg width="128" height="128" viewBox="0 0 128 128">
          <circle cx="64" cy="64" r={r} fill="none" stroke="var(--color-line-2)" strokeWidth="10" />
          <circle
            cx="64"
            cy="64"
            r={r}
            fill="none"
            stroke={color}
            strokeWidth="10"
            strokeLinecap="round"
            strokeDasharray={c}
            strokeDashoffset={offset}
            transform="rotate(-90 64 64)"
          />
        </svg>
        <div className={styles.donutLabel}>
          <span className={styles.donutScore}>
            {noteSurVingt != null ? formatNote(note) : "—"}
            <span className={styles.donutOf}>/20</span>
          </span>
          <span className={styles.donutPct}>{noteSurVingt != null ? `${pct}%` : ""}</span>
        </div>
      </div>

      <div className={styles.scoreSide}>
        <div className={styles.cecrlPill}>
          <span className={styles.cecrlPillLabel}>Niveau estimé</span>
          <span className={styles.cecrlPillVal}>{niveauCecrlLabel(niveauCecrl)}</span>
        </div>
        {justification && <p className={styles.scoreJustif}>{justification}</p>}

        <div className={styles.cecrlScale} aria-hidden>
          {SCALE.map((lvl, i) => (
            <span
              key={lvl}
              className={`${styles.cecrlSeg} ${
                targetIdx >= 0 && i === targetIdx
                  ? styles.cecrlSegTarget
                  : targetIdx >= 0 && i < targetIdx
                    ? styles.cecrlSegOn
                    : ""
              }`}
            />
          ))}
        </div>
        <div className={styles.cecrlLabels} aria-hidden>
          {SCALE.map((lvl) => (
            <span key={lvl}>{lvl}</span>
          ))}
        </div>
      </div>
    </div>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
