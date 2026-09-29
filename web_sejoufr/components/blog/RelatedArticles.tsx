import type { ArticleListItem } from "@/lib/blog/types";
import { ArticleCard } from "./ArticleCard";

interface Props {
  articles: ArticleListItem[];
}

export function RelatedArticles({ articles }: Props) {
  if (articles.length === 0) return null;

  return (
    <section className="related-articles">
      <h2 className="related-articles-title">À lire aussi</h2>
      <div className="related-articles-grid">
        {articles.map((a) => (
          <ArticleCard key={a.slug} article={a} />
        ))}
      </div>
      <style>{`
        .related-articles {
          margin-top: 56px;
          padding-top: 40px;
          border-top: 1px solid var(--color-line);
        }
        @media (min-width: 1024px) {
          .related-articles {
            margin-top: 72px;
            padding-top: 48px;
          }
        }
        .related-articles-title {
          margin: 0 0 24px 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          font-size: 24px;
          line-height: 1.2;
          color: var(--color-ink);
        }
        @media (min-width: 1024px) {
          .related-articles-title {
            font-size: 30px;
          }
        }
        .related-articles-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 20px;
        }
        @media (min-width: 640px) {
          .related-articles-grid {
            grid-template-columns: repeat(2, 1fr);
          }
        }
        @media (min-width: 1024px) {
          .related-articles-grid {
            grid-template-columns: repeat(3, 1fr);
            gap: 24px;
          }
        }
      `}</style>
    </section>
  );
}
