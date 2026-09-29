"use client";

import {useId, useState} from "react";
import {ChevronDown, Lightbulb} from "lucide-react";
import {REFERENCES_OPEN_BY_DEFAULT} from "@/lib/skill-result-view";
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
 * **Repliées par défaut** (décision client, `REFERENCES_OPEN_BY_DEFAULT`) : le
 * candidat lit d'abord son propre retour, déplié juste au-dessus, et va se
 * comparer ensuite s'il le veut. Le dépliant est un vrai `<button>` —
 * `aria-expanded` + `aria-controls`, atteignable au clavier, focus visible —
 * et non un titre cliquable.
 *
 * On ouvre sur « Attendu » : c'est la cible, pas le contre-exemple.
 */
export function CompetenceReferences({
  references,
  defaultOpen = REFERENCES_OPEN_BY_DEFAULT,
}: {
  references: SkillReferenceDto[];
  /**
   * Ouvert d'emblée quand l'écran n'a pas d'analyse à montrer : les références
   * y sont le seul retour. Voir `referencesOpenByDefault`.
   */
  defaultOpen?: boolean;
}) {
  const byLevel = new Map(references.map((r) => [r.level, r]));
  const available = SKILL_REFERENCE_LEVELS.filter((l) => byLevel.has(l));
  const [level, setLevel] = useState<SkillReferenceLevel>("EXPECTED");
  const [open, setOpen] = useState(defaultOpen);
  const panelId = useId();

  if (available.length === 0) return null;

  const current = byLevel.get(level) ?? byLevel.get(available[0]);
  if (!current) return null;

  return (
    <section className={s.refSection}>
      <button
        type="button"
        className={s.refToggle}
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen((o) => !o)}
      >
        <span className={s.refToggleBody}>
          <span className={s.refToggleTitle}>Compare avec les niveaux de référence</span>
          <span className={s.refToggleHint}>
            Trois productions du même sujet : insuffisante, attendue, très réussie.
          </span>
        </span>
        {/* L'invite à ouvrir nomme le geste que la section propose — « Comparer »,
            pas « Afficher ». Miroir du `collapsedLabel` de `_SectionToggle` côté
            mobile ; le repli, lui, se dit « Masquer » des deux côtés. */}
        <span className={s.refToggleAction}>
          {open ? "Masquer" : "Comparer"}
          <ChevronDown
            size={15}
            strokeWidth={2.4}
            aria-hidden
            className={`${s.refChevron} ${open ? s.refChevronOpen : ""}`}
          />
        </span>
      </button>

      {open && (
        <div id={panelId} className={s.refPanel}>
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
              <Lightbulb
                size={14}
                strokeWidth={2}
                aria-hidden
                style={{flex: "none", marginTop: 2}}
              />
              <span>{current.pedagogicalNote}</span>
            </p>
          </div>
        </div>
      )}
    </section>
  );
}
