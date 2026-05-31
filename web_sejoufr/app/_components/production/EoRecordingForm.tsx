"use client";

import {useEffect, useRef, useState} from "react";
import {Clock, Mic, RotateCcw, Square} from "lucide-react";
import {formatDurationSec, type ProductionTaskDto} from "@/lib/types";
import styles from "./production.module.css";

/** Les 5 critères d'évaluation EO (affichés avant l'enregistrement). */
const EO_CRITERIA = [
  "Pertinence et richesse du contenu",
  "Aisance et fluidité",
  "Correction grammaticale",
  "Lexique et précision",
  "Prononciation et intonation",
];

/** Choisit un conteneur audio supporté par le navigateur (Chrome/FF: webm,
 *  Safari: mp4). Whisper accepte ces formats. */
function pickMime(): {mime: string; ext: string} {
  if (typeof MediaRecorder === "undefined") return {mime: "", ext: "webm"};
  const candidates = [
    {mime: "audio/webm", ext: "webm"},
    {mime: "audio/mp4", ext: "mp4"},
    {mime: "audio/ogg", ext: "ogg"},
  ];
  for (const c of candidates) {
    if (MediaRecorder.isTypeSupported(c.mime)) return c;
  }
  return {mime: "", ext: "webm"};
}

function fmtTimer(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

/**
 * Enregistrement d'une tâche EO via le micro du navigateur (`MediaRecorder`) :
 * consigne + critères + bouton micro, chrono, réécoute, refaire, envoi. Pendant
 * de `EeWritingForm` côté oral. La logique d'attempt/navigation reste au parent
 * via `onSubmit(audio, durationSec)`.
 */
export function EoRecordingForm({
  task,
  submitting,
  error,
  submitLabel = "Soumettre à l'évaluation",
  onSubmit,
}: {
  task: ProductionTaskDto;
  submitting: boolean;
  error?: string | null;
  submitLabel?: string;
  onSubmit: (audio: Blob, durationSec: number) => void;
}) {
  const [phase, setPhase] = useState<"idle" | "recording" | "recorded">("idle");
  const [elapsed, setElapsed] = useState(0);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [permError, setPermError] = useState<string | null>(null);

  const recorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const blobRef = useRef<Blob | null>(null);
  const extRef = useRef("webm");
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Nettoyage : stoppe le flux micro + révoque l'URL à la destruction.
  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      streamRef.current?.getTracks().forEach((t) => t.stop());
      if (audioUrl) URL.revokeObjectURL(audioUrl);
    };
  }, [audioUrl]);

  async function start() {
    setPermError(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({audio: true});
      streamRef.current = stream;
      const {mime, ext} = pickMime();
      extRef.current = ext;
      const rec = mime ? new MediaRecorder(stream, {mimeType: mime}) : new MediaRecorder(stream);
      chunksRef.current = [];
      rec.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      rec.onstop = () => {
        const blob = new Blob(chunksRef.current, {type: rec.mimeType || "audio/webm"});
        blobRef.current = blob;
        setAudioUrl((prev) => {
          if (prev) URL.revokeObjectURL(prev);
          return URL.createObjectURL(blob);
        });
        setPhase("recorded");
        streamRef.current?.getTracks().forEach((t) => t.stop());
        streamRef.current = null;
      };
      recorderRef.current = rec;
      rec.start();
      setElapsed(0);
      setPhase("recording");
      timerRef.current = setInterval(() => setElapsed((e) => e + 1), 1000);
    } catch {
      setPermError(
        "Micro inaccessible. Autorisez le microphone dans votre navigateur, puis réessayez.",
      );
    }
  }

  function stop() {
    if (timerRef.current) clearInterval(timerRef.current);
    recorderRef.current?.stop();
  }

  function redo() {
    setAudioUrl((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return null;
    });
    blobRef.current = null;
    setElapsed(0);
    setPhase("idle");
  }

  const min = task.dureeMinSec;
  const max = task.dureeMaxSec;
  const inRange = (min == null || elapsed >= min) && (max == null || elapsed <= max);
  const timerClass =
    phase === "idle" ? "" : inRange ? styles.timerOk : styles.timerWarn;
  const rangeLabel =
    min != null && max != null
      ? `${formatDurationSec(min)} – ${formatDurationSec(max)}`
      : max != null
        ? `≤ ${formatDurationSec(max)}`
        : "";

  return (
    <>
      <div className={styles.card}>
        <p className={styles.cardLabel}>Consigne · Tâche {task.tacheNumero}</p>
        <p className={styles.consigne}>{task.consigne}</p>
        {task.contexte && <div className={styles.contexte}>{task.contexte}</div>}
        <div className={styles.metaRow}>
          {rangeLabel && (
            <span className={styles.metaChip}>
              <Clock size={13} strokeWidth={2} />
              {rangeLabel}
            </span>
          )}
          <span className={styles.metaChip}>
            <Mic size={13} strokeWidth={2} />
            Niveau {task.niveauCible}
          </span>
        </div>
      </div>

      <div className={styles.card}>
        <p className={styles.cardLabel}>Vous serez évalué sur</p>
        <ul className={styles.criteriaList}>
          {EO_CRITERIA.map((c) => (
            <li key={c} className={styles.criteriaItem}>
              <span className={styles.criteriaDot} />
              {c}
            </li>
          ))}
        </ul>
      </div>

      <div className={styles.recorder}>
        <div className={`${styles.timerBig} ${timerClass}`}>{fmtTimer(elapsed)}</div>

        {phase === "recording" ? (
          <button type="button" className={`${styles.recordCircle} ${styles.recordCircleRec}`} onClick={stop}>
            <Square size={28} strokeWidth={2.2} fill="currentColor" />
          </button>
        ) : (
          <button
            type="button"
            className={styles.recordCircle}
            onClick={start}
            disabled={submitting}
            aria-label={phase === "recorded" ? "Réenregistrer" : "Démarrer l'enregistrement"}
          >
            <Mic size={32} strokeWidth={2} />
          </button>
        )}

        <p className={styles.recordHint}>
          {phase === "recording"
            ? "Enregistrement en cours… appuyez sur le carré pour arrêter."
            : phase === "recorded"
              ? "Réécoutez votre réponse, refaites-la ou envoyez-la à l'évaluation."
              : rangeLabel
                ? `Appuyez sur le micro et parlez (durée conseillée ${rangeLabel}).`
                : "Appuyez sur le micro pour vous enregistrer."}
        </p>

        {phase === "recorded" && audioUrl && (
          <div className={styles.player}>
            <audio src={audioUrl} controls preload="metadata" />
          </div>
        )}
      </div>

      {(permError || error) && <div className={styles.error}>{permError ?? error}</div>}

      {phase === "recorded" && (
        <div className={styles.submitRow}>
          <button
            type="button"
            className="btn btn-ghost"
            disabled={submitting}
            onClick={redo}
          >
            <RotateCcw size={15} strokeWidth={2.2} style={{marginRight: 6}} />
            Refaire
          </button>
          <button
            type="button"
            className={`btn btn-red btn-lg ${styles.grow}`}
            disabled={submitting}
            onClick={() => blobRef.current && onSubmit(blobRef.current, elapsed)}
          >
            {submitting ? "Envoi en cours…" : submitLabel}
          </button>
        </div>
      )}
    </>
  );
}
