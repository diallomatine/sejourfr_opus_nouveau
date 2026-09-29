import Link from "next/link";
import { Tag } from "lucide-react";
import type { Article } from "@/lib/blog/types";
import { ShareButtons } from "./ShareButtons";

interface Props {
  article: Article;
  url: string;
}

export function ArticleFooter({ article, url }: Props) {
  return (
    <footer className="article-footer">
      {article.tags.length > 0 && (
        <div className="article-footer-tags">
          <Tag className="article-footer-tag-icon" />
          {article.tags.map((t) => (
            <Link
              key={t}
              href={`/blog?tag=${encodeURIComponent(t)}`}
              className="article-footer-tag"
            >
              #{t}
            </Link>
          ))}
        </div>
      )}

      <div className="article-footer-bottom">
        <div className="article-footer-byline">
          Article publié par{" "}
          <span className="article-footer-author">{article.author.name}</span>
          {article.author.role && <> · {article.author.role}</>}
        </div>
        <ShareButtons title={article.title} url={url} />
      </div>

      <style>{`
        .article-footer {
          margin-top: 48px;
          padding-top: 32px;
          border-top: 1px solid var(--color-line);
        }
        @media (min-width: 1024px) {
          .article-footer {
            margin-top: 64px;
            padding-top: 40px;
          }
        }
        .article-footer-tags {
          margin-bottom: 24px;
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 8px;
        }
        .article-footer-tag-icon {
          width: 16px;
          height: 16px;
          color: var(--color-muted-2);
        }
        .article-footer-tag {
          display: inline-block;
          background: var(--color-paper-2);
          color: var(--color-ink-2);
          font-size: 12px;
          padding: 5px 12px;
          border-radius: 999px;
          transition: background 0.15s, color 0.15s;
          text-decoration: none;
        }
        .article-footer-tag:hover {
          background: var(--color-line);
          color: var(--color-ink);
        }
        .article-footer-bottom {
          display: flex;
          flex-direction: column;
          align-items: flex-start;
          gap: 16px;
        }
        @media (min-width: 640px) {
          .article-footer-bottom {
            flex-direction: row;
            align-items: center;
            justify-content: space-between;
          }
        }
        .article-footer-byline {
          font-size: 13.5px;
          color: var(--color-muted);
        }
        .article-footer-author {
          font-weight: 600;
          color: var(--color-ink);
        }
      `}</style>
    </footer>
  );
}
