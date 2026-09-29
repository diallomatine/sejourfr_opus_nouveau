import type { ReactNode } from "react";
import styles from "./Panel.module.css";

interface PanelProps {
  title?: string;
  sub?: string;
  actions?: ReactNode;
  children: ReactNode;
  noPadding?: boolean;
}

export function Panel({ title, sub, actions, children, noPadding }: PanelProps) {
  return (
    <div className={styles.panel}>
      {(title || actions) && (
        <div className={styles.header}>
          <div>
            {title && <h2 className={styles.title}>{title}</h2>}
            {sub && <div className={styles.sub}>{sub}</div>}
          </div>
          {actions && <div>{actions}</div>}
        </div>
      )}
      <div className={noPadding ? "" : styles.body}>{children}</div>
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title: string;
  description?: string;
}) {
  return (
    <div className={styles.empty}>
      <div className={styles.emptyTitle}>{title}</div>
      {description && <div className={styles.emptyDesc}>{description}</div>}
    </div>
  );
}
