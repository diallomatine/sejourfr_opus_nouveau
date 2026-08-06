"use client";

import {useState} from "react";
import {Lightbulb} from "lucide-react";
import {
  SKILL_REFERENCE_LEVEL_LABEL,
  SKILL_REFERENCE_LEVELS,
  type SkillReferenceDto,
  type SkillReferenceLevel,
} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * Code couleur de l'onglet actif, porteur de sens et **identique au mobile** :
 * rouge pour l'insuffisant, vert pour l'attendu, bleu pour le très réussi.
 * Trois pilules neutres obligeaient à relire le libellé pour savoir où l'on est.
 */
const TAB_TONE: Record<SkillReferenceLevel, string> = {
  INSUFFICIENT: s.refTabInsufficient,
  EXPECTED: s.refTabExpected,
  EXCELLENT: s.refTabExcellent,
};

/**
 * Les trois productions de référence d'un petit sujet, en onglets
 * `Insuffisant | Attendu | Très réussi`.
 *
 * Elles n'apparaissent **jamais avant d'avoir produit** (règle UX §13.2, doublée
 * d'un garde serveur qui répond 403 tant qu'aucune tentative n'existe) : lues
 * trop tôt, elles ne sont plus des repères mais un modèle à recopier.
 *
 * On ouvre sur « Attendu » : c'est la cible, pas le contre-exemple.
 */
export function CompetenceReferences({references}: {references: SkillReferenceDto[]}) {
  const byLevel = new Map(references.map((r) => [r.level, r]));
  const available = SKILL_REFERENCE_LEVELS.filter((l) => byLevel.has(l));
  const [level, setLevel] = useState<SkillReferenceLevel>("EXPECTED");

  if (available.length === 0) return null;

  const current = byLevel.get(level) ?? byLevel.get(available[0]);
  if (!current) return null;

  return (
    <section>
      <h2 className={s.resultSectionTitle}>Comparez avec les niveaux de référence</h2>
      <div className={s.refTabs} role="tablist" aria-label="Niveau de référence">
        {available.map((l) => {
          const on = current.level === l;
          return (
            <button
              key={l}
              type="button"
              role="tab"
              aria-selected={on}
              className={`${s.refTab} ${on ? TAB_TONE[l] : ""}`}
              onClick={() => setLevel(l)}
            >
              {SKILL_REFERENCE_LEVEL_LABEL[l]}
            </button>
          );
        })}
      </div>
      <div className={s.refBox}>
        <span className={s.answerLabel}>{SKILL_REFERENCE_LEVEL_LABEL[current.level]}</span>
        <p className={s.prodText}>{current.text}</p>
        <p className={s.refNote}>
          <Lightbulb size={14} strokeWidth={2} aria-hidden style={{flex: "none", marginTop: 2}} />
          <span>{current.pedagogicalNote}</span>
        </p>
      </div>
    </section>
  );
}
