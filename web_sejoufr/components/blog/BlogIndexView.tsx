import { ArticleCard } from "@/components/blog/ArticleCard";
import { FeaturedArticleCard } from "@/components/blog/FeaturedArticleCard";
import { CategoryFilter } from "@/components/blog/CategoryFilter";
import { BlogCategoryDropdown } from "@/components/blog/BlogCategoryDropdown";
import { NewsletterCTA } from "@/components/blog/NewsletterCTA";
import { Pagination } from "@/components/blog/Pagination";
import type { PagedArticles } from "@/lib/blog/articles";
import { SITE } from "@/lib/site";
import { safeJsonLd } from "@/lib/security";

export const BLOG_INDEX_DESCRIPTION =
  "Articles, guides et actualités juridiques pour réussir votre examen civique, votre TCF IRN, votre demande de titre de séjour et votre naturalisation française.";

/**
 * Corps de l'index /blog, partagé par la page 1 (`/blog`) et les pages
 * suivantes (`/blog/page/[page]`). L'article à la une n'existe qu'en page 1
 * (cf. `getBlogPage`).
 */
export function BlogIndexView({ data }: { data: PagedArticles }) {
  const { featured, items, page, totalPages } = data;
  const visible = featured ? [featured, ...items] : items;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Blog",
    name: `Blog ${SITE.name}`,
    description: BLOG_INDEX_DESCRIPTION,
    url: `${SITE.url}/blog`,
    blogPost: visible.map((a) => ({
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
          pour préparer votre examen civique, votre TCF IRN, votre titre de
          séjour ou votre naturalisation.
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

      {visible.length === 0 ? (
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

          {items.length > 0 && (
            <section aria-label="Tous les articles" className="blog-index-rest">
              <div className="blog-index-rest-head">
                <h2 className="blog-index-rest-title">Tous les articles</h2>
                {totalPages > 1 && (
                  <p className="blog-index-rest-count">
                    Page {page} sur {totalPages}
                  </p>
                )}
              </div>
              <div className="blog-index-grid">
                {items.map((a) => (
                  <ArticleCard key={a.slug} article={a} />
                ))}
              </div>
              <Pagination
                page={page}
                totalPages={totalPages}
                basePath="/blog"
              />
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
        .blog-index-rest-head {
          display: flex;
          align-items: baseline;
          justify-content: space-between;
          gap: 12px;
          flex-wrap: wrap;
          margin-bottom: 22px;
        }
        .blog-index-rest-title {
          margin: 0;
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
        .blog-index-rest-count {
          margin: 0;
          font-family: var(--font-mono);
          font-size: 12px;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          color: var(--color-muted);
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
