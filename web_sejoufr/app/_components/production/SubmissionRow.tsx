"use client";

import {ChevronRight} from "lucide-react";
import {
  type EpreuveType,
  formatNoteSur20,
  productionTaskTitle,
  type ProductionSubmissionDto,
} from "@/lib/types";
import styles from "./production.module.css";

/**
 * Ligne d'une soumission de production (EE/EO) : numéro de tâche, titre (selon
 * l'épreuve), état (note si évaluée, sinon « en cours » / « échouée »). Pas de
 * niveau CECRL par tâche. Partagée entre les hubs et les historiques.
 */
export function SubmissionRow({
  submission: s,
  epreuve,
  onClick,
}: {
  submission: ProductionSubmissionDto;
  epreuve: EpreuveType;
  onClick: () => void;
}) {
  const note = s.evaluation?.noteSurVingt;
  const pending = s.statut !== "EVALUATED" && s.statut !== "FAILED";
  const sub =
    s.statut === "FAILED"
      ? "Évaluation échouée — relancer"
      : pending
        ? "Évaluation en cours…"
        : formatDay(s.submittedAt);

  const toneClass =
    s.tacheNumero === 1
      ? styles.rowChipT1
      : s.tacheNumero === 2
        ? styles.rowChipT2
        : s.tacheNumero === 3
          ? styles.rowChipT3
          : "";

  return (
    <button type="button" className={styles.row} onClick={onClick}>
      <span className={`${styles.rowChip} ${toneClass}`}>T{s.tacheNumero ?? "?"}</span>
      <span className={styles.rowBody}>
        <span className={styles.rowTitle}>{productionTaskTitle(epreuve, s.tacheNumero ?? 0)}</span>
        <span className={styles.rowSub}>{sub}</span>
      </span>
      {note != null && s.statut === "EVALUATED" ? (
        <span
          className={styles.rowScore}
          style={{background: "var(--color-blue-soft)", color: "var(--color-blue)"}}
        >
          {formatNoteSur20(note)}/20
        </span>
      ) : null}
      <ChevronRight size={20} className={styles.rowChevron} />
    </button>
  );
}


function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short"});
}
