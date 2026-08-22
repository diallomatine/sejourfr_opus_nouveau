import type { ReactNode } from "react";
import { barWidth, pct } from "../format";
import styles from "../analytics.module.css";

export interface Column<T> {
  key: string;
  label: string;
  /** Colonne secondaire, masquee sous 860 px plutot que de comprimer la table. */
  hideSmall?: boolean;
  cell?: "key" | "strong";
  render: (row: T) => ReactNode;
}

interface DataTableProps<T> {
  cols: Column<T>[];
  rows: T[];
  keyOf: (row: T) => string;
  onRow?: (row: T) => void;
  foot?: Record<string, ReactNode>;
}

export function DataTable<T>({
  cols,
  rows,
  keyOf,
  onRow,
  foot,
}: DataTableProps<T>) {
  const cellClass = (col: Column<T>) =>
    [
      col.cell === "key" ? styles.cellKey : "",
      col.cell === "strong" ? styles.cellStrong : "",
      col.hideSmall ? styles.hideSmall : "",
    ]
      .filter(Boolean)
      .join(" ");

  return (
    <div className={styles.tableWrap}>
      <table className={styles.table}>
        <thead>
          <tr>
            {cols.map((col) => (
              <th key={col.key} className={col.hideSmall ? styles.hideSmall : ""}>
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={keyOf(row)}
              className={onRow ? styles.rowClickable : ""}
              onClick={onRow ? () => onRow(row) : undefined}
            >
              {cols.map((col) => (
                <td key={col.key} className={cellClass(col)}>
                  {col.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
        {foot && (
          <tfoot>
            <tr>
              {cols.map((col) => (
                <td key={col.key} className={col.hideSmall ? styles.hideSmall : ""}>
                  {foot[col.key] ?? ""}
                </td>
              ))}
            </tr>
          </tfoot>
        )}
      </table>
    </div>
  );
}

/** Barre de volume glissee dans une cellule : le classement se lit d'un coup. */
export function TBar({ value, max }: { value: number; max: number }) {
  return (
    <span className={styles.tbar}>
      <i style={{ width: barWidth(value, max, 2) }} />
    </span>
  );
}

/**
 * Pastille de conversion : l'intensite dit la qualite RELATIVE a la moyenne de
 * la periode. Un taux sans reference ne veut rien dire, d'ou `base`.
 * `value` a `null` (base nulle) rend un tiret, jamais un « 0,0 % ».
 */
export function Heat({
  value,
  base,
  digits = 2,
}: {
  value: number | null;
  base: number | null;
  digits?: number;
}) {
  if (value == null || base == null || base <= 0) {
    return <span className={styles.heat}>{pct(value, digits)}</span>;
  }

  const ratio = Math.min(2.2, value / base);
  const strong = ratio > 1.25;
  const weak = ratio < 0.6 && value > 0;
  const tone = strong ? styles.heatStrong : weak ? styles.heatWeak : "";

  return (
    <span className={`${styles.heat} ${tone}`}>{pct(value, digits)}</span>
  );
}
