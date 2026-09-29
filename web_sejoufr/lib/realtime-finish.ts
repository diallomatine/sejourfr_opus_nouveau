// Issue d'une session EO temps réel, du point de vue du CANDIDAT.
//
// Pourquoi ce module existe : la clôture (`POST /api/realtime/eo/sessions/{id}/
// finish`) était appelée dans un `try/catch` qui, en cas d'échec, laissait le
// drapeau « évalué » à `true`. Un envoi raté devenait indistinguable d'un
// succès : l'examen enchaînait la tâche suivante et la production du candidat
// disparaissait sans trace. Ici on refuse ce mensonge — l'état rendu dit
// exactement ce qui s'est passé, y compris quand c'est une mauvaise nouvelle.
//
// Ce qu'il faut savoir du backend pour lire les règles ci-dessous
// (`RealtimeSessionService`, lu dans le code, pas de mémoire) :
//   - le transcript est accumulé côté serveur au fil des `POST …/transcript` ;
//   - `finish` est IDEMPOTENT : rappelé sur une session encore ACTIVE, il
//     clôture et déclenche la notation normalement. Un échec réseau de la
//     clôture est donc RATTRAPABLE — à condition qu'au moins un tour candidat
//     soit arrivé jusqu'au serveur ;
//   - `evaluated=false` signifie « aucune submission créée » : côté serveur le
//     transcript ne contient aucun tour « Candidat : … ».
//
// Miroir mobile : `mobile_sejourfr/lib/screens/tcf_production/realtime/
// realtime_finish.dart` (mêmes règles, mêmes libellés, verrouillés par un test
// de chaque côté).

/**
 * - `evaluated` : une submission existe, il y a un résultat à afficher.
 * - `noSpeech` : le candidat n'a rien dit — rien à évaluer, et c'est exact.
 * - `lost` : le candidat a parlé mais sa parole n'est jamais arrivée au
 *   serveur. Rien à relancer : il faut le dire, pas le maquiller.
 * - `retryable` : la clôture a échoué alors que l'échange est bien côté
 *   serveur. Une relance de `finish` suffit, sans refaire l'oral.
 */
export type RealtimeFinishKind = "evaluated" | "noSpeech" | "lost" | "retryable";

export interface RealtimeFinishResult {
    kind: RealtimeFinishKind;
    /** Tours de dialogue DÉFINITIVEMENT perdus : le relais les a réessayés (à
     *  `turnIndex` constant, donc sans risque de doublon côté serveur) et aucun
     *  essai n'est passé. Les tours suivants portant un index plus haut,
     *  celui-ci ne pourra plus être appliqué. */
    droppedTurns: number;
}

export interface RealtimeFinishInput {
    /** La requête de clôture a-t-elle abouti (peu importe son verdict) ? */
    finishOk: boolean;
    /** `evaluated` renvoyé par le serveur — n'a de sens que si `finishOk`. */
    serverEvaluated: boolean;
    /** Tours candidat émis par le transcripteur pendant l'échange. */
    candidateTurnsSpoken: number;
    /** Tours candidat effectivement acceptés par le serveur. */
    candidateTurnsRelayed: number;
    /** Tours (tous locuteurs) perdus par le relais. */
    droppedTurns: number;
}

/**
 * Traduit la fin d'une session en une issue honnête.
 *
 * Le cas qui compte : `finishOk=false`. On ne suppose plus « évalué » —
 * on regarde si quelque chose du candidat est arrivé au serveur. Si oui la
 * clôture est rejouable ; si non, la production est perdue et on l'annonce.
 */
export function resolveRealtimeFinish(i: RealtimeFinishInput): RealtimeFinishResult {
    const droppedTurns = Math.max(0, i.droppedTurns);
    if (i.finishOk) {
        if (i.serverEvaluated) return {kind: "evaluated", droppedTurns};
        // Le serveur n'a vu aucun tour candidat. Deux histoires très
        // différentes : le candidat s'est tu (exact), ou sa parole s'est
        // perdue en route (il ne faut surtout pas lui dire qu'il s'est tu).
        return {kind: i.candidateTurnsSpoken > 0 ? "lost" : "noSpeech", droppedTurns};
    }
    if (i.candidateTurnsRelayed > 0) return {kind: "retryable", droppedTurns};
    return {kind: i.candidateTurnsSpoken > 0 ? "lost" : "noSpeech", droppedTurns};
}

/**
 * L'issue demande-t-elle une décision explicite du candidat avant de quitter
 * l'écran ? Vrai quand il y a une relance à proposer, une perte à annoncer, ou
 * une transmission partielle à signaler — jamais pour un déroulé nominal.
 */
export function needsRealtimeAcknowledgement(r: RealtimeFinishResult): boolean {
    if (r.kind === "retryable" || r.kind === "lost") return true;
    return r.kind === "evaluated" && r.droppedTurns > 0;
}

// Libellés — contrat gelé, recopié à l'identique côté mobile (même règle que
// les libellés de compétences : la chaîne ne transite pas par le réseau, donc
// seul un test par couche empêche les deux fronts de diverger).
export const RT_FINISH_RETRYABLE_TITLE = "Envoi impossible";
export const RT_FINISH_RETRYABLE_MESSAGE =
    "Votre échange n'a pas pu être envoyé à l'évaluation. Il est conservé sur nos serveurs : réessayez, vous n'avez pas à refaire l'oral.";
export const RT_FINISH_LOST_TITLE = "Réponse non transmise";
export const RT_FINISH_LOST_MESSAGE =
    "Votre échange n'est pas arrivé jusqu'à nous : il n'y a rien à évaluer, et il ne peut pas être récupéré. Refaites l'oral quand vous êtes prêt·e.";
export const RT_FINISH_PARTIAL_TITLE = "Transmission partielle";
export const RT_FINISH_PARTIAL_MESSAGE =
    "Une partie de votre échange n'a pas pu être transmise. Votre évaluation portera uniquement sur ce qui nous est parvenu.";
// Reprise de session après coupure du WebSocket — mêmes chaînes côté mobile
// (`kRtResume*` dans `realtime_finish.dart`). Ton du produit : on annonce ce qui
// se passe et ce qui est conservé, jamais un manque du candidat.
export const RT_RESUME_TITLE = "Connexion perdue";
export const RT_RESUME_MESSAGE =
    "Reprise de l'échange en cours — votre transcription et votre temps de parole sont conservés.";
export const RT_RESUME_STATUS = "Reprise de la connexion…";
export const RT_RESUME_HINT = "Restez sur cet écran, on repart là où vous en étiez.";
export const RT_RESUME_FAILED_MESSAGE =
    "La connexion à l'examinateur n'a pas pu être rétablie. Vous pouvez faire cette tâche en enregistrement classique.";

export const RT_FINISH_RETRY_ACTION = "Réessayer l'envoi";
export const RT_FINISH_GIVE_UP_ACTION = "Continuer sans cette réponse";
export const RT_FINISH_SEE_RESULT_ACTION = "Voir mon évaluation";

/** Titre + message du panneau à afficher pour une issue à acquitter. */
export function realtimeFinishNotice(r: RealtimeFinishResult): {title: string; message: string} {
    if (r.kind === "retryable") {
        return {title: RT_FINISH_RETRYABLE_TITLE, message: RT_FINISH_RETRYABLE_MESSAGE};
    }
    if (r.kind === "lost") {
        return {title: RT_FINISH_LOST_TITLE, message: RT_FINISH_LOST_MESSAGE};
    }
    return {title: RT_FINISH_PARTIAL_TITLE, message: RT_FINISH_PARTIAL_MESSAGE};
}
