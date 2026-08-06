"use client";

import {useEffect, useRef, useState, type ReactNode} from "react";
import {Clock, Mic, RotateCcw, Square, Target} from "lucide-react";
import {formatDurationSec, type ProductionTaskDto} from "@/lib/types";
import {SkillAccent} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {EoTranscriptNotice} from "./EoTranscriptNotice";
import {ProductionCriteriaCard} from "./ProductionCriteriaCard";
import styles from "./production.module.css";

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
  consigneLabel,
  exerciseTitle,
  headerSlot,
  criteriaSlot,
  footerSlot,
  examMode = false,
  timeoutSignal = 0,
  onTimeout,
  onModeChoice,
  onSubmit,
}: {
  task: ProductionTaskDto;
  submitting: boolean;
  error?: string | null;
  submitLabel?: string;
  /** Remplace « Tâche N » sur le badge de contrainte (micro-exercices :
   *  « Petit sujet · 2/5 »). */
  consigneLabel?: string;
  /** Titre d'intention affiché **dans** la carte d'exercice, au-dessus de la
   *  consigne. Absent par défaut : les micro-exercices portent déjà le leur
   *  dans `headerSlot`. */
  exerciseTitle?: ReactNode;
  /** Inséré tout en haut, **avant** la carte de consigne : intention de
   *  l'exercice et critère travaillé. Rien par défaut. */
  headerSlot?: ReactNode;
  /** Remplace la carte des 4 critères du TCF. `null` la retire — les
   *  micro-exercices « Compétences » n'évaluent QU'UN critère et affichent le
   *  leur ici, juste au-dessus de l'enregistreur. */
  criteriaSlot?: ReactNode;
  /** Inséré juste au-dessus des boutons Refaire / Envoyer, donc visible une fois
   *  la prise enregistrée (auto-évaluation, options de soumission). */
  footerSlot?: ReactNode;
  /** En examen blanc : décompte par tâche (dureeMaxSec), auto-stop à 0 et
   *  soumission immédiate au stop (manuel ou auto) — pas d'étape de réécoute. */
  examMode?: boolean;
  /** Incrémenté par le parent quand le chrono de l'épreuve tombe à 0:00 :
   *  coupe la capture en cours et remonte l'audio via `onTimeout`. */
  timeoutSignal?: number;
  /** Reçoit l'audio capturé jusqu'à l'expiration (null si rien n'était en
   *  cours). Au parent de le soumettre en best-effort puis de finaliser. */
  onTimeout?: (audio: Blob | null) => void;
  /** EO T1/T2 : appelé au 1ᵉʳ tap « démarrer » (une fois le sujet lu) pour
   *  choisir le mode — examinateur temps réel vs enregistrement seul. « classic »
   *  → on enregistre ici ; « realtime »/« cancel » → le parent prend la main
   *  (navigation vers l'échange, ou retour). Absent = enregistrement direct. */
  onModeChoice?: () => Promise<"classic" | "realtime" | "cancel">;
  onSubmit: (audio: Blob, durationSec: number) => void;
}) {
  const [phase, setPhase] = useState<"idle" | "recording" | "recorded">("idle");
  // Une fois « seul » choisi, les taps suivants (réenregistrer) démarrent
  // directement sans reproposer le mode.
  const [classicLocked, setClassicLocked] = useState(false);
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
  // Expiration du chrono d'épreuve : l'audio remonte à `onTimeout`, pas à
  // `onSubmit` (le parent finalise l'épreuve au lieu d'enchaîner la tâche).
  const timeoutOnStopRef = useRef(false);
  const lastTimeoutSignalRef = useRef(0);

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

  // Chrono d'épreuve à 0:00 : on coupe la capture en cours (l'audio déjà
  // enregistré part quand même en évaluation) et on rend la main au parent.
  useEffect(() => {
    if (timeoutSignal <= 0 || timeoutSignal === lastTimeoutSignalRef.current) return;
    lastTimeoutSignalRef.current = timeoutSignal;
    if (phase !== "recording") {
      onTimeout?.(null);
      return;
    }
    if (timerRef.current) clearInterval(timerRef.current);
    timeoutOnStopRef.current = true;
    recorderRef.current?.stop();
  }, [timeoutSignal, phase, onTimeout]);

  /** Tap sur le bouton micro. Pour EO T1/T2 (`onModeChoice` fourni), on propose
   *  d'abord le mode maintenant que le sujet a été lu ; « seul » → capture ici,
   *  « temps réel »/annulé → le parent gère. Sinon capture directe. */
  async function handleStartClick() {
    if (onModeChoice && !classicLocked) {
      const choice = await onModeChoice();
      if (choice !== "classic") return;
      setClassicLocked(true);
    }
    await start();
  }

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
        if (timeoutOnStopRef.current) {
          timeoutOnStopRef.current = false;
          setPhase("recorded");
          onTimeout?.(blob);
          return;
        }
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
    <SkillAccent accent="red">
      {headerSlot}

      {/* Même carte d'exercice qu'à l'écrit : le parcours est identique en EE
          et en EO, seules la zone de production et la couleur d'accent
          changent. */}
      <section className={s.exercise}>
        <div className={s.exerciseTop}>
          <span className={s.criterionTag}>
            <Target size={12} strokeWidth={2.4} aria-hidden />
            {consigneLabel ?? `Tâche ${task.tacheNumero}`}
          </span>
          <span className={s.stepTag}>Niveau {task.niveauCible}</span>
        </div>

        {exerciseTitle && <h2 className={s.exerciseTitle}>{exerciseTitle}</h2>}
        <p className={s.exerciseIntro}>{task.consigne}</p>

        {task.contexte && (
          <div className={s.context}>
            <span className={s.contextLabel}>Situation</span>
            {task.contexte}
          </div>
        )}

        {rangeLabel && (
          <div className={s.requirements}>
            <span className={s.requirement}>
              <Clock size={11} strokeWidth={2.4} aria-hidden />
              {rangeLabel}
            </span>
          </div>
        )}
      </section>

      {criteriaSlot === undefined ? <ProductionCriteriaCard /> : criteriaSlot}

      <EoTranscriptNotice />

      <div className={`${s.card} ${s.panel}`}>
        <div className={styles.recorder}>
          <div className={`${styles.timerBig} ${timerClass}`}>{fmtTimer(shownSec)}</div>

          {phase === "recording" ? (
            <button
              type="button"
              className={`${styles.recordCircle} ${styles.recordCircleRec}`}
              onClick={stop}
              aria-label="Arrêter l'enregistrement"
            >
              <Square size={28} strokeWidth={2.2} fill="currentColor" />
            </button>
          ) : (
            <button
              type="button"
              className={styles.recordCircle}
              onClick={handleStartClick}
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
      </div>

      {(blockMsg || permError || error) && (
        <div className={s.error}>{blockMsg ?? permError ?? error}</div>
      )}

      {!examMode && phase === "recorded" && footerSlot}

      {!examMode && phase === "recorded" && (
        <div className={s.actionRow}>
          <button
            type="button"
            className={s.primary}
            disabled={submitting}
            onClick={() => blobRef.current && onSubmit(blobRef.current, elapsed)}
          >
            {submitting ? "Envoi en cours…" : submitLabel}
          </button>
          <button type="button" className={s.secondary} disabled={submitting} onClick={redo}>
            <RotateCcw size={15} strokeWidth={2.2} style={{marginRight: 6}} aria-hidden />
            Refaire
          </button>
        </div>
      )}
    </SkillAccent>
  );
}
