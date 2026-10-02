import styles from "./Chips.module.css";

interface ChipsProps<T extends string> {
  options: readonly { value: T; label: string }[];
  value: T;
  onChange: (value: T) => void;
  label: string;
}

/** Filtre exclusif en pastilles ; défile horizontalement sous 720 px. */
export function Chips<T extends string>({ options, value, onChange, label }: ChipsProps<T>) {
  return (
    <div className={styles.chips} role="group" aria-label={label}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          className={`${styles.chip} ${o.value === value ? styles.active : ""}`}
          aria-pressed={o.value === value}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
