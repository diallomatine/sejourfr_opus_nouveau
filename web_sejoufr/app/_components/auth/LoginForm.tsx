"use client";

import { Lock, Mail } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import { ApiException } from "@/lib/api";
import { splitServerErrors, validateLogin, type AuthFieldErrors } from "@/lib/auth-form";
import { useAuth } from "@/lib/auth-context";
import { AuthField } from "./AuthField";
import { AuthAlert, AuthSubmit, focusFirstError } from "./AuthForm";
import styles from "./auth.module.css";

const FIELD_ORDER = ["email", "password"] as const;

/**
 * LE formulaire de connexion — `/connexion` et les deux écrans de compte des
 * diagnostics invités (« J'ai déjà un compte ») le montent tel quel. Ce qui
 * suit la connexion (redirection, ou rien : l'écran de diagnostic observe la
 * bascule d'authentification) passe par `onLoggedIn`.
 */
export function LoginForm({
  submitLabel = "Se connecter",
  autoFocus = false,
  onLoggedIn,
}: {
  submitLabel?: string;
  autoFocus?: boolean;
  /** Après la connexion, par e-mail comme par Google. */
  onLoggedIn?: () => void;
}) {
  const { login } = useAuth();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<AuthFieldErrors>({});

  const clearField = (name: keyof AuthFieldErrors) =>
    setFieldErrors((prev) => (prev[name] ? { ...prev, [name]: undefined } : prev));

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);

    const fd = new FormData(e.currentTarget);
    const payload = {
      email: String(fd.get("email") ?? ""),
      password: String(fd.get("password") ?? ""),
    };

    const invalid = validateLogin(payload);
    setFieldErrors(invalid);
    if (Object.keys(invalid).length > 0) {
      focusFirstError(FIELD_ORDER, invalid);
      return;
    }

    setSubmitting(true);
    try {
      await login(payload);
      onLoggedIn?.();
    } catch (err) {
      if (err instanceof ApiException) {
        if (err.status === 401) {
          setError("Email ou mot de passe incorrect.");
        } else {
          const { fields, global } = splitServerErrors(err);
          setFieldErrors(fields);
          setError(global);
          focusFirstError(FIELD_ORDER, fields);
        }
      } else {
        setError("Impossible de se connecter. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <form onSubmit={handleSubmit} className={styles.form} noValidate suppressHydrationWarning>
        {error ? <AuthAlert>{error}</AuthAlert> : null}

        <AuthField
          id="email"
          name="email"
          type="email"
          label="Adresse e-mail"
          icon={Mail}
          autoComplete="email"
          placeholder="vous@exemple.com"
          autoFocus={autoFocus}
          disabled={submitting}
          error={fieldErrors.email}
          onChange={() => clearField("email")}
        />

        <AuthField
          id="password"
          name="password"
          type="password"
          label="Mot de passe"
          icon={Lock}
          autoComplete="current-password"
          placeholder="Votre mot de passe"
          disabled={submitting}
          error={fieldErrors.password}
          onChange={() => clearField("password")}
          labelAside={
            <Link href="/mot-de-passe-oublie" className={styles.labelLink}>
              Mot de passe oublié ?
            </Link>
          }
        />

        <AuthSubmit loading={submitting} label={submitLabel} loadingLabel="Connexion…" />
      </form>

      <GoogleSignInButton variant="signin" onSuccess={onLoggedIn} onError={setError} />
    </>
  );
}
