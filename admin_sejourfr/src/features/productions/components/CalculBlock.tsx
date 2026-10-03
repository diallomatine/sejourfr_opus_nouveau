import { Tag } from "../../../components/ui/Tag";
import { NIVEAU_LABEL } from "../../../lib/evaluation";
import type { AdminProductionCalcul, AdminProductionEvaluationIa, NiveauCecrl } from "../../../types/api";
import { formatScore } from "../productionLabels";
import { Facts, NotAvailable, SectionLabel } from "./Facts";
import styles from "./CalculBlock.module.css";

function niveau(value: NiveauCecrl | null): string | null {
  return value === null ? null : NIVEAU_LABEL[value];
}

function codes(list: string[]): string | null {
  return list.length === 0 ? null : list.join(", ");
}

/**
 * Le calcul SejourFR relu par le serveur avec la grille DE L'ÉVALUATION (les
 * mêmes fonctions que la notation). Le niveau qui fait foi reste le niveau
 * enregistré ; un écart avec le recalcul est montré, jamais corrigé.
 */
export function CalculBlock({ calcul }: { calcul: AdminProductionCalcul }) {
  if (calcul.statut !== "CALCULE") {
    return (
      <div className={styles.wrap}>
        <p className={styles.notice}>{calcul.statutLabel}</p>
        {calcul.statut === "REGLE_NON_TRACABLE" && (
          <Facts
            columns={4}
            items={[
              { label: "Niveau enregistré", value: niveau(calcul.niveauPersiste) },
              {
                label: "Note enregistrée",
                value: calcul.notePersistee === null ? null : `${formatScore(calcul.notePersistee)} / 20`,
              },
              { label: "Grille", value: calcul.rubricsVersion, mono: true },
              { label: "Schéma de sortie", value: calcul.promptVersion, mono: true },
            ]}
          />
        )}
      </div>
    );
  }

  const seuils = calcul.seuils;
  const couplage = calcul.couplage;

  return (
    <div className={styles.wrap}>
      <div className={styles.result}>
        <div className={styles.resultMain}>
          <SectionLabel>Niveau observé (tâche) enregistré</SectionLabel>
          <span className={styles.level}>{niveau(calcul.niveauPersiste) ?? "—"}</span>
        </div>
        <div className={styles.resultSide}>
          {calcul.coherent === true && <Tag tone="success" dot>Recalcul conforme au niveau enregistré</Tag>}
          {calcul.coherent === false && (
            <Tag tone="danger" dot>
              Écart : recalcul {niveau(calcul.niveauRecalcule) ?? "—"} ≠ enregistré {niveau(calcul.niveauPersiste) ?? "—"}
            </Tag>
          )}
          {calcul.coherent === null && <Tag tone="neutral">Cohérence non vérifiable</Tag>}
          <span className={styles.version}>
            Grille <code>{calcul.rubricsVersion ?? "—"}</code>
            {calcul.grilleActive ? " (active)" : " (historique)"} · schéma <code>{calcul.promptVersion ?? "—"}</code>
          </span>
        </div>
      </div>

      <Facts
        columns={4}
        items={[
          {
            label: "Note recalculée",
            value: calcul.noteRecalculee === null ? null : `${formatScore(calcul.noteRecalculee)} / 20`,
          },
          {
            label: "Note enregistrée",
            value: calcul.notePersistee === null ? null : `${formatScore(calcul.notePersistee)} / 20`,
          },
          {
            label: "Compétence",
            value: calcul.competence === null ? null : `${formatScore(calcul.competence)} / 20`,
          },
          { label: "Critères porteurs du niveau", value: codes(calcul.criteresPorteursNiveau), mono: true },
          {
            label: "Seuils A2 · B1 · B2",
            value: seuils
              ? `${seuils.a2 === null ? "—" : formatScore(seuils.a2)} · ${seuils.b1 === null ? "—" : formatScore(seuils.b1)} · ${seuils.b2 === null ? "—" : formatScore(seuils.b2)}`
              : null,
          },
          {
            label: "Origine des seuils",
            value: calcul.seuilsDeLaGrille ? "Fichier de la grille" : "Configuration actuelle (grille sans seuils)",
          },
          { label: "Niveau avant plafonds", value: niveau(calcul.niveauAvantPlafonds) },
          { label: "Niveau recalculé", value: niveau(calcul.niveauRecalcule) },
        ]}
      />

      {calcul.formuleNote && (
        <div>
          <SectionLabel>Formule de la note</SectionLabel>
          <p className={styles.rule}>{calcul.formuleNote}</p>
        </div>
      )}
      {calcul.regleNiveau && (
        <div>
          <SectionLabel>Règle du niveau</SectionLabel>
          <p className={styles.rule}>{calcul.regleNiveau}</p>
        </div>
      )}

      <div className={styles.split}>
        <div className={styles.box}>
          <SectionLabel>Plafonds de niveau</SectionLabel>
          {calcul.plafondsDeclenches.length === 0 ? (
            <p className={styles.small}>Aucun plafond déclenché sur les scores retenus.</p>
          ) : (
            <ul className={styles.plafonds}>
              {calcul.plafondsDeclenches.map((p, index) => (
                <li key={`${p.regle}-${index}`}>
                  <code>{p.regle}</code> → niveau max {niveau(p.niveauMax) ?? "—"}
                  {p.declencheur && <span className={styles.small}> · {p.declencheur}</span>}
                </li>
              ))}
            </ul>
          )}
          <p className={styles.small}>
            Plafond enregistré à l&apos;évaluation : {niveau(calcul.plafondPersiste) ?? "aucun"}
          </p>
        </div>

        <div className={styles.box}>
          <SectionLabel>Couplage réalisation ⇄ langue</SectionLabel>
          {couplage === null ? (
            <NotAvailable />
          ) : !couplage.actif ? (
            <p className={styles.small}>Garde-fou coupé pour cette grille.</p>
          ) : (
            <Facts
              columns={2}
              items={[
                { label: "Écart max", value: couplage.ecartMax === null ? null : formatScore(couplage.ecartMax) },
                {
                  label: "Plafond de réalisation",
                  value: couplage.plafondRealisation === null ? null : `${formatScore(couplage.plafondRealisation)} / 20`,
                },
                { label: "Critères de réalisation", value: codes(couplage.criteresRealisation), mono: true },
                { label: "Critères de langue", value: codes(couplage.criteresLangue), mono: true },
                {
                  label: "Possiblement ramenés",
                  value: couplage.criteresAuPlafond.length === 0 ? "Aucun" : codes(couplage.criteresAuPlafond),
                  mono: couplage.criteresAuPlafond.length > 0,
                  wide: true,
                },
              ]}
            />
          )}
        </div>
      </div>
    </div>
  );
}

/** Niveau proposé par l'IA (indicatif) face au niveau retenu par le serveur. */
export function NiveauIaVsRetenu({ evaluation }: { evaluation: AdminProductionEvaluationIa }) {
  const ecart = evaluation.ecartNiveauCrans;
  return (
    <div className={styles.compare}>
      <Facts
        columns={3}
        items={[
          { label: "Niveau proposé par l'IA (indicatif)", value: niveau(evaluation.niveauIa) },
          { label: "Niveau observé (tâche) retenu", value: niveau(evaluation.niveauRetenu) },
          {
            label: "Montré au candidat",
            value: evaluation.niveauMontreAuCandidat ? "Oui" : "Non (confiance absente)",
          },
        ]}
      />
      {ecart !== null && ecart !== 0 && (
        <p className={styles.gap} role="note">
          Écart de {Math.abs(ecart)} cran{Math.abs(ecart) > 1 ? "s" : ""} : l&apos;IA proposait{" "}
          {niveau(evaluation.niveauIa)}, le serveur a retenu {niveau(evaluation.niveauRetenu)}.
        </p>
      )}
      {ecart === 0 && <p className={styles.small}>L&apos;IA et le serveur concluent au même niveau.</p>}
    </div>
  );
}
