import type { ReactNode } from "react";
import styles from "./Tag.module.css";

type TagTone =
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
  children: ReactNode;
}

export function Tag({ tone, children }: TagProps) {
  return <span className={`${styles.tag} ${styles[tone]}`}>{children}</span>;
}
