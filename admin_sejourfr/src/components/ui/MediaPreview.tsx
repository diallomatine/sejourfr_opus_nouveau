import type { MediaType } from "../../types/api";
import styles from "./MediaPreview.module.css";

interface Props {
  url: string;
  type: MediaType;
  altText?: string | null;
  compact?: boolean;
  /**
   * SVG inline. Quand fourni, on rend ce balisage en lieu et place de url
   * (les captures TCF dessinées en Flyway n'ont pas d'URL externe).
   */
  inlineSvg?: string | null;
}

export function MediaPreview({ url, type, altText, compact, inlineSvg }: Props) {
  const cls = `${styles.wrap} ${compact ? styles.compact : ""}`;

  if (inlineSvg) {
    return (
      <div className={cls}>
        <div className={styles.badge}>SVG · inline</div>
        <div
          className={styles.image}
          dangerouslySetInnerHTML={{ __html: inlineSvg }}
          role="img"
          aria-label={altText ?? "Document"}
        />
      </div>
    );
  }

  if (type === "AUDIO") {
    return (
      <div className={cls}>
        <div className={styles.badge}>Audio</div>
        <audio controls src={url} className={styles.audio} preload="metadata" />
      </div>
    );
  }

  if (type === "IMAGE") {
    return (
      <div className={cls}>
        <div className={styles.badge}>Image</div>
        <img src={url} alt={altText ?? ""} className={styles.image} />
      </div>
    );
  }

  return (
    <div className={cls}>
      <div className={styles.badge}>Vidéo</div>
      <video controls src={url} className={styles.video} preload="metadata" />
    </div>
  );
}
