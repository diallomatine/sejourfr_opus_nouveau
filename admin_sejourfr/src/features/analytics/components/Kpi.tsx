import type { ReactNode } from "react";
import styles from "../analytics.module.css";
import { Delta } from "./Delta";

interface SparklineProps {
  values: (number | null)[];
}

/** Micro-courbe d'un KPI. Sous deux points mesures, on ne dessine rien. */
export function Sparkline({ values }: SparklineProps) {
  const points = values.filter((value): value is number => value != null);
  if (points.length < 2) return <div className={styles.spark} />;

  const height = 26;
  const width = 120;
  const max = Math.max(...points);
  const min = Math.min(...points, 0);
  const span = max - min || 1;

  const coords = points.map((value, index) => [
    index * (width / (points.length - 1)),
    height - 2 - ((value - min) / span) * (height - 6),
  ]);
  const line = coords
    .map((p, i) => `${i ? "L" : "M"}${p[0].toFixed(1)} ${p[1].toFixed(1)}`)
    .join(" ");

  return (
    <svg
      className={styles.spark}
      viewBox={`0 0 ${width} ${height}`}
      width="100%"
      height={height}
      preserveAspectRatio="none"
      aria-hidden="true"
    >
      <path d={`${line} L${width} ${height} L0 ${height} Z`} fill="var(--blue)" opacity=".08" />
      <path
        d={line}
        fill="none"
        stroke="var(--blue)"
        strokeWidth="1.6"
        strokeLinejoin="round"
        strokeLinecap="round"
        vectorEffect="non-scaling-stroke"
      />
    </svg>
  );
}

interface KpiProps {
  label: string;
  value: string;
  current?: number;
  previous?: number | null;
  invert?: boolean;
  sub?: ReactNode;
  note?: ReactNode;
  spark?: (number | null)[];
  mini?: boolean;
  onClick?: () => void;
}

export function Kpi({
  label,
  value,
  current,
  previous,
  invert,
  sub,
  note,
  spark,
  mini,
  onClick,
}: KpiProps) {
  const className = `${styles.kpi} ${mini ? styles.kpiMini : ""} ${
    onClick ? styles.kpiButton : ""
  }`;

  const body = (
    <>
      <div className={styles.lbl}>{label}</div>
      <div className={styles.kpiValue}>
        <span className={styles.num}>{value}</span>
        {current != null && (
          <Delta current={current} previous={previous} invert={invert} />
        )}
      </div>
      {sub && <div className={styles.kpiSub}>{sub}</div>}
      {note && <div className={styles.kpiNote}>{note}</div>}
      {spark && <Sparkline values={spark} />}
    </>
  );

  if (onClick) {
    return (
      <button type="button" className={className} onClick={onClick}>
        {body}
      </button>
    );
  }
  return <div className={className}>{body}</div>;
}
