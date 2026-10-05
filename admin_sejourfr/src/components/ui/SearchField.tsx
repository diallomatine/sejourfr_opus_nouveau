import { Icon } from "./Icon";
import styles from "./SearchField.module.css";

interface SearchFieldProps {
  /** Intitulé lu par les lecteurs d'écran (le champ n'a pas d'étiquette visible). */
  label: string;
  placeholder: string;
  value: string;
  onChange: (value: string) => void;
}

/** Champ de recherche des listes (loupe à gauche), à brancher sur `useUrlSearchInput`. */
export function SearchField({ label, placeholder, value, onChange }: SearchFieldProps) {
  return (
    <label className={styles.search}>
      <span className="visually-hidden">{label}</span>
      <Icon name="search" size={17} className={styles.icon} />
      <input
        type="search"
        className={styles.input}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </label>
  );
}
