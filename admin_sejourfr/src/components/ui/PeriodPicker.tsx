import { monthOptions, parisToday } from "../../lib/dates";
import { PERIOD_LABELS, type PeriodId, type PeriodPatch } from "../../lib/period";
import { Segmented } from "./Segmented";
import styles from "./PeriodPicker.module.css";

interface PeriodPickerProps {
  /** Périodes offertes par l'écran, dans l'ordre d'affichage. */
  offered: readonly PeriodId[];
  period: PeriodId;
  from: string;
  to: string;
  /** Mois affiché sous « Mois » (`yyyy-MM`). */
  month?: string;
  /** Bornes servies de la vue courante : point de départ d'une plage personnalisée. */
  servedFrom: string | null;
  servedTo: string | null;
  onChange: (patch: PeriodPatch) => void;
}

/**
 * Sélecteur de période des écrans de pilotage (Suivi, Activité, Productions IA) : presets du
 * serveur, puis « Personnalisé » qui ouvre deux champs date. « Mois » ouvre
 * la liste des 24 derniers mois (le mois courant par défaut). Une plage
 * inversée n'est jamais écrite (elle partirait en 400).
 */
export function PeriodPicker({
  offered,
  period,
  from,
  to,
  month,
  servedFrom,
  servedTo,
  onChange,
}: PeriodPickerProps) {
  const today = parisToday();
  const options = offered.map((id) => ({ value: id, label: PERIOD_LABELS[id] }));

  const choose = (id: PeriodId) => {
    if (id !== "custom") {
      onChange({ period: id });
      return;
    }
    onChange({ period: "custom", from: servedFrom ?? today, to: servedTo ?? today });
  };

  return (
    <div className={styles.picker}>
      <Segmented options={options} value={period} onChange={choose} label="Période" />
      {period === "month" && month && (
        <div className={styles.range}>
          <label className={styles.dateLabel}>
            Mois{" "}
            <select
              className={styles.dateInput}
              value={month}
              onChange={(event) => onChange({ period: "month", month: event.target.value })}
            >
              {monthOptions(month).map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </label>
        </div>
      )}
      {period === "custom" && (
        <div className={styles.range}>
          <label className={styles.dateLabel}>
            Du{" "}
            <input
              type="date"
              className={styles.dateInput}
              value={from}
              max={to || today}
              onChange={(event) => {
                const value = event.target.value;
                if (value && value <= to) onChange({ from: value });
              }}
            />
          </label>
          <label className={styles.dateLabel}>
            au{" "}
            <input
              type="date"
              className={styles.dateInput}
              value={to}
              min={from}
              max={today}
              onChange={(event) => {
                const value = event.target.value;
                if (value && value >= from) onChange({ to: value });
              }}
            />
          </label>
        </div>
      )}
    </div>
  );
}
