// Données statiques des catégories des modules civique et naturalisation.
//
// L'ancien projet récupérait ces catégories via les endpoints
// `/api/modules/{moduleType}/categories` qui n'existent plus côté backend
// Spring du nouveau projet (les "thématiques" y vivent dans `/api/themes`
// mais nécessitent une authentification).
//
// Comme ces deux landings sont publiques (vitrine marketing), on hardcode
// ici les 5 catégories de référence — alignées sur le seed Flyway
// `db/migration/10_reference/V100__seed_reference.sql` (5 thèmes CIVIQUE).
// Si un nouveau thème est ajouté côté backend, mettre à jour cette liste.

export type LandingModuleType = "CIVIQUE" | "NATURALISATION";

export interface LandingCategory {
  /** Identifiant stable utilisé comme key React. */
  id: string;
  /** Slug utilisé dans l'URL `/civique/[slug]` et `/naturalisation/[slug]`. */
  slug: string;
  name: string;
  description: string;
  emoji: string;
  /** Nombre de questions disponibles dans la catégorie (vitrine). */
  questionCount: number;
}

const CIVIQUE_CATEGORIES: LandingCategory[] = [
  {
    id: "civique-principes",
    slug: "principes",
    name: "Principes et valeurs de la République",
    description: "Devise, symboles, laïcité, liberté, égalité, fraternité",
    emoji: "🇫🇷",
    questionCount: 42,
  },
  {
    id: "civique-institutions",
    slug: "institutions",
    name: "Système institutionnel et politique",
    description: "Constitution, président, parlement, séparation des pouvoirs",
    emoji: "🏛️",
    questionCount: 58,
  },
  {
    id: "civique-droits-devoirs",
    slug: "droits-devoirs",
    name: "Droits et devoirs",
    description: "Charte des droits et devoirs du citoyen français",
    emoji: "⚖️",
    questionCount: 36,
  },
  {
    id: "civique-histoire-geo",
    slug: "histoire-geo",
    name: "Histoire, géographie et culture",
    description: "Repères historiques, géographie, patrimoine culturel",
    emoji: "🗺️",
    questionCount: 64,
  },
  {
    id: "civique-societe",
    slug: "societe",
    name: "Vivre dans la société française",
    description: "Vie quotidienne, services publics, vivre-ensemble",
    emoji: "🤝",
    questionCount: 40,
  },
];

const NATURALISATION_CATEGORIES: LandingCategory[] = [
  {
    id: "nat-principes",
    slug: "principes",
    name: "Valeurs et principes de la République",
    description: "Devise, symboles, laïcité, liberté, égalité, fraternité",
    emoji: "🇫🇷",
    questionCount: 48,
  },
  {
    id: "nat-institutions",
    slug: "institutions",
    name: "Institutions et vie politique",
    description: "Constitution, président, parlement, élections, séparation des pouvoirs",
    emoji: "🏛️",
    questionCount: 62,
  },
  {
    id: "nat-droits-devoirs",
    slug: "droits-devoirs",
    name: "Droits et devoirs du citoyen",
    description: "Charte des droits et devoirs, libertés fondamentales",
    emoji: "⚖️",
    questionCount: 44,
  },
  {
    id: "nat-histoire-culture",
    slug: "histoire-culture",
    name: "Histoire et culture françaises",
    description: "Grandes dates, personnages, patrimoine, géographie",
    emoji: "🗺️",
    questionCount: 72,
  },
  {
    id: "nat-societe",
    slug: "societe",
    name: "Vie en société",
    description: "Quotidien, services publics, santé, école, vivre-ensemble",
    emoji: "🤝",
    questionCount: 46,
  },
];

export const MODULE_CATEGORIES: Record<LandingModuleType, LandingCategory[]> = {
  CIVIQUE: CIVIQUE_CATEGORIES,
  NATURALISATION: NATURALISATION_CATEGORIES,
};

export function getCategories(moduleType: LandingModuleType): LandingCategory[] {
  return MODULE_CATEGORIES[moduleType];
}

export function getCategory(
  moduleType: LandingModuleType,
  slug: string,
): LandingCategory | null {
  return MODULE_CATEGORIES[moduleType].find((c) => c.slug === slug) ?? null;
}

export function getValidSlugs(moduleType: LandingModuleType): string[] {
  return MODULE_CATEGORIES[moduleType].map((c) => c.slug);
}

/** Total examens blancs (constante de marque, alignée avec l'ancien projet). */
export const TOTAL_MOCK_EXAMS = 20;
