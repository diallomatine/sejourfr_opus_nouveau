"use client";

import { Lock, Mail, UserRound } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import { AuthField } from "@/app/_components/auth/AuthField";
import { AuthAlert, AuthSubmit, focusFirstError } from "@/app/_components/auth/AuthForm";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { SIGNUP_PANEL } from "@/app/_components/auth/auth-panels";
import styles from "@/app/_components/auth/auth.module.css";
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
import { safeInternalPath } from "@/lib/security";
import { TCF_LEVEL_BY_PROCEDURE, type TargetProcedure } from "@/lib/types";

/** Le palier exigé vient du référentiel partagé, jamais recopié ici :
 *  `TCF_LEVEL_BY_PROCEDURE` est le miroir gelé de l'enum `TargetProcedure`
 *  côté backend (cf. `lib/types.test.ts`). */
const MENTIONS: { v: TargetProcedure; code: string; name: string }[] = [
  { v: "CSP", code: "CSP", name: "Carte de séjour" },
  { v: "CR", code: "CR", name: "Carte de résident" },
  { v: "NAT", code: "NAT", name: "Naturalisation" },
];

const FIELD_ORDER = ["firstName", "lastName", "email", "password", "consent"] as const;

export default function InscriptionPage() {
  return (
    <Suspense fallback={null}>
      <InscriptionInner />
    </Suspense>
  );
}

function InscriptionInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { register, status, user } = useAuth();
  // Parcours d'achat depuis une landing : ?next=/paiement?plan=… ramène le
  // nouvel inscrit sur le pass qu'il venait de choisir, au lieu du dashboard.
  const nextHref = safeInternalPath(search.get("next"), "/dashboard");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<AuthFieldErrors>({});
  const [mention, setMention] = useState<TargetProcedure>("CSP");
  const [passwordLength, setPasswordLength] = useState(0);

  // D'où vient cette inscription ? La seule chose que le navigateur sache, ici,
  // c'est la destination demandée (`?next=`) et la page précédente. On n'en
  // déduit rien au-delà : le repli est `OTHER`, jamais une provenance inventée.
  const signupStarted = () =>
    track("SIGNUP_STARTED", {registrationContext: registrationContextOf(nextHref)}, {once: true});

  useEffect(() => {
    if (status === "authenticated" && user) {
      router.replace(nextHref);
    }
  }, [status, user, router, nextHref]);

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
      targetProcedure: mention,
    };

    const invalid = validateRegister({ ...payload, consent: fd.get("consent") === "on" });
    setFieldErrors(invalid);
    if (Object.keys(invalid).length > 0) {
      focusFirstError(FIELD_ORDER, invalid);
      return;
    }

    setSubmitting(true);
    try {
      await register(payload);
      router.push(nextHref);
    } catch (err) {
      if (err instanceof ApiException) {
        const { fields, global } = splitServerErrors(err);
        setFieldErrors(fields);
        setError(global);
        focusFirstError(FIELD_ORDER, fields);
      } else {
        setError("Impossible de créer le compte. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      kicker="Compte gratuit · sans carte bancaire"
      title={
        <>
          Commencez votre <em>préparation</em>.
        </>
      }
      subtitle="Un compte pour suivre votre niveau, votre plan et vos entraînements, sur le web comme sur l'application."
      panel={SIGNUP_PANEL}
    >
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

        <fieldset className={styles.mentions} disabled={submitting}>
          <legend className={styles.label}>Votre démarche</legend>
          <div className={styles.mentionGrid}>
            {MENTIONS.map((opt) => {
              const active = mention === opt.v;
              return (
                <label
                  key={opt.v}
                  className={`${styles.mentionOpt} ${active ? styles.mentionActive : ""}`}
                >
                  <input
                    type="radio"
                    name="mention"
                    value={opt.v}
                    checked={active}
                    onChange={() => setMention(opt.v)}
                  />
                  <span className={styles.mentionCode}>{opt.code}</span>
                  <span className={styles.mentionName}>{opt.name}</span>
                  <span className={styles.mentionTcf}>
                    TCF <strong>{TCF_LEVEL_BY_PROCEDURE[opt.v]}</strong>
                  </span>
                </label>
              );
            })}
          </div>
        </fieldset>

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

        <AuthSubmit
          loading={submitting}
          tone="red"
          label="Créer mon compte gratuit"
          loadingLabel="Création…"
        />
      </form>

      <div onClickCapture={signupStarted}>
        <GoogleSignInButton
          variant="signup"
          onSuccess={() => router.push(nextHref)}
          onError={setError}
        />
      </div>

      <p className={styles.switchLine}>
        Déjà un compte ?{" "}
        <Link
          href={`/connexion?next=${encodeURIComponent(nextHref)}`}
          className={styles.switchLink}
          onClick={() => track("LOGIN_CLICKED", {})}
        >
          Se connecter
        </Link>
      </p>
    </AuthShell>
  );
}

/**
 * Contexte d'inscription **déduit de faits**, jamais deviné : la destination
 * demandée après création du compte est la seule intention réellement connue à
 * cet instant.
 *
 * ⚠️ L'inscription faite *pendant* le diagnostic ne passe pas par ici : elle a
 * son propre écran (`DiagnosticAccountGate`), qui déclare `DURING_DIAGNOSTIC`.
 */
function registrationContextOf(nextHref: string): AnalyticsRegistrationContext {
  if (nextHref.startsWith("/diagnostic")) return "BEFORE_DIAGNOSTIC";
  if (nextHref.startsWith("/plan")) return "AFTER_DIAGNOSTIC";
  if (nextHref.startsWith("/paiement") || nextHref.startsWith("/tarifs")) return "PRICING";
  if (nextHref.startsWith("/reussir")) return "LANDING";
  return "OTHER";
}
