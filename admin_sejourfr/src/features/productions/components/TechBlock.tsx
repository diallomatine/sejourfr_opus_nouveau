import { formatParisDateTime } from "../../../lib/dates";
import type { AdminProductionTechnique } from "../../../types/api";
import { formatEuroCents, formatInteger, formatMicroUsd, formatSeconds } from "../productionLabels";
import { Facts, NotAvailable } from "./Facts";
import styles from "./TechBlock.module.css";

/**
 * Uniquement ce qui est enregistré sur l'appel. Le coût est en millionièmes de
 * dollar ; l'ancienne colonne en centimes d'euro est montrée à part, jamais
 * additionnée.
 */
export function TechBlock({ technique }: { technique: AdminProductionTechnique }) {
  return (
    <div className={styles.wrap}>
      <Facts
        columns={4}
        items={[
          { label: "Fournisseur", value: <NotAvailable>Non enregistré</NotAvailable> },
          { label: "Modèle", value: technique.modele, mono: true },
          { label: "Version de grille", value: technique.rubricsVersion, mono: true },
          { label: "Schéma de sortie (prompt)", value: technique.promptVersion, mono: true },
          { label: "Tokens entrée", value: technique.tokensInput === null ? null : formatInteger(technique.tokensInput) },
          {
            label: "dont cache",
            value: technique.tokensInputCacheHit === null ? null : formatInteger(technique.tokensInputCacheHit),
          },
          { label: "Tokens sortie", value: technique.tokensOutput === null ? null : formatInteger(technique.tokensOutput) },
          { label: "Coût (USD)", value: technique.coutMicroUsd === null ? null : formatMicroUsd(technique.coutMicroUsd), mono: true },
          {
            label: "Coût legacy (€, ancienne colonne)",
            value: technique.coutLegacyCentimesEuro === null ? null : formatEuroCents(technique.coutLegacyCentimesEuro),
            mono: true,
          },
          { label: "Soumise le", value: technique.submittedAt ? formatParisDateTime(technique.submittedAt) : null },
          { label: "Évaluée le", value: technique.evaluatedAt ? formatParisDateTime(technique.evaluatedAt) : null },
          {
            label: "Délai soumission → évaluation",
            value:
              technique.delaiSoumissionEvaluationSec === null
                ? null
                : formatSeconds(technique.delaiSoumissionEvaluationSec),
          },
          { label: "Relances manuelles", value: String(technique.relancesManuelles) },
        ]}
      />
      <p className={styles.note}>
        Tokens : cumul correction, réparation, seconde passe et version ciblée (non ventilable). Le délai
        inclut la file d&apos;attente : ce n&apos;est pas une durée d&apos;appel.
      </p>
      {technique.erreurMessage && <pre className={styles.error}>{technique.erreurMessage}</pre>}
    </div>
  );
}
