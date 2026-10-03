"use client";

import {useEffect, useState} from "react";
import {examSlotsApi} from "./api";
import {useAuth} from "./auth-context";
import type {EpreuveType} from "./types";

/**
 * La grille SERVIE d'examens blancs, avec son état de lecture : les verrous
 * (case i = créneau i+1), « en cours » / « échec » et un « Réessayer ».
 *
 * 🛑 Le serveur décide du verrou (2026-09-24) : ce hook ne connaît ni rang, ni
 * accès — il relit la grille, compte ou visiteur selon la session, et la relit
 * quand l'accès du compte change (achat). Le NOMBRE de créneaux est celui de
 * la grille servie (`locks.length`), jamais une constante écrite à l'écran.
 *
 * `locks` vaut `[]` tant que la grille n'est pas arrivée ou si la lecture
 * échoue : un créneau absent reste verrouillé, on n'ouvre jamais par défaut.
 * `epreuve` nul désactive la lecture.
 */
export interface ExamSlotGrid {
    locks: ReadonlyArray<boolean>;
    loading: boolean;
    error: boolean;
    reload: () => void;
}

export function useExamSlotGrid(epreuve: EpreuveType | null): ExamSlotGrid {
    const {user, status} = useAuth();
    const [state, setState] = useState<{key: string; value: boolean[] | null; error: boolean} | null>(null);
    const [attempt, setAttempt] = useState(0);
    const auth = status === "authenticated";
    const key = `${epreuve}|${auth}|${user?.hasTcf}|${user?.hasCivique}|${attempt}`;

    useEffect(() => {
        if (status === "loading" || !epreuve) return;
        let cancelled = false;
        examSlotsApi
            .get(epreuve, auth)
            .then((grille) => {
                if (!cancelled) setState({key, value: grille.slots.map((s) => s.locked), error: false});
            })
            .catch(() => {
                /* La grille reste verrouillée ; l'écran peut le dire. */
                if (!cancelled) setState({key, value: null, error: true});
            });
        return () => {
            cancelled = true;
        };
    }, [status, epreuve, auth, key]);

    const fresh = state?.key === key ? state : null;
    return {
        locks: fresh?.value ?? NONE,
        loading: Boolean(epreuve) && status !== "loading" && fresh === null,
        error: fresh?.error ?? false,
        reload: () => setAttempt((n) => n + 1),
    };
}

/**
 * Les seuls verrous, tels que `ExamsGrid` les attend. Même lecture que
 * {@link useExamSlotGrid}, sans l'état de chargement.
 */
export function useExamSlotLocks(epreuve: EpreuveType | null): ReadonlyArray<boolean> {
    return useExamSlotGrid(epreuve).locks;
}

const NONE: ReadonlyArray<boolean> = [];
