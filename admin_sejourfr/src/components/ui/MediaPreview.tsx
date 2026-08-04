import type { MediaType } from "../../types/api";
import { sanitizeSvg } from "../../lib/sanitizeSvg";
import styles from "./MediaPreview.module.css";

const TYPE_BADGE: Record<MediaType, string> = {
  AUDIO: "Audio",
  IMAGE: "Image",
  VIDEO: "Vidéo",
};

interface Props {
  /** Null quand le média n'a pas de fichier : l'image vit alors en SVG inline. */
  url: string | null;
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
          dangerouslySetInnerHTML={{ __html: sanitizeSvg(inlineSvg) }}
          role="img"
          aria-label={altText ?? "Document"}
        />
      </div>
    );
  }

  if (!url) {
    return (
      <div className={cls}>
        <div className={styles.badge}>{TYPE_BADGE[type]}</div>
        <p className={styles.missing}>
          Ce média n&apos;a ni fichier ni SVG inline : rien à prévisualiser.
        </p>
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
