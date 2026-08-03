import type { ReactNode } from "react";
import type {
  AccomplissementPoint,
  BandeCritere,
  EvaluationResultDto,
  ScoreCritereFeedback,
} from "../../../types/api";
import {
  BANDE_LABEL,
  CONFIANCE_LABEL,
  CRITERES_OBSOLETES,
  NIVEAU_LABEL,
  critereLabel,
  formatDecimal,
  isLegacyEvaluation,
  toNumber,
} from "../calibrationHelpers";
import styles from "./EvaluationReport.module.css";

const BANDE_CLASS: Record<BandeCritere, string> = {
  TRES_BONNE_MAITRISE: styles.bandeHaute,
  SATISFAISANT: styles.bandeBonne,
  EN_COURS_ACQUISITION: styles.bandeMoyenne,
  FRAGILE: styles.bandeFragile,
  NON_EVALUABLE: styles.bandeNeutre,
};

export function EvaluationReport({
  evaluation,
}: {
  evaluation: EvaluationResultDto;
}) {
  const feedback = evaluation.feedback;
  const criteres = feedback?.scores_criteres ?? [];
  const accomplissement = feedback?.accomplissement;
  const raisons = feedback?.confiance_raisons ?? [];
  const avertissements = feedback?.avertissements ?? [];
  const legacy = isLegacyEvaluation(evaluation);

  const traites = accomplissement?.points_traites ?? [];
  const oublies = accomplissement?.points_oublies ?? [];

  return (
    <section className={styles.wrap}>
      <div className={styles.head}>
        <h3 className={styles.title}>Évaluation de l&apos;IA</h3>
        {legacy && (
          <span className={styles.legacy} title="Évaluation antérieure au schéma v4">
            Format v3 — sans bandes ni preuves
          </span>
        )}
      </div>

      <div className={styles.summary}>
        <div className={styles.scoreBlock}>
          <span className={styles.scoreLabel}>Note globale</span>
          <span className={styles.scoreValue}>
            {evaluation.noteSurVingt === null
              ? "—"
              : formatDecimal(evaluation.noteSurVingt)}
            <em> / 20</em>
          </span>
        </div>

        <div className={styles.summaryMeta}>
          <MetaLine label="Niveau observé">
            {evaluation.niveauObserve
              ? NIVEAU_LABEL[evaluation.niveauObserve]
              : "Non renseigné"}
          </MetaLine>
          <MetaLine label="Confiance">
            {evaluation.confiance
              ? CONFIANCE_LABEL[evaluation.confiance]
              : "Non renseignée"}
          </MetaLine>
        </div>
      </div>

      {evaluation.avertissementNiveau && (
        <p className={styles.avertissementNiveau}>{evaluation.avertissementNiveau}</p>
      )}

      {raisons.length > 0 && (
        <Block title="Raisons de la confiance">
          <ul className={styles.plainList}>
            {raisons.map((raison, index) => (
              <li key={index}>{raison}</li>
            ))}
          </ul>
        </Block>
      )}

      {criteres.length > 0 ? (
        <Block title="Détail par critère">
          <ul className={styles.criteres}>
            {criteres.map((critere, index) => (
              <CritereRow key={`${critere.code}-${index}`} critere={critere} />
            ))}
          </ul>
        </Block>
      ) : (
        <Block title="Détail par critère">
          <p className={styles.none}>
            Aucun score par critère n&apos;a été persisté pour cette évaluation.
          </p>
        </Block>
      )}

      {(traites.length > 0 || oublies.length > 0) && (
        <Block title="Accomplissement de la consigne">
          <div className={styles.accomplissement}>
            <PointsColumn
              heading={`Points traités (${traites.length})`}
              points={traites}
              treated
            />
            <PointsColumn
              heading={`Points oubliés (${oublies.length})`}
              points={oublies}
              treated={false}
            />
          </div>
        </Block>
      )}

      {avertissements.length > 0 && (
        <Block title="Avertissements">
          <ul className={styles.avertissements}>
            {avertissements.map((avertissement, index) => (
              <li key={index}>{avertissement}</li>
            ))}
          </ul>
        </Block>
      )}

      <WrittenFeedback evaluation={evaluation} />
    </section>
  );
}

function CritereRow({ critere }: { critere: ScoreCritereFeedback }) {
  const note = toNumber(critere.note_sur_20);
  const obsolete = CRITERES_OBSOLETES.includes(critere.code);

  return (
    <li className={styles.critere}>
      <div className={styles.critereHead}>
        <span className={styles.critereName}>
          {critereLabel(critere.code, critere.label)}
          {obsolete && <em className={styles.obsolete}> critère v3</em>}
        </span>
        <span className={styles.critereScore}>
          {note === null ? "—" : `${formatDecimal(note)} / 20`}
        </span>
      </div>

      <div className={styles.critereTags}>
        <code className={styles.critereCode}>{critere.code}</code>
        {critere.bande && (
          <span className={`${styles.bande} ${BANDE_CLASS[critere.bande]}`}>
            {BANDE_LABEL[critere.bande]}
          </span>
        )}
      </div>

      {critere.commentaire && (
        <p className={styles.critereComment}>{critere.commentaire}</p>
      )}

      {critere.preuve && (
        <blockquote className={styles.preuve}>{critere.preuve}</blockquote>
      )}
    </li>
  );
}

function PointsColumn({
  heading,
  points,
  treated,
}: {
  heading: string;
  points: AccomplissementPoint[];
  treated: boolean;
}) {
  return (
    <div className={styles.pointsColumn}>
      <div className={styles.pointsHeading}>{heading}</div>
      {points.length === 0 ? (
        <p className={styles.none}>Aucun</p>
      ) : (
        <ul className={styles.points}>
          {points.map((point, index) => (
            <li
              key={index}
              className={treated ? styles.pointTraite : styles.pointOublie}
            >
              <span aria-hidden="true" className={styles.pointMark}>
                {treated ? "✓" : "✗"}
              </span>
              <span>{point.libelle}</span>
              {point.obligatoire && (
                <span className={styles.obligatoire}>obligatoire</span>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/** Ce que le candidat lit dans l'application, regroupé en fin de fiche. */
function WrittenFeedback({ evaluation }: { evaluation: EvaluationResultDto }) {
  const feedback = evaluation.feedback;
  const sections: { title: string; items: string[] }[] = [
    { title: "Points forts", items: feedback?.points_forts ?? [] },
    { title: "Points à améliorer", items: feedback?.points_a_ameliorer ?? [] },
    { title: "Suggestions", items: feedback?.suggestions ?? [] },
    { title: "Exemples corrigés", items: feedback?.exemples_corriges ?? [] },
  ].filter((section) => section.items.length > 0);

  if (sections.length === 0) return null;

  return (
    <Block title="Retour rédigé au candidat">
      <div className={styles.written}>
        {sections.map((section) => (
          <div key={section.title}>
            <div className={styles.writtenHeading}>{section.title}</div>
            <ul className={styles.plainList}>
              {section.items.map((item, index) => (
                <li key={index}>{item}</li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </Block>
  );
}

function Block({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <div className={styles.block}>
      <div className={styles.blockTitle}>{title}</div>
      {children}
    </div>
  );
}

function MetaLine({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <div className={styles.metaLine}>
      <span className={styles.metaLabel}>{label}</span>
      <span className={styles.metaValue}>{children}</span>
    </div>
  );
}
