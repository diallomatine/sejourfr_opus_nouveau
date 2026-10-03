import { useState } from "react";
import { Collapsible } from "../../../components/ui/Collapsible";
import { Panel } from "../../../components/ui/Panel";
import tableStyles from "../../../components/ui/DataTable.module.css";
import { dayMonth } from "../../../lib/dates";
import { count, int } from "../../../lib/format";
import type { ActivityDailyPoint, AdminActivityResponse } from "../../../types/api";
import { activityUnmeasured } from "../notes";
import styles from "../activity.module.css";

function weekday(day: string): string {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date)).toLocaleDateString("fr-FR", {
    weekday: "short",
    timeZone: "UTC",
  });
}

function readout(point: ActivityDailyPoint, unmeasured: string): string {
  const head = `${weekday(point.day)} ${dayMonth(point.day)}`;
  if (point.total == null) return `${head} · ${unmeasured}`;
  const detail = point.byPlatform
    .filter((cell) => cell.displayed && cell.value != null && cell.value > 0)
    .map((cell) => `${cell.label} ${int(cell.value)}`)
    .join(" · ");
  const total = count(point.total, "compte actif", "comptes actifs");
  return detail ? `${head} · ${total} — ${detail}` : `${head} · ${total}`;
}

/**
 * Série journalière SERVIE (un point par jour, sans trou). Barres en CSS, sans
 * librairie : la hauteur est une échelle visuelle rapportée au plus haut jour
 * de la série (aucun pourcentage affiché) ; un jour non mesuré n'a pas de
 * barre mais un cadre pointillé. Masquée sur un seul jour (Aujourd'hui, Hier).
 */
export function DailyPanel({ data }: { data: AdminActivityResponse }) {
  const daily = data.activeUsers.daily;
  const [selected, setSelected] = useState<number | null>(null);
  if (daily.length <= 1) return null;

  const unmeasured = activityUnmeasured(data, "ACTIVE_USERS");
  const max = Math.max(0, ...daily.map((point) => point.total ?? 0));
  const focus = (selected != null ? daily[selected] : undefined) ?? daily[daily.length - 1];
  const columns = daily[0].byPlatform.filter((cell) => cell.displayed);

  return (
    <Panel
      title="Évolution journalière des actifs"
      sub="Comptes actifs distincts par jour. Série non additive : un compte actif trois jours compte trois fois si l’on somme les jours."
    >
      <div className={styles.chartBody}>
        <p className={styles.readout} aria-live="polite">
          {readout(focus, unmeasured)}
        </p>
        <div className={styles.chartFrame}>
          <span className={styles.chartMax}>{int(max)}</span>
          <div
            className={styles.bars}
            role="group"
            aria-label="Comptes actifs par jour"
            onMouseLeave={() => setSelected(null)}
          >
            {daily.map((point, index) => {
              const height = max > 0 && point.total != null ? (point.total / max) * 100 : 0;
              return (
                <button
                  key={point.day}
                  type="button"
                  className={`${styles.barSlot} ${index === selected ? styles.barSlotActive : ""}`}
                  aria-label={readout(point, unmeasured)}
                  onMouseEnter={() => setSelected(index)}
                  onFocus={() => setSelected(index)}
                  onClick={() => setSelected(index)}
                >
                  {point.total == null ? (
                    <span className={styles.barUnmeasured} />
                  ) : point.total === 0 ? (
                    <span className={styles.barZero} />
                  ) : (
                    <span className={styles.barFill} style={{ height: `${height}%` }} />
                  )}
                </button>
              );
            })}
          </div>
        </div>
        <div className={styles.axis} aria-hidden="true">
          <span>{dayMonth(daily[0].day)}</span>
          <span>{dayMonth(daily[daily.length - 1].day)}</span>
        </div>
      </div>

      <div className={styles.panelFoot}>
        <Collapsible title="Détail par jour" hint={`${daily.length} jours`}>
          <div className={tableStyles.tableWrap}>
            <table
              className={`${tableStyles.table} ${tableStyles.cardTable} ${tableStyles.noActions}`}
            >
              <thead>
                <tr>
                  <th>Jour</th>
                  <th className={styles.num}>Total</th>
                  {columns.map((cell) => (
                    <th key={cell.platform} className={styles.num}>
                      {cell.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {daily.map((point) => (
                  <tr key={point.day}>
                    <td>
                      {weekday(point.day)} {dayMonth(point.day)}
                    </td>
                    <td data-label="Total" className={styles.num}>
                      {int(point.total)}
                    </td>
                    {point.byPlatform
                      .filter((cell) => cell.displayed)
                      .map((cell) => (
                        <td key={cell.platform} data-label={cell.label} className={styles.num}>
                          {int(cell.value)}
                        </td>
                      ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Collapsible>
      </div>
    </Panel>
  );
}
