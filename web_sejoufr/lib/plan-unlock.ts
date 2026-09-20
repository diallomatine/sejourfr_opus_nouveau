/**
 * **L'écran de déblocage du Plan** (`/plan/debloquer`) — ses règles et ses
 * libellés, déclarés **une seule fois** pour tout le web.
 *
 * C'est l'écran de transition ouvert par « Débloquer mon plan », entre le Plan
 * et la page de choix du pass. Il raconte **ce que le diagnostic a trouvé**,
 * puis il annonce le prix d'entrée du module.
 *
 * 🛑 **UN SEUL écran pour les deux modules**, paramétré par [PlanUnlockModule].
 * Les deux maquettes du propriétaire partagent l'anatomie — œil-de-bœuf, héros
 * bleu, titre, sous-titre, trois lignes numérotées, un bloc propre au module,
 * le prix, le bouton rouge, le lien discret — et ne diffèrent que par leur
 * **matière**. Deux écrans divergeraient au premier correctif : c'est ce que
 * D-50 / A86 ont refusé pour `PlanCycleSection`, et la raison est la même.
 *
 * 🛑 **Rien n'est dérivé ici.** Le palier, le score, l'état de chaque priorité
 * et le prix d'entrée arrivent **servis** ; ce fichier ne fait que les mettre
 * en mots. Aucun nombre n'est classé en état pédagogique.
 *
 * 🛑 **Aucun prix écrit.** Le montant vient de `billingApi.listPlans()` via
 * `passFromPrice` (`lib/passes.ts`). Catalogue injoignable ⇒ **aucune ligne de
 * prix**, jamais un montant de repli.
 *
 * Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/plan/plan_unlock_labels.dart` : un libellé qui
 * bouge, ce sont deux fichiers dans la même passe.
 */
import type {Module} from "./types";
import type {PassModule} from "./passes";
import {formatPassPrice} from "./passes";

/** Le parcours dont on débloque le plan. */
export type PlanUnlockModule = "TCF" | "CIVIQUE";

/** La route de l'écran, et le seul endroit qui l'écrit. */
export const PLAN_UNLOCK_PATH = "/plan/debloquer";

export function planUnlockHref(module: PlanUnlockModule): string {
  return `${PLAN_UNLOCK_PATH}?module=${module}`;
}

/** Le retour : on revient au Plan, jamais à un écran intermédiaire. */
export function planRetourHref(module: PlanUnlockModule): string {
  return module === "CIVIQUE" ? "/plan?module=CIVIQUE" : "/plan";
}

/**
 * 🛑 **Le TCF s'achète avec le pass INTÉGRAL**, jamais avec le Pass Civique —
 * c'est exactement ce que la page de choix doit rendre évident. Cette table est
 * la seule qui fasse la correspondance côté web.
 */
export function planUnlockPassModule(module: PlanUnlockModule): PassModule {
  return module === "CIVIQUE" ? "CIVIQUE" : "INTEGRAL";
}

/**
 * **L'accès que cet écran attend** — celui qu'il faut avoir pour qu'il n'ait
 * plus lieu d'être.
 *
 * ⚠️ À ne pas confondre avec `planUnlockPassModule` : on ACHÈTE le TCF avec le
 * pass Intégral, mais l'accès qui s'ouvre est `hasTcf`. Deux questions
 * différentes, deux tables. Miroir mobile : `planUnlockAccessModule`.
 */
export function planUnlockAccessModule(module: PlanUnlockModule): Module {
  return module === "CIVIQUE" ? "CIVIQUE" : "TCF";
}

/** La page de choix du pass, avec le module mis en avant. */
export function planUnlockPaywallHref(module: PlanUnlockModule): string {
  return `/paiement?module=${planUnlockPassModule(module)}`;
}

/* ------------------------------------------------------------- les mots -- */

export const PLAN_UNLOCK_EYEBROW: Record<PlanUnlockModule, string> = {
  TCF: "Diagnostic terminé",
  CIVIQUE: "Examen civique",
};

export const PLAN_UNLOCK_TITLE: Record<PlanUnlockModule, string> = {
  TCF: "Votre plan de progression est prêt",
  CIVIQUE: "Votre plan de révision est prêt",
};

/**
 * Le sous-titre annonce **le nombre réellement servi**, jamais « 3 ».
 *
 * 🛑 Le serveur plafonne déjà les priorités ; les compter ici sur la liste
 * servie évite d'annoncer trois compétences quand il en reste deux.
 */
export function planUnlockLead(module: PlanUnlockModule, priorites: number): string {
  if (module === "CIVIQUE") {
    return `Vos réponses classent les ${priorites} thématique`
        + `${priorites > 1 ? "s" : ""} officielle${priorites > 1 ? "s" : ""} par urgence.`;
  }
  return `Vos réponses font ressortir ${priorites} compétence`
      + `${priorites > 1 ? "s" : ""} à travailler en priorité.`;
}

/** Le sur-titre de la liste numérotée. */
export const PLAN_UNLOCK_LIST_TITLE: Record<PlanUnlockModule, string> = {
  TCF: "Vos priorités",
  CIVIQUE: "On commence par",
};

/** L'intitulé du héros, à gauche. */
export const PLAN_UNLOCK_HERO_LABEL: Record<PlanUnlockModule, string> = {
  TCF: "Niveau estimé",
  CIVIQUE: "Votre diagnostic",
};

/** Le palier non mesuré s'écrit « — » : `null = inconnu, jamais mauvais`. */
export const PLAN_UNLOCK_LEVEL_UNKNOWN = "—";

/** « Objectif B2 ». `null` quand la démarche n'est pas déclarée. */
export function planUnlockGoalPill(cible: string | null): string | null {
  return cible ? `Objectif ${cible}` : null;
}

/** « Seuil 32 / 40 ». Les deux nombres sont **servis**. */
export function planUnlockSeuilPill(seuil: number, format: number): string {
  return `Seuil ${seuil} / ${format}`;
}

/**
 * **Le ton d'une priorité du Plan** sur cet écran, pour le repli qui lit le
 * Plan au lieu du diagnostic 4 épreuves.
 *
 * 🛑 **Aucun ton ne se dérive d'un compteur ni d'un rang** : il suit la
 * `nature` **servie**, et il suit la doctrine du Plan — le rouge de fragilité
 * (`hot`) est réservé à ce qui a été **observé** fragile, donc une compétence
 * *à acquérir* (rien d'observé) reste `muted`, jamais « à renforcer ». Ce sont
 * le **libellé** et la nature qui les distinguent, pas la seule couleur.
 *
 * Miroir mobile : `planUnlockNatureTone` (`plan_unlock_labels.dart`).
 */
export const PLAN_UNLOCK_NATURE_TONE = {
  A_EVALUER: "muted",
  A_ACQUERIR: "muted",
  A_RENFORCER: "hot",
  A_VERIFIER: "ok",
} as const;

/* ----------------------------------------------- ce que le pass ouvre ---- */

/**
 * Les trois puces du TCF. La première nomme **le nombre servi** de priorités —
 * « ces 3 priorités » sur une liste qui en montre deux serait faux.
 */
export function planUnlockChecksTcf(priorites: number): string[] {
  return [
    `Des entraînements ciblés sur ces ${priorites} priorité${priorites > 1 ? "s" : ""}`,
    "Chaque réponse corrigée et expliquée",
    "Un plan réévalué après chaque session",
  ];
}

/** Les deux faits du civique, sous l'encart des mises en situation. */
export const PLAN_UNLOCK_CHECKS_CIVIQUE: string[] = [
  "Corrections expliquées",
  "Examens blancs 40 questions",
];

/* ------------------------------------------------------------- le prix --- */

/**
 * « À partir de 9,99 € achat unique ».
 *
 * 🛑 `null` ⇒ **aucune ligne de prix**. Le catalogue est injoignable, on se
 * tait : un montant de repli est un prix faux.
 */
export function planUnlockPriceLine(minPrice: number | null): string | null {
  if (minPrice === null) return null;
  return `À partir de ${formatPassPrice(minPrice)} € achat unique`;
}

export const PLAN_UNLOCK_PRICE_NOTE =
    "Sans abonnement ni reconduction automatique";

/* -------------------------------------------------------------- gestes --- */

export const PLAN_UNLOCK_CTA = "Débloquer mon plan";
export const PLAN_UNLOCK_SKIP = "Continuer sans le plan";
