// Helpers partagés entre /dashboard et /recommandations (catégories du
// GET /api/me/dashboard).

import { themeSlug } from "./themes";
import type { DashboardCategoryStat } from "./types";

/** Route d'entraînement d'une catégorie (CTA "Réviser"). */
export function categoryHref(cat: DashboardCategoryStat): string {
  switch (cat.code) {
    case "TCF_CO":
      return "/entrainement/tcf/co";
    case "TCF_CE":
      return "/entrainement/tcf/ce";
    case "TCF_STRUCTURE":
      return "/entrainement/tcf/structure";
    case "TCF_EE":
      return "/entrainement/tcf/ee";
    case "TCF_EO":
      return "/entrainement/tcf/eo";
    default:
      return cat.themeId
        ? `/entrainement/civique/${themeSlug(cat.code)}`
        : "/entrainement?module=CIVIQUE";
  }
}

/** Page d'examens blancs d'une catégorie (pendant de categoryHref). */
export function categoryExamsHref(cat: DashboardCategoryStat): string {
  switch (cat.code) {
    case "TCF_CO":
      return "/entrainement/tcf/co/examens";
    case "TCF_CE":
      return "/entrainement/tcf/ce/examens";
    case "TCF_STRUCTURE":
      return "/entrainement/tcf/structure/examens";
    case "TCF_EE":
      return "/entrainement/tcf/ee/examens";
    case "TCF_EO":
      return "/entrainement/tcf/eo/examens";
    default:
      return cat.themeId
        ? `/entrainement/civique/${themeSlug(cat.code)}/examens`
        : "/examens-blancs";
  }
}

/**
 * Teinte d'une barre de progression — **un accent de marque, pas un verdict**.
 *
 * 🛑 Elle classait le pourcentage (vert ≥ 80, ambre < 60, bleu entre les deux)
 * jusqu'au 2026-08-23. Supprimé : un ton se dérive d'un **état servi**, jamais
 * d'un nombre (moteur de progression V4.2, §25 bis.3, invariant I42). Une
 * seconde table de seuils dans le front finit toujours par peindre autre chose
 * que ce que le serveur a décidé.
 *
 * La fonction reste — un seul endroit décide de cette teinte, et c'est ici.
 */
export function barTone(): "green" | "amber" | "blue" {
  return "blue";
}

/** Moyenne des pourcentages renseignés d'un module (null si aucun). */
export function moduleAverage(cats: DashboardCategoryStat[]): number | null {
  const known = cats.filter((c) => c.percent !== null);
  if (known.length === 0) return null;
  return Math.round(
    known.reduce((sum, c) => sum + (c.percent ?? 0), 0) / known.length,
  );
}

/**
 * Sous-titre d'un taux de réussite — **il dit d'où vient le chiffre, il ne le
 * juge pas**.
 *
 * 🛑 Il rendait « Excellent niveau » / « En bonne voie » / « À consolider »
 * selon des seuils locaux. Supprimé le 2026-08-23 : un état pédagogique vient
 * servi ou n'existe pas (§25 bis.3). Le pourcentage affiché ici est un taux de
 * bonnes réponses, pas un score TCF ni une probabilité de réussite.
 */
export function successHint(percent: number | null): string {
  return percent === null
    ? "Commencez l'entraînement"
    : "sur vos réponses enregistrées";
}

/**
 * Badge d'une catégorie dans les hubs — **le seul fait qu'il énonce, c'est si
 * la catégorie a déjà été travaillée**.
 *
 * 🛑 Il rendait « Solide » ≥ 80, « En bonne voie » ≥ 60, « À renforcer » en
 * dessous : trois verdicts pédagogiques calculés dans le navigateur à partir
 * d'un taux de bonnes réponses. Supprimé le 2026-08-23 (§25 bis.3, §25 bis.4).
 *
 * Le vrai état — « À renforcer », « En progression », « Prêt à vérifier »,
 * « Acquis », « À vérifier » — viendra du serveur avec le moteur de
 * progression, avec son ton (`lib/progression-contract.ts`). D'ici là, on
 * n'invente rien : un chiffre brut ne dit pas où en est un candidat.
 */
export function categoryBadge(percent: number | null): {
  label: string;
  tone: "green" | "blue" | "amber" | "none";
} {
  return percent === null
    ? { label: "À découvrir", tone: "none" }
    : { label: "Déjà travaillé", tone: "blue" };
}
