"use client";

import {useEffect, useRef, useState} from "react";
import {Clock, Mic, RotateCcw, Square} from "lucide-react";
import {formatDurationSec, type ProductionTaskDto} from "@/lib/types";
import {EoTranscriptNotice} from "./EoTranscriptNotice";
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
function pickMime(): string {
  if (typeof MediaRecorder === "undefined") return "";
  for (const mime of ["audio/webm", "audio/mp4", "audio/ogg"]) {
    if (MediaRecorder.isTypeSupported(mime)) return mime;
  }
  return "";
}

function fmtTimer(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

/** Message précis selon le type d'échec de `getUserMedia`. */
function micErrorMessage(name: string, message: string): string {
  // Chrome précise "Permission denied by system" quand c'est l'OS (et non le
  // site) qui bloque le navigateur — cas typique : site sur Autoriser mais
  // macOS n'a pas donné le micro à Chrome.
  if (/system/i.test(message)) {
    return "C'est votre système qui bloque le micro du navigateur (le site, lui, est autorisé). macOS : Réglages Système → Confidentialité et sécurité → Microphone → activez votre navigateur, puis quittez-le et relancez-le.";
  }
  switch (name) {
    case "NotAllowedError":
    case "SecurityError":
      return "Accès au micro refusé. Autorisez-le via l'icône à gauche de l'adresse → Microphone, et vérifiez aussi que votre système autorise ce navigateur à utiliser le micro (macOS : Réglages Système → Confidentialité et sécurité → Microphone). Puis réessayez.";
    case "NotFoundError":
    case "DevicesNotFoundError":
      return "Aucun microphone détecté. Branchez un micro puis réessayez.";
    case "NotReadableError":
    case "TrackStartError":
      return "Le micro est utilisé par une autre application (visioconférence, dictaphone…). Fermez-la puis réessayez.";
    default:
      return "Micro inaccessible. Autorisez le microphone dans votre navigateur, puis réessayez.";
  }
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
  examMode = false,
  onSubmit,
}: {
  task: ProductionTaskDto;
  submitting: boolean;
  error?: string | null;
  submitLabel?: string;
  /** En examen blanc : décompte par tâche (dureeMaxSec), auto-stop à 0 et
   *  soumission immédiate au stop (manuel ou auto) — pas d'étape de réécoute. */
  examMode?: boolean;
  onSubmit: (audio: Blob, durationSec: number) => void;
}) {
  const [phase, setPhase] = useState<"idle" | "recording" | "recorded">("idle");
  const [elapsed, setElapsed] = useState(0);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [permError, setPermError] = useState<string | null>(null);
  // État du droit micro, déterminé au montage (avant tout clic) pour guider
  // l'utilisateur : "ready" = on peut demander/enregistrer, sinon cas bloquant.
  const [micState, setMicState] = useState<
    "unknown" | "ready" | "denied" | "insecure" | "unsupported"
  >("unknown");

  const recorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const blobRef = useRef<Blob | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  // En examen, on soumet directement au stop : ce ref retient la durée réelle
  // au moment de l'arrêt (l'`onstop` du MediaRecorder est asynchrone).
  const submitOnStopRef = useRef(false);
  const stopElapsedRef = useRef(0);

  // Nettoyage : stoppe le flux micro + révoque l'URL à la destruction.
  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      streamRef.current?.getTracks().forEach((t) => t.stop());
      if (audioUrl) URL.revokeObjectURL(audioUrl);
    };
  }, [audioUrl]);

  // Détection du contexte + état de permission au montage (sans déclencher la
  // pop-up : on lit juste l'état pour afficher le bon message d'amorce).
  // L'état "denied" n'est qu'indicatif — l'API Permissions de Chrome peut
  // être en désaccord avec les réglages réels (changement sans reload,
  // origine localhost vs IP LAN, permission système). La source de vérité
  // est le `getUserMedia` déclenché au clic ; on re-lit aussi l'état quand
  // l'onglet reprend le focus (retour des réglages).
  useEffect(() => {
    if (typeof window === "undefined") return;
    const initial = !window.isSecureContext
      ? "insecure"
      : typeof navigator === "undefined" ||
          !navigator.mediaDevices?.getUserMedia ||
          typeof MediaRecorder === "undefined"
        ? "unsupported"
        : "ready";
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setMicState(initial);
    if (initial !== "ready" || !navigator.permissions?.query) return;

    let result: PermissionStatus | null = null;
    const apply = (state: PermissionState) => {
      setMicState((prev) =>
        prev === "insecure" || prev === "unsupported"
          ? prev
          : state === "denied"
            ? "denied"
            : "ready",
      );
    };
    navigator.permissions
      .query({name: "microphone" as PermissionName})
      .then((res) => {
        result = res;
        apply(res.state);
        res.onchange = () => apply(res.state);
      })
      .catch(() => undefined);

    const onFocus = () => {
      if (result) apply(result.state);
    };
    window.addEventListener("focus", onFocus);
    return () => {
      window.removeEventListener("focus", onFocus);
      if (result) result.onchange = null;
    };
  }, []);

  async function start() {
    setPermError(null);
    if (typeof navigator === "undefined" || !navigator.mediaDevices?.getUserMedia) {
      setMicState("unsupported");
      return;
    }
    try {
      // Déclenche la demande d'autorisation du navigateur (1ʳᵉ fois).
      const stream = await navigator.mediaDevices.getUserMedia({audio: true});
      setMicState("ready");
      streamRef.current = stream;
      const mime = pickMime();
      const rec = mime ? new MediaRecorder(stream, {mimeType: mime}) : new MediaRecorder(stream);
      chunksRef.current = [];
      rec.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      rec.onstop = () => {
        const blob = new Blob(chunksRef.current, {type: rec.mimeType || "audio/webm"});
        blobRef.current = blob;
        streamRef.current?.getTracks().forEach((t) => t.stop());
        streamRef.current = null;
        if (submitOnStopRef.current) {
          // Examen : soumission immédiate (manuel ou auto-stop), pas de réécoute.
          submitOnStopRef.current = false;
          setPhase("recorded");
          onSubmit(blob, stopElapsedRef.current);
          return;
        }
        setAudioUrl((prev) => {
          if (prev) URL.revokeObjectURL(prev);
          return URL.createObjectURL(blob);
        });
        setPhase("recorded");
      };
      recorderRef.current = rec;
      rec.start();
      setElapsed(0);
      setPhase("recording");
      timerRef.current = setInterval(
        () =>
          setElapsed((e) => {
            const next = e + 1;
            // Examen : auto-stop quand la durée max est atteinte.
            if (examMode && task.dureeMaxSec != null && next >= task.dureeMaxSec) {
              stopExam(next);
            }
            return next;
          }),
        1000,
      );
    } catch (e) {
      const name = typeof e === "object" && e && "name" in e ? String((e as {name?: unknown}).name) : "";
      const message =
        typeof e === "object" && e && "message" in e
          ? String((e as {message?: unknown}).message)
          : "";
      if (name === "NotAllowedError" || name === "SecurityError") setMicState("denied");
      setPermError(micErrorMessage(name, message));
    }
  }

  function stop() {
    if (timerRef.current) clearInterval(timerRef.current);
    if (examMode) {
      stopExam(elapsed);
      return;
    }
    recorderRef.current?.stop();
  }

  /** Arrête l'enregistrement en mode examen → soumission immédiate dans `onstop`. */
  function stopExam(durationSec: number) {
    if (submitOnStopRef.current) return;
    if (timerRef.current) clearInterval(timerRef.current);
    submitOnStopRef.current = true;
    stopElapsedRef.current = durationSec;
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
  // En examen, le chrono décompte la durée restante (auto-stop à 0) ; sinon il
  // chronomètre simplement le temps écoulé.
  const examCountdown = examMode && max != null;
  const shownSec = examCountdown ? Math.max(0, max - elapsed) : elapsed;
  const examUrgent = examCountdown && phase === "recording" && shownSec <= 15;
  const timerClass = examCountdown
    ? phase === "recording"
      ? examUrgent
        ? styles.timerWarn
        : styles.timerOk
      : ""
    : phase === "idle"
      ? ""
      : inRange
        ? styles.timerOk
        : styles.timerWarn;
  const rangeLabel =
    min != null && max != null
      ? `${formatDurationSec(min)} – ${formatDurationSec(max)}`
      : max != null
        ? `≤ ${formatDurationSec(max)}`
        : "";

  // Seuls les cas réellement insolubles désactivent le bouton. "denied" reste
  // cliquable : getUserMedia est la source de vérité (il re-prompte ou réussit
  // si les réglages ont changé sans reload).
  const blocked = micState === "insecure" || micState === "unsupported";
  const blockMsg =
    micState === "insecure"
      ? "Le micro nécessite une connexion sécurisée (HTTPS) ou localhost. Ouvrez le site en https pour enregistrer."
      : micState === "unsupported"
        ? "Votre navigateur ne supporte pas l'enregistrement audio. Essayez Chrome ou Firefox à jour."
        : micState === "denied"
          ? "Le navigateur indique que le micro est bloqué pour ce site. Cliquez sur le micro pour réessayer — si rien ne se passe, autorisez-le via l'icône à gauche de l'adresse → Microphone."
          : null;

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

      <EoTranscriptNotice />

      <div className={styles.recorder}>
        <div className={`${styles.timerBig} ${timerClass}`}>{fmtTimer(shownSec)}</div>

        {phase === "recording" ? (
          <button type="button" className={`${styles.recordCircle} ${styles.recordCircleRec}`} onClick={stop}>
            <Square size={28} strokeWidth={2.2} fill="currentColor" />
          </button>
        ) : (
          <button
            type="button"
            className={styles.recordCircle}
            onClick={start}
            disabled={submitting || blocked || (examMode && phase === "recorded")}
            aria-label={phase === "recorded" ? "Réenregistrer" : "Démarrer l'enregistrement"}
          >
            <Mic size={32} strokeWidth={2} />
          </button>
        )}

        <p className={styles.recordHint}>
          {phase === "recording"
            ? examCountdown
              ? "Enregistrement en cours… arrêt automatique à 0:00, ou appuyez sur le carré pour soumettre."
              : "Enregistrement en cours… appuyez sur le carré pour arrêter."
            : phase === "recorded"
              ? examMode
                ? "Réponse envoyée à l'évaluation…"
                : "Réécoutez votre réponse, refaites-la ou envoyez-la à l'évaluation."
              : examCountdown
                ? `Appuyez sur le micro : vous avez ${rangeLabel || formatDurationSec(max ?? 0)} et votre réponse est soumise dès l'arrêt. La 1ʳᵉ fois, votre navigateur vous demandera l'accès au micro.`
                : `Appuyez sur le micro pour autoriser et enregistrer${
                    rangeLabel ? ` (durée conseillée ${rangeLabel})` : ""
                  }. La 1ʳᵉ fois, votre navigateur vous demandera l'accès au micro.`}
        </p>

        {!examMode && phase === "recorded" && audioUrl && (
          <div className={styles.player}>
            <audio src={audioUrl} controls preload="metadata" />
          </div>
        )}
      </div>

      {(blockMsg || permError || error) && (
        <div className={styles.error}>{blockMsg ?? permError ?? error}</div>
      )}

      {!examMode && phase === "recorded" && (
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
