"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { ApiException } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";

export default function ConnexionPage() {
  return (
    <Suspense fallback={<ConnexionSkeleton />}>
      <ConnexionInner />
    </Suspense>
  );
}

function ConnexionInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { login, status, user } = useAuth();
  const nextHref = search.get("next") ?? "/dashboard";
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (status === "authenticated" && user) {
      router.replace(nextHref);
    }
  }, [status, user, router, nextHref]);

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
      await login(payload);
      router.push(nextHref);
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
            <span className="dot" aria-hidden />
            Espace personnel
          </div>
          <h1 className="form-h1">
            Heureux de vous <em>revoir</em>.
          </h1>
          <p className="form-sub">
            Connectez-vous pour reprendre votre préparation là où vous
            l&apos;avez laissée.
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

            <div className="field">
              <div className="pwd-row">
                <label htmlFor="password" className="field-label">
                  Mot de passe
                </label>
                <Link href="/mot-de-passe-oublie" className="pwd-forgot">
                  Oublié ?
                </Link>
              </div>
              <div className="field-pwd-wrap">
                <input
                  id="password"
                  name="password"
                  type={showPassword ? "text" : "password"}
                  required
                  placeholder="••••••••"
                  className="field-input"
                  autoComplete="current-password"
                />
                <button
                  type="button"
                  className="field-pwd-toggle"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? "Masquer" : "Afficher"}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOffIcon /> : <EyeIcon />}
                </button>
              </div>
            </div>

            <label className="form-check">
              <input type="checkbox" defaultChecked />
              <span>Rester connecté sur cet appareil</span>
            </label>

            <button type="submit" disabled={submitting} className="form-submit">
              {submitting ? "Connexion…" : "Se connecter"}
              <span className="form-submit-arrow">→</span>
            </button>

            <p className="form-signup">
              Nouveau sur SejourFR ?{" "}
              <Link href="/inscription" className="form-signup-link">
                Créer un compte gratuit →
              </Link>
            </p>
          </form>

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
            ESPACE PERSONNEL · CONTINUITÉ
          </div>

          <blockquote className="visual-quote">
            <div className="visual-quote-mark">&ldquo;</div>
            <p>
              Le TCF B1 me faisait peur. Les exercices de compréhension orale
              m&apos;ont vraiment préparé. J&apos;ai eu ma carte de résident.
            </p>
            <footer className="visual-author">
              <div className="visual-avatar">VO</div>
              <div>
                <div className="visual-name">Viktor O.</div>
                <div className="visual-meta">CARTE DE RÉSIDENT · LYON</div>
              </div>
            </footer>
          </blockquote>

          <div className="visual-stats">
            <Stat num="2 500+" label="Questions calibrées" />
            <Stat num="94 %" label="Taux de réussite" />
            <Stat num="8 200+" label="Candidats inscrits" />
            <Stat num="4,8 /5" label="Note utilisateurs" />
          </div>
        </div>
      </div>

      <style>{styles}</style>
    </div>
  );
}

// ============================================================================
// STAT
// ============================================================================
function Stat({ num, label }: { num: string; label: string }) {
  return (
    <div className="visual-stat">
      <div className="visual-stat-num">{num}</div>
      <div className="visual-stat-label">{label}</div>
    </div>
  );
}

// ============================================================================
// SKELETON
// ============================================================================
function ConnexionSkeleton() {
  return (
    <div className="auth-loading">
      <style>{`.auth-loading { min-height: 100vh; background: #fff; }`}</style>
    </div>
  );
}

// ============================================================================
// ICONS
// ============================================================================
const EyeIcon = () => (
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
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
    <circle cx="12" cy="12" r="3" />
  </svg>
);
const EyeOffIcon = () => (
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
    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
    <line x1="1" y1="1" x2="23" y2="23" />
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
    background: var(--color-blue-light);
    color: var(--color-blue);
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.12em;
    font-weight: 700;
    text-transform: uppercase;
    margin-bottom: 18px;
  }
  .form-eyebrow .dot {
    width: 6px; height: 6px;
    border-radius: 50%;
    background: var(--color-blue);
    box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.18);
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

  /* PWD ROW (label + lien oublié sur la même ligne) */
  .pwd-row {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 7px;
  }
  .pwd-row .field-label { margin-bottom: 0; }
  .pwd-forgot {
    font-family: var(--font-sans);
    font-size: 12px;
    color: var(--color-blue);
    font-weight: 700;
    text-decoration: none;
    transition: color 0.15s;
  }
  .pwd-forgot:hover { color: var(--color-blue-dark); text-decoration: underline; }

  /* PASSWORD TOGGLE */
  .field-pwd-wrap { position: relative; }
  .field-pwd-wrap .field-input { padding-right: 44px; }
  .field-pwd-toggle {
    position: absolute;
    right: 6px;
    top: 50%;
    transform: translateY(-50%);
    width: 36px; height: 36px;
    background: none;
    border: none;
    border-radius: 8px;
    color: var(--color-muted);
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    transition: color 0.15s, background 0.15s;
  }
  .field-pwd-toggle:hover {
    color: var(--color-blue);
    background: var(--color-blue-soft);
  }

  /* CHECK */
  .form-check {
    display: flex;
    gap: 10px;
    align-items: center;
    font-size: 13px;
    color: var(--color-ink-2);
    line-height: 1.5;
    cursor: pointer;
  }
  .form-check input {
    width: 16px; height: 16px;
    accent-color: var(--color-blue);
    flex-shrink: 0;
  }

  /* SUBMIT */
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
  }
  .form-submit:hover:not(:disabled) {
    background: var(--color-blue-dark);
    transform: translateY(-1px);
    box-shadow: 0 10px 24px -10px rgba(30, 58, 140, 0.4);
  }
  .form-submit:disabled { opacity: 0.6; cursor: not-allowed; }
  .form-submit-arrow { transition: transform 0.15s; }
  .form-submit:hover .form-submit-arrow { transform: translateX(3px); }

  .form-signup {
    text-align: center;
    font-size: 13.5px;
    color: var(--color-muted);
    margin: 0;
    padding-top: 18px;
    border-top: 1px solid var(--color-line-2);
  }
  .form-signup-link {
    color: var(--color-red);
    font-weight: 700;
    text-decoration: none;
  }
  .form-signup-link:hover { color: var(--color-red-dark); text-decoration: underline; }

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

  /* QUOTE */
  .visual-quote {
    margin: 64px 0 56px;
    padding: 0;
    position: relative;
  }
  .visual-quote-mark {
    font-family: var(--font-display);
    font-size: 96px;
    line-height: 0.5;
    color: rgba(255, 255, 255, 0.18);
    font-weight: 600;
    margin-bottom: 16px;
  }
  .visual-quote p {
    font-family: var(--font-display);
    font-weight: 500;
    font-size: clamp(22px, 2.4vw, 30px);
    line-height: 1.25;
    letter-spacing: -0.015em;
    color: #fff;
    margin: 0 0 28px;
    max-width: 480px;
  }
  .visual-author {
    display: flex;
    gap: 12px;
    align-items: center;
  }
  .visual-avatar {
    width: 44px; height: 44px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--color-green), var(--color-blue));
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 14px;
    flex-shrink: 0;
  }
  .visual-name { font-weight: 700; font-size: 15px; }
  .visual-meta {
    font-family: var(--font-mono);
    font-size: 10.5px;
    color: rgba(255, 255, 255, 0.6);
    letter-spacing: 0.12em;
    margin-top: 2px;
  }

  /* STATS */
  .visual-stats {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
    border-top: 1px solid rgba(255, 255, 255, 0.16);
    padding-top: 32px;
  }
  .visual-stat-num {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(26px, 2.8vw, 32px);
    letter-spacing: -0.025em;
    line-height: 1;
    color: #fff;
    margin-bottom: 6px;
  }
  .visual-stat-label {
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: rgba(255, 255, 255, 0.6);
  }

  /* ============ RESPONSIVE ============ */
  @media (max-width: 980px) {
    .auth-wrap { grid-template-columns: 1fr; min-height: auto; }
    .visual-side { display: none; }
    .form-side { padding: 24px 24px 48px; min-height: 100vh; }
    .form-inner { padding-top: 12px; justify-content: flex-start; }
  }
`;
