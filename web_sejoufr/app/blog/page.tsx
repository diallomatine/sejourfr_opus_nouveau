import type { Metadata } from "next";
import { ArticleCard } from "@/components/blog/ArticleCard";
import { FeaturedArticleCard } from "@/components/blog/FeaturedArticleCard";
import { CategoryFilter } from "@/components/blog/CategoryFilter";
import { BlogCategoryDropdown } from "@/components/blog/BlogCategoryDropdown";
import { NewsletterCTA } from "@/components/blog/NewsletterCTA";
import { listArticles } from "@/lib/blog/articles";
import { SITE } from "@/lib/site";
import { safeJsonLd } from "@/lib/security";

const PAGE_DESCRIPTION =
  "Articles, guides et actualités juridiques pour réussir votre examen civique, votre demande de titre de séjour et votre naturalisation française.";

export const metadata: Metadata = {
  title: "Blog — Examen civique, titre de séjour, naturalisation",
  description: PAGE_DESCRIPTION,
  alternates: { canonical: "/blog" },
  openGraph: {
    title: `Blog ${SITE.name}`,
    description:
      "Guides et actualités pour titre de séjour, naturalisation et examen civique.",
    url: `${SITE.url}/blog`,
    type: "website",
  },
};

export default function BlogIndexPage() {
  const articles = listArticles();
  const [featured, ...rest] = articles;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Blog",
    name: `Blog ${SITE.name}`,
    description: PAGE_DESCRIPTION,
    url: `${SITE.url}/blog`,
    blogPost: articles.map((a) => ({
      "@type": "BlogPosting",
      headline: a.title,
      description: a.excerpt,
      url: `${SITE.url}/blog/${a.slug}`,
      datePublished: a.publishedAt,
      dateModified: a.updatedAt ?? a.publishedAt,
      author: { "@type": "Person", name: a.author.name },
    })),
  };

  return (
    <div className="blog-index container-x">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLd(jsonLd) }}
      />

      <header className="blog-index-header">
        <p className="eyebrow blog-index-eyebrow">Le blog {SITE.name}</p>
        <h1 className="blog-index-title editorial">
          Comprendre vos démarches.
          <br />
          <em>Sans jargon.</em>
        </h1>
        <p className="blog-index-subtitle">
          Guides, décryptages d&apos;actualités juridiques et conseils concrets
          pour préparer votre examen civique, votre titre de séjour ou votre
          naturalisation.
        </p>
      </header>

      <div className="blog-index-filter">
        <div className="blog-index-filter-mobile">
          <BlogCategoryDropdown active="all" />
        </div>
        <div className="blog-index-filter-desktop">
          <CategoryFilter active="all" />
        </div>
      </div>

      {articles.length === 0 ? (
        <div className="blog-index-empty">
          Aucun article publié pour le moment. Revenez bientôt !
        </div>
      ) : (
        <>
          {featured && (
            <section
              aria-labelledby="featured-heading"
              className="blog-index-featured"
            >
              <h2 id="featured-heading" className="sr-only">
                Article à la une
              </h2>
              <FeaturedArticleCard article={featured} />
            </section>
          )}

          {rest.length > 0 && (
            <section
              aria-label="Tous les articles"
              className="blog-index-rest"
            >
              <h2 className="blog-index-rest-title">Tous les articles</h2>
              <div className="blog-index-grid">
                {rest.map((a) => (
                  <ArticleCard key={a.slug} article={a} />
                ))}
              </div>
            </section>
          )}
        </>
      )}

      <section className="blog-index-newsletter">
        <NewsletterCTA source="blog-index" />
      </section>

      <style>{`
        .blog-index {
          padding-top: 36px;
          padding-bottom: 72px;
        }
        @media (min-width: 768px) {
          .blog-index {
            padding-top: 52px;
            padding-bottom: 96px;
          }
        }
        .blog-index-header {
          margin-bottom: 36px;
        }
        @media (min-width: 1024px) {
          .blog-index-header {
            margin-bottom: 52px;
          }
        }
        .blog-index-eyebrow {
          margin: 0 0 10px 0;
        }
        .blog-index-title {
          margin: 0;
          font-size: 38px;
          color: var(--color-ink);
        }
        @media (min-width: 768px) {
          .blog-index-title {
            font-size: 52px;
          }
        }
        @media (min-width: 1024px) {
          .blog-index-title {
            font-size: 64px;
          }
        }
        .blog-index-subtitle {
          margin: 18px 0 0 0;
          font-size: 17px;
          line-height: 1.55;
          color: var(--color-muted);
          max-width: 60ch;
        }
        @media (min-width: 1024px) {
          .blog-index-subtitle {
            font-size: 19px;
          }
        }
        .blog-index-filter {
          margin-bottom: 32px;
        }
        @media (min-width: 1024px) {
          .blog-index-filter {
            margin-bottom: 40px;
          }
        }
        .blog-index-filter-desktop {
          display: none;
        }
        @media (min-width: 1024px) {
          .blog-index-filter-mobile {
            display: none;
          }
          .blog-index-filter-desktop {
            display: block;
          }
        }
        .blog-index-empty {
          border: 1px dashed var(--color-line);
          border-radius: 20px;
          padding: 48px 20px;
          text-align: center;
          color: var(--color-muted);
        }
        .blog-index-featured {
          margin-bottom: 44px;
        }
        @media (min-width: 1024px) {
          .blog-index-featured {
            margin-bottom: 56px;
          }
        }
        .blog-index-rest-title {
          margin: 0 0 22px 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          font-size: 22px;
          line-height: 1.2;
          color: var(--color-ink);
        }
        @media (min-width: 1024px) {
          .blog-index-rest-title {
            font-size: 26px;
          }
        }
        .blog-index-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 20px;
        }
        @media (min-width: 640px) {
          .blog-index-grid {
            grid-template-columns: repeat(2, 1fr);
          }
        }
        @media (min-width: 1024px) {
          .blog-index-grid {
            grid-template-columns: repeat(3, 1fr);
            gap: 24px;
          }
        }
        .blog-index-newsletter {
          margin-top: 56px;
        }
        @media (min-width: 1024px) {
          .blog-index-newsletter {
            margin-top: 72px;
          }
        }
        .sr-only {
          position: absolute;
          width: 1px;
          height: 1px;
          padding: 0;
          margin: -1px;
          overflow: hidden;
          clip: rect(0, 0, 0, 0);
          white-space: nowrap;
          border: 0;
        }
      `}</style>
    </div>
  );
}
