"use client";

import { Check, Lock } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { AuthField } from "@/app/_components/auth/AuthField";
import { AuthAlert, AuthSubmit } from "@/app/_components/auth/AuthForm";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { SIGNIN_PANEL } from "@/app/_components/auth/auth-panels";
import styles from "@/app/_components/auth/auth.module.css";
import { ApiException, authApi } from "@/lib/api";

export default function ReinitialiserMotDePassePage() {
  return (
    <Suspense fallback={null}>
      <ResetInner />
    </Suspense>
  );
}

function ResetInner() {
  const router = useRouter();
  const search = useSearchParams();
  const token = search.get("token") ?? "";
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);

    const fd = new FormData(e.currentTarget);
    const pwd = String(fd.get("password") ?? "");
    const confirm = String(fd.get("confirm") ?? "");

    if (pwd !== confirm) {
      setError("Les deux mots de passe ne correspondent pas.");
      return;
    }
    if (pwd.length < 8) {
      setError("Le mot de passe doit faire au moins 8 caractères.");
      return;
    }

    setSubmitting(true);
    try {
      await authApi.resetPassword(token, pwd);
      setDone(true);
      setTimeout(() => router.push("/connexion"), 1800);
    } catch (err) {
      if (err instanceof ApiException && (err.status === 400 || err.status === 404)) {
        setError("Lien expiré ou invalide. Demandez-en un nouveau.");
      } else if (err instanceof ApiException) {
        setError(err.message);
      } else {
        setError("Impossible de réinitialiser. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  if (!token) {
    return (
      <AuthShell
        kicker="Lien invalide"
        title={
          <>
            Lien de <em>réinitialisation</em> incomplet.
          </>
        }
        subtitle="Le lien est incomplet ou a expiré. Demandez-en un nouveau."
        panel={SIGNIN_PANEL}
      >
        <div className={`${styles.notice} ${styles.noticeError}`}>
          <p className={styles.noticeText}>
            Le lien de réinitialisation ne contient pas de jeton valide.
          </p>
          <div className={styles.noticeActions}>
            <Link href="/mot-de-passe-oublie" className={`${styles.submit} ${styles.submitBlue}`}>
              Demander un nouveau lien
            </Link>
          </div>
        </div>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      kicker="Nouveau mot de passe"
      title={
        <>
          Choisissez un <em>nouveau mot de passe</em>.
        </>
      }
      subtitle={
        done
          ? "C'est fait."
          : "Au moins 8 caractères. Évitez ceux de vos autres comptes."
      }
      panel={SIGNIN_PANEL}
    >
      {done ? (
        <div className={`${styles.notice} ${styles.noticeSuccess}`}>
          <span className={styles.noticeIcon}>
            <Check size={22} strokeWidth={2.4} aria-hidden />
          </span>
          <p className={styles.noticeTitle}>Mot de passe modifié.</p>
          <p className={styles.noticeText}>Redirection vers la connexion…</p>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className={styles.form} noValidate suppressHydrationWarning>
          {error ? <AuthAlert>{error}</AuthAlert> : null}

          <AuthField
            id="password"
            name="password"
            type="password"
            label="Nouveau mot de passe"
            icon={Lock}
            placeholder="8 caractères minimum"
            autoComplete="new-password"
            disabled={submitting}
          />

          <AuthField
            id="confirm"
            name="confirm"
            type="password"
            label="Confirmer"
            icon={Lock}
            placeholder="Le même mot de passe"
            autoComplete="new-password"
            disabled={submitting}
          />

          <AuthSubmit
            loading={submitting}
            label="Réinitialiser le mot de passe"
            loadingLabel="Enregistrement…"
          />
        </form>
      )}
    </AuthShell>
  );
}
