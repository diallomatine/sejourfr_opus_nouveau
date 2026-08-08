"use client";

import {Info} from "lucide-react";
import {
  TCF_NOTE_BANDS,
  canShowNiveau,
  objectifPresentation,
  shouldShowConfiance,
  tcfBandRange,
  tcfNiveauTone,
  tcfScalePosition,
} from "@/lib/production-feedback";
import {
  confianceLabel,
  formatNoteSur20,
  niveauCecrlLabel,
  niveauCecrlShort,
  type ConfianceEvaluation,
  type NiveauCecrl,
  type ObjectifAccomplissement,
} from "@/lib/types";
import styles from "./production.module.css";

const PORTEE_SUR_LA_TACHE =
  "Cette note est une estimation, exprimée sur l'échelle du TCF : c'est elle qui donne le " +
  "niveau. Elle porte ici sur cette seule tâche — au TCF, la note sur 20 est celle de " +
  "l'épreuve entière, vos trois tâches.";

const CONFIANCE_SANS_RAISON =
  "Une partie de votre production était difficile à analyser : cette note est à prendre avec " +
  "prudence.";

/**
 * En-tête du rapport : **le verdict, la note et le niveau dans UN SEUL bloc**.
 *
 * Avant, c'étaient trois cartes empilées (accusé « Production évaluée », bandeau
 * d'objectif, carte de note) qui disaient chacune une moitié de la même chose et
 * remplissaient un écran entier avant le premier conseil. Le candidat doit
 * pouvoir répondre à « c'est bien ou pas ? » sans faire défiler.
 *
 * Miroir strict du mobile (`results_hero.dart`) et de la maquette « Rapport
 * express » : dégradé de marque, halo clair en haut à droite, note à droite, et
 * panneau de niveau **translucide** posé dessus.
 *
 * Ce qui n'a pas bougé, parce que ce sont des règles et non de la mise en page :
 * - la note s'affiche AVEC l'échelle du TCF — sans elle, un 4,5/20 (un A2) se
 *   lit comme une catastrophe scolaire ;
 * - **le niveau ne s'affiche jamais sans sa confiance** ({@link canShowNiveau}) ;
 * - **une confiance HAUTE ne s'affiche pas** ({@link shouldShowConfiance}) :
 *   c'est le cas normal, l'écrire fait douter d'un résultat qui ne le mérite
 *   pas ;
 * - notre niveau est une **estimation** : « proche du niveau B1 », jamais « B1 »
 *   sec ;
 * - la portée de la note (`avertissementNiveau`, ou son repli) reste accessible
 *   en un geste — le panneau de niveau est un `<details>`.
 */
export function ProductionResultsHero({
  eyebrow,
  objectif,
  resume,
  noteSurVingt,
  niveau,
  confiance,
  avertissementNiveau,
  confianceRaisons,
}: {
  /** Situe la correction (« Expression écrite · Tâche 1 »). */
  eyebrow?: string | null;
  objectif: ObjectifAccomplissement | null;
  resume: string | null;
  noteSurVingt: number | null;
  niveau: NiveauCecrl | null;
  confiance: ConfianceEvaluation | null;
  avertissementNiveau: string | null;
  confianceRaisons: string[];
}) {
  const presentation = objectifPresentation(objectif);
  const showLevel = canShowNiveau(niveau, confiance);
  const showConfiance = shouldShowConfiance(confiance);
  const position = tcfScalePosition(noteSurVingt);

  return (
    <section className={styles.hero}>
      <span className={styles.heroHalo} aria-hidden />
      <div className={styles.heroTop}>
        <div className={styles.heroMain}>
          {eyebrow && <p className={styles.heroTag}>{eyebrow}</p>}
          {/* Aucune pastille d'icône devant le verdict : la maquette n'en a pas,
              et « Objectif non atteint » se lit en toutes lettres. */}
          <h2 className={styles.heroVerdict}>
            {presentation ? `Objectif ${presentation.label.toLowerCase()}` : "Votre correction"}
          </h2>
        </div>
        <p className={styles.heroScore}>
          {noteSurVingt != null ? formatNoteSur20(noteSurVingt) : "—"}
          <span className={styles.heroScoreOf}>/20</span>
        </p>
      </div>

      {resume && <p className={styles.heroResume}>{resume}</p>}

      <details className={styles.levelPanel}>
        <summary className={styles.levelSummary}>
          <span className={styles.levelRow}>
            <span className={styles.levelMain}>
              <span className={styles.levelEyebrow}>
                {showLevel ? "Niveau estimé" : "Note sur l'échelle du TCF"}
                <Info size={13} strokeWidth={2.4} aria-hidden />
              </span>
              {showLevel && niveau && (
                <span className={styles.levelValue}>
                  {niveau === "A1_NON_ATTEINT"
                    ? "Niveau A1 non atteint"
                    : `Proche du niveau ${niveauCecrlLabel(niveau)}`}
                </span>
              )}
            </span>
            {showLevel && niveau && (
              <span className={styles.levelPill} data-tone={tcfNiveauTone(niveau)}>
                {niveauCecrlShort(niveau)}
              </span>
            )}
          </span>

          <HeroScale activeIndex={position?.bandIndex ?? null} note={noteSurVingt} />

          {showConfiance && confiance && (
            <span className={styles.heroConfBox}>
              <span className={styles.heroConfLabel}>{confianceLabel(confiance)}</span>
              <span className={styles.heroConfWhy}>
                {confianceRaisons.length > 0
                  ? confianceRaisons.join(" · ")
                  : CONFIANCE_SANS_RAISON}
              </span>
            </span>
          )}
        </summary>

        <div className={styles.levelRule}>
          <p className={styles.levelRuleText}>{avertissementNiveau ?? PORTEE_SUR_LA_TACHE}</p>
          <ul className={styles.levelTable}>
            {TCF_NOTE_BANDS.map((band) => (
              <li key={band.niveau} className={styles.levelTableRow}>
                <span className={styles.levelTableRange} data-tone={tcfNiveauTone(band.niveau)}>
                  {tcfBandRange(band)}
                </span>
                <span className={styles.levelTableLabel}>{band.label}</span>
              </li>
            ))}
          </ul>
        </div>
      </details>
    </section>
  );
}

/**
 * L'échelle **sur le dégradé** : cinq segments à largeur égale et **une seule
 * ligne** de libellés (les paliers, pas leurs bornes chiffrées).
 *
 * Deux écarts assumés avec la version claire, pour la même raison — le fond :
 * les teintes de palier ne se voient plus sur du bleu, donc le segment atteint
 * passe en **blanc plein** et c'est la pastille (blanche, texte teinté) qui
 * porte la couleur ; et les bornes chiffrées, qui sont de la règle de lecture et
 * non du résultat, vivent dans le dépliant.
 */
function HeroScale({activeIndex, note}: {activeIndex: number | null; note: number | null}) {
  const activeBand = activeIndex != null ? TCF_NOTE_BANDS[activeIndex] : null;

  return (
    <span className={styles.heroScale}>
      <span
        className={styles.heroScaleTrack}
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
            className={styles.heroScaleSeg}
            data-active={i === activeIndex ? "" : undefined}
          />
        ))}
      </span>
      <span className={styles.heroScaleLabels} aria-hidden>
        {TCF_NOTE_BANDS.map((band, i) => (
          <span
            key={band.niveau}
            className={styles.heroScaleLabel}
            data-active={i === activeIndex ? "" : undefined}
          >
            {niveauCecrlShort(band.niveau)}
          </span>
        ))}
      </span>
    </span>
  );
}
