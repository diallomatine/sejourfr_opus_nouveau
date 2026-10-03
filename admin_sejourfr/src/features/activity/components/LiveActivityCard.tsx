import { Link } from "react-router-dom";
import { formatParisTime, parisDay } from "../../../lib/dates";
import { DASH, count, int } from "../../../lib/format";
import { unmeasuredNote } from "../../../lib/measurement";
import type { AdminActivityLiveResponse } from "../../../types/api";
import { useActivityLive } from "../useActivity";
import styles from "../activity.module.css";

interface LiveActivityCardProps {
  includeInternal: boolean;
  /** `compact` : carte légère de Suivi, avec lien vers l'écran Activité. */
  variant: "compact" | "full";
}

/** « 180 » → « 3 min » ; mise en forme de la fenêtre SERVIE, jamais une valeur en dur. */
function windowLabel(seconds: number): string {
  return seconds % 60 === 0 ? `${seconds / 60}${" "}min` : `${seconds}${" "}s`;
}

function liveNote(data: AdminActivityLiveResponse): string {
  return unmeasuredNote(data.measurementStart, parisDay(data.at));
}

/**
 * Comptes connectés actifs depuis moins de `windowSeconds` (servi), relus
 * toutes les 30 s. Le total servi fait foi : les lignes par plateforme ne s'y
 * additionnent pas (un compte peut être en ligne sur deux plateformes).
 */
export function LiveActivityCard({ includeInternal, variant }: LiveActivityCardProps) {
  const { data, error, isPending } = useActivityLive(includeInternal);
  const compact = variant === "compact";
  const rows = data?.byPlatform.filter((row) => row.displayed) ?? [];

  return (
    <section
      className={`${styles.card} ${styles.live} ${compact ? styles.liveCompact : ""}`}
      aria-label={compact ? "Actifs maintenant" : "En ligne maintenant"}
    >
      <div className={styles.liveMain}>
        <div className={styles.liveTitle}>
          <span className={styles.livePulse} aria-hidden="true" />
          {compact ? "Actifs maintenant" : "En ligne maintenant"}
        </div>
        <div className={styles.liveValue}>
          {data ? int(data.total) : DASH}
          {data && data.total == null && (
            <span className={styles.unmeasured}> {liveNote(data)}</span>
          )}
        </div>
        <div className={styles.liveSub}>
          {data
            ? `activité depuis moins de ${windowLabel(data.windowSeconds)} · relevé à ${formatParisTime(data.at)}`
            : isPending
              ? "Chargement…"
              : DASH}
        </div>
        {error && (
          <div className={styles.liveError} role="alert">
            Direct indisponible : {error.message}
          </div>
        )}
      </div>

      {(data || compact) && (
        <div className={styles.liveSide}>
          {rows.length > 0 && (
            <ul className={styles.livePlatforms}>
              {rows.map((row) => (
                <li key={row.platform}>
                  <span>{row.label}</span>
                  <strong>{int(row.value)}</strong>
                </li>
              ))}
            </ul>
          )}
          {!compact && data?.multiPlatformUsers != null && data.multiPlatformUsers > 0 && (
            <p className={styles.note}>
              Dont {count(data.multiPlatformUsers, "compte", "comptes")} sur plusieurs
              plateformes : les lignes ne s’additionnent pas au total.
            </p>
          )}
          {compact && (
            <Link
              className={styles.liveLink}
              to={includeInternal ? "/dashboard/activity?internal=1" : "/dashboard/activity"}
            >
              Voir l’activité →
            </Link>
          )}
        </div>
      )}
    </section>
  );
}
