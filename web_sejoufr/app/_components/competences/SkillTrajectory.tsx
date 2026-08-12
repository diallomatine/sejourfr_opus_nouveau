"use client";

import {LEARNING_PLAN_SOURCE_LABEL} from "@/lib/diagnostic";
import type {SkillObservationPointDto} from "@/lib/types";
import {LearningPlanStatusPill, SectionHead} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * La frise d'une compétence : ce qui a été constaté, quand, et dans quoi —
 * **du plus ancien au plus récent**, le sens dans lequel un parcours se lit.
 * L'ordre vient du serveur, il n'est pas retrié ici.
 *
 * Ce que cette frise apprend au candidat, aucun pourcentage ne le dirait :
 * « Diagnostic : prioritaire → Entraînement ciblé : à renforcer → Production
 * complète : solide ». L'état agrégé qu'elle produit, lui, est la pastille de
 * maîtrise portée par la carte de la compétence.
 *
 * **Trajectoire vide ⇒ aucune section**, pas d'encart d'excuse : une compétence
 * jamais observée n'a rien à raconter, et le dire n'aiderait personne.
 *
 * `confidence` n'est **jamais** affichée : c'est la certitude du correcteur, pas
 * une information sur le niveau du candidat.
 */
export function SkillTrajectory({points}: {points: SkillObservationPointDto[]}) {
  if (points.length === 0) return null;
  return (
    <section aria-labelledby="trajectory-title">
      <SectionHead
        title="Ton parcours sur cette compétence"
        text="Ce que tes productions ont montré, dans l'ordre."
        titleId="trajectory-title"
      />
      <ol className={s.traj}>
        {points.map((point, index) => (
          <li className={s.trajRow} key={`${point.observedAt}-${index}`}>
            <span className={s.trajMark} aria-hidden />
            <div className={s.trajBody}>
              <div className={s.trajHead}>
                <span className={s.trajSource}>{LEARNING_PLAN_SOURCE_LABEL[point.source]}</span>
                <LearningPlanStatusPill status={point.status} />
                <span className={s.trajDate}>{trajectoryDate(point.observedAt)}</span>
              </div>
              {point.explanation && <p className={s.trajWhy}>{point.explanation}</p>}
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}

/** Date courte d'une observation (« 4 août 2026 »). Une date illisible ne
 *  s'affiche pas : la ligne garde sa source et son verdict. */
function trajectoryDate(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleDateString("fr-FR", {day: "numeric", month: "long", year: "numeric"});
}
