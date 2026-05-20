"use client";

import {useEffect} from "react";
import {Clock, Mic, PenLine, Sparkles} from "lucide-react";

export type ProductionKind = "EO" | "EE";

interface Props {
    open: boolean;
    kind: ProductionKind | null;
    onClose: () => void;
}

/**
 * Modal détail Expression orale / écrite — explique la tâche puis pousse à
 * télécharger l'app mobile (l'entraînement EO/EE n'est pas (encore) disponible
 * sur le web : micro/brouillon natifs + évaluation IA mieux servis côté mobile).
 */
export function ProductionMobileSheet({open, kind, onClose}: Props) {
    // Fermeture par ESC + lock scroll body.
    useEffect(() => {
        if (!open) return;
        const onKey = (e: KeyboardEvent) => {
            if (e.key === "Escape") onClose();
        };
        window.addEventListener("keydown", onKey);
        const prev = document.body.style.overflow;
        document.body.style.overflow = "hidden";
        return () => {
            window.removeEventListener("keydown", onKey);
            document.body.style.overflow = prev;
        };
    }, [open, onClose]);

    if (!open || kind === null) return null;

    const isOral = kind === "EO";
    const data = isOral
        ? {
            eyebrow: "TCF · EXPRESSION ORALE",
            title: "Expression orale",
            lede:
                "Vous parlez ~12 minutes au micro sur 3 tâches enchaînées " +
                "(entretien dirigé, point de vue, jeu de rôle). L'IA vous note sur 20 et " +
                "vous attribue un niveau CECRL A2 à C2 avec un feedback détaillé en ~15 secondes.",
            tasks: [
                {label: "Tâche 1", text: "Entretien dirigé — 1 min 30 (questions personnelles)"},
                {label: "Tâche 2", text: "Expression d'un point de vue — 2 min (sujet imposé)"},
                {label: "Tâche 3", text: "Jeu de rôle — 3 à 4 min (interaction simulée)"},
            ],
            why: "L'enregistrement audio nécessite un micro de bonne qualité et un environnement calme — l'app mobile gère mieux ces conditions et conserve vos enregistrements en local.",
        }
        : {
            eyebrow: "TCF · EXPRESSION ÉCRITE",
            title: "Expression écrite",
            lede:
                "Vous rédigez 3 productions courtes (message, échange, prise de position) " +
                "en ~60 minutes. L'IA vous note sur 20 et vous donne un feedback structuré " +
                "par critères (cohérence, lexique, grammaire, pertinence).",
            tasks: [
                {label: "Tâche 1", text: "Message court (60–120 mots) — situation pratique"},
                {label: "Tâche 2", text: "Échange écrit (120–150 mots) — réagir à un message"},
                {label: "Tâche 3", text: "Prise de position argumentée (150–200 mots)"},
            ],
            why: "L'app mobile sauvegarde votre brouillon automatiquement toutes les 3 secondes et vous permet de rédiger même hors connexion.",
        };

    const Icon = isOral ? Mic : PenLine;

    return (
        <div
            className="pms"
            role="dialog"
            aria-modal="true"
            aria-labelledby="pms-title"
            onClick={onClose}
        >
            <div className="pms-backdrop"/>
            <div className="pms-sheet" onClick={(e) => e.stopPropagation()}>
                <button
                    type="button"
                    className="pms-close"
                    onClick={onClose}
                    aria-label="Fermer"
                >
                    ✕
                </button>

                <div className="pms-icon" aria-hidden>
                    <Icon size={26} strokeWidth={1.8}/>
                </div>

                <div className="pms-eyebrow">{data.eyebrow}</div>
                <h2 id="pms-title" className="pms-title">{data.title}</h2>
                <p className="pms-lede">{data.lede}</p>

                <ul className="pms-tasks">
                    {data.tasks.map((t) => (
                        <li key={t.label} className="pms-task">
                            <span className="pms-task-label">{t.label}</span>
                            <span className="pms-task-text">{t.text}</span>
                        </li>
                    ))}
                </ul>

                <div className="pms-meta">
                    <div className="pms-meta-item">
                        <Clock size={14} strokeWidth={2}/>
                        <span>{isOral ? "~12 min" : "~60 min"}</span>
                    </div>
                    <div className="pms-meta-item">
                        <Sparkles size={14} strokeWidth={2}/>
                        <span>Évaluation IA · note /20 + CECRL</span>
                    </div>
                </div>

                <div className="pms-cta-block">
                    <div className="pms-cta-title">
                        Disponible sur l&apos;application mobile
                    </div>
                    <p className="pms-cta-text">{data.why}</p>
                    <div className="pms-stores">
                        <StoreBadge variant="ios"/>
                        <StoreBadge variant="android"/>
                    </div>
                    <p className="pms-cta-note">
                        Un seul compte SejourFR partagé entre le site et l&apos;app.
                    </p>
                </div>

                <button type="button" className="pms-later" onClick={onClose}>
                    Plus tard
                </button>
            </div>

            <style>{`
        .pms {
          position: fixed; inset: 0;
          z-index: 1000;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 24px;
        }
        .pms-backdrop {
          position: absolute; inset: 0;
          background: rgba(15, 24, 57, 0.55);
          backdrop-filter: blur(2px);
        }
        .pms-sheet {
          position: relative;
          background: #fff;
          border-radius: 20px;
          max-width: 480px;
          width: 100%;
          max-height: calc(100vh - 48px);
          overflow-y: auto;
          padding: 32px 28px 24px;
          box-shadow: 0 30px 80px -20px rgba(15, 24, 57, 0.4);
          animation: pms-pop 0.2s ease-out;
        }
        @keyframes pms-pop {
          from { opacity: 0; transform: translateY(8px) scale(0.98); }
          to { opacity: 1; transform: translateY(0) scale(1); }
        }
        .pms-close {
          position: absolute;
          top: 14px; right: 14px;
          width: 32px; height: 32px;
          background: var(--color-paper);
          border: 1px solid var(--color-line);
          border-radius: 8px;
          font-size: 14px;
          color: var(--color-muted);
          cursor: pointer;
          display: inline-flex;
          align-items: center; justify-content: center;
          transition: color 0.15s, background 0.15s;
        }
        .pms-close:hover {
          color: var(--color-ink);
          background: var(--color-line-2);
        }

        .pms-icon {
          width: 52px; height: 52px;
          border-radius: 14px;
          background: var(--color-red-light);
          color: var(--color-red);
          display: inline-flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 14px;
        }
        .pms-eyebrow {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.14em;
          color: var(--color-red);
          font-weight: 700;
          margin-bottom: 6px;
        }
        .pms-title {
          font-family: var(--font-display);
          font-size: 26px;
          font-weight: 600;
          letter-spacing: -0.02em;
          margin: 0 0 10px;
          color: var(--color-ink);
          line-height: 1.15;
        }
        .pms-lede {
          font-size: 14px;
          color: var(--color-ink-2);
          line-height: 1.55;
          margin: 0 0 18px;
        }

        .pms-tasks {
          list-style: none;
          padding: 0;
          margin: 0 0 16px;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .pms-task {
          background: var(--color-paper);
          border: 1px solid var(--color-line);
          border-radius: 10px;
          padding: 10px 12px;
          display: flex;
          gap: 12px;
          align-items: baseline;
        }
        .pms-task-label {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.12em;
          font-weight: 700;
          color: var(--color-red);
          flex-shrink: 0;
          padding-top: 1px;
        }
        .pms-task-text {
          font-size: 13px;
          color: var(--color-ink-2);
          line-height: 1.4;
        }

        .pms-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          margin-bottom: 22px;
        }
        .pms-meta-item {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 6px 10px;
          background: var(--color-blue-soft);
          border-radius: 8px;
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.04em;
          color: var(--color-blue);
          font-weight: 600;
        }

        .pms-cta-block {
          background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          border-radius: 14px;
          padding: 20px;
          color: #fff;
          margin-bottom: 12px;
        }
        .pms-cta-title {
          font-family: var(--font-display);
          font-size: 17px;
          font-weight: 600;
          letter-spacing: -0.01em;
          margin-bottom: 6px;
        }
        .pms-cta-text {
          font-size: 13px;
          line-height: 1.5;
          color: rgba(255, 255, 255, 0.88);
          margin: 0 0 14px;
        }
        .pms-stores {
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
          margin-bottom: 12px;
        }
        .pms-cta-note {
          font-size: 11.5px;
          color: rgba(255, 255, 255, 0.7);
          margin: 0;
          line-height: 1.4;
        }

        .pms-later {
          width: 100%;
          background: transparent;
          border: 0;
          color: var(--color-muted);
          font-family: inherit;
          font-size: 13px;
          font-weight: 600;
          padding: 10px;
          cursor: pointer;
          border-radius: 8px;
          transition: color 0.15s, background 0.15s;
        }
        .pms-later:hover {
          color: var(--color-ink);
          background: var(--color-paper);
        }

        @media (max-width: 560px) {
          .pms { padding: 0; align-items: flex-end; }
          .pms-sheet {
            border-radius: 20px 20px 0 0;
            max-width: none;
            max-height: 92vh;
            padding: 28px 20px 20px;
            animation: pms-slide 0.22s ease-out;
          }
          @keyframes pms-slide {
            from { transform: translateY(100%); }
            to { transform: translateY(0); }
          }
          .pms-title { font-size: 22px; }
          .pms-stores { flex-direction: column; }
        }
      `}</style>
        </div>
    );
}

// ============================================================================
// Store badges (duplique celui de MobileAppPromo : on garde chaque fichier
// auto-contenu, pas d'export commun pour 2 cas d'usage).
// ============================================================================

function StoreBadge({variant}: { variant: "ios" | "android" }) {
    const isIos = variant === "ios";
    return (
        <a
            href="#telecharger"
            className="sb"
            aria-label={isIos ? "Télécharger sur l'App Store" : "Disponible sur Google Play"}
        >
      <span className="sb__icon" aria-hidden>
        {isIos ? <AppleIcon/> : <GooglePlayIcon/>}
      </span>
            <span className="sb__copy">
        <span className="sb__eyebrow">
          {isIos ? "Télécharger sur" : "Disponible sur"}
        </span>
        <span className="sb__name">
          {isIos ? "App Store" : "Google Play"}
        </span>
      </span>
            <style>{`
        .sb {
          display: inline-flex;
          align-items: center;
          gap: 10px;
          padding: 9px 14px;
          background: rgba(255, 255, 255, 0.12);
          border: 1px solid rgba(255, 255, 255, 0.2);
          color: #fff;
          border-radius: 10px;
          text-decoration: none;
          transition: background 0.15s, transform 0.15s;
          flex: 1;
          min-width: 0;
        }
        .sb:hover {
          background: rgba(255, 255, 255, 0.2);
          transform: translateY(-1px);
        }
        .sb__icon {
          display: inline-flex;
          align-items: center; justify-content: center;
          width: 22px; height: 22px;
          flex-shrink: 0;
        }
        .sb__copy {
          display: inline-flex;
          flex-direction: column;
          gap: 1px;
          min-width: 0;
        }
        .sb__eyebrow {
          font-family: var(--font-mono);
          font-size: 8.5px;
          letter-spacing: 0.16em;
          text-transform: uppercase;
          color: rgba(255, 255, 255, 0.7);
        }
        .sb__name {
          font-family: var(--font-sans);
          font-weight: 700;
          font-size: 13.5px;
          letter-spacing: -0.005em;
        }
      `}</style>
        </a>
    );
}

function AppleIcon() {
    return (
        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden>
            <path
                d="M16.498 12.66c.025 2.73 2.39 3.638 2.417 3.65-.021.066-.378 1.291-1.246 2.555-.75 1.094-1.529 2.183-2.755 2.206-1.205.022-1.593-.715-2.97-.715-1.376 0-1.806.692-2.946.737-1.184.045-2.085-1.183-2.842-2.272-1.547-2.234-2.73-6.314-1.14-9.07.79-1.367 2.2-2.232 3.732-2.254 1.162-.023 2.26.781 2.97.781.71 0 2.046-.966 3.45-.823.587.024 2.236.237 3.295 1.787-.085.053-1.967 1.149-1.945 3.418zM14.272 4.94c.626-.758 1.047-1.812.932-2.86-.9.036-1.991.6-2.638 1.357-.58.671-1.088 1.745-.95 2.772 1.005.078 2.029-.51 2.656-1.268z"/>
        </svg>
    );
}

function GooglePlayIcon() {
    return (
        <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden>
            <path d="M3.6 1.7c-.4.3-.6.8-.6 1.4v17.7c0 .6.2 1.1.6 1.4l9.4-10.3L3.6 1.7z" fill="#00C2FF"/>
            <path d="M16.6 8.6L4.7 1.4c-.5-.3-1-.4-1.4-.2L14 12 16.6 8.6z" fill="#39E170"/>
            <path d="M21.4 11l-4.8-2.4L14 12l2.6 3.4L21.4 13c1-.6 1-1.4 0-2z" fill="#FFCC00"/>
            <path d="M4.7 22.6L16.6 15.4 14 12 3.3 22.8c.4.2.9.1 1.4-.2z" fill="#FF3B47"/>
        </svg>
    );
}
