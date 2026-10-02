import type { ReactNode } from "react";
import styles from "./PageHeader.module.css";

interface PageHeaderProps {
  eyebrow?: string;
  title: string;
  /** Suite du titre, accentuée en rouge (`<em>`). */
  emphasis?: string;
  description?: ReactNode;
  actions?: ReactNode;
}

export function PageHeader({ eyebrow, title, emphasis, description, actions }: PageHeaderProps) {
  return (
    <div className={styles.header}>
      <div className={styles.heading}>
        {eyebrow && <div className={styles.eyebrow}>{eyebrow}</div>}
        <h1 className={styles.title}>
          {title} {emphasis && <em className={styles.emphasis}>{emphasis}</em>}
        </h1>
        {description && <p className={styles.description}>{description}</p>}
      </div>
      {actions && <div className={styles.actions}>{actions}</div>}
    </div>
  );
}
