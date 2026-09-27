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
 *
 * 🛑 **Aucun import React ici** : `lib/api.ts` importe ce module et il est lu
 * par des composants SERVEUR. Le hook vit dans `use-plan-relecture.ts`.
 */
let version = 0;
const abonnes = new Set<() => void>();

export function signalerPlanARelire(): void {
    version += 1;
    abonnes.forEach((abonne) => abonne());
}

export function abonnerPlanRelecture(abonne: () => void): () => void {
    abonnes.add(abonne);
    return () => {
        abonnes.delete(abonne);
    };
}

export function versionPlanRelecture(): number {
    return version;
}
