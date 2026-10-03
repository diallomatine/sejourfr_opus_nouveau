import { StatTile } from "../../../components/ui/StatTile";
import type { AdminSuiviResponse, SuiviIndicator, SuiviKpi } from "../../../types/api";
import { DASH, int, money, pct, signedPct } from "../../../lib/format";
import { comparedTo } from "../../../lib/period";
import { measuredSinceNote, unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";

/**
 * Ligne secondaire d'un KPI. Valeur inconnue : on dit pourquoi, jamais un
 * ratio ni une tendance calcules sur du vide. Periode a cheval sur la date de
 * debut de mesure : la valeur part de cette date, on le dit (D117).
 */
function secondary(
  data: AdminSuiviResponse,
  kpi: SuiviKpi,
  indicator: SuiviIndicator,
  text: string | null,
): { trend: string; neutral: boolean } {
  if (kpi.value == null) return { trend: unmeasuredNote(data, indicator), neutral: true };
  const since = measuredSinceNote(data, indicator);
  if (text == null) return { trend: since ?? DASH, neutral: true };
  return { trend: since == null ? text : `${text} · ${since}`, neutral: false };
}

export function KpiGrid({ data }: { data: AdminSuiviResponse }) {
  const { visitors, submitted, purchases, netExVatCents } = data.kpis;

  const visitorsLine = secondary(
    data,
    visitors,
    "VISITORS",
    visitors.deltaPct == null
      ? null
      : `${signedPct(visitors.deltaPct)} ${comparedTo(data.window.preset)}`,
  );
  const submittedLine = secondary(
    data,
    submitted,
    "DIAGNOSTIC_SUBMITTED",
    submitted.ratioPct == null ? null : `${pct(submitted.ratioPct)} des visiteurs`,
  );
  const purchasesLine = secondary(
    data,
    purchases,
    "PURCHASES",
    purchases.ratioPct == null ? null : `${pct(purchases.ratioPct)} des diagnostics`,
  );
  const netLine = secondary(data, netExVatCents, "REVENUE_BREAKDOWN", "après TVA et frais");

  return (
    <section className={styles.gridKpi}>
      <StatTile
        label="Visiteurs uniques"
        value={int(visitors.value)}
        trend={visitorsLine.trend}
        neutral={visitorsLine.neutral || (visitors.deltaPct ?? 0) <= 0}
      />
      <StatTile
        label="Diagnostics soumis"
        value={int(submitted.value)}
        trend={submittedLine.trend}
        neutral={submittedLine.neutral}
      />
      <StatTile
        label="Achats"
        value={int(purchases.value)}
        trend={purchasesLine.trend}
        neutral
      />
      <StatTile
        label="Net réel estimé"
        value={money(netExVatCents.value)}
        trend={netLine.trend}
        neutral={netLine.neutral}
      />
    </section>
  );
}
