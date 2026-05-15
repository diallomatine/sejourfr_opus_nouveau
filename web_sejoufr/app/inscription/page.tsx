"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Brand } from "../_components/Brand";
import { ApiException, authApi } from "@/lib/api";
import type { TargetProcedure } from "@/lib/types";

export default function InscriptionPage() {
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mention, setMention] = useState<TargetProcedure>("CSP");

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
      await authApi.register(payload);
      // Inscription OK → redirection vers la page principale (ou un /dashboard plus tard)
      router.push("/?welcome=1");
    } catch (err) {
      if (err instanceof ApiException) {
        const fields = err.payload?.fieldErrors;
        if (fields) {
          setError(Object.values(fields).join(" · "));
        } else {
          setError(err.message);
        }
      } else {
        setError("Impossible de créer le compte. Réessayez dans un instant.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="auth-wrap">
      {/* LEFT : FORM */}
      <div className="auth-form-side">
        <div className="auth-top">
          <Brand />
          <div className="top-link">
            Déjà un compte ?
            <Link href="/connexion">Se connecter</Link>
          </div>
        </div>

        <div className="auth-inner">
          <span className="eyebrow">Compte gratuit · 30 secondes</span>
          <h1 className="h1-edit">
            Commencez votre <em>préparation</em>.
          </h1>
          <p className="sub">
            Pas de carte bancaire. 10 QCM par catégorie offerts et un examen
            blanc complet pour chaque module.
          </p>

          <form onSubmit={handleSubmit} className="auth-form">
            {error && <div className="form-error">{error}</div>}

            <div className="row-2">
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
              <label className="field-label">Votre démarche</label>
              <div className="mention-grid">
                {(
                  [
                    { v: "CSP", code: "CSP", name: "Carte de séjour" },
                    { v: "CR", code: "CR", name: "Carte de résident" },
                    { v: "NAT", code: "NAT", name: "Naturalisation" },
                  ] as const
                ).map((opt) => (
                  <label
                    key={opt.v}
                    className={`mention-opt ${mention === opt.v ? "active" : ""}`}
                  >
                    <input
                      type="radio"
                      name="mention"
                      value={opt.v}
                      checked={mention === opt.v}
                      onChange={() => setMention(opt.v)}
                    />
                    <span className="code">{opt.code}</span>
                    <span className="name">{opt.name}</span>
                  </label>
                ))}
              </div>
            </div>

            <label className="check">
              <input type="checkbox" required />
              <span>
                J'accepte les <Link href="#">Conditions générales</Link> et la{" "}
                <Link href="#">Politique de confidentialité</Link>.
              </span>
            </label>

            <button type="submit" disabled={submitting} className="btn-submit">
              {submitting ? "Création..." : "Créer mon compte gratuit"}
              <span>→</span>
            </button>
          </form>

          <p className="legal">
            Vos données sont hébergées en France · Conforme RGPD
            <br />
            Aucune donnée transmise à des tiers sans votre accord.
          </p>
        </div>
      </div>

      {/* RIGHT : VISUAL */}
      <div className="auth-visual-side">
        <div className="visual-content">
          <div className="visual-top">Ils ont réussi · Trust score</div>

          <div className="visual-quote">
            <h2>
              « 37/40 à l'examen civique après six semaines avec SejourFR. Les
              blancs sont identiques au format réel. »
            </h2>
            <div className="author">
              <div className="avatar">FA</div>
              <div>
                <div className="name">Fatima A.</div>
                <div className="meta">Naturalisation · Marseille</div>
              </div>
            </div>
          </div>

          <div className="trust-grid">
            <div className="trust-item">
              <h4>
                8 200<span className="accent">+</span>
              </h4>
              <p>Candidats inscrits</p>
            </div>
            <div className="trust-item">
              <h4>
                94 <span className="accent">%</span>
              </h4>
              <p>Taux de réussite</p>
            </div>
            <div className="trust-item">
              <h4>
                1 240<span className="accent">+</span>
              </h4>
              <p>Questions calibrées</p>
            </div>
            <div className="trust-item">
              <h4>
                4,8<span className="accent">/5</span>
              </h4>
              <p>Note des utilisateurs</p>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .auth-wrap { min-height: 100vh; display: grid; grid-template-columns: 1fr 1fr; }

        .auth-form-side { padding: 32px 48px; display: flex; flex-direction: column; background: var(--color-paper); }
        .auth-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 56px; }
        .top-link { font-size: 14px; color: var(--color-muted); }
        .top-link a { color: var(--color-blue); font-weight: 600; margin-left: 4px; }
        .top-link a:hover { color: var(--color-red); }

        .auth-inner { max-width: 440px; margin: 0 auto; width: 100%; flex: 1; display: flex; flex-direction: column; justify-content: center; padding-bottom: 48px; }

        .h1-edit {
          font-family: var(--font-display); font-weight: 500; font-size: 42px;
          line-height: 1.05; letter-spacing: -0.025em; margin: 14px 0 12px;
        }
        .h1-edit em { font-style: italic; color: var(--color-red); }
        .sub { color: var(--color-muted); font-size: 16px; margin: 0 0 36px; }

        .auth-form { display: flex; flex-direction: column; gap: 18px; }
        .row-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

        .mention-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
        .mention-opt {
          border: 1px solid var(--color-line); border-radius: 10px; background: #fff;
          padding: 14px 10px; text-align: center; cursor: pointer;
          transition: all 0.15s;
          display: flex; flex-direction: column; gap: 4px;
          position: relative;
        }
        .mention-opt:hover { border-color: var(--color-ink-2); }
        .mention-opt input { position: absolute; opacity: 0; pointer-events: none; }
        .mention-opt .code {
          font-family: var(--font-mono); font-size: 12px;
          font-weight: 500; color: var(--color-blue); letter-spacing: 0.05em;
        }
        .mention-opt .name { font-size: 12px; color: var(--color-muted); }
        .mention-opt.active {
          border-color: var(--color-blue); background: var(--color-blue-light); border-width: 2px; padding: 13px 9px;
        }
        .mention-opt.active .code { color: var(--color-blue-dark); }
        .mention-opt.active .name { color: var(--color-ink-2); font-weight: 500; }

        .check { display: flex; gap: 10px; align-items: flex-start; font-size: 13.5px; color: var(--color-ink-2); line-height: 1.5; }
        .check input { width: 16px; height: 16px; margin-top: 2px; accent-color: var(--color-blue); flex-shrink: 0; }
        .check a { color: var(--color-blue); font-weight: 600; }

        .btn-submit {
          background: var(--color-red); color: #fff; border: none; border-radius: 10px;
          padding: 14px 22px; font-size: 15px; font-weight: 600;
          font-family: var(--font-sans);
          cursor: pointer; transition: all 0.15s;
          display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-submit:hover { background: var(--color-red-dark); transform: translateY(-1px); }
        .btn-submit:disabled { opacity: 0.7; cursor: not-allowed; transform: none; }

        .legal { margin-top: 28px; font-size: 12px; color: var(--color-muted-2); text-align: center; line-height: 1.5; }

        .auth-visual-side {
          background: var(--color-blue); color: #fff; padding: 48px;
          position: relative; overflow: hidden;
          display: flex; flex-direction: column;
        }
        .auth-visual-side::before {
          content: ''; position: absolute; inset: 0;
          background: radial-gradient(circle at 20% 20%, rgba(255,255,255,0.06) 0%, transparent 40%),
                      radial-gradient(circle at 80% 80%, rgba(225,55,47,0.25) 0%, transparent 50%);
          pointer-events: none;
        }
        .visual-content { position: relative; z-index: 1; flex: 1; display: flex; flex-direction: column; justify-content: space-between; }

        .visual-top {
          display: flex; align-items: center; gap: 10px;
          font-family: var(--font-mono); font-size: 11px;
          letter-spacing: 0.14em; text-transform: uppercase; color: rgba(255,255,255,0.55);
        }
        .visual-top::before {
          content: ''; width: 24px; height: 1px; background: rgba(255,255,255,0.4);
        }

        .visual-quote h2 {
          font-family: var(--font-display); font-weight: 400; font-style: italic;
          font-size: 32px; line-height: 1.2; letter-spacing: -0.015em;
          color: #fff; margin: 0 0 28px;
        }
        .visual-quote .author { display: flex; gap: 12px; align-items: center; }
        .visual-quote .avatar {
          width: 44px; height: 44px; border-radius: 50%;
          background: var(--color-red); color: #fff;
          display: flex; align-items: center; justify-content: center;
          font-weight: 700;
        }
        .visual-quote .name { font-weight: 600; font-size: 15px; }
        .visual-quote .meta {
          font-family: var(--font-mono); font-size: 11px;
          color: rgba(255,255,255,0.55); letter-spacing: 0.08em;
        }

        .trust-grid {
          display: grid; grid-template-columns: repeat(2, 1fr); gap: 18px;
          border-top: 1px solid rgba(255,255,255,0.12);
          padding-top: 32px;
        }
        .trust-item h4 {
          font-family: var(--font-display); font-weight: 500; font-size: 28px;
          margin: 0 0 4px; letter-spacing: -0.02em;
        }
        .trust-item h4 .accent { color: #ffb3b0; }
        .trust-item p {
          font-family: var(--font-mono); font-size: 10.5px;
          letter-spacing: 0.12em; text-transform: uppercase;
          color: rgba(255,255,255,0.6); margin: 0;
        }

        @media (max-width: 900px) {
          .auth-wrap { grid-template-columns: 1fr; }
          .auth-visual-side { display: none; }
          .auth-form-side { padding: 24px; }
        }
        @media (max-width: 480px) {
          .row-2 { grid-template-columns: 1fr; }
          .mention-grid { grid-template-columns: 1fr; }
          .h1-edit { font-size: 32px; }
        }
      `}</style>
    </div>
  );
}
