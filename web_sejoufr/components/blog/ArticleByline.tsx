import { Clock } from "lucide-react";
import type { Article } from "@/lib/blog/types";

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

interface Props {
  article: Article;
}

export function ArticleByline({ article }: Props) {
  const { author, publishedAt, updatedAt, readingTimeMinutes } = article;
  return (
    <div className="article-byline">
      <span aria-hidden className="article-byline-avatar">
        {author.initials}
      </span>
      <div className="article-byline-meta">
        <span className="article-byline-name">{author.name}</span>
        <span className="article-byline-sep">·</span>
        <span className="article-byline-role">{author.role}</span>
        <span className="article-byline-sep">·</span>
        <time dateTime={publishedAt} className="article-byline-date">
          {formatDate(publishedAt)}
        </time>
        <span className="article-byline-sep">·</span>
        <span className="article-byline-reading">
          <Clock className="article-byline-clock" />
          {readingTimeMinutes} min de lecture
        </span>
        {updatedAt && updatedAt !== publishedAt && (
          <>
            <span className="article-byline-sep">·</span>
            <span className="article-byline-updated">
              Mis à jour le {formatDate(updatedAt)}
            </span>
          </>
        )}
      </div>
      <style>{`
        .article-byline {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 12px;
          font-size: 14px;
        }
        .article-byline-avatar {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: linear-gradient(
            135deg,
            var(--color-blue),
            var(--color-ink-2)
          );
          color: #fff;
          font-family: var(--font-sans);
          font-size: 12px;
          font-weight: 600;
          flex-shrink: 0;
        }
        .article-byline-meta {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 6px 8px;
          color: var(--color-muted);
        }
        .article-byline-name {
          font-weight: 600;
          color: var(--color-ink);
        }
        .article-byline-role,
        .article-byline-date,
        .article-byline-reading {
          color: var(--color-muted);
        }
        .article-byline-reading {
          display: inline-flex;
          align-items: center;
          gap: 4px;
        }
        .article-byline-clock {
          width: 12px;
          height: 12px;
        }
        .article-byline-sep {
          color: var(--color-line);
        }
        @media (max-width: 640px) {
          .article-byline-sep {
            display: none;
          }
        }
        .article-byline-updated {
          font-size: 12px;
          font-style: italic;
          color: var(--color-muted-2);
        }
      `}</style>
    </div>
  );
}
