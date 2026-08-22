import {Check, Circle, RefreshCw, Sparkles} from "lucide-react";
import {SKILL_PROMPT_STATUS_LABEL, type SkillPromptStatus} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";

const TONE: Record<SkillPromptStatus, string> = {
  TODO: s.badgeTodo,
  TREATED: s.badgeTreated,
  VALIDATED: s.badgeValidated,
  TO_REINFORCE: s.badgeReinforce,
};

/**
 * Badge de statut d'un petit sujet. Les quatre statuts sont **visuellement
 * distincts** (règle UX §13.8) : couleur, icône et libellé changent ensemble,
 * pour que la distinction tienne aussi sans la couleur.
 *
 * Le libellé vient du contrat gelé — « Fait » (TREATED) dit exactement ce qui
 * s'est passé quand la production n'a pas été analysée : ni validée, ni ratée.
 */
export function CompetenceStatusBadge({status}: {status: SkillPromptStatus}) {
  return (
    <span className={`${s.badge} ${TONE[status]}`}>
      <StatusIcon status={status} />
      {SKILL_PROMPT_STATUS_LABEL[status]}
    </span>
  );
}

function StatusIcon({status}: {status: SkillPromptStatus}) {
  switch (status) {
    case "VALIDATED":
      return <Check size={12} strokeWidth={2.8} aria-hidden />;
    case "TO_REINFORCE":
      return <RefreshCw size={11} strokeWidth={2.4} aria-hidden />;
    case "TREATED":
      return <Sparkles size={11} strokeWidth={2.2} aria-hidden />;
    case "TODO":
      return <Circle size={9} strokeWidth={2.6} aria-hidden />;
  }
}
