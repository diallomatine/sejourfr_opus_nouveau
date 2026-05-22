"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import GoogleSignInButton from "@/app/_components/GoogleSignInButton";
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
  const [showPassword, setShowPassword] = useState(false);

  // Si l'utilisateur est déjà connecté, on file directement au dashboard.
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
            Compte gratuit · 30 secondes
          </div>
          <h1 className="form-h1">
            Commencez votre <em>préparation</em>.
          </h1>
          <p className="form-sub">
            Pas de carte bancaire. 20 QCM offerts par module et un examen blanc
            complet pour chaque module.
          </p>

          <form onSubmit={handleSubmit} className="form" noValidate>
            {error && (
              <div className="form-error" role="alert">
                {error}
              </div>
            )}

            <div className="form-row-2">
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
              <div className="field-pwd-wrap">
                <input
                  id="password"
                  name="password"
                  type={showPassword ? "text" : "password"}
                  required
                  minLength={8}
                  placeholder="8 caractères minimum"
                  className="field-input"
                  autoComplete="new-password"
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

            <div className="field">
              <label className="field-label">Votre démarche</label>
              <div className="mention-grid">
                {MENTIONS.map((opt) => {
                  const active = mention === opt.v;
                  return (
                    <label
                      key={opt.v}
                      className={`mention-opt ${active ? "is-active" : ""}`}
                    >
                      <input
                        type="radio"
                        name="mention"
                        value={opt.v}
                        checked={active}
                        onChange={() => setMention(opt.v)}
                      />
                      <span className="mention-code">{opt.code}</span>
                      <span className="mention-name">{opt.name}</span>
                      <span className="mention-tcf">
                        TCF <strong>{opt.tcf}</strong>
                      </span>
                    </label>
                  );
                })}
              </div>
            </div>

            <label className="form-check">
              <input type="checkbox" required />
              <span>
                J&apos;accepte les{" "}
                <Link href="#">Conditions générales</Link> et la{" "}
                <Link href="#">Politique de confidentialité</Link>.
              </span>
            </label>

            <button type="submit" disabled={submitting} className="form-submit">
              {submitting ? "Création…" : "Créer mon compte gratuit"}
              <span className="form-submit-arrow">→</span>
            </button>

            <GoogleSignInButton
              variant="signup"
              onSuccess={() => router.push("/dashboard")}
              onError={setError}
            />

            <p className="form-already">
              Déjà un compte ?{" "}
              <Link href="/connexion" className="form-already-link">
                Se connecter →
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
            ILS ONT RÉUSSI · TRUST SCORE
          </div>

          <blockquote className="visual-quote">
            <div className="visual-quote-mark">&ldquo;</div>
            <p>
              37 sur 40 à l&apos;examen civique après six semaines avec
              SejourFR. Les blancs sont identiques au format réel.
            </p>
            <footer className="visual-author">
              <div className="visual-avatar">FA</div>
              <div>
                <div className="visual-name">Fatima A.</div>
                <div className="visual-meta">NATURALISATION · MARSEILLE</div>
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
    max-width: 460px;
    margin: 0 auto;
    width: 100%;
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .form-eyebrow {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    align-self: flex-start;
    padding: 6px 12px;
    border-radius: 100px;
    background: rgba(22, 143, 91, 0.10);
    color: var(--color-green);
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
    background: var(--color-green);
    box-shadow: 0 0 0 3px rgba(22, 143, 91, 0.18);
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
    max-width: 420px;
  }

  .form { display: flex; flex-direction: column; gap: 18px; }
  .form-row-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

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

  /* MENTION GRID */
  .mention-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
  }
  .mention-opt {
    position: relative;
    border: 1.5px solid var(--color-line);
    background: #fff;
    border-radius: 12px;
    padding: 14px 10px;
    text-align: center;
    cursor: pointer;
    transition: all 0.18s;
    display: flex;
    flex-direction: column;
    gap: 4px;
    align-items: center;
  }
  .mention-opt:hover:not(.is-active) {
    border-color: var(--color-blue);
    background: var(--color-blue-soft);
  }
  .mention-opt input {
    position: absolute;
    opacity: 0;
    pointer-events: none;
  }
  .mention-code {
    font-family: var(--font-mono);
    font-size: 12.5px;
    font-weight: 700;
    color: var(--color-blue);
    letter-spacing: 0.08em;
  }
  .mention-name {
    font-size: 12px;
    color: var(--color-muted);
    line-height: 1.3;
  }
  .mention-tcf {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.08em;
    color: var(--color-muted-2);
    margin-top: 2px;
  }
  .mention-tcf strong {
    color: var(--color-red);
    font-weight: 700;
  }
  .mention-opt.is-active {
    border-color: var(--color-blue);
    background: var(--color-blue-light);
  }
  .mention-opt.is-active .mention-code { color: var(--color-blue-dark); }
  .mention-opt.is-active .mention-name {
    color: var(--color-ink);
    font-weight: 600;
  }

  /* CHECK */
  .form-check {
    display: flex;
    gap: 10px;
    align-items: flex-start;
    font-size: 13px;
    color: var(--color-ink-2);
    line-height: 1.5;
  }
  .form-check input {
    width: 16px; height: 16px;
    margin-top: 2px;
    accent-color: var(--color-blue);
    flex-shrink: 0;
  }
  .form-check a {
    color: var(--color-blue);
    font-weight: 600;
    text-decoration: none;
  }
  .form-check a:hover { text-decoration: underline; }

  /* SUBMIT */
  .form-submit {
    background: var(--color-red);
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
    background: var(--color-red-dark);
    transform: translateY(-1px);
    box-shadow: 0 10px 24px -10px rgba(225, 55, 47, 0.4);
  }
  .form-submit:disabled { opacity: 0.6; cursor: not-allowed; }
  .form-submit-arrow { transition: transform 0.15s; }
  .form-submit:hover .form-submit-arrow { transform: translateX(3px); }

  .form-already {
    text-align: center;
    font-size: 13.5px;
    color: var(--color-muted);
    margin: 0;
  }
  .form-already-link {
    color: var(--color-blue);
    font-weight: 700;
    text-decoration: none;
  }
  .form-already-link:hover { text-decoration: underline; }

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
    background: linear-gradient(135deg, var(--color-red), var(--color-amber));
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
    .form-inner { padding-top: 12px; }
  }
  @media (max-width: 480px) {
    .form-row-2 { grid-template-columns: 1fr; }
    .mention-grid { grid-template-columns: 1fr; }
    .mention-opt {
      flex-direction: row;
      justify-content: flex-start;
      gap: 12px;
      text-align: left;
      padding: 12px 14px;
    }
    .mention-tcf { margin-top: 0; margin-left: auto; }
  }
`;
