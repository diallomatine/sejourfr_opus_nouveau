"use client";

import {useEffect, useMemo, useRef, useState, type ReactNode} from "react";
import {ArrowRight, Check, Clock, Lightbulb, Mic, RotateCcw, Square, Target} from "lucide-react";
import {formatDurationSec, type ProductionTaskDto} from "@/lib/types";
import {useScreenWakeLock} from "@/lib/use-screen-wake-lock";
import {SkillAccent} from "@/app/_components/skill-ui/SkillLayout";
import {
  PRODUCTION_EXAM_REDO,
  PRODUCTION_EXAM_REDO_NOTE,
  PRODUCTION_EXAM_RETRY,
  PRODUCTION_EXAM_REVIEW_TITLE,
  PRODUCTION_EXAM_SENDING,
  productionExamReviewHint,
} from "@/lib/production-exam-copy";
import s from "@/app/_components/skill-ui/skill.module.css";
import {type ProductionVoice} from "./config";
import {EoTranscriptNotice} from "./EoTranscriptNotice";
import {ProductionCriteriaCard} from "./ProductionCriteriaCard";
import {ProductionSplit} from "./ProductionExamRunner";
import {RecordingLevelMeter} from "./RecordingLevelMeter";
import styles from "./production.module.css";

/**
 * Chrome de l'enregistreur dans les deux voix. Seules figurent ici les phrases
 * réellement atteignables **hors** mode examen : le mode examen n'existe que
 * sur les écrans de production TCF, qui vouvoient — dupliquer ses phrases
 * n'aurait rien apporté qu'une occasion de les voir diverger.
 */
const COPY: Record<
  ProductionVoice,
  {
    micSystem: string;
    micDenied: string;
    micNotFound: string;
    micBusy: string;
    micDefault: string;
    blockInsecure: string;
    blockUnsupported: string;
    blockDenied: string;
    recording: string;
    recordingCapped: (cap: string) => string;
    recorded: string;
    idle: (range: string, cap: string) => string;
  }
> = {
  vouvoiement: {
    micSystem:
      "C'est votre système qui bloque le micro du navigateur (le site, lui, est autorisé). macOS : Réglages Système → Confidentialité et sécurité → Microphone → activez votre navigateur, puis quittez-le et relancez-le.",
    micDenied:
      "Accès au micro refusé. Autorisez-le via l'icône à gauche de l'adresse → Microphone, et vérifiez aussi que votre système autorise ce navigateur à utiliser le micro (macOS : Réglages Système → Confidentialité et sécurité → Microphone). Puis réessayez.",
    micNotFound: "Aucun microphone détecté. Branchez un micro puis réessayez.",
    micBusy:
      "Le micro est utilisé par une autre application (visioconférence, dictaphone…). Fermez-la puis réessayez.",
    micDefault:
      "Micro inaccessible. Autorisez le microphone dans votre navigateur, puis réessayez.",
    blockInsecure:
      "Le micro nécessite une connexion sécurisée (HTTPS) ou localhost. Ouvrez le site en https pour enregistrer.",
    blockUnsupported:
      "Votre navigateur ne supporte pas l'enregistrement audio. Essayez Chrome ou Firefox à jour.",
    blockDenied:
      "Le navigateur indique que le micro est bloqué pour ce site. Cliquez sur le micro pour réessayer — si rien ne se passe, autorisez-le via l'icône à gauche de l'adresse → Microphone.",
    recording: "Enregistrement en cours… appuyez sur le carré pour arrêter.",
    recordingCapped: (cap) =>
      `Enregistrement en cours… appuyez sur le carré pour arrêter (arrêt automatique à ${cap}).`,
    recorded: "Réécoutez votre réponse, refaites-la ou envoyez-la à l'évaluation.",
    idle: (range, cap) =>
      `Appuyez sur le micro pour autoriser et enregistrer${range}${cap}. La 1ʳᵉ fois, votre navigateur vous demandera l'accès au micro.`,
  },
  tutoiement: {
    micSystem:
      "C'est ton système qui bloque le micro du navigateur (le site, lui, est autorisé). macOS : Réglages Système → Confidentialité et sécurité → Microphone → active ton navigateur, puis quitte-le et relance-le.",
    micDenied:
      "Accès au micro refusé. Autorise-le via l'icône à gauche de l'adresse → Microphone, et vérifie aussi que ton système autorise ce navigateur à utiliser le micro (macOS : Réglages Système → Confidentialité et sécurité → Microphone). Puis réessaie.",
    micNotFound: "Aucun microphone détecté. Branche un micro puis réessaie.",
    micBusy:
      "Le micro est utilisé par une autre application (visioconférence, dictaphone…). Ferme-la puis réessaie.",
    micDefault: "Micro inaccessible. Autorise le microphone dans ton navigateur, puis réessaie.",
    blockInsecure:
      "Le micro nécessite une connexion sécurisée (HTTPS) ou localhost. Ouvre le site en https pour enregistrer.",
    blockUnsupported:
      "Ton navigateur ne supporte pas l'enregistrement audio. Essaie Chrome ou Firefox à jour.",
    blockDenied:
      "Le navigateur indique que le micro est bloqué pour ce site. Clique sur le micro pour réessayer — si rien ne se passe, autorise-le via l'icône à gauche de l'adresse → Microphone.",
    recording: "Enregistrement en cours… appuie sur le carré pour arrêter.",
    recordingCapped: (cap) =>
      `Enregistrement en cours… appuie sur le carré pour arrêter (arrêt automatique à ${cap}).`,
    recorded: "Réécoute ta réponse, refais-la ou envoie-la à l'évaluation.",
    idle: (range, cap) =>
      `Appuie sur le micro pour autoriser et enregistrer${range}${cap}. La 1ʳᵉ fois, ton navigateur te demandera l'accès au micro.`,
  },
};

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

/**
 * Intervalle entre deux repères de temps annoncés aux lecteurs d'écran, en
 * secondes.
 *
 * L'état d'enregistrement doit être **dit**, pas seulement montré — mais un
 * chrono branché sur une région `aria-live` se fait relire **à chaque seconde**,
 * et couvre alors la voix du candidat pendant qu'il produit : le contraire du
 * service rendu. On annonce donc l'entrée en enregistrement, puis un repère
 * toutes les 30 s, puis la fin.
 */
const ANNOUNCE_EVERY_SEC = 30;

/**
 * Pendant oral d'`AnswerCard` : la zone de production en carte (icône + titre,
 * suggestion de démarrage, enregistreur, pied astuce / durée). L'écran d'un
 * petit sujet est **structuré à l'identique** à l'écrit et à l'oral — seule la
 * zone de production change, ici l'enregistreur au lieu du champ de saisie.
 */
export interface RecorderCard {
  title: string;
  icon?: ReactNode;
  /** Amorce du sujet, proposée comme **suggestion de démarrage** (l'oral n'a
   *  pas de texte grisé). Absente = aucune suggestion, pas de bloc vide. */
  starter?: string | null;
  /** Rappel du geste souvent oublié. Absent = seule la durée s'affiche. */
  tip?: string | null;
}

/** Message précis selon le type d'échec de `getUserMedia`. */
function micErrorMessage(name: string, message: string, voice: ProductionVoice): string {
  const copy = COPY[voice];
  // Chrome précise "Permission denied by system" quand c'est l'OS (et non le
  // site) qui bloque le navigateur — cas typique : site sur Autoriser mais
  // macOS n'a pas donné le micro à Chrome.
  if (/system/i.test(message)) return copy.micSystem;
  switch (name) {
    case "NotAllowedError":
    case "SecurityError":
      return copy.micDenied;
    case "NotFoundError":
    case "DevicesNotFoundError":
      return copy.micNotFound;
    case "NotReadableError":
    case "TrackStartError":
      return copy.micBusy;
    default:
      return copy.micDefault;
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
  sendError = null,
  submitLabel = "Soumettre à l'évaluation",
  consigneLabel,
  exerciseTitle,
  headerSlot,
  promptSlot,
  criteriaSlot,
  answerCard,
  footerSlot,
  footerAlwaysVisible = false,
  maxDurationSec,
  voice = "vouvoiement",
  examMode = false,
  split = false,
  timeoutSignal = 0,
  onTimeout,
  onModeChoice,
  onSubmit,
}: {
  task: ProductionTaskDto;
  submitting: boolean;
  error?: string | null;
  /** Échec de l'ENVOI de la prise (examen) : le bouton principal devient
   *  « Réessayer » et renvoie la même prise, restée sur l'appareil. */
  sendError?: string | null;
  submitLabel?: string;
  /** Remplace « Tâche N » sur le badge de contrainte (micro-exercices :
   *  « Petit sujet · 2/3 »). */
  consigneLabel?: string;
  /** Titre d'intention affiché **dans** la carte d'exercice, au-dessus de la
   *  consigne. Absent par défaut : les micro-exercices portent déjà le leur
   *  dans `headerSlot`. */
  exerciseTitle?: ReactNode;
  /** Inséré tout en haut, **avant** la carte de consigne : intention de
   *  l'exercice et critère travaillé. Rien par défaut. */
  headerSlot?: ReactNode;
  /** Remplace **entièrement** la carte d'exercice (badge, palier, consigne,
   *  situation, chips de format). Absent = carte historique. Même prop, même
   *  contenu qu'à l'écrit : le guidage d'un petit sujet. */
  promptSlot?: ReactNode;
  /** Remplace la carte de nos 4 critères. `null` la retire — les
   *  micro-exercices « Compétences » n'évaluent QU'UN critère et affichent le
   *  leur ici, juste au-dessus de l'enregistreur. */
  criteriaSlot?: ReactNode;
  /** Présente l'enregistreur en carte (icône + titre, suggestion de démarrage,
   *  pied astuce / durée). Absent = panneau d'enregistrement historique. */
  answerCard?: RecorderCard;
  /** Inséré juste au-dessus des boutons Refaire / Envoyer, donc visible une fois
   *  la prise enregistrée (auto-évaluation, options de soumission). */
  footerSlot?: ReactNode;
  /** Rend `footerSlot` **dès l'ouverture de l'écran**, et non plus seulement
   *  après l'arrêt de l'enregistrement.
   *
   *  Ce qu'il porte dans le module « Compétences » — l'auto-évaluation, la
   *  bascule « Analyser ma réponse avec l'IA » et le rappel « les références
   *  n'apparaissent qu'après ta production » — est une **décision à prendre
   *  avant de parler** : arrivée après coup, le candidat avait déjà consommé
   *  une de ses analyses offertes sans le savoir. Faux par défaut : les écrans
   *  de production TCF gardent leur pied d'après-prise. */
  footerAlwaysVisible?: boolean;
  /** Plafond **dur** de capture, en secondes, hors mode examen : la prise
   *  s'arrête d'elle-même et la durée transmise est bornée à cette valeur.
   *
   *  C'est le reflet d'un garde **serveur** (`sejourfr.competences.analysis`),
   *  pas un réglage d'affichage : sans lui, un enregistrement de cinq minutes
   *  partait puis était refusé, production perdue. À ne pas confondre avec
   *  `task.dureeMaxSec`, qui reste la durée **conseillée** (indicative) et
   *  pilote seule le décompte du mode examen. Absent = aucune borne, le
   *  comportement historique. */
  maxDurationSec?: number | null;
  /** Voix du chrome de l'enregistreur. Vouvoiement par défaut ; le module
   *  « Compétences » tutoie. Ne touche jamais au texte du sujet. */
  voice?: ProductionVoice;
  /** En examen blanc : décompte par tâche (dureeMaxSec) lancé par « Je suis
   *  prêt », auto-stop à 0, puis **revue** : réécoute locale, « Recommencer »
   *  (nouvelle prise, décompte remis en entier) ou envoi par le bouton
   *  principal. Rien ne part tant que le candidat n'a pas appuyé dessus. */
  examMode?: boolean;
  /** Consigne à gauche, enregistreur à droite au palier desktop
   *  (`ProductionSplit`). Une colonne en dessous, comme l'app. */
  split?: boolean;
  /** Incrémenté par le parent quand le chrono de l'épreuve tombe à 0:00 :
   *  coupe la capture en cours et remonte l'audio via `onTimeout`. */
  timeoutSignal?: number;
  /** Reçoit l'audio capturé jusqu'à l'expiration (null si rien n'était
   *  enregistré) et le numéro de sa prise. Au parent de le soumettre en
   *  best-effort puis de finaliser. */
  onTimeout?: (audio: Blob | null, take: number) => void;
  /** EO T1/T2 : appelé au 1ᵉʳ tap « démarrer » (une fois le sujet lu) pour
   *  choisir le mode — examinateur temps réel vs enregistrement seul. « classic »
   *  → on enregistre ici ; « realtime »/« cancel » → le parent prend la main
   *  (navigation vers l'échange, ou retour). Absent = enregistrement direct. */
  onModeChoice?: () => Promise<"classic" | "realtime" | "cancel">;
  /** `take` numérote la prise (1, 2… à chaque « Recommencer ») : c'est ce qui
   *  distingue deux PRODUCTIONS d'une même tâche, donc leur clé d'idempotence.
   *  Renvoyer la même prise après un échec rend le même numéro. */
  onSubmit: (audio: Blob, durationSec: number, take: number) => void;
}) {
  const [phase, setPhase] = useState<"idle" | "recording" | "recorded">("idle");
  // Une fois « seul » choisi, les taps suivants (réenregistrer) démarrent
  // directement sans reproposer le mode.
  const [classicLocked, setClassicLocked] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [permError, setPermError] = useState<string | null>(null);
  // Le flux micro en cours, exposé en état (et pas seulement en ref) parce que
  // c'est lui qui alimente le retour visuel : un `ref` ne déclencherait pas le
  // montage du compteur de niveau.
  const [micStream, setMicStream] = useState<MediaStream | null>(null);
  // Réécoute en cours dans le lecteur inline : l'écran doit rester allumé le
  // temps de l'écoute, pas pendant toute la phase « enregistré » (le candidat
  // peut y rester longtemps avant d'envoyer).
  const [replaying, setReplaying] = useState(false);
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
  // Numéro de la prise en cours : +1 à chaque démarrage. Une prise = une
  // production = une clé d'idempotence côté parent.
  const takeRef = useRef(0);
  // Garde d'un arrêt déjà demandé (bouton ET décompte peuvent tomber ensemble).
  const stoppingRef = useRef(false);
  // En examen, l'arrêt venu du décompte (et non du candidat) se dit à la revue.
  const [timeUp, setTimeUp] = useState(false);
  // Expiration du chrono d'épreuve : l'audio remonte à `onTimeout`, pas à
  // `onSubmit` (le parent finalise l'épreuve au lieu d'enchaîner la tâche).
  const timeoutOnStopRef = useRef(false);
  const lastTimeoutSignalRef = useRef(0);

  const copy = COPY[voice];

  // Une prise de parole de 2-3 min sans toucher l'écran, c'est exactement le
  // scénario où le téléphone se verrouille — et sur mobile un écran verrouillé
  // coupe la capture `MediaRecorder`. Dégradation silencieuse si l'API manque.
  useScreenWakeLock(phase === "recording" || replaying);

  // Plafond dur de capture : hors examen seulement (en examen, c'est
  // `task.dureeMaxSec` qui borne déjà la prise et déclenche la soumission).
  const hardCapSec = !examMode && maxDurationSec != null && maxDurationSec > 0 ? maxDurationSec : null;

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
      // En revue, la prise enregistrée part quand même : le temps a expiré
      // pendant que le candidat la réécoutait.
      onTimeout?.(phase === "recorded" ? blobRef.current : null, takeRef.current);
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
      setMicStream(stream);
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
        // Libère l'`AudioContext` du compteur de niveau : sans ça on en fuirait
        // un par enregistrement.
        setMicStream(null);
        stoppingRef.current = false;
        if (timeoutOnStopRef.current) {
          timeoutOnStopRef.current = false;
          setPhase("recorded");
          onTimeout?.(blob, takeRef.current);
          return;
        }
        // Examen comme entraînement : l'arrêt ouvre la REVUE. La réécoute lit
        // le Blob resté en mémoire (URL locale), rien n'est envoyé pour elle.
        setAudioUrl((prev) => {
          if (prev) URL.revokeObjectURL(prev);
          return URL.createObjectURL(blob);
        });
        setPhase("recorded");
      };
      recorderRef.current = rec;
      rec.start();
      takeRef.current += 1;
      stoppingRef.current = false;
      setTimeUp(false);
      setElapsed(0);
      // Le lecteur de réécoute est démonté par le passage en « recording » :
      // son `onPause` ne partira pas, on remet le drapeau à plat nous-mêmes.
      setReplaying(false);
      setPhase("recording");
      timerRef.current = setInterval(
        () =>
          setElapsed((e) => {
            const next = e + 1;
            // Examen : auto-stop quand la durée max est atteinte.
            if (examMode && task.dureeMaxSec != null && next >= task.dureeMaxSec) {
              setTimeUp(true);
              stopCapture();
            } else if (hardCapSec != null && next >= hardCapSec) {
              // Hors examen : plafond dur du serveur. On coupe la capture au
              // lieu d'envoyer un fichier qui sera refusé — le candidat garde
              // ce qu'il a dit et peut le réécouter avant d'envoyer.
              stopAtHardCap();
            }
            return Math.min(next, hardCapSec ?? next);
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
      setPermError(micErrorMessage(name, message, voice));
    }
  }

  function stop() {
    stopCapture();
  }

  /** Arrête la capture une seule fois : `onstop` ouvre ensuite la revue. */
  function stopCapture() {
    if (stoppingRef.current) return;
    stoppingRef.current = true;
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (recorderRef.current?.state === "recording") recorderRef.current.stop();
    else stoppingRef.current = false;
  }

  /** Arrête la capture au plafond dur (hors examen) : chemin d'arrêt normal —
   *  le candidat retrouve sa prise, la réécoute, la refait ou l'envoie. */
  function stopAtHardCap() {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (recorderRef.current?.state === "recording") recorderRef.current.stop();
  }

  function redo() {
    setAudioUrl((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return null;
    });
    blobRef.current = null;
    setElapsed(0);
    setReplaying(false);
    setTimeUp(false);
    setPhase("idle");
  }

  const min = task.dureeMinSec;
  const max = task.dureeMaxSec;
  const inRange = (min == null || elapsed >= min) && (max == null || elapsed <= max);
  // En examen, le chrono décompte la durée restante (auto-stop à 0) ; sinon il
  // chronomètre simplement le temps écoulé.
  const examCountdown = examMode && max != null;
  /** Consigne d'examen encore à lire : rien n'est lancé, donc rien n'est
   *  chronométré — c'est le « Je suis prêt » qui met le temps en marche, comme
   *  au vrai TCF. */
  const examIdle = examMode && phase === "idle";
  /** Revue d'une prise d'examen : ni micro ni décompte, la prise se réécoute,
   *  se recommence ou part par le bouton principal. */
  const examReview = examMode && phase === "recorded";
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
      ? copy.blockInsecure
      : micState === "unsupported"
        ? copy.blockUnsupported
        : micState === "denied"
          ? copy.blockDenied
          : null;

  // Palier d'annonce : ne change qu'au franchissement d'un multiple de 30 s, si
  // bien que la région vivante ci-dessous n'est relue qu'à ce moment-là. C'est
  // ce qui permet d'annoncer l'état SANS réciter le chrono par-dessus la voix du
  // candidat.
  const announceStep = phase === "recording" ? Math.floor(elapsed / ANNOUNCE_EVERY_SEC) : 0;
  const recordingAnnouncement = useMemo(() => {
    if (phase === "idle") return "";
    if (phase === "recorded") return "Enregistrement terminé.";
    const spent = announceStep * ANNOUNCE_EVERY_SEC;
    if (spent <= 0) return "Enregistrement en cours.";
    if (examCountdown) {
      const left = Math.max(0, (max ?? 0) - spent);
      return left > 0
        ? `Enregistrement en cours, il reste ${formatDurationSec(left)}.`
        : "Enregistrement en cours.";
    }
    return `Enregistrement en cours depuis ${formatDurationSec(spent)}.`;
  }, [phase, announceStep, examCountdown, max]);

  // Corps de l'enregistreur, partagé par les deux présentations (panneau
  // historique et carte de réponse) : le dupliquer serait la garantie de voir
  // un correctif n'atterrir que d'un côté.
  const recorder = (
    <div className={styles.recorder}>
      {/* En examen, la consigne se lit SANS aucun décompte : le chrono de la
          tâche n'existe pas encore, il naît du « Je suis prêt ». Afficher
          « 3:00 » figé donnait déjà l'impression d'être chronométré. */}
      {examReview ? (
        <div className={styles.reviewHead}>
          <span className={styles.reviewCheck} aria-hidden>
            <Check size={26} strokeWidth={2.6} />
          </span>
          <p className={styles.reviewTitle}>{PRODUCTION_EXAM_REVIEW_TITLE}</p>
          <p className={styles.reviewDuration}>Durée enregistrée · {fmtTimer(elapsed)}</p>
        </div>
      ) : !examIdle &&
        (phase === "recording" ? (
          /* Ce qu'un candidat stressé doit pouvoir constater d'un coup d'œil :
             un MICRO — il avait disparu de l'écran le jour où le bouton est
             devenu un carré d'arrêt — et des chiffres qui BATTENT. Le battement
             est remonté par React à chaque seconde : si le rendu se fige, il
             s'arrête avec les chiffres, alors qu'une pulsation purement CSS
             continuerait de tourner et ne prouverait rien. */
          <div className={styles.timerLive}>
            <Mic className={styles.timerMic} size={26} strokeWidth={2.3} aria-hidden />
            <span
              key={shownSec}
              className={`${styles.timerBig} ${styles.timerBeat} ${timerClass}`}
            >
              {fmtTimer(shownSec)}
            </span>
          </div>
        ) : (
          <div className={`${styles.timerBig} ${timerClass}`}>{fmtTimer(shownSec)}</div>
        ))}

      {/* L'état de la capture est ANNONCÉ, pas seulement montré. Une seule
          région vivante dans tout l'enregistreur — la pastille rouge et la
          forme d'onde sont purement visuelles — et elle ne parle qu'aux
          changements d'état, plus un repère toutes les 30 s. */}
      <p className={styles.srOnly} role="status" aria-live="polite">
        {recordingAnnouncement}
      </p>

      {phase === "recording" ? (
        <button
          type="button"
          className={`${styles.recordCircle} ${styles.recordCircleRec}`}
          onClick={stop}
          aria-label="Arrêter l'enregistrement"
        >
          <Square size={28} strokeWidth={2.2} fill="currentColor" />
        </button>
      ) : examReview ? null : examIdle ? (
        <button
          type="button"
          className={styles.readyBtn}
          onClick={handleStartClick}
          disabled={submitting || blocked}
        >
          <Mic size={18} strokeWidth={2.2} aria-hidden />
          Je suis prêt · Commencer la tâche
        </button>
      ) : (
        <button
          type="button"
          className={styles.recordCircle}
          onClick={handleStartClick}
          disabled={submitting || blocked}
          aria-label={phase === "recorded" ? "Réenregistrer" : "Démarrer l'enregistrement"}
        >
          <Mic size={32} strokeWidth={2} />
        </button>
      )}

      {/* Ce qui prouve que la voix est captée : sans lui, un micro muet est
          indiscernable d'un enregistrement qui marche, et le candidat ne
          l'apprend qu'après l'analyse. */}
      {phase === "recording" && <RecordingLevelMeter stream={micStream} />}

      <p className={styles.recordHint}>
        {phase === "recording"
          ? examCountdown
            ? "Enregistrement en cours… arrêt automatique à 0:00, ou appuyez sur le carré pour arrêter."
            : hardCapSec != null
              ? copy.recordingCapped(fmtTimer(hardCapSec))
              : copy.recording
          : phase === "recorded"
            ? examMode
              ? productionExamReviewHint(timeUp)
              : copy.recorded
            : examCountdown
              ? `Prenez le temps de lire la consigne : rien n'est chronométré tant que vous n'avez pas commencé. Le temps de parole (${formatDurationSec(max ?? 0)}) démarre quand vous lancez la tâche. À l'arrêt, vous pourrez réécouter votre réponse avant de l'envoyer. La 1ʳᵉ fois, votre navigateur vous demandera l'accès au micro.`
              : copy.idle(
                  rangeLabel ? ` (durée conseillée ${rangeLabel})` : "",
                  hardCapSec != null ? `, ${formatDurationSec(hardCapSec)} maximum` : "",
                )}
      </p>

      {phase === "recorded" && audioUrl && (
        <div className={styles.player}>
          <audio
            src={audioUrl}
            controls
            preload="metadata"
            onPlay={() => setReplaying(true)}
            onPause={() => setReplaying(false)}
            onEnded={() => setReplaying(false)}
          />
        </div>
      )}
    </div>
  );

  // Pendant du compteur de mots : ce qui a été dit, sur ce qui est visé. Il
  // prend les teintes du compteur de l'écrit (`counterWarn` = ambre LISIBLE),
  // pas celles du gros chrono, qui sont calibrées pour du texte de 34 px.
  const durationText = max != null ? `${fmtTimer(elapsed)} / ${fmtTimer(max)}` : fmtTimer(elapsed);
  const durationClass = phase === "idle" ? "" : inRange ? s.counterOk : s.counterWarn;

  return (
    <SkillAccent>
      <ProductionSplit
        split={split}
        aside={
          <>
            {headerSlot}

            {/* Même carte d'exercice qu'à l'écrit : le parcours est identique en EE
                et en EO, seules la zone de production et la couleur d'accent
                changent. */}
            {promptSlot === undefined ? (
              <section className={s.exercise}>
                <div className={s.exerciseTop}>
                  <span className={s.criterionTag}>
                    <Target size={12} strokeWidth={2.4} aria-hidden />
                    {consigneLabel ?? `Tâche ${task.tacheNumero}`}
                  </span>
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
            ) : (
              promptSlot
            )}
          </>
        }
      >
        {criteriaSlot === undefined ? <ProductionCriteriaCard /> : criteriaSlot}

        {/* En carte, l'avertissement passe SOUS l'enregistreur : il reste dit, il
          ne repousse plus le micro sous la ligne de flottaison. */}
        {!answerCard && <EoTranscriptNotice voice={voice} />}

        {answerCard ? (
          <section className={s.answerCard}>
            <div className={s.answerHead}>
              {answerCard.icon && (
                <span className={s.answerIcon} aria-hidden>
                  {answerCard.icon}
                </span>
              )}
              <h2 className={s.answerTitle}>{answerCard.title}</h2>
            </div>
            {answerCard.starter && (
              <p className={s.starter}>Pour démarrer : « {answerCard.starter} »</p>
            )}
            {recorder}
            <div className={s.answerFoot}>
              {answerCard.tip ? (
                <span className={s.answerTip}>
                  <Lightbulb size={13} strokeWidth={2.2} aria-hidden />
                  Astuce : {answerCard.tip}
                </span>
              ) : (
                <span />
              )}
              {/* Purement visuel : branché en `aria-live`, ce compteur se faisait
                relire À CHAQUE SECONDE pendant que le candidat parlait. L'état
                de la capture est annoncé une seule fois, dans l'enregistreur. */}
              <span className={`${s.answerCount} ${durationClass}`}>{durationText}</span>
            </div>
          </section>
        ) : (
          <div className={`${s.card} ${s.panel}`}>{recorder}</div>
        )}

        {answerCard && <EoTranscriptNotice voice={voice} />}

        {(blockMsg || permError || sendError || error) && (
          <div className={s.error} role="alert">
            {blockMsg ?? permError ?? sendError ?? error}
          </div>
        )}

        {/* Ce que porte ce pied — auto-évaluation, option d'analyse IA, rappel
          sur les références — se décide AVANT de parler : c'est pour ça qu'il
          peut être rendu dès l'ouverture de l'écran. */}
        {!examMode && (footerAlwaysVisible || phase === "recorded") && footerSlot}

        {/* EN EXAMEN, la revue : le bouton principal ENVOIE (et dit l'envoi en
          cours — c'est le silence de cet instant qui figeait l'écran),
          « Recommencer » jette la prise locale. Après un échec, la MÊME prise
          se renvoie (même numéro, donc même clé d'idempotence). */}
        {examReview && (
          <>
            <div className={s.actionRow}>
              <button
                type="button"
                className={s.primary}
                disabled={submitting}
                aria-busy={submitting}
                onClick={() =>
                  blobRef.current && onSubmit(blobRef.current, elapsed, takeRef.current)
                }
              >
                {submitting ? (
                  <>
                    <span className={styles.btnSpinner} aria-hidden />
                    {PRODUCTION_EXAM_SENDING}
                  </>
                ) : (
                  <>
                    {sendError ? PRODUCTION_EXAM_RETRY : submitLabel}
                    <ArrowRight size={16} strokeWidth={2.4} style={{marginLeft: 6}} aria-hidden />
                  </>
                )}
              </button>
              <button type="button" className={s.secondary} disabled={submitting} onClick={redo}>
                <RotateCcw size={15} strokeWidth={2.2} style={{marginRight: 6}} aria-hidden />
                {PRODUCTION_EXAM_REDO}
              </button>
            </div>
            <p className={styles.reviewNote}>{PRODUCTION_EXAM_REDO_NOTE}</p>
          </>
        )}

        {!examMode && phase === "recorded" && (
          <div className={s.actionRow}>
            <button
              type="button"
              className={s.primary}
              disabled={submitting}
              onClick={() =>
                blobRef.current &&
                onSubmit(blobRef.current, Math.min(elapsed, hardCapSec ?? elapsed), takeRef.current)
              }
            >
              {submitting ? "Envoi en cours…" : submitLabel}
            </button>
            <button type="button" className={s.secondary} disabled={submitting} onClick={redo}>
              <RotateCcw size={15} strokeWidth={2.2} style={{marginRight: 6}} aria-hidden />
              Refaire
            </button>
          </div>
        )}
      </ProductionSplit>
    </SkillAccent>
  );
}
