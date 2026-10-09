// ============================================================================
// Conduite de l'examinateur temps réel côté client — logique PURE : aucune
// dépendance au réseau, à l'audio ou à l'horloge réelle (horloge et minuteurs
// injectés). Trois mécanismes, réglés par la conduite servie
// (`RealtimeConductConfig`, `prompts/realtime-conduct-<v>.json`) :
//
//  1. FIN DE TEMPS DOUCE (audit F03) : à l'échéance, si l'examinateur parle on
//     attend la fin de sa lecture ; si le candidat parle on le laisse finir sa
//     phrase (au plus `timeUp.graceMaxMs`) ; ENSUITE seulement on coupe le
//     micro et on envoie `[FIN]`, puis on clôt après `closeIdleMs` de silence de
//     l'examinateur, au plus `closeMaxMs`.
//  2. RELANCE SUR SILENCE (F02) : minuteur armé à la fin de la lecture de
//     l'examinateur, annulé dès que le candidat parle ; à `afterMs` sans parole,
//     `[SILENCE]` ; au plus `maxConsecutive` relances sans parole entre elles,
//     aucune dans les `disabledLastSec` dernières secondes ni pendant la fin de
//     temps.
//  3. REPRISE SANS CONTEXTE (F13) : `[REPRISE]` + les `contextTurns` derniers
//     tours, pour que l'examinateur ne rejoue pas l'ouverture.
//
// Le signal « le candidat parle » vient d'une détection LOCALE d'énergie du
// micro (après annulation d'écho, `VoiceActivityDetector`), jamais de la
// transcription, qui arrive en retard. Biais assumé : un bruit peut passer pour
// de la parole — sans gravité pour la relance (elle est seulement annulée),
// borné par `graceMaxMs` pour la fin de temps.
//
// Miroir Dart, cas pour cas : `mobile_sejourfr/lib/core/realtime/realtime_conduct.dart`.
// ============================================================================

import type {RealtimeConductConfig, RealtimeConductEvent, RealtimeSpeaker} from "../types";

/** Horloge et minuteurs injectés (réels en production, simulés en vérification). */
export interface ConductClock {
    now(): number;
    setTimeout(fn: () => void, ms: number): unknown;
    clearTimeout(handle: unknown): void;
}

/** Ce que la conduite demande à la session et à l'écran. */
export interface ConductActions {
    /** Envoie un tour texte au modèle (message entre crochets). */
    sendText(text: string): void;
    /** Coupe le micro du candidat (il ne parle plus après la fin de temps). */
    muteCandidate(): void;
    /** Clôt la session, cause `TIME_UP`. */
    close(): void;
    /** Trace un événement de conduite (mesure). */
    recordEvent(event: RealtimeConductEvent): void;
    /** Phase de fin de temps, pour l'écran. */
    onPhaseChange?(phase: ConductPhase): void;
}

/**
 * `live` : échange en cours · `waitExaminer` : échéance atteinte, l'examinateur
 * finit sa phrase · `grace` : le candidat finit la sienne · `closing` : `[FIN]`
 * envoyé, l'examinateur conclut.
 */
export type ConductPhase = "live" | "waitExaminer" | "grace" | "closing";

export class ConductController {
    private phase: ConductPhase = "live";
    private examinerSpeaking = false;
    private candidateActive = false;
    private suspended = false;
    private remainingSec: number;
    // Instant du dernier tic du chrono : le reste se lit à l'instant voulu, pas
    // seulement au tic (un minuteur peut expirer entre deux tics).
    private tickAt: number | null = null;
    private consecutiveRelances = 0;
    private silenceTimer: unknown = null;
    private waitTimer: unknown = null;
    private graceTimer: unknown = null;
    private graceStartedAt = 0;
    private capTimer: unknown = null;
    private idleTimer: unknown = null;
    private heardClose = false;
    private closed = false;
    private readonly conduct: RealtimeConductConfig;
    private readonly clock: ConductClock;
    private readonly actions: ConductActions;
    /** ms depuis l'établissement de la connexion, pour horodater un événement. */
    private readonly elapsedMs: () => number | null;
    /** Énergie du micro au-dessus du seuil EN CE MOMENT (début de parole pas encore confirmé). */
    private readonly candidateEnergyNow: () => boolean;

    constructor(
        conduct: RealtimeConductConfig,
        clock: ConductClock,
        actions: ConductActions,
        targetSec: number,
        elapsedMs: () => number | null,
        candidateEnergyNow: () => boolean = () => false,
    ) {
        this.conduct = conduct;
        this.clock = clock;
        this.actions = actions;
        this.remainingSec = targetSec;
        this.elapsedMs = elapsedMs;
        this.candidateEnergyNow = candidateEnergyNow;
    }

    getPhase(): ConductPhase {
        return this.phase;
    }

    /** Secondes restantes au chrono de la tâche (appelé à chaque tic). */
    tick(remainingSec: number): void {
        this.remainingSec = remainingSec;
        this.tickAt = this.clock.now();
    }

    /** Coupure réseau en cours : aucune relance ne part. */
    setSuspended(suspended: boolean): void {
        this.suspended = suspended;
        if (suspended) this.cancel("silence");
    }

    examinerSpeakingChanged(speaking: boolean): void {
        if (this.closed || speaking === this.examinerSpeaking) return;
        this.examinerSpeaking = speaking;
        if (speaking) {
            this.cancel("silence");
            if (this.phase === "closing") {
                this.heardClose = true;
                this.cancel("idle");
            }
            return;
        }
        switch (this.phase) {
            case "live":
                this.armSilence();
                break;
            case "waitExaminer":
                this.cancel("wait");
                this.afterExaminer();
                break;
            case "closing":
                if (this.heardClose) {
                    this.cancel("idle");
                    this.idleTimer = this.clock.setTimeout(() => this.finish(), this.conduct.timeUp.closeIdleMs);
                }
                break;
            default:
                break;
        }
    }

    candidateVoiceChanged(active: boolean): void {
        if (this.closed || active === this.candidateActive) return;
        this.candidateActive = active;
        if (active) {
            this.cancel("silence");
            this.consecutiveRelances = 0;
            return;
        }
        if (this.phase === "grace") this.endGrace();
    }

    /** Le chrono de la tâche vient d'atteindre l'échéance. */
    timeUp(): void {
        if (this.closed || this.phase !== "live") return;
        this.cancel("silence");
        if (this.conduct.timeUp.graceMaxMs <= 0) {
            // Conduite sans fin de temps douce (v0) : coupure immédiate, comme avant.
            this.sendFin();
            return;
        }
        if (this.examinerSpeaking) {
            this.setPhase("waitExaminer");
            // Borne : une lecture qui ne finit jamais ne retient pas la clôture.
            this.waitTimer = this.clock.setTimeout(() => this.afterExaminer(), this.conduct.timeUp.graceMaxMs);
            return;
        }
        this.afterExaminer();
    }

    dispose(): void {
        this.closed = true;
        this.cancel("silence");
        this.cancel("wait");
        this.cancel("grace");
        this.cancel("cap");
        this.cancel("idle");
    }

    // --- Fin de temps ------------------------------------------------------

    private afterExaminer(): void {
        if (this.closed || (this.phase !== "live" && this.phase !== "waitExaminer")) return;
        if (this.candidateActive || this.candidateEnergyNow()) {
            this.setPhase("grace");
            this.graceStartedAt = this.clock.now();
            this.graceTimer = this.clock.setTimeout(() => this.endGrace(), this.conduct.timeUp.graceMaxMs);
            return;
        }
        this.sendFin();
    }

    private endGrace(): void {
        if (this.phase !== "grace") return;
        this.cancel("grace");
        this.actions.recordEvent({
            type: "TIMEUP_GRACE",
            atMs: this.elapsedMs(),
            valueMs: Math.max(0, Math.round(this.clock.now() - this.graceStartedAt)),
        });
        this.sendFin();
    }

    private sendFin(): void {
        this.setPhase("closing");
        this.actions.muteCandidate();
        this.actions.sendText(this.conduct.timeUp.message);
        this.heardClose = false;
        this.capTimer = this.clock.setTimeout(() => this.finish(), this.conduct.timeUp.closeMaxMs);
    }

    private finish(): void {
        if (this.closed) return;
        this.dispose();
        this.actions.close();
    }

    // --- Relance sur silence ----------------------------------------------

    private armSilence(): void {
        this.cancel("silence");
        const r = this.conduct.silenceRelance;
        if (!r.message || this.suspended || this.consecutiveRelances >= r.maxConsecutive) return;
        // Une relance qui tomberait dans les dernières secondes n'est pas armée.
        if (this.remainingNowSec() - r.afterMs / 1000 <= r.disabledLastSec) return;
        this.silenceTimer = this.clock.setTimeout(() => this.fireSilence(), r.afterMs);
    }

    private fireSilence(): void {
        this.silenceTimer = null;
        const r = this.conduct.silenceRelance;
        if (this.closed || this.phase !== "live" || this.suspended || this.examinerSpeaking) return;
        if (this.remainingNowSec() <= r.disabledLastSec) return;
        // Course : le candidat commence à parler à l'instant où le minuteur expire.
        if (this.candidateActive || this.candidateEnergyNow()) return;
        if (this.consecutiveRelances >= r.maxConsecutive) return;
        this.consecutiveRelances += 1;
        this.actions.recordEvent({type: "SILENCE_RELANCE", atMs: this.elapsedMs()});
        this.actions.sendText(r.message);
    }

    // --- Outils ------------------------------------------------------------

    /** Secondes restantes au chrono à cet instant (le chrono ne court qu'une fois lancé). */
    private remainingNowSec(): number {
        if (this.tickAt == null) return this.remainingSec;
        return this.remainingSec - (this.clock.now() - this.tickAt) / 1000;
    }

    private setPhase(phase: ConductPhase): void {
        if (phase === this.phase) return;
        this.phase = phase;
        this.actions.onPhaseChange?.(phase);
    }

    private cancel(which: "silence" | "wait" | "grace" | "cap" | "idle"): void {
        const key = `${which}Timer` as "silenceTimer" | "waitTimer" | "graceTimer" | "capTimer" | "idleTimer";
        if (this[key] != null) {
            this.clock.clearTimeout(this[key]);
            this[key] = null;
        }
    }
}

/**
 * Détection LOCALE de voix sur l'énergie RMS du micro (après annulation d'écho).
 * Début confirmé après `minSpeechMs` au-dessus du seuil ; fin après `hangoverMs`
 * en dessous. Un seul détecteur par session, réutilisé par la fin de temps, la
 * relance et la mesure (D-07). `sinceMs` dit depuis combien de temps la
 * transition a RÉELLEMENT eu lieu : le début est confirmé `minSpeechMs` après le
 * premier paquet au-dessus du seuil, la fin `hangoverMs` après le dernier.
 */
export class VoiceActivityDetector {
    private active = false;
    private aboveMs = 0;
    private belowMs = 0;
    private lastAbove = false;
    private readonly voice: RealtimeConductConfig["voiceActivity"];
    private readonly onChange: (active: boolean, sinceMs: number) => void;

    constructor(
        voice: RealtimeConductConfig["voiceActivity"],
        onChange: (active: boolean, sinceMs: number) => void,
    ) {
        this.voice = voice;
        this.onChange = onChange;
    }

    /** Un paquet micro : son énergie RMS (0..1) et sa durée. */
    feed(rms: number, frameMs: number): void {
        this.lastAbove = rms >= this.voice.energyThreshold;
        if (this.lastAbove) {
            this.aboveMs += frameMs;
            this.belowMs = 0;
            if (!this.active && this.aboveMs >= this.voice.minSpeechMs) {
                this.active = true;
                this.onChange(true, this.aboveMs);
            }
        } else {
            this.belowMs += frameMs;
            this.aboveMs = 0;
            if (this.active && this.belowMs >= this.voice.hangoverMs) {
                this.active = false;
                this.onChange(false, this.belowMs);
            }
        }
    }

    /** Énergie au-dessus du seuil sur le dernier paquet (début pas encore confirmé compris). */
    energyNow(): boolean {
        return this.lastAbove;
    }

    /** Remet à zéro (l'examinateur parle : ce que capte le micro n'est pas le candidat). */
    reset(): void {
        const wasActive = this.active;
        const since = this.belowMs;
        this.active = false;
        this.aboveMs = 0;
        this.belowMs = 0;
        this.lastAbove = false;
        if (wasActive) this.onChange(false, since);
    }
}

/** Énergie RMS d'un paquet PCM flottant (-1..1). */
export function rmsOf(frame: Float32Array): number {
    if (frame.length === 0) return 0;
    let sum = 0;
    for (let i = 0; i < frame.length; i++) sum += frame[i] * frame[i];
    return Math.sqrt(sum / frame.length);
}

/**
 * Tour texte d'une reprise SANS contexte restauré : `[REPRISE]` puis les
 * `contextTurns` derniers tours du transcript, pour que l'examinateur reprenne
 * l'échange au lieu de rejouer l'ouverture. Vide si la conduite le désactive.
 */
export function resumePrimer(
    conduct: RealtimeConductConfig,
    lines: readonly {speaker: RealtimeSpeaker; text: string}[],
): string {
    const {message, contextTurns} = conduct.resume;
    if (!message) return "";
    const derniers = contextTurns > 0 ? lines.slice(-contextTurns) : [];
    return [
        message,
        ...derniers.map((l) => `${l.speaker === "EXAMINER" ? "Examinateur" : "Candidat"} : ${l.text}`),
    ].join("\n");
}
