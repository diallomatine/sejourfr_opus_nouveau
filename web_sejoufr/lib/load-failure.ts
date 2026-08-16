import { ApiException } from "./api";

/**
 * Le backend n'a pas répondu du tout : serveur éteint, `NEXT_PUBLIC_API_BASE_URL`
 * qui pointe ailleurs, réseau coupé. `fetch` lève alors un `TypeError`, jamais
 * une {@link ApiException} — c'est précisément le cas que les écrans oubliaient,
 * si bien qu'une panne de transport s'affichait soit en écran vide, soit en
 * « aucune série disponible », c'est-à-dire un mensonge sur le catalogue.
 */
export const SERVEUR_INJOIGNABLE =
  "Impossible de joindre le serveur. Vérifiez votre connexion, puis réessayez.";

/**
 * Message lisible pour un échec de **lecture** (chargement d'un catalogue :
 * thèmes, séries, examens). Pendant de `classifyStartFailure`, qui traite les
 * échecs d'**écriture** (démarrage d'un attempt) et route les 403 vers l'offre.
 *
 * Ici il n'y a rien à débloquer, donc rien à router : on se contente de nommer
 * la panne. Deux règles :
 *
 * - un **401/403 en lecture** n'est jamais une information pour le visiteur —
 *   c'est le front qui a appelé le client authentifié là où le mode invité
 *   attend `publicLotApi`/`publicThemeApi`. On affiche le repli, jamais le
 *   message du serveur (« Authentification requise » ne veut rien dire pour
 *   quelqu'un qui navigue sans compte) ;
 * - une erreur de transport se nomme comme telle, elle ne se déguise pas en
 *   catalogue vide.
 */
export function loadFailureMessage(error: unknown, fallbackMessage: string): string {
  if (error instanceof ApiException) {
    if (error.status === 401 || error.status === 403) return fallbackMessage;
    return error.message || fallbackMessage;
  }
  if (error instanceof TypeError) return SERVEUR_INJOIGNABLE;
  return fallbackMessage;
}
