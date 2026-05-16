import "server-only";
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import readingTime from "reading-time";
import type {
  Article,
  ArticleFrontmatter,
  ArticleListItem,
  ArticleCategorySlug,
} from "./types";

const ARTICLES_DIR = path.join(process.cwd(), "content", "articles");

let cache: Article[] | null = null;

/**
 * Lit tous les .mdx du dossier `content/articles` et les renvoie triés
 * par date de publication décroissante. Le résultat est mémoïsé au sein
 * du process Node (utile au build SSG, pas un cache HTTP).
 */
export function readArticles(): Article[] {
  if (cache) return cache;

  if (!fs.existsSync(ARTICLES_DIR)) {
    cache = [];
    return cache;
  }

  const files = fs
    .readdirSync(ARTICLES_DIR)
    .filter((f) => f.endsWith(".mdx"));

  const articles = files.map((file) => {
    const full = path.join(ARTICLES_DIR, file);
    const raw = fs.readFileSync(full, "utf8");
    const { data, content } = matter(raw);
    const fm = data as ArticleFrontmatter;
    const stats = readingTime(content);
    return {
      ...fm,
      content,
      readingTimeMinutes: Math.max(1, Math.round(stats.minutes)),
    } satisfies Article;
  });

  articles.sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
  cache = articles;
  return articles;
}

export function listArticles(): ArticleListItem[] {
  return readArticles().map(({ content: _content, ...rest }) => rest);
}

export function getArticleBySlug(slug: string): Article | null {
  return readArticles().find((a) => a.slug === slug) ?? null;
}

export function getArticlesByCategory(
  category: ArticleCategorySlug,
): ArticleListItem[] {
  return listArticles().filter((a) => a.category === category);
}

/**
 * Articles « liés » : même catégorie d'abord, complétés par les plus récents
 * d'autres catégories pour atteindre `limit`.
 */
export function getRelatedArticles(
  current: { slug: string; category: ArticleCategorySlug },
  limit = 3,
): ArticleListItem[] {
  const all = listArticles().filter((a) => a.slug !== current.slug);
  const sameCat = all.filter((a) => a.category === current.category);
  const others = all.filter((a) => a.category !== current.category);
  return [...sameCat, ...others].slice(0, limit);
}

export function getAllSlugs(): string[] {
  return readArticles().map((a) => a.slug);
}
