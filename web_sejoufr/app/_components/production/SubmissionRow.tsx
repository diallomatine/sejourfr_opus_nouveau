"use client";

import {
  type EpreuveType,
  formatNoteSur20,
  productionTaskTitle,
  type ProductionSubmissionDto,
} from "@/lib/types";
import {
  RowChevron,
  SkillBadge,
  SkillRowCard,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * Ligne d'une soumission de production (EE/EO) : numéro de tâche, titre (selon
 * l'épreuve), état (note si évaluée, sinon « en cours » / « échouée »). Pas de
 * niveau CECRL par tâche. Partagée entre le hub et l'historique — c'est la même
 * carte que celles des sujets, à la géométrie de la maquette.
 */
export function SubmissionRow({
  submission: sub,
  epreuve,
  onClick,
}: {
  submission: ProductionSubmissionDto;
  epreuve: EpreuveType;
  onClick: () => void;
}) {
  const note = sub.evaluation?.noteSurVingt;
  const evaluated = sub.statut === "EVALUATED";
  const pending = !evaluated && sub.statut !== "FAILED";
  const text =
    sub.statut === "FAILED"
      ? "Évaluation échouée — relancer"
      : pending
        ? "Évaluation en cours…"
        : formatDay(sub.submittedAt);

  return (
    <SkillRowCard
      tile={`T${sub.tacheNumero ?? "?"}`}
      tileDone={evaluated}
      mark={evaluated ? "done" : "none"}
      title={productionTaskTitle(epreuve, sub.tacheNumero ?? 0)}
      text={text}
      aside={
        note != null && evaluated ? (
          <span className={s.rowAside}>
            <SkillBadge tone="treated">{formatNoteSur20(note)}/20</SkillBadge>
            <RowChevron />
          </span>
        ) : undefined
      }
      onClick={onClick}
    />
  );
}

function formatDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("fr-FR", {day: "2-digit", month: "short"});
}
