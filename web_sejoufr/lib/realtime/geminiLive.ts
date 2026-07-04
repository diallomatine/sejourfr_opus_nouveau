// ============================================================================
// Client Gemini Live (audio natif) — SEUL fichier qui connaît le protocole WS
// du fournisseur. Schéma de connexion (A) : on ouvre le WebSocket directement
// vers Gemini avec le token éphémère émis par le backend (persona verrouillée
// côté serveur). Changer de fournisseur (OpenAI Realtime, Qwen…) = remplacer
// ce fichier, rien d'autre côté web.
//
// Pipeline audio :
//  - capture micro -> PCM 16 bit 16 kHz mono (base64) -> realtimeInput.audio
//  - réception audio examinateur PCM 24 kHz -> file de lecture (barge-in géré)
//  - transcription entrée (candidat) + sortie (examinateur) -> callbacks
//
// ⚠️ La logique de permission micro / messages d'erreur FR est volontairement
// alignée sur EoRecordingForm (même UX d'autorisation).
// ============================================================================

import type {RealtimeSessionDescriptor} from "../types";

export type GeminiLiveState = "connecting" | "welcoming" | "live" | "closed" | "error";

export interface GeminiLiveCallbacks {
    /** Transcription d'un fragment dit par le CANDIDAT (micro). */
    onCandidateTranscript?: (text: string) => void;
    /** Transcription d'un fragment dit par l'EXAMINATEUR (modèle). */
    onExaminerTranscript?: (text: string) => void;
    /** L'examinateur parle / s'arrête (pour un indicateur visuel). */
    onSpeakingChange?: (speaking: boolean) => void;
    onStateChange?: (state: GeminiLiveState) => void;
    onError?: (message: string) => void;
}

/** Message d'erreur micro lisible (aligné sur EoRecordingForm). */
function micErrorMessage(name: string, message: string): string {
    if (/system/i.test(message)) {
        return "C'est votre système qui bloque le micro du navigateur. macOS : Réglages Système → Confidentialité et sécurité → Microphone → activez votre navigateur, puis relancez-le.";
    }
    switch (name) {
        case "NotAllowedError":
        case "SecurityError":
            return "Accès au micro refusé. Autorisez-le via l'icône à gauche de l'adresse → Microphone, puis réessayez.";
        case "NotFoundError":
        case "DevicesNotFoundError":
            return "Aucun microphone détecté. Branchez un micro puis réessayez.";
        case "NotReadableError":
        case "TrackStartError":
            return "Le micro est utilisé par une autre application. Fermez-la puis réessayez.";
        default:
            return "Micro inaccessible. Autorisez le microphone dans votre navigateur, puis réessayez.";
    }
}

function floatToPcm16(input: Float32Array): ArrayBuffer {
    const out = new DataView(new ArrayBuffer(input.length * 2));
    for (let i = 0; i < input.length; i++) {
        const s = Math.max(-1, Math.min(1, input[i]));
        out.setInt16(i * 2, s < 0 ? s * 0x8000 : s * 0x7fff, true);
    }
    return out.buffer;
}

function arrayBufferToBase64(buf: ArrayBuffer): string {
    const bytes = new Uint8Array(buf);
    let bin = "";
    const chunk = 0x8000;
    for (let i = 0; i < bytes.length; i += chunk) {
        bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
    }
    return btoa(bin);
}

function base64ToInt16(b64: string): Int16Array {
    const bin = atob(b64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new Int16Array(bytes.buffer);
}

/** Module AudioWorklet (inline) : poste les frames Float32 du micro au main thread. */
const WORKLET_SRC = `
class PcmCaptureProcessor extends AudioWorkletProcessor {
  process(inputs) {
    const input = inputs[0];
    if (input && input[0]) {
      this.port.postMessage(input[0].slice(0));
    }
    return true;
  }
}
registerProcessor('pcm-capture', PcmCaptureProcessor);
`;

export class GeminiLiveSession {
    private readonly descriptor: RealtimeSessionDescriptor;
    private readonly cb: GeminiLiveCallbacks;
    private readonly inputRate: number;
    private readonly outputRate: number;
    private readonly inputMime: string;

    private ws: WebSocket | null = null;
    private micStream: MediaStream | null = null;
    private captureCtx: AudioContext | null = null;
    private workletNode: AudioWorkletNode | null = null;
    private scriptNode: ScriptProcessorNode | null = null;
    private playbackCtx: AudioContext | null = null;
    private playHead = 0;
    private speaking = false;
    private closed = false;
    // Micro coupé (temps écoulé) : on cesse d'émettre les frames candidat mais on
    // garde le WS ouvert pour laisser l'examinateur prononcer sa phrase de clôture.
    private inputMuted = false;
    // Tant que l'examinateur n'a pas prononcé sa première phrase (accueil), on
    // coupe le micro du candidat. Libéré au 1er audio examinateur, ou par
    // garde-fou si rien n'arrive.
    private awaitingFirstExaminer = true;
    private welcomeTimer: ReturnType<typeof setTimeout> | null = null;
    // Transcription : on accumule les fragments Gemini VERBATIM (ils portent leur
    // propre espacement) et on n'émet une ligne qu'à la fin du tour (turnComplete
    // / interrupted). Ajouter un espace entre fragments coupait les mots.
    private candidateBuf = "";
    private examinerBuf = "";

    constructor(descriptor: RealtimeSessionDescriptor, cb: GeminiLiveCallbacks) {
        this.descriptor = descriptor;
        this.cb = cb;
        this.inputRate = descriptor.inputSampleRate ?? 16000;
        this.outputRate = descriptor.outputSampleRate ?? 24000;
        this.inputMime = descriptor.inputAudioMimeType ?? "audio/pcm;rate=16000";
    }

    /** Ouvre le micro + le WebSocket et démarre la conversation. */
    async start(): Promise<void> {
        this.cb.onStateChange?.("connecting");
        // Double-montage StrictMode / Fast Refresh (dev) : React lance start()
        // puis démonte aussitôt (cleanup -> stop()) avant de remonter. On diffère
        // l'ouverture du WS d'un micro-tick pour que le cleanup pose closed=true
        // AVANT — sinon la session jetée ouvrirait un socket clos en plein
        // handshake (1006), gâchant le token à usage unique et faisant remonter
        // une fausse « connexion échouée ». La vraie session (2e montage) passe.
        await Promise.resolve();
        if (this.closed) return;
        // Latence : on ouvre le WebSocket TOUT DE SUITE, en parallèle de l'init
        // micro. Le handshake WS + l'envoi du setup + la génération de l'accueil
        // par le modèle (le plus gros du « l'examinateur met du temps à arriver »)
        // se déroulent pendant que getUserMedia/AudioContext/worklet s'initialisent.
        // Le micro n'émet de toute façon rien avant la 1re phrase de l'examinateur
        // (half-duplex, awaitingFirstExaminer) — rien n'impose de l'attendre.
        this.openSocket();
        try {
            await this.openMic();
        } catch (e) {
            const name = e && typeof e === "object" && "name" in e ? String((e as {name?: unknown}).name) : "";
            const msg = e && typeof e === "object" && "message" in e ? String((e as {message?: unknown}).message) : "";
            this.fail(micErrorMessage(name, msg));
        }
        // StrictMode (double-montage dev) : si stop() a été appelé pendant
        // l'ouverture async du micro, fail()/stop() a déjà coupé le socket.
    }

    private openSocket(): void {
        const url = `${this.descriptor.wsEndpoint}?access_token=${encodeURIComponent(this.descriptor.ephemeralToken ?? "")}`;
        let ws: WebSocket;
        try {
            ws = new WebSocket(url);
        } catch {
            this.fail("Connexion à l'examinateur impossible.");
            return;
        }
        ws.binaryType = "arraybuffer";
        this.ws = ws;

        ws.onopen = () => {
            if (this.closed) return;
            // Endpoint "Constrained" : TOUT le setup (generationConfig, voix,
            // transcription in/out, VAD, systemInstruction) est verrouillé dans le
            // token éphémère côté serveur. Le client n'envoie qu'un setup MINIMAL
            // (juste le modèle) — réenvoyer les champs verrouillés fait rejeter la
            // connexion par l'endpoint contraint.
            ws.send(JSON.stringify({
                setup: {model: this.descriptor.model ?? undefined},
            }));
        };
        ws.onmessage = (ev) => this.onMessage(ev);
        ws.onerror = () => {
            // Session déjà fermée (cleanup StrictMode/Fast Refresh) : ne pas
            // remonter une fausse erreur qui tuerait le vrai flux.
            if (this.closed) return;
            this.fail("La connexion à l'examinateur a échoué.");
        };
        ws.onclose = (ev) => {
            // Code/raison utiles au diagnostic (1007 = setup invalide, 1008 = auth,
            // 1011 = erreur serveur…).
            if (ev.code !== 1000 && ev.code !== 1005) {
                console.warn(`[realtime] WS fermé code=${ev.code} raison=${ev.reason || "—"}`);
            }
            if (!this.closed) {
                this.closed = true;
                this.cb.onStateChange?.("closed");
            }
        };
    }

    private async onMessage(ev: MessageEvent): Promise<void> {
        // Après stop(), des messages déjà en file peuvent encore arriver : on les
        // ignore, sinon enqueueAudio rouvrirait un AudioContext et l'examinateur
        // « repartirait » après la clôture (et même après le rapport).
        if (this.closed) return;
        let text: string;
        if (ev.data instanceof ArrayBuffer) {
            text = new TextDecoder().decode(ev.data);
        } else if (ev.data instanceof Blob) {
            text = await ev.data.text();
        } else {
            text = String(ev.data);
        }
        let msg: GeminiServerMessage;
        try {
            msg = JSON.parse(text) as GeminiServerMessage;
        } catch {
            return;
        }
        if (msg.setupComplete) {
            // Phase d'accueil : micro coupé, on attend la 1re phrase de l'examinateur.
            this.cb.onStateChange?.("welcoming");
            // Gemini ne parle pas spontanément : on déclenche l'accueil par un
            // premier tour utilisateur « Bonjour. » — l'examinateur enchaîne
            // aussitôt (fin de l'attente « il met du temps à arriver »).
            this.sendOpeningTrigger();
            // Garde-fou : si rien sous ~8 s, on libère le micro et on passe en
            // conversation (un greeting audio manquant ne doit pas bloquer le candidat).
            this.welcomeTimer = setTimeout(() => this.beginConversation(), 8000);
            return;
        }
        const sc = msg.serverContent;
        if (!sc) return;

        // Accumulation VERBATIM (les fragments Gemini portent leur espacement).
        if (sc.inputTranscription?.text) this.candidateBuf += sc.inputTranscription.text;
        if (sc.outputTranscription?.text) this.examinerBuf += sc.outputTranscription.text;

        if (sc.interrupted) {
            this.flushPlayback();
            this.flushLine("examiner"); // barge-in : le tour examinateur est clos
        }

        const parts = sc.modelTurn?.parts ?? [];
        for (const p of parts) {
            const data = p.inlineData?.data;
            if (data) this.enqueueAudio(data);
        }

        // Fin de tour : on émet les lignes complètes (candidat puis examinateur).
        if (sc.turnComplete) {
            this.flushLine("candidate");
            this.flushLine("examiner");
        }
    }

    /** Émet une ligne de transcription complète (tour terminé), puis vide le buffer. */
    private flushLine(speaker: "candidate" | "examiner"): void {
        if (speaker === "candidate") {
            const text = this.candidateBuf.trim();
            this.candidateBuf = "";
            if (text) this.cb.onCandidateTranscript?.(text);
        } else {
            const text = this.examinerBuf.trim();
            this.examinerBuf = "";
            if (text) this.cb.onExaminerTranscript?.(text);
        }
    }

    /**
     * Amorce l'entretien : Gemini ne prend pas la parole tout seul après le setup.
     * On envoie un vrai tour utilisateur « Bonjour. » ({@code clientContent} +
     * {@code turnComplete}) — l'examinateur enchaîne son accueil (dicté par la
     * persona verrouillée dans le token). Ce tour texte n'est PAS de l'audio micro
     * → il n'apparaît pas dans la transcription du candidat.
     */
    private sendOpeningTrigger(): void {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
        this.ws.send(JSON.stringify({
            clientContent: {
                turns: [{role: "user", parts: [{text: "Bonjour."}]}],
                turnComplete: true,
            },
        }));
    }

    // --- Capture micro -------------------------------------------------------

    private async openMic(): Promise<void> {
        if (typeof navigator === "undefined" || !navigator.mediaDevices?.getUserMedia) {
            throw Object.assign(new Error("unsupported"), {name: "NotSupportedError"});
        }
        // Echo cancellation + suppression du bruit : sinon le micro capte le
        // haut-parleur (l'examinateur) et le renvoie à Gemini, qui le transcrit
        // comme une intervention candidat.
        const stream = await navigator.mediaDevices.getUserMedia({
            audio: {echoCancellation: true, noiseSuppression: true, autoGainControl: true},
        });
        // StrictMode : stop() pendant l'await -> on coupe le flux et on sort.
        if (this.closed) {
            stream.getTracks().forEach((t) => t.stop());
            return;
        }
        this.micStream = stream;
        const Ctor = window.AudioContext ?? (window as unknown as {webkitAudioContext: typeof AudioContext}).webkitAudioContext;
        const ctx = new Ctor({sampleRate: this.inputRate});
        this.captureCtx = ctx;
        if (ctx.state === "suspended") await ctx.resume();
        const source = ctx.createMediaStreamSource(stream);

        if (ctx.audioWorklet) {
            try {
                const blobUrl = URL.createObjectURL(new Blob([WORKLET_SRC], {type: "application/javascript"}));
                await ctx.audioWorklet.addModule(blobUrl);
                if (this.closed) return;
                URL.revokeObjectURL(blobUrl);
                const node = new AudioWorkletNode(ctx, "pcm-capture");
                node.port.onmessage = (e) => this.sendFrame(e.data as Float32Array, ctx.sampleRate);
                source.connect(node);
                // Pas de connexion à la destination : on ne veut pas réémettre le micro.
                this.workletNode = node;
                return;
            } catch {
                // Repli ScriptProcessor ci-dessous.
            }
        }
        const node = ctx.createScriptProcessor(4096, 1, 1);
        node.onaudioprocess = (e) => this.sendFrame(e.inputBuffer.getChannelData(0), ctx.sampleRate);
        source.connect(node);
        node.connect(ctx.destination);
        this.scriptNode = node;
    }

    private sendFrame(frame: Float32Array, ctxRate: number): void {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
        // Half-duplex : on n'émet PAS le micro pendant que l'examinateur parle —
        // évite la boucle d'écho (sa voix transcrite comme parole candidat).
        // Conséquence assumée : pas de barge-in (le candidat attend la question).
        // `inputMuted` : temps écoulé → le candidat ne parle plus, on écoute la clôture.
        if (this.awaitingFirstExaminer || this.speaking || this.inputMuted) return;
        const pcm = ctxRate === this.inputRate ? frame : downsample(frame, ctxRate, this.inputRate);
        const b64 = arrayBufferToBase64(floatToPcm16(pcm));
        this.ws.send(JSON.stringify({
            realtimeInput: {audio: {data: b64, mimeType: this.inputMime}},
        }));
    }

    // --- Lecture audio examinateur ------------------------------------------

    private ensurePlayback(): AudioContext {
        if (!this.playbackCtx) {
            const Ctor = window.AudioContext ?? (window as unknown as {webkitAudioContext: typeof AudioContext}).webkitAudioContext;
            this.playbackCtx = new Ctor({sampleRate: this.outputRate});
            this.playHead = 0;
        }
        // Politique autoplay : le contexte peut naître `suspended` -> aucun son.
        // On le réveille (la session part d'un clic utilisateur, donc autorisé).
        if (this.playbackCtx.state === "suspended") {
            this.playbackCtx.resume().catch(() => undefined);
        }
        return this.playbackCtx;
    }

    private enqueueAudio(b64: string): void {
        if (this.closed) return;
        // Premier audio de l'examinateur : fin de l'accueil, on ouvre le micro.
        this.beginConversation();
        const ctx = this.ensurePlayback();
        const pcm = base64ToInt16(b64);
        const buf = ctx.createBuffer(1, pcm.length, this.outputRate);
        const ch = buf.getChannelData(0);
        for (let i = 0; i < pcm.length; i++) ch[i] = pcm[i] / 0x8000;
        const src = ctx.createBufferSource();
        src.buffer = buf;
        src.connect(ctx.destination);
        const now = ctx.currentTime;
        const startAt = Math.max(now, this.playHead);
        src.start(startAt);
        this.playHead = startAt + buf.duration;
        if (!this.speaking) {
            this.speaking = true;
            this.cb.onSpeakingChange?.(true);
        }
        src.onended = () => {
            if (this.playbackCtx && this.playHead - this.playbackCtx.currentTime <= 0.05 && this.speaking) {
                this.speaking = false;
                this.cb.onSpeakingChange?.(false);
            }
        };
    }

    /** Fin de l'accueil : ouvre le micro et passe en conversation. */
    private beginConversation(): void {
        if (!this.awaitingFirstExaminer) return;
        this.awaitingFirstExaminer = false;
        if (this.welcomeTimer != null) {
            clearTimeout(this.welcomeTimer);
            this.welcomeTimer = null;
        }
        if (!this.closed) this.cb.onStateChange?.("live");
    }

    private flushPlayback(): void {
        if (this.playbackCtx) {
            this.playbackCtx.close().catch(() => undefined);
            this.playbackCtx = null;
        }
        this.playHead = 0;
        if (this.speaking) {
            this.speaking = false;
            this.cb.onSpeakingChange?.(false);
        }
    }

    /**
     * Signale au modèle que le temps de la tâche est écoulé : un vrai tour
     * utilisateur ({@code clientContent} + {@code turnComplete}) — c'est ce qui
     * déclenche la phrase de clôture de la persona. Un {@code realtimeInput.text}
     * n'est PAS un tour de dialogue et serait ignoré.
     */
    notifyTimeUp(): void {
        // Le candidat ne parle plus : on coupe son micro pour que le seul tour
        // restant soit la clôture de l'examinateur (évite qu'un dernier mot du
        // candidat relance un échange après le temps).
        this.inputMuted = true;
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({
                clientContent: {
                    turns: [{
                        role: "user",
                        parts: [{text: "[Le temps de cette partie est écoulé. Remerciez brièvement le candidat et concluez maintenant.]"}],
                    }],
                    turnComplete: true,
                },
            }));
        }
    }

    /** Coupe tout : micro, WebSocket, lecture. */
    stop(): void {
        // Clôture en plein tour : on émet le dernier buffer (sinon la fin de la
        // dernière réponse du candidat serait perdue).
        this.flushLine("candidate");
        this.flushLine("examiner");
        this.closed = true;
        if (this.welcomeTimer != null) {
            clearTimeout(this.welcomeTimer);
            this.welcomeTimer = null;
        }
        try {
            this.workletNode?.disconnect();
            this.scriptNode?.disconnect();
            this.captureCtx?.close().catch(() => undefined);
        } catch {
            // ignore
        }
        this.micStream?.getTracks().forEach((t) => t.stop());
        this.flushPlayback();
        if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
            try {
                this.ws.close();
            } catch {
                // ignore
            }
        }
        this.ws = null;
        this.cb.onStateChange?.("closed");
    }

    private fail(message: string): void {
        this.cb.onError?.(message);
        this.cb.onStateChange?.("error");
        this.stop();
    }
}

function downsample(input: Float32Array, fromRate: number, toRate: number): Float32Array {
    if (toRate >= fromRate) return input;
    const ratio = fromRate / toRate;
    const outLen = Math.floor(input.length / ratio);
    const out = new Float32Array(outLen);
    for (let i = 0; i < outLen; i++) {
        const start = Math.floor(i * ratio);
        const end = Math.min(input.length, Math.floor((i + 1) * ratio));
        let sum = 0;
        for (let j = start; j < end; j++) sum += input[j];
        out[i] = sum / Math.max(1, end - start);
    }
    return out;
}

// --- Formes des messages serveur Gemini Live --------------------------------

interface GeminiInlineData {
    data?: string;
    mimeType?: string;
}
interface GeminiPart {
    inlineData?: GeminiInlineData;
    text?: string;
}
interface GeminiServerContent {
    modelTurn?: {parts?: GeminiPart[]};
    inputTranscription?: {text?: string};
    outputTranscription?: {text?: string};
    turnComplete?: boolean;
    interrupted?: boolean;
}
interface GeminiServerMessage {
    setupComplete?: unknown;
    serverContent?: GeminiServerContent;
}
