import { parisToday } from "../dates";
import {
  PERIOD_PRESETS,
  isSameChoice,
  type PeriodChoice,
} from "../period";
import styles from "./PeriodFilter.module.css";

/**
 * Filtre unique de l'écran : il pilote les DEUX sections. Un filtre par section
 * ferait comparer deux périodes différentes sans qu'on s'en aperçoive.
 */
export function PeriodFilter({
  choice,
  onChange,
}: {
  choice: PeriodChoice;
  onChange: (choice: PeriodChoice) => void;
}) {
  const today = parisToday();
  const selectedDay = choice.kind === "day" ? choice.day : "";

  return (
    <div className={styles.bar}>
      <div className={styles.presets}>
        {PERIOD_PRESETS.map((preset) => (
          <button
            key={preset.label}
            type="button"
            className={`${styles.preset} ${
              isSameChoice(preset.choice, choice) ? styles.presetActive : ""
            }`}
            onClick={() => onChange(preset.choice)}
          >
            {preset.label}
          </button>
        ))}
      </div>

      <label className={styles.dayPicker}>
        <span className={styles.dayLabel}>Un jour précis</span>
        <input
          type="date"
          className={styles.dayInput}
          value={selectedDay}
          max={today}
          onChange={(e) => {
            if (e.target.value) onChange({ kind: "day", day: e.target.value });
          }}
        />
      </label>
    </div>
  );
}
