import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { CategoryListView } from "@/components/blog/CategoryListView";
import { categories, getCategoryOrNull } from "@/lib/blog/categories";
import { getCategoryPage } from "@/lib/blog/articles";
import { SITE } from "@/lib/site";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export function generateStaticParams() {
  return categories.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const cat = getCategoryOrNull(slug);
  if (!cat) return { title: "Catégorie introuvable" };
  return {
    title: `${cat.name} — Blog ${SITE.name}`,
    description: cat.description,
    alternates: { canonical: `/blog/category/${cat.slug}` },
    openGraph: {
      title: `${cat.name} — Blog ${SITE.name}`,
      description: cat.description,
      url: `${SITE.url}/blog/category/${cat.slug}`,
      type: "website",
    },
  };
}

export default async function BlogCategoryPage({ params }: PageProps) {
  const { slug } = await params;
  const cat = getCategoryOrNull(slug);
  if (!cat) notFound();
  return <CategoryListView category={cat} data={getCategoryPage(cat.slug, 1)} />;
}
