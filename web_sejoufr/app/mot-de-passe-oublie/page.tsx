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
      // Le backend retourne 200 OK même si l'email n'existe pas (anti-énumération),
      // donc on affiche toujours le même message neutre.
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

  function handleRetry() {
    setSent(null);
    setError(null);
  }

  return (
    <div className="auth-wrap">
      {/* ============ LEFT : FORM ============ */}
      <div className="form-side">
        <Link href="/" className="form-brand" aria-label="Retour à l'accueil SejourFR">
          <span className="form-cocarde" aria-hidden />
          <span className="form-wordmark">
            Sejour<span className="fr">FR</span>
          </span>
        </Link>

        <div className="form-inner">
          <div className="form-eyebrow">
            <KeyIcon />
            Récupération de compte
          </div>
          <h1 className="form-h1">
            Mot de passe <em>oublié</em>.
          </h1>

          {sent ? (
            <SuccessState email={sent} onRetry={handleRetry} />
          ) : (
            <>
              <p className="form-sub">
                Saisissez votre email — nous vous enverrons un lien pour
                choisir un nouveau mot de passe.
              </p>

              <form onSubmit={handleSubmit} className="form" noValidate>
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

                <button
                  type="submit"
                  disabled={submitting}
                  className="form-submit"
                >
                  {submitting ? "Envoi…" : "Envoyer le lien"}
                  <span className="form-submit-arrow">→</span>
                </button>

                <p className="form-back">
                  <Link href="/connexion" className="form-back-link">
                    ← Revenir à la connexion
                  </Link>
                </p>
              </form>
            </>
          )}

          <p className="form-legal">
            <ShieldIcon /> Données hébergées en France · Conforme RGPD · Aucun
            partage avec des tiers.
          </p>
        </div>
      </div>

      {/* ============ RIGHT : VISUAL ============ */}
      <div className="visual-side" aria-hidden>
        <div className="visual-bg" />
        <div className="visual-content">
          <div className="visual-top">
            <span className="visual-top-bar" />
            RÉCUPÉRATION · SÉCURITÉ
          </div>

          <div className="visual-hero">
            <h2 className="visual-h2">
              Vos données sont en <em>sécurité</em>.
            </h2>
            <p className="visual-pitch">
              Pas de panique : vos questions favorites, vos erreurs récentes
              et votre progression vous attendent. Récupérez votre compte en
              30 secondes.
            </p>
          </div>

          <ul className="visual-features">
            <Feature
              icon={<ClockIcon />}
              title="Lien valable 1 heure"
              body="Au-delà, vous pouvez en redemander un autre instantanément."
            />
            <Feature
              icon={<MailIcon />}
              title="Email signé"
              body="Vérification DKIM et SPF activées — pas de phishing."
            />
            <Feature
              icon={<DatabaseIcon />}
              title="Progression conservée"
              body="Examens passés, favoris et erreurs restent rattachés à votre compte."
            />
            <Feature
              icon={<LockIcon />}
              title="Reset déclenché par vous"
              body="Aucune réinitialisation forcée. Vous gardez le contrôle."
            />
          </ul>
        </div>
      </div>

      <style>{styles}</style>
    </div>
  );
}

// ============================================================================
// SUCCESS STATE
// ============================================================================
function SuccessState({
  email,
  onRetry,
}: {
  email: string;
  onRetry: () => void;
}) {
  return (
    <div className="success">
      <div className="success-icon">
        <CheckIcon />
      </div>
      <p className="success-title">Email envoyé.</p>
      <p className="success-sub">
        Si <strong>{email}</strong> correspond à un compte SejourFR, vous allez
        recevoir un lien de réinitialisation. Il est valable 1 heure.
      </p>
      <div className="success-actions">
        <Link href="/connexion" className="form-submit form-submit-outline">
          ← Retour à la connexion
        </Link>
        <button type="button" onClick={onRetry} className="success-retry">
          Pas reçu ? Réessayer avec un autre email
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// FEATURE
// ============================================================================
function Feature({
  icon,
  title,
  body,
}: {
  icon: React.ReactNode;
  title: string;
  body: string;
}) {
  return (
    <li className="visual-feature">
      <span className="visual-feature-icon">{icon}</span>
      <div>
        <div className="visual-feature-title">{title}</div>
        <div className="visual-feature-body">{body}</div>
      </div>
    </li>
  );
}

// ============================================================================
// ICONS
// ============================================================================
const KeyIcon = () => (
  <svg
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="8" cy="15" r="4" />
    <path d="m10.85 12.15 7.15-7.15M16 6.5l3 3" />
  </svg>
);
const ShieldIcon = () => (
  <svg
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </svg>
);
const ClockIcon = () => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </svg>
);
const MailIcon = () => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
    <polyline points="22,6 12,13 2,6" />
  </svg>
);
const DatabaseIcon = () => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <ellipse cx="12" cy="5" rx="9" ry="3" />
    <path d="M3 5v6c0 1.66 4 3 9 3s9-1.34 9-3V5" />
    <path d="M3 11v6c0 1.66 4 3 9 3s9-1.34 9-3v-6" />
  </svg>
);
const LockIcon = () => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <rect x="3" y="11" width="18" height="11" rx="2" />
    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
  </svg>
);
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
  >
    <polyline points="20 6 9 17 4 12" />
  </svg>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .auth-wrap {
    min-height: 100vh;
    display: grid;
    grid-template-columns: 1fr 1fr;
    background: #fff;
  }

  /* ============ FORM SIDE ============ */
  .form-side {
    padding: 28px 48px 48px;
    display: flex;
    flex-direction: column;
    background: #fff;
    position: relative;
  }
  .form-brand {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    text-decoration: none;
    width: fit-content;
    margin-bottom: 30px;
  }
  .form-cocarde {
    width: 32px; height: 32px;
    border-radius: 50%;
    flex-shrink: 0;
    background:
      radial-gradient(circle, var(--color-red) 0 28%, transparent 28%),
      radial-gradient(circle, #fff 0 60%, transparent 60%),
      var(--color-blue);
  }
  .form-wordmark {
    font-family: var(--font-sans);
    font-weight: 800;
    font-size: 20px;
    letter-spacing: -0.02em;
    color: var(--color-blue);
  }
  .form-wordmark .fr { color: var(--color-red); }

  .form-inner {
    max-width: 440px;
    margin: 0 auto;
    width: 100%;
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  .form-eyebrow {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    align-self: flex-start;
    padding: 6px 12px;
    border-radius: 100px;
    background: rgba(232, 163, 23, 0.14);
    color: var(--color-amber);
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.12em;
    font-weight: 700;
    text-transform: uppercase;
    margin-bottom: 18px;
  }
  .form-h1 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(32px, 4vw, 44px);
    line-height: 1.05;
    letter-spacing: -0.025em;
    margin: 0 0 14px;
    color: var(--color-ink);
  }
  .form-h1 em {
    font-style: italic;
    font-weight: 500;
    color: var(--color-blue);
  }
  .form-sub {
    color: var(--color-muted);
    font-size: 15.5px;
    margin: 0 0 32px;
    line-height: 1.55;
    max-width: 400px;
  }

  .form { display: flex; flex-direction: column; gap: 18px; }

  .form-submit {
    background: var(--color-blue);
    color: #fff;
    border: none;
    border-radius: 12px;
    padding: 15px 22px;
    font-size: 15px;
    font-weight: 700;
    font-family: var(--font-sans);
    cursor: pointer;
    transition: all 0.15s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    margin-top: 4px;
    text-decoration: none;
  }
  .form-submit:hover:not(:disabled) {
    background: var(--color-blue-dark);
    transform: translateY(-1px);
    box-shadow: 0 10px 24px -10px rgba(30, 58, 140, 0.4);
  }
  .form-submit:disabled { opacity: 0.6; cursor: not-allowed; }
  .form-submit-arrow { transition: transform 0.15s; }
  .form-submit:hover .form-submit-arrow { transform: translateX(3px); }

  .form-submit-outline {
    background: #fff;
    color: var(--color-ink);
    border: 1px solid var(--color-line);
  }
  .form-submit-outline:hover:not(:disabled) {
    background: var(--color-paper);
    border-color: var(--color-blue);
    color: var(--color-blue);
    box-shadow: none;
  }

  .form-back {
    text-align: center;
    margin: 0;
    padding-top: 6px;
  }
  .form-back-link {
    font-size: 13.5px;
    color: var(--color-muted);
    font-weight: 600;
    text-decoration: none;
    transition: color 0.15s;
  }
  .form-back-link:hover { color: var(--color-blue); }

  .form-legal {
    margin-top: 32px;
    font-size: 11.5px;
    color: var(--color-muted-2);
    text-align: center;
    line-height: 1.5;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    font-family: var(--font-mono);
    letter-spacing: 0.04em;
  }

  /* ============ SUCCESS STATE ============ */
  .success {
    background: linear-gradient(135deg, rgba(22, 143, 91, 0.08), #fff);
    border: 1px solid rgba(22, 143, 91, 0.25);
    border-radius: 16px;
    padding: 28px 24px;
    text-align: center;
  }
  .success-icon {
    width: 56px; height: 56px;
    border-radius: 50%;
    background: var(--color-green);
    color: #fff;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 14px;
    box-shadow: 0 8px 20px -8px rgba(22, 143, 91, 0.5);
  }
  .success-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 22px;
    color: var(--color-ink);
    letter-spacing: -0.015em;
    margin: 0 0 6px;
  }
  .success-sub {
    color: var(--color-muted);
    font-size: 13.5px;
    line-height: 1.55;
    margin: 0 0 22px;
  }
  .success-sub strong {
    color: var(--color-ink);
    font-weight: 700;
    font-family: var(--font-mono);
    font-size: 13px;
  }
  .success-actions {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .success-retry {
    background: none;
    border: none;
    color: var(--color-blue);
    font-family: var(--font-sans);
    font-size: 12.5px;
    font-weight: 600;
    cursor: pointer;
    padding: 4px;
  }
  .success-retry:hover { text-decoration: underline; }

  /* ============ VISUAL SIDE ============ */
  .visual-side {
    background:
      linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
    color: #fff;
    padding: 56px 56px 48px;
    position: relative;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }
  .visual-bg {
    position: absolute;
    inset: 0;
    background:
      radial-gradient(circle at 100% 0%, var(--color-red) 0%, transparent 35%),
      radial-gradient(circle at 0% 100%, rgba(255, 255, 255, 0.08) 0%, transparent 50%);
    opacity: 0.5;
    pointer-events: none;
  }
  .visual-content {
    position: relative;
    z-index: 1;
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }
  .visual-top {
    display: flex;
    align-items: center;
    gap: 14px;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.16em;
    color: rgba(255, 255, 255, 0.65);
    font-weight: 600;
  }
  .visual-top-bar {
    width: 32px;
    height: 1px;
    background: rgba(255, 255, 255, 0.4);
  }

  /* HERO */
  .visual-hero { margin: 48px 0 32px; }
  .visual-h2 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(30px, 3.4vw, 42px);
    line-height: 1.1;
    letter-spacing: -0.02em;
    color: #fff;
    margin: 0 0 18px;
    max-width: 460px;
  }
  .visual-h2 em {
    font-style: italic;
    font-weight: 500;
    color: #ffb3b0;
  }
  .visual-pitch {
    color: rgba(255, 255, 255, 0.82);
    font-size: 15.5px;
    line-height: 1.55;
    margin: 0;
    max-width: 460px;
  }

  /* FEATURES */
  .visual-features {
    list-style: none;
    padding: 28px 0 0;
    margin: 0;
    border-top: 1px solid rgba(255, 255, 255, 0.16);
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
  }
  .visual-feature {
    display: flex;
    gap: 14px;
    align-items: flex-start;
  }
  .visual-feature-icon {
    width: 38px;
    height: 38px;
    border-radius: 11px;
    background: rgba(255, 255, 255, 0.12);
    color: #fff;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
  }
  .visual-feature-title {
    font-weight: 700;
    font-size: 14px;
    color: #fff;
    line-height: 1.25;
    margin-bottom: 4px;
  }
  .visual-feature-body {
    font-size: 12.5px;
    color: rgba(255, 255, 255, 0.7);
    line-height: 1.45;
  }

  /* ============ RESPONSIVE ============ */
  @media (max-width: 980px) {
    .auth-wrap { grid-template-columns: 1fr; min-height: auto; }
    .visual-side { display: none; }
    .form-side { padding: 24px 24px 48px; min-height: 100vh; }
    .form-inner { padding-top: 12px; justify-content: flex-start; }
  }
  @media (max-width: 560px) {
    .visual-features { grid-template-columns: 1fr; gap: 18px; }
  }
`;
