"use client";

import { AlertCircle, CheckCircle2, Circle, type LucideIcon } from "lucide-react";
import type { ReactNode } from "react";
import { PasswordInput } from "./PasswordInput";
import styles from "./auth.module.css";

interface AuthFieldProps {
  id: string;
  name: string;
  label: string;
  type?: "text" | "email" | "password";
  icon?: LucideIcon;
  autoComplete: string;
  placeholder?: string;
  /** Erreur du champ : bordure rouge, `aria-invalid`, message relié par `aria-describedby`. */
  error?: string;
  /** Contrainte serveur affichée sous le champ, cochée quand elle est remplie. */
  requirement?: { label: string; met: boolean };
  /** À droite du libellé (ex. « Mot de passe oublié ? »). */
  labelAside?: ReactNode;
  autoFocus?: boolean;
  disabled?: boolean;
  /** Valeur de départ (le champ reste non contrôlé) — ex. un prénom déjà connu. */
  defaultValue?: string;
  onChange?: (value: string) => void;
}

/**
 * Champ des formulaires d'auth (connexion, inscription, mot de passe) : libellé
 * lisible, champ haut avec icône, anneau de focus aux tokens, erreur accessible.
 * Non contrôlé : la page lit le `FormData` à l'envoi.
 */
export function AuthField({
  id,
  name,
  label,
  type = "text",
  icon: Icon,
  autoComplete,
  placeholder,
  error,
  requirement,
  labelAside,
  autoFocus,
  disabled,
  defaultValue,
  onChange,
}: AuthFieldProps) {
  const reqId = requirement ? `${id}-req` : undefined;
  const errId = error ? `${id}-error` : undefined;
  const describedBy = [errId, reqId].filter(Boolean).join(" ") || undefined;
  const inputClass = `${styles.input} ${Icon ? styles.inputWithIcon : ""} ${error ? styles.inputInvalid : ""}`;

  const common = {
    id,
    name,
    autoComplete,
    placeholder,
    autoFocus,
    disabled,
    defaultValue,
    required: true,
    className: inputClass,
    "aria-invalid": error ? true : undefined,
    "aria-describedby": describedBy,
    onChange: onChange ? (e: React.ChangeEvent<HTMLInputElement>) => onChange(e.target.value) : undefined,
  };

  return (
    <div className={styles.field}>
      <div className={styles.labelRow}>
        <label htmlFor={id} className={styles.label}>
          {label}
        </label>
        {labelAside}
      </div>
      <div className={styles.control}>
        {Icon ? (
          <span className={styles.inputIcon} aria-hidden>
            <Icon size={18} />
          </span>
        ) : null}
        {type === "password" ? (
          <PasswordInput {...common} />
        ) : (
          <input
            {...common}
            type={type}
            inputMode={type === "email" ? "email" : undefined}
            autoCapitalize={type === "email" ? "none" : "words"}
            spellCheck={false}
            suppressHydrationWarning
          />
        )}
      </div>
      {error ? (
        <p id={errId} className={styles.fieldError}>
          <AlertCircle size={15} aria-hidden />
          <span>{error}</span>
        </p>
      ) : null}
      {requirement ? (
        <p
          id={reqId}
          className={`${styles.requirement} ${requirement.met ? styles.requirementMet : ""}`}
        >
          {requirement.met ? <CheckCircle2 size={15} aria-hidden /> : <Circle size={15} aria-hidden />}
          <span>{requirement.label}</span>
        </p>
      ) : null}
    </div>
  );
}
