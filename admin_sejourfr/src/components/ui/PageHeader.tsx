import type { ReactNode } from "react";
import styles from "./PageHeader.module.css";

interface PageHeaderProps {
  eyebrow: string;
  title: string;
  emphasis?: string;
  actions?: ReactNode;
}

export function PageHeader({ eyebrow, title, emphasis, actions }: PageHeaderProps) {
  return (
    <div className={styles.header}>
      <div>
        <div className={styles.eyebrow}>{eyebrow}</div>
        <h1 className={styles.title}>
          {title} {emphasis && <em className={styles.emphasis}>{emphasis}</em>}
        </h1>
      </div>
      {actions && <div className={styles.actions}>{actions}</div>}
    </div>
  );
}
