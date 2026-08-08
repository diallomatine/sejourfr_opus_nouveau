"use client";

import {AlertTriangle, Check, ChevronDown, Info, Lightbulb, Target} from "lucide-react";
import {
  groupAccomplishment,
  hasAccomplishmentDetail,
  type AccomplishmentGroups,
} from "@/lib/production-feedback";
import {
  type EeAccomplishment,
  type EeAccomplishmentPoint,
  type EeCorrection,
} from "@/lib/types";
import {FeedbackList} from "./FeedbackList";
import styles from "./production.module.css";

/**
 * L'expertise, **repliée**. Tout ce que l'évaluation contient encore une fois
 * qu'on a servi au candidat ce qui l'aide immédiatement : les limites de
 * l'analyse, le détail par critère avec sa citation, la check-list de la
 * consigne, les corrections et les suggestions.
 *
 * Rien n'est perdu — c'est la contrepartie du haut d'écran court. L'ordre est
 * identique au mobile : avertissements → accomplissement → exemples corrigés →
 * suggestions. **Le détail par critère a quitté ce repli** pour la section
 * « Votre profil en un coup d'œil » ({@link CriteriaOverview}) : il y était, donc
 * personne ne le voyait.
 */
export function ProductionFullAnalysis({
  avertissements,
  accomplissement,
  exemplesCorriges,
  suggestions,
  isOral,
}: {
  avertissements: string[];
  accomplissement: EeAccomplishment | null;
  exemplesCorriges: EeCorrection[];
  suggestions: string[];
  isOral: boolean;
}) {
  const groups = groupAccomplishment(accomplissement);
  const hasAccomplishment = hasAccomplishmentDetail(groups);
  const hasSomething =
    avertissements.length > 0 ||
    hasAccomplishment ||
    exemplesCorriges.length > 0 ||
    suggestions.length > 0;

  if (!hasSomething) return null;

  return (
    <details className={styles.details}>
      <summary className={styles.detailsSummary}>
        <span className={styles.detailsSummaryText}>
          <span className={styles.detailsSummaryTitle}>Voir l&apos;analyse complète</span>
          <span className={styles.detailsSummaryHint}>
            Consigne point par point, corrections et suggestions.
          </span>
        </span>
        <ChevronDown className={styles.detailsChevron} size={18} strokeWidth={2.4} aria-hidden />
      </summary>

      <div className={styles.detailsBody}>
        {avertissements.length > 0 && (
          <section className={styles.limitsBox}>
            <p className={styles.limitsTitle}>
              <Info size={16} strokeWidth={2.2} aria-hidden /> À savoir sur cette évaluation
            </p>
            <ul className={styles.limitsList}>
              {avertissements.map((a, i) => (
                <li key={i}>{a}</li>
              ))}
            </ul>
          </section>
        )}

        {hasAccomplishment && (
          <section className={styles.subBlock}>
            <p className={styles.subTitle}>
              <Target size={15} strokeWidth={2.2} color="var(--color-blue)" aria-hidden />
              Ce que demandait la consigne
            </p>
            <AccomplishmentGroupsView groups={groups} />
          </section>
        )}

        {exemplesCorriges.length > 0 && (
          <section className={styles.subBlock}>
            <p className={styles.subTitle}>
              {isOral ? (
                <Lightbulb size={15} strokeWidth={2.2} color="var(--color-blue)" aria-hidden />
              ) : (
                <AlertTriangle size={15} strokeWidth={2.2} color="var(--color-red)" aria-hidden />
              )}
              {isOral ? "Reformulations pour plus de clarté" : "Corrections"}
            </p>
            {exemplesCorriges.map((e, i) => (
              <div key={i} className={styles.correction}>
                <div className={styles.corrLine}>
                  {e.original && <span className={styles.corrOrig}>{e.original}</span>}
                  {e.original && e.corrige ? "  →  " : ""}
                  {e.corrige && <span className={styles.corrFix}>{e.corrige}</span>}
                </div>
                {e.explication && <p className={styles.corrExpl}>{e.explication}</p>}
                {e.gain && (
                  <p className={styles.corrGain}>
                    <span className={styles.corrGainTag}>Ce que ça démontre</span>
                    {e.gain}
                  </p>
                )}
              </div>
            ))}
          </section>
        )}

        {suggestions.length > 0 && (
          <section className={styles.subBlock}>
            <FeedbackList
              title="Suggestions"
              icon={<Lightbulb size={15} strokeWidth={2.2} color="var(--color-blue)" />}
              items={suggestions}
              dot={styles.fbInfo}
            />
          </section>
        )}
      </div>
    </details>
  );
}

/**
 * La consigne en TROIS groupes (parité mobile) : ce qui a été traité, ce qui
 * manque et qui était exigé, ce qui n'était qu'une piste. Mélanger les deux
 * derniers fait paniquer pour des points qui ne coûtent rien.
 */
function AccomplishmentGroupsView({groups}: {groups: AccomplishmentGroups}) {
  return (
    <div className={styles.accGroups}>
      {groups.traites.length > 0 && (
        <AccomplishmentGroup title="Points traités" state="done" points={groups.traites} />
      )}
      {groups.manquesObligatoires.length > 0 && (
        <AccomplishmentGroup
          title="Manques obligatoires"
          state="missing"
          points={groups.manquesObligatoires}
        />
      )}
      {groups.pistesNonAbordees.length > 0 && (
        <AccomplishmentGroup
          title="Pistes non abordées"
          state="skipped"
          points={groups.pistesNonAbordees}
          foot="Les pistes sont des idées proposées par le sujet : ne pas les traiter n'enlève aucun point."
        />
      )}
    </div>
  );
}

function AccomplishmentGroup({
  title,
  state,
  points,
  foot,
}: {
  title: string;
  state: "done" | "missing" | "skipped";
  points: EeAccomplishmentPoint[];
  foot?: string;
}) {
  return (
    <div className={styles.accGroup}>
      <p className={styles.accGroupTitle} data-state={state}>
        {title}
        <span className={styles.accGroupCount}>{points.length}</span>
      </p>
      <ul className={styles.accList}>
        {points.map((p, i) => (
          <AccomplishmentItem key={i} point={p} state={state} />
        ))}
      </ul>
      {foot && <p className={styles.accFoot}>{foot}</p>}
    </div>
  );
}

/** Une ligne de la check-list. Le tag rappelle si le point était exigé par la
 *  consigne ou seulement suggéré — la distinction porte tout le sens. */
function AccomplishmentItem({
  point,
  state,
}: {
  point: EeAccomplishmentPoint;
  state: "done" | "missing" | "skipped";
}) {
  return (
    <li className={styles.accItem}>
      <span className={styles.accIcon} data-state={state} aria-hidden>
        {state === "done" ? <Check size={13} strokeWidth={3.2} /> : null}
      </span>
      <span className={styles.accLabel}>{point.libelle}</span>
      <span className={styles.accTag} data-state={state}>
        {point.obligatoire ? "demandé par la consigne" : "piste"}
      </span>
    </li>
  );
}
