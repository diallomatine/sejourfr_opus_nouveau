export type ArticleCategorySlug =
  | "titre-de-sejour"
  | "naturalisation"
  | "actualite"
  | "conseils";

export type CategoryColor = "blue" | "red" | "amber" | "indigo";

export interface CategoryMeta {
  name: string;
  slug: ArticleCategorySlug;
  color: CategoryColor;
  description: string;
}

export interface Author {
  name: string;
  role: string;
  initials: string;
}

export interface ArticleSeo {
  title: string;
  description: string;
}

export interface ArticleFrontmatter {
  title: string;
  slug: string;
  category: ArticleCategorySlug;
  excerpt: string;
  publishedAt: string;
  updatedAt?: string;
  author: Author;
  coverImage?: string;
  coverIcon?: string;
  tags: string[];
  seo?: ArticleSeo;
}

export interface Article extends ArticleFrontmatter {
  readingTimeMinutes: number;
  /** Contenu MDX brut (string), prêt à être passé à MDXRemote. */
  content: string;
}

export type ArticleListItem = Omit<Article, "content">;
