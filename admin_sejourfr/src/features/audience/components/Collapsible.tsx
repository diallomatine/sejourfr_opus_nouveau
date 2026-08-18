import type { ReactNode } from "react";
import panels from "./panels.module.css";
import styles from "./Collapsible.module.css";

/**
 * Second rideau de l'écran : rien ne disparaît, tout se replie. `<details>`
 * natif — l'état d'ouverture est géré par le navigateur, pas par un état React
 * qu'il faudrait synchroniser.
 */
export function Collapsible({
  title,
  hint,
  nature,
  defaultOpen = false,
  children,
}: {
  title: string;
  hint?: string;
  /** Nature des données du bloc : elle doit rester lisible même replié. */
  nature?: "exact" | "anon";
  defaultOpen?: boolean;
  children: ReactNode;
}) {
  return (
    <details className={styles.wrap} open={defaultOpen}>
      <summary className={styles.summary}>
        {nature && (
          <span
            className={`${panels.nature} ${
              nature === "exact" ? panels.natureExact : panels.natureAnon
            }`}
          >
            {nature === "exact" ? "exact · par compte" : "anonyme · par page"}
          </span>
        )}
        <span className={styles.title}>{title}</span>
        {hint && <span className={styles.hint}>{hint}</span>}
        <span className={styles.chevron}>déplier / replier</span>
      </summary>
      <div className={styles.body}>{children}</div>
    </details>
  );
}
