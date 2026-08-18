/**
 * Passes d'accès à durée fixe (lot 5) — règles d'affichage et de parcours,
 * déclarées **une seule fois** pour tout le web.
 *
 * Elles vivaient recopiées dans `/tarifs` (`components/pricing/PricingPlans`),
 * `/paiement` et `/reussir` : trois copies de `POPULAR_PASS_CODE`, trois de
 * l'équivalent mensuel et trois libellés de durée, dont un qui avait déjà
 * divergé (365 jours rendait « 12 mois » sur la landing, « 1 an » ailleurs).
 * Le CLAUDE.md racine exige un pass mis en avant « déclaré une fois par front ».
 *
 * Tout est pur : aucune dépendance React, aucun appel réseau.
 */

import { withTrafficSource, type TrafficSource } from "./audience-events";
import { realtimeSessionsLabel, type PlanPublicResponse } from "./types";

/** Module vendu par un pass. Miroir de `ModuleAccess` côté serveur, restreint
 *  aux deux valeurs réellement payables. */
export type PassModule = "CIVIQUE" | "INTEGRAL";

/**
 * Pass mis en avant (« le plus populaire »), cohérent web ⇄ mobile
 * (`_popularPassCode`). Un pass ne peut pas être « le plus populaire » sur une
 * surface et anonyme sur la suivante.
 */
export const POPULAR_PASS_CODE = "INTEGRAL_PASS_2M";

/** Pendant civique, pour les surfaces qui n'affichent qu'un module à la fois. */
export const POPULAR_CIVIQUE_PASS_CODE = "CIVIQUE_PASS_3M";

export function isPopularPass(code: string): boolean {
  return code === POPULAR_PASS_CODE || code === POPULAR_CIVIQUE_PASS_CODE;
}

/**
 * Code du pass à mettre en avant dans une liste d'un seul module. Repli sur le
 * milieu de la grille quand aucun des deux codes de référence n'est vendu.
 */
export function popularPassCodeOf(list: PlanPublicResponse[]): string | null {
  if (list.length === 0) return null;
  const featured = list.find((p) => isPopularPass(p.code));
  if (featured) return featured.code;
  return list[Math.floor((list.length - 1) / 2)].code;
}

/** « 29,99 » / « 30 ». Le séparateur décimal est la virgule (fr-FR). */
export function formatPassPrice(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(2).replace(".", ",");
}

/**
 * Libellé de durée d'un pass (« 7 jours », « 1 mois », « 2 mois », « 1 an »).
 * Une semaine seule s'annonce **en jours** — c'est ainsi que le pass d'essai
 * est vendu, et « 1 semaines » est ce que rendait la règle plurielle.
 */
export function passDurationLabel(days: number): string {
  if (days <= 0) return "";
  if (days % 365 === 0) {
    const y = days / 365;
    return y === 1 ? "1 an" : `${y} ans`;
  }
  if (days >= 30 && days % 30 === 0) return `${days / 30} mois`;
  if (days % 7 === 0) return days === 7 ? "7 jours" : `${days / 7} semaines`;
  return `${days} jours`;
}

/**
 * Équivalent mensuel d'un pass, dérivé de sa durée (1 an → /12, 3 mois → /3,
 * 6 semaines → /1,5 en comptant un mois = 4 semaines). `null` pour un pass
 * ≤ 1 mois, où le prix affiché est déjà mensuel.
 *
 * ⚠️ C'est le **montant réellement débité** qui s'affiche en principal — un
 * pass se paie une fois, mettre un « /mois » en avant laisse croire à un
 * abonnement (règle du CLAUDE.md racine, valable sur les trois surfaces).
 * L'équivalent mensuel ne sert qu'à comparer deux durées entre elles.
 */
export function passMonthlyEquivalent(price: number, days: number): number | null {
  const months =
    days <= 0
      ? 0
      : days % 365 === 0
        ? (days / 365) * 12
        : days % 30 === 0
          ? days / 30
          : days % 7 === 0
            ? days / 7 / 4
            : days / 30;
  if (months <= 1) return null;
  return price / months;
}

/** « soit 15,00 €/mois », ou `null` quand il n'y a rien de comparable à dire. */
export function passMonthlyLabel(plan: PlanPublicResponse): string | null {
  const monthly = passMonthlyEquivalent(plan.price, plan.durationDays);
  if (monthly === null) return null;
  return `soit ${formatPassPrice(Number(monthly.toFixed(2)))} €/mois`;
}

/** Module payable d'un plan, ou `null` (plan gratuit / module non vendu). */
export function passModuleOf(plan: PlanPublicResponse): PassModule | null {
  if (plan.moduleAccess === "CIVIQUE") return "CIVIQUE";
  if (plan.moduleAccess === "INTEGRAL") return "INTEGRAL";
  return null;
}

/**
 * Le catalogue servi est-il en mode passes (lot 5) ? On ignore les plans non
 * payables (FREE reste `SUBSCRIPTION` en base) : sinon le `every` échouerait.
 */
export function isOneTimeCatalog(plans: PlanPublicResponse[]): boolean {
  const payable = plans.filter((p) => p.moduleAccess !== "NONE" && p.price > 0);
  return payable.length > 0 && payable.every((p) => p.purchaseType === "ONE_TIME");
}

/** Passes d'un module, **triés par durée croissante** (grille comparable). */
export function oneTimePassesOf(
  plans: PlanPublicResponse[],
  module: PassModule,
): PlanPublicResponse[] {
  return plans
    .filter((p) => p.purchaseType === "ONE_TIME" && p.moduleAccess === module)
    .sort((a, b) => a.durationDays - b.durationDays);
}

/** Retrouve un pass **actif** par son code (`listPlans` ne sert que les actifs). */
export function findOneTimePass(
  plans: PlanPublicResponse[],
  code: string | null,
): PlanPublicResponse | null {
  if (!code) return null;
  return (
    plans.find((p) => p.code === code && p.purchaseType === "ONE_TIME") ?? null
  );
}

/** Ce que le pass ouvre en simulations orales, en puce de liste. */
export function passSessionsLabel(plan: PlanPublicResponse): string | null {
  return realtimeSessionsLabel(plan);
}

// ---------------------------------------------------------------------------
// Parcours d'achat — « ce qu'il a cliqué doit le suivre jusqu'au paiement »
// ---------------------------------------------------------------------------

/** Écran de récapitulatif du pass choisi (authentifié, protégé par le middleware). */
export const PASS_RECAP_PATH = "/paiement/recapitulatif";

export function passRecapHref(code: string, source?: TrafficSource | null): string {
  return withTrafficSource(
    `${PASS_RECAP_PATH}?plan=${encodeURIComponent(code)}`,
    source,
  );
}

/**
 * Destination d'un clic sur un prix, connecté ou non. **Un seul montage**,
 * repris de `/reussir` : connecté → le récapitulatif du pass cliqué ; visiteur
 * → l'inscription en gardant la destination (`?next=`, passée par
 * `safeInternalPath` à l'arrivée), pour qu'il retombe exactement sur ce qu'il a
 * choisi au lieu de re-choisir dans une grille.
 *
 * `authenticated` inconnu (auth encore en chargement) ⇒ on vise le
 * récapitulatif : le middleware renverra un visiteur sur `/connexion?next=…`,
 * qui propose lui-même la création de compte. Jamais l'inverse — envoyer un
 * compte connecté sur `/inscription` serait un cul-de-sac.
 *
 * `source` transporte la provenance jusqu'à la **porte du compte** : sans elle
 * le `?src=` mourait en quittant la landing, et le serveur ne pouvait plus
 * rattacher l'inscription au réseau d'origine. Elle est posée sur les DEUX
 * destinations — l'écran d'inscription (qui portera l'en-tête au moment du
 * `register`) et le récapitulatif qui le suit.
 */
export function passCheckoutHref(
  code: string,
  authenticated: boolean | null,
  source?: TrafficSource | null,
): string {
  const recap = passRecapHref(code, source);
  if (authenticated === false) {
    return withTrafficSource(`/inscription?next=${encodeURIComponent(recap)}`, source);
  }
  return recap;
}
