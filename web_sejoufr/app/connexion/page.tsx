"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { PasswordInput } from "@/app/_components/auth/PasswordInput";
import styles from "@/app/_components/auth/auth.module.css";
import { ApiException } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";

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
  const nextHref = search.get("next") ?? "/dashboard";
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (status === "authenticated" && user) {
      router.replace(nextHref);
    }
  }, [status, user, router, nextHref]);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    const fd = new FormData(e.currentTarget);
    const payload = {
      email: String(fd.get("email") ?? ""),
      password: String(fd.get("password") ?? ""),
    };

    try {
      await login(payload);
      router.push(nextHref);
    } catch (err) {
      if (err instanceof ApiException) {
        setError(err.status === 401 ? "Email ou mot de passe incorrect." : err.message);
      } else {
        setError("Impossible de se connecter. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      eyebrow="Espace personnel"
      eyebrowTone="blue"
      title={
        <>
          Heureux de vous <em>revoir</em>.
        </>
      }
      subtitle="Connectez-vous pour reprendre votre préparation là où vous l'avez laissée."
      visual={{
        tag: "ESPACE PERSONNEL · CONTINUITÉ",
        quote:
          "Le TCF B1 me faisait peur. Les exercices de compréhension orale m'ont vraiment préparé. J'ai eu ma carte de résident.",
        authorInitials: "VO",
        authorName: "Viktor O.",
        authorMeta: "CARTE DE RÉSIDENT · LYON",
        avatarTone: "blue",
      }}
    >
      <form onSubmit={handleSubmit} className={styles.form} noValidate>
        {error && (
          <div className="form-error" role="alert">
            {error}
          </div>
        )}

        <div className="field">
          <label htmlFor="email" className="field-label">
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            placeholder="vous@exemple.com"
            className="field-input"
            autoComplete="email"
            autoFocus
          />
        </div>

        <div className="field">
          <div className={styles.pwdRow}>
            <label htmlFor="password" className="field-label">
              Mot de passe
            </label>
            <Link href="/mot-de-passe-oublie" className={styles.pwdForgot}>
              Oublié ?
            </Link>
          </div>
          <PasswordInput
            id="password"
            name="password"
            placeholder="••••••••"
            autoComplete="current-password"
          />
        </div>

        <label className={styles.check}>
          <input type="checkbox" defaultChecked />
          <span>Rester connecté sur cet appareil</span>
        </label>

        <button type="submit" disabled={submitting} className={`${styles.submit} ${styles.submitBlue}`}>
          {submitting ? "Connexion…" : "Se connecter"}
          <span className={styles.submitArrow}>→</span>
        </button>

        <GoogleSignInButton
          variant="signin"
          onSuccess={() => router.push(nextHref)}
          onError={setError}
        />

        <p className={`${styles.switchLine} ${styles.switchLineTop}`}>
          Nouveau sur SejourFR ?{" "}
          <Link href="/inscription" className={`${styles.switchLink} ${styles.switchLinkRed}`}>
            Créer un compte gratuit →
          </Link>
        </p>
      </form>
    </AuthShell>
  );
}
