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
 * La note est celle du TCF, sur la MÊME échelle que l'examen officiel
 * (10-20 = B2, 6-9 = B1, 2-5 = A2, 1 = A1, 0 = hors sujet). Elle est donc
 * directement lisible — d'où la teinte par palier CECRL et non par pourcentage :
 * cette échelle est comprimée, et 7/20 (un B1, le niveau exigé pour la carte de
 * résident) ne doit pas s'afficher comme un « 35 % » rouge.
 *
 * Ce qui reste vrai, et ce que dit le texte : la note porte sur CETTE tâche,
 * alors qu'au TCF la note sur 20 est celle de l'épreuve entière (les 3 tâches),
 * et c'est elle qui donne le niveau officiel.
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
  // Teinte par palier de la grille TCF, jamais par pourcentage : sur cette
  // échelle 10/20 est déjà un B2, et 7/20 un B1 — les seuils scolaires (70/40)
  // peindraient en rouge des notes qui valent le niveau exigé.
  const color =
    note >= 10
      ? "var(--color-green)"
      : note >= 6
        ? "var(--color-blue)"
        : note >= 2
          ? "var(--color-amber)"
          : "var(--color-red)";

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
              La note ci-contre est sur l&apos;échelle du TCF : 10 et plus
              correspond à B2, 6 à 9 à B1, 2 à 5 à A2.
            </p>
          </>
        ) : (
          <>
            <p className={styles.scoreNoteLabel}>Note de la tâche</p>
            <p className={styles.scoreNoteHint}>
              Note sur 20 attribuée par l&apos;IA sur l&apos;échelle du TCF : 10 et
              plus correspond à B2, 6 à 9 à B1, 2 à 5 à A2. Elle porte sur cette
              seule tâche — au TCF, la note sur 20 est celle de l&apos;épreuve
              entière, vos trois tâches.
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
        </div>
      </div>
    </div>
  );
}
