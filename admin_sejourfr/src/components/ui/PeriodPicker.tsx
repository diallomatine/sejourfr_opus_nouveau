import { parisToday } from "../../lib/dates";
import { PERIOD_LABELS, type PeriodId, type PeriodPatch } from "../../lib/period";
import { Segmented } from "./Segmented";
import styles from "./PeriodPicker.module.css";

interface PeriodPickerProps {
  /** Périodes offertes par l'écran, dans l'ordre d'affichage. */
  offered: readonly PeriodId[];
  period: PeriodId;
  from: string;
  to: string;
  /** Bornes servies de la vue courante : point de départ d'une plage personnalisée. */
  servedFrom: string | null;
  servedTo: string | null;
  onChange: (patch: PeriodPatch) => void;
}

/**
 * Sélecteur de période des écrans de pilotage (Suivi, Activité) : presets du
 * serveur, puis « Personnalisé » qui ouvre deux champs date. Une plage
 * inversée n'est jamais écrite (elle partirait en 400).
 */
export function PeriodPicker({
  offered,
  period,
  from,
  to,
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
