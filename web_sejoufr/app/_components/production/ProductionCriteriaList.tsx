"use client";

import {
  PRODUCTION_CRITERIA,
  PRODUCTION_CRITERIA_FOOT,
} from "@/lib/production-exam-copy";
import styles from "./production.module.css";

/**
 * Les quatre critères de notre grille et leur note, lus dans la feuille « ⓘ »
 * du runner (copie : `lib/production-exam-copy.ts`, miroir mobile
 * `production_exam_copy.dart`). Ils ne sont plus déroulés sur la page d'un sujet.
 */
export function ProductionCriteriaList() {
  return (
    <>
      <ul className={styles.criteriaList}>
        {PRODUCTION_CRITERIA.map((c) => (
          <li key={c.label} className={styles.criteriaItem}>
            <span className={styles.criteriaDot} />
            <span>
              <strong>{c.label}</strong> — {c.hint}
            </span>
          </li>
        ))}
      </ul>
      <p className={styles.criteriaFoot}>{PRODUCTION_CRITERIA_FOOT}</p>
    </>
  );
}
