import {
  count,
  percent,
  percentOf,
  plural,
  type AudienceInsights,
} from "../insights";
import styles from "./HeadlineBoard.module.css";

/**
 * Ce qu'on doit savoir sans rien lire : combien sont arrivés, combien ont payé,
 * où ça fuit, quel réseau vaut le coup. La phrase de synthèse est calculée dans
 * `insights.ts`, seuils d'honnêteté compris.
 */
export function HeadlineBoard({ insights }: { insights: AudienceInsights }) {
  const { signups, diagnosticsCompleted, purchases, conversion } = insights;

  return (
    <div className={styles.board}>
      <div className={styles.figures}>
        <Figure
          label="Inscrits"
          value={count(signups)}
          tone="blue"
          detail={`comptes créés sur la période`}
        />
        <Figure
          label="Diagnostic terminé"
          value={count(diagnosticsCompleted)}
          detail={
            signups > 0
              ? `${percentOf(diagnosticsCompleted, signups)} des inscrits`
              : "aucun inscrit à suivre"
          }
        />
        <Figure
          label="Payants"
          value={count(purchases)}
          tone="green"
          detail={`${plural(purchases, "paiement abouti", "paiements aboutis")}`}
        />
        <Figure
          label="Conversion"
          value={percent(conversion)}
          tone="green"
          detail="payants ÷ inscrits"
        />
      </div>

      <p className={styles.summary}>
        {insights.summary.map((part) => (
          <span
            key={part.text}
            className={part.tone === "caveat" ? styles.caveat : undefined}
          >
            {part.text}{" "}
          </span>
        ))}
      </p>
    </div>
  );
}

function Figure({
  label,
  value,
  detail,
  tone,
}: {
  label: string;
  value: string;
  detail: string;
  tone?: "blue" | "green";
}) {
  const toneClass =
    tone === "blue" ? styles.valueBlue : tone === "green" ? styles.valueGreen : "";

  return (
    <div className={styles.figure}>
      <span className={styles.label}>{label}</span>
      <span className={`${styles.value} ${toneClass}`}>{value}</span>
      <span className={styles.detail}>{detail}</span>
    </div>
  );
}
