"use client";

import type {ReactNode} from "react";
import styles from "./plan.module.css";

/**
 * **Les structures partagées par les écrans SECONDAIRES du Plan**
 * (`/plan/domaine/[x]`, `/plan/progression`).
 *
 * Elles vivaient dans `LearningPlanView`, que la refonte du 2026-09-11 a
 * basculé sur le kit `sejour/` : les quatre écrans qui les importaient n'ont
 * pas été refondus et continuent de lire `plan.module.css`. Extraites ici pour
 * que la refonte de l'écran principal n'entraîne pas la leur.
 */

export function PlanShell({children}: {children: ReactNode}) {
  return <main className={styles.page}>{children}</main>;
}

export function EmptyCard({icon, title, text, children, role}: {
  icon: ReactNode;
  title: string;
  text: string;
  children?: ReactNode;
  role?: "alert";
}) {
  return (
    <section className={styles.emptyCard} role={role}>
      <span className={styles.emptyIcon} aria-hidden>{icon}</span>
      <h2>{title}</h2>
      <p>{text}</p>
      {children && <div className={styles.actions}>{children}</div>}
    </section>
  );
}

export function BlockHead({title, text, titleId, action}: {
  title: string;
  text?: string;
  titleId?: string;
  action?: ReactNode;
}) {
  return (
    <div className={styles.blockHead}>
      <div>
        <h2 id={titleId}>{title}</h2>
        {text && <p>{text}</p>}
      </div>
      {action}
    </div>
  );
}

