"use client";

import {useCallback, useEffect, useRef, useState} from "react";
import {ChevronDown, Mic, MessagesSquare, Square, Volume2, WifiOff, X} from "lucide-react";
import {ApiException, realtimeApi} from "@/lib/api";
import {GeminiLiveSession, type GeminiLiveState} from "@/lib/realtime/geminiLive";
import {
    needsRealtimeAcknowledgement,
    realtimeFinishNotice,
    resolveRealtimeFinish,
    RT_FINISH_GIVE_UP_ACTION,
    RT_FINISH_RETRY_ACTION,
    RT_FINISH_SEE_RESULT_ACTION,
    RT_RESUME_FAILED_MESSAGE,
    RT_RESUME_HINT,
    RT_RESUME_MESSAGE,
    RT_RESUME_STATUS,
    RT_RESUME_TITLE,
    type RealtimeFinishResult,
} from "@/lib/realtime-finish";
import type {ProductionTaskDto, RealtimeSessionDescriptor, RealtimeSpeaker} from "@/lib/types";
import {useScreenWakeLock} from "@/lib/use-screen-wake-lock";
import {TranscriptDialogue} from "./TranscriptDialogue";

/**
 * Clôture après le temps écoulé. On ne coupe plus l'examinateur au bout d'un
 * délai fixe : à 0:00 on lui signale la fin (il prononce sa phrase de clôture),
 * puis on clôture DÈS QU'IL REDEVIENT SILENCIEUX (`CLOSE_SETTLE_MS` de repos
 * après avoir parlé) — pas de silence mort ni de coupure en plein milieu. Le
 * plafond `CLOSE_CAP_SEC` borne le cas où il divague ou ne conclut jamais.
 */
const CLOSE_SETTLE_MS = 1200;
const CLOSE_CAP_SEC = 12;

/**
 * Période de relais du transcript vers le backend. Valeur commune web ⇄ mobile
 * (le mobile relayait toutes les 1500 ms, deux cadences pour un même artefact
 * de notation).
 */
const TRANSCRIPT_RELAY_MS = 1200;

/**
 * Repli de DERNIER RECOURS quand le backend n'envoie pas `targetDurationSec`.
 * La valeur canonique est `production_tasks.duree_max_sec`, servie sur le
 * descripteur — elle vaut 180 s (EO tâche 1) et 210 s (EO tâche 2), les deux
 * seules tâches ouvertes au temps réel. On prend la plus COURTE : un repli ne
 * doit jamais accorder plus de temps que la tâche réelle. Valeur commune
 * web ⇄ mobile (le mobile repliait sur 200 s, le web sur 210 s).
 */
const DEFAULT_TARGET_SEC = 180;

/**
 * Essais d'envoi d'un MÊME fragment de transcript. Le tour garde son
 * `turnIndex` d'un essai à l'autre, donc le serveur ignore un doublon : le
 * renvoi ne peut plus fabriquer de parole, ce qui l'interdisait avant.
 */
const TRANSCRIPT_MAX_ATTEMPTS = 3;

/**
 * Attente entre deux essais d'un fragment (ms) : assez pour laisser passer une
 * micro-coupure, assez court pour ne pas retarder la clôture, qui attend la
 * chaîne d'envoi.
 */
const TRANSCRIPT_RETRY_DELAY_MS = 600;

/**
 * Tentatives de reprise pour UNE coupure : 3 essais espacés couvrent un tunnel
 * court ou une bascule wifi→4G sans transformer une panne durable en boucle de
 * reconnexion infinie.
 */
const RESUME_MAX_ATTEMPTS = 3;

/**
 * Backoff entre deux tentatives de reprise (ms). Le premier essai part
 * IMMÉDIATEMENT : la fenêtre de reprise du token est comptée, on ne l'entame pas
 * en attendant que le candidat revienne devant son écran.
 */
const RESUME_BACKOFF_MS = [0, 1000, 3000];

/**
 * Budget total d'une reprise (s). Au-delà on cesse de faire patienter le
 * candidat devant un écran figé. Borné aussi par `connectWindowSec` : passé
 * cette fenêtre le token de reprise ne peut plus ouvrir de connexion.
 */
const RESUME_BUDGET_SEC = 15;

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
    task,
    taskTitle,
    onFinished,
    onFatalError,
}: {
    descriptor: RealtimeSessionDescriptor;
    /** Sujet de la tâche : reste affiché (aide-mémoire) pendant l'échange —
     *  indispensable au jeu de rôle T2 où le candidat mène l'interaction. */
    task: ProductionTaskDto;
    taskTitle: string;
    /** Session close SANS incident : `evaluated` (une submission existe) ou
     *  `noSpeech` (le candidat n'a rien dit). Les issues à acquitter (envoi
     *  raté, production perdue, transmission partielle) sont traitées ICI, dans
     *  le runner, et ne remontent qu'une fois la décision prise par le
     *  candidat — via `onFinished` si la relance a réussi, `onFatalError`
     *  sinon. Un finish raté ne peut donc plus passer pour un succès. */
    onFinished: (result: RealtimeFinishResult) => void;
    onFatalError: (message: string) => void;
}) {
    const sessionId = descriptor.sessionId ?? "";
    const target = descriptor.targetDurationSec ?? DEFAULT_TARGET_SEC;

    const [state, setState] = useState<GeminiLiveState>("connecting");
    const [elapsed, setElapsed] = useState(0);
    const [examinerSpeaking, setExaminerSpeaking] = useState(false);
    const [timeUp, setTimeUp] = useState(false);
    const [finishing, setFinishing] = useState(false);
    // Dialogue affiché à la demande (bouton « Voir ma transcription »). Chaque
    // tour terminé arrive comme UNE ligne complète → une bulle.
    const [lines, setLines] = useState<{speaker: RealtimeSpeaker; text: string}[]>([]);
    const [showTranscript, setShowTranscript] = useState(false);
    // Consigne dépliée par défaut : le candidat garde son sujet sous les yeux.
    const [showSubject, setShowSubject] = useState(true);
    // Issue de la clôture à faire acquitter par le candidat (null = déroulé
    // nominal, on a déjà rendu la main à l'appelant).
    const [notice, setNotice] = useState<RealtimeFinishResult | null>(null);
    const [retrying, setRetrying] = useState(false);
    // Le WebSocket est tombé et une reprise est en cours. Le transcript, le
    // sujet et le chrono restent à l'écran : bandeau discret, rien de bloquant.
    const [reconnecting, setReconnecting] = useState(false);

    const liveRef = useRef<GeminiLiveSession | null>(null);
    const sheetBodyRef = useRef<HTMLDivElement | null>(null);
    // File ORDONNÉE des tours à relayer (l'ordre du dialogue est un artefact de
    // notation) + chaîne d'envoi séquentielle : les appendTranscript partent un
    // par un, dans l'ordre, et `finish()` peut ATTENDRE que tout soit arrivé.
    const pendingRef = useRef<{speaker: RealtimeSpeaker; text: string}[]>([]);
    const sendChainRef = useRef<Promise<void>>(Promise.resolve());
    const finishedRef = useRef(false);
    const elapsedRef = useRef(0);
    const timeUpRef = useRef(false);
    // Clôture pilotée par la fin de parole : l'examinateur a-t-il commencé sa
    // conclusion (parlé au moins une fois depuis 0:00) ? + timers repos/plafond.
    const heardCloseRef = useRef(false);
    const settleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const capTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    // Comptage du relais de transcript, qui est best-effort : sans lui, un
    // fragment perdu rétrécissait silencieusement la production notée. Ce sont
    // ces trois compteurs qui rendent la perte DÉTECTABLE et permettent de
    // distinguer « le candidat s'est tu » de « sa parole ne nous est pas
    // parvenue » — deux messages opposés à ne jamais confondre.
    const spokenRef = useRef(0);
    const relayedRef = useRef(0);
    const droppedRef = useRef(0);

    // --- État de REPRISE. Ce runner en est le seul propriétaire : la session WS
    // remonte le handle et signale la chute, elle ne décide rien. -------------
    // Numéro du prochain tour relayé (0, 1, 2…, strictement croissant sur la
    // session). Attribué UNE SEULE FOIS par segment, à la construction du lot, et
    // CONSERVÉ pendant les réessais : c'est lui qui rend l'envoi idempotent et
    // protège le quota du candidat.
    const turnIndexRef = useRef(0);
    // Dernier handle reçu du fournisseur, et dernier handle déjà transmis au
    // serveur — pour ne le joindre au POST /transcript que s'il est plus récent.
    const handleRef = useRef<string | null>(null);
    const handleRelayedRef = useRef<string | null>(null);
    const resumableRef = useRef(descriptor.resumable);
    const resumptionsLeftRef = useRef(descriptor.resumptionsRemaining ?? 0);
    const connectWindowRef = useRef(descriptor.connectWindowSec ?? null);
    const reconnectingRef = useRef(false);
    // La session WS est montée une seule fois (deps []) : elle appelle ce relais
    // plutôt qu'un handler figé dans la closure du premier rendu.
    const connectionLostRef = useRef<() => void>(() => undefined);

    // Écran allumé tant que l'échange est en cours : le candidat parle sans
    // toucher l'écran pendant plusieurs minutes, et une mise en veille couperait
    // le micro et la voix de l'examinateur au milieu de sa production. Relâché
    // dès que la session est close, en erreur, ou qu'un panneau d'issue attend
    // une décision (plus rien de temps réel à ce moment-là).
    useScreenWakeLock(state !== "closed" && state !== "error" && notice === null);

    // Relais batché du transcript (~1,2 s) : capture serveur fiable du dialogue
    // (artefact de notation). On NE l'affiche PAS — on l'envoie seulement. Les
    // tours consécutifs d'un même locuteur sont fusionnés (un appel par
    // segment) et les envois passent par sendChainRef : ordre garanti, et la
    // Future retournée attend TOUS les envois engagés (ce flush + les ticks
    // précédents encore en vol).
    const flush = useCallback((): Promise<void> => {
        if (!sessionId || pendingRef.current.length === 0) return sendChainRef.current;
        const batch = pendingRef.current;
        pendingRef.current = [];
        // Le numéro de tour est attribué ICI, une seule fois par segment et de
        // façon strictement croissante : c'est ce que le serveur déduplique.
        const segments: {speaker: RealtimeSpeaker; text: string; turns: number; index: number}[] = [];
        for (const turn of batch) {
            const last = segments[segments.length - 1];
            if (last && last.speaker === turn.speaker) {
                last.text += ` ${turn.text}`;
                last.turns += 1;
            } else {
                segments.push({...turn, turns: 1, index: turnIndexRef.current++});
            }
        }
        sendChainRef.current = sendChainRef.current.then(async () => {
            for (const seg of segments) {
                let sent = false;
                for (let attempt = 0; attempt < TRANSCRIPT_MAX_ATTEMPTS && !sent; attempt++) {
                    if (attempt > 0) {
                        await new Promise((r) => setTimeout(r, TRANSCRIPT_RETRY_DELAY_MS));
                    }
                    // Le handle voyage sur un appel qui a déjà lieu : pas
                    // d'aller-retour dédié. Seulement s'il est plus récent que
                    // le dernier transmis.
                    const handle =
                        handleRef.current !== handleRelayedRef.current ? handleRef.current : null;
                    try {
                        // MÊME index à chaque essai : un tour déjà appliqué est
                        // ignoré par le serveur, donc un réessai ne peut plus
                        // dupliquer de parole ni rendre une citation ambiguë.
                        // C'est ce qui a remplacé l'ancien « on ne renvoie jamais ».
                        await realtimeApi.appendTranscript(
                            sessionId,
                            seg.speaker,
                            seg.text,
                            seg.index,
                            handle,
                        );
                        if (handle) handleRelayedRef.current = handle;
                        sent = true;
                    } catch {
                        // Réessai avec le même index ; si tout échoue, la perte
                        // est comptée.
                    }
                }
                if (sent) {
                    if (seg.speaker === "CANDIDATE") relayedRef.current += seg.turns;
                } else {
                    // Perte RÉELLE : les tours suivants portent un index plus
                    // haut, donc celui-ci ne pourra plus être appliqué. On la
                    // compte au lieu de la maquiller, et on l'annonce.
                    droppedRef.current += seg.turns;
                }
            }
        });
        return sendChainRef.current;
    }, [sessionId]);

    /** Clôt la session côté backend (une relance automatique : une coupure
     *  passagère ne doit pas coûter une production, et `finish` est idempotent),
     *  puis traduit le tout en issue honnête. */
    const resolveFinish = useCallback(async (): Promise<RealtimeFinishResult> => {
        let finishOk = false;
        let serverEvaluated = false;
        for (let attempt = 0; attempt < 2 && !finishOk; attempt++) {
            if (attempt > 0) await new Promise((r) => setTimeout(r, 700));
            try {
                const st = await realtimeApi.finishSession(sessionId);
                serverEvaluated = st.evaluated;
                finishOk = true;
            } catch {
                // Rejoué une fois ; l'issue dira la vérité si ça ne passe pas.
            }
        }
        return resolveRealtimeFinish({
            finishOk,
            serverEvaluated,
            candidateTurnsSpoken: spokenRef.current,
            candidateTurnsRelayed: relayedRef.current,
            droppedTurns: droppedRef.current,
        });
    }, [sessionId]);

    const finish = useCallback(async () => {
        if (finishedRef.current) return;
        finishedRef.current = true;
        if (settleTimerRef.current) clearTimeout(settleTimerRef.current);
        if (capTimerRef.current) clearTimeout(capTimerRef.current);
        setFinishing(true);
        // stop() émet synchroneusement les derniers tours en tampon (callbacks →
        // pendingRef) ; on ATTEND ensuite la chaîne d'envoi complète avant de
        // clôturer : le backend passe la session en COMPLETED au finish et
        // ignore silencieusement tout fragment arrivé après — un flush non
        // attendu perdait le dernier tour (voire tout un échange court) →
        // « rien de transcrit, impossible d'évaluer ».
        liveRef.current?.stop();
        await flush();
        const result = await resolveFinish();
        // Une clôture ratée n'est PLUS confondue avec un succès : on n'appelle
        // l'appelant que sur un déroulé nominal, sinon on affiche le panneau.
        if (needsRealtimeAcknowledgement(result)) {
            setFinishing(false);
            setNotice(result);
            return;
        }
        onFinished(result);
    }, [flush, onFinished, resolveFinish]);

    /** Demande un nouveau token de reprise et rouvre le WebSocket avec.
     *  Réessaie sur une erreur réseau (backoff court et borné) ; un refus
     *  explicite du serveur (422 session terminée / plafond atteint / reprise
     *  désactivée, 404 session d'autrui) ou un `ASYNC_FALLBACK` arrête tout de
     *  suite : réessayer ne changerait rien. */
    const attemptResume = useCallback(async (): Promise<boolean> => {
        const window = connectWindowRef.current;
        const budgetMs = Math.min(RESUME_BUDGET_SEC, window ?? RESUME_BUDGET_SEC) * 1000;
        const startedAt = Date.now();
        for (let attempt = 0; attempt < RESUME_MAX_ATTEMPTS; attempt++) {
            if (attempt > 0) await new Promise((r) => setTimeout(r, RESUME_BACKOFF_MS[attempt]));
            if (finishedRef.current || Date.now() - startedAt > budgetMs) return false;
            try {
                const next = await realtimeApi.resumeSession(sessionId, handleRef.current);
                // ASYNC_FALLBACK (mint impossible côté serveur) ou descripteur
                // inexploitable : rien à rouvrir, on bascule sans réessayer.
                if (next.mode !== "REALTIME" || !next.wsEndpoint || !next.ephemeralToken) {
                    return false;
                }
                resumableRef.current = next.resumable;
                resumptionsLeftRef.current = next.resumptionsRemaining ?? 0;
                connectWindowRef.current = next.connectWindowSec ?? connectWindowRef.current;
                liveRef.current?.reconnect(next);
                return true;
            } catch (e) {
                if (e instanceof ApiException && e.status >= 400 && e.status < 500) return false;
                // Réseau / 5xx : on retente avec le même handle.
            }
        }
        return false;
    }, [sessionId]);

    /** Relance demandée par le candidat : `finish` est idempotent côté backend
     *  et le transcript est déjà en base — c'est bien l'ENVOI qu'on rejoue, pas
     *  l'oral. On repasse d'abord les fragments encore en attente. */
    const retryFinish = useCallback(async () => {
        if (retrying) return;
        setRetrying(true);
        await flush();
        const result = await resolveFinish();
        setRetrying(false);
        if (needsRealtimeAcknowledgement(result)) setNotice(result);
        else onFinished(result);
    }, [flush, onFinished, resolveFinish, retrying]);

    /** La reprise n'est pas (ou plus) possible. Ce qui est déjà arrivé au
     *  serveur est évaluable : on CLÔTURE plutôt que de le jeter, et
     *  `resolveRealtimeFinish` dira honnêtement ce qui s'est passé. Si rien
     *  n'est parti, il n'y a rien à sauver : on bascule sur l'enregistrement
     *  classique (chemin de repli existant, `onFatalError`). */
    const giveUpRealtime = useCallback(() => {
        if (relayedRef.current > 0) {
            void finish();
            return;
        }
        if (!finishedRef.current) {
            finishedRef.current = true;
            onFatalError(RT_RESUME_FAILED_MESSAGE);
        }
    }, [finish, onFatalError]);

    /** Le transport est tombé. Trois issues, dans cet ordre :
     *   1. le temps est écoulé (ou la clôture est engagée) → on clôture, il n'y
     *      a plus d'échange à reprendre ;
     *   2. la reprise est armée et il reste des reprises → on la demande TOUT
     *      DE SUITE (la fenêtre du token est comptée) ;
     *   3. sinon → repli.
     *
     *  🛑 On ne rappelle JAMAIS `POST /sessions` ici : cela créerait une seconde
     *  session et débiterait un second slot de simulation au candidat. */
    const handleConnectionLost = useCallback(async () => {
        if (finishedRef.current || reconnectingRef.current) return;
        if (timeUpRef.current) {
            void finish();
            return;
        }
        if (!resumableRef.current || resumptionsLeftRef.current <= 0) {
            giveUpRealtime();
            return;
        }
        reconnectingRef.current = true;
        // Le chrono s'ARRÊTE pendant la coupure (effet du minuteur, plus bas) :
        // le candidat ne doit pas perdre du temps de parole à cause de notre
        // réseau. Il ne repart pas de zéro non plus — `elapsedRef` est conservé.
        setReconnecting(true);
        const resumed = await attemptResume();
        reconnectingRef.current = false;
        setReconnecting(false);
        if (!resumed) giveUpRealtime();
    }, [attemptResume, finish, giveUpRealtime]);

    useEffect(() => {
        connectionLostRef.current = () => void handleConnectionLost();
    }, [handleConnectionLost]);

    // Connexion Gemini Live (montée une seule fois).
    useEffect(() => {
        const live = new GeminiLiveSession(descriptor, {
            onStateChange: setState,
            onSpeakingChange: setExaminerSpeaking,
            onCandidateTranscript: (t) => {
                spokenRef.current += 1;
                pendingRef.current.push({speaker: "CANDIDATE", text: t});
                setLines((prev) => [...prev, {speaker: "CANDIDATE", text: t}]);
            },
            onExaminerTranscript: (t) => {
                pendingRef.current.push({speaker: "EXAMINER", text: t});
                setLines((prev) => [...prev, {speaker: "EXAMINER", text: t}]);
            },
            // Mémorisé ici, relayé gratuitement sur le prochain POST /transcript.
            onResumptionHandle: (h) => {
                handleRef.current = h;
            },
            onConnectionLost: () => connectionLostRef.current(),
            onError: (m) => {
                if (!finishedRef.current) {
                    finishedRef.current = true;
                    onFatalError(m);
                }
            },
        });
        liveRef.current = live;
        live.start();
        const relay = setInterval(flush, TRANSCRIPT_RELAY_MS);
        return () => {
            clearInterval(relay);
            if (settleTimerRef.current) clearTimeout(settleTimerRef.current);
            if (capTimerRef.current) clearTimeout(capTimerRef.current);
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
        //
        // `reconnecting` MET LE DÉCOMPTE EN PAUSE : `elapsedRef` n'est jamais
        // remis à zéro, le chrono reprend là où il s'était arrêté quand le
        // WebSocket est rétabli.
        if (state !== "live" || reconnecting) return;
        const id = setInterval(() => {
            elapsedRef.current += 1;
            setElapsed(elapsedRef.current);
            if (!timeUpRef.current && elapsedRef.current >= target) {
                timeUpRef.current = true;
                setTimeUp(true);
                // Signale la fin (coupe le micro candidat + demande la conclusion).
                // La clôture réelle est pilotée par la fin de parole (effet plus
                // bas) ; le plafond borne le cas où l'examinateur ne conclut pas.
                liveRef.current?.notifyTimeUp();
                capTimerRef.current = setTimeout(() => void finish(), CLOSE_CAP_SEC * 1000);
            }
        }, 1000);
        return () => clearInterval(id);
    }, [state, target, finish, reconnecting]);

    // Clôture pilotée par la parole de l'examinateur après 0:00 : on attend qu'il
    // ait prononcé sa conclusion (a parlé au moins une fois) PUIS qu'il se taise
    // (repos `CLOSE_SETTLE_MS`) avant de couper — sinon on tranche en plein mot ou
    // on laisse un silence. S'il reparle, on annule le repos et on réattend.
    useEffect(() => {
        if (!timeUp) return;
        if (examinerSpeaking) {
            heardCloseRef.current = true;
            if (settleTimerRef.current) {
                clearTimeout(settleTimerRef.current);
                settleTimerRef.current = null;
            }
        } else if (heardCloseRef.current && !settleTimerRef.current) {
            settleTimerRef.current = setTimeout(() => void finish(), CLOSE_SETTLE_MS);
        }
    }, [timeUp, examinerSpeaking, finish]);

    // Panneau ouvert / nouveau tour → on colle le dialogue en bas.
    useEffect(() => {
        if (showTranscript && sheetBodyRef.current) {
            sheetBodyRef.current.scrollTop = sheetBodyRef.current.scrollHeight;
        }
    }, [showTranscript, lines.length]);

    const remaining = Math.max(0, target - elapsed);
    const speaking = examinerSpeaking && !reconnecting;
    const yourTurn = state === "live" && !speaking && !timeUp && !reconnecting;
    const statusLabel = reconnecting
        ? RT_RESUME_STATUS
        : finishing
          ? "Préparation de votre évaluation…"
          : state === "connecting"
            ? "Connexion à l'examinateur…"
            : state === "welcoming"
              ? "L'examinateur vous accueille…"
              : timeUp
                ? "Temps écoulé — l'examinateur conclut."
                : speaking
                  ? "L'examinateur parle…"
                  : "À vous de parler.";
    const hint = reconnecting
        ? RT_RESUME_HINT
        : finishing || state === "connecting" || timeUp
          ? taskTitle
          : state === "welcoming"
            ? "Un instant — votre micro s'activera après son accueil."
            : speaking
              ? "Écoutez sa question, puis répondez à voix haute."
              : "Parlez naturellement, comme à un vrai oral.";

    if (notice) {
        const {title, message} = realtimeFinishNotice(notice);
        return (
            <div className="rtn">
                <div className="rtn-card">
                    <p className="rtn-title">{title}</p>
                    <p className="rtn-msg">{message}</p>
                </div>
                <div className="rtn-actions">
                    {notice.kind === "evaluated" ? (
                        <button type="button" className="rtn-primary" onClick={() => onFinished(notice)}>
                            {RT_FINISH_SEE_RESULT_ACTION}
                        </button>
                    ) : (
                        <>
                            {notice.kind === "retryable" && (
                                <button
                                    type="button"
                                    className="rtn-primary"
                                    onClick={() => void retryFinish()}
                                    disabled={retrying}
                                >
                                    {retrying ? "Envoi en cours…" : RT_FINISH_RETRY_ACTION}
                                </button>
                            )}
                            <button
                                type="button"
                                className="rtn-secondary"
                                onClick={() => onFatalError(message)}
                                disabled={retrying}
                            >
                                {RT_FINISH_GIVE_UP_ACTION}
                            </button>
                        </>
                    )}
                </div>
                <style>{`
                    .rtn { display: flex; flex-direction: column; gap: 16px; }
                    .rtn-card {
                        background: var(--color-red-light); border: 1px solid var(--color-red);
                        border-radius: 14px; padding: 18px 16px;
                    }
                    .rtn-title {
                        margin: 0 0 6px; font-family: var(--font-display); font-size: 19px;
                        color: var(--color-ink);
                    }
                    .rtn-msg { margin: 0; font-size: 14px; line-height: 1.55; color: var(--color-ink-2); }
                    .rtn-actions { display: flex; flex-wrap: wrap; gap: 10px; }
                    .rtn-primary, .rtn-secondary {
                        flex: 1 1 200px; min-width: 0; border-radius: 12px; padding: 13px 20px;
                        font-family: var(--font-sans); font-weight: 800; font-size: 14px; cursor: pointer;
                    }
                    .rtn-primary { border: none; background: var(--color-ink); color: white; }
                    .rtn-secondary {
                        border: 1px solid var(--color-line); background: white; color: var(--color-ink);
                    }
                    .rtn-primary:disabled, .rtn-secondary:disabled { opacity: 0.5; cursor: default; }
                `}</style>
            </div>
        );
    }

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

            {reconnecting && (
                <div className="rte-reco" role="status" aria-live="polite">
                    <WifiOff size={16} strokeWidth={2.2} className="rte-reco-icon" />
                    <span className="rte-reco-text">
                        <span className="rte-reco-title">{RT_RESUME_TITLE}</span>
                        <span className="rte-reco-msg">{RT_RESUME_MESSAGE}</span>
                    </span>
                </div>
            )}

            <div className="rte-subject">
                <button
                    type="button"
                    className="rte-subject-head"
                    onClick={() => setShowSubject((v) => !v)}
                    aria-expanded={showSubject}
                >
                    <span className="rte-subject-eyebrow">Votre sujet · Tâche {task.tacheNumero}</span>
                    <ChevronDown
                        size={16}
                        strokeWidth={2.4}
                        className={`rte-subject-chev${showSubject ? " is-open" : ""}`}
                    />
                </button>
                {showSubject && (
                    <div className="rte-subject-body">
                        <p className="rte-subject-consigne">{task.consigne}</p>
                        {task.contexte && <p className="rte-subject-contexte">{task.contexte}</p>}
                    </div>
                )}
            </div>

            <div className="rte-stage">
                <div className={`rte-mic${speaking ? " is-exam" : ""}${yourTurn ? " is-you" : ""}`} aria-hidden>
                    <span className="rte-halo" />
                    <span className="rte-disc">
                        {speaking ? <Volume2 size={46} strokeWidth={1.8} /> : <Mic size={46} strokeWidth={1.8} />}
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
                    background: white; border: 1px solid var(--color-line);
                    border-radius: 14px; padding: 12px 14px;
                }
                .rte-id-row { display: flex; align-items: center; gap: 8px; min-width: 0; }
                .rte-name { font-family: var(--font-sans); font-weight: 800; font-size: 15px; color: var(--color-ink); }
                .rte-ia {
                    font-family: var(--font-mono); font-weight: 700; font-size: 10px;
                    color: var(--color-red-dark); background: white;
                    border: 1px solid var(--color-red); border-radius: 5px; padding: 1px 5px;
                }
                /* Bandeau de reprise : discret, non bloquant, il n'efface ni le
                   sujet, ni la transcription, ni le chrono (mis en pause). */
                .rte-reco {
                    display: flex; align-items: flex-start; gap: 10px;
                    background: var(--color-blue-soft);
                    border: 1px solid var(--color-blue);
                    border-radius: 14px; padding: 11px 14px;
                }
                .rte-reco-icon { flex-shrink: 0; margin-top: 2px; color: var(--color-blue); }
                .rte-reco-text { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
                .rte-reco-title {
                    font-family: var(--font-sans); font-weight: 800; font-size: 13px;
                    color: var(--color-blue);
                }
                .rte-reco-msg { font-size: 12.5px; line-height: 1.45; color: var(--color-ink-2); }
                .rte-subject {
                    background: var(--color-red-light);
                    border: 1px solid var(--color-red);
                    border-radius: 14px; overflow: hidden;
                }
                .rte-subject-head {
                    width: 100%; display: flex; align-items: center; justify-content: space-between;
                    gap: 10px; padding: 11px 14px; background: none; border: none; cursor: pointer;
                }
                .rte-subject-eyebrow {
                    font-family: var(--font-mono); font-weight: 700; font-size: 11px;
                    letter-spacing: 0.06em; text-transform: uppercase; color: var(--color-red-dark);
                }
                .rte-subject-chev { color: var(--color-red-dark); transition: transform 0.18s ease; }
                .rte-subject-chev.is-open { transform: rotate(180deg); }
                .rte-subject-body { padding: 0 14px 13px; }
                .rte-subject-consigne {
                    margin: 0; font-family: var(--font-sans); font-weight: 600; font-size: 14px;
                    line-height: 1.5; color: var(--color-ink);
                }
                .rte-subject-contexte {
                    margin: 8px 0 0; font-size: 13px; line-height: 1.5; color: var(--color-ink-2);
                }
                .rte-right { display: flex; align-items: center; gap: 12px; flex-shrink: 0; }
                .rte-live {
                    display: inline-flex; align-items: center; gap: 5px;
                    font-family: var(--font-mono); font-weight: 700; font-size: 10px;
                    letter-spacing: 0.06em; color: var(--color-red);
                }
                .rte-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--color-red); animation: rte-blink 1.4s ease-in-out infinite; }
                .rte-timer { font-family: var(--font-mono); font-weight: 700; font-size: 20px; color: var(--color-red); line-height: 1; }
                .rte-timer.is-urgent { color: var(--color-red-dark); }

                .rte-stage {
                    flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
                    text-align: center; gap: 8px; padding: 24px 8px;
                }
                .rte-mic { position: relative; width: 180px; height: 180px; display: flex; align-items: center; justify-content: center; }
                .rte-halo {
                    position: absolute; inset: 0; border-radius: 50%;
                    background: var(--color-red-light); opacity: 0.5;
                }
                .rte-mic.is-you .rte-halo { animation: rte-pulse 1.6s ease-out infinite; opacity: 1; }
                .rte-mic.is-exam .rte-halo { background: var(--color-blue-light); opacity: 1; }
                .rte-disc {
                    position: relative; width: 108px; height: 108px; border-radius: 50%;
                    display: flex; align-items: center; justify-content: center;
                    background: var(--color-red); color: white;
                    box-shadow: 0 10px 30px rgba(225, 55, 47, 0.28);
                }
                .rte-mic.is-exam .rte-disc { background: var(--color-blue); box-shadow: 0 10px 30px rgba(30, 58, 140, 0.26); }
                .rte-state { font-family: var(--font-display); font-size: 22px; color: var(--color-ink); margin: 8px 0 0; }
                .rte-hint { font-size: 13px; color: var(--color-muted); margin: 0; max-width: 320px; }

                .rte-stop {
                    align-self: center; display: inline-flex; align-items: center; gap: 8px;
                    border: none; border-radius: 12px; padding: 13px 26px;
                    background: var(--color-ink); color: white;
                    font-family: var(--font-sans); font-weight: 800; font-size: 14px; cursor: pointer;
                }
                .rte-stop:disabled { opacity: 0.5; cursor: default; }

                .rte-actions { display: flex; flex-direction: column; align-items: center; gap: 10px; }
                .rte-see {
                    display: inline-flex; align-items: center; gap: 8px;
                    border: 1px solid var(--color-line); border-radius: 12px;
                    padding: 10px 18px; background: white; color: var(--color-blue);
                    font-family: var(--font-sans); font-weight: 700; font-size: 13px; cursor: pointer;
                }
                .rte-see:hover { background: var(--color-blue-soft); }

                .rte-sheet {
                    position: absolute; inset: 0; z-index: 5;
                    background: white; border: 1px solid var(--color-line); border-radius: 14px;
                    display: flex; flex-direction: column; overflow: hidden;
                }
                .rte-sheet-head {
                    display: flex; align-items: center; justify-content: space-between;
                    padding: 14px 16px; border-bottom: 1px solid var(--color-line); flex-shrink: 0;
                }
                .rte-sheet-title { font-family: var(--font-display); font-size: 18px; color: var(--color-ink); }
                .rte-sheet-close {
                    display: inline-flex; border: none; cursor: pointer;
                    background: var(--color-paper-2); border-radius: 9px; padding: 6px; color: var(--color-ink);
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
