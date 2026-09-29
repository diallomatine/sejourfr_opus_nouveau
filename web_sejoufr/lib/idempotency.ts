/**
 * Clés d'idempotence des soumissions payantes (backend V046).
 *
 * Le problème qu'elles ferment : une production EE/EO part, le réseau lâche
 * avant la réponse, le client renvoie — et le serveur, qui n'a aucun moyen de
 * reconnaître la même production, paie une seconde correction IA et décompte
 * une seconde fois le quota du candidat.
 *
 * 🛑 **Une clé par PRODUCTION, jamais par requête.** Une clé régénérée à chaque
 * envoi ne protège de rien : c'est précisément le renvoi qui doit porter la même
 * clé que l'envoi initial. Elle ne change que lorsque le candidat commence une
 * *autre* production.
 *
 * Le serveur traite une clé absente comme « ce client ne sait pas encore se
 * répéter sans dommage » et garde l'ancien comportement : ne jamais envoyer de
 * clé bricolée pour « faire propre ».
 */
import { useCallback, useRef } from "react";

/** UUID v4, avec repli pour les contextes non sécurisés (http:// en dev). */
export function newSubmissionKey(): string {
    if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
        return crypto.randomUUID();
    }
    // Repli : `crypto.randomUUID` n'existe que sur les origines sécurisées.
    // La qualité aléatoire importe peu ici — la clé est bornée à un utilisateur
    // côté serveur, une collision entre deux comptes est sans effet.
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
        const r = (Math.random() * 16) | 0;
        const v = c === "x" ? r : (r & 0x3) | 0x8;
        return v.toString(16);
    });
}

/**
 * Une clé stable **par production**, sans reset manuel à tenir.
 *
 * `keyFor(identity)` rend toujours la même clé pour la même `identity`, et une
 * nouvelle dès que l'identité change. L'identité est ce qui désigne LA
 * production : typiquement `` `${attemptId}:${taskId}` `` pour une tâche
 * complète, `` `${promptId}:${essai}` `` pour un petit sujet.
 *
 * Pourquoi une identité plutôt qu'un `reset()` : un reset oublié est
 * silencieux — deux productions différentes partiraient sous la même clé, et la
 * seconde recevrait le rapport de la première. Une identité fausse, elle, se
 * voit immédiatement.
 *
 * Un `ref` et pas un `state` : changer de clé ne doit provoquer aucun rendu, et
 * la clé doit être lisible tout de suite dans le callback qui soumet.
 */
export function useSubmissionKey(): (identity: string) => string {
    const keys = useRef<Map<string, string>>(new Map());

    return useCallback((identity: string) => {
        const existing = keys.current.get(identity);
        if (existing !== undefined) {
            return existing;
        }
        const fresh = newSubmissionKey();
        keys.current.set(identity, fresh);
        return fresh;
    }, []);
}
