"use client";

import {useEffect, useState} from "react";
import {Check, Lock, Mic, Radio, X} from "lucide-react";

/**
 * Modal de lancement d'une Tâche 1 / 2 d'expression orale (§2.3). S'ouvre pour
 * TOUT LE MONDE (abonné ou non). On SÉLECTIONNE un mode — TEMPS RÉEL
 * (examinateur IA) ou CLASSIQUE (enregistrement) — puis on confirme avec
 * « Valider ». ✕ en haut ferme sans rien lancer. Trois états de la carte temps
 * réel selon le quota :
 *  - `cap === 0` (non-abonné) → verrouillée, un clic ouvre le PAYWALL (incitation) ;
 *  - `cap > 0 && remaining === 0` (abonné, quota épuisé) → désactivée ;
 *  - sinon → sélectionnable.
 */
export function RealtimeLaunchSheet({
    open,
    tacheNumero,
    taskTitle,
    sessionsRemaining,
    cap,
    starting,
    error,
    onPickRealtime,
    onPickClassic,
    onPaywall,
    onClose,
}: {
    open: boolean;
    tacheNumero: number;
    taskTitle: string;
    /** Sessions temps réel restantes (null = inconnu / non concerné). */
    sessionsRemaining: number | null;
    /** Cap du pass : 0 = non éligible (→ paywall), > 0 = pass TCF (null = inconnu). */
    cap: number | null;
    starting: boolean;
    error?: string | null;
    onPickRealtime: () => void;
    onPickClassic: () => void;
    /** Clic sur la carte temps réel verrouillée (non-abonné). */
    onPaywall: () => void;
    onClose: () => void;
}) {
    const known = cap != null;
    const remaining = sessionsRemaining ?? 0;
    const locked = known && cap === 0; // non-abonné → paywall
    const exhausted = known && (cap ?? 0) > 0 && remaining <= 0; // abonné, quota épuisé
    const available = !known || ((cap ?? 0) > 0 && remaining > 0);

    const [selected, setSelected] = useState<"realtime" | "classic">(
        available ? "realtime" : "classic",
    );

    // Pré-sélection à l'ouverture : temps réel si dispo, sinon classique.
    useEffect(() => {
        if (open) setSelected(available ? "realtime" : "classic");
    }, [open, available]);

    useEffect(() => {
        if (!open) return;
        const onKey = (e: KeyboardEvent) => {
            if (e.key === "Escape" && !starting) onClose();
        };
        window.addEventListener("keydown", onKey);
        return () => window.removeEventListener("keydown", onKey);
    }, [open, starting, onClose]);

    if (!open) return null;

    const remainingLabel = locked
        ? "Réservé à l'abonnement Intégral — touchez pour vous abonner"
        : exhausted
          ? "Plus de session temps réel sur votre pass"
          : sessionsRemaining == null
            ? null
            : `−1 session · il vous en reste ${sessionsRemaining} sur votre pass`;

    const onRealtimeClick = () => {
        if (starting) return;
        if (locked) onPaywall();
        else if (available) setSelected("realtime");
    };

    const onValidate = () => {
        if (starting) return;
        if (selected === "realtime" && available) onPickRealtime();
        else onPickClassic();
    };

    return (
        <div className="rls-overlay" onClick={() => !starting && onClose()} role="presentation">
            <div className="rls-sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
                <button type="button" className="rls-close" onClick={onClose} disabled={starting} aria-label="Fermer">
                    <X size={18} strokeWidth={2.4} />
                </button>
                <div className="rls-handle" aria-hidden />
                <div className="rls-eyebrow">Tâche {tacheNumero}</div>
                <h2 className="rls-title">{taskTitle}</h2>
                <p className="rls-subtitle">Comment souhaitez-vous passer cette partie&nbsp;?</p>

                <button
                    type="button"
                    className={`rls-option rls-rt${selected === "realtime" && available ? " is-selected" : ""}${locked ? " is-locked" : ""}`}
                    onClick={onRealtimeClick}
                    disabled={starting || exhausted}
                    aria-pressed={selected === "realtime" && available}
                >
                    <span className="rls-opt-ico"><Radio size={20} strokeWidth={2} /></span>
                    <span className="rls-opt-body">
                        <span className="rls-opt-titrow">
                            <span className="rls-opt-title">Avec un examinateur</span>
                            <span className="rls-ia">IA</span>
                        </span>
                        <span className="rls-opt-desc">
                            {"Une intelligence artificielle joue l'examinateur : elle vous parle et vous répond en direct, comme à un vrai oral. Votre échange est noté à la fin."}
                        </span>
                    </span>
                    <span className="rls-radio" aria-hidden>
                        {locked || exhausted
                            ? <Lock size={12} strokeWidth={2.4} />
                            : selected === "realtime" && <Check size={13} strokeWidth={3} />}
                    </span>
                </button>

                {remainingLabel && (
                    <p className={`rls-remaining${available ? "" : locked ? " is-locked" : " is-empty"}`}>{remainingLabel}</p>
                )}

                <button
                    type="button"
                    className={`rls-option rls-classic${selected === "classic" ? " is-selected" : ""}`}
                    onClick={() => !starting && setSelected("classic")}
                    disabled={starting}
                    aria-pressed={selected === "classic"}
                >
                    <span className="rls-opt-ico"><Mic size={20} strokeWidth={2} /></span>
                    <span className="rls-opt-body">
                        <span className="rls-opt-title">Tout(e) seul(e) (enregistrement)</span>
                        <span className="rls-opt-desc">{"Vous parlez seul, sans interlocuteur ; votre enregistrement est ensuite évalué par l'IA."}</span>
                    </span>
                    <span className="rls-radio" aria-hidden>{selected === "classic" && <Check size={13} strokeWidth={3} />}</span>
                </button>

                {error && <div className="rls-error">{error}</div>}
                {starting && <p className="rls-starting">{"Connexion à l'examinateur…"}</p>}

                <button type="button" className="rls-valider" onClick={onValidate} disabled={starting}>
                    Valider
                </button>

                <style>{`
                    .rls-overlay {
                        position: fixed; inset: 0; z-index: 1000;
                        background: rgba(15, 24, 57, 0.45);
                        display: flex; align-items: flex-end; justify-content: center;
                        animation: rls-fade 0.15s ease;
                    }
                    .rls-sheet {
                        position: relative;
                        width: 100%; max-width: 480px; background: white;
                        border-radius: 22px 22px 0 0;
                        padding: 10px 22px calc(22px + env(safe-area-inset-bottom));
                        box-shadow: 0 -20px 50px -20px rgba(15, 24, 57, 0.3);
                        animation: rls-up 0.2s ease; max-height: 92vh; overflow-y: auto;
                    }
                    .rls-close {
                        position: absolute; top: 12px; right: 12px; z-index: 1;
                        width: 32px; height: 32px; border-radius: 50%;
                        display: flex; align-items: center; justify-content: center;
                        border: none; background: var(--color-paper-2); color: var(--color-ink-2);
                        cursor: pointer;
                    }
                    .rls-close:disabled { opacity: 0.5; cursor: default; }
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
                        position: relative; width: 100%; display: flex; align-items: flex-start; gap: 12px;
                        text-align: left; border: 1.5px solid var(--color-line);
                        border-radius: 14px; padding: 14px 38px 14px 14px; background: white;
                        cursor: pointer; margin-bottom: 10px;
                    }
                    .rls-option:disabled { opacity: 0.5; cursor: default; }
                    .rls-rt:disabled { border-color: var(--color-line); background: var(--color-paper-2); }
                    .rls-rt.is-locked { opacity: 1; cursor: pointer; border-style: dashed; border-color: var(--color-red); background: white; }
                    .rls-rt.is-locked .rls-radio { color: var(--color-red); border-color: var(--color-red); background: white; }
                    .rls-remaining.is-locked { color: var(--color-red-dark); background: var(--color-red-light); }
                    .rls-option.is-selected.rls-rt { border-color: var(--color-red); background: var(--color-red-light); }
                    .rls-option.is-selected.rls-classic { border-color: var(--color-blue); background: var(--color-blue-light); }
                    .rls-opt-ico {
                        flex-shrink: 0; width: 40px; height: 40px; border-radius: 11px;
                        display: flex; align-items: center; justify-content: center;
                        background: white; color: var(--color-red);
                        border: 1px solid var(--color-line);
                    }
                    .rls-classic .rls-opt-ico { color: var(--color-blue); }
                    .rls-opt-body { display: flex; flex-direction: column; gap: 3px; min-width: 0; }
                    .rls-opt-titrow { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
                    .rls-opt-title {
                        font-family: var(--font-sans); font-weight: 800; font-size: 14px;
                        color: var(--color-ink);
                    }
                    .rls-ia {
                        font-family: var(--font-mono); font-weight: 700; font-size: 10px;
                        letter-spacing: 0.06em; color: var(--color-red-dark);
                        background: white; border: 1px solid var(--color-red);
                        border-radius: 5px; padding: 1px 5px; line-height: 1.4;
                    }
                    .rls-opt-desc { font-size: 12.5px; line-height: 1.45; color: var(--color-muted); }
                    .rls-radio {
                        position: absolute; top: 50%; right: 14px; transform: translateY(-50%);
                        width: 20px; height: 20px; border-radius: 50%;
                        display: flex; align-items: center; justify-content: center;
                        border: 1.5px solid var(--color-line-2); background: white; color: white;
                    }
                    .rls-option.is-selected.rls-rt .rls-radio { background: var(--color-red); border-color: var(--color-red); }
                    .rls-option.is-selected.rls-classic .rls-radio { background: var(--color-blue); border-color: var(--color-blue); }
                    .rls-remaining {
                        display: inline-flex; align-self: center; gap: 6px;
                        font-family: var(--font-mono); font-size: 11px; font-weight: 700;
                        letter-spacing: 0.02em;
                        color: var(--color-red-dark);
                        background: var(--color-red-light);
                        border-radius: 8px; padding: 6px 10px; margin: -2px 0 12px;
                    }
                    .rls-remaining.is-empty {
                        color: var(--color-muted); background: var(--color-paper-2);
                    }
                    .rls-error {
                        margin-top: 4px; font-size: 12.5px; color: var(--color-red); text-align: center;
                    }
                    .rls-starting {
                        margin-top: 4px; font-size: 12.5px; color: var(--color-muted); text-align: center;
                    }
                    .rls-valider {
                        width: 100%; margin-top: 12px; border: none; border-radius: 12px; padding: 14px;
                        background: var(--color-red); color: white;
                        font-family: var(--font-sans); font-weight: 800; font-size: 15px; cursor: pointer;
                    }
                    .rls-valider:disabled { opacity: 0.6; cursor: default; }
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
