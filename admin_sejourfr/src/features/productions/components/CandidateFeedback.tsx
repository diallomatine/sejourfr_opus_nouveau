import type { ReactNode } from "react";
import type {
  AccomplissementPoint,
  EvaluationResultDto,
  ExempleCorrige,
  ObjectifAccomplissement,
  PointAmeliorer,
} from "../../../types/api";
import {
  CONFIANCE_LABEL,
  NIVEAU_LABEL,
  NON_EVALUABLE_LABEL,
  OBJECTIF_LABEL,
  isLegacyEvaluation,
  isNonEvaluable,
  normalizePointAmeliorer,
} from "../../../lib/evaluation";
import styles from "./CandidateFeedback.module.css";

const OBJECTIF_CLASS: Record<ObjectifAccomplissement, string> = {
  ATTEINT: styles.objectifAtteint,
  PARTIELLEMENT_ATTEINT: styles.objectifPartiel,
  NON_ATTEINT: styles.objectifNonAtteint,
};

/**
 * Le retour tel que le candidat l'a reçu, rendu depuis `vueCandidat` (le DTO
 * exact de l'endpoint candidat). Le détail par critère n'est pas répété : ce
 * sont les mêmes `scores_criteres` que le bloc « Évaluation IA », qui les
 * montre avec leur poids.
 */
export function CandidateFeedback({ evaluation }: { evaluation: EvaluationResultDto }) {
  const feedback = evaluation.feedback;
  const accomplissement = feedback?.accomplissement;
  const raisons = feedback?.confiance_raisons ?? [];
  const avertissements = feedback?.avertissements ?? [];
  const legacy = isLegacyEvaluation(evaluation);

  const traites = accomplissement?.points_traites ?? [];
  const oublies = accomplissement?.points_oublies ?? [];
  const objectif = accomplissement?.objectif ?? null;
  const objectifResume = accomplissement?.objectif_resume;

  const head = legacy ? (
    <div className={styles.head}>
      <span className={styles.legacy} title="Évaluation antérieure au schéma v4">
        Format v3 — sans bandes ni preuves
      </span>
    </div>
  ) : null;

  if (isNonEvaluable(evaluation)) {
    return (
      <section className={styles.wrap}>
        {head}
        <NonEvaluableBanner raisons={raisons} />
        {avertissements.length > 0 && (
          <Block title="Avertissements">
            <ul className={styles.avertissements}>
              {avertissements.map((avertissement, index) => (
                <li key={index}>{avertissement}</li>
              ))}
            </ul>
          </Block>
        )}
      </section>
    );
  }

  return (
    <section className={styles.wrap}>
      {head}

      <div className={styles.summaryMeta}>
        <MetaLine label="Niveau observé (tâche)">
          {evaluation.niveauObserve
            ? NIVEAU_LABEL[evaluation.niveauObserve]
            : "Non montré au candidat"}
        </MetaLine>
        <MetaLine label="Position dans le niveau">
          {evaluation.situationDansNiveauLabel ?? "Non disponible"}
        </MetaLine>
        <MetaLine label="Confiance">
          {evaluation.confiance
            ? CONFIANCE_LABEL[evaluation.confiance]
            : "Non disponible"}
        </MetaLine>
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

/**
 * Ce que dit une évaluation `NON_EVALUABLE` : le serveur a jugé la production
 * inexploitable (vide, quasi vide, langue non française, recopiage de la
 * consigne) et n'a émis **aucun appel LLM**. Elle ne porte donc ni note, ni
 * niveau, ni `scores_criteres` — jusqu'au 2026-08-21 elle portait 0/20,
 * `A1_NON_ATTEINT` et quatre critères à zéro, c'est-à-dire une absence de
 * preuve enregistrée comme la preuve du niveau le plus faible.
 *
 * Elle reste visible ici parce qu'une console de calibration doit pouvoir
 * constater ces refus : ce sont eux qu'on regarde quand on se demande si les
 * contrôles déterministes écartent trop, ou pas assez.
 */
function NonEvaluableBanner({ raisons }: { raisons: string[] }) {
  return (
    <div className={styles.nonEvaluable}>
      <p className={styles.nonEvaluableTitle}>
        {NON_EVALUABLE_LABEL} — aucun appel au correcteur
      </p>
      <p className={styles.nonEvaluableText}>
        La production a été écartée par les contrôles déterministes du serveur : ni note, ni
        niveau, ni score par critère n&apos;ont été produits. Il n&apos;y a rien à annoter.
      </p>
      {raisons.length > 0 && (
        <ul className={styles.plainList}>
          {raisons.map((raison, index) => (
            <li key={index}>{raison}</li>
          ))}
        </ul>
      )}
    </div>
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
