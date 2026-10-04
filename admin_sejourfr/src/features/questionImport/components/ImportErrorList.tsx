import type { CoImageImportError } from "../../../types/api";
import styles from "./ImportReport.module.css";

interface ImportErrorListProps {
  errors: CoImageImportError[];
}

export function ImportErrorList({ errors }: ImportErrorListProps) {
  return (
    <ul className={styles.errorList}>
      {errors.map((error, i) => (
        <li key={`${error.code}-${error.field ?? ""}-${i}`} className={styles.errorItem}>
          <span className={styles.errorMessage}>{error.message}</span>
          <span className={styles.errorCode}>
            {error.code}
            {error.field ? ` · ${error.field}` : ""}
          </span>
        </li>
      ))}
    </ul>
  );
}
