import { useState } from "react";
import type {
  AnalyticsAnnotation,
  AnalyticsMetricKey,
  AnalyticsSeriesPoint,
} from "../../../types/api";
import { formatDay } from "../dates";
import { int, money0 } from "../format";
import { CHART_METRICS } from "../labels";
import styles from "../analytics.module.css";
import { EmptyState } from "./Card";
import { useWidth } from "./useWidth";

interface LineChartProps {
  series: AnalyticsSeriesPoint[];
  prevSeries?: AnalyticsSeriesPoint[] | null;
  metric: AnalyticsMetricKey;
  annotations?: AnalyticsAnnotation[];
  height?: number;
}

/**
 * Courbe temporelle, en SVG ecrit a la main : ce projet n'embarque aucune
 * librairie de graphes. Les intervalles `empty` (heures a venir) sont SAUTES,
 * jamais traces a zero — un zero se lirait comme une chute.
 */
export function LineChart({
  series,
  prevSeries,
  metric,
  annotations,
  height = 260,
}: LineChartProps) {
  const [ref, width] = useWidth();
  const [hover, setHover] = useState<number | null>(null);

  const pad = { l: 52, r: 16, t: 18, b: 26 };
  const isMoney = metric === "revEurCents";
  const values = series.map((point) => (point.empty ? null : point.m[metric]));
  const prevValues = prevSeries
    ? prevSeries.map((point) => (point.empty ? null : point.m[metric]))
    : [];
  const withPrev = Boolean(prevSeries && prevSeries.length);

  const measured = values.filter((value): value is number => value != null);
  const hasData = measured.some((value) => value > 0);

  const all = [...measured, ...(withPrev ? prevValues : [])].filter(
    (value): value is number => value != null,
  );
  const max = Math.max(...all, 1) * 1.18;
  const count = series.length;
  const innerWidth = Math.max(120, width - pad.l - pad.r);
  const innerHeight = height - pad.t - pad.b;

  const x = (index: number) =>
    pad.l + (count <= 1 ? innerWidth / 2 : (index * innerWidth) / (count - 1));
  const y = (value: number) => pad.t + innerHeight - (value / max) * innerHeight;

  const path = (points: (number | null)[]) =>
    points.reduce<string>(
      (acc, value, index) =>
        value == null
          ? acc
          : `${acc}${acc ? " L" : "M"}${x(index).toFixed(1)} ${y(value).toFixed(1)}`,
      "",
    );

  const line = path(values);
  const lastIndex = values.reduce<number>(
    (acc, value, index) => (value != null ? index : acc),
    0,
  );
  const area = line
    ? `${line} L${x(lastIndex).toFixed(1)} ${(pad.t + innerHeight).toFixed(1)} L${x(0).toFixed(1)} ${(pad.t + innerHeight).toFixed(1)} Z`
    : "";

  const ticks = [0, max / 2, max];
  const formatValue = (value: number) => (isMoney ? money0(value) : int(value));
  const labelIndexes =
    count <= 8
      ? series.map((_, index) => index)
      : [0, Math.round((count - 1) / 3), Math.round((2 * (count - 1)) / 3), count - 1];

  const marks = (annotations ?? [])
    .map((annotation, order) => {
      const index = series.findIndex(
        (point) =>
          (point.iso && point.iso === annotation.iso) ||
          (point.iso &&
            point.isoEnd &&
            annotation.iso >= point.iso &&
            annotation.iso <= point.isoEnd),
      );
      return index < 0 ? null : { ...annotation, index, order: order + 1 };
    })
    .filter((mark): mark is AnalyticsAnnotation & { index: number; order: number } =>
      Boolean(mark),
    );

  if (!hasData) {
    return (
      <EmptyState>
        Aucune mesure sur cette période — la courbe reste vide plutôt que de
        dessiner une ligne à zéro.
      </EmptyState>
    );
  }

  const onMove = (event: React.MouseEvent<SVGSVGElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const offset = event.clientX - rect.left;
    let index = Math.round(((offset - pad.l) / (innerWidth || 1)) * (count - 1));
    index = Math.max(0, Math.min(count - 1, index));
    setHover(values[index] == null ? null : index);
  };

  const metricLabel =
    CHART_METRICS.find((entry) => entry.id === metric)?.label ?? "Mesure";

  return (
    <div className={styles.chartWrap} ref={ref}>
      <svg
        width="100%"
        height={height}
        className={styles.chartSvg}
        onMouseMove={onMove}
        onMouseLeave={() => setHover(null)}
        role="img"
        aria-label={`Évolution — ${metricLabel}`}
      >
        <defs>
          <linearGradient id="analyticsFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--blue)" stopOpacity=".18" />
            <stop offset="100%" stopColor="var(--blue)" stopOpacity="0" />
          </linearGradient>
        </defs>

        {ticks.map((tick) => (
          <g key={tick}>
            <line
              x1={pad.l}
              x2={pad.l + innerWidth}
              y1={y(tick)}
              y2={y(tick)}
              stroke="var(--rule-2)"
              strokeWidth="1"
            />
            <text
              x={pad.l - 10}
              y={y(tick) + 4}
              textAnchor="end"
              fontSize="11"
              fill="var(--muted-2)"
            >
              {formatValue(tick)}
            </text>
          </g>
        ))}

        {marks.map((mark) => (
          <g key={`${mark.iso}-${mark.order}`}>
            <line
              x1={x(mark.index)}
              x2={x(mark.index)}
              y1={pad.t - 6}
              y2={pad.t + innerHeight}
              stroke="var(--muted-2)"
              strokeWidth="1"
              strokeDasharray="2 4"
              opacity=".7"
            />
            <circle
              cx={x(mark.index)}
              cy={pad.t - 9}
              r="7.5"
              fill="var(--surface)"
              stroke="var(--rule)"
            />
            <text
              x={x(mark.index)}
              y={pad.t - 5.5}
              textAnchor="middle"
              fontSize="9.5"
              fontWeight="700"
              fill="var(--muted)"
            >
              {mark.order}
            </text>
          </g>
        ))}

        {withPrev && (
          <path
            d={path(prevValues)}
            fill="none"
            stroke="var(--muted-2)"
            strokeWidth="1.5"
            strokeDasharray="4 4"
            opacity=".7"
          />
        )}
        {area && <path d={area} fill="url(#analyticsFill)" />}
        <path
          d={line}
          fill="none"
          stroke="var(--blue)"
          strokeWidth="2.2"
          strokeLinejoin="round"
          strokeLinecap="round"
        />

        {labelIndexes.map((index) => (
          <text
            key={index}
            x={x(index)}
            y={height - 6}
            textAnchor={index === 0 ? "start" : index === count - 1 ? "end" : "middle"}
            fontSize="11"
            fill="var(--muted-2)"
          >
            {series[index]?.short || series[index]?.label}
          </text>
        ))}

        {hover != null && values[hover] != null && (
          <g>
            <line
              x1={x(hover)}
              x2={x(hover)}
              y1={pad.t}
              y2={pad.t + innerHeight}
              stroke="var(--blue)"
              strokeWidth="1"
              opacity=".35"
            />
            <circle
              cx={x(hover)}
              cy={y(values[hover] as number)}
              r="4.5"
              fill="var(--surface)"
              stroke="var(--blue)"
              strokeWidth="2.2"
            />
          </g>
        )}
      </svg>

      {hover != null && values[hover] != null && (
        <div
          className={styles.tip}
          style={{
            left: Math.min(Math.max(x(hover) - 66, 4), Math.max(4, width - 150)),
            top: Math.max(4, y(values[hover] as number) - 74),
          }}
        >
          <b>{series[hover].label}</b>
          <div className={styles.tipRow}>
            <span>{metricLabel}</span>
            <strong>{formatValue(values[hover] as number)}</strong>
          </div>
          {withPrev && prevValues[hover] != null && (
            <div className={`${styles.tipRow} ${styles.tipRowPrev}`}>
              <span>Période préc.</span>
              <span>{formatValue(prevValues[hover] as number)}</span>
            </div>
          )}
        </div>
      )}

      {(marks.length > 0 || withPrev) && (
        <div className={styles.legend}>
          <span>
            <i />
            Période sélectionnée
          </span>
          {withPrev && (
            <span>
              <i className={styles.dash} />
              Période précédente
            </span>
          )}
          {marks.map((mark) => (
            <span key={`legend-${mark.iso}-${mark.order}`} className={styles.legendMark}>
              <b>{mark.order}</b> {formatDay(mark.iso)} · {mark.label}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
