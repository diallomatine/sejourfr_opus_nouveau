import type { ReactNode } from "react";
import styles from "./StatTile.module.css";

interface StatTileProps {
  label: string;
  /** Valeur déjà formatée (`lib/format.ts`) : `—` pour l'absent, jamais 0. */
  value: string;
  /** Ligne secondaire : tendance servie, ou raison d'une valeur absente. */
  trend: ReactNode;
  /** Ton neutre (gris) ; sinon vert, réservé à une hausse servie. */
  neutral?: boolean;
  /** Ligne d'appoint discrète sous la tendance (détail servi). */
  meta?: ReactNode;
}

/** Tuile KPI des écrans de pilotage (Suivi, Activité). */
export function StatTile({ label, value, trend, neutral, meta }: StatTileProps) {
  return (
    <div className={styles.tile}>
      <div className={styles.label}>{label}</div>
      <div className={styles.value}>{value}</div>
      <div className={`${styles.trend} ${neutral ? styles.neutral : ""}`}>{trend}</div>
      {meta && <div className={styles.meta}>{meta}</div>}
    </div>
  );
}
