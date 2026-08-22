import type { ReactNode } from "react";
import styles from "../analytics.module.css";
import { Icon } from "./Icon";

interface CardProps {
  title?: string;
  /** La question a laquelle la carte repond, en italique a cote du titre. */
  question?: string;
  actions?: ReactNode;
  children: ReactNode;
  clipped?: boolean;
  bodyClassName?: string;
}

export function Card({
  title,
  question,
  actions,
  children,
  clipped,
  bodyClassName,
}: CardProps) {
  return (
    <section className={`${styles.card} ${clipped ? styles.cardClipped : ""}`}>
      {(title || actions) && (
        <div className={styles.cardHead}>
          {title && <h3>{title}</h3>}
          {question && <span className={styles.cardQuestion}>{question}</span>}
          {actions && <div className={styles.cardActions}>{actions}</div>}
        </div>
      )}
      <div className={bodyClassName}>{children}</div>
    </section>
  );
}

interface SectionHeadProps {
  title: string;
  sub?: string;
  right?: ReactNode;
}

export function SectionHead({ title, sub, right }: SectionHeadProps) {
  return (
    <div className={styles.secHead}>
      <div className={styles.secHeadText}>
        <h2>{title}</h2>
        {sub && <p>{sub}</p>}
      </div>
      {right && <div className={styles.secHeadRight}>{right}</div>}
    </div>
  );
}

export function Note({ children }: { children: ReactNode }) {
  return (
    <div className={styles.note}>
      <span className={styles.noteIcon}>
        <Icon name="alert" size={15} />
      </span>
      <div>{children}</div>
    </div>
  );
}

/**
 * Un etat vide DIT pourquoi il est vide. C'est la regle du brief §82 : sur peu
 * de donnees, on n'affiche pas un graphe casse ni des zeros qu'on lirait comme
 * des mesures.
 */
export function EmptyState({
  title = "Pas encore assez de données sur cette période.",
  children,
}: {
  title?: string;
  children?: ReactNode;
}) {
  return (
    <div className={styles.empty}>
      <span className={styles.emptyTitle}>{title}</span>
      {children}
    </div>
  );
}

export function EmptyBlock({
  title = "Pas encore assez de données sur cette période.",
  children,
  error,
}: {
  title?: string;
  children?: ReactNode;
  error?: boolean;
}) {
  return (
    <p className={`${styles.emptyBlock} ${error ? styles.errorBlock : ""}`}>
      <span className={styles.emptyTitle}>{title}</span>
      {children}
    </p>
  );
}
