"use client";

import {useCallback, useEffect, useRef, useState} from "react";
import {Radio, Square} from "lucide-react";
import {realtimeApi} from "@/lib/api";
import {GeminiLiveSession, type GeminiLiveState} from "@/lib/realtime/geminiLive";
import type {RealtimeSessionDescriptor, RealtimeSpeaker} from "@/lib/types";

/** Grâce après le temps écoulé : laisse l'examinateur dire sa phrase de clôture. */
const CLOSE_GRACE_SEC = 7;

function fmt(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}:${String(s).padStart(2, "0")}`;
}

/**
 * Pilote une session d'expression orale temps réel : connexion Gemini Live via
 * `GeminiLiveSession`, minuteur par tâche (la cible fait foi), relais batché du
 * transcript vers le backend, bouton de fin. À la clôture, le backend a créé la
 * submission + lancé la notation → `onFinished` (le parent navigue vers le
 * résultat). Erreur fatale (micro/connexion) → `onFatalError` (repli classique).
 */
export function RealtimeEoRunner({
    descriptor,
    taskTitle,
    onFinished,
    onFatalError,
}: {
    descriptor: RealtimeSessionDescriptor;
    taskTitle: string;
    onFinished: () => void;
    onFatalError: (message: string) => void;
}) {
    const sessionId = descriptor.sessionId ?? "";
    const target = descriptor.targetDurationSec ?? 210;

    const [state, setState] = useState<GeminiLiveState>("connecting");
    const [elapsed, setElapsed] = useState(0);
    const [examinerSpeaking, setExaminerSpeaking] = useState(false);
    const [timeUp, setTimeUp] = useState(false);
    const [finishing, setFinishing] = useState(false);

    const liveRef = useRef<GeminiLiveSession | null>(null);
    const pendingRef = useRef<Record<RealtimeSpeaker, string>>({CANDIDATE: "", EXAMINER: ""});
    const finishedRef = useRef(false);
    const elapsedRef = useRef(0);
    const timeUpRef = useRef(false);

    // Relais batché du transcript (~1,2 s) : capture serveur fiable du dialogue.
    const flush = useCallback(() => {
        if (!sessionId) return;
        (["CANDIDATE", "EXAMINER"] as RealtimeSpeaker[]).forEach((speaker) => {
            const text = pendingRef.current[speaker].trim();
            if (!text) return;
            pendingRef.current[speaker] = "";
            realtimeApi.appendTranscript(sessionId, speaker, text).catch(() => undefined);
        });
    }, [sessionId]);

    const finish = useCallback(async () => {
        if (finishedRef.current) return;
        finishedRef.current = true;
        setFinishing(true);
        liveRef.current?.stop();
        flush();
        // Laisse les derniers fragments partir avant de clôturer côté serveur.
        await new Promise((r) => setTimeout(r, 400));
        try {
            await realtimeApi.finishSession(sessionId);
        } catch {
            // La session reste exploitable côté backend ; on continue.
        }
        onFinished();
    }, [flush, onFinished, sessionId]);

    // Connexion Gemini Live (montée une seule fois).
    useEffect(() => {
        const live = new GeminiLiveSession(descriptor, {
            onStateChange: setState,
            onSpeakingChange: setExaminerSpeaking,
            onCandidateTranscript: (t) => {
                pendingRef.current.CANDIDATE += (pendingRef.current.CANDIDATE ? " " : "") + t;
            },
            onExaminerTranscript: (t) => {
                pendingRef.current.EXAMINER += (pendingRef.current.EXAMINER ? " " : "") + t;
            },
            onError: (m) => {
                if (!finishedRef.current) {
                    finishedRef.current = true;
                    onFatalError(m);
                }
            },
        });
        liveRef.current = live;
        live.start();
        const relay = setInterval(flush, 1200);
        return () => {
            clearInterval(relay);
            live.stop();
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    // Minuteur : la cible fait foi. À échéance, on signale au modèle puis on
    // clôture après une courte grâce (phrase de fin de l'examinateur). Les
    // setState vivent dans le callback d'intervalle (pas dans le corps d'effet).
    useEffect(() => {
        if (state !== "live") return;
        const id = setInterval(() => {
            elapsedRef.current += 1;
            setElapsed(elapsedRef.current);
            if (!timeUpRef.current && elapsedRef.current >= target) {
                timeUpRef.current = true;
                setTimeUp(true);
                liveRef.current?.notifyTimeUp();
                window.setTimeout(() => void finish(), CLOSE_GRACE_SEC * 1000);
            }
        }, 1000);
        return () => clearInterval(id);
    }, [state, target, finish]);

    const remaining = Math.max(0, target - elapsed);

    return (
        <div className="rte">
            <div className="rte-card">
                <div className={`rte-orb${examinerSpeaking ? " is-speaking" : ""}`} aria-hidden>
                    <Radio size={30} strokeWidth={2} />
                </div>
                <p className="rte-status">
                    {finishing
                        ? "Préparation de votre évaluation…"
                        : state === "connecting"
                          ? "Connexion à l'examinateur…"
                          : timeUp
                            ? "Temps écoulé — l'examinateur conclut."
                            : examinerSpeaking
                              ? "L'examinateur parle…"
                              : "À vous la parole."}
                </p>
                <div className={`rte-timer${remaining <= 15 && !timeUp ? " is-urgent" : ""}`}>
                    {timeUp ? "0:00" : fmt(remaining)}
                </div>
                <p className="rte-hint">
                    {`${taskTitle} · Parlez naturellement, l'examinateur vous répond. La conversation est enregistrée et évaluée à la fin.`}
                </p>
                <button
                    type="button"
                    className="rte-stop"
                    onClick={() => void finish()}
                    disabled={finishing || state === "connecting"}
                >
                    <Square size={16} strokeWidth={2.4} fill="currentColor" />
                    Terminer la partie
                </button>
            </div>

            <style>{`
                .rte { display: flex; flex-direction: column; gap: 14px; }
                .rte-card {
                    background: #fff; border: 1px solid var(--color-line);
                    border-radius: 18px; padding: 28px 20px;
                    display: flex; flex-direction: column; align-items: center; gap: 14px;
                    text-align: center;
                }
                .rte-orb {
                    width: 92px; height: 92px; border-radius: 50%;
                    display: flex; align-items: center; justify-content: center;
                    color: #fff; background: var(--color-red);
                    box-shadow: 0 0 0 0 rgba(225, 55, 47, 0.4);
                    transition: transform 0.2s ease;
                }
                .rte-orb.is-speaking { animation: rte-pulse 1.4s ease-out infinite; transform: scale(1.04); }
                .rte-status {
                    font-family: var(--font-sans); font-weight: 800; font-size: 15px;
                    color: var(--color-ink); margin: 0;
                }
                .rte-timer {
                    font-family: var(--font-mono); font-weight: 700; font-size: 38px;
                    color: var(--color-ink); line-height: 1;
                }
                .rte-timer.is-urgent { color: var(--color-red); }
                .rte-hint {
                    font-size: 12.5px; line-height: 1.5; color: var(--color-muted);
                    max-width: 340px; margin: 0;
                }
                .rte-stop {
                    margin-top: 4px; display: inline-flex; align-items: center; gap: 8px;
                    border: none; border-radius: 12px; padding: 12px 22px;
                    background: var(--color-ink); color: #fff;
                    font-family: var(--font-sans); font-weight: 800; font-size: 14px; cursor: pointer;
                }
                .rte-stop:disabled { opacity: 0.5; cursor: default; }
                @keyframes rte-pulse {
                    0% { box-shadow: 0 0 0 0 rgba(225, 55, 47, 0.45); }
                    100% { box-shadow: 0 0 0 22px rgba(225, 55, 47, 0); }
                }
            `}</style>
        </div>
    );
}
