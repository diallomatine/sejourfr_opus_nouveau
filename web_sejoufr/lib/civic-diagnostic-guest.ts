/**
 * Le tunnel **invité** du diagnostic civique (`V053`).
 *
 * 🛑 **Arbitrage du propriétaire, 2026-09-10** : « que ce soit le diagnostic
 * examen civique ou TCF, l'utilisateur doit pouvoir passer le diagnostic avant
 * de créer son compte ; il répond au QCM et seulement après on lui demande de
 * créer son compte pour voir le résultat. »
 *
 * **Ce que ce module garde, et ce qu'il ne garde pas.** Il garde une *adresse* :
 * l'identifiant de la session ouverte côté serveur et celui de son attempt.
 * Les questions, les réponses et la correction, elles, restent au serveur.
 *
 * 🛑 **Différence assumée avec le TCF**, dont le tunnel invité conserve les
 * productions sur l'appareil (`lib/diagnostic-local-store.ts`) : le TCF produit
 * du texte et de l'audio, que personne n'a besoin de corriger avant l'analyse.
 * Le civique est du QCM — le corriger côté client obligerait à **servir les
 * bonnes réponses à un visiteur**, et jouer 40 questions hors `attempts`
 * obligerait à écrire un **second runner**. Les deux sont interdits.
 *
 * D'où `localStorage` et non IndexedDB : il n'y a ici que deux UUID.
 * Best-effort de bout en bout — navigation privée ou stockage refusé rendent
 * `null` plutôt que de lever, et le visiteur perd alors seulement la reprise.
 */
import {civicDiagnosticApi, publicCivicDiagnosticApi} from "./api";
import type {CivicDiagnosticDto, TargetProcedure} from "./types";

const CLE = "sejourfr.civic-diagnostic.invite";

/** L'adresse d'un diagnostic ouvert sans compte. */
export interface CivicDiagnosticInvite {
    sessionId: string;
    attemptId: string;
    /** La démarche déclarée au tirage — elle préremplit le formulaire de compte. */
    procedure: TargetProcedure;
    savedAt: number;
}

export function lireInvite(): CivicDiagnosticInvite | null {
    if (typeof window === "undefined") return null;
    try {
        const brut = window.localStorage.getItem(CLE);
        if (!brut) return null;
        const parse = JSON.parse(brut) as Partial<CivicDiagnosticInvite>;
        if (!parse.sessionId || !parse.attemptId) return null;
        return {
            sessionId: parse.sessionId,
            attemptId: parse.attemptId,
            procedure: parse.procedure ?? "CSP",
            savedAt: parse.savedAt ?? 0,
        };
    } catch {
        return null;
    }
}

export function ecrireInvite(
    dto: CivicDiagnosticDto,
    procedure: TargetProcedure,
): void {
    if (typeof window === "undefined") return;
    try {
        const entree: CivicDiagnosticInvite = {
            sessionId: dto.sessionId,
            attemptId: dto.attemptId,
            procedure,
            savedAt: Date.now(),
        };
        window.localStorage.setItem(CLE, JSON.stringify(entree));
    } catch {
        // Stockage refusé : la session existe quand même côté serveur, seule la
        // reprise après rechargement est perdue. On ne bloque pas le parcours.
    }
}

export function oublierInvite(): void {
    if (typeof window === "undefined") return;
    try {
        window.localStorage.removeItem(CLE);
    } catch {
        // Rien à faire : l'entrée résiduelle sera ignorée, la session étant
        // devenue introuvable publiquement dès son adoption.
    }
}

/**
 * L'avancement de la session invitée, ou `null` si elle n'existe plus.
 *
 * 🛑 **`null` efface l'adresse locale.** Une session adoptée ailleurs, expirée
 * ou ouverte depuis une autre IP renvoie 404 : garder son identifiant ferait
 * rejouer l'échec à chaque visite.
 */
export async function etatInvite(): Promise<CivicDiagnosticDto | null> {
    const invite = lireInvite();
    if (!invite) return null;
    try {
        return await publicCivicDiagnosticApi.get(invite.sessionId);
    } catch {
        oublierInvite();
        return null;
    }
}

/**
 * **L'adoption** : le visiteur vient de créer son compte, son diagnostic
 * devient le sien.
 *
 * À appeler dès qu'un écran du parcours civique se rend authentifié. Rend la
 * session adoptée, ou `null` s'il n'y avait rien à adopter.
 *
 * 🛑 **Un échec efface l'adresse locale et ne casse rien.** Le refus le plus
 * probable est le quota : un compte qui a déjà son diagnostic gratuit ne s'en
 * offre pas un second en repassant par le tunnel invité. L'écran appelant
 * retombe alors sur le diagnostic du compte, qui existe.
 */
export async function adopterSiInvite(): Promise<CivicDiagnosticDto | null> {
    const invite = lireInvite();
    if (!invite) return null;
    try {
        const adopte = await civicDiagnosticApi.adopt(invite.sessionId);
        oublierInvite();
        return adopte;
    } catch {
        oublierInvite();
        return null;
    }
}
