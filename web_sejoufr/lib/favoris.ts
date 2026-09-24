/**
 * « Mes favoris » (`/favoris`), ouvert depuis le Profil : les questions que le
 * candidat a épinglées pendant un entraînement.
 *
 * 🛑 **Miroir mot pour mot** de
 * `mobile_sejourfr/lib/screens/favoris/favoris_labels.dart` (et, pour le détail
 * — « DÉTAIL · X », « PASSAGE », « EXPLICATION » —, de `QuestionDetailSheet`).
 * Un texte qui bouge ici bouge là-bas dans la même passe.
 *
 * Remplace `/revision` (« Mes erreurs / Mes favoris »), supprimé le 2026-09-24
 * avec la liste des erreurs (décision du propriétaire : la progression suffit
 * pour voir son avancement). `/revision` redirige ici (`next.config.ts`).
 */

import type { Module } from "./types";

export const FAVORIS_HREF = "/favoris";

export const FAVORIS_TITLE = "Mes favoris";
export const FAVORIS_LEAD = "Retrouvez les questions que vous avez marquées.";
/** Sous-titre de la ligne du Profil. */
export const FAVORIS_ROW_SUB = "Questions épinglées pendant l'entraînement";

export const FAVORIS_MODULE_LABEL: Record<Module, string> = {
  CIVIQUE: "Civique",
  TCF: "TCF",
};

export const FAVORIS_EMPTY_TITLE = "Aucun favori";
export const FAVORIS_EMPTY_HINT =
  "Pendant un entraînement, appuyez sur l'icône marque-page pour épingler une question.";
export const FAVORIS_EMPTY_CTA = "Lancer un entraînement";
export const FAVORIS_LOAD_ERROR = "Impossible de charger vos favoris.";
export const FAVORIS_RETRY = "Réessayer";

/** Taille de fenêtre de la liste, et palier du bouton « Afficher plus ». */
export const FAVORIS_PAGE_SIZE = 20;

export function favorisShowMore(remaining: number): string {
  return `Afficher plus (${remaining} restante${remaining > 1 ? "s" : ""})`;
}

// ── Détail d'un favori ──────────────────────────────────────────────────
export function favoriDetailEyebrow(module: Module): string {
  return `DÉTAIL · ${module}`;
}
export const FAVORI_ON = "Favori";
export const FAVORI_ADD = "Ajouter aux favoris";
export const FAVORI_PASSAGE = "PASSAGE";
export const FAVORI_EXPLICATION = "EXPLICATION";
export const FAVORI_DETAIL_ERROR = "Impossible de charger la correction.";
