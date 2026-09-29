"use client";

import {useEffect, useState} from "react";
import {examSlotsApi} from "./api";
import {useAuth} from "./auth-context";
import type {EpreuveType} from "./types";

/**
 * Les verrous SERVIS d'une grille d'examens blancs (case i = créneau i+1), tels
 * que `ExamsGrid` les attend. 🛑 Le serveur décide du verrou (2026-09-24) : ce
 * hook ne connaît ni rang, ni accès — il relit la grille, compte ou visiteur
 * selon la session, et la relit quand l'accès du compte change (achat).
 *
 * `[]` tant que la grille n'est pas arrivée (ou si la lecture échoue) : un
 * créneau absent reste verrouillé, on n'ouvre jamais par défaut. `epreuve`
 * nul désactive la lecture.
 */
export function useExamSlotLocks(epreuve: EpreuveType | null): ReadonlyArray<boolean> {
    const {user, status} = useAuth();
    const [locks, setLocks] = useState<{key: string; value: boolean[]} | null>(null);
    const auth = status === "authenticated";
    const key = `${epreuve}|${auth}|${user?.hasTcf}|${user?.hasCivique}`;

    useEffect(() => {
        if (status === "loading" || !epreuve) return;
        let cancelled = false;
        examSlotsApi
            .get(epreuve, auth)
            .then((grille) => {
                if (!cancelled) setLocks({key, value: grille.slots.map((s) => s.locked)});
            })
            .catch(() => {
                /* best-effort : la grille reste verrouillée */
            });
        return () => {
            cancelled = true;
        };
    }, [status, epreuve, auth, key]);

    return locks?.key === key ? locks.value : NONE;
}

const NONE: ReadonlyArray<boolean> = [];
