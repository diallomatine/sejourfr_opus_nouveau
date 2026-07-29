import categoriesJson from "@/content/categories.json";
import type {
  ArticleCategorySlug,
  CategoryColor,
  CategoryMeta,
} from "./types";

const raw = categoriesJson as Record<ArticleCategorySlug, CategoryMeta>;

export const categories: CategoryMeta[] = Object.values(raw);

export function getCategory(slug: ArticleCategorySlug): CategoryMeta {
  return raw[slug];
}

export function getCategoryOrNull(slug: string): CategoryMeta | null {
  return raw[slug as ArticleCategorySlug] ?? null;
}

/**
 * Variables CSS communes à toutes les surfaces d'une catégorie. Les valeurs
 * sont injectées via `style` (ou utilisées dans les `<style>` JSX) — pas de
 * Tailwind utility-first dans le markup côté web.
 */
export interface CategoryTone {
  /** Couleur principale (texte / accents). */
  fg: string;
  /** Fond de badge léger (alpha sur fg). */
  badgeBg: string;
  /** Gradient start (cover). */
  coverFrom: string;
  /** Gradient end (cover). */
  coverTo: string;
  /** Couleur du point indicateur. */
  dot: string;
}

export function categoryTone(color: CategoryColor): CategoryTone {
  switch (color) {
    case "blue":
      return {
        fg: "var(--color-blue)",
        badgeBg: "rgba(30, 58, 140, 0.10)",
        coverFrom: "var(--color-blue)",
        coverTo: "var(--color-ink-2)",
        dot: "var(--color-blue)",
      };
    case "red":
      return {
        fg: "var(--color-red)",
        badgeBg: "rgba(225, 55, 47, 0.10)",
        coverFrom: "var(--color-red)",
        coverTo: "#9a1c16",
        dot: "var(--color-red)",
      };
    case "amber":
      return {
        fg: "#8a5d00",
        badgeBg: "rgba(232, 163, 23, 0.16)",
        coverFrom: "var(--color-amber)",
        coverTo: "#b46e00",
        dot: "var(--color-amber)",
      };
    case "indigo":
      return {
        fg: "#4338ca",
        badgeBg: "rgba(67, 56, 202, 0.10)",
        coverFrom: "#6366f1",
        coverTo: "#7c3aed",
        dot: "#6366f1",
      };
    case "green":
      return {
        fg: "var(--color-green)",
        badgeBg: "rgba(22, 143, 91, 0.12)",
        coverFrom: "var(--color-green)",
        coverTo: "#0c5f3c",
        dot: "var(--color-green)",
      };
  }
}
