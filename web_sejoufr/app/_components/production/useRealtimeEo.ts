"use client";

import {useCallback, useEffect, useState} from "react";
import {ApiException, realtimeApi} from "@/lib/api";
import type {RealtimeSessionDescriptor} from "@/lib/types";

/** Résultat de l'ouverture d'une session temps réel. */
export type RealtimeStart =
  | {kind: "realtime"; descriptor: RealtimeSessionDescriptor}
  | {kind: "fallback"}
  | {kind: "paywall"}
  | {kind: "error"; message: string};

/** Une tâche EO est éligible au temps réel : audio + Tâche 1 ou 2 (T3 = async). */
export function isRealtimeEligible(mode: "text" | "audio", tacheNumero: number): boolean {
  return mode === "audio" && (tacheNumero === 1 || tacheNumero === 2);
}

/**
 * Logique partagée du lancement d'une session EO temps réel, commune à
 * l'entraînement libre (`ProductionInputPage`) et à l'examen blanc 3 tâches
 * (`ProductionSession`) : compteur de quota + ouverture d'une session pour un
 * `(productionTaskId, attemptId)`. Le quota n'est interrogé que si `enabled`.
 * Le démarrage interprète le descripteur (REALTIME vs bascule async) et le 403
 * (paywall) sans jamais bloquer le candidat.
 */
export function useRealtimeEo(enabled: boolean) {
  const [remaining, setRemaining] = useState<number | null>(null);
  // Cap du pass : 0 = non éligible (free/Civique → paywall), > 0 = pass TCF.
  const [cap, setCap] = useState<number | null>(null);

  useEffect(() => {
    if (!enabled) return;
    let cancelled = false;
    realtimeApi
      .getQuota()
      .then((q) => {
        if (!cancelled) {
          setRemaining(q.remaining);
          setCap(q.cap);
        }
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [enabled]);

  const start = useCallback(
    async (productionTaskId: string, attemptId: string): Promise<RealtimeStart> => {
      try {
        const descriptor = await realtimeApi.startSession({productionTaskId, attemptId});
        if (typeof descriptor.sessionsRemaining === "number") {
          setRemaining(descriptor.sessionsRemaining);
        }
        if (descriptor.mode === "REALTIME" && descriptor.sessionId) {
          return {kind: "realtime", descriptor};
        }
        // Quota épuisé / pass non éligible / non configuré : bascule async.
        return {kind: "fallback"};
      } catch (e) {
        if (e instanceof ApiException && e.status === 403) return {kind: "paywall"};
        return {
          kind: "error",
          message: e instanceof ApiException ? e.message : "Connexion à l'examinateur impossible.",
        };
      }
    },
    [],
  );

  return {remaining, cap, start};
}
