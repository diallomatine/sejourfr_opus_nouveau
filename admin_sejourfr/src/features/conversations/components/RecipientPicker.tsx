import { useId, useState } from "react";
import type { KeyboardEvent } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { httpErrorMessage } from "../../../api/http";
import { usersApi } from "../../../api/usersApi";
import { Avatar } from "../../../components/ui/Avatar";
import { Input } from "../../../components/ui/Form";
import { useDebouncedValue } from "../../../hooks/useDebouncedValue";
import styles from "./RecipientPicker.module.css";

/** Le compte destinataire : ce que la liste ou la fiche servent déjà. */
export interface MessageRecipient {
  id: string;
  email: string;
  displayName: string | null;
}

interface RecipientPickerProps {
  value: MessageRecipient | null;
  onChange: (recipient: MessageRecipient | null) => void;
  disabled?: boolean;
}

const MIN_QUERY = 2;
const RESULTS = 8;

/**
 * Combobox de recherche d'un compte (email, nom ou UUID) sur `GET /api/admin/users?q=`,
 * la même recherche que la liste « Utilisateurs » — comptes supprimés exclus (D-56).
 */
export function RecipientPicker({ value, onChange, disabled }: RecipientPickerProps) {
  const inputId = useId();
  const listId = useId();
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const debounced = useDebouncedValue(query.trim(), 300);
  const enabled = debounced.length >= MIN_QUERY;

  const results = useQuery({
    queryKey: ["adminUsers", "list", { q: debounced, size: RESULTS }],
    queryFn: () => usersApi.list({ q: debounced, size: RESULTS }),
    enabled,
    placeholderData: keepPreviousData,
  });

  const items = enabled ? (results.data?.content ?? []) : [];
  const expanded = open && enabled;

  const pick = (index: number) => {
    const u = items[index];
    if (!u) return;
    onChange({ id: u.id, email: u.email, displayName: u.displayName });
    setQuery("");
    setOpen(false);
  };

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setOpen(true);
      setActive((i) => Math.min(i + 1, Math.max(items.length - 1, 0)));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter" && expanded && items.length > 0) {
      e.preventDefault();
      pick(active);
    } else if (e.key === "Escape" && expanded) {
      e.stopPropagation();
      setOpen(false);
    }
  };

  if (value) {
    return (
      <div className={styles.selected}>
        <Avatar name={value.displayName} email={value.email} size="sm" />
        <div className={styles.selectedText}>
          <span className={styles.name}>{value.displayName ?? value.email}</span>
          {value.displayName && <span className={styles.email}>{value.email}</span>}
        </div>
        {!disabled && (
          <button type="button" className={styles.change} onClick={() => onChange(null)}>
            Changer
          </button>
        )}
      </div>
    );
  }

  return (
    <div className={styles.picker}>
      <label className={styles.srOnly} htmlFor={inputId}>
        Rechercher un compte destinataire
      </label>
      <Input
        id={inputId}
        type="search"
        role="combobox"
        aria-expanded={expanded}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={expanded && items[active] ? `${listId}-${active}` : undefined}
        placeholder="Email, nom ou identifiant du compte…"
        autoComplete="off"
        value={query}
        disabled={disabled}
        onChange={(e) => {
          setQuery(e.target.value);
          setActive(0);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
        onKeyDown={onKeyDown}
      />
      {expanded && (
        <ul id={listId} role="listbox" className={styles.listbox} aria-label="Comptes trouvés">
          {results.isError && (
            <li className={styles.state} role="presentation">
              Recherche impossible : {httpErrorMessage(results.error)}
            </li>
          )}
          {!results.isError && results.isPending && (
            <li className={styles.state} role="presentation">
              Recherche…
            </li>
          )}
          {!results.isError && results.data && items.length === 0 && (
            <li className={styles.state} role="presentation">
              Aucun compte ne correspond.
            </li>
          )}
          {items.map((u, i) => (
            <li
              key={u.id}
              id={`${listId}-${i}`}
              role="option"
              aria-selected={i === active}
              className={`${styles.option} ${i === active ? styles.active : ""}`}
              onMouseDown={(e) => {
                e.preventDefault();
                pick(i);
              }}
              onMouseEnter={() => setActive(i)}
            >
              <Avatar name={u.displayName} email={u.email} size="sm" />
              <span className={styles.optionText}>
                <span className={styles.name}>{u.displayName ?? u.email}</span>
                {u.displayName && <span className={styles.email}>{u.email}</span>}
              </span>
            </li>
          ))}
        </ul>
      )}
      {!enabled && query.trim().length > 0 && (
        <p className={styles.hint}>Saisissez au moins {MIN_QUERY} caractères.</p>
      )}
    </div>
  );
}
