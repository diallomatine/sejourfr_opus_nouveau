"use client";

import { Lock, Mail, UserRound } from "lucide-react";
import Link from "next/link";
import { useState, type ReactNode } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import { track, type AnalyticsRegistrationContext } from "@/lib/analytics";
import { ApiException } from "@/lib/api";
import {
  AUTH_PASSWORD_MIN,
  AUTH_PASSWORD_RULE,
  splitServerErrors,
  validateRegister,
  type AuthFieldErrors,
} from "@/lib/auth-form";
import { useAuth } from "@/lib/auth-context";
import type { TargetProcedure } from "@/lib/types";
import { AuthField } from "./AuthField";
import { AuthAlert, AuthSubmit, focusFirstError } from "./AuthForm";
import { DemarcheField } from "./DemarcheField";
import styles from "./auth.module.css";

const FIELD_ORDER = ["firstName", "lastName", "email", "password", "targetProcedure", "consent"] as const;

/**
 * LE formulaire d'inscription — `/inscription` et les deux écrans de compte
 * des diagnostics invités le montent tel quel. Ce qui change d'un écran à
 * l'autre passe en props : le libellé du bouton, la démarche préremplie, un
 * champ de plus, et ce qui se passe APRÈS la création du compte.
 *
 * 🛑 **La démarche n'est jamais pré-cochée** (2026-09-26, demande du
 * propriétaire) : elle valait CSP par défaut, donc un candidat pressé
 * s'inscrivait « Carte de séjour » sans l'avoir choisi. Seul `initialMention`
 * la préremplit, et uniquement avec une réponse que le candidat a déjà donnée
 * (la démarche déclarée avant le diagnostic civique).
 *
 * 🛑 Le rattachement d'une session invitée et le lancement d'une analyse ne se
 * font PAS ici : ils partent de l'écran qui observe la bascule
 * d'authentification (`DiagnosticView`, `CivicDiagnosticResult`). Deux
 * appelants pour la même adoption, ce serait deux chemins à tenir.
 */
export function RegisterForm({
  registrationContext,
  initialMention,
  submitLabel = "Créer mon compte gratuit",
  extraFields,
  onRegistered,
  onGoogleSuccess,
}: {
  /** `SIGNUP_STARTED` à la première frappe ; absent ⇒ aucun événement. */
  registrationContext?: AnalyticsRegistrationContext;
  /** Une démarche DÉJÀ déclarée par le candidat — jamais un défaut. */
  initialMention?: TargetProcedure;
  submitLabel?: string;
  /** Rendu entre la démarche et le consentement. */
  extraFields?: ReactNode;
  /** Après la création du compte ; reçoit le formulaire pour ses champs en plus. */
  onRegistered?: (form: FormData) => void | Promise<void>;
  onGoogleSuccess?: () => void;
}) {
  const { register } = useAuth();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<AuthFieldErrors>({});
  const [mention, setMention] = useState<TargetProcedure | null>(initialMention ?? null);
  const [passwordLength, setPasswordLength] = useState(0);

  // Une inscription **commencée**, c'est la première frappe — pas l'ouverture
  // de l'écran. `once` : une seule fois par onglet.
  const signupStarted = registrationContext
    ? () => track("SIGNUP_STARTED", { registrationContext }, { once: true })
    : undefined;

  const clearField = (name: keyof AuthFieldErrors) =>
    setFieldErrors((prev) => (prev[name] ? { ...prev, [name]: undefined } : prev));

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);

    const fd = new FormData(e.currentTarget);
    const payload = {
      firstName: String(fd.get("firstName") ?? ""),
      lastName: String(fd.get("lastName") ?? ""),
      email: String(fd.get("email") ?? ""),
      password: String(fd.get("password") ?? ""),
    };

    const invalid = validateRegister({
      ...payload,
      targetProcedure: mention,
      consent: fd.get("consent") === "on",
    });
    setFieldErrors(invalid);
    if (Object.keys(invalid).length > 0 || !mention) {
      focusFirstError(FIELD_ORDER, invalid);
      return;
    }

    setSubmitting(true);
    try {
      await register({ ...payload, targetProcedure: mention });
    } catch (err) {
      if (err instanceof ApiException) {
        const { fields, global } = splitServerErrors(err);
        setFieldErrors(fields);
        setError(global);
        focusFirstError(FIELD_ORDER, fields);
      } else {
        setError("Impossible de créer le compte. Réessayez dans un instant.");
      }
      setSubmitting(false);
      return;
    }
    // Hors du `try` : un échec de la suite ne doit jamais se lire comme un
    // compte non créé.
    await onRegistered?.(fd);
    setSubmitting(false);
  }

  return (
    <>
      <form
        onSubmit={handleSubmit}
        onInput={signupStarted}
        className={styles.form}
        noValidate
        suppressHydrationWarning
      >
        {error ? <AuthAlert>{error}</AuthAlert> : null}

        <div className={styles.row2}>
          <AuthField
            id="firstName"
            name="firstName"
            label="Prénom"
            icon={UserRound}
            autoComplete="given-name"
            disabled={submitting}
            error={fieldErrors.firstName}
            onChange={() => clearField("firstName")}
          />
          <AuthField
            id="lastName"
            name="lastName"
            label="Nom"
            autoComplete="family-name"
            disabled={submitting}
            error={fieldErrors.lastName}
            onChange={() => clearField("lastName")}
          />
        </div>

        <AuthField
          id="email"
          name="email"
          type="email"
          label="Adresse e-mail"
          icon={Mail}
          autoComplete="email"
          placeholder="vous@exemple.com"
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
          autoComplete="new-password"
          disabled={submitting}
          error={fieldErrors.password}
          requirement={{ label: AUTH_PASSWORD_RULE, met: passwordLength >= AUTH_PASSWORD_MIN }}
          onChange={(v) => {
            setPasswordLength(v.length);
            clearField("password");
          }}
        />

        <DemarcheField
          value={mention}
          disabled={submitting}
          error={fieldErrors.targetProcedure}
          onChange={(v) => {
            setMention(v);
            clearField("targetProcedure");
          }}
        />

        {extraFields}

        <div className={styles.consent}>
          <label className={styles.check}>
            <input
              id="consent"
              name="consent"
              type="checkbox"
              required
              disabled={submitting}
              aria-invalid={fieldErrors.consent ? true : undefined}
              aria-describedby={fieldErrors.consent ? "consent-error" : undefined}
              onChange={() => clearField("consent")}
            />
            <span>
              J&apos;accepte les <Link href="/cgu">Conditions générales</Link> et la{" "}
              <Link href="/confidentialite">Politique de confidentialité</Link>.
            </span>
          </label>
          {fieldErrors.consent ? (
            <p id="consent-error" className={styles.fieldError}>
              {fieldErrors.consent}
            </p>
          ) : null}
        </div>

        <AuthSubmit loading={submitting} tone="red" label={submitLabel} loadingLabel="Création…" />
      </form>

      <div onClickCapture={signupStarted}>
        <GoogleSignInButton variant="signup" onSuccess={onGoogleSuccess} onError={setError} />
      </div>
    </>
  );
}
