import type { ReactNode } from "react";
import { NON_DISPONIBLE } from "../productionLabels";
import styles from "./Facts.module.css";

export interface Fact {
  label: string;
  /** `null` / `undefined` ⇒ « Non disponible », jamais une valeur simulée. */
  value: ReactNode | null | undefined;
  mono?: boolean;
  wide?: boolean;
}

/** Grille « intitulé / valeur » des blocs de la fiche. */
export function Facts({ items, columns = 4 }: { items: Fact[]; columns?: 2 | 3 | 4 }) {
  return (
    <dl className={`${styles.facts} ${styles[`cols${columns}`]}`}>
      {items.map((item) => (
        <div key={item.label} className={`${styles.fact} ${item.wide ? styles.wide : ""}`}>
          <dt className={styles.label}>{item.label}</dt>
          <dd className={`${styles.value} ${item.mono ? styles.mono : ""}`}>
            {item.value === null || item.value === undefined ? <NotAvailable /> : item.value}
          </dd>
        </div>
      ))}
    </dl>
  );
}

export function NotAvailable({ children = NON_DISPONIBLE }: { children?: ReactNode }) {
  return <span className={styles.na}>{children}</span>;
}

export function SectionLabel({ children }: { children: ReactNode }) {
  return <span className={styles.label}>{children}</span>;
}
