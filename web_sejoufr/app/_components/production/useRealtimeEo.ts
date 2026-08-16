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

/**
 * Le candidat a demandé l'examinateur et on n'a pas pu le lui donner : on
 * bascule sur l'enregistrement seul (il n'est JAMAIS bloqué), mais on le DIT.
 * Le silence a caché quatre jours de temps réel mort — une valeur de VAD
 * inexistante faisait refuser chaque token par le fournisseur, et les deux
 * fronts déposaient le candidat sur l'enregistreur solo sans un mot, comme
 * s'il l'avait choisi. Miroir mot pour mot de `kRealtimeUnavailableMessage`
 * (mobile, `realtime_launch.dart`).
 */
export const REALTIME_UNAVAILABLE_MESSAGE =
  "L'examinateur n'est pas disponible pour l'instant. Vous allez vous enregistrer seul(e) — votre réponse sera évaluée normalement.";

/** Une tâche EO est éligible au temps réel : audio + Tâche 1 ou 2 (T3 = async). */
export function isRealtimeEligible(mode: "text" | "audio", tacheNumero: number): boolean {
  return mode === "audio" && (tacheNumero === 1 || tacheNumero === 2);
}

/**
 * Logique partagée du lancement d'une session EO temps réel, commune à
 * l'entraînement libre (`ProductionInputPage`) et à l'examen blanc 3 tâches
 * (`ProductionSession`) : compteur de quota + ouverture d'une session pour un
 * `(productionTaskId, attemptId)`. Le quota n'est interrogé que si `enabled`.
 *
 * Le démarrage n'aboutit plus systématiquement à un descripteur : le backend
 * valide la session visée avant d'ouvrir l'échange (épreuve terminée, chrono
 * écoulé, tâche relevant d'une autre épreuve, tâche déjà rendue) et refuse en
 * 422 ; le quota épuisé ou un broker non configuré renvoient, eux, un
 * descripteur de bascule asynchrone. Aucun de ces cas ne bloque le candidat :
 * il lui reste toujours l'enregistrement classique.
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
        // 403 = accès refusé (session d'un autre compte) ; le paywall reste la
        // réponse la plus utile côté UI, l'offre étant le seul levier candidat.
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
