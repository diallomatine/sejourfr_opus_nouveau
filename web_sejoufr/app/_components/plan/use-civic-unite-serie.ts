"use client";

/**
 * **Ouvrir la série d'une UNITÉ OFFICIELLE** — l'action d'une étape du cycle
 * civique (D-48, P8.7).
 *
 * 🛑 **Un seul hook pour un seul geste.** Le Plan dérivé a le sien
 * (`useCivicSerie`, sur une **cible**) ; celui-ci porte le grain du **cycle**,
 * une **unité de l'arrêté**. Deux grains, deux routes — mais **un seul endroit
 * par grain**, pour qu'une même unité ne s'ouvre jamais de deux façons.
 *
 * 🛑 **Le 403 n'est pas une panne** : c'est le verrou freemium que le serveur
 * oppose (D-33), et il ouvre l'offre. Même traitement que les autres lanceurs.
 */
import {useCallback, useState} from "react";
import {useRouter} from "next/navigation";
import {civicPlanApi} from "@/lib/api";
import {handleStartFailure} from "@/lib/start-failure";

export function useCivicUniteSerie() {
    const router = useRouter();
    const [enCours, setEnCours] = useState<string | null>(null);
    const [erreur, setErreur] = useState<string | null>(null);
    const [paywall, setPaywall] = useState(false);

    const start = useCallback(async (uniteCode: string) => {
        setErreur(null);
        setEnCours(uniteCode);
        try {
            const attempt = await civicPlanApi.serieSurUnite(uniteCode);
            router.push(`/examen-blanc?attempt=${attempt.id}`);
        } catch (cause) {
            handleStartFailure(cause, {
                onPaywall: () => setPaywall(true),
                onMessage: setErreur,
                fallbackMessage: "La série n'a pas pu démarrer. Réessayez.",
            });
        } finally {
            setEnCours(null);
        }
    }, [router]);

    return {enCours, erreur, paywall, setPaywall, start};
}
