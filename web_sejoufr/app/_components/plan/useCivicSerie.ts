"use client";

/**
 * **Où mène « travailler cette cible » côté civique**, en un seul endroit.
 *
 * ⚠️ Extrait à sa **deuxième** surface : le Plan civique et l'écran Réviser
 * ouvrent la même série sur la même cible. Deux copies auraient fini par
 * oublier l'une des trois choses qui comptent ici — le verrou lu, le refus
 * attendu, ou la destination.
 *
 * 🛑 Le **403** est un refus attendu — le verrou du serveur et le `locked`
 * servi sont la même règle — et il ouvre l'offre, jamais un message d'erreur
 * technique (`handleStartFailure`, l'autorité partagée).
 *
 * Miroir mobile : `screens/plan/civic_serie_launcher.dart`.
 */

import {useCallback, useState} from "react";
import {useRouter} from "next/navigation";
import {civicPlanApi} from "@/lib/api";
import {handleStartFailure} from "@/lib/start-failure";
import type {CivicPlanCibleDto} from "@/lib/types";

export const CIVIC_SERIE_FALLBACK = "Impossible de démarrer cette série.";

export interface CivicSerie {
    /** L'id de la cible en cours de lancement, `null` sinon. */
    enCours: string | null;
    /** Le message d'un échec **technique** ; un refus d'accès ouvre l'offre. */
    erreur: string | null;
    setErreur: (message: string | null) => void;
    /** L'offre est demandée. */
    paywall: boolean;
    setPaywall: (open: boolean) => void;
    commencer: (cible: CivicPlanCibleDto) => Promise<void>;
}

export function useCivicSerie(): CivicSerie {
    const router = useRouter();
    const [enCours, setEnCours] = useState<string | null>(null);
    const [erreur, setErreur] = useState<string | null>(null);
    const [paywall, setPaywall] = useState(false);

    const commencer = useCallback(
        async (cible: CivicPlanCibleDto) => {
            if (enCours) return;
            if (cible.locked) {
                setPaywall(true);
                return;
            }
            setEnCours(cible.id);
            setErreur(null);
            try {
                const attempt = await civicPlanApi.serie(cible.id, cible.grain);
                router.push(`/sessions/${attempt.id}`);
            } catch (e) {
                handleStartFailure(e, {
                    onPaywall: () => setPaywall(true),
                    onMessage: setErreur,
                    fallbackMessage: CIVIC_SERIE_FALLBACK,
                });
                setEnCours(null);
            }
        },
        [enCours, router],
    );

    return {enCours, erreur, setErreur, paywall, setPaywall, commencer};
}
