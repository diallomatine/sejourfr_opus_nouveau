import type { Metadata } from "next";
import { notFound } from "next/navigation";
import {
  BlogIndexView,
  BLOG_INDEX_DESCRIPTION,
} from "@/components/blog/BlogIndexView";
import { blogPageCount, getBlogPage } from "@/lib/blog/articles";
import { SITE } from "@/lib/site";

interface PageProps {
  params: Promise<{ page: string }>;
}

/** Pages 2..N — la page 1 vit sur `/blog` (pas de doublon d'URL). */
export function generateStaticParams() {
  const total = blogPageCount();
  return Array.from({ length: Math.max(0, total - 1) }, (_, i) => ({
    page: String(i + 2),
  }));
}

function parsePage(raw: string): number | null {
  if (!/^\d+$/.test(raw)) return null;
  const page = Number(raw);
  if (page < 2 || page > blogPageCount()) return null;
  return page;
}

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { page: raw } = await params;
  const page = parsePage(raw);
  if (!page) return { title: "Page introuvable" };
  return {
    title: `Blog — page ${page}`,
    description: BLOG_INDEX_DESCRIPTION,
    alternates: { canonical: `/blog/page/${page}` },
    openGraph: {
      title: `Blog ${SITE.name} — page ${page}`,
      description: BLOG_INDEX_DESCRIPTION,
      url: `${SITE.url}/blog/page/${page}`,
      type: "website",
    },
  };
}

export default async function BlogIndexPaginatedPage({ params }: PageProps) {
  const { page: raw } = await params;
  const page = parsePage(raw);
  if (!page) notFound();
  return <BlogIndexView data={getBlogPage(page)} />;
}
