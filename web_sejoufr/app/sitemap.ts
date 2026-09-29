import type { MetadataRoute } from "next";
import { listArticles } from "@/lib/blog/articles";
import { categories } from "@/lib/blog/categories";
import { SITE } from "@/lib/site";

const PAGES_PUBLIQUES: Array<{
  path: string;
  priority: number;
  changeFrequency: MetadataRoute.Sitemap[number]["changeFrequency"];
}> = [
  { path: "/", priority: 1, changeFrequency: "weekly" },
  { path: "/reussir", priority: 0.9, changeFrequency: "monthly" },
  { path: "/diagnostic", priority: 0.9, changeFrequency: "monthly" },
  { path: "/tarifs", priority: 0.8, changeFrequency: "monthly" },
  { path: "/examens-blancs", priority: 0.8, changeFrequency: "monthly" },
  { path: "/blog", priority: 0.8, changeFrequency: "weekly" },
  { path: "/faq", priority: 0.6, changeFrequency: "monthly" },
  { path: "/a-propos", priority: 0.4, changeFrequency: "yearly" },
  { path: "/contact", priority: 0.4, changeFrequency: "yearly" },
  { path: "/cgu", priority: 0.2, changeFrequency: "yearly" },
  { path: "/confidentialite", priority: 0.2, changeFrequency: "yearly" },
  { path: "/mentions-legales", priority: 0.2, changeFrequency: "yearly" },
];

export default function sitemap(): MetadataRoute.Sitemap {
  const articles = listArticles();
  return [
    ...PAGES_PUBLIQUES.map(({ path, priority, changeFrequency }) => ({
      url: `${SITE.url}${path === "/" ? "" : path}`,
      changeFrequency,
      priority,
    })),
    ...categories.map((c) => ({
      url: `${SITE.url}/blog/category/${c.slug}`,
      changeFrequency: "weekly" as const,
      priority: 0.6,
    })),
    ...articles.map((a) => ({
      url: `${SITE.url}/blog/${a.slug}`,
      lastModified: a.updatedAt ?? a.publishedAt,
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
  ];
}
