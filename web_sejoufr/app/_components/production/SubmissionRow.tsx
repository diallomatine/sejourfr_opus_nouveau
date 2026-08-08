"use client";

import {
  type EpreuveType,
  productionTaskTitle,
  type ProductionSubmissionDto,
} from "@/lib/types";
import {
  TACHE_EVALUEE_LABEL,
  tacheNiveau,
  tacheNiveauLabel,
} from "@/lib/production-feedback";
import {
  RowChevron,
  SkillBadge,
  SkillRowCard,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * Ligne d'une soumission de production (EE/EO) : numéro de tâche, titre (selon
 * l'épreuve), état (**niveau** si évaluée, sinon « en cours » / « échouée »).
 * Partagée entre le hub et l'historique — c'est la même carte que celles des
 * sujets, à la géométrie de la maquette.
 *
 * Le badge portait la note /20 : une soumission, c'est UNE tâche, et le TCF n'y
 * attache pas de note (décision produit du 2026-08-08). Il porte donc le palier
 * observé sur cette tâche.
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
  const niveau = tacheNiveau(sub.evaluation);
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
        <span className={s.rowAside}>
          {/* Évaluée sans niveau affichable (éval antérieure au contrat v4) :
              on écrit « Évaluée », on ne laisse pas le vide — même repli que
              le détail par tâche du bilan et que le badge d'un sujet traité.
              Et le chevron ne dépend pas du badge : la ligne est cliquable
              dans tous les cas (parité `HistorySessionCard` mobile), le
              retirer donnait une ligne qui ne semblait mener nulle part. */}
          {evaluated && (
            <SkillBadge tone="treated">
              {niveau ? tacheNiveauLabel(niveau) : TACHE_EVALUEE_LABEL}
            </SkillBadge>
          )}
          <RowChevron />
        </span>
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
