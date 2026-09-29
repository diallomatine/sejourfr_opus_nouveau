"use client";

import {
  PRODUCTION_CRITERIA,
  PRODUCTION_CRITERIA_FOOT,
  PRODUCTION_INFO_CRITERIA_LABEL,
} from "@/lib/production-exam-copy";
import styles from "./production.module.css";

/**
 * Critères annoncés au candidat avant qu'il produise. La liste et ses phrases
 * vivent dans `lib/production-exam-copy.ts` (miroir mobile
 * `production_exam_copy.dart`) : la même copie sert la feuille « ⓘ » du runner
 * d'examen blanc, qui ne la déroule plus en bloc.
 */
export function ProductionCriteriaCard() {
  return (
    <div className={styles.card}>
      <p className={styles.cardLabel}>{PRODUCTION_INFO_CRITERIA_LABEL}</p>
      <ProductionCriteriaList />
    </div>
  );
}

/** La liste des quatre critères et sa note, sans carte autour. */
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
