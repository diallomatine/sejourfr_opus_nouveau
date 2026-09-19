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
 * **L'historique des examens blancs d'un thème civique** — 10 créneaux de
 * 20 questions, la page qui existe déjà.
 *
 * 🛑 **Un seul endroit décide de cette adresse.** Elle s'écrivait à la main
 * dans `lib/dashboard.ts`, dans l'en-tête de la page de séries et, depuis le
 * 2026-09-19, sur la ligne de thème de l'Accueil : la 3ᵉ occurrence était de la
 * dette. Miroir mobile : `AppRoutes.civiqueThemeExamsPath`.
 *
 * ⚠️ Elle prend le **segment d'URL**, pas le code : l'appelant passe
 * `themeSlug(code)` quand il tient un code, et son `ref` hérité (un UUID de
 * retour de session) quand il n'a que ça — c'est `resolveThemeRef` qui résout
 * les deux, et cette fonction n'a pas à choisir pour lui.
 */
export function civicThemeExamsHref(ref: string): string {
  return `/entrainement/civique/${ref}/examens`;
}

/**
 * **« Vos résultats » d'un thème civique** — le pendant civique de
 * `/historique/epreuve/[domaine]`.
 *
 * 🛑 **À ne pas confondre avec `civicThemeExamsHref`** : là on **passe** un
 * examen, ici on **lit** ses résultats. C'est cette adresse que porte « Voir
 * mes résultats » sur l'Accueil ; la grille d'examens est le lien de pied de
 * l'écran d'arrivée.
 *
 * ⚠️ Elle prend le **segment d'URL** comme sa voisine : l'appelant passe
 * `themeSlug(code)` quand il tient un code, son `ref` hérité sinon.
 * Miroir mobile : `AppRoutes.themeHistoriquePath`.
 */
export function themeHistoriqueHref(ref: string): string {
  return `/historique/theme/${ref}`;
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
