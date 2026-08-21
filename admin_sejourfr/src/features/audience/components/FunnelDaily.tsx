import type { FunnelDailyStat } from "../../../types/api";
import { fillDays } from "../dates";
import { DailyChart } from "./DailyChart";
import panels from "./panels.module.css";

/** Chaque compte est compté au jour de son inscription, jamais au jour de l'étape. */
export function FunnelDaily({
  daily,
  from,
  to,
}: {
  daily: FunnelDailyStat[];
  from: string;
  to: string;
}) {
  const series = fillDays(daily, from, to, (day) => ({
    day,
    signups: 0,
    diagnosticsStarted: 0,
    diagnosticsCompleted: 0,
    purchases: 0,
  }));

  if (series.length === 0) {
    return (
      <p className={panels.note}>
        Aucun jour à afficher sur cette fenêtre.
      </p>
    );
  }

  return (
    <DailyChart
      days={series.map((d) => d.day)}
      series={[
        {
          key: "signups",
          label: "Inscriptions",
          tone: "soft",
          values: series.map((d) => d.signups),
        },
        {
          key: "diagnosticsCompleted",
          label: "Diagnostics terminés",
          tone: "mid",
          values: series.map((d) => d.diagnosticsCompleted),
        },
        {
          key: "purchases",
          label: "Paiements",
          tone: "success",
          values: series.map((d) => d.purchases),
        },
      ]}
    />
  );
}
