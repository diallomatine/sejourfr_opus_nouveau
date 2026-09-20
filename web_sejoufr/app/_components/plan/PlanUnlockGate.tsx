"use client";

import {useSearchParams} from "next/navigation";
import {PlanUnlockScreen} from "./PlanUnlockScreen";
import type {PlanUnlockModule} from "@/lib/plan-unlock";

/**
 * Le module vient de l'URL — **TCF par défaut**, comme le Plan lui-même : un
 * paramètre absent ou inconnu ne doit pas laisser l'écran sans parcours.
 */
function moduleDepuisUrl(raw: string | null): PlanUnlockModule {
  return raw === "CIVIQUE" ? "CIVIQUE" : "TCF";
}

export function PlanUnlockGate() {
  const params = useSearchParams();
  return <PlanUnlockScreen module={moduleDepuisUrl(params.get("module"))} />;
}
