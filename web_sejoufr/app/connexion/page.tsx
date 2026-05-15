"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Brand } from "../_components/Brand";
import { ApiException, authApi } from "@/lib/api";

export default function ConnexionPage() {
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
      await authApi.login(payload);
      router.push("/");
    } catch (err) {
      if (err instanceof ApiException) {
        if (err.status === 401) {
          setError("Email ou mot de passe incorrect.");
        } else {
          setError(err.message);
        }
      } else {
        setError("Impossible de se connecter. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <div className="page-top">
        <Brand />
        <div className="top-link">
          Pas encore inscrit ?
          <Link href="/inscription">Créer un compte</Link>
        </div>
      </div>

      <div className="center-wrap">
        <div className="card">
          <span className="eyebrow">Espace personnel</span>
          <h1 className="h1-edit">
            Heureux de vous <em>revoir</em>.
          </h1>
          <p className="sub">Connectez-vous pour reprendre votre préparation.</p>

          <form onSubmit={handleSubmit} className="login-form">
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

            <div className="field">
              <div className="pwd-row">
                <label htmlFor="password" className="field-label">
                  Mot de passe
                </label>
                <Link href="#">Oublié ?</Link>
              </div>
              <input
                id="password"
                name="password"
                type="password"
                required
                placeholder="••••••••"
                className="field-input"
                autoComplete="current-password"
              />
            </div>

            <label className="remember">
              <input type="checkbox" defaultChecked />
              <span>Rester connecté sur cet appareil</span>
            </label>

            <button type="submit" disabled={submitting} className="btn-submit">
              {submitting ? "Connexion..." : "Se connecter"}
              <span>→</span>
            </button>
          </form>

          <p className="signup-prompt">
            Nouveau sur SejourFR ?<br />
            <Link href="/inscription">
              Créer un compte gratuit en 30 secondes →
            </Link>
          </p>
        </div>
      </div>

      <style>{`
        body {
          background-image:
            radial-gradient(at 10% 10%, var(--color-blue-light) 0px, transparent 50%),
            radial-gradient(at 90% 90%, var(--color-red-light) 0px, transparent 50%);
        }

        .page-top {
          max-width: 1180px; margin: 0 auto;
          padding: 24px 28px;
          display: flex; justify-content: space-between; align-items: center;
        }
        .top-link { font-size: 14px; color: var(--color-muted); }
        .top-link a { color: var(--color-blue); font-weight: 600; margin-left: 4px; }
        .top-link a:hover { color: var(--color-red); }

        .center-wrap {
          min-height: calc(100vh - 88px);
          display: flex; align-items: center; justify-content: center;
          padding: 40px 24px;
        }

        .card {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 18px;
          padding: 44px 44px 36px;
          max-width: 440px;
          width: 100%;
          box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18), 0 1px 2px rgba(15, 24, 57, 0.04);
        }

        .h1-edit {
          font-family: var(--font-display); font-weight: 500; font-size: 36px;
          line-height: 1.05; letter-spacing: -0.025em; margin: 12px 0 10px;
        }
        .h1-edit em { font-style: italic; color: var(--color-red); }
        .sub { color: var(--color-muted); font-size: 15px; margin: 0 0 28px; }

        .login-form { display: flex; flex-direction: column; gap: 16px; }

        .pwd-row { display: flex; justify-content: space-between; align-items: center; }
        .pwd-row a { font-size: 12px; color: var(--color-blue); font-weight: 600; }
        .pwd-row a:hover { color: var(--color-red); }

        .remember { display: flex; gap: 8px; align-items: center; font-size: 13.5px; color: var(--color-ink-2); }
        .remember input { width: 16px; height: 16px; accent-color: var(--color-blue); flex-shrink: 0; }

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
        .signup-prompt a { color: var(--color-red); font-weight: 600; }
        .signup-prompt a:hover { color: var(--color-red-dark); }

        @media (max-width: 480px) {
          .card { padding: 32px 26px 26px; }
          .h1-edit { font-size: 28px; }
        }
      `}</style>
    </>
  );
}
