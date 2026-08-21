import type { FunnelBreakdownCounts } from "../../../types/api";
import tableStyles from "../../../components/ui/DataTable.module.css";
import {
  barWidth,
  count,
  percent,
  percentOf,
  type SourceScore,
} from "../insights";
import { BREAKDOWN_COLUMNS, UNKNOWN_SOURCE, sourceLabel } from "../labels";
import panels from "./panels.module.css";
import styles from "./SourceRanking.module.css";

/**
 * Classement des provenances. L'ordre vient de `compareSources` (volume de
 * payants d'abord) : trier sur le seul taux hisserait en tête un réseau à
 * 1 inscrit et 1 payant. Le détail des 7 étapes reste consultable, replié —
 * c'est une console d'admin, on doit pouvoir vérifier.
 */
export function SourceRanking({
  ranking,
  bestSource,
}: {
  ranking: SourceScore[];
  bestSource: SourceScore | null;
}) {
  if (ranking.length === 0) {
    return (
      <p className={panels.state}>
        <strong className={panels.stateTitle}>Aucune provenance</strong>
        Aucun compte de la période ne porte de provenance : le lien de campagne
        n&apos;a pas encore été utilisé, ou ces comptes sont antérieurs à la
        mesure.
      </p>
    );
  }

  const maxSignups = ranking.reduce((max, s) => Math.max(max, s.signups), 0);
  const maxConversion = ranking.reduce(
    (max, s) => Math.max(max, s.conversion ?? 0),
    0,
  );

  return (
    <div className={panels.panel}>
      <div className={panels.head}>
        <h3 className={panels.title}>Quel réseau amène des comptes qui paient</h3>
        <span className={panels.hint}>
          classé par nombre de payants, puis par taux de conversion
        </span>
      </div>

      <ol className={styles.rows}>
        {ranking.map((source, index) => {
          const isBest = bestSource !== null && bestSource.source === source.source;
          const isUnknown = source.source === UNKNOWN_SOURCE;

          return (
            <li
              key={source.source}
              className={`${styles.row} ${isBest ? styles.rowBest : ""} ${
                isUnknown ? styles.rowUnknown : ""
              }`}
            >
              <span className={styles.rank}>
                {String(index + 1).padStart(2, "0")}
              </span>

              <div className={styles.identity}>
                <span className={styles.name}>
                  {sourceLabel(source.source)}
                  {isBest && <span className={styles.best}>meilleur taux</span>}
                </span>
                <span className={styles.volume}>
                  <i style={{ width: barWidth(source.signups, maxSignups) }} />
                </span>
                <span className={styles.counts}>
                  {count(source.signups)} inscrits · {count(source.purchases)}{" "}
                  payants
                </span>
              </div>

              <div className={styles.conversion}>
                <span
                  className={`${styles.conversionValue} ${
                    source.purchases === 0 ? styles.conversionZero : ""
                  }`}
                >
                  {percent(source.conversion)}
                </span>
                {maxConversion > 0 && (
                  <span className={styles.conversionBar}>
                    <i
                      style={{
                        width: barWidth(source.conversion ?? 0, maxConversion),
                      }}
                    />
                  </span>
                )}
                <span className={styles.conversionCaption}>conversion</span>
              </div>
            </li>
          );
        })}
      </ol>

      <details className={styles.details}>
        <summary className={styles.detailsSummary}>
          Détail des 7 étapes, provenance par provenance
        </summary>
        <div className={styles.detailsBody}>
          <BreakdownTable ranking={ranking} />
        </div>
      </details>
    </div>
  );
}

function BreakdownTable({ ranking }: { ranking: SourceScore[] }) {
  const total = ranking.reduce(sumBreakdown, emptyBreakdown());

  return (
    <div className={tableStyles.tableWrap}>
      <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
        <thead>
          <tr>
            <th>Provenance</th>
            {BREAKDOWN_COLUMNS.map((column) => (
              <th key={column.key} className={styles.numCol}>
                {column.label}
              </th>
            ))}
            <th className={styles.numCol}>Conversion</th>
          </tr>
        </thead>
        <tbody>
          {ranking.map((row) => (
            <tr key={row.source}>
              <td className={styles.rowName}>{sourceLabel(row.source)}</td>
              {BREAKDOWN_COLUMNS.map((column) => (
                <td
                  key={column.key}
                  data-label={column.label}
                  className={styles.num}
                >
                  {count(row[column.key])}
                </td>
              ))}
              <td className={styles.num}>
                <span className={styles.mobileLabel}>Conversion</span>
                <strong className={styles.tableConversion}>
                  {percentOf(row.purchases, row.signups)}
                </strong>
              </td>
            </tr>
          ))}
          <tr className={styles.totalRow}>
            <td className={styles.rowName}>Toutes provenances</td>
            {BREAKDOWN_COLUMNS.map((column) => (
              <td
                key={column.key}
                data-label={column.label}
                className={styles.num}
              >
                {count(total[column.key])}
              </td>
            ))}
            <td className={styles.num}>
              <span className={styles.mobileLabel}>Conversion</span>
              <strong className={styles.tableConversion}>
                {percentOf(total.purchases, total.signups)}
              </strong>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}

function emptyBreakdown(): FunnelBreakdownCounts {
  return {
    signups: 0,
    diagnosticsStarted: 0,
    diagnosticsCompleted: 0,
    paywallViewed: 0,
    subscribeClicked: 0,
    checkoutStarted: 0,
    purchases: 0,
  };
}

function sumBreakdown(
  total: FunnelBreakdownCounts,
  row: FunnelBreakdownCounts,
): FunnelBreakdownCounts {
  return {
    signups: total.signups + row.signups,
    diagnosticsStarted: total.diagnosticsStarted + row.diagnosticsStarted,
    diagnosticsCompleted: total.diagnosticsCompleted + row.diagnosticsCompleted,
    paywallViewed: total.paywallViewed + row.paywallViewed,
    subscribeClicked: total.subscribeClicked + row.subscribeClicked,
    checkoutStarted: total.checkoutStarted + row.checkoutStarted,
    purchases: total.purchases + row.purchases,
  };
}
