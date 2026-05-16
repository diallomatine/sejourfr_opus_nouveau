import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { ArticleCard } from "@/components/blog/ArticleCard";
import { CategoryFilter } from "@/components/blog/CategoryFilter";
import { BlogCategoryDropdown } from "@/components/blog/BlogCategoryDropdown";
import { NewsletterCTA } from "@/components/blog/NewsletterCTA";
import { categories, getCategoryOrNull } from "@/lib/blog/categories";
import { getArticlesByCategory } from "@/lib/blog/articles";
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
  const articles = getArticlesByCategory(cat.slug);

  return (
    <div className="blog-cat container-x">
      <header className="blog-cat-header">
        <p className="eyebrow blog-cat-eyebrow">Catégorie</p>
        <h1 className="blog-cat-title">{cat.name}</h1>
        <p className="blog-cat-desc">{cat.description}</p>
      </header>

      <div className="blog-cat-filter">
        <div className="blog-cat-filter-mobile">
          <BlogCategoryDropdown active={cat.slug} />
        </div>
        <div className="blog-cat-filter-desktop">
          <CategoryFilter active={cat.slug} />
        </div>
      </div>

      {articles.length === 0 ? (
        <div className="blog-cat-empty">
          Aucun article dans cette catégorie pour le moment.
        </div>
      ) : (
        <div className="blog-cat-grid">
          {articles.map((a) => (
            <ArticleCard key={a.slug} article={a} />
          ))}
        </div>
      )}

      <section className="blog-cat-newsletter">
        <NewsletterCTA source={`blog-cat-${cat.slug}`} />
      </section>

      <style>{`
        .blog-cat {
          padding-top: 36px;
          padding-bottom: 72px;
        }
        @media (min-width: 768px) {
          .blog-cat {
            padding-top: 52px;
            padding-bottom: 96px;
          }
        }
        .blog-cat-header {
          margin-bottom: 36px;
        }
        @media (min-width: 1024px) {
          .blog-cat-header {
            margin-bottom: 44px;
          }
        }
        .blog-cat-eyebrow {
          margin: 0 0 10px 0;
        }
        .blog-cat-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          line-height: 1.1;
          font-size: 32px;
          color: var(--color-ink);
        }
        @media (min-width: 768px) {
          .blog-cat-title {
            font-size: 40px;
          }
        }
        @media (min-width: 1024px) {
          .blog-cat-title {
            font-size: 48px;
          }
        }
        .blog-cat-desc {
          margin: 14px 0 0 0;
          font-size: 16px;
          line-height: 1.55;
          color: var(--color-muted);
          max-width: 60ch;
        }
        @media (min-width: 1024px) {
          .blog-cat-desc {
            font-size: 18px;
          }
        }
        .blog-cat-filter {
          margin-bottom: 32px;
        }
        .blog-cat-filter-desktop {
          display: none;
        }
        @media (min-width: 1024px) {
          .blog-cat-filter-mobile {
            display: none;
          }
          .blog-cat-filter-desktop {
            display: block;
          }
        }
        .blog-cat-empty {
          border: 1px dashed var(--color-line);
          border-radius: 20px;
          padding: 48px 20px;
          text-align: center;
          color: var(--color-muted);
        }
        .blog-cat-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 20px;
        }
        @media (min-width: 640px) {
          .blog-cat-grid {
            grid-template-columns: repeat(2, 1fr);
          }
        }
        @media (min-width: 1024px) {
          .blog-cat-grid {
            grid-template-columns: repeat(3, 1fr);
            gap: 24px;
          }
        }
        .blog-cat-newsletter {
          margin-top: 56px;
        }
        @media (min-width: 1024px) {
          .blog-cat-newsletter {
            margin-top: 72px;
          }
        }
      `}</style>
    </div>
  );
}
