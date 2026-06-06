import type { ThemeUserResponse } from "./types";

/**
 * Slug d'URL d'un thème civique, dérivé de son code stable en base
 * (CIV_DROITS_DEVOIRS → "droits-devoirs"). Utilisé par les routes
 * /entrainement/civique/[theme] à la place de l'UUID.
 */
export function themeSlug(code: string): string {
  return code.replace(/^CIV_/, "").toLowerCase().replace(/_/g, "-");
}

/**
 * Résout le segment d'URL d'un thème : slug (nouvelles URLs) ou UUID
 * (héritage — retours de session, anciens liens).
 */
export function resolveThemeRef(
  themes: ThemeUserResponse[],
  ref: string,
): ThemeUserResponse | undefined {
  return themes.find((t) => t.id === ref || themeSlug(t.code) === ref);
}
