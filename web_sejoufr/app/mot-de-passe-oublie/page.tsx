"use client";

import Link from "next/link";
import { useState } from "react";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import styles from "@/app/_components/auth/auth.module.css";
import { ApiException, authApi } from "@/lib/api";

export default function MotDePasseOubliePage() {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    const fd = new FormData(e.currentTarget);
    const email = String(fd.get("email") ?? "").trim();

    try {
      await authApi.forgotPassword(email);
      // Le backend renvoie 200 même si l'email n'existe pas (anti-énumération) :
      // on affiche toujours le même message neutre.
      setSent(email);
    } catch (err) {
      setError(
        err instanceof ApiException
          ? err.message
          : "Impossible d'envoyer le mail. Réessayez dans un instant.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      eyebrow="Récupération de compte"
      eyebrowTone="blue"
      title={
        <>
          Mot de passe <em>oublié</em>.
        </>
      }
      subtitle={
        sent
          ? "Vérifiez votre boîte mail."
          : "Saisissez votre email — nous vous enverrons un lien pour choisir un nouveau mot de passe."
      }
      visual={{
        tag: "RÉCUPÉRATION · SÉCURITÉ",
        quote:
          "J'avais perdu l'accès à mon compte avant l'examen. Le lien de réinitialisation est arrivé en quelques secondes, tout était intact.",
        authorInitials: "VO",
        authorName: "Viktor O.",
        authorMeta: "CARTE DE RÉSIDENT · LYON",
        avatarTone: "blue",
      }}
    >
      {sent ? (
        <div className={`${styles.notice} ${styles.noticeSuccess}`}>
          <span className={styles.noticeIcon}>
            <CheckIcon />
          </span>
          <p className={styles.noticeTitle}>Email envoyé.</p>
          <p className={styles.noticeText}>
            Si <strong>{sent}</strong> correspond à un compte SejourFR, vous
            recevrez un lien de réinitialisation, valable 1 heure.
          </p>
          <div className={styles.noticeActions}>
            <Link href="/connexion" className={`${styles.submit} ${styles.submitOutline}`}>
              ← Retour à la connexion
            </Link>
            <button
              type="button"
              onClick={() => {
                setSent(null);
                setError(null);
              }}
              className={styles.retry}
            >
              Pas reçu ? Réessayer avec un autre email
            </button>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className={styles.form} noValidate suppressHydrationWarning>
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
              suppressHydrationWarning
            />
          </div>

          <button type="submit" disabled={submitting} className={`${styles.submit} ${styles.submitBlue}`}>
            {submitting ? "Envoi…" : "Envoyer le lien"}
            <span className={styles.submitArrow}>→</span>
          </button>

          <p className={styles.backLink}>
            <Link href="/connexion">← Revenir à la connexion</Link>
          </p>
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
