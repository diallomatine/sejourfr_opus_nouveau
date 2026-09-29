import styles from "./Spinner.module.css";

export function Spinner({ label }: { label?: string }) {
  return (
    <div className={styles.wrap}>
      <div className={styles.spinner} />
      {label && <span className={styles.label}>{label}</span>}
    </div>
  );
}
