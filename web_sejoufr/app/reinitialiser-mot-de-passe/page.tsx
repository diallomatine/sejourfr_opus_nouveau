"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
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
      // Petit délai avant la redirection pour que le user voie le succès.
      setTimeout(() => router.push("/connexion"), 1800);
    } catch (err) {
      if (err instanceof ApiException) {
        if (err.status === 400 || err.status === 404) {
          setError("Lien expiré ou invalide. Demandez-en un nouveau.");
        } else {
          setError(err.message);
        }
      } else {
        setError("Impossible de réinitialiser. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  if (!token) {
    return (
      <div className="center-wrap">
        <div className="card">
          <span className="eyebrow">Lien invalide</span>
          <h1 className="h1-edit">
            Aucun token de <em>réinitialisation</em>.
          </h1>
          <p className="sub">
            Le lien de réinitialisation est incomplet. Demandez un nouveau lien.
          </p>
          <Link href="/mot-de-passe-oublie" className="btn btn-red full">
            Demander un nouveau lien
          </Link>
        </div>
        <PageStyles />
      </div>
    );
  }

  return (
    <div className="center-wrap">
      <div className="card">
        <span className="eyebrow">Nouveau mot de passe</span>
        <h1 className="h1-edit">
          Choisissez un <em>nouveau mot de passe</em>.
        </h1>

        {done ? (
          <>
            <p className="sub success">
              ✓ Mot de passe modifié. Redirection vers la connexion…
            </p>
          </>
        ) : (
          <>
            <p className="sub">Au moins 8 caractères. Évitez ceux de vos autres comptes.</p>

            <form onSubmit={handleSubmit} className="reset-form">
              {error && <div className="form-error">{error}</div>}

              <div className="field">
                <label htmlFor="password" className="field-label">
                  Nouveau mot de passe
                </label>
                <input
                  id="password"
                  name="password"
                  type="password"
                  required
                  minLength={8}
                  placeholder="8 caractères minimum"
                  className="field-input"
                  autoComplete="new-password"
                />
              </div>

              <div className="field">
                <label htmlFor="confirm" className="field-label">
                  Confirmer
                </label>
                <input
                  id="confirm"
                  name="confirm"
                  type="password"
                  required
                  minLength={8}
                  placeholder="Le même"
                  className="field-input"
                  autoComplete="new-password"
                />
              </div>

              <button type="submit" disabled={submitting} className="btn-submit">
                {submitting ? "Enregistrement..." : "Réinitialiser le mot de passe"}
                <span>→</span>
              </button>
            </form>
          </>
        )}
      </div>
      <PageStyles />
    </div>
  );
}

function PageStyles() {
  return (
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
        font-family: var(--font-display); font-weight: 500; font-size: 32px;
        line-height: 1.05; letter-spacing: -0.025em; margin: 12px 0 10px;
      }
      .h1-edit em { font-style: italic; color: var(--color-red); }
      .sub { color: var(--color-muted); font-size: 15px; margin: 0 0 24px; line-height: 1.55; }
      .sub.success { color: var(--color-green); font-weight: 600; }
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
      .full { width: 100%; }
      @media (max-width: 480px) {
        .card { padding: 32px 26px 26px; }
        .h1-edit { font-size: 26px; }
      }
    `}</style>
  );
}
