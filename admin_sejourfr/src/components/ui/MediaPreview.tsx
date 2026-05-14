import type { MediaType } from "../../types/api";
import styles from "./MediaPreview.module.css";

interface Props {
  url: string;
  type: MediaType;
  altText?: string | null;
  compact?: boolean;
}

export function MediaPreview({ url, type, altText, compact }: Props) {
  const cls = `${styles.wrap} ${compact ? styles.compact : ""}`;

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
