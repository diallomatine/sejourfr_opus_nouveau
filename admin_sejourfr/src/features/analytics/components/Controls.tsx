import { useEffect, useRef, useState } from "react";
import styles from "../analytics.module.css";
import { Icon } from "./Icon";

interface SegmentedProps<T extends string> {
  options: { id: T; label: string }[];
  value: T;
  onChange: (id: T) => void;
  small?: boolean;
  ariaLabel?: string;
}

export function Segmented<T extends string>({
  options,
  value,
  onChange,
  small,
  ariaLabel,
}: SegmentedProps<T>) {
  return (
    <div
      className={`${styles.seg} ${small ? styles.segSmall : ""}`}
      role="group"
      aria-label={ariaLabel}
    >
      {options.map((option) => (
        <button
          key={option.id}
          type="button"
          aria-pressed={value === option.id}
          onClick={() => onChange(option.id)}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}

interface MenuProps {
  label: string;
  allLabel: string;
  value: string | null;
  options: { id: string; label: string; hint?: string }[];
  onChange: (id: string | null) => void;
}

/** Filtre a valeur unique. Le `×` retire le filtre sans ouvrir le menu. */
export function Menu({ label, allLabel, value, options, onChange }: MenuProps) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!open) return;
    const handle = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handle);
    return () => document.removeEventListener("mousedown", handle);
  }, [open]);

  const selected = options.find((option) => option.id === value);

  return (
    <div className={styles.menu} ref={ref}>
      <button
        type="button"
        className={`${styles.chip} ${value ? styles.chipOn : ""}`}
        aria-expanded={open}
        onClick={() => setOpen(!open)}
      >
        {selected ? selected.label : label}
        {value ? (
          <span
            className={styles.chipX}
            aria-hidden="true"
            onClick={(event) => {
              event.stopPropagation();
              onChange(null);
            }}
          >
            <Icon name="close" size={13} stroke={2.4} />
          </span>
        ) : (
          <Icon name="chevron" size={13} stroke={2.2} />
        )}
      </button>

      {open && (
        <div className={styles.menuPop}>
          <button
            type="button"
            aria-pressed={!value}
            onClick={() => {
              onChange(null);
              setOpen(false);
            }}
          >
            {allLabel}
          </button>
          <div className={styles.menuSep} />
          {options.map((option) => (
            <button
              key={option.id}
              type="button"
              aria-pressed={value === option.id}
              onClick={() => {
                onChange(option.id);
                setOpen(false);
              }}
            >
              {option.label}
              {option.hint && (
                <span className={styles.menuHint}>{option.hint}</span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
