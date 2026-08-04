"use client";

import {
  confianceLabel,
  formatNoteSur20,
  niveauCecrlLabel,
  type ConfianceEvaluation,
  type NiveauCecrl,
} from "@/lib/types";
import styles from "./production.module.css";

/**
 * En-tête du résultat d'une production : le NIVEAU OBSERVÉ d'abord — c'est
 * l'information que le candidat cherche — avec sa note /20 à côté.
 *
 * Deux règles portées ici, et nulle part ailleurs :
 *
 * 1. **Le niveau ne s'affiche jamais sans sa confiance.** Le garde-fou vit dans
 *    ce composant : sans `confiance`, on retombe sur la note seule plutôt que
 *    d'annoncer un niveau sans dire ce qu'il vaut.
 * 2. **Le niveau qui fait foi reste celui du bilan des trois tâches** — dit en
 *    second plan (`avertissementNiveau`, fourni par le backend), après
 *    l'information principale et non avant.
 *
 * La note est PÉDAGOGIQUE : notre échelle (16-20 = B2, 11-15 = B1, 6-10 = A2,
 * 1-5 = A1) est plus fine que celle du TCF, où 10/20 vaut déjà B2. Aucune
 * correspondance TCF ici : au TCF, une tâche isolée n'a pas de note.
 */
export function ProductionScoreHero({
  noteSurVingt,
  niveau,
  confiance,
  avertissementNiveau,
  confianceRaisons,
}: {
  noteSurVingt: number | null;
  niveau: NiveauCecrl | null;
  confiance: ConfianceEvaluation | null;
  avertissementNiveau: string | null;
  confianceRaisons: string[];
}) {
  const showLevel = niveau != null && confiance != null;
  const note = noteSurVingt ?? 0;
  const pct = Math.max(0, Math.min(100, Math.round((note / 20) * 100)));
  const color =
    pct >= 70 ? "var(--color-green)" : pct >= 40 ? "var(--color-amber)" : "var(--color-red)";

  const r = 52;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - pct / 100);

  return (
    <div className={`${styles.scoreCard} ${showLevel ? styles.scoreCardLevel : ""}`}>
      <div className={styles.scoreSide}>
        {showLevel ? (
          <>
            <p className={styles.heroEyebrow}>Niveau observé sur cette tâche</p>
            <p className={styles.heroLevel}>
              {niveau === "A1_NON_ATTEINT"
                ? "Niveau A1 non atteint"
                : `Proche du niveau ${niveauCecrlLabel(niveau)}`}
            </p>
            <p className={styles.heroConf}>
              <span className={styles.confChip} data-confiance={confiance}>
                {confianceLabel(confiance)}
              </span>
              {confianceRaisons.length > 0 && (
                <span className={styles.heroConfWhy}>{confianceRaisons.join(" · ")}</span>
              )}
            </p>
            <p className={styles.heroFoot}>
              {avertissementNiveau ??
                "Estimation pédagogique portant sur cette seule tâche. Le niveau qui fait foi est celui du bilan des trois tâches de l'épreuve."}{" "}
              La note ci-contre suit notre échelle pédagogique, plus fine que celle
              du TCF : sa correspondance officielle s&apos;affiche au bilan.
            </p>
          </>
        ) : (
          <>
            <p className={styles.scoreNoteLabel}>Note pédagogique de la tâche</p>
            <p className={styles.scoreNoteHint}>
              Note sur 20 attribuée par l&apos;IA selon les critères du TCF. Notre
              échelle est plus fine que celle du TCF, qui note l&apos;épreuve entière
              et pas une tâche : la correspondance officielle s&apos;affiche au bilan
              de l&apos;épreuve.
            </p>
          </>
        )}
      </div>

      <div className={styles.donut}>
        <svg viewBox="0 0 128 128" width="100%" height="100%">
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
            {noteSurVingt != null ? formatNoteSur20(note) : "—"}
            <span className={styles.donutOf}>/20</span>
          </span>
          <span className={styles.donutPct}>{noteSurVingt != null ? `${pct}%` : ""}</span>
        </div>
      </div>
    </div>
  );
}
