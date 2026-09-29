import type {AnalyticsCtaLocation} from "@/lib/analytics";
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
export function usePlanJourneyId(module: ParcoursModule, enabled = true): string | null {
  const {status} = useAuth();
  const journey = useCachedData<JourneyDto>(
    enabled && status === "authenticated" ? journeyApi.cacheKeyFor(module) : null,
    () => journeyApi.getCached(module),
  );
  return journey.data?.journeyId ?? null;
}

/**
 * **L'origine d'achat d'un écran atteignable depuis le Plan** (contrôle F,
 * 2026-09-25). La provenance se lit sur le **marqueur de route** (`?etape=1`,
 * `lib/plan-step.ts`), jamais sur la seule présence d'un parcours en cache :
 * arrivé du Plan ⇒ `LOCKED_PLAN` + `journeyId` servi ; sinon le CTA que l'écran
 * pose sur son propre verrou, sans parcours. Hors Plan, aucun appel.
 */
export function usePlanStepPurchaseOrigin(
  fromPlan: boolean,
  horsPlan: AnalyticsCtaLocation | null,
  module: ParcoursModule = "TCF",
): {ctaLocation: AnalyticsCtaLocation | null; journeyId: string | null} {
  const journeyId = usePlanJourneyId(module, fromPlan);
  return fromPlan
    ? {ctaLocation: "LOCKED_PLAN", journeyId}
    : {ctaLocation: horsPlan, journeyId: null};
}
