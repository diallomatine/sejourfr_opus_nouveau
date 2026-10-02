import type { ReactNode } from "react";
import styles from "./Tag.module.css";

/** Tons génériques (`info`…`neutral`) + tons historiques des écrans de contenu. */
export type TagTone =
  | "info"
  | "success"
  | "danger"
  | "warning"
  | "neutral"
  | "csp"
  | "cr"
  | "nat"
  | "a2"
  | "b1"
  | "b2"
  | "active"
  | "draft"
  | "premium"
  | "free"
  | "co"
  | "ce"
  | "conn"
  | "mise"
  | "structure"
  | "muted";

interface TagProps {
  tone: TagTone;
  /** Pastille de couleur devant le libellé (statuts). */
  dot?: boolean;
  children: ReactNode;
}

export function Tag({ tone, dot = false, children }: TagProps) {
  return <span className={`${styles.tag} ${styles[tone]} ${dot ? styles.dot : ""}`}>{children}</span>;
}
