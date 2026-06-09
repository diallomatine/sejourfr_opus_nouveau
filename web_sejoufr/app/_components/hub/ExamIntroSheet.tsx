"use client";

import { useEffect } from "react";

/** Une donnée clé de l'examen (questions / durée / seuil…). */
export interface ExamFact {
  label: string;
  value: string;
  /** Met la valeur en vert (seuil de réussite, notation cible). */
  highlight?: boolean;
}

/**
 * Feuille d'info affichée avant de lancer un examen blanc ciblé (thème civique,
 * épreuve TCF QCM, EE/EO). Explique le déroulé + le seuil, puis « Démarrer »
 * lance réellement l'examen. Même squelette bottom-sheet/dialog que
 * ConfirmSheet. Pour la CO, l'écran d'écoute du runner reste une seconde
 * confirmation après celle-ci.
 */
export function ExamIntroSheet({
  open,
  eyebrow,
  title,
  subtitle,
  facts,
  tips,
  confirmLabel = "Démarrer l'examen",
  loading = false,
  error,
  onConfirm,
  onClose,
}: {
  open: boolean;
  eyebrow: string;
  title: string;
  subtitle?: string;
  facts: ExamFact[];
  tips: string[];
  confirmLabel?: string;
  loading?: boolean;
  error?: string | null;
  onConfirm: () => void;
  onClose: () => void;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !loading) onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, loading, onClose]);

  if (!open) return null;

  return (
    <div className="eis-overlay" onClick={() => !loading && onClose()} role="presentation">
      <div className="eis-sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
        <div className="eis-handle" aria-hidden />

        <div className="eis-eyebrow">{eyebrow}</div>
        <h2 className="eis-title">{title}</h2>
        {subtitle && <p className="eis-subtitle">{subtitle}</p>}

        <div className="eis-facts">
          {facts.map((f) => (
            <div key={f.label} className="eis-fact">
              <span className="eis-fact-value" data-good={f.highlight ? "" : undefined}>
                {f.value}
              </span>
              <span className="eis-fact-label">{f.label}</span>
            </div>
          ))}
        </div>

        {tips.length > 0 && (
          <div className="eis-tips">
            <div className="eis-tips-title">À savoir</div>
            <ul className="eis-tips-list">
              {tips.map((t) => (
                <li key={t}>{t}</li>
              ))}
            </ul>
          </div>
        )}

        {error && <div className="eis-error">{error}</div>}

        <button type="button" className="eis-btn eis-confirm" onClick={onConfirm} disabled={loading}>
          {loading ? "Démarrage…" : confirmLabel}
        </button>
        <button type="button" className="eis-btn eis-cancel" onClick={onClose} disabled={loading}>
          Annuler
        </button>

        <style>{`
          .eis-overlay {
            position: fixed; inset: 0; z-index: 1000;
            background: rgba(15, 24, 57, 0.45);
            display: flex; align-items: flex-end; justify-content: center;
            animation: eis-fade 0.15s ease;
          }
          .eis-sheet {
            width: 100%; max-width: 480px;
            background: #fff;
            border-radius: 22px 22px 0 0;
            padding: 10px 22px calc(22px + env(safe-area-inset-bottom));
            box-shadow: 0 -20px 50px -20px rgba(15, 24, 57, 0.3);
            animation: eis-up 0.2s ease;
            max-height: 92vh; overflow-y: auto;
          }
          .eis-handle {
            width: 36px; height: 4px; border-radius: 2px;
            background: var(--color-line-2);
            margin: 6px auto 14px;
          }
          .eis-eyebrow {
            font-family: var(--font-mono); font-weight: 700; font-size: 11px;
            letter-spacing: 0.08em; text-transform: uppercase;
            color: var(--color-red); text-align: center;
          }
          .eis-title {
            font-family: var(--font-sans); font-weight: 800; font-size: 19px;
            line-height: 1.25; color: var(--color-ink); text-align: center;
            margin: 5px 0 0;
          }
          .eis-subtitle {
            font-size: 13px; line-height: 1.5; color: var(--color-muted);
            text-align: center; margin: 7px 0 0;
          }
          .eis-facts {
            display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px;
            margin: 16px 0 4px;
          }
          .eis-fact {
            display: flex; flex-direction: column; align-items: center; gap: 2px;
            background: var(--color-paper-2); border-radius: 12px;
            padding: 12px 8px; text-align: center;
          }
          .eis-fact-value {
            font-family: var(--font-display); font-weight: 700; font-size: 18px;
            color: var(--color-ink); line-height: 1.1;
          }
          .eis-fact-value[data-good] { color: var(--color-green); }
          .eis-fact-label {
            font-size: 11px; line-height: 1.3; color: var(--color-muted);
          }
          .eis-tips {
            margin-top: 14px; background: var(--color-blue-soft, var(--color-paper-2));
            border-radius: 12px; padding: 12px 14px;
          }
          .eis-tips-title {
            font-family: var(--font-mono); font-weight: 700; font-size: 10.5px;
            letter-spacing: 0.07em; text-transform: uppercase;
            color: var(--color-blue); margin-bottom: 6px;
          }
          .eis-tips-list {
            margin: 0; padding-left: 18px;
            display: flex; flex-direction: column; gap: 5px;
          }
          .eis-tips-list li {
            font-size: 12.5px; line-height: 1.45; color: var(--color-ink-2);
          }
          .eis-error {
            margin-top: 12px; font-size: 12.5px; color: var(--color-red);
            text-align: center;
          }
          .eis-btn {
            width: 100%; margin-top: 12px;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            border: none; border-radius: 12px; padding: 13px;
            font-family: var(--font-sans); font-weight: 800; font-size: 14px;
            cursor: pointer;
          }
          .eis-btn:disabled { opacity: 0.6; cursor: default; }
          .eis-confirm { background: var(--color-red); color: #fff; }
          .eis-cancel { background: var(--color-paper-2); color: var(--color-ink-2); }
          @media (min-width: 560px) {
            .eis-overlay { align-items: center; }
            .eis-sheet { border-radius: 20px; }
          }
          @keyframes eis-fade { from { opacity: 0; } to { opacity: 1; } }
          @keyframes eis-up { from { transform: translateY(16px); } to { transform: translateY(0); } }
        `}</style>
      </div>
    </div>
  );
}
