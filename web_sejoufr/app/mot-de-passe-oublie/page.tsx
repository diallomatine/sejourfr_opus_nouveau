"use client";

import { Check, Mail } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { AuthField } from "@/app/_components/auth/AuthField";
import { AuthAlert, AuthSubmit } from "@/app/_components/auth/AuthForm";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { SIGNIN_PANEL } from "@/app/_components/auth/auth-panels";
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
      kicker="Récupération de compte"
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
      panel={SIGNIN_PANEL}
    >
      {sent ? (
        <div className={`${styles.notice} ${styles.noticeSuccess}`}>
          <span className={styles.noticeIcon}>
            <Check size={22} strokeWidth={2.4} aria-hidden />
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
          />

          <AuthSubmit loading={submitting} label="Envoyer le lien" loadingLabel="Envoi…" />

          <p className={styles.backLink}>
            <Link href="/connexion">← Revenir à la connexion</Link>
          </p>
        </form>
      )}
    </AuthShell>
  );
}
