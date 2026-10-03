import { StatTile } from "../../../components/ui/StatTile";
import { DASH, count, int, signedPct } from "../../../lib/format";
import { comparedTo } from "../../../lib/period";
import type { ActivityIndicator, ActivityKpi, AdminActivityResponse } from "../../../types/api";
import { activityMeasuredSince, activityUnmeasured } from "../notes";
import styles from "../activity.module.css";

/**
 * Ligne secondaire d'un KPI : tendance SERVIE, ou raison de l'absence. Une
 * période à cheval sur la date de début de mesure le dit (D117).
 */
function trendLine(
  data: AdminActivityResponse,
  kpi: ActivityKpi,
  indicator: ActivityIndicator,
  measuredSince: string | null,
): { trend: string; neutral: boolean } {
  if (kpi.value == null) return { trend: activityUnmeasured(data, indicator), neutral: true };
  const since = activityMeasuredSince(data, measuredSince);
  const deltaPct = kpi.deltaPct;
  if (deltaPct == null) return { trend: since ?? DASH, neutral: true };
  const delta = `${signedPct(deltaPct)} ${comparedTo(data.window.preset)}`;
  return { trend: since == null ? delta : `${delta} · ${since}`, neutral: deltaPct <= 0 };
}

export function ActivityKpis({ data }: { data: AdminActivityResponse }) {
  const { activeUsers, logins } = data;
  const active = trendLine(data, activeUsers.total, "ACTIVE_USERS", activeUsers.measuredSince);
  const loggedIn = trendLine(data, logins.uniqueUsers, "LOGINS", logins.measuredSince);

  return (
    <section className={styles.kpis}>
      <StatTile
        label="Utilisateurs actifs"
        value={int(activeUsers.total.value)}
        trend={active.trend}
        neutral={active.neutral}
        meta="Comptes uniques ayant utilisé l’application ou le site."
      />
      <StatTile
        label="Utilisateurs connectés"
        value={int(logins.uniqueUsers.value)}
        trend={loggedIn.trend}
        neutral={loggedIn.neutral}
        meta={
          logins.total == null
            ? "Comptes uniques ayant ouvert une session."
            : `${count(logins.total, "connexion", "connexions")} · dont ${count(
                logins.signups,
                "inscription",
                "inscriptions",
              )}`
        }
      />
    </section>
  );
}
