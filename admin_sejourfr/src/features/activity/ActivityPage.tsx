import { PeriodPicker } from "../../components/ui/PeriodPicker";
import { Spinner } from "../../components/ui/Spinner";
import { formatRange } from "../../lib/dates";
import { ActivityKpis } from "./components/ActivityKpis";
import { DailyPanel } from "./components/DailyPanel";
import { LiveActivityCard } from "./components/LiveActivityCard";
import { PlatformPanel } from "./components/PlatformPanel";
import { ScreensPanel } from "./components/ScreensPanel";
import { useActivity } from "./useActivity";
import { ACTIVITY_PERIODS, useActivityParams } from "./useActivityParams";
import styles from "./activity.module.css";

/**
 * Écran « Activité » (route `/dashboard/activity`) : un appel pour la période
 * (`useActivity`), plus le direct relu toutes les 30 s. Agrégats seulement —
 * aucun nom ni email. Les bornes affichées sont celles SERVIES.
 */
export function ActivityPage() {
  const { period, from, to, month, query, update } = useActivityParams();
  const { data, error, isPending, isPlaceholderData } = useActivity(query);

  return (
    <div className={styles.root}>
      <div className={styles.topbar}>
        <div>
          <h1 className={styles.title}>Activité</h1>
          <p className={styles.subtitle}>
            Qui utilise SejourFR, sur quelle plateforme, et quels écrans sont consultés.
          </p>
          {data && (
            <p className={styles.period}>
              {formatRange(data.window.from, data.window.to)} · heure de Paris
            </p>
          )}
        </div>
        <div className={styles.filters}>
          <PeriodPicker
            offered={ACTIVITY_PERIODS}
            period={period}
            from={from}
            to={to}
            month={month}
            servedFrom={data?.window.from ?? null}
            servedTo={data?.window.to ?? null}
            onChange={update}
          />
          <label className={styles.check}>
            <input
              type="checkbox"
              checked={query.includeInternal}
              onChange={(event) => update({ includeInternal: event.target.checked })}
            />
            Inclure internes
          </label>
        </div>
      </div>

      <LiveActivityCard includeInternal={query.includeInternal} variant="full" />

      {error && (
        <div className={styles.error} role="alert">
          Impossible de charger l’activité : {error.message}
        </div>
      )}

      {isPending && !data && <Spinner label="Chargement de l’activité…" />}

      {data && (
        <div className={isPlaceholderData ? styles.stale : ""}>
          <ActivityKpis data={data} />
          <PlatformPanel data={data} />
          <DailyPanel data={data} />
          <ScreensPanel data={data} />
        </div>
      )}
    </div>
  );
}
