import type { ReactNode } from "react";
import { Icon } from "./Icon";
import styles from "./Collapsible.module.css";

interface CollapsibleProps {
  title: string;
  /** Ligne d'appoint à droite du titre, visible replié. */
  hint?: string;
  defaultOpen?: boolean;
  children: ReactNode;
}

/** Carte repliable (`<details>` natif : clavier et lecteurs d'écran sans code). */
export function Collapsible({ title, hint, defaultOpen = false, children }: CollapsibleProps) {
  return (
    <details className={styles.card} open={defaultOpen}>
      <summary className={styles.summary}>
        <span className={styles.heading}>
          <span className={styles.title}>{title}</span>
          {hint && <span className={styles.hint}>{hint}</span>}
        </span>
        <span className={styles.toggle}>
          <span className={styles.toggleText}>Afficher</span>
          <Icon name="chevronDown" size={16} className={styles.chevron} />
        </span>
      </summary>
      <div className={styles.body}>{children}</div>
    </details>
  );
}
