import { useEffect, type ReactNode } from "react";
import styles from "../analytics.module.css";
import { Icon } from "./Icon";

interface DrawerProps {
  title: string;
  sub?: string;
  onClose: () => void;
  children: ReactNode;
}

export function Drawer({ title, sub, onClose, children }: DrawerProps) {
  useEffect(() => {
    const handle = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handle);
    return () => document.removeEventListener("keydown", handle);
  }, [onClose]);

  return (
    <>
      <button
        type="button"
        className={styles.scrim}
        aria-label="Fermer le détail"
        onClick={onClose}
      />
      <aside className={styles.drawer} role="dialog" aria-label={title}>
        <div className={styles.drawerHead}>
          <div className={styles.drawerTitles}>
            <div className={styles.lbl}>Détail</div>
            <h2>{title}</h2>
            {sub && <p>{sub}</p>}
          </div>
          <button
            type="button"
            className={styles.iconBtn}
            onClick={onClose}
            aria-label="Fermer"
          >
            <Icon name="close" size={15} />
          </button>
        </div>
        <div className={styles.drawerBody}>{children}</div>
      </aside>
    </>
  );
}
