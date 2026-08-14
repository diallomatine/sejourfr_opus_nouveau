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
 * Intitulé de la carte de niveau. **Il nomme la production, pas le candidat** :
 * ce palier est celui de la réponse qui vient d'être rendue — quinze à trente
 * mots —, pas le niveau TCF de la personne, qui se mesure sur des épreuves
 * entières et vit sur le tableau de bord. « TON NIVEAU » laissait exactement
 * cette confusion possible, et c'est la lecture la plus décourageante : un A2
 * sur une phrase n'est pas un verdict sur soi.
 *
 * Miroir mot pour mot de `kSkillLevelCardEyebrow` côté mobile
 * (`competences/widgets/skill_level_card.dart`).
 */
const LEVEL_EYEBROW = "NIVEAU DE TA RÉPONSE";

/**
 * « Niveau de ta réponse » — la réponse à *où j'en suis*, en trois secondes.
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
      <span className={s.levelEyebrow}>{LEVEL_EYEBROW}</span>

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

      {/* Les deux puces sont indépendantes : chacune disparaît si son champ est
          absent. */}
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

      {/* Verdict vide (analyse dégradée) ⇒ pas de paragraphe fantôme sous les
          puces. Même garde que `SkillLevelCard` côté mobile. */}
      {verdict.trim().length > 0 && <p className={s.criterionVerdict}>{verdict}</p>}
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
  // Une échelle d'un seul cran ne situe rien : pas de jauge du tout, comme sur
  // mobile (`SkillLevelCard` : `progress.scale.length > 1`). Le contrat serveur
  // en promet trois — c'est un garde-fou de rendu, pas une règle.
  if (scale.length < 2) return null;

  // `last >= 1` garanti par la garde ci-dessus : plus de division par zéro à
  // couvrir ici.
  const last = scale.length - 1;
  const cursor = Math.min(Math.max(cursorIndex, 0), last);
  const percent = (cursor / last) * 100;

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
            style={{left: `${(i / last) * 100}%`}}
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
