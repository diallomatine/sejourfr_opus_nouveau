"use client";

import {useSyncExternalStore} from "react";
import {abonnerPlanRelecture, versionPlanRelecture} from "./plan-relecture";

/** La version courante du signal « Relisez le Plan » : à mettre dans les
 *  dépendances d'une lecture (`lib/plan-relecture.ts`). */
export function usePlanRelecture(): number {
    return useSyncExternalStore(abonnerPlanRelecture, versionPlanRelecture, () => 0);
}
