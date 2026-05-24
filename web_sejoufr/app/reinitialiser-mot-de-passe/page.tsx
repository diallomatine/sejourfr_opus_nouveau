"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { PasswordInput } from "@/app/_components/auth/PasswordInput";
import styles from "@/app/_components/auth/auth.module.css";
import { ApiException, authApi } from "@/lib/api";

export default function ReinitialiserMotDePassePage() {
  return (
    <Suspense fallback={null}>
      <ResetInner />
    </Suspense>
  );
}

const VISUAL = {
  tag: "SÉCURITÉ · NOUVEAU MOT DE PASSE",
  quote:
    "Réinitialisation simple et rapide. Mes statistiques et mes favoris étaient toujours là après reconnexion.",
  authorInitials: "VO",
  authorName: "Viktor O.",
  authorMeta: "CARTE DE RÉSIDENT · LYON",
  avatarTone: "blue" as const,
};

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
        eyebrow="Lien invalide"
        eyebrowTone="blue"
        title={
          <>
            Lien de <em>réinitialisation</em> incomplet.
          </>
        }
        subtitle="Le lien est incomplet ou a expiré. Demandez-en un nouveau."
        visual={VISUAL}
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
      eyebrow="Nouveau mot de passe"
      eyebrowTone="blue"
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
      visual={VISUAL}
    >
      {done ? (
        <div className={`${styles.notice} ${styles.noticeSuccess}`}>
          <span className={styles.noticeIcon}>
            <CheckIcon />
          </span>
          <p className={styles.noticeTitle}>Mot de passe modifié.</p>
          <p className={styles.noticeText}>Redirection vers la connexion…</p>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className={styles.form} noValidate suppressHydrationWarning>
          {error && (
            <div className="form-error" role="alert">
              {error}
            </div>
          )}

          <div className="field">
            <label htmlFor="password" className="field-label">
              Nouveau mot de passe
            </label>
            <PasswordInput
              id="password"
              name="password"
              placeholder="8 caractères minimum"
              autoComplete="new-password"
              minLength={8}
            />
          </div>

          <div className="field">
            <label htmlFor="confirm" className="field-label">
              Confirmer
            </label>
            <PasswordInput
              id="confirm"
              name="confirm"
              placeholder="Le même mot de passe"
              autoComplete="new-password"
              minLength={8}
            />
          </div>

          <button type="submit" disabled={submitting} className={`${styles.submit} ${styles.submitBlue}`}>
            {submitting ? "Enregistrement…" : "Réinitialiser le mot de passe"}
            <span className={styles.submitArrow}>→</span>
          </button>
        </form>
      )}
    </AuthShell>
  );
}

const CheckIcon = () => (
  <svg
    width="22"
    height="22"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.4"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden
  >
    <polyline points="20 6 9 17 4 12" />
  </svg>
);
