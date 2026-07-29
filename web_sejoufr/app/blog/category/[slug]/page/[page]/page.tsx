import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { CategoryListView } from "@/components/blog/CategoryListView";
import { categories, getCategoryOrNull } from "@/lib/blog/categories";
import { categoryPageCount, getCategoryPage } from "@/lib/blog/articles";
import type { CategoryMeta } from "@/lib/blog/types";
import { SITE } from "@/lib/site";

interface PageProps {
  params: Promise<{ slug: string; page: string }>;
}

/** Pages 2..N de chaque catégorie — la page 1 vit sur `/blog/category/[slug]`. */
export function generateStaticParams() {
  return categories.flatMap((c) => {
    const total = categoryPageCount(c.slug);
    return Array.from({ length: Math.max(0, total - 1) }, (_, i) => ({
      slug: c.slug,
      page: String(i + 2),
    }));
  });
}

function resolve(
  rawSlug: string,
  rawPage: string,
): { category: CategoryMeta; page: number } | null {
  const category = getCategoryOrNull(rawSlug);
  if (!category) return null;
  if (!/^\d+$/.test(rawPage)) return null;
  const page = Number(rawPage);
  if (page < 2 || page > categoryPageCount(category.slug)) return null;
  return { category, page };
}

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { slug, page: rawPage } = await params;
  const found = resolve(slug, rawPage);
  if (!found) return { title: "Page introuvable" };
  const { category, page } = found;
  const url = `${SITE.url}/blog/category/${category.slug}/page/${page}`;
  return {
    title: `${category.name} — page ${page} — Blog ${SITE.name}`,
    description: category.description,
    alternates: { canonical: `/blog/category/${category.slug}/page/${page}` },
    openGraph: {
      title: `${category.name} — page ${page}`,
      description: category.description,
      url,
      type: "website",
    },
  };
}

export default async function BlogCategoryPaginatedPage({ params }: PageProps) {
  const { slug, page: rawPage } = await params;
  const found = resolve(slug, rawPage);
  if (!found) notFound();
  return (
    <CategoryListView
      category={found.category}
      data={getCategoryPage(found.category.slug, found.page)}
    />
  );
}
