"use client";

import {Check, Sparkles, Target, TrendingUp} from "lucide-react";
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
 *  non atteint (un critère, pas un palier CECRL, donc le rouge y est permis).
 *  La pastille est à fond blanc : elle se lit aussi bien sur le bandeau sombre
 *  que sur une carte claire, sans seconde palette. */
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
 * Mention d'estimation, en pied du bandeau.
 *
 * Ce n'est pas une décoration reprise de la maquette : le dépôt **bannit** toute
 * formulation qui laisserait croire que notre palier reproduit la note du TCF
 * (« votre note officielle serait », « notre grille est celle du vrai examen »).
 * Le bandeau affiche un palier en très grand ; il doit dire dans la même carte
 * ce que ce palier est — une estimation d'entraînement.
 */
const ESTIMATION_NOTE =
  "Estimation d'entraînement SejourFR, sur cette seule réponse. Ce n'est pas une note officielle.";

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
 * **Bandeau sombre depuis la refonte maquette** (`WResultat`) : deux paliers en
 * très grand côte à côte — celui qu'on vient de démontrer, celui qu'on vise —,
 * la phrase de situation, la jauge à trois crans ; puis un pied clair qui porte
 * les deux étiquettes, le verdict du critère et la mention d'estimation. Aucune
 * donnée n'a changé de source : c'est la même carte, à l'échelle d'un écran de
 * bureau.
 *
 * Les deux puces du pied sont indépendantes : chacune disparaît si son champ est
 * absent (analyse ancienne, ou étiquette non produite).
 *
 * **Le verdict du critère unique** (`status` + `verdict`) reste ici : une
 * pastille sur la rangée des paliers, et le texte en une ligne dans le pied.
 * Le critère unique est la raison d'être du sujet ; le taire sur un « Critère
 * non atteint » laissait l'écran muet sur l'essentiel.
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
    <section className={s.analysisHero}>
      <div className={s.analysisHeroTop}>
        <span className={s.analysisEyebrow}>
          <Sparkles size={13} strokeWidth={2.4} aria-hidden />
          {LEVEL_EYEBROW}
        </span>

        <div className={s.analysisFigures}>
          <div className={s.analysisFigure}>
            <strong className={s.analysisFigureValue}>
              {niveauCecrlShort(progress.levelReached)}
            </strong>
          </div>
          <div className={`${s.analysisFigure} ${s.analysisFigureGoal}`}>
            <span className={s.analysisFigureLabel}>Objectif</span>
            <strong className={s.analysisFigureValue}>{progress.targetLevel}</strong>
          </div>
          <span
            className={`${s.status} ${CRITERION_STATUS_TONE[criterionStatus]} ${s.analysisStatus}`}
          >
            {criterionStatus === "VALIDATED" ? (
              <Check size={12} strokeWidth={2.8} aria-hidden />
            ) : (
              <Target size={11} strokeWidth={2.4} aria-hidden />
            )}
            {SKILL_CRITERION_STATUS_LABEL[criterionStatus]}
          </span>
        </div>

        <p className={s.analysisPhrase}>
          <span className={s.analysisPhraseIcon} aria-hidden>
            {atteint ? (
              <Check size={14} strokeWidth={2.8} />
            ) : (
              <TrendingUp size={14} strokeWidth={2.4} />
            )}
          </span>
          {progress.situationLabel}
        </p>

        <LevelGauge scale={progress.scale} cursorIndex={progress.cursorIndex} />
      </div>

      <div className={s.analysisFoot}>
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

        <p className={s.analysisNote}>{ESTIMATION_NOTE}</p>
      </div>
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
