import { ApiException } from "./api";

/** Réaction attendue à l'échec du démarrage d'un attempt. */
export type StartFailure =
  /** Verrou freemium appliqué par le backend (403) → on montre l'offre. */
  | { kind: "paywall" }
  /** Tout le reste (validation, réseau, serveur) → message lisible. */
  | { kind: "message"; message: string };

/**
 * Classifie l'erreur d'un démarrage d'attempt (série, examen blanc QCM, session
 * d'examen EE/EO). Le backend applique lui-même le paywall des examens blancs :
 * un écran dont le statut premium en cache est périmé (abonnement expiré en
 * cours de session, refresh raté) reçoit un 403 là où son UI croyait le slot
 * ouvert. Ce 403 est un refus **attendu**, pas une panne — il ne doit jamais
 * s'afficher en erreur technique.
 */
export function classifyStartFailure(error: unknown, fallbackMessage: string): StartFailure {
  if (error instanceof ApiException) {
    return error.status === 403 ? { kind: "paywall" } : { kind: "message", message: error.message };
  }
  return { kind: "message", message: fallbackMessage };
}

/**
 * Applique {@link classifyStartFailure} : `onPaywall` sur un 403, sinon
 * `onMessage` avec le message du backend. Un écran qui empile une feuille
 * (briefing, intro) la ferme dans `onPaywall` pour ne pas superposer deux
 * modales.
 */
export function handleStartFailure(
  error: unknown,
  handlers: {
    onPaywall: () => void;
    onMessage: (message: string) => void;
    fallbackMessage: string;
  },
): void {
  const failure = classifyStartFailure(error, handlers.fallbackMessage);
  if (failure.kind === "paywall") handlers.onPaywall();
  else handlers.onMessage(failure.message);
}
