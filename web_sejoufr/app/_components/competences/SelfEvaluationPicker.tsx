"use client";

import {
  SKILL_SELF_EVALUATION_LABEL,
  type SkillSelfEvaluation,
} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";

const CHOICES: readonly SkillSelfEvaluation[] = ["REUSSI", "INCERTAIN", "DIFFICILE"];

/**
 * Auto-évaluation facultative, remplie avant validation. Elle est **déclarative
 * et sans effet** : elle ne pèse ni sur le verdict de l'IA ni sur le statut du
 * sujet. C'est un miroir pour le candidat — comparer ce qu'il croyait avoir
 * réussi à ce que le correcteur constate, c'est l'essentiel de ce qu'on apprend
 * d'un micro-exercice.
 *
 * Un second clic sur le même choix le retire : rien n'oblige à se prononcer.
 */
export function SelfEvaluationPicker({
  value,
  disabled = false,
  onChange,
}: {
  value: SkillSelfEvaluation | null;
  disabled?: boolean;
  onChange: (next: SkillSelfEvaluation | null) => void;
}) {
  return (
    <div className={s.selfBlock}>
      <span className={s.selfLabel}>Auto-évaluation</span>
      <p className={s.selfHint}>
        Facultatif. Votre ressenti n&apos;influence pas la correction.
      </p>
      <div className={s.selfRow} role="group" aria-label="Auto-évaluation">
        {CHOICES.map((choice) => {
          const on = value === choice;
          return (
            <button
              key={choice}
              type="button"
              aria-pressed={on}
              disabled={disabled}
              className={`${s.selfBtn} ${on ? s.selfBtnOn : ""}`}
              onClick={() => onChange(on ? null : choice)}
            >
              {SKILL_SELF_EVALUATION_LABEL[choice]}
            </button>
          );
        })}
      </div>
    </div>
  );
}
