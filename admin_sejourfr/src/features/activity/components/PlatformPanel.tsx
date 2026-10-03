import { Panel } from "../../../components/ui/Panel";
import tableStyles from "../../../components/ui/DataTable.module.css";
import { count, int } from "../../../lib/format";
import type { AdminActivityResponse } from "../../../types/api";
import { activityMeasuredSince, activityUnmeasured } from "../notes";
import styles from "../activity.module.css";

/**
 * Répartition par plateforme, lignes et libellés servis (« Non déclarée »
 * seulement quand le serveur la marque `displayed`). La ligne Total est celle
 * du serveur — un compte compté une fois — jamais la somme des lignes.
 */
export function PlatformPanel({ data }: { data: AdminActivityResponse }) {
  const { activeUsers, logins } = data;
  const rows = data.platforms.filter((row) => row.displayed);
  const activeNote =
    activeUsers.total.value == null
      ? activityUnmeasured(data, "ACTIVE_USERS")
      : activityMeasuredSince(data, activeUsers.measuredSince);
  const loginsNote =
    logins.uniqueUsers.value == null
      ? activityUnmeasured(data, "LOGINS")
      : activityMeasuredSince(data, logins.measuredSince);

  return (
    <Panel
      title="Répartition par plateforme"
      sub="Comptes uniques par plateforme ; un compte actif sur deux plateformes figure sur les deux lignes."
    >
      <div className={tableStyles.tableWrap}>
        <table
          className={`${tableStyles.table} ${tableStyles.cardTable} ${tableStyles.noActions}`}
        >
          <thead>
            <tr>
              <th>Plateforme</th>
              <th className={styles.num}>Actifs uniques</th>
              <th className={styles.num}>Comptes connectés</th>
              <th className={styles.num}>Connexions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.platform}>
                <td>{row.label}</td>
                <td data-label="Actifs uniques" className={styles.num}>
                  {int(row.activeUsers)}
                </td>
                <td data-label="Comptes connectés" className={styles.num}>
                  {int(row.loggedInUsers)}
                </td>
                <td data-label="Connexions" className={styles.num}>
                  {int(row.logins)}
                </td>
              </tr>
            ))}
            <tr className={styles.totalRow}>
              <td>Total — un compte compté une fois</td>
              <td data-label="Actifs uniques" className={styles.num}>
                {int(activeUsers.total.value)}
              </td>
              <td data-label="Comptes connectés" className={styles.num}>
                {int(logins.uniqueUsers.value)}
              </td>
              <td data-label="Connexions" className={styles.num}>
                {int(logins.total)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div className={styles.panelFoot}>
        {activeUsers.multiPlatformUsers != null && (
          <p className={styles.note}>
            Dont {count(activeUsers.multiPlatformUsers, "compte actif", "comptes actifs")} sur
            plusieurs plateformes : la somme des lignes peut dépasser le total.
          </p>
        )}
        {activeNote && <p className={styles.note}>Actifs : {activeNote}.</p>}
        {loginsNote && <p className={styles.note}>Connexions : {loginsNote}.</p>}

        <div className={styles.methods} aria-label="Connexions par méthode">
          <span className={styles.methodsTitle}>Connexions par méthode</span>
          {logins.byMethod.map((method) => (
            <span key={method.method} className={styles.method}>
              {method.label} <strong>{int(method.value)}</strong>
            </span>
          ))}
          <span className={styles.method}>
            dont inscriptions <strong>{int(logins.signups)}</strong>
          </span>
        </div>
      </div>
    </Panel>
  );
}
