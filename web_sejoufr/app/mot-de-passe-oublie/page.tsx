"use client";

import Link from "next/link";
import { useState } from "react";
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
      // Le backend retourne 200 OK même si l'email n'existe pas, pour ne pas
      // permettre l'énumération des comptes. On affiche donc toujours un
      // message neutre.
      setSent(email);
    } catch (err) {
      if (err instanceof ApiException) {
        setError(err.message);
      } else {
        setError("Impossible d'envoyer le mail. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="center-wrap">
      <div className="card">
        <span className="eyebrow">Réinitialisation</span>
        <h1 className="h1-edit">
          Mot de passe <em>oublié</em>.
        </h1>

        {sent ? (
          <>
            <p className="sub">
              Si <strong>{sent}</strong> correspond à un compte SejourFR, vous allez recevoir un lien de réinitialisation par email. Il est valable 1 heure.
            </p>
            <p className="sub-note">
              Pas reçu&nbsp;? Vérifiez vos spams ou{" "}
              <button
                type="button"
                className="link-btn"
                onClick={() => {
                  setSent(null);
                  setError(null);
                }}
              >
                réessayez avec un autre email
              </button>
              .
            </p>
            <Link href="/connexion" className="btn btn-ghost full">
              ← Retour à la connexion
            </Link>
          </>
        ) : (
          <>
            <p className="sub">
              Saisissez votre email&nbsp;: nous vous enverrons un lien pour choisir un nouveau mot de passe.
            </p>

            <form onSubmit={handleSubmit} className="reset-form">
              {error && <div className="form-error">{error}</div>}

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

              <button type="submit" disabled={submitting} className="btn-submit">
                {submitting ? "Envoi..." : "Envoyer le lien"}
                <span>→</span>
              </button>
            </form>

            <p className="signup-prompt">
              <Link href="/connexion">← Revenir à la connexion</Link>
            </p>
          </>
        )}
      </div>

      <style>{`
        body {
          background-image:
            radial-gradient(at 10% 10%, var(--color-blue-light) 0px, transparent 50%),
            radial-gradient(at 90% 90%, var(--color-red-light) 0px, transparent 50%);
        }
        .center-wrap {
          min-height: calc(100vh - 140px);
          display: flex; align-items: center; justify-content: center;
          padding: 40px 24px;
        }
        .card {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 18px;
          padding: 44px 44px 36px;
          max-width: 440px; width: 100%;
          box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
        }
        .h1-edit {
          font-family: var(--font-display); font-weight: 500; font-size: 36px;
          line-height: 1.05; letter-spacing: -0.025em; margin: 12px 0 10px;
        }
        .h1-edit em { font-style: italic; color: var(--color-red); }
        .sub {
          color: var(--color-muted); font-size: 15px;
          margin: 0 0 24px; line-height: 1.55;
        }
        .sub strong { color: var(--color-ink); font-weight: 600; }
        .sub-note {
          color: var(--color-muted); font-size: 13.5px;
          margin: 0 0 24px; line-height: 1.55;
        }
        .reset-form { display: flex; flex-direction: column; gap: 18px; }
        .btn-submit {
          background: var(--color-blue); color: #fff; border: none; border-radius: 10px;
          padding: 14px 22px; font-size: 15px; font-weight: 600;
          font-family: var(--font-sans);
          cursor: pointer; transition: all 0.15s;
          display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-submit:hover { background: var(--color-blue-dark); transform: translateY(-1px); }
        .btn-submit:disabled { opacity: 0.7; cursor: not-allowed; transform: none; }
        .signup-prompt {
          text-align: center; margin-top: 26px; font-size: 14px; color: var(--color-muted);
          padding-top: 22px; border-top: 1px solid var(--color-line-2);
        }
        .signup-prompt a { color: var(--color-blue); font-weight: 600; }
        .link-btn {
          background: none; border: none; padding: 0;
          color: var(--color-blue); font-weight: 600; cursor: pointer;
          font-family: inherit; font-size: inherit;
          text-decoration: underline;
        }
        .full { width: 100%; }
        @media (max-width: 480px) {
          .card { padding: 32px 26px 26px; }
          .h1-edit { font-size: 28px; }
        }
      `}</style>
    </div>
  );
}
