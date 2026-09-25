import type { ReactNode } from "react";
import type { AdminSuiviResponse, SuiviIndicator, SuiviKpi } from "../../../types/api";
import { DASH, int, money, pct, signedPct } from "../format";
import { comparedTo } from "../labels";
import { unmeasuredNote } from "../measurement";
import styles from "../suivi.module.css";

interface KpiCardProps {
  label: string;
  value: string;
  trend: ReactNode;
  neutral?: boolean;
}

function KpiCard({ label, value, trend, neutral }: KpiCardProps) {
  return (
    <div className={`${styles.card} ${styles.kpi}`}>
      <div className={styles.kpiLabel}>{label}</div>
      <div className={styles.kpiValue}>{value}</div>
      <div className={`${styles.trend} ${neutral ? styles.trendNeutral : ""}`}>{trend}</div>
    </div>
  );
}

/**
 * Ligne secondaire d'un KPI. Valeur inconnue : on dit pourquoi, jamais un
 * ratio ni une tendance calcules sur du vide.
 */
function secondary(
  data: AdminSuiviResponse,
  kpi: SuiviKpi,
  indicator: SuiviIndicator,
  text: string | null,
): { trend: string; neutral: boolean } {
  if (kpi.value == null) return { trend: unmeasuredNote(data, indicator), neutral: true };
  if (text == null) return { trend: DASH, neutral: true };
  return { trend: text, neutral: false };
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
      <KpiCard
        label="Visiteurs uniques"
        value={int(visitors.value)}
        trend={visitorsLine.trend}
        neutral={visitorsLine.neutral || (visitors.deltaPct ?? 0) <= 0}
      />
      <KpiCard
        label="Diagnostics soumis"
        value={int(submitted.value)}
        trend={submittedLine.trend}
        neutral={submittedLine.neutral}
      />
      <KpiCard
        label="Achats"
        value={int(purchases.value)}
        trend={purchasesLine.trend}
        neutral
      />
      <KpiCard
        label="Net réel estimé"
        value={money(netExVatCents.value)}
        trend={netLine.trend}
        neutral={netLine.neutral}
      />
    </section>
  );
}
