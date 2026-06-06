"use client";

import Link from "next/link";
import { useEffect } from "react";
import { usePathname } from "next/navigation";

interface GuestGateSheetProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  message?: string;
}

/**
 * Pendant guest de PaywallSheet : modal d'incitation à créer un compte
 * (gratuit). Affichée quand un visiteur non connecté clique sur un contenu
 * réservé aux comptes (série 2+, examen 2+, EE/EO...). Le CTA inscription
 * porte un `?next=` vers la page courante pour revenir après signup.
 */
export function GuestGateSheet({
  open,
  onClose,
  title = "Créez votre compte gratuit",
  message = "Vous avez utilisé le contenu découverte. Un compte gratuit débloque plus de séries, vos statistiques et la reprise de vos sessions.",
}: GuestGateSheetProps) {
  const pathname = usePathname();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [open, onClose]);

  if (!open) return null;

  const next = encodeURIComponent(pathname ?? "/");

  return (
    <div
      className="ggs"
      role="dialog"
      aria-modal="true"
      aria-labelledby="guest-gate-title"
      onClick={onClose}
    >
      <div className="ggs-backdrop" />
      <div className="ggs-sheet" onClick={(e) => e.stopPropagation()}>
        <button
          type="button"
          className="ggs-close"
          onClick={onClose}
          aria-label="Fermer"
        >
          ✕
        </button>

        <div className="ggs-icon" aria-hidden>
          <svg viewBox="0 0 24 24" width="30" height="30" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M19 8v6" />
            <path d="M22 11h-6" />
          </svg>
        </div>

        <h2 id="guest-gate-title" className="ggs-title">{title}</h2>
        <p className="ggs-text">{message}</p>

        <div className="ggs-features">
          <div className="ggs-feature">
            <span className="ggs-check">✓</span> Suivi de progression et statistiques
          </div>
          <div className="ggs-feature">
            <span className="ggs-check">✓</span> Une série gratuite par thème et niveau
          </div>
          <div className="ggs-feature">
            <span className="ggs-check">✓</span> Expression écrite et orale évaluées par l&apos;IA
          </div>
          <div className="ggs-feature">
            <span className="ggs-check">✓</span> Révision de vos erreurs
          </div>
        </div>

        <Link
          href={`/inscription?next=${next}`}
          className="btn btn-lg ggs-cta"
          onClick={onClose}
        >
          Créer mon compte gratuit →
        </Link>
        <Link href={`/connexion?next=${next}`} className="ggs-later" onClick={onClose}>
          J&apos;ai déjà un compte — me connecter
        </Link>
      </div>

      <style>{`
        .ggs {
          position: fixed; inset: 0;
          z-index: 100;
          display: flex; align-items: flex-end; justify-content: center;
        }
        .ggs-backdrop {
          position: absolute; inset: 0;
          background: rgba(15, 24, 57, 0.45);
          animation: ggs-fade-in 0.18s ease-out;
        }
        @keyframes ggs-fade-in {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes ggs-slide-up {
          from { transform: translateY(20px); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }
        .ggs-sheet {
          position: relative;
          background: #fff;
          border-radius: 22px 22px 0 0;
          padding: 28px 24px 24px;
          width: 100%;
          max-width: 480px;
          box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25);
          animation: ggs-slide-up 0.22s ease-out;
          max-height: 90vh;
          overflow-y: auto;
        }
        .ggs-close {
          position: absolute; top: 12px; right: 12px;
          width: 32px; height: 32px;
          background: var(--color-paper-2);
          border: none; border-radius: 8px;
          font-size: 14px;
          color: var(--color-muted);
          cursor: pointer;
        }
        .ggs-close:hover { background: var(--color-line); color: var(--color-ink); }
        .ggs-icon {
          width: 56px; height: 56px;
          margin: 0 auto 14px;
          background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          color: #fff;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          box-shadow: 0 8px 24px -8px rgba(30, 58, 140, 0.4);
        }
        .ggs-title {
          font-family: var(--font-display);
          font-weight: 500; font-size: 24px;
          letter-spacing: -0.015em;
          text-align: center;
          margin: 0 0 8px;
          color: var(--color-ink);
        }
        .ggs-text {
          font-size: 13.5px; line-height: 1.55;
          color: var(--color-muted);
          text-align: center;
          margin: 0 0 18px;
        }
        .ggs-features {
          background: var(--color-paper);
          border-radius: 12px;
          padding: 14px 16px;
          margin-bottom: 18px;
          display: flex; flex-direction: column; gap: 8px;
        }
        .ggs-feature {
          font-size: 13.5px; color: var(--color-ink-2);
          display: flex; align-items: center; gap: 10px;
        }
        .ggs-check {
          color: var(--color-green);
          font-weight: 700;
        }
        .ggs-cta {
          width: 100%;
          text-align: center;
          margin-bottom: 8px;
        }
        .ggs-later {
          display: block;
          width: 100%;
          padding: 10px;
          text-align: center;
          font-size: 13px;
          color: var(--color-muted);
          text-decoration: none;
        }
        .ggs-later:hover { color: var(--color-ink); }

        @media (min-width: 640px) {
          .ggs { align-items: center; }
          .ggs-sheet { border-radius: 22px; }
        }
      `}</style>
    </div>
  );
}
