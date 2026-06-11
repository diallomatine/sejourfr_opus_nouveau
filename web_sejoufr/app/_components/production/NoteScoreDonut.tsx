"use client";

import styles from "./production.module.css";

/**
 * Carte score d'une production évaluée : donut note/20 seul. Le niveau CECRL
 * n'est plus attribué par tâche (il ne vit qu'au bilan d'épreuve en examen
 * blanc). La couleur du donut suit le pourcentage (rouge < 40 %, ambre 40–70 %,
 * vert ≥ 70 %).
 */
export function NoteScoreDonut({noteSurVingt}: {noteSurVingt: number | null}) {
  const note = noteSurVingt ?? 0;
  const pct = Math.max(0, Math.min(100, Math.round((note / 20) * 100)));
  const color =
    pct >= 70 ? "var(--color-green)" : pct >= 40 ? "var(--color-amber)" : "var(--color-red)";

  const r = 52;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - pct / 100);

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
        <p className={styles.scoreNoteLabel}>Note de la tâche</p>
        <p className={styles.scoreNoteHint}>
          Note sur 20 attribuée par l&apos;IA selon les critères du TCF.
        </p>
      </div>
    </div>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
