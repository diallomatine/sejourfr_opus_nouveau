import { Fragment } from "react";
import type { AnalyticsFunnelStep } from "../../../types/api";
import { blueStep, int, pct, plural } from "../format";
import styles from "../analytics.module.css";
import { Icon } from "./Icon";

interface FunnelProps {
  steps: AnalyticsFunnelStep[];
  onStep?: (step: AnalyticsFunnelStep) => void;
  compact?: boolean;
  /**
   * Index a partir duquel une marche peut etre designee « plus forte perte ».
   * La chute visiteurs → premier clic est structurelle : la designer chaque
   * fois masquerait la vraie fuite du parcours.
   */
  worstFrom?: number;
}

export function Funnel({ steps, onStep, compact, worstFrom = 1 }: FunnelProps) {
  const max = Math.max(...steps.map((step) => step.value), 1);
  const losses = steps.map((step, index) =>
    index >= worstFrom ? step.lost : -1,
  );
  const biggest = Math.max(...losses);
  const worstIndex = biggest > 0 ? losses.indexOf(biggest) : -1;

  return (
    <div className={styles.funnel}>
      {steps.map((step, index) => {
        /* Compression en puissance 0,42 : sans elle, les dernieres etapes d'un
           entonnoir qui divise par cent sont invisibles a l'ecran. */
        const width = Math.max(0.6, Math.pow(step.value / max, 0.42) * 100);
        const worst = index === worstIndex;

        const row = (
          <>
            <div className={styles.fstepLabel}>
              <span className={styles.num}>{int(step.value)}</span>
              <span>{step.label}</span>
            </div>
            <div className={styles.fbarTrack}>
              <div
                className={styles.fbar}
                style={{
                  width: `${width}%`,
                  background: worst
                    ? "var(--red)"
                    : blueStep(index, steps.length),
                }}
              />
            </div>
            <div
              className={`${styles.fconv} ${step.conv == null ? styles.fconvStart : ""}`}
            >
              {step.conv != null ? (
                <>
                  <b>{pct(step.conv, step.conv < 0.1 ? 1 : 0)}</b>
                  <small>
                    {compact ? "de l'étape préc." : "depuis l'étape précédente"}
                  </small>
                </>
              ) : (
                <>
                  <b>{pct(1, 0)}</b>
                  <small>point de départ</small>
                </>
              )}
            </div>
          </>
        );

        const className = `${styles.fstep} ${onStep ? styles.fstepClickable : ""} ${
          worst ? styles.fstepWorst : ""
        }`;

        return (
          <Fragment key={step.k}>
            {index > 0 && (
              <div className={styles.fgap}>
                <div className={styles.fgapLine}>
                  <i />
                  {worst ? (
                    <span className={styles.loss}>
                      <Icon name="alert" size={12} stroke={2.2} />
                      Plus forte perte · {int(step.lost)}{" "}
                      {plural(step.lost, "personne", "personnes")}
                    </span>
                  ) : (
                    <span>− {int(step.lost)}</span>
                  )}
                </div>
              </div>
            )}
            {onStep ? (
              <button
                type="button"
                className={className}
                onClick={() => onStep(step)}
              >
                {row}
              </button>
            ) : (
              <div className={className}>{row}</div>
            )}
          </Fragment>
        );
      })}
    </div>
  );
}
