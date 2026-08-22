import DOMPurify from "dompurify";
import type { AnalyticsInsight } from "../../../types/api";
import styles from "../analytics.module.css";

const TONE_CLASS: Record<AnalyticsInsight["tone"], string> = {
  OK: styles.dotOk,
  WARN: styles.dotWarn,
  BAD: styles.dotBad,
  NEUTRAL: "",
};

/**
 * Un constat porte de l'emphase (`<b>`) autour de ses chiffres. Le texte vient
 * du serveur, mais il peut citer un nom de campagne saisi par un tiers : on le
 * nettoie avant de l'injecter plutot que de faire confiance a la source.
 */
function sanitize(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ["b", "strong", "em", "i"],
    ALLOWED_ATTR: [],
  });
}

export function Insights({ insights }: { insights: AnalyticsInsight[] }) {
  if (insights.length === 0) return null;

  return (
    <div className={styles.insights}>
      {insights.map((insight, index) => (
        <div className={styles.insightItem} key={`${insight.tone}-${index}`}>
          <span className={`${styles.dot} ${TONE_CLASS[insight.tone]}`} />
          <p dangerouslySetInnerHTML={{ __html: sanitize(insight.html) }} />
        </div>
      ))}
    </div>
  );
}
