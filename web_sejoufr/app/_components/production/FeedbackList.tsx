"use client";

import type {ReactNode} from "react";
import styles from "./production.module.css";

/** Liste à puces d'un bloc de feedback (points forts, suggestions…). Partagée
 *  entre le haut de l'écran et l'analyse complète : un seul rendu pour une
 *  même forme de contenu. */
export function FeedbackList({
  title,
  icon,
  items,
  dot,
}: {
  title: string;
  icon: ReactNode;
  items: string[];
  /** Classe de teinte de la puce (`fbGood` ou `fbInfo`). */
  dot: string;
}) {
  return (
    <>
      <p className={styles.fbTitle}>
        {icon}
        {title}
      </p>
      <ul className={styles.fbList}>
        {items.map((item, i) => (
          <li key={i} className={styles.fbItem}>
            <span className={`${styles.fbBullet} ${dot}`} />
            {item}
          </li>
        ))}
      </ul>
    </>
  );
}
