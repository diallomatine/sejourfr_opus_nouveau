import type { ReactNode } from "react";
import type {
  AccomplissementPoint,
  BandeCritere,
  EvaluationResultDto,
  ExempleCorrige,
  ObjectifAccomplissement,
  PointAmeliorer,
  ScoreCritereFeedback,
} from "../../../types/api";
import {
  BANDE_LABEL,
  CONFIANCE_LABEL,
  CRITERES_OBSOLETES,
  NIVEAU_LABEL,
  OBJECTIF_LABEL,
  critereLabel,
  formatDecimal,
  isLegacyEvaluation,
  normalizePointAmeliorer,
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

const OBJECTIF_CLASS: Record<ObjectifAccomplissement, string> = {
  ATTEINT: styles.objectifAtteint,
  PARTIELLEMENT_ATTEINT: styles.objectifPartiel,
  NON_ATTEINT: styles.objectifNonAtteint,
};

export function EvaluationReport({
  evaluation,
  rubricsVersion,
  promptVersion,
}: {
  evaluation: EvaluationResultDto;
  /** Grille appliquée. Null pour une évaluation antérieure à la colonne. */
  rubricsVersion: string | null;
  promptVersion: string | null;
}) {
  const feedback = evaluation.feedback;
  const criteres = feedback?.scores_criteres ?? [];
  const accomplissement = feedback?.accomplissement;
  const raisons = feedback?.confiance_raisons ?? [];
  const avertissements = feedback?.avertissements ?? [];
  const legacy = isLegacyEvaluation(evaluation);

  const traites = accomplissement?.points_traites ?? [];
  const oublies = accomplissement?.points_oublies ?? [];
  const objectif = accomplissement?.objectif ?? null;
  const objectifResume = accomplissement?.objectif_resume;

  return (
    <section className={styles.wrap}>
      <div className={styles.head}>
        <h3 className={styles.title}>Évaluation de l&apos;IA</h3>
        <div className={styles.headTags}>
          {legacy && (
            <span className={styles.legacy} title="Évaluation antérieure au schéma v4">
              Format v3 — sans bandes ni preuves
            </span>
          )}
          <span
            className={styles.legacy}
            title={
              promptVersion
                ? `Grille de notation appliquée · schéma de sortie ${promptVersion}`
                : "Grille de notation appliquée"
            }
          >
            Grille {rubricsVersion ?? "inconnue"}
          </span>
        </div>
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

      {(traites.length > 0 || oublies.length > 0 || objectif || objectifResume) && (
        <Block title="Accomplissement de la consigne">
          {(objectif || objectifResume) && (
            <div className={styles.objectifRow}>
              {objectif ? (
                <span className={`${styles.objectif} ${OBJECTIF_CLASS[objectif]}`}>
                  {OBJECTIF_LABEL[objectif]}
                </span>
              ) : (
                <span className={styles.none}>Verdict non renseigné (évaluation antérieure à v8)</span>
              )}
              {objectifResume && <p className={styles.objectifResume}>{objectifResume}</p>}
            </div>
          )}
          {(traites.length > 0 || oublies.length > 0) && (
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
          )}
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
          {obsolete && <em className={styles.obsolete}> grille précédente</em>}
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

/**
 * Ce que le correcteur a rédigé pour le candidat, regroupé en fin de fiche.
 *
 * ⚠️ **Trois de ces blocs n'existent plus dans le contrat de sortie** :
 * `version_amelioree` (retirée en v14/v8), puis `exemples_corriges` et
 * `suggestions` (retirés en v15/v9). La console de calibration les affiche
 * quand même — elle relit des évaluations **déjà en base**, dont une centaine
 * les portent, et comparer deux grilles suppose de voir ce que chacune rendait.
 * Chaque bloc se masque seul quand son champ manque (et le bloc entier
 * disparaît quand ils manquent tous) : c'est ce qui rend l'écran tolérant à une
 * évaluation v9, qui n'en porte plus aucun. Les écrans candidat, eux, ne les
 * affichent plus du tout.
 */
function WrittenFeedback({ evaluation }: { evaluation: EvaluationResultDto }) {
  const feedback = evaluation.feedback;
  const pointsForts = feedback?.points_forts ?? [];
  const suggestions = feedback?.suggestions ?? [];
  const ameliorations = (feedback?.points_a_ameliorer ?? []).map(normalizePointAmeliorer);
  const exemples = feedback?.exemples_corriges ?? [];
  const versionAmelioree = feedback?.version_amelioree;

  if (
    pointsForts.length === 0 &&
    ameliorations.length === 0 &&
    suggestions.length === 0 &&
    exemples.length === 0 &&
    !versionAmelioree
  ) {
    return null;
  }

  return (
    <Block title="Retour rédigé au candidat">
      <div className={styles.written}>
        {pointsForts.length > 0 && (
          <div>
            <div className={styles.writtenHeading}>Points forts</div>
            <ul className={styles.plainList}>
              {pointsForts.map((item, index) => (
                <li key={index}>{item}</li>
              ))}
            </ul>
          </div>
        )}

        {ameliorations.length > 0 && (
          <div className={styles.ameliorationsBlock}>
            <div className={styles.writtenHeading}>Points à améliorer</div>
            <ul className={styles.ameliorations}>
              {ameliorations.map((point, index) => (
                <AmeliorationRow key={index} point={point} />
              ))}
            </ul>
          </div>
        )}

        {suggestions.length > 0 && (
          <div>
            <div className={styles.writtenHeading}>
              Suggestions
              <em className={styles.obsolete}> contrat ≤ v14</em>
            </div>
            <ul className={styles.plainList}>
              {suggestions.map((item, index) => (
                <li key={index}>{item}</li>
              ))}
            </ul>
          </div>
        )}

        {exemples.length > 0 && (
          <div className={styles.exemplesBlock}>
            <div className={styles.writtenHeading}>
              Exemples corrigés
              <em className={styles.obsolete}> contrat ≤ v14</em>
            </div>
            <ul className={styles.exemples}>
              {exemples.map((exemple, index) => (
                <ExempleRow key={index} exemple={exemple} />
              ))}
            </ul>
          </div>
        )}

        {versionAmelioree && (
          <div className={styles.versionAmelioreeBlock}>
            <div className={styles.writtenHeading}>
              Version améliorée (réécriture complète — EE uniquement)
              <em className={styles.obsolete}> contrat ≤ v13</em>
            </div>
            <p className={styles.versionAmelioree}>{versionAmelioree}</p>
          </div>
        )}
      </div>
    </Block>
  );
}

function AmeliorationRow({ point }: { point: PointAmeliorer }) {
  return (
    <li className={styles.amelioration}>
      <p className={styles.ameliorationConstat}>{point.constat}</p>
      {point.comment && <p className={styles.ameliorationComment}>{point.comment}</p>}
      {point.exemple && (
        <div className={styles.ameliorationExemple}>
          <div className={styles.exempleLine}>
            <span className={styles.exempleTag}>Avant</span>
            <q className={styles.exempleOriginal}>{point.exemple.avant}</q>
          </div>
          <div className={styles.exempleLine}>
            <span className={`${styles.exempleTag} ${styles.exempleTagOk}`}>Après</span>
            <q className={styles.exempleCorrige}>{point.exemple.apres}</q>
          </div>
        </div>
      )}
    </li>
  );
}

function ExempleRow({ exemple }: { exemple: ExempleCorrige }) {
  return (
    <li className={styles.exemple}>
      <div className={styles.exempleLine}>
        <span className={styles.exempleTag}>Production</span>
        <q className={styles.exempleOriginal}>{exemple.original}</q>
      </div>
      <div className={styles.exempleLine}>
        <span className={`${styles.exempleTag} ${styles.exempleTagOk}`}>
          Corrigé
        </span>
        <q className={styles.exempleCorrige}>{exemple.corrige}</q>
      </div>
      {exemple.explication && (
        <p className={styles.exempleExplication}>{exemple.explication}</p>
      )}
      {exemple.gain && (
        <p className={styles.exempleGain}>
          <span className={styles.exempleGainTag}>Ce que ça démontre</span>
          {exemple.gain}
        </p>
      )}
    </li>
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
