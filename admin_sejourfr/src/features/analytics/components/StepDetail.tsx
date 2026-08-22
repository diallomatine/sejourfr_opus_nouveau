import type { AnalyticsMetricKey, AnalyticsResponse } from "../../../types/api";
import { int, pct, rate } from "../format";
import { STEP_LABELS, STEP_PREV } from "../labels";
import styles from "../analytics.module.css";
import { BarList } from "./BarList";
import { Card, EmptyState } from "./Card";
import { DataTable, Heat, TBar, type Column } from "./DataTable";
import { Kpi } from "./Kpi";
import { LineChart } from "./LineChart";

interface StepDetailProps {
  stepKey: string;
  data: AnalyticsResponse;
  prev: AnalyticsResponse["prev"] | null;
  compare: boolean;
}

const CHARTABLE: AnalyticsMetricKey[] = [
  "v",
  "sig",
  "start",
  "prem",
  "pay",
  "revEurCents",
];

type SourceRow = AnalyticsResponse["sources"][number];

/** Ce qui se cache derriere une etape de l'entonnoir : sources, temps, pays. */
export function StepDetail({ stepKey, data, prev, compare }: StepDetailProps) {
  const key = stepKey as AnalyticsMetricKey;
  const previousKey = STEP_PREV[stepKey];
  const total = data.total;

  const sources = [...data.sources].sort((a, b) => b.m[key] - a.m[key]);
  const maxSource = Math.max(...sources.map((source) => source.m[key]), 1);

  const cols: Column<SourceRow>[] = [
    {
      key: "source",
      label: "Source",
      cell: "key",
      render: (row) => (
        <span className={styles.cellWithBar}>
          <TBar value={row.m[key]} max={maxSource} />
          {row.label}
        </span>
      ),
    },
    {
      key: "value",
      label: (STEP_LABELS[stepKey] ?? "").length > 18 ? "Volume" : STEP_LABELS[stepKey],
      cell: "strong",
      render: (row) => int(row.m[key]),
    },
    {
      key: "share",
      label: "Part",
      render: (row) => pct(rate(row.m[key], total[key]), 0),
    },
    ...(previousKey
      ? [
          {
            key: "conv",
            label: "Depuis l'étape préc.",
            render: (row: SourceRow) => (
              <Heat
                value={rate(row.m[key], row.m[previousKey])}
                base={rate(total[key], total[previousKey])}
                digits={key === "pay" ? 1 : 0}
              />
            ),
          },
        ]
      : []),
  ];

  const chartMetric = CHARTABLE.includes(key) ? key : "v";

  return (
    <>
      <section className={`${styles.card} ${styles.cardClipped}`}>
        <div className={`${styles.kpis} ${styles.kpisHalf}`}>
          <Kpi
            label="Volume sur la période"
            value={int(total[key])}
            current={total[key]}
            previous={compare && prev ? prev[key] : null}
          />
          <Kpi
            label={
              previousKey ? "Conversion depuis l'étape préc." : "Part des visiteurs"
            }
            value={
              previousKey ? pct(rate(total[key], total[previousKey]), 1) : pct(1, 0)
            }
            sub={previousKey ? STEP_LABELS[previousKey] : undefined}
          />
        </div>
      </section>

      <Card title="Répartition par source">
        {sources.length === 0 ? (
          <EmptyState>Aucune provenance mesurée sur cette période.</EmptyState>
        ) : (
          <DataTable cols={cols} rows={sources} keyOf={(row) => row.id} />
        )}
      </Card>

      <Card title="Évolution">
        <LineChart
          series={data.series}
          prevSeries={compare ? data.prevSeries : null}
          metric={chartMetric}
          height={180}
        />
        {chartMetric !== key && (
          <div className={styles.chartNote}>
            Courbe des visiteurs, pour situer l'étape dans son contexte de trafic.
          </div>
        )}
      </Card>

      <Card title="Répartition par pays">
        {data.countries.length === 0 ? (
          <EmptyState>Aucun pays mesuré sur cette période.</EmptyState>
        ) : (
          <BarList
            rows={data.countries.slice(0, 5).map((country) => ({
              id: country.id,
              label: country.label,
              value: country.v,
              sub: pct(rate(country.v, total.v), 0),
            }))}
          />
        )}
      </Card>
    </>
  );
}
