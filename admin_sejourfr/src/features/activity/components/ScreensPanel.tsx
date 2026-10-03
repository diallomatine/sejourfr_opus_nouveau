import { useState } from "react";
import { Panel } from "../../../components/ui/Panel";
import { Segmented } from "../../../components/ui/Segmented";
import tableStyles from "../../../components/ui/DataTable.module.css";
import { int } from "../../../lib/format";
import type {
  ActivityPlatform,
  ActivityScreenRow,
  ActivityScreenTable,
  AdminActivityResponse,
} from "../../../types/api";
import { activityMeasuredSince, activityUnmeasured } from "../notes";
import styles from "../activity.module.css";

type Tab = "web" | "app";

const TABS: readonly { value: Tab; label: string }[] = [
  { value: "web", label: "Web" },
  { value: "app", label: "Application" },
];

/** Colonnes système de l'onglet App, intitulées par les libellés de plateforme servis. */
const APP_SYSTEMS: readonly { platform: ActivityPlatform; field: "ios" | "android" | "appUnknownSystem" }[] = [
  { platform: "IOS", field: "ios" },
  { platform: "ANDROID", field: "android" },
  { platform: "MOBILE", field: "appUnknownSystem" },
];

function rowClass(row: ActivityScreenRow): string {
  if (row.kind === "TOTAL") return styles.totalRow;
  if (row.kind === "SCREEN") return "";
  return styles.synthRow;
}

/**
 * Pages (web) et écrans (app) les plus consultés : le top servi, puis les
 * lignes de synthèse SERVIES (« Autres écrans suivis », « Écrans non
 * déclarés », « Total ») — des uniques ne s'additionnent pas, le front n'en
 * reconstruit aucune.
 */
export function ScreensPanel({ data }: { data: AdminActivityResponse }) {
  const [tab, setTab] = useState<Tab>("web");
  const table: ActivityScreenTable = data.screens[tab];
  const indicator = tab === "web" ? "SCREEN_VIEWS_WEB" : "SCREEN_VIEWS_APP";
  const systems = tab === "app" ? APP_SYSTEMS : [];
  const labelOf = (platform: ActivityPlatform) =>
    data.platforms.find((row) => row.platform === platform)?.label ?? platform;
  const lines = [
    ...table.rows,
    table.otherTracked,
    table.undeclared,
    table.total,
  ].filter((row): row is ActivityScreenRow => row != null);
  const since = activityMeasuredSince(data, table.measuredSince);

  return (
    <Panel
      title="Pages et écrans les plus consultés"
      sub={`Les ${table.topLimit} plus vus, puis les lignes de synthèse calculées par le serveur.`}
      actions={<Segmented options={TABS} value={tab} onChange={setTab} label="Support" />}
    >
      {table.measuredSince == null ? (
        <p className={styles.emptyNote}>
          Vues {tab === "web" ? "de pages" : "d’écrans"} :{" "}
          <span className={styles.unmeasured}>{activityUnmeasured(data, indicator)}</span>
        </p>
      ) : (
        <div className={tableStyles.tableWrap}>
          <table
            className={`${tableStyles.table} ${tableStyles.cardTable} ${tableStyles.noActions}`}
          >
            <thead>
              <tr>
                <th>{tab === "web" ? "Page" : "Écran"}</th>
                <th className={styles.num}>Vues</th>
                <th className={styles.num}>Visiteurs uniques</th>
                <th className={styles.num}>Comptes (partiel)</th>
                {systems.map((system) => (
                  <th key={system.platform} className={styles.num}>
                    {labelOf(system.platform)}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {lines.map((row) => (
                <tr key={`${row.kind}-${row.path ?? ""}`} className={rowClass(row)}>
                  <td>
                    <span className={styles.screenLabel}>{row.label}</span>
                    {row.kind === "SCREEN" && row.path && row.path !== row.label && (
                      <span className={styles.screenPath}>{row.path}</span>
                    )}
                  </td>
                  <td data-label="Vues" className={styles.num}>
                    {int(row.views)}
                  </td>
                  <td data-label="Visiteurs uniques" className={styles.num}>
                    {int(row.uniqueVisitors)}
                  </td>
                  <td data-label="Comptes (partiel)" className={styles.num}>
                    {int(row.uniqueUsers)}
                  </td>
                  {systems.map((system) => (
                    <td
                      key={system.platform}
                      data-label={labelOf(system.platform)}
                      className={styles.num}
                    >
                      {int(row[system.field])}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className={styles.panelFoot}>
        {since && <p className={styles.note}>Vues {since}.</p>}
        <p className={styles.note}>
          « Comptes » est partiel : une vue envoyée sans session ouverte n’est rattachée à aucun
          compte. Les uniques ne s’additionnent pas d’une ligne à l’autre.
        </p>
      </div>
    </Panel>
  );
}
