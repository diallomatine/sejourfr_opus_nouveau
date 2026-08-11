"use client";

import {Check, Target, TrendingUp} from "lucide-react";
import {
  niveauCecrlShort,
  SKILL_CRITERION_STATUS_LABEL,
  type NiveauCecrl,
  type SkillCriterionStatus,
  type SkillLevelProgressDto,
} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";

/** Teinte de la pastille de statut du critère — même code couleur que
 *  `CompetenceStatusBadge` / `VerdictCard` : vert validé, ambre partiel, rouge
 *  non atteint (un critère, pas un palier CECRL, donc le rouge y est permis). */
const CRITERION_STATUS_TONE: Record<SkillCriterionStatus, string> = {
  VALIDATED: s.statusValidated,
  PARTIAL: s.statusPartial,
  NOT_VALIDATED: s.statusNot,
};

/**
 * « TON NIVEAU » — la réponse à *où j'en suis*, en trois secondes.
 *
 * **Rien n'est calculé ici.** Le niveau démontré, le palier visé, la phrase de
 * situation, les trois crans de la jauge et la position du curseur viennent tous
 * du serveur (`SkillLevelProgressResolver`). Un front qui redériverait l'un
 * d'eux réintroduirait la table de correspondance CECRL ⇄ démarche qui a déjà
 * vécu en six copies divergentes dans ce dépôt.
 *
 * `situationLabel` est rendu **tel quel** : il est gelé côté serveur, et le
 * recomposer depuis `situation` est exactement la façon dont les libellés du
 * module avaient décroché entre le web et le mobile.
 *
 * Les deux puces du bas sont indépendantes : chacune disparaît si son champ est
 * absent (analyse ancienne, ou étiquette non produite).
 *
 * **Le verdict du critère unique** (`status` + `verdict`) est réintroduit ici,
 * sous forme compacte : une pastille sur la rangée du haut, et le texte en une
 * ligne sous les puces — sans carte ni intertitre séparés. Le critère unique
 * est la raison d'être du sujet ; le taire sur un « Critère non atteint »
 * laissait l'écran muet sur l'essentiel.
 */
export function CompetenceLevelCard({
  progress,
  strengthTag,
  focusTag,
  criterionStatus,
  verdict,
}: {
  progress: SkillLevelProgressDto;
  strengthTag: string | null;
  focusTag: string | null;
  criterionStatus: SkillCriterionStatus;
  verdict: string;
}) {
  const atteint = progress.situation === "OBJECTIF_ATTEINT";

  return (
    <section className={s.levelCard}>
      <span className={s.levelEyebrow}>TON NIVEAU</span>

      <div className={s.levelTop}>
        <strong className={s.levelBig}>{niveauCecrlShort(progress.levelReached)}</strong>
        <span className={s.levelGoal}>Objectif {progress.targetLevel}</span>
        <span className={`${s.status} ${CRITERION_STATUS_TONE[criterionStatus]}`}>
          {criterionStatus === "VALIDATED" ? (
            <Check size={12} strokeWidth={2.8} aria-hidden />
          ) : (
            <Target size={11} strokeWidth={2.4} aria-hidden />
          )}
          {SKILL_CRITERION_STATUS_LABEL[criterionStatus]}
        </span>
      </div>

      <p className={`${s.levelSituation} ${atteint ? s.levelSituationDone : ""}`}>
        <span className={s.levelSituationIcon} aria-hidden>
          {atteint ? (
            <Check size={14} strokeWidth={2.8} />
          ) : (
            <TrendingUp size={14} strokeWidth={2.4} />
          )}
        </span>
        {progress.situationLabel}
      </p>

      <LevelGauge scale={progress.scale} cursorIndex={progress.cursorIndex} />

      {(strengthTag || focusTag) && (
        <div className={s.tagRow}>
          {strengthTag && (
            <span className={`${s.tag} ${s.tagGood}`}>
              <Check size={12} strokeWidth={2.8} aria-hidden />
              {strengthTag}
            </span>
          )}
          {focusTag && (
            <span className={`${s.tag} ${s.tagFocus}`}>
              <Target size={12} strokeWidth={2.4} aria-hidden />
              {focusTag}
            </span>
          )}
        </div>
      )}

      <p className={s.criterionVerdict}>{verdict}</p>
    </section>
  );
}

/**
 * Jauge à trois crans étiquetés : trait rempli jusqu'au curseur, point marqué
 * sur le cran courant, crans suivants en gris.
 *
 * L'échelle et l'index arrivent **prêts à l'emploi**. Le seul ajustement fait
 * ici est un garde-fou de rendu (borne d'index, division par zéro sur une
 * échelle dégénérée) : il protège l'affichage, il ne recalcule aucune position
 * et ne réordonne rien.
 */
function LevelGauge({scale, cursorIndex}: {scale: NiveauCecrl[]; cursorIndex: number}) {
  if (scale.length === 0) return null;

  const last = scale.length - 1;
  const cursor = Math.min(Math.max(cursorIndex, 0), last);
  const percent = last === 0 ? 100 : (cursor / last) * 100;

  return (
    <div className={s.gauge}>
      <div className={s.gaugeRail} aria-hidden>
        <span className={s.gaugeFill} style={{width: `${percent}%`}} />
        {scale.map((level, i) => (
          <span
            key={`${level}-${i}`}
            className={`${s.gaugeDot} ${i <= cursor ? s.gaugeDotOn : ""} ${
              i === cursor ? s.gaugeDotNow : ""
            }`}
            style={{left: last === 0 ? "100%" : `${(i / last) * 100}%`}}
          />
        ))}
      </div>
      <div className={s.gaugeLabels}>
        {scale.map((level, i) => (
          <span
            key={`${level}-${i}`}
            className={`${s.gaugeLabel} ${i <= cursor ? s.gaugeLabelOn : ""}`}
          >
            {niveauCecrlShort(level)}
          </span>
        ))}
      </div>
    </div>
  );
}
