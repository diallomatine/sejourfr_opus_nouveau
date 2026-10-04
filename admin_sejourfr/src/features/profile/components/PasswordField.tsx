import { useState } from "react";
import { FormRow, Input } from "../../../components/ui/Form";
import { Icon } from "../../../components/ui/Icon";
import styles from "./ProfileForm.module.css";

interface PasswordFieldProps {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  autoComplete: "current-password" | "new-password";
  error?: string;
  hint?: string;
  disabled?: boolean;
}

/** Champ mot de passe avec bouton « Afficher / Masquer » (un par champ). */
export function PasswordField({ id, label, value, onChange, autoComplete, error, hint, disabled }: PasswordFieldProps) {
  const [visible, setVisible] = useState(false);
  const hintId = `${id}-hint`;
  return (
    <FormRow label={label} htmlFor={id} error={error}>
      <div className={styles.passwordWrap}>
        <Input
          id={id}
          type={visible ? "text" : "password"}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          autoComplete={autoComplete}
          aria-invalid={error ? true : undefined}
          aria-describedby={hint && !error ? hintId : undefined}
          disabled={disabled}
          spellCheck={false}
          autoCapitalize="off"
        />
        <button
          type="button"
          className={styles.reveal}
          onClick={() => setVisible((v) => !v)}
          aria-label={visible ? "Masquer le mot de passe" : "Afficher le mot de passe"}
          aria-pressed={visible}
          aria-controls={id}
          title={visible ? "Masquer le mot de passe" : "Afficher le mot de passe"}
          disabled={disabled}
        >
          <Icon name={visible ? "eyeOff" : "eye"} size={17} />
        </button>
      </div>
      {hint && !error && (
        <div id={hintId} className={styles.hint}>
          {hint}
        </div>
      )}
    </FormRow>
  );
}
