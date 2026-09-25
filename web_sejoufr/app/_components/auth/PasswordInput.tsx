"use client";

import { Eye, EyeOff } from "lucide-react";
import { useState, type InputHTMLAttributes } from "react";
import { COMPTE_PASSWORD_HIDE, COMPTE_PASSWORD_SHOW } from "@/lib/compte";
import styles from "./auth.module.css";

interface PasswordInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "type"> {
  id: string;
  name: string;
}

/**
 * Champ mot de passe avec bouton afficher/masquer — le seul de la famille auth
 * (`AuthField` le monte, les écrans de compte des diagnostics l'utilisent nu).
 * Sans `className`, il prend le style global `.field-input`.
 */
export function PasswordInput({
  id,
  className = "field-input",
  required = true,
  ...rest
}: PasswordInputProps) {
  const [show, setShow] = useState(false);
  return (
    <div className={styles.pwdWrap}>
      <input
        {...rest}
        id={id}
        type={show ? "text" : "password"}
        required={required}
        className={className}
        autoCapitalize="none"
        autoCorrect="off"
        spellCheck={false}
        suppressHydrationWarning
      />
      <button
        type="button"
        className={styles.pwdToggle}
        onClick={() => setShow((v) => !v)}
        aria-label={show ? COMPTE_PASSWORD_HIDE : COMPTE_PASSWORD_SHOW}
        aria-pressed={show}
        aria-controls={id}
        disabled={rest.disabled}
      >
        {show ? <EyeOff size={18} aria-hidden /> : <Eye size={18} aria-hidden />}
      </button>
    </div>
  );
}
