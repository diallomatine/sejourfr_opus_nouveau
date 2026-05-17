import Link from "next/link";
import { ArrowRight, Clock } from "lucide-react";
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

export function FeaturedArticleCard({ article }: { article: ArticleListItem }) {
  return (
    <Link href={`/blog/${article.slug}`} className="featured-card">
      <div className="featured-card-cover">
        <CoverIllustration
          category={article.category}
          iconKey={article.coverIcon}
          variant="hero"
          fillHeight
          imageUrl={article.coverImage}
          imageAlt={article.title}
        />
      </div>
      <div className="featured-card-body">
        <div className="featured-card-top">
          <CategoryBadge slug={article.category} />
          <span className="featured-card-time">
            <Clock className="featured-card-clock" />
            {article.readingTimeMinutes} min
          </span>
        </div>
        <h2 className="featured-card-title">{article.title}</h2>
        <p className="featured-card-excerpt">{article.excerpt}</p>
        <div className="featured-card-footer">
          <span className="featured-card-author">
            Par {article.author.name} ·{" "}
            <time dateTime={article.publishedAt}>
              {formatDate(article.publishedAt)}
            </time>
          </span>
          <span className="featured-card-cta">
            Lire <ArrowRight className="featured-card-arrow" />
          </span>
        </div>
      </div>
      <style>{`
        .featured-card {
          display: grid;
          grid-template-columns: 1fr;
          gap: 0;
          background: #fff;
          border: 1px solid var(--color-line-2);
          border-radius: 22px;
          overflow: hidden;
          color: inherit;
          text-decoration: none;
          transition: transform 0.18s ease, box-shadow 0.18s ease,
            border-color 0.18s ease;
        }
        @media (min-width: 1024px) {
          .featured-card {
            grid-template-columns: 1fr 1fr;
          }
        }
        .featured-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 28px 48px -28px rgba(15, 24, 57, 0.3);
          border-color: var(--color-line);
        }
        .featured-card:focus-visible {
          outline: none;
          box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.35);
        }
        .featured-card-cover {
          min-height: 0;
        }
        .featured-card-body {
          display: flex;
          flex-direction: column;
          gap: 16px;
          padding: 28px;
        }
        @media (min-width: 1024px) {
          .featured-card-body {
            padding: 40px;
          }
        }
        .featured-card-top {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 8px;
        }
        .featured-card-time {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          font-size: 12px;
          color: var(--color-muted);
        }
        .featured-card-clock {
          width: 12px;
          height: 12px;
        }
        .featured-card-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          letter-spacing: -0.02em;
          font-size: 26px;
          line-height: 1.15;
          color: var(--color-ink);
          transition: color 0.15s;
        }
        @media (min-width: 768px) {
          .featured-card-title {
            font-size: 32px;
          }
        }
        @media (min-width: 1024px) {
          .featured-card-title {
            font-size: 38px;
          }
        }
        .featured-card:hover .featured-card-title {
          color: var(--color-blue);
        }
        .featured-card-excerpt {
          margin: 0;
          font-size: 15.5px;
          line-height: 1.6;
          color: var(--color-muted);
          display: -webkit-box;
          -webkit-line-clamp: 3;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        @media (min-width: 1024px) {
          .featured-card-excerpt {
            font-size: 17px;
          }
        }
        .featured-card-footer {
          margin-top: auto;
          padding-top: 8px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          font-size: 13.5px;
          color: var(--color-muted);
        }
        .featured-card-author {
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .featured-card-cta {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          color: var(--color-blue);
          font-weight: 600;
          flex-shrink: 0;
          transition: transform 0.15s;
        }
        .featured-card:hover .featured-card-cta {
          transform: translateX(2px);
        }
        .featured-card-arrow {
          width: 14px;
          height: 14px;
        }
      `}</style>
    </Link>
  );
}
