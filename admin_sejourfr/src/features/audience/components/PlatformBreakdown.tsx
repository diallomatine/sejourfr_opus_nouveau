import type { FunnelPlatformStat } from "../../../types/api";
import { count, percentOf, plural } from "../insights";
import { BREAKDOWN_COLUMNS, PLATFORM_LABELS } from "../labels";
import panels from "./panels.module.css";
import styles from "./PlatformBreakdown.module.css";

/** Où le compte a été créé, puis ce qu'il y a fait. */
export function PlatformBreakdown({
  platforms,
}: {
  platforms: FunnelPlatformStat[];
}) {
  if (platforms.length === 0) {
    return (
      <p className={panels.state}>
        Aucune plateforme renseignée sur la fenêtre : ces comptes sont antérieurs
        à la mesure de plateforme.
      </p>
    );
  }

  return (
    <div className={styles.platforms}>
      {platforms.map((platform) => (
        <div key={platform.platform} className={styles.platform}>
          <span className={styles.name}>
            {PLATFORM_LABELS[platform.platform]}
          </span>
          <span className={styles.value}>{count(platform.signups)}</span>
          <span className={styles.hint}>
            {plural(platform.signups, "inscription", "inscriptions")}
          </span>
          <ul className={styles.list}>
            {BREAKDOWN_COLUMNS.slice(1).map((column) => (
              <li key={column.key}>
                <span>{column.label}</span>
                <strong>
                  {count(platform[column.key])}
                  <em> · {percentOf(platform[column.key], platform.signups)}</em>
                </strong>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}
