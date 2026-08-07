"use client";

import styles from "./production.module.css";

/**
 * Critères annoncés au candidat avant qu'il produise — miroir strict de la
 * grille serveur (`prompts/production-rubrics-*.json`, documentée dans
 * `docs/notation-ia-eo-ee.md`). Ce sont les QUATRE critères de **notre grille
 * SejourFR**, à poids égaux, identiques sur les six tâches : ce qui change
 * d'une tâche à l'autre, ce sont les attentes derrière chaque critère, pas leur
 * liste.
 *
 * ⚠️ Ne pas les présenter comme « les critères du TCF » : France Éducation
 * international publie ses critères en trois familles (linguistiques,
 * pragmatiques, sociolinguistiques) et fait corriger par plusieurs évaluateurs
 * humains. Nos quatre critères **couvrent** ces dimensions ; ils ne
 * reproduisent pas la grille de correction officielle.
 *
 * Côté oral, ni l'aisance ni la prononciation n'y figurent : l'évaluation part
 * de la transcription et ne les entend pas. Les annoncer contredirait
 * l'avertissement affiché juste sous cette carte.
 */
const CRITERIA: readonly {label: string; hint: string}[] = [
  {
    label: "Communiquer",
    hint: "accomplir ce que demande la consigne et enchaîner ses idées",
  },
  {
    label: "Interagir",
    hint: "s'adapter à la situation et à la personne à qui l'on s'adresse",
  },
  {label: "Lexique", hint: "un vocabulaire approprié et précis"},
  {label: "Morphosyntaxe", hint: "la correction grammaticale"},
];

export function ProductionCriteriaCard() {
  return (
    <div className={styles.card}>
      <p className={styles.cardLabel}>Vous serez évalué sur</p>
      <ul className={styles.criteriaList}>
        {CRITERIA.map((c) => (
          <li key={c.label} className={styles.criteriaItem}>
            <span className={styles.criteriaDot} />
            <span>
              <strong>{c.label}</strong> — {c.hint}
            </span>
          </li>
        ))}
      </ul>
      <p className={styles.criteriaFoot}>
        Les quatre critères de notre grille, qui comptent autant l&apos;un que
        l&apos;autre. Ils couvrent les dimensions évaluées au TCF — linguistique,
        pragmatique, sociolinguistique — sans reprendre la grille de correction
        officielle. Ce sont les attentes derrière chacun qui montent d&apos;une
        tâche à la suivante.
      </p>
    </div>
  );
}
