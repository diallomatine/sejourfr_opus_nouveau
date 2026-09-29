"use client";

import {Info} from "lucide-react";
import {
  NIVEAU_PORTEE_TACHE,
  TCF_NOTE_BANDS,
  canShowNiveau,
  demarcheRappel,
  niveauAtteintLabel,
  objectifPresentation,
  shouldShowConfiance,
  tcfNiveauTone,
  tcfPalierIndex,
  type SituationView,
} from "@/lib/production-feedback";
import {
  confianceLabel,
  niveauCecrlShort,
  type ConfianceEvaluation,
  type NiveauCecrl,
  type ObjectifAccomplissement,
  type TargetLevel,
} from "@/lib/types";
import styles from "./production.module.css";

const CONFIANCE_SANS_RAISON =
  "Une partie de votre production était difficile à analyser : ce niveau est à prendre avec " +
  "prudence.";

/**
 * En-tête du rapport : **le verdict et le niveau dans UN SEUL bloc**.
 *
 * Avant, c'étaient trois cartes empilées (accusé « Production évaluée », bandeau
 * d'objectif, carte de note) qui disaient chacune une moitié de la même chose et
 * remplissaient un écran entier avant le premier conseil. Le candidat doit
 * pouvoir répondre à « c'est bien ou pas ? » sans faire défiler.
 *
 * Miroir strict du mobile (`results_hero.dart`).
 *
 * **La note /20 a disparu du résultat d'une tâche** (décision produit du
 * 2026-08-08) : au TCF, un correcteur attribue **un niveau par tâche**, jamais
 * une note — le /20 ne porte que sur l'épreuve entière (3 tâches). Et comme
 * 10/20 y vaut déjà B2, un A2 normal s'affichait « 3,5/20 », qu'un francophone
 * lit comme une catastrophe scolaire. Le **niveau** est donc le héros de la
 * carte, et la note reste là où elle a un sens : les bilans d'épreuve et
 * d'examen complet. Corollaire assumé : les bornes chiffrées du barème
 * (« 2-5 → A2 ») ne sont plus affichées nulle part ici.
 *
 * Ce qui n'a pas bougé, parce que ce sont des règles et non de la mise en page :
 * - **le niveau ne s'affiche jamais sans sa confiance** ({@link canShowNiveau}) ;
 * - **une confiance HAUTE ne s'affiche pas** ({@link shouldShowConfiance}) :
 *   c'est le cas normal, l'écrire fait douter d'un résultat qui ne le mérite
 *   pas ;
 * - la portée du niveau (`avertissementNiveau`, ou {@link NIVEAU_PORTEE_TACHE})
 *   reste accessible en un geste — le panneau de niveau est un `<details>`.
 */
export function ProductionResultsHero({
  eyebrow,
  objectif,
  resume,
  niveau,
  confiance,
  avertissementNiveau,
  confianceRaisons,
  situation,
  targetLevel,
}: {
  /** Situe la correction (« Expression écrite · Tâche 1 »). */
  eyebrow?: string | null;
  objectif: ObjectifAccomplissement | null;
  resume: string | null;
  niveau: NiveauCecrl | null;
  confiance: ConfianceEvaluation | null;
  avertissementNiveau: string | null;
  confianceRaisons: string[];
  /** Cran de progression **dans** le palier (« Palier solide »). `null` = rien
   *  à situer : la pastille disparaît, sans placeholder. */
  situation?: SituationView | null;
  /** Palier visé par la démarche du candidat. `null` = inconnu : on n'affiche
   *  alors aucun rappel plutôt qu'un message générique. */
  targetLevel: TargetLevel | null;
}) {
  const presentation = objectifPresentation(objectif);
  const showLevel = canShowNiveau(niveau, confiance);
  const showConfiance = shouldShowConfiance(confiance);
  const rappel = showLevel ? demarcheRappel(targetLevel, niveau) : null;

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
      </div>

      {resume && <p className={styles.heroResume}>{resume}</p>}

      <details className={styles.levelPanel}>
        <summary className={styles.levelSummary}>
          <span className={styles.levelRow}>
            <span className={styles.levelMain}>
              <span className={styles.levelEyebrow}>
                Niveau estimé
                <Info size={13} strokeWidth={2.4} aria-hidden />
              </span>
              <span className={styles.levelValue}>
                {showLevel && niveau
                  ? niveauAtteintLabel(niveau)
                  : "Niveau indisponible pour cette production"}
              </span>
              {/* Le cran DANS le palier : c'est lui qui remplace la note
                  disparue, sans chiffre et sans vocabulaire de manque. Il
                  nuance le niveau, il ne le remplace pas — d'où la discrétion. */}
              {showLevel && situation && (
                <span className={styles.levelSituation}>{situation.libelleAvecNiveau}</span>
              )}
            </span>
            {showLevel && niveau && (
              <span className={styles.levelPill} data-tone={tcfNiveauTone(niveau)}>
                {niveauCecrlShort(niveau)}
              </span>
            )}
          </span>

          {showLevel && niveau && <HeroScale niveau={niveau} />}

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
          <p className={styles.levelRuleText}>{avertissementNiveau ?? NIVEAU_PORTEE_TACHE}</p>
        </div>
      </details>

      {/* Le rappel d'enjeu : un A2 qui vise la carte de séjour pluriannuelle EST
          au niveau demandé, et personne ne le lui disait. */}
      {rappel && (
        <p className={styles.heroStake} data-reached={rappel.atteint ? "" : undefined}>
          <span className={styles.heroStakeLabel}>Votre démarche</span>
          <span className={styles.heroStakeText}>{rappel.text}</span>
        </p>
      )}
    </section>
  );
}

/**
 * Les cinq paliers du TCF **sur le dégradé**, celui du candidat mis en avant.
 *
 * C'était l'échelle des notes, curseur compris ; elle situe désormais un
 * **niveau**, la seule chose que le résultat d'une tâche annonce. Les teintes de
 * palier ne se voient pas sur du bleu : le segment atteint passe en blanc plein,
 * et c'est la pastille (blanche, texte teinté) qui porte la couleur.
 */
function HeroScale({niveau}: {niveau: NiveauCecrl}) {
  const activeIndex = tcfPalierIndex(niveau);

  return (
    <span className={styles.heroScale}>
      <span
        className={styles.heroScaleTrack}
        role="img"
        aria-label={`Votre production se situe au palier ${niveauCecrlShort(niveau)} de l'échelle du TCF.`}
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
