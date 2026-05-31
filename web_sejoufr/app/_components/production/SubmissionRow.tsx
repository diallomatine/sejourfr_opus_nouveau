"use client";

import {ChevronRight} from "lucide-react";
import {eeTaskTitle, niveauCecrlLabel, type ProductionSubmissionDto} from "@/lib/types";
import styles from "./production.module.css";

/**
 * Ligne d'une soumission EE (historique / hub) : numéro de tâche, titre, état
 * (note + niveau si évaluée, sinon « en cours » / « échouée »). Partagée entre
 * le hub EE et l'historique.
 */
export function SubmissionRow({
  submission: s,
  onClick,
}: {
  submission: ProductionSubmissionDto;
  onClick: () => void;
}) {
  const note = s.evaluation?.noteSurVingt;
  const pending = s.statut !== "EVALUATED" && s.statut !== "FAILED";
  const sub =
    s.statut === "FAILED"
      ? "Évaluation échouée — relancer"
      : pending
        ? "Évaluation en cours…"
        : `${niveauCecrlLabel(s.evaluation?.niveauCecrl)} · ${formatDay(s.submittedAt)}`;

  return (
    <button type="button" className={styles.row} onClick={onClick}>
      <span className={styles.rowChip}>T{s.tacheNumero ?? "?"}</span>
      <span className={styles.rowBody}>
        <span className={styles.rowTitle}>{eeTaskTitle(s.tacheNumero ?? 0)}</span>
        <span className={styles.rowSub}>{sub}</span>
      </span>
      {note != null && s.statut === "EVALUATED" ? (
        <span
          className={styles.rowScore}
          style={{background: "var(--color-blue-soft)", color: "var(--color-blue)"}}
        >
          {formatNote(note)}/20
        </span>
      ) : null}
      <ChevronRight size={20} className={styles.rowChevron} />
    </button>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short"});
}
