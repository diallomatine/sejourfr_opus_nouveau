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

import { withTrafficSource, type TrafficSource } from "./traffic-source";
import { realtimeSessionsLabel, type PlanPublicResponse } from "./types";

/** Module vendu par un pass. Miroir de `ModuleAccess` côté serveur, restreint
 *  aux deux valeurs réellement payables. */
export type PassModule = "CIVIQUE" | "INTEGRAL";

/**
 * 🛑 **L'ORDRE DES MODULES DANS UNE GRILLE DE PASS — décidé ICI, et nulle part
 * ailleurs.** L'**Intégral passe toujours devant** le Civique (demande du
 * propriétaire, 2026-09-20 : « pour l'affichage des pass, toujours afficher le
 * plan intégral en premier et la partie civique »).
 *
 * ⚠️ **L'ordre est FIXE** : il ne dépend plus du module d'arrivée
 * (`/paiement?module=`). C'est une règle de mise en avant commerciale, pas une
 * réponse au clic précédent — le pass ciblé reste repéré par `?plan=`, qui
 * surligne sa ligne et scrolle dessus.
 *
 * ⚠️ Le tri **par durée croissante à l'intérieur d'un module** ne change pas :
 * il vit dans `oneTimePassesOf`.
 *
 * Miroir Dart : `kPassModulesInOrder` (`core/models/billing_models.dart`).
 */
export const PASS_MODULES_IN_ORDER: readonly PassModule[] = ["INTEGRAL", "CIVIQUE"];

/**
 * **Le nom court d'un module**, celui qui se glisse dans une phrase
 * (« Votre pass Civique — 3 mois »).
 *
 * Miroir Dart : `PlanModuleTargetX.label`.
 */
export const PASS_MODULE_NAME: Record<PassModule, string> = {
  INTEGRAL: "Intégral",
  CIVIQUE: "Civique",
};

/**
 * 🛑 **LE TITRE DE LA CARTE d'un module dans une grille de pass**, déclaré une
 * seule fois pour tout le web.
 *
 * Le civique dit « **Examen civique uniquement** » (demande du propriétaire,
 * 2026-09-20) : depuis qu'il passe **après** l'Intégral, un titre « Civique »
 * se lisait comme un accès complet. Le titre nomme donc son **périmètre**.
 *
 * ⚠️ **Distinct de `PASS_MODULE_NAME`** : ce libellé-là est un **titre**, il ne
 * se met pas dans une phrase (« Votre pass Examen civique uniquement » ne se
 * lit pas).
 *
 * Miroir Dart : `PlanModuleTargetX.cardTitle`.
 */
export const PASS_MODULE_CARD_TITLE: Record<PassModule, string> = {
  INTEGRAL: "Intégral",
  CIVIQUE: "Examen civique uniquement",
};

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

/**
 * **Le prix d'entrée d'un module** — le plus petit montant réellement vendu.
 *
 * 🛑 **Dérivé du catalogue, jamais écrit.** C'est ce que rend « À partir de
 * X € » sur l'écran de déblocage du Plan : un chiffre en dur y vieillirait à la
 * première grille de prix, et le propriétaire a déjà deux montants différents
 * en tête selon les maquettes. `null` quand le module ne vend rien (catalogue
 * injoignable, ou aucun pass actif) — l'écran n'affiche alors **aucune** ligne
 * de prix plutôt qu'un montant de repli.
 *
 * Miroir Dart : `passFromPrice` (`core/widgets/paywall_context.dart`).
 */
export function passFromPrice(
  plans: PlanPublicResponse[],
  module: PassModule,
): number | null {
  return passFrom(plans, module)?.price ?? null;
}

/**
 * **Le pass d'entrée d'un module** — celui dont `passFromPrice` affiche le
 * prix. La mesure de « Débloquer mon plan » dit ce que le candidat avait sous
 * les yeux (`planCode` + `displayedPriceCents`) : c'est ce pass-là.
 */
export function passFrom(
  plans: PlanPublicResponse[],
  module: PassModule,
): PlanPublicResponse | null {
  const passes = oneTimePassesOf(plans, module);
  if (passes.length === 0) return null;
  return passes.reduce((min, p) => (p.price < min.price ? p : min), passes[0]);
}

/**
 * 🛑 **CE QUE LE COMPTE GRATUIT OUVRE, en puces de carte de prix** — déclaré une
 * seule fois pour tout le web (accueil `/` et `/tarifs`).
 *
 * Chaque ligne est une règle de `docs/regles/freemium.md`, jamais une promesse
 * éditoriale :
 *  · série 1 offerte par thème civique et par (épreuve TCF × niveau) — D-46 ;
 *  · créneau 1 de chaque grille d'examens blancs QCM, rejouable — D-33, D-62 ;
 *  · **un** examen blanc EE et **un** examen blanc EO, corrigés en entier par
 *    l'IA, à vie — D-17 / D-17 bis. ⚠️ Deux libellés faux l'ont précédée
 *    (« 1 découverte de l'évaluation IA en EE/EO », « T1 d'EE/EO 1 fois ») :
 *    la gratuité n'est ni une tâche isolée ni un aperçu, c'est l'examen entier.
 */
const FREE_EXPRESSION_EXAMS =
  "1 examen blanc d'expression écrite et 1 d'expression orale, corrigés par l'IA";

export const FREE_OFFER_FEATURES: readonly string[] = [
  "La 1ʳᵉ série d'entraînement de chaque thème et de chaque niveau",
  "Le 1ᵉʳ examen blanc de chaque épreuve et de chaque thème, rejouable",
  FREE_EXPRESSION_EXAMS,
  "Accès sans limite de durée",
];

/**
 * 🛑 **CE QU'UN PASS OUVRE, en puces** — déclaré une seule fois pour tout le
 * web : accueil `/`, `/paiement`, `/paiement/recapitulatif`, `/profil/abonnement`.
 * Miroir mot pour mot : `PlanModuleTargetX.passFeatures` (mobile,
 * `core/models/billing_models.dart`).
 *
 * Chaque ligne est un droit que le serveur ouvre au module (`hasCivique` /
 * `hasTcf`, `docs/regles/freemium.md`), jamais une promesse éditoriale. Ont été
 * retirés le 2026-09-26, parce que faux ou non propres au pass :
 *  · « Diagnostic CECRL (A2 / B1 / B2) » — le diagnostic rapide est GRATUIT pour
 *    tous, et le diagnostic complet n'est plus proposé ;
 *  · « Module TCF complet (CO + CE + Structure) » — le TCF IRN a QUATRE épreuves
 *    (CO, CE, EE, EO) ; Structure est un entraînement complémentaire ;
 *  · « Examens blancs … illimités » — les grilles ont 20 créneaux (10 en EE/EO) ;
 *  · « Favoris », « Statistiques par thématique », « Explications après chaque
 *    question » — ouverts à tout compte, gratuit compris.
 *
 * Le nombre de simulations orales en direct n'est PAS ici : il varie d'un pass à
 * l'autre et se lit sur chaque ligne de durée (`passSessionsLabel`).
 */
export const PASS_FEATURES: Record<PassModule, readonly string[]> = {
  INTEGRAL: [
    "Tout le pass Civique",
    "Les 4 épreuves du TCF IRN : toutes les séries et tous les examens blancs",
    "Expression écrite et orale corrigées par l'IA",
    "Votre plan TCF personnalisé, étape par étape",
  ],
  CIVIQUE: [
    "Toutes les séries d'entraînement des 5 thèmes",
    "Tous les examens blancs civiques, complets et par thème",
    "Votre plan civique personnalisé",
  ],
};

/**
 * **Ce qu'un pass n'ouvre PAS** — une ligne, pas une liste barrée. Le Pass
 * Civique ne débloque pas le TCF IRN (demande du propriétaire, 2026-09-20) ;
 * l'Intégral couvre tout, d'où `null`. Miroir : `PlanModuleTargetX.passExcluded`.
 */
export const PASS_EXCLUDED: Record<PassModule, string | null> = {
  INTEGRAL: null,
  CIVIQUE: "Le TCF IRN (4 épreuves, correction IA)",
};

/** Une phrase de périmètre, sous le titre d'une carte de pass. */
export const PASS_PITCH: Record<PassModule, string> = {
  INTEGRAL: "L'examen civique et le TCF IRN : toute la préparation de votre démarche.",
  CIVIQUE: "Toute la préparation à l'examen civique, sans le TCF IRN.",
};

// ---------------------------------------------------------------------------
// La feuille d'offre (paywall) — ce qu'elle dit, déclaré une fois
// ---------------------------------------------------------------------------

/**
 * 🛑 **LE TEXTE DE LA FEUILLE D'OFFRE** (`app/_components/PaywallSheet.tsx`),
 * contextuel au module touché. Miroir mot pour mot :
 * `PlanModuleTargetX.offerTitleLead` / `offerTitleEm` / `offerText`
 * (`mobile_sejourfr/lib/core/models/billing_models.dart`).
 *
 * Il remplace, le 2026-09-26, un texte entièrement périmé : « Continuez en
 * illimité », « Le mode démo offre 20 questions de découverte », « Activez
 * l'abonnement », « Plus de 1 200 questions », « Tous les thèmes, sans limite »,
 * « Favoris » et « Voir les abonnements ». Un pass est un **achat unique**, sans
 * renouvellement ; les grilles ont des créneaux comptés ; les favoris sont
 * ouverts à tout compte. Les puces viennent de `PASS_FEATURES`, jamais d'ici.
 *
 * Le titre se coupe en deux parce que la fin passe en `<em>` (rouge, Fraunces).
 */
export const PASS_OFFER_TITLE: Record<PassModule, { lead: string; em: string }> = {
  INTEGRAL: { lead: "Continuez avec le pass ", em: "Intégral" },
  CIVIQUE: { lead: "Continuez avec le pass ", em: "Civique" },
};

/** La phrase sous le titre, quand l'écran n'en donne pas de plus précise. */
export const PASS_OFFER_TEXT: Record<PassModule, string> = {
  INTEGRAL:
    "Ce contenu fait partie du pass Intégral : le TCF IRN et l'examen civique, pour la durée de votre choix.",
  CIVIQUE:
    "Ce contenu fait partie du pass Civique, et de l'Intégral qui y ajoute le TCF IRN.",
};

/** La promesse commerciale d'un pass, en une ligne. Miroir : `kPassOneTimeNote`. */
export const PASS_ONE_TIME_NOTE = "Paiement unique, sans abonnement ni renouvellement automatique.";

/** Le bouton de la feuille, qui mène à `/paiement`. Miroir : `kPassOfferCta`. */
export const PASS_OFFER_CTA = "Voir les pass";

/** Le refus poli. Miroir : `kPassOfferLater`. */
export const PASS_OFFER_LATER = "Plus tard";

/**
 * **Le pass que la feuille désigne sur `/paiement`** (`?plan=`, qui surligne la
 * ligne et y fait défiler). Le pass mis en avant du module : on n'invente pas
 * un « pass adapté ». Un code absent du catalogue actif reste inerte.
 */
export const PASS_OFFER_PLAN: Record<PassModule, string> = {
  INTEGRAL: POPULAR_PASS_CODE,
  CIVIQUE: POPULAR_CIVIQUE_PASS_CODE,
};

/**
 * **Ce qu'un compte gratuit ajoute à la visite sans compte** — les puces de la
 * feuille d'inscription (`GuestGateSheet`). Web seul : le mobile n'a aucun mode
 * invité. Chaque ligne est vraie pour un compte gratuit (`docs/regles/freemium.md`) :
 * les séries 2+ ne s'y trouvent PAS, elles restent dans les pass.
 */
export const FREE_ACCOUNT_EXTRAS: readonly string[] = [
  FREE_EXPRESSION_EXAMS,
  "Vos scores, votre progression et la reprise de vos sessions",
  "Vos favoris, pour retrouver vos questions",
];

/** Le pass qui ouvre un module d'examen : tout le TCF est dans l'Intégral. */
export function passModuleOfExam(module: "CIVIQUE" | "TCF"): PassModule {
  return module === "TCF" ? "INTEGRAL" : "CIVIQUE";
}

/**
 * La fin d'une série offerte, pour un compte sans le pass du module
 * (`TrainingResultCard`). Miroir mot pour mot : `passSeriesDoneText`
 * (`mobile_sejourfr/lib/core/models/billing_models.dart`), lu par le dialogue
 * de fin de série du runner. Remplace « Démo terminée … l'abonnement débloque
 * l'entraînement illimité » (2026-09-26).
 */
export const PASS_SERIES_DONE_TITLE = "Série terminée";

export function passSeriesDoneText(module: PassModule, total: number): string {
  return `Vous avez terminé cette série de ${total} questions. Les séries suivantes font partie du pass ${PASS_MODULE_NAME[module]}.`;
}
