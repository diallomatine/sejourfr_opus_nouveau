"use client";

import { useEffect } from "react";
import { AlertTriangle, Info } from "lucide-react";

/**
 * Feuille de confirmation / d'information générique (même squelette que
 * ExamDoneSheet : bottom sheet mobile, dialog centré desktop). Deux usages :
 *  - `onConfirm` fourni → avertissement avec Confirmer / Annuler ;
 *  - sans `onConfirm` → simple modale d'info avec un bouton « Compris ».
 */
export function ConfirmSheet({
  open,
  tone = "warning",
  title,
  message,
  confirmLabel = "Continuer",
  cancelLabel = "Annuler",
  onConfirm,
  onClose,
}: {
  open: boolean;
  tone?: "warning" | "info";
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  onConfirm?: () => void;
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
    <div className="cfs-overlay" onClick={onClose} role="presentation">
      <div
        className="cfs-sheet"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="cfs-title"
      >
        <div className="cfs-handle" aria-hidden />
        <div className={`cfs-icon cfs-icon-${tone}`} aria-hidden>
          {tone === "warning" ? (
            <AlertTriangle size={22} strokeWidth={2} />
          ) : (
            <Info size={22} strokeWidth={2} />
          )}
        </div>
        <h2 id="cfs-title" className="cfs-title">
          {title}
        </h2>
        <p className="cfs-msg">{message}</p>
        {onConfirm ? (
          <>
            <button type="button" className="cfs-btn cfs-confirm" onClick={onConfirm}>
              {confirmLabel}
            </button>
            <button type="button" className="cfs-btn cfs-cancel" onClick={onClose}>
              {cancelLabel}
            </button>
          </>
        ) : (
          <button type="button" className="cfs-btn cfs-ok" onClick={onClose}>
            Compris
          </button>
        )}

        <style>{`
          .cfs-overlay {
            position: fixed; inset: 0; z-index: 1000;
            background: rgba(15, 24, 57, 0.45);
            display: flex; align-items: flex-end; justify-content: center;
            animation: cfs-fade 0.15s ease;
          }
          .cfs-sheet {
            width: 100%; max-width: 460px;
            background: #fff;
            border-radius: 22px 22px 0 0;
            padding: 10px 22px calc(22px + env(safe-area-inset-bottom));
            box-shadow: 0 -20px 50px -20px rgba(15, 24, 57, 0.3);
            animation: cfs-up 0.2s ease;
          }
          .cfs-handle {
            width: 36px; height: 4px; border-radius: 2px;
            background: var(--color-line-2);
            margin: 6px auto 14px;
          }
          .cfs-icon {
            width: 46px; height: 46px; border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 12px;
          }
          .cfs-icon-warning { background: rgba(232, 163, 23, 0.14); color: var(--color-amber); }
          .cfs-icon-info { background: var(--color-blue-light); color: var(--color-blue); }
          .cfs-title {
            font-family: var(--font-sans); font-weight: 800; font-size: 18px;
            color: var(--color-ink); text-align: center; margin: 0;
          }
          .cfs-msg {
            font-size: 13.5px; line-height: 1.55; color: var(--color-muted);
            text-align: center; margin: 8px 0 4px;
          }
          .cfs-btn {
            width: 100%; margin-top: 12px;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            border: none; border-radius: 12px; padding: 13px;
            font-family: var(--font-sans); font-weight: 800; font-size: 14px;
            cursor: pointer;
          }
          .cfs-confirm { background: var(--color-red); color: #fff; }
          .cfs-cancel { background: var(--color-paper-2); color: var(--color-ink-2); }
          .cfs-ok { background: var(--color-blue); color: #fff; }
          @media (min-width: 560px) {
            .cfs-overlay { align-items: center; }
            .cfs-sheet { border-radius: 20px; }
          }
          @keyframes cfs-fade { from { opacity: 0; } to { opacity: 1; } }
          @keyframes cfs-up { from { transform: translateY(16px); } to { transform: translateY(0); } }
        `}</style>
      </div>
    </div>
  );
}
