import type { ReactNode } from "react";
import styles from "../suivi.module.css";

interface SectionProps {
  title: string;
  description: string;
  badges?: ReactNode;
  className?: string;
  children: ReactNode;
}

/** Carte titree du template (`card section` + `section-head`). */
export function Section({ title, description, badges, className, children }: SectionProps) {
  return (
    <div className={`${styles.card} ${className ?? styles.section}`}>
      <div className={styles.sectionHead}>
        <div>
          <h2>{title}</h2>
          <p>{description}</p>
        </div>
        {badges && <div className={styles.badges}>{badges}</div>}
      </div>
      {children}
    </div>
  );
}

interface StatItemProps {
  name: string;
  meta: ReactNode;
  number: ReactNode;
}

export function StatItem({ name, meta, number }: StatItemProps) {
  return (
    <div className={styles.statItem}>
      <div>
        <div className={styles.statName}>{name}</div>
        <div className={styles.statMeta}>{meta}</div>
      </div>
      <div className={styles.statNumber}>{number}</div>
    </div>
  );
}

/** Mention d'une valeur non mesuree, en retrait typographique. */
export function Unmeasured({ children }: { children: ReactNode }) {
  return <span className={styles.unmeasured}>{children}</span>;
}
