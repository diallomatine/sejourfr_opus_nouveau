"use client";

import Link from "next/link";

/**
 * Affiché à la place de la liste de thèmes/du runner quand l'utilisateur
 * sélectionne le module TCF mais n'a pas le plan INTÉGRAL.
 */
export function TcfPaywallCard({ compact = false }: { compact?: boolean }) {
  return (
    <div className={`tpc ${compact ? "is-compact" : ""}`}>
      <div className="tpc-badge">
        <span className="tpc-badge-dot" />
        ABONNEMENT INTÉGRAL REQUIS
      </div>
      <h3 className="tpc-title">
        Le TCF IRN demande l&apos;abonnement <em>Intégral</em>
      </h3>
      <p className="tpc-text">
        L&apos;épreuve TCF (compréhension orale + écrite + structures) est
        incluse uniquement dans l&apos;abonnement <strong>Intégral</strong>.
        Vous gardez aussi tout l&apos;entraînement civique.
      </p>
      <ul className="tpc-features">
        <li>Compréhension orale (audios authentiques)</li>
        <li>Compréhension écrite et structures de la langue</li>
        <li>Examen blanc complet, 35 questions chronométrées</li>
        <li>Statistiques par niveau et révision des erreurs</li>
      </ul>
      <div className="tpc-actions">
        <Link href="/paiement?module=INTEGRAL" className="btn btn-red">
          Voir l&apos;offre Intégral →
        </Link>
        <Link href="/paiement" className="btn btn-ghost">
          Comparer les formules
        </Link>
      </div>

      <style>{`
        .tpc {
          background: linear-gradient(135deg, var(--color-red-light) 0%, #fff 60%);
          border: 1px solid rgba(225, 55, 47, 0.25);
          border-radius: 18px;
          padding: 24px 24px 22px;
          box-shadow: 0 30px 60px -30px rgba(225, 55, 47, 0.18);
        }
        .tpc.is-compact { padding: 18px 18px 16px; }

        .tpc-badge {
          display: inline-flex; align-items: center; gap: 6px;
          background: rgba(225, 55, 47, 0.12);
          color: var(--color-red-dark);
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.16em;
          font-weight: 700;
          padding: 4px 10px; border-radius: 100px;
          margin-bottom: 14px;
        }
        .tpc-badge-dot {
          width: 6px; height: 6px;
          background: var(--color-red);
          border-radius: 50%;
          animation: tpc-pulse 1.8s ease-in-out infinite;
        }
        @keyframes tpc-pulse {
          0%, 100% { opacity: 0.4; }
          50% { opacity: 1; }
        }

        .tpc-title {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 24px;
          line-height: 1.2; letter-spacing: -0.015em;
          color: var(--color-ink);
          margin: 0 0 10px;
        }
        .tpc-title em { font-style: italic; color: var(--color-red); }

        .tpc-text {
          font-size: 14px; line-height: 1.55;
          color: var(--color-muted);
          margin: 0 0 14px;
        }
        .tpc-text strong { color: var(--color-ink); font-weight: 600; }

        .tpc-features {
          list-style: none; padding: 0; margin: 0 0 18px;
          display: flex; flex-direction: column; gap: 6px;
        }
        .tpc-features li {
          position: relative;
          padding-left: 20px;
          font-size: 13.5px;
          color: var(--color-ink-2);
          line-height: 1.45;
        }
        .tpc-features li::before {
          content: "✓";
          position: absolute; left: 0;
          color: var(--color-green);
          font-weight: 700;
        }

        .tpc-actions {
          display: flex; gap: 10px; flex-wrap: wrap;
        }
      `}</style>
    </div>
  );
}
