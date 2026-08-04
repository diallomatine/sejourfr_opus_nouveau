"use client";

import type {EpreuveType} from "@/lib/types";
import styles from "./production.module.css";

/**
 * Critères annoncés au candidat avant qu'il produise — miroir strict des
 * rubriques serveur (`prompts/production-rubrics-*.json`, documentées dans
 * `docs/notation-ia-eo-ee.md`). Ils changent d'une tâche à l'autre : une liste
 * unique promettait des critères qui n'existent dans aucune rubrique.
 *
 * Côté oral, ni l'aisance ni la prononciation n'y figurent : l'évaluation part
 * de la transcription et ne les entend pas. Les annoncer contredirait
 * l'avertissement affiché juste sous cette carte.
 */
const CRITERIA: Record<"TCF_EE" | "TCF_EO", Record<number, string[]>> = {
  TCF_EE: {
    1: [
      "Réalisation de la consigne",
      "Adéquation au destinataire et au registre",
      "Étendue et maîtrise du lexique",
      "Correction morphosyntaxique",
      "Clarté et enchaînement du message",
    ],
    2: [
      "Réalisation du récit ou du compte rendu",
      "Chronologie et repères temporels",
      "Cohérence et organisation",
      "Étendue et maîtrise du lexique",
      "Correction morphosyntaxique",
    ],
    3: [
      "Prise de position claire",
      "Justification et développement des arguments",
      "Organisation et connecteurs logiques",
      "Étendue et maîtrise du lexique",
      "Correction morphosyntaxique",
    ],
  },
  TCF_EO: {
    1: [
      "Réponse à la consigne et présentation de soi",
      "Développement des réponses",
      "Étendue et maîtrise du lexique",
      "Correction grammaticale perceptible",
      "Cohérence du propos",
    ],
    2: [
      "Conduite de l'échange et obtention des informations",
      "Adéquation à l'interlocuteur et au registre",
      "Étendue et maîtrise du lexique",
      "Correction grammaticale perceptible",
      "Cohérence des interventions",
    ],
    3: [
      "Point de vue clair et réponse à la question",
      "Développement des arguments et exemples",
      "Organisation du monologue",
      "Étendue et maîtrise du lexique",
      "Correction grammaticale perceptible",
    ],
  },
};

export function ProductionCriteriaCard({
  epreuve,
  tacheNumero,
}: {
  epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO">;
  tacheNumero: number;
}) {
  const items = CRITERIA[epreuve][tacheNumero] ?? CRITERIA[epreuve][1];
  return (
    <div className={styles.card}>
      <p className={styles.cardLabel}>Vous serez évalué sur</p>
      <ul className={styles.criteriaList}>
        {items.map((c) => (
          <li key={c} className={styles.criteriaItem}>
            <span className={styles.criteriaDot} />
            {c}
          </li>
        ))}
      </ul>
    </div>
  );
}
