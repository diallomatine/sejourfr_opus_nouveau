"use client";

import styles from "./production.module.css";

/**
 * Carte score d'une production évaluée : donut note/20 seul. Le niveau CECRL
 * n'est plus attribué par tâche (il ne vit qu'au bilan d'épreuve en examen
 * blanc). La couleur du donut suit le pourcentage (rouge < 40 %, ambre 40–70 %,
 * vert ≥ 70 %).
 *
 * Cette note est PÉDAGOGIQUE : notre échelle (16-20 = B2, 11-15 = B1, 6-10 = A2,
 * 1-5 = A1) est plus fine que celle du TCF, où 10/20 suffit déjà pour B2. On ne
 * met donc AUCUNE correspondance TCF ici — au TCF, la note /20 porte sur les 3
 * tâches d'une épreuve, jamais sur une tâche isolée.
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
        <p className={styles.scoreNoteLabel}>Note pédagogique de la tâche</p>
        <p className={styles.scoreNoteHint}>
          Note sur 20 attribuée par l&apos;IA selon les critères du TCF. Notre
          échelle est plus fine que celle du TCF, qui note l&apos;épreuve entière
          et pas une tâche : la correspondance officielle s&apos;affiche au bilan
          de l&apos;épreuve.
        </p>
      </div>
    </div>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
