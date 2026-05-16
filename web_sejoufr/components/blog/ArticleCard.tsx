import Link from "next/link";
import { Clock } from "lucide-react";
import type { ArticleListItem } from "@/lib/blog/types";
import { CategoryBadge } from "./CategoryBadge";
import { CoverIllustration } from "./CoverIllustration";

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

export function ArticleCard({ article }: { article: ArticleListItem }) {
  return (
    <Link href={`/blog/${article.slug}`} className="article-card">
      <CoverIllustration
        category={article.category}
        iconKey={article.coverIcon}
        variant="card"
      />
      <div className="article-card-body">
        <div className="article-card-top">
          <CategoryBadge slug={article.category} />
          <span className="article-card-time">
            <Clock className="article-card-clock" />
            {article.readingTimeMinutes} min
          </span>
        </div>
        <h3 className="article-card-title">{article.title}</h3>
        <p className="article-card-excerpt">{article.excerpt}</p>
        <div className="article-card-footer">
          <span className="article-card-author">{article.author.name}</span>
          <time dateTime={article.publishedAt} className="article-card-date">
            {formatDate(article.publishedAt)}
          </time>
        </div>
      </div>
      <style>{`
        .article-card {
          display: flex;
          flex-direction: column;
          background: #fff;
          border: 1px solid var(--color-line-2);
          border-radius: 18px;
          overflow: hidden;
          transition: transform 0.18s ease, box-shadow 0.18s ease,
            border-color 0.18s ease;
          text-decoration: none;
          color: inherit;
        }
        .article-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 20px 36px -22px rgba(15, 24, 57, 0.25);
          border-color: var(--color-line);
        }
        .article-card:focus-visible {
          outline: none;
          box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.35);
        }
        .article-card-body {
          display: flex;
          flex-direction: column;
          flex: 1;
          padding: 22px;
          gap: 12px;
        }
        .article-card-top {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 8px;
        }
        .article-card-time {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          font-size: 12px;
          color: var(--color-muted);
        }
        .article-card-clock {
          width: 12px;
          height: 12px;
        }
        .article-card-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          font-size: 19px;
          line-height: 1.25;
          color: var(--color-ink);
          display: -webkit-box;
          -webkit-line-clamp: 3;
          -webkit-box-orient: vertical;
          overflow: hidden;
          transition: color 0.15s;
        }
        @media (min-width: 1024px) {
          .article-card-title {
            font-size: 21px;
          }
        }
        .article-card:hover .article-card-title {
          color: var(--color-blue);
        }
        .article-card-excerpt {
          margin: 0;
          font-size: 14px;
          line-height: 1.55;
          color: var(--color-muted);
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        .article-card-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 10px;
          padding-top: 14px;
          border-top: 1px solid var(--color-line-2);
          margin-top: auto;
          font-size: 12px;
          color: var(--color-muted);
        }
        .article-card-author {
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
      `}</style>
    </Link>
  );
}
