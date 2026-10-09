// ============================================================================
// Paramètres de CONDUITE de l'examinateur temps réel, servis par le backend
// (`RealtimeSessionDescriptor.conduct`, source unique :
// `backend_sejourfr/src/main/resources/prompts/realtime-conduct-<v>.json`).
//
// Le repli local ci-dessous ne sert QUE si le serveur ne sert pas le bloc
// (backend antérieur) ; il est identique au JSON v1. Miroir mobile :
// `RealtimeConductConfig.fallback` dans `realtime_models.dart`.
// ============================================================================

import type {RealtimeConductConfig, RealtimeSessionDescriptor} from "../types";

export const FALLBACK_CONDUCT: RealtimeConductConfig = {
    version: "v1",
    welcomePrimer: "Bonjour.",
    welcomeGuardMs: 8000,
    halfDuplexHoldMs: 120,
    voiceActivity: {energyThreshold: 0.02, minSpeechMs: 200, hangoverMs: 600},
    silenceRelance: {afterMs: 7000, maxConsecutive: 2, disabledLastSec: 15, message: "[SILENCE]"},
    timeUp: {graceMaxMs: 10000, message: "[FIN]", closeIdleMs: 1200, closeMaxMs: 15000},
    resume: {message: "[REPRISE]", contextTurns: 3},
};

/** Le bloc servi, ou le repli s'il est absent. */
export function resolveConduct(descriptor: RealtimeSessionDescriptor): RealtimeConductConfig {
    return descriptor.conduct ?? FALLBACK_CONDUCT;
}
