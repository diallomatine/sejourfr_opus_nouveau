// Helpers partagés entre /dashboard et /recommandations (catégories du
// GET /api/me/dashboard).

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
        ? `/entrainement/civique/${cat.themeId}`
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
        ? `/entrainement/civique/${cat.themeId}/examens`
        : "/examens-blancs";
  }
}

/** Teinte d'une barre de progression : vert ≥ 80, ambre < 60, bleu entre les deux. */
export function barTone(percent: number | null): "green" | "amber" | "blue" {
  if (percent === null) return "blue";
  if (percent >= 80) return "green";
  if (percent < 60) return "amber";
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

/** Sous-titre qualitatif d'un score de maîtrise. */
export function masteryHint(percent: number | null): string {
  if (percent === null) return "Commencez l'entraînement";
  if (percent >= 75) return "Excellent niveau";
  if (percent >= 55) return "En bonne voie";
  return "À consolider";
}

/** Statut d'une catégorie (badge des hubs) : Solide ≥ 80, En bonne voie ≥ 60,
 *  À renforcer en dessous, À découvrir si jamais travaillée. */
export function categoryStatus(percent: number | null): {
  label: string;
  tone: "green" | "blue" | "amber" | "none";
} {
  if (percent === null) return { label: "À découvrir", tone: "none" };
  if (percent >= 80) return { label: "Solide", tone: "green" };
  if (percent >= 60) return { label: "En bonne voie", tone: "blue" };
  return { label: "À renforcer", tone: "amber" };
}
