import type { ReactNode } from "react";
import { barWidth, int } from "../format";
import styles from "../analytics.module.css";

export interface BarListRow {
  id: string;
  label: string;
  value: number;
  sub?: ReactNode;
  right?: ReactNode;
}

interface BarListProps {
  rows: BarListRow[];
  onRow?: (row: BarListRow) => void;
  format?: (value: number) => string;
}

export function BarList({ rows, onRow, format }: BarListProps) {
  const max = Math.max(...rows.map((row) => row.value), 1);
  const render = format ?? int;

  return (
    <div className={styles.barList}>
      {rows.map((row) => {
        const body = (
          <>
            <div className={styles.barRowTop}>
              <span>{row.label}</span>
              {row.sub && <span className={styles.barRowSub}>{row.sub}</span>}
            </div>
            <div className={styles.barRowVal}>
              {render(row.value)}
              {row.right && (
                <span className={styles.barRowRight}>{row.right}</span>
              )}
            </div>
            <div className={styles.barTrack}>
              <i style={{ width: barWidth(row.value, max) }} />
            </div>
          </>
        );

        const className = `${styles.barRow} ${onRow ? styles.barRowClickable : ""}`;

        return onRow ? (
          <button
            key={row.id}
            type="button"
            className={className}
            onClick={() => onRow(row)}
          >
            {body}
          </button>
        ) : (
          <div key={row.id} className={className}>
            {body}
          </div>
        );
      })}
    </div>
  );
}
