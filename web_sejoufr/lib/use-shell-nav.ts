"use client";

import {usePathname} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {dashboardApi, progressionApi} from "./api";
import {useAuth} from "./auth-context";
import {peekCached} from "./data-cache";
import {shellNavTails, type ShellNavTails} from "./shell-nav";
import type {DashboardSummaryResponse, ProgressionCiviqueDto, ProgressionTcfDto} from "./types";

/**
 * **La source UNIQUE des tails de la barre latérale** (Navigation v2).
 *
 * 🛑 Elle ne fait que relire des caches PARTAGÉS, déjà lus par les écrans :
 * le résumé de l'Accueil (`dashboardApi.summaryCached`, mémo 30 s partagé
 * avec l'Accueil, Réviser, le Profil, les examens blancs) et les deux
 * progressions (`progressionApi.tcf|civique`, data-cache sous le préfixe
 * `progress:`, partagé avec les écrans `/progression/*` et vidé par toute
 * écriture de mesure). Aucune lecture n'est propre à la navigation.
 *
 * La barre latérale est montée UNE fois par écran (desktop et tiroir sont le
 * même élément) : un seul appel par donnée. Elle se relit à chaque navigation
 * — sans réseau tant que le cache tient, et c'est ce qui rafraîchit un tail
 * après un examen (le cache vient d'être purgé par l'écriture).
 */
export function useShellNav(): ShellNavTails {
    const {user, status} = useAuth();
    const pathname = usePathname();
    const [summary, setSummary] = useState<DashboardSummaryResponse | undefined>(undefined);
    const [tcf, setTcf] = useState<ProgressionTcfDto | undefined>(() =>
        peekCached<ProgressionTcfDto>(progressionApi.tcfKey(false)),
    );
    const [civique, setCivique] = useState<ProgressionCiviqueDto | undefined>(() =>
        peekCached<ProgressionCiviqueDto>(progressionApi.civiqueKey(false)),
    );

    useEffect(() => {
        if (status !== "authenticated") return;
        let vivant = true;
        dashboardApi
            .summaryCached()
            .then((d) => {
                if (vivant) setSummary(d);
            })
            .catch(() => {});
        progressionApi
            .tcf(false)
            .then((p) => {
                if (vivant) setTcf(p);
            })
            .catch(() => {});
        progressionApi
            .civique(false)
            .then((p) => {
                if (vivant) setCivique(p);
            })
            .catch(() => {});
        return () => {
            vivant = false;
        };
    }, [status, pathname]);

    const cible = user ? (user.targetLevel ?? null) : undefined;
    return useMemo(
        () =>
            shellNavTails({
                cible,
                niveauActuel: summary ? summary.estimatedTcfLevel : undefined,
                dernierExamenComplet: tcf ? (tcf.examensComplets.dernier?.niveau ?? null) : undefined,
                themesCivique: summary?.civique,
                meilleurTauxCivique: civique ? (civique.global.meilleur?.taux ?? null) : undefined,
            }),
        [cible, summary, tcf, civique],
    );
}
