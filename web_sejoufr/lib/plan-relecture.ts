import {useSyncExternalStore} from "react";

/**
 * **« Relisez le Plan » — le signal des écritures qui changent l'écran OÙ L'ON
 * EST** (2026-09-27).
 *
 * Le cache (`lib/data-cache.ts`) est purgé par chaque écriture de mesure, mais
 * une purge ne fait relire **que l'écran qui se monte ensuite**. « Actualiser
 * mon plan » se clique DEPUIS le Plan : rien ne se remontait, et le candidat
 * gardait l'ancien cycle sous les yeux jusqu'au rechargement de la page.
 *
 * Les vues du Plan (`LearningPlanView`, `CivicPlanPanel`) mettent la version
 * dans les dépendances de leur lecture : un signal ⇒ elles relisent le cache
 * purgé. Miroir mobile : `learningPlanRevisionProvider` /
 * `relireSourcesDuCompte`.
 */
let version = 0;
const abonnes = new Set<() => void>();

export function signalerPlanARelire(): void {
    version += 1;
    abonnes.forEach((abonne) => abonne());
}

function abonner(abonne: () => void): () => void {
    abonnes.add(abonne);
    return () => {
        abonnes.delete(abonne);
    };
}

/** La version courante du signal : à mettre dans les dépendances d'une lecture. */
export function usePlanRelecture(): number {
    return useSyncExternalStore(abonner, () => version, () => 0);
}
