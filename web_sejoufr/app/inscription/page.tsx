"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { PasswordInput } from "@/app/_components/auth/PasswordInput";
import styles from "@/app/_components/auth/auth.module.css";
import { ApiException } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { TargetProcedure } from "@/lib/types";

const MENTIONS: { v: TargetProcedure; code: string; name: string; tcf: string }[] = [
  { v: "CSP", code: "CSP", name: "Carte de séjour", tcf: "A2" },
  { v: "CR", code: "CR", name: "Carte de résident", tcf: "B1" },
  { v: "NAT", code: "NAT", name: "Naturalisation", tcf: "B2" },
];

export default function InscriptionPage() {
  const router = useRouter();
  const { register, status, user } = useAuth();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mention, setMention] = useState<TargetProcedure>("CSP");

  useEffect(() => {
    if (status === "authenticated" && user) {
      router.replace("/dashboard");
    }
  }, [status, user, router]);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    const fd = new FormData(e.currentTarget);
    const payload = {
      firstName: String(fd.get("firstName") ?? ""),
      lastName: String(fd.get("lastName") ?? ""),
      email: String(fd.get("email") ?? ""),
      password: String(fd.get("password") ?? ""),
      targetProcedure: mention,
    };

    try {
      await register(payload);
      router.push("/dashboard");
    } catch (err) {
      if (err instanceof ApiException) {
        const fields = err.payload?.fieldErrors;
        setError(fields ? Object.values(fields).join(" · ") : err.message);
      } else {
        setError("Impossible de créer le compte. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      eyebrow="Compte gratuit · 30 secondes"
      eyebrowTone="green"
      title={
        <>
          Commencez votre <em>préparation</em>.
        </>
      }
      subtitle="Pas de carte bancaire. 20 QCM offerts par module et un examen blanc complet pour chaque module."
      visual={{
        tag: "ILS ONT RÉUSSI · TRUST SCORE",
        quote:
          "37 sur 40 à l'examen civique après six semaines avec SejourFR. Les blancs sont identiques au format réel.",
        authorInitials: "FA",
        authorName: "Fatima A.",
        authorMeta: "NATURALISATION · MARSEILLE",
        avatarTone: "red",
      }}
    >
      <form onSubmit={handleSubmit} className={styles.form} noValidate>
        {error && (
          <div className="form-error" role="alert">
            {error}
          </div>
        )}

        <div className={styles.row2}>
          <div className="field">
            <label htmlFor="firstName" className="field-label">
              Prénom
            </label>
            <input
              id="firstName"
              name="firstName"
              type="text"
              required
              placeholder="Fatima"
              className="field-input"
              autoComplete="given-name"
            />
          </div>
          <div className="field">
            <label htmlFor="lastName" className="field-label">
              Nom
            </label>
            <input
              id="lastName"
              name="lastName"
              type="text"
              required
              placeholder="Achour"
              className="field-input"
              autoComplete="family-name"
            />
          </div>
        </div>

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
          />
        </div>

        <div className="field">
          <label htmlFor="password" className="field-label">
            Mot de passe
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
          <label className="field-label">Votre démarche</label>
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
                    TCF <strong>{opt.tcf}</strong>
                  </span>
                </label>
              );
            })}
          </div>
        </div>

        <label className={styles.check}>
          <input type="checkbox" required />
          <span>
            J&apos;accepte les <Link href="/cgu">Conditions générales</Link> et la{" "}
            <Link href="/confidentialite">Politique de confidentialité</Link>.
          </span>
        </label>

        <button type="submit" disabled={submitting} className={`${styles.submit} ${styles.submitRed}`}>
          {submitting ? "Création…" : "Créer mon compte gratuit"}
          <span className={styles.submitArrow}>→</span>
        </button>

        <GoogleSignInButton
          variant="signup"
          onSuccess={() => router.push("/dashboard")}
          onError={setError}
        />

        <p className={styles.switchLine}>
          Déjà un compte ?{" "}
          <Link href="/connexion" className={`${styles.switchLink} ${styles.switchLinkBlue}`}>
            Se connecter →
          </Link>
        </p>
      </form>
    </AuthShell>
  );
}
