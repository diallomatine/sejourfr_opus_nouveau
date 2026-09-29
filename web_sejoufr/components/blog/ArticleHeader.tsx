import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import type { Article } from "@/lib/blog/types";
import { CategoryBadge } from "./CategoryBadge";
import { CoverIllustration } from "./CoverIllustration";
import { ArticleByline } from "./ArticleByline";

export function ArticleHeader({ article }: { article: Article }) {
  return (
    <header className="article-header">
      <div className="article-header-back">
        <Link href="/blog" className="article-header-back-link">
          <ArrowLeft className="article-header-back-icon" />
          Retour au blog
        </Link>
      </div>

      <div className="article-header-badge">
        <CategoryBadge slug={article.category} asLink size="md" />
      </div>

      <h1 className="article-header-title">{article.title}</h1>

      <p className="article-header-excerpt">{article.excerpt}</p>

      <div className="article-header-byline">
        <ArticleByline article={article} />
      </div>

      <div className="article-header-cover">
        <CoverIllustration
          category={article.category}
          iconKey={article.coverIcon}
          variant="hero"
          title={article.title}
          imageUrl={article.coverImage}
          imageAlt={article.title}
        />
      </div>

      <style>{`
        .article-header {
          margin-bottom: 36px;
        }
        @media (min-width: 1024px) {
          .article-header {
            margin-bottom: 44px;
          }
        }
        .article-header-back {
          margin-bottom: 18px;
        }
        .article-header-back-link {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          font-size: 13.5px;
          color: var(--color-muted);
          transition: color 0.15s;
          text-decoration: none;
        }
        .article-header-back-link:hover {
          color: var(--color-blue);
        }
        .article-header-back-icon {
          width: 14px;
          height: 14px;
        }
        .article-header-badge {
          margin-bottom: 14px;
        }
        .article-header-title {
          margin: 0 0 16px 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          line-height: 1.08;
          font-size: 32px;
          color: var(--color-ink);
        }
        @media (min-width: 768px) {
          .article-header-title {
            font-size: 40px;
          }
        }
        @media (min-width: 1024px) {
          .article-header-title {
            font-size: 50px;
          }
        }
        .article-header-excerpt {
          margin: 0;
          font-size: 17px;
          line-height: 1.55;
          color: var(--color-muted);
          max-width: 65ch;
        }
        @media (min-width: 1024px) {
          .article-header-excerpt {
            font-size: 19px;
          }
        }
        .article-header-byline {
          margin-top: 24px;
        }
        @media (min-width: 1024px) {
          .article-header-byline {
            margin-top: 32px;
          }
        }
        .article-header-cover {
          margin-top: 32px;
          border-radius: 22px;
          overflow: hidden;
          border: 1px solid var(--color-line-2);
        }
        @media (min-width: 1024px) {
          .article-header-cover {
            margin-top: 40px;
          }
        }
      `}</style>
    </header>
  );
}
