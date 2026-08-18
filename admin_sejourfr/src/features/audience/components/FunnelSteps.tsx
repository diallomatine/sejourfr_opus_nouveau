import type { FunnelStatsResponse } from "../../../types/api";
import { barWidth, count, percentOf, plural, type FunnelLeak } from "../insights";
import { STAGE_LABELS } from "../labels";
import styles from "./FunnelSteps.module.css";

/**
 * L'objet central de l'écran. Les 7 étapes sont servies déjà ordonnées par le
 * backend et ne sont JAMAIS réordonnées ici. Chaque piste vaut 100 % des
 * inscrits : les largeurs se comparent donc entre elles.
 */
export function FunnelSteps({
  stats,
  signups,
  leak,
}: {
  stats: FunnelStatsResponse;
  signups: number;
  leak: FunnelLeak | null;
}) {
  const lastIndex = stats.stages.length - 1;

  return (
    <ol className={styles.steps}>
      {stats.stages.map((stage, index) => {
        const previous = index > 0 ? stats.stages[index - 1] : null;
        const lost = previous ? previous.count - stage.count : 0;
        const isWorst = leak !== null && leak.toIndex === index;
        const isFinal = index === lastIndex;

        return (
          <li
            key={stage.stage}
            className={`${styles.step} ${isWorst ? styles.stepWorst : ""}`}
          >
            <div className={styles.head}>
              <span className={styles.index}>
                {String(index + 1).padStart(2, "0")}
              </span>
              <span className={styles.label}>{STAGE_LABELS[stage.stage]}</span>
              {isWorst && <span className={styles.badge}>plus grosse perte</span>}
              <span
                className={`${styles.count} ${isFinal ? styles.countFinal : ""}`}
              >
                {count(stage.count)}
              </span>
            </div>

            <span className={styles.track}>
              <i
                className={`${styles.kept} ${isFinal ? styles.keptFinal : ""}`}
                style={{ width: barWidth(stage.count, signups) }}
              />
              {lost > 0 && (
                <i
                  className={`${styles.lost} ${isWorst ? styles.lostWorst : ""}`}
                  style={{
                    left: barWidth(stage.count, signups),
                    width: barWidth(lost, signups),
                  }}
                />
              )}
            </span>

            <div className={styles.meta}>
              <span className={styles.share}>
                {percentOf(stage.count, signups)} des inscrits
              </span>
              {previous && (
                <span>
                  {percentOf(stage.count, previous.count)} depuis «{" "}
                  {STAGE_LABELS[previous.stage]} »
                </span>
              )}
              {lost > 0 && (
                <span
                  className={isWorst ? styles.lostTextWorst : styles.lostText}
                >
                  −{count(lost)} {plural(lost, "compte perdu", "comptes perdus")}
                </span>
              )}
            </div>
          </li>
        );
      })}
    </ol>
  );
}
