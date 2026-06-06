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
