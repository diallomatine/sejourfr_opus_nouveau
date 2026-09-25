import {journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import type {ParcoursModule} from "@/lib/module-switch";
import type {JourneyDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";

/**
 * **Le `journeyId` SERVI du parcours d'un module** (`JourneyDto.journeyId`,
 * `plan_id` du chantier « Suivi », Q8), pour les feuilles d'achat des écrans
 * du Plan qui n'ont pas déjà le parcours en main. Lu sous la **même clé de
 * cache** que le Plan : aucun appel de plus quand on en vient.
 *
 * `null` = inconnu (visiteur, parcours pas encore lu ou illisible) : l'achat
 * part sans parcours, jamais avec un identifiant deviné.
 */
export function usePlanJourneyId(module: ParcoursModule): string | null {
  const {status} = useAuth();
  const journey = useCachedData<JourneyDto>(
    status === "authenticated" ? journeyApi.cacheKeyFor(module) : null,
    () => journeyApi.getCached(module),
  );
  return journey.data?.journeyId ?? null;
}
