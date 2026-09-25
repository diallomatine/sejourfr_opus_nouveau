import type {AnalyticsCtaLocation} from "./analytics";
import {UUID_RE} from "./client-context";

/**
 * **D'où vient un achat** — le CTA qui l'a lancé et le parcours affiché à ce
 * moment-là. Ils voyagent dans l'adresse du parcours d'achat, comme `?retour=`
 * (`lib/retour.ts`), jusqu'à `billingApi.getPaymentLink`, où le serveur en fait
 * l'intention d'achat (Q12).
 *
 * 🛑 **Seul `LOCKED_PLAN` range l'achat dans le tunnel du diagnostic** (D32) :
 * c'est le CTA des écrans du Plan. Un achat lancé ailleurs est `OTHER_CTA`, et
 * garde son `journeyId` s'il en a un.
 *
 * Les deux valeurs sont **relues et validées** à l'arrivée : une adresse se
 * trafique dans la barre d'URL, et une valeur hors liste ne doit pas devenir
 * un CTA.
 */

export const CTA_PARAM = "cta";
export const JOURNEY_PARAM = "journey";

const CTA_LOCATIONS: ReadonlySet<AnalyticsCtaLocation> = new Set<AnalyticsCtaLocation>([
  "DIAGNOSTIC_REPORT",
  "LOCKED_PLAN",
  "PRICING",
  "AI_CORRECTION",
  "MOCK_EXAM",
  "HERO",
  "MIDDLE",
  "STICKY",
  "FOOTER",
  "OTHER",
]);

export type PurchaseOrigin = {
  ctaLocation: AnalyticsCtaLocation;
  journeyId: string | null;
};

/**
 * L'origine lue sur l'adresse, sinon `fallback` : l'écran qui porte le bouton
 * d'achat quand rien n'est arrivé avec lui (la grille des pass est un écran de
 * prix — `PRICING` y est un fait, pas une supposition).
 */
export function purchaseOriginDe(
  params: {get(key: string): string | null},
  fallback: AnalyticsCtaLocation,
): PurchaseOrigin {
  const cta = params.get(CTA_PARAM) as AnalyticsCtaLocation | null;
  const journey = params.get(JOURNEY_PARAM);
  return {
    ctaLocation: cta && CTA_LOCATIONS.has(cta) ? cta : fallback,
    journeyId: journey && UUID_RE.test(journey) ? journey : null,
  };
}

/** Pose l'origine sur une adresse interne du parcours d'achat. */
export function withPurchaseOrigin(
  href: string,
  origin: {ctaLocation: AnalyticsCtaLocation; journeyId?: string | null},
): string {
  const [base, hash = ""] = href.split("#");
  const params = new URLSearchParams({[CTA_PARAM]: origin.ctaLocation});
  if (origin.journeyId) params.set(JOURNEY_PARAM, origin.journeyId);
  const sep = base.includes("?") ? "&" : "?";
  return `${base}${sep}${params.toString()}${hash ? `#${hash}` : ""}`;
}
