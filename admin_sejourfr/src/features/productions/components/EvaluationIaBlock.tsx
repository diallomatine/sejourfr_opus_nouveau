import { Tag } from "../../../components/ui/Tag";
import { formatParisDateTime } from "../../../lib/dates";
import { BANDE_LABEL, CONFIANCE_LABEL } from "../../../lib/evaluation";
import type { AdminProductionCritereRetenu, AdminProductionEvaluationIa, ConfianceEvaluation } from "../../../types/api";
import { BANDE_TONE, formatScore, isBande } from "../productionLabels";
import { Facts, NotAvailable, SectionLabel } from "./Facts";
import styles from "./EvaluationIaBlock.module.css";

function confianceLabel(value: string | null): string | null {
  if (value === null) return null;
  return value in CONFIANCE_LABEL ? CONFIANCE_LABEL[value as ConfianceEvaluation] : value;
}

/**
 * Scores RETENUS (après garde-fous serveur), /20 par critère, avec le poids de
 * la grille de l'évaluation. Les notes d'origine de l'IA ne sont pas conservées.
 */
export function EvaluationIaBlock({
  evaluation,
  criteresAuPlafond,
}: {
  evaluation: AdminProductionEvaluationIa;
  /** Critères exactement au plafond de couplage : possiblement ramenés. */
  criteresAuPlafond: string[];
}) {
  const nonEvaluable = evaluation.evaluabilite === "NON_EVALUABLE";

  return (
    <div className={styles.wrap}>
      <Facts
        columns={4}
        items={[
          {
            label: "Note retenue",
            value: evaluation.noteSur20 === null ? null : `${formatScore(evaluation.noteSur20)} / 20`,
          },
          { label: "Confiance", value: confianceLabel(evaluation.confiance) },
          { label: "Évaluée le", value: evaluation.evaluatedAt ? formatParisDateTime(evaluation.evaluatedAt) : null },
          {
            label: "Évaluations de la production",
            value: evaluation.nbEvaluations > 1 ? `${evaluation.nbEvaluations} (la dernière est affichée)` : String(evaluation.nbEvaluations),
          },
        ]}
      />

      {nonEvaluable ? (
        <div className={styles.nonEvaluable}>
          <p className={styles.nonEvaluableTitle}>Non évaluable — aucun appel au correcteur</p>
          <p className={styles.nonEvaluableText}>
            Le serveur a écarté la production avant toute correction : ni note, ni niveau, ni score par critère.
          </p>
        </div>
      ) : (
        <div>
          <SectionLabel>Scores retenus par critère</SectionLabel>
          {evaluation.criteres.length === 0 ? (
            <NotAvailable>Aucun score par critère enregistré pour cette évaluation</NotAvailable>
          ) : (
            <ul className={styles.criteres}>
              {evaluation.criteres.map((critere, index) => (
                <CritereCard
                  key={`${critere.code}-${index}`}
                  critere={critere}
                  auPlafond={criteresAuPlafond.includes(critere.code)}
                />
              ))}
            </ul>
          )}
        </div>
      )}

      {evaluation.justificationNiveau && (
        <div>
          <SectionLabel>Justification du niveau par l&apos;IA (jamais montrée au candidat)</SectionLabel>
          <p className={styles.text}>{evaluation.justificationNiveau}</p>
        </div>
      )}

      {evaluation.confianceRaisons.length > 0 && (
        <div>
          <SectionLabel>Raisons de la confiance</SectionLabel>
          <ul className={styles.list}>
            {evaluation.confianceRaisons.map((raison, index) => (
              <li key={index}>{raison}</li>
            ))}
          </ul>
        </div>
      )}

      {evaluation.avertissements.length > 0 && (
        <div>
          <SectionLabel>Avertissements</SectionLabel>
          <ul className={styles.warnings}>
            {evaluation.avertissements.map((avertissement, index) => (
              <li key={index}>{avertissement}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

function CritereCard({ critere, auPlafond }: { critere: AdminProductionCritereRetenu; auPlafond: boolean }) {
  return (
    <li className={styles.critere}>
      <div className={styles.critereHead}>
        <span className={styles.critereName}>{critere.label ?? critere.code}</span>
        <code className={styles.code}>{critere.code}</code>
      </div>
      <div className={styles.score}>
        {critere.noteSur20 === null ? "—" : formatScore(critere.noteSur20)}
        <span className={styles.scoreMax}> / 20</span>
      </div>
      <div className={styles.critereMeta}>
        <span className={styles.poids}>
          {critere.poids === null ? "poids non disponible" : `poids × ${formatScore(critere.poids)}`}
        </span>
        {isBande(critere.bande) && <Tag tone={BANDE_TONE[critere.bande]}>{BANDE_LABEL[critere.bande]}</Tag>}
        {auPlafond && (
          <span title="Exactement au plafond du garde-fou de couplage : la note a pu être ramenée (note d'origine non conservée).">
            <Tag tone="warning">Possiblement ramené</Tag>
          </span>
        )}
      </div>
      {critere.commentaire && <p className={styles.comment}>{critere.commentaire}</p>}
      {critere.preuve && <blockquote className={styles.preuve}>{critere.preuve}</blockquote>}
    </li>
  );
}
