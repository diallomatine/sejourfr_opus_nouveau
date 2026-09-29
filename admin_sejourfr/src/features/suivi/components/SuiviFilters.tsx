import type { SuiviPlatformFilter, SuiviTypeFilter } from "../../../types/api";
import { parisToday } from "../dates";
import { PLATFORM_OPTIONS, TYPE_OPTIONS, sourceLabel } from "../labels";
import { PERIOD_OPTIONS, type PeriodId, type SuiviPatch } from "../useSuiviParams";
import styles from "../suivi.module.css";

interface SuiviFiltersProps {
  period: PeriodId;
  from: string;
  to: string;
  type: SuiviTypeFilter;
  platform: SuiviPlatformFilter;
  source: string;
  includeInternal: boolean;
  availableSources: string[];
  /** Bornes servies de la vue courante : point de depart d'une plage personnalisee. */
  servedFrom: string | null;
  servedTo: string | null;
  onChange: (patch: SuiviPatch) => void;
}

/**
 * Les deux segmented du template (periode, type), puis une ligne discrete pour
 * les filtres du brief absents du template : plateforme, source, internes.
 */
export function SuiviFilters(props: SuiviFiltersProps) {
  const { period, from, to, onChange } = props;
  const today = parisToday();

  const choosePeriod = (id: PeriodId) => {
    if (id !== "custom") {
      onChange({ period: id });
      return;
    }
    const start = props.servedFrom ?? today;
    const end = props.servedTo ?? today;
    onChange({ period: "custom", from: start, to: end });
  };

  return (
    <div className={styles.filters}>
      <div className={styles.filterRow}>
        <div className={styles.segmented} role="group" aria-label="Période">
          {PERIOD_OPTIONS.map((option) => (
            <button
              key={option.id}
              type="button"
              aria-pressed={period === option.id}
              onClick={() => choosePeriod(option.id)}
            >
              {option.label}
            </button>
          ))}
        </div>
        <div className={styles.segmented} role="group" aria-label="Type de diagnostic">
          {TYPE_OPTIONS.map((option) => (
            <button
              key={option.id}
              type="button"
              aria-pressed={props.type === option.id}
              onClick={() => onChange({ type: option.id })}
            >
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {period === "custom" && (
        <div className={styles.filterRow}>
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

      <div className={styles.filterRow}>
        <select
          className={styles.select}
          aria-label="Plateforme"
          value={props.platform}
          onChange={(event) =>
            onChange({ platform: event.target.value as SuiviPlatformFilter })
          }
        >
          {PLATFORM_OPTIONS.map((option) => (
            <option key={option.id} value={option.id}>
              {option.label}
            </option>
          ))}
        </select>
        <select
          className={styles.select}
          aria-label="Source"
          value={props.source}
          onChange={(event) => onChange({ source: event.target.value })}
        >
          <option value="ALL">Toutes sources</option>
          {props.availableSources.map((group) => (
            <option key={group} value={group}>
              {sourceLabel(group)}
            </option>
          ))}
          {props.source !== "ALL" && !props.availableSources.includes(props.source) && (
            <option value={props.source}>{sourceLabel(props.source)}</option>
          )}
        </select>
        <label className={styles.check}>
          <input
            type="checkbox"
            checked={props.includeInternal}
            onChange={(event) => onChange({ includeInternal: event.target.checked })}
          />
          Inclure internes
        </label>
      </div>
    </div>
  );
}
