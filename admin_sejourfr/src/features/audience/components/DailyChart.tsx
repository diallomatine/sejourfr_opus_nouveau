import { formatDay } from "../dates";
import styles from "./DailyChart.module.css";

export type ChartTone = "soft" | "mid" | "strong" | "success";

export interface ChartSeries {
  key: string;
  label: string;
  tone: ChartTone;
  /** Une valeur par jour, même longueur et même ordre que `days`. */
  values: number[];
}

/**
 * Barres verticales maison — aucune librairie de graphes dans ce projet.
 * Les séries se superposent : elles doivent être emboîtées (la première
 * englobe les suivantes), ce qui est le cas d'un entonnoir.
 */
export function DailyChart({
  days,
  series,
}: {
  days: string[];
  series: ChartSeries[];
}) {
  const max = series.reduce(
    (m, s) => s.values.reduce((inner, v) => Math.max(inner, v), m),
    0,
  );
  const first = days[0];
  const last = days[days.length - 1];

  if (days.length === 0) {
    return <p className={styles.empty}>Aucun jour à afficher.</p>;
  }

  return (
    <div className={styles.wrap}>
      <div className={styles.chart}>
        {days.map((day, index) => (
          <span
            key={day}
            className={styles.col}
            title={`${formatDay(day)} — ${series
              .map((s) => `${s.values[index] ?? 0} ${s.label.toLowerCase()}`)
              .join(", ")}`}
          >
            {series.map((s) => (
              <i
                key={s.key}
                className={`${styles.bar} ${styles[s.tone]}`}
                style={{
                  height:
                    max > 0 ? `${((s.values[index] ?? 0) * 100) / max}%` : "0%",
                }}
              />
            ))}
          </span>
        ))}
      </div>

      {/* Une seule journée : un axe à deux bornes identiques n'apprendrait rien. */}
      <div
        className={`${styles.axis} ${days.length === 1 ? styles.axisSingle : ""}`}
      >
        <span>{formatDay(first)}</span>
        {days.length > 1 && <span>{formatDay(last)}</span>}
      </div>

      <ul className={styles.legend}>
        {series.map((s) => (
          <li key={s.key}>
            <i className={`${styles.swatch} ${styles[s.tone]}`} />
            {s.label}
          </li>
        ))}
      </ul>
    </div>
  );
}
