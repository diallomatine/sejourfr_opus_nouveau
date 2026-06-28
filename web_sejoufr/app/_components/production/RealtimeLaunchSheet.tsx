"use client";

import {useEffect} from "react";
import {Mic, Radio} from "lucide-react";

/**
 * Modal de lancement d'une Tâche 1 / 2 d'expression orale (§2.3). Propose le
 * mode TEMPS RÉEL (examinateur IA) ou le mode CLASSIQUE (enregistrement), et
 * affiche le nombre de sessions temps réel restantes. Quota épuisé / non
 * éligible → option temps réel désactivée, message clair, le candidat fait
 * l'épreuve en enregistrement (jamais bloqué).
 */
export function RealtimeLaunchSheet({
    open,
    tacheNumero,
    taskTitle,
    sessionsRemaining,
    realtimeAvailable,
    starting,
    error,
    onPickRealtime,
    onPickClassic,
    onClose,
}: {
    open: boolean;
    tacheNumero: number;
    taskTitle: string;
    /** Sessions temps réel restantes (null = inconnu / non concerné). */
    sessionsRemaining: number | null;
    /** False = quota épuisé ou pass sans temps réel → seul le classique. */
    realtimeAvailable: boolean;
    starting: boolean;
    error?: string | null;
    onPickRealtime: () => void;
    onPickClassic: () => void;
    onClose: () => void;
}) {
    useEffect(() => {
        if (!open) return;
        const onKey = (e: KeyboardEvent) => {
            if (e.key === "Escape" && !starting) onClose();
        };
        window.addEventListener("keydown", onKey);
        return () => window.removeEventListener("keydown", onKey);
    }, [open, starting, onClose]);

    if (!open) return null;

    const remainingLabel =
        sessionsRemaining == null
            ? null
            : sessionsRemaining > 0
              ? `${sessionsRemaining} session${sessionsRemaining > 1 ? "s" : ""} en temps réel restante${sessionsRemaining > 1 ? "s" : ""}`
              : "Plus de session en temps réel ce mois-ci";

    return (
        <div className="rls-overlay" onClick={() => !starting && onClose()} role="presentation">
            <div className="rls-sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
                <div className="rls-handle" aria-hidden />
                <div className="rls-eyebrow">Tâche {tacheNumero}</div>
                <h2 className="rls-title">{taskTitle}</h2>
                <p className="rls-subtitle">Comment souhaitez-vous passer cette partie&nbsp;?</p>

                <button
                    type="button"
                    className="rls-option rls-rt"
                    onClick={onPickRealtime}
                    disabled={starting || !realtimeAvailable}
                >
                    <span className="rls-opt-ico"><Radio size={20} strokeWidth={2} /></span>
                    <span className="rls-opt-body">
                        <span className="rls-opt-title">Passer en temps réel avec un examinateur</span>
                        <span className="rls-opt-desc">
                            {"Un examinateur vocal mène l'échange, comme le jour de l'examen."}
                        </span>
                    </span>
                </button>

                {remainingLabel && (
                    <p className={`rls-remaining${realtimeAvailable ? "" : " is-empty"}`}>{remainingLabel}</p>
                )}

                <button
                    type="button"
                    className="rls-option rls-classic"
                    onClick={onPickClassic}
                    disabled={starting}
                >
                    <span className="rls-opt-ico"><Mic size={20} strokeWidth={2} /></span>
                    <span className="rls-opt-body">
                        <span className="rls-opt-title">Le faire en mode classique</span>
                        <span className="rls-opt-desc">{"Vous enregistrez votre réponse, l'IA l'évalue ensuite."}</span>
                    </span>
                </button>

                {error && <div className="rls-error">{error}</div>}
                {starting && <p className="rls-starting">{"Connexion à l'examinateur…"}</p>}

                <button type="button" className="rls-cancel" onClick={onClose} disabled={starting}>
                    Annuler
                </button>

                <style>{`
                    .rls-overlay {
                        position: fixed; inset: 0; z-index: 1000;
                        background: rgba(15, 24, 57, 0.45);
                        display: flex; align-items: flex-end; justify-content: center;
                        animation: rls-fade 0.15s ease;
                    }
                    .rls-sheet {
                        width: 100%; max-width: 480px; background: #fff;
                        border-radius: 22px 22px 0 0;
                        padding: 10px 22px calc(22px + env(safe-area-inset-bottom));
                        box-shadow: 0 -20px 50px -20px rgba(15, 24, 57, 0.3);
                        animation: rls-up 0.2s ease; max-height: 92vh; overflow-y: auto;
                    }
                    .rls-handle {
                        width: 36px; height: 4px; border-radius: 2px;
                        background: var(--color-line-2); margin: 6px auto 14px;
                    }
                    .rls-eyebrow {
                        font-family: var(--font-mono); font-weight: 700; font-size: 11px;
                        letter-spacing: 0.08em; text-transform: uppercase;
                        color: var(--color-red); text-align: center;
                    }
                    .rls-title {
                        font-family: var(--font-sans); font-weight: 800; font-size: 19px;
                        line-height: 1.25; color: var(--color-ink); text-align: center; margin: 5px 0 0;
                    }
                    .rls-subtitle {
                        font-size: 13px; line-height: 1.5; color: var(--color-muted);
                        text-align: center; margin: 7px 0 16px;
                    }
                    .rls-option {
                        width: 100%; display: flex; align-items: flex-start; gap: 12px;
                        text-align: left; border: 1px solid var(--color-line);
                        border-radius: 14px; padding: 14px; background: #fff;
                        cursor: pointer; margin-bottom: 10px;
                    }
                    .rls-option:disabled { opacity: 0.5; cursor: default; }
                    .rls-rt { border-color: var(--color-red); background: var(--color-red-light, #FDECEB); }
                    .rls-rt:disabled { border-color: var(--color-line); background: var(--color-paper-2); }
                    .rls-opt-ico {
                        flex-shrink: 0; width: 40px; height: 40px; border-radius: 11px;
                        display: flex; align-items: center; justify-content: center;
                        background: #fff; color: var(--color-red);
                        border: 1px solid var(--color-line);
                    }
                    .rls-classic .rls-opt-ico { color: var(--color-blue); }
                    .rls-opt-body { display: flex; flex-direction: column; gap: 3px; min-width: 0; }
                    .rls-opt-title {
                        font-family: var(--font-sans); font-weight: 800; font-size: 14px;
                        color: var(--color-ink);
                    }
                    .rls-opt-desc { font-size: 12.5px; line-height: 1.4; color: var(--color-muted); }
                    .rls-remaining {
                        font-family: var(--font-mono); font-size: 11px; font-weight: 700;
                        letter-spacing: 0.04em; text-transform: uppercase;
                        color: var(--color-red); text-align: center; margin: -2px 0 12px;
                    }
                    .rls-remaining.is-empty { color: var(--color-muted); }
                    .rls-error {
                        margin-top: 4px; font-size: 12.5px; color: var(--color-red); text-align: center;
                    }
                    .rls-starting {
                        margin-top: 4px; font-size: 12.5px; color: var(--color-muted); text-align: center;
                    }
                    .rls-cancel {
                        width: 100%; margin-top: 10px; border: none; border-radius: 12px; padding: 13px;
                        background: var(--color-paper-2); color: var(--color-ink-2);
                        font-family: var(--font-sans); font-weight: 800; font-size: 14px; cursor: pointer;
                    }
                    .rls-cancel:disabled { opacity: 0.6; cursor: default; }
                    @media (min-width: 560px) {
                        .rls-overlay { align-items: center; }
                        .rls-sheet { border-radius: 20px; }
                    }
                    @keyframes rls-fade { from { opacity: 0; } to { opacity: 1; } }
                    @keyframes rls-up { from { transform: translateY(16px); } to { transform: translateY(0); } }
                `}</style>
            </div>
        </div>
    );
}
