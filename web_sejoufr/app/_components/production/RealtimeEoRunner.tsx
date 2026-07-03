"use client";

import {useCallback, useEffect, useRef, useState} from "react";
import {Mic, MessagesSquare, Square, Volume2, X} from "lucide-react";
import {realtimeApi} from "@/lib/api";
import {GeminiLiveSession, type GeminiLiveState} from "@/lib/realtime/geminiLive";
import type {RealtimeSessionDescriptor, RealtimeSpeaker} from "@/lib/types";
import {TranscriptDialogue} from "./TranscriptDialogue";

/** Grâce après le temps écoulé : laisse l'examinateur dire sa phrase de clôture. */
const CLOSE_GRACE_SEC = 7;

function fmt(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}:${String(s).padStart(2, "0")}`;
}

/**
 * Pilote une session d'expression orale temps réel : connexion Gemini Live via
 * `GeminiLiveSession`, minuteur par tâche, relais batché du transcript vers le
 * backend (pour la NOTATION). L'écran est centré sur un GROS MICRO + un libellé
 * d'état (« À vous de parler » / « L'examinateur parle… ») — pas d'affichage du
 * dialogue. À la clôture, le backend a créé la submission + lancé la notation →
 * `onFinished`. Erreur fatale → `onFatalError` (repli classique).
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
    // Dialogue affiché à la demande (bouton « Voir ma transcription »). Chaque
    // tour terminé arrive comme UNE ligne complète → une bulle.
    const [lines, setLines] = useState<{speaker: RealtimeSpeaker; text: string}[]>([]);
    const [showTranscript, setShowTranscript] = useState(false);

    const liveRef = useRef<GeminiLiveSession | null>(null);
    const sheetBodyRef = useRef<HTMLDivElement | null>(null);
    const pendingRef = useRef<Record<RealtimeSpeaker, string>>({CANDIDATE: "", EXAMINER: ""});
    const finishedRef = useRef(false);
    const elapsedRef = useRef(0);
    const timeUpRef = useRef(false);

    // Relais batché du transcript (~1,2 s) : capture serveur fiable du dialogue
    // (artefact de notation). On NE l'affiche PAS — on l'envoie seulement.
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
                setLines((prev) => [...prev, {speaker: "CANDIDATE", text: t}]);
            },
            onExaminerTranscript: (t) => {
                pendingRef.current.EXAMINER += (pendingRef.current.EXAMINER ? " " : "") + t;
                setLines((prev) => [...prev, {speaker: "EXAMINER", text: t}]);
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
    // clôture après une courte grâce (phrase de fin de l'examinateur).
    useEffect(() => {
        // Le chrono ne démarre QU'AU premier mot de l'examinateur (passage en
        // "live" via beginConversation), pas pendant l'accueil : la latence de
        // connexion/greeting ne doit pas amputer le temps de parole du candidat.
        // Le garde-fou de 8 s côté client promeut welcoming → live même sans
        // audio, donc le chrono finit toujours par démarrer.
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

    // Panneau ouvert / nouveau tour → on colle le dialogue en bas.
    useEffect(() => {
        if (showTranscript && sheetBodyRef.current) {
            sheetBodyRef.current.scrollTop = sheetBodyRef.current.scrollHeight;
        }
    }, [showTranscript, lines.length]);

    const remaining = Math.max(0, target - elapsed);
    const yourTurn = state === "live" && !examinerSpeaking && !timeUp;
    const statusLabel = finishing
        ? "Préparation de votre évaluation…"
        : state === "connecting"
          ? "Connexion à l'examinateur…"
          : state === "welcoming"
            ? "L'examinateur vous accueille…"
            : timeUp
              ? "Temps écoulé — l'examinateur conclut."
              : examinerSpeaking
                ? "L'examinateur parle…"
                : "À vous de parler.";
    const hint = finishing || state === "connecting" || timeUp
        ? taskTitle
        : state === "welcoming"
          ? "Un instant — votre micro s'activera après son accueil."
          : examinerSpeaking
            ? "Écoutez sa question, puis répondez à voix haute."
            : "Parlez naturellement, comme à un vrai oral.";

    return (
        <div className="rte">
            <div className="rte-strip">
                <span className="rte-id-row">
                    <span className="rte-name">Examinateur IA</span>
                    <span className="rte-ia">IA</span>
                </span>
                <span className="rte-right">
                    {state !== "connecting" && (
                        <span className="rte-live"><span className="rte-dot" />EN DIRECT</span>
                    )}
                    {(state === "live" || timeUp) && (
                        <span className={`rte-timer${remaining <= 15 && !timeUp ? " is-urgent" : ""}`}>
                            {timeUp ? "0:00" : fmt(remaining)}
                        </span>
                    )}
                </span>
            </div>

            <div className="rte-stage">
                <div className={`rte-mic${examinerSpeaking ? " is-exam" : ""}${yourTurn ? " is-you" : ""}`} aria-hidden>
                    <span className="rte-halo" />
                    <span className="rte-disc">
                        {examinerSpeaking ? <Volume2 size={46} strokeWidth={1.8} /> : <Mic size={46} strokeWidth={1.8} />}
                    </span>
                </div>
                <p className="rte-state">{statusLabel}</p>
                <p className="rte-hint">{hint}</p>
            </div>

            <div className="rte-actions">
                {lines.length > 0 && (
                    <button
                        type="button"
                        className="rte-see"
                        onClick={() => setShowTranscript(true)}
                    >
                        <MessagesSquare size={16} strokeWidth={2} />
                        Voir ma transcription
                    </button>
                )}
                <button
                    type="button"
                    className="rte-stop"
                    onClick={() => void finish()}
                    disabled={finishing || state === "connecting"}
                >
                    <Square size={16} strokeWidth={2.4} fill="currentColor" />
                    Terminer l&apos;oral
                </button>
            </div>

            {showTranscript && (
                <div className="rte-sheet" role="dialog" aria-modal="true" aria-label="Transcription de l'échange">
                    <div className="rte-sheet-head">
                        <span className="rte-sheet-title">Transcription</span>
                        <button
                            type="button"
                            className="rte-sheet-close"
                            onClick={() => setShowTranscript(false)}
                            aria-label="Fermer"
                        >
                            <X size={18} strokeWidth={2.2} />
                        </button>
                    </div>
                    <div className="rte-sheet-body" ref={sheetBodyRef}>
                        {lines.length === 0 ? (
                            <p className="rte-sheet-empty">Le dialogue s&apos;affichera ici au fil de l&apos;échange.</p>
                        ) : (
                            <TranscriptDialogue lines={lines} />
                        )}
                    </div>
                </div>
            )}

            <style>{`
                .rte { position: relative; display: flex; flex-direction: column; gap: 18px; min-height: 60vh; }
                .rte-strip {
                    display: flex; align-items: center; justify-content: space-between; gap: 12px;
                    background: #fff; border: 1px solid var(--color-line);
                    border-radius: 14px; padding: 12px 14px;
                }
                .rte-id-row { display: flex; align-items: center; gap: 8px; min-width: 0; }
                .rte-name { font-family: var(--font-sans); font-weight: 800; font-size: 15px; color: var(--color-ink); }
                .rte-ia {
                    font-family: var(--font-mono); font-weight: 700; font-size: 10px;
                    color: var(--color-red-dark, #B5251E); background: #fff;
                    border: 1px solid var(--color-red); border-radius: 5px; padding: 1px 5px;
                }
                .rte-right { display: flex; align-items: center; gap: 12px; flex-shrink: 0; }
                .rte-live {
                    display: inline-flex; align-items: center; gap: 5px;
                    font-family: var(--font-mono); font-weight: 700; font-size: 10px;
                    letter-spacing: 0.06em; color: var(--color-red);
                }
                .rte-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--color-red); animation: rte-blink 1.4s ease-in-out infinite; }
                .rte-timer { font-family: var(--font-mono); font-weight: 700; font-size: 20px; color: var(--color-red); line-height: 1; }
                .rte-timer.is-urgent { color: var(--color-red-dark, #B5251E); }

                .rte-stage {
                    flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
                    text-align: center; gap: 8px; padding: 24px 8px;
                }
                .rte-mic { position: relative; width: 180px; height: 180px; display: flex; align-items: center; justify-content: center; }
                .rte-halo {
                    position: absolute; inset: 0; border-radius: 50%;
                    background: var(--color-red-light, #FDECEB); opacity: 0.5;
                }
                .rte-mic.is-you .rte-halo { animation: rte-pulse 1.6s ease-out infinite; opacity: 1; }
                .rte-mic.is-exam .rte-halo { background: var(--color-blue-light, #E8ECF8); opacity: 1; }
                .rte-disc {
                    position: relative; width: 108px; height: 108px; border-radius: 50%;
                    display: flex; align-items: center; justify-content: center;
                    background: var(--color-red); color: #fff;
                    box-shadow: 0 10px 30px rgba(225, 55, 47, 0.28);
                }
                .rte-mic.is-exam .rte-disc { background: var(--color-blue); box-shadow: 0 10px 30px rgba(30, 58, 140, 0.26); }
                .rte-state { font-family: var(--font-display); font-size: 22px; color: var(--color-ink); margin: 8px 0 0; }
                .rte-hint { font-size: 13px; color: var(--color-muted); margin: 0; max-width: 320px; }

                .rte-stop {
                    align-self: center; display: inline-flex; align-items: center; gap: 8px;
                    border: none; border-radius: 12px; padding: 13px 26px;
                    background: var(--color-ink); color: #fff;
                    font-family: var(--font-sans); font-weight: 800; font-size: 14px; cursor: pointer;
                }
                .rte-stop:disabled { opacity: 0.5; cursor: default; }

                .rte-actions { display: flex; flex-direction: column; align-items: center; gap: 10px; }
                .rte-see {
                    display: inline-flex; align-items: center; gap: 8px;
                    border: 1px solid var(--color-line); border-radius: 12px;
                    padding: 10px 18px; background: #fff; color: var(--color-blue);
                    font-family: var(--font-sans); font-weight: 700; font-size: 13px; cursor: pointer;
                }
                .rte-see:hover { background: var(--color-blue-soft, #F4F6FC); }

                .rte-sheet {
                    position: absolute; inset: 0; z-index: 5;
                    background: #fff; border: 1px solid var(--color-line); border-radius: 14px;
                    display: flex; flex-direction: column; overflow: hidden;
                }
                .rte-sheet-head {
                    display: flex; align-items: center; justify-content: space-between;
                    padding: 14px 16px; border-bottom: 1px solid var(--color-line); flex-shrink: 0;
                }
                .rte-sheet-title { font-family: var(--font-display); font-size: 18px; color: var(--color-ink); }
                .rte-sheet-close {
                    display: inline-flex; border: none; cursor: pointer;
                    background: var(--color-paper-2, #F2F1EC); border-radius: 9px; padding: 6px; color: var(--color-ink);
                }
                .rte-sheet-body {
                    flex: 1; overflow-y: auto; padding: 16px;
                    display: flex; flex-direction: column; gap: 10px;
                }
                .rte-sheet-empty { color: var(--color-muted); font-size: 13px; text-align: center; margin: auto; max-width: 240px; }

                @keyframes rte-pulse {
                    0% { box-shadow: 0 0 0 0 rgba(225, 55, 47, 0.40); transform: scale(1); }
                    100% { box-shadow: 0 0 0 26px rgba(225, 55, 47, 0); transform: scale(1.04); }
                }
                @keyframes rte-blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
            `}</style>
        </div>
    );
}
