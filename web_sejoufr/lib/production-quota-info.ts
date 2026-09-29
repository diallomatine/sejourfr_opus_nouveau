// Règle de l'info one-time « 1 essai d'entraînement gratuit par épreuve »
// (EE/EO). Volontairement pure et sans dépendance : c'est une décision de
// communication freemium, elle doit être testable seule.
//
// Source de la règle (backend, vérifiée dans le code, pas de mémoire) :
// `ProductionAccessService.enforceQuota` — 1 essai d'entraînement par épreuve
// à vie pour un compte gratuit, Premium TCF illimité — et
// `AttemptService.startProductionAttempt` — 1 examen blanc de production
// offert, dont les soumissions ne consomment pas ce quota.
//
// Miroir mobile : `mobile_sejourfr/lib/screens/tcf_production/production_quota_info.dart`.

import type {EpreuveType} from "./types";

/**
 * Clé de mémorisation, **par épreuve** : l'essai gratuit se compte par épreuve,
 * donc l'annonce se fait une fois pour l'écrit et une fois pour l'oral. Format
 * partagé mot pour mot avec le mobile (`EpreuveType.wire` côté Dart).
 */
export function prodQuotaInfoKey(epreuve: EpreuveType): string {
    return `sejourfr.prodQuotaInfo.${epreuve}`;
}

/**
 * Annonce-t-on l'essai gratuit ?
 *
 * `isPremium` reste calculé par l'appelant via `canAccessModule(user, "TCF")` :
 * la vérité du premium vit à un seul endroit, ce helper ne fait que décider du
 * moment. Un abonné ne doit jamais lire qu'il dispose d'un quota gratuit.
 */
export function shouldAnnounceFreeTrial({
    status,
    hasUser,
    isPremium,
    alreadySeen,
}: {
    status: string;
    hasUser: boolean;
    isPremium: boolean;
    alreadySeen: boolean;
}): boolean {
    if (status !== "authenticated" || !hasUser) return false;
    if (isPremium) return false;
    return !alreadySeen;
}
