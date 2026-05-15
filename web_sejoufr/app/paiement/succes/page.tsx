"use client";

import Link from "next/link";
import { Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { useAuth } from "@/lib/auth-context";

export default function PaiementSuccesPage() {
  return (
    <Suspense fallback={null}>
      <SuccesInner />
    </Suspense>
  );
}

function SuccesInner() {
  const sp = useSearchParams();
  const { user } = useAuth();
  const sessionId = sp.get("session_id");

  return (
    <main className="succes">
      <div className="succes-card">
        <div className="succes-icon" aria-hidden>
          <svg viewBox="0 0 24 24" fill="none">
            <path
              d="M20 6 9 17l-5-5"
              stroke="currentColor"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>

        <span className="eyebrow">Paiement confirmé</span>
        <h1>
          Bienvenue dans <em>Premium</em>.
        </h1>
        <p className="succes-sub">
          {user?.firstName ? `${user.firstName}, votre` : "Votre"} abonnement est actif. Tous les examens blancs sont débloqués et votre progression est sauvegardée à vie.
        </p>

        <div className="succes-next">
          <h2>Et maintenant ?</h2>
          <ol>
            <li>
              <strong>Téléchargez l&apos;application mobile</strong> — c&apos;est là que se passe l&apos;entraînement quotidien.
              <div className="succes-stores">
                <a href="#" className="store-btn">
                  <span className="store-eyebrow">Télécharger sur</span>
                  <span className="store-name">App Store</span>
                </a>
                <a href="#" className="store-btn">
                  <span className="store-eyebrow">Disponible sur</span>
                  <span className="store-name">Google Play</span>
                </a>
              </div>
            </li>
            <li>
              <strong>Connectez-vous sur l&apos;app</strong> avec{" "}
              <code>{user?.email ?? "votre email"}</code>. Votre statut Premium est synchronisé automatiquement.
            </li>
            <li>
              <strong>Visez 10 questions/jour.</strong> Les rappels et la révision des erreurs sont conçus pour ça.
            </li>
          </ol>
        </div>

        <div className="succes-actions">
          <Link href="/examens-blancs" className="btn btn-red btn-lg">
            Lancer un examen blanc maintenant
          </Link>
          <Link href="/dashboard" className="btn btn-ghost">
            Mon tableau de bord
          </Link>
        </div>

        {sessionId && (
          <p className="succes-meta">
            Référence transaction&nbsp;: <code>{sessionId}</code>
          </p>
        )}
      </div>

      <style>{`
        .succes {
          max-width: 720px; margin: 0 auto;
          padding: 64px 28px 80px;
        }
        .succes-card {
          background: #fff; border: 1px solid var(--color-line);
          border-radius: 18px;
          padding: 48px 44px 40px;
          text-align: center;
          box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
        }
        .succes-icon {
          width: 64px; height: 64px;
          border-radius: 50%;
          background: rgba(22, 143, 91, 0.12);
          color: var(--color-green);
          display: flex; align-items: center; justify-content: center;
          margin: 0 auto 18px;
        }
        .succes-icon svg { width: 30px; height: 30px; }

        .succes h1 {
          font-family: var(--font-display); font-weight: 500; font-size: 40px;
          line-height: 1.05; letter-spacing: -0.025em;
          margin: 12px 0 14px;
        }
        .succes h1 em { font-style: italic; color: var(--color-red); }

        .succes-sub {
          color: var(--color-muted); font-size: 16px;
          margin: 0 auto 32px; max-width: 520px;
          line-height: 1.55;
        }

        .succes-next {
          background: var(--color-paper); border-radius: 14px;
          padding: 28px 32px; text-align: left;
          margin-bottom: 28px;
        }
        .succes-next h2 {
          font-family: var(--font-sans); font-weight: 700; font-size: 13px;
          letter-spacing: 0.08em; text-transform: uppercase;
          color: var(--color-muted);
          margin: 0 0 16px;
        }
        .succes-next ol {
          list-style: none; padding: 0; margin: 0;
          counter-reset: succes-step;
        }
        .succes-next li {
          counter-increment: succes-step;
          padding: 14px 0 16px 44px;
          border-bottom: 1px solid var(--color-line-2);
          position: relative;
          font-size: 14.5px; line-height: 1.55; color: var(--color-ink-2);
        }
        .succes-next li:last-child { border-bottom: none; }
        .succes-next li::before {
          content: counter(succes-step);
          position: absolute; left: 0; top: 12px;
          width: 28px; height: 28px;
          background: var(--color-blue); color: #fff;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-family: var(--font-mono); font-size: 13px; font-weight: 700;
        }
        .succes-next li strong { color: var(--color-ink); font-weight: 600; }
        .succes-next li code {
          font-family: var(--font-mono);
          background: var(--color-blue-light); color: var(--color-blue-dark);
          padding: 2px 6px; border-radius: 4px; font-size: 12.5px;
        }

        .succes-stores {
          display: flex; gap: 10px; flex-wrap: wrap; margin-top: 10px;
        }
        .store-btn {
          display: flex; flex-direction: column;
          padding: 8px 18px;
          background: var(--color-ink); color: #fff;
          border-radius: 10px; text-decoration: none;
          min-width: 150px;
          transition: transform 0.15s;
        }
        .store-btn:hover { transform: translateY(-2px); }
        .store-eyebrow {
          font-family: var(--font-mono); font-size: 9px;
          letter-spacing: 0.16em; text-transform: uppercase;
          color: rgba(255, 255, 255, 0.6);
        }
        .store-name {
          font-family: var(--font-sans); font-weight: 700; font-size: 16px;
          letter-spacing: -0.01em;
        }

        .succes-actions {
          display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;
          margin-bottom: 20px;
        }
        .succes-meta {
          font-family: var(--font-mono); font-size: 11px;
          letter-spacing: 0.08em; color: var(--color-muted);
          margin: 0;
        }
        .succes-meta code {
          background: var(--color-paper);
          padding: 2px 6px; border-radius: 4px;
          color: var(--color-ink-2);
        }

        @media (max-width: 560px) {
          .succes { padding: 28px 16px 60px; }
          .succes-card { padding: 32px 24px 28px; }
          .succes h1 { font-size: 30px; }
          .succes-next { padding: 22px 20px; }
          .succes-next li { padding-left: 38px; }
        }
      `}</style>
    </main>
  );
}
