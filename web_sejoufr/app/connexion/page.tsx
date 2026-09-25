"use client";

import { Lock, Mail } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import { AuthField } from "@/app/_components/auth/AuthField";
import { AuthAlert, AuthSubmit, focusFirstError } from "@/app/_components/auth/AuthForm";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { SIGNIN_PANEL } from "@/app/_components/auth/auth-panels";
import styles from "@/app/_components/auth/auth.module.css";
import { ApiException } from "@/lib/api";
import { splitServerErrors, validateLogin, type AuthFieldErrors } from "@/lib/auth-form";
import { useAuth } from "@/lib/auth-context";
import { safeInternalPath } from "@/lib/security";

const FIELD_ORDER = ["email", "password"] as const;

export default function ConnexionPage() {
  return (
    <Suspense fallback={null}>
      <ConnexionInner />
    </Suspense>
  );
}

function ConnexionInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { login, status, user } = useAuth();
  const nextHref = safeInternalPath(search.get("next"), "/dashboard");
  const registerHref = `/inscription?next=${encodeURIComponent(nextHref)}`;
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<AuthFieldErrors>({});

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
      router.push(nextHref);
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
    <AuthShell
      kicker="Espace personnel"
      title={
        <>
          Heureux de vous <em>revoir</em>.
        </>
      }
      subtitle="Connectez-vous pour reprendre votre préparation là où vous l'avez laissée."
      panel={SIGNIN_PANEL}
    >
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
          autoFocus
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

        <AuthSubmit loading={submitting} label="Se connecter" loadingLabel="Connexion…" />
      </form>

      <GoogleSignInButton
        variant="signin"
        onSuccess={() => router.push(nextHref)}
        onError={setError}
      />

      <p className={styles.switchLine}>
        Nouveau sur SejourFR ?{" "}
        <Link href={registerHref} className={styles.switchLink}>
          Créer un compte gratuit
        </Link>
      </p>
    </AuthShell>
  );
}
