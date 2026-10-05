import { PeriodPicker } from "../../../components/ui/PeriodPicker";
import { Segmented } from "../../../components/ui/Segmented";
import type { PeriodId } from "../../../lib/period";
import type { SuiviPlatformFilter, SuiviTypeFilter } from "../../../types/api";
import { PLATFORM_OPTIONS, TYPE_OPTIONS, sourceLabel } from "../labels";
import { SUIVI_PERIODS, type SuiviPatch } from "../useSuiviParams";
import styles from "../suivi.module.css";

interface SuiviFiltersProps {
  period: PeriodId;
  from: string;
  to: string;
  month: string;
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
  const { onChange } = props;

  return (
    <div className={styles.filters}>
      <PeriodPicker
        offered={SUIVI_PERIODS}
        period={props.period}
        from={props.from}
        to={props.to}
        month={props.month}
        servedFrom={props.servedFrom}
        servedTo={props.servedTo}
        onChange={onChange}
      />
      <div className={styles.filterRow}>
        <Segmented
          options={TYPE_OPTIONS}
          value={props.type}
          onChange={(type) => onChange({ type })}
          label="Type de diagnostic"
        />
      </div>

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
