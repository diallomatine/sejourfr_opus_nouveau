"use client";

import {useEffect} from "react";
import {FileText, RotateCcw} from "lucide-react";

/**
 * Feuille « déjà fait » — miroir de `ExamDoneSheet` mobile. Affichée quand on
 * tape quelque chose de terminé : « Voir le détail » (rapport / session finie)
 * + « Reprendre » (nouvelle tentative, premium-gated en amont par l'appelant).
 * Bottom sheet sur mobile, dialog centré sur desktop.
 *
 * Les deux libellés et la teinte du second bouton sont **facultatifs**, valeurs
 * par défaut inchangées : c'est ce qui permet au module « Compétences » de
 * réutiliser exactement ce geste (relire son dernier retour / refaire le sujet)
 * au lieu d'inventer une seconde feuille pour la même intention.
 */
export function ExamDoneSheet({
  open,
  title = "Examen blanc",
  subtitle,
  detailLabel = "Voir le détail",
  resumeLabel = "Reprendre",
  resumeTone = "red",
  onViewDetail,
  onResume,
  onClose,
}: {
  open: boolean;
  title?: string;
  subtitle?: string | null;
  detailLabel?: string;
  resumeLabel?: string;
  /** `red` = geste lourd (relancer un examen) ; `blue` = simple reprise. */
  resumeTone?: "red" | "blue";
  onViewDetail: () => void;
  onResume: () => void;
  onClose: () => void;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="eds-overlay" onClick={onClose} role="presentation">
      <div className="eds-sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
        <div className="eds-handle" aria-hidden />
        <h2 className="eds-title">{title}</h2>
        {subtitle && <p className="eds-sub">{subtitle}</p>}
        <button type="button" className="eds-btn eds-detail" onClick={onViewDetail}>
          <FileText size={18} strokeWidth={2} />
          {detailLabel}
        </button>
        <button
          type="button"
          className={`eds-btn ${resumeTone === "blue" ? "eds-resume-blue" : "eds-resume"}`}
          onClick={onResume}
        >
          <RotateCcw size={18} strokeWidth={2} />
          {resumeLabel}
        </button>

        <style>{`
          .eds-overlay {
            position: fixed; inset: 0; z-index: 1000;
            background: rgba(15, 24, 57, 0.45);
            display: flex; align-items: flex-end; justify-content: center;
            animation: eds-fade 0.15s ease;
          }
          .eds-sheet {
            width: 100%; max-width: 460px;
            background: #fff;
            border-radius: 22px 22px 0 0;
            padding: 10px 20px calc(20px + env(safe-area-inset-bottom));
            box-shadow: 0 -20px 50px -20px rgba(15, 24, 57, 0.3);
            animation: eds-up 0.2s ease;
          }
          .eds-handle {
            width: 36px; height: 4px; border-radius: 2px;
            background: var(--color-line-2);
            margin: 6px auto 14px;
          }
          .eds-title {
            font-family: var(--font-sans); font-weight: 800; font-size: 18px;
            color: var(--color-ink); text-align: center; margin: 0;
          }
          .eds-sub {
            font-size: 12.5px; color: var(--color-muted);
            text-align: center; margin: 4px 0 0;
          }
          .eds-btn {
            width: 100%; margin-top: 12px;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            border: none; border-radius: 12px; padding: 13px;
            font-family: var(--font-sans); font-weight: 800; font-size: 14px;
            cursor: pointer;
          }
          .eds-detail { background: var(--color-blue-light); color: var(--color-blue); }
          .eds-resume { background: var(--color-red); color: #fff; }
          .eds-resume-blue { background: var(--color-blue); color: #fff; }
          @media (min-width: 560px) {
            .eds-overlay { align-items: center; }
            .eds-sheet { border-radius: 20px; }
          }
          @keyframes eds-fade { from { opacity: 0; } to { opacity: 1; } }
          @keyframes eds-up { from { transform: translateY(16px); } to { transform: translateY(0); } }
        `}</style>
      </div>
    </div>
  );
}
