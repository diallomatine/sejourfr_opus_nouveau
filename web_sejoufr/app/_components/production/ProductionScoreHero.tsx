"use client";

import {
  TCF_NOTE_BANDS,
  canShowNiveau,
  shouldShowConfiance,
  tcfBandRange,
  tcfNiveauTone,
  tcfNoteTone,
  tcfScalePosition,
} from "@/lib/production-feedback";
import {
  confianceLabel,
  formatNoteSur20,
  niveauCecrlLabel,
  type ConfianceEvaluation,
  type NiveauCecrl,
} from "@/lib/types";
import styles from "./production.module.css";

/**
 * La note et **l'échelle sur laquelle elle se lit**.
 *
 * Notre note est une **estimation pédagogique exprimée sur l'échelle du TCF**
 * (0 → A1 non atteint, 1 → A1, 2-5 → A2, 6-9 → B1, 10-20 → B2) : l'échelle est
 * bien celle de l'examen, la correction est la nôtre — elle n'est pas celle de
 * France Éducation international, qui fait corriger chaque production par
 * plusieurs évaluateurs humains indépendants. Sans cette échelle sous les yeux,
 * un 4,5/20 se lit comme une catastrophe scolaire alors qu'il vaut A2 : c'est
 * exactement ce que cette carte corrige. D'où l'absence de tout pourcentage et
 * de toute jauge « sur 20 points » — ce serait redire l'échelle française qu'on
 * cherche à désamorcer.
 *
 * Deux règles vivent ici, et nulle part ailleurs :
 *
 * 1. **Le niveau ne s'affiche jamais sans sa confiance**
 *    ({@link canShowNiveau}) : sans elle, on retombe sur la note seule plutôt
 *    que d'annoncer un niveau sans dire ce qu'il vaut.
 * 2. **Une confiance HAUTE ne s'affiche pas** ({@link shouldShowConfiance}) :
 *    c'est le cas normal, l'écrire n'apprend rien et fait douter d'un résultat
 *    qui ne le mérite pas. Elle n'apparaît, avec ses raisons, que lorsqu'elle
 *    nuance vraiment le résultat.
 *
 * Le niveau qui fait foi reste celui du bilan des trois tâches
 * (`avertissementNiveau`, fourni par le backend) — dit en second plan, après
 * l'information principale.
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
  const showLevel = canShowNiveau(niveau, confiance);
  const showConfiance = shouldShowConfiance(confiance);
  const position = tcfScalePosition(noteSurVingt);
  // Le verdict ne se peint jamais en rouge : ni un palier bas (un A1 reste un
  // résultat), ni une production pas encore évaluée (« — » gris neutre).
  const tone = tcfNoteTone(noteSurVingt);

  return (
    <div className={`${styles.scoreCard} ${showLevel ? styles.scoreCardLevel : ""}`}>
      <div className={styles.scoreHead}>
        <p className={styles.scoreNote} data-tone={tone}>
          {noteSurVingt != null ? formatNoteSur20(noteSurVingt) : "—"}
          <span className={styles.scoreNoteOf}>/20</span>
        </p>
        <div className={styles.scoreSide}>
          {showLevel ? (
            <>
              <p className={styles.heroEyebrow}>Niveau observé sur cette tâche</p>
              <p className={styles.heroLevel}>
                {niveau === "A1_NON_ATTEINT"
                  ? "Niveau A1 non atteint"
                  : `Proche du niveau ${niveauCecrlLabel(niveau)}`}
              </p>
            </>
          ) : (
            <>
              <p className={styles.heroEyebrow}>Note de la tâche</p>
              <p className={styles.scoreNoteHint}>
                Note attribuée par l&apos;IA sur l&apos;échelle du TCF, celle de
                l&apos;examen officiel.
              </p>
            </>
          )}
        </div>
      </div>

      <TcfScale
        percent={position?.percent ?? null}
        activeIndex={position?.bandIndex ?? null}
        note={noteSurVingt}
      />

      {showConfiance && confiance && (
        <p className={styles.heroConf}>
          <span className={styles.confChip} data-confiance={confiance}>
            {confianceLabel(confiance)}
          </span>
          <span className={styles.heroConfWhy}>
            {confianceRaisons.length > 0
              ? confianceRaisons.join(" · ")
              : "Une partie de votre production était difficile à analyser : cette note est à prendre avec prudence."}
          </span>
        </p>
      )}

      <p className={styles.heroFoot}>
        {avertissementNiveau ??
          "Estimation portant sur cette seule tâche. Le niveau qui fait foi est celui du bilan des trois tâches de l'épreuve."}
      </p>
    </div>
  );
}

/**
 * L'échelle officielle, dessinée à bandes de largeur égale et non à l'échelle
 * réelle : « B2 » vaut la moitié des notes possibles et « A1 non atteint » une
 * seule — proportionnelles, elles seraient illisibles. Le curseur, lui, est
 * placé proportionnellement DANS sa bande (cf. `tcfScalePosition`).
 */
function TcfScale({
  percent,
  activeIndex,
  note,
}: {
  percent: number | null;
  activeIndex: number | null;
  note: number | null;
}) {
  const activeBand = activeIndex != null ? TCF_NOTE_BANDS[activeIndex] : null;

  return (
    <div className={styles.scale}>
      <p className={styles.scaleTitle}>Échelle du TCF</p>
      <div
        className={styles.scaleTrack}
        role="img"
        aria-label={
          note != null && activeBand
            ? `Votre note, ${formatNoteSur20(note)} sur 20, se situe dans la bande ${activeBand.label} de l'échelle du TCF.`
            : "Échelle de notation du TCF."
        }
      >
        {TCF_NOTE_BANDS.map((band, i) => (
          <span
            key={band.niveau}
            className={styles.scaleSeg}
            data-tone={tcfNiveauTone(band.niveau)}
            data-active={i === activeIndex ? "" : undefined}
          />
        ))}
        {percent != null && (
          <span
            className={styles.scaleCursor}
            style={{left: `${percent}%`}}
            data-tone={activeBand ? tcfNiveauTone(activeBand.niveau) : undefined}
            aria-hidden
          />
        )}
      </div>
      <div className={styles.scaleLabels} aria-hidden>
        {TCF_NOTE_BANDS.map((band, i) => (
          <span
            key={band.niveau}
            className={styles.scaleLabel}
            data-active={i === activeIndex ? "" : undefined}
          >
            {/* Plage en premier : « A1 non atteint » passe sur deux lignes sous
                360 px, et les plages doivent rester alignées entre elles. */}
            <span className={styles.scaleLabelRange}>{tcfBandRange(band)}</span>
            <span className={styles.scaleLabelLvl}>{band.label}</span>
          </span>
        ))}
      </div>
      <p className={styles.scaleFoot}>
        Notre note est une estimation, exprimée sur l&apos;échelle du TCF : elle
        se lit ainsi, pas comme une note scolaire sur 20.
      </p>
    </div>
  );
}
