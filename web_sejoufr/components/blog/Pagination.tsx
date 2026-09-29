import Link from "next/link";
import { ChevronLeft, ChevronRight } from "lucide-react";

interface Props {
  page: number;
  totalPages: number;
  /** Racine de la liste, sans slash final (ex: "/blog", "/blog/category/tcf"). */
  basePath: string;
}

function hrefFor(basePath: string, page: number): string {
  return page <= 1 ? basePath : `${basePath}/page/${page}`;
}

/**
 * Fenêtre de numéros autour de la page courante, avec ellipses.
 * `null` = séparateur.
 */
function windowed(page: number, totalPages: number): (number | null)[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const around = [page - 1, page, page + 1].filter(
    (p) => p > 1 && p < totalPages,
  );
  const out: (number | null)[] = [1];
  if (around[0] !== undefined && around[0] > 2) out.push(null);
  out.push(...around);
  const last = around[around.length - 1];
  if (last !== undefined && last < totalPages - 1) out.push(null);
  out.push(totalPages);
  return out;
}

export function Pagination({ page, totalPages, basePath }: Props) {
  if (totalPages <= 1) return null;

  const items = windowed(page, totalPages);

  return (
    <nav aria-label="Pagination des articles" className="blog-pagination">
      {page > 1 ? (
        <Link
          href={hrefFor(basePath, page - 1)}
          rel="prev"
          className="blog-pagination-arrow"
          aria-label="Page précédente"
        >
          <ChevronLeft className="blog-pagination-icon" />
          <span className="blog-pagination-arrow-label">Précédent</span>
        </Link>
      ) : (
        <span
          className="blog-pagination-arrow blog-pagination-arrow--disabled"
          aria-hidden
        >
          <ChevronLeft className="blog-pagination-icon" />
          <span className="blog-pagination-arrow-label">Précédent</span>
        </span>
      )}

      <ol className="blog-pagination-list">
        {items.map((item, index) =>
          item === null ? (
            <li key={`gap-${index}`} aria-hidden className="blog-pagination-gap">
              …
            </li>
          ) : (
            <li key={item}>
              <Link
                href={hrefFor(basePath, item)}
                aria-current={item === page ? "page" : undefined}
                aria-label={`Page ${item}`}
                className={
                  item === page
                    ? "blog-pagination-page blog-pagination-page--active"
                    : "blog-pagination-page"
                }
              >
                {item}
              </Link>
            </li>
          ),
        )}
      </ol>

      {page < totalPages ? (
        <Link
          href={hrefFor(basePath, page + 1)}
          rel="next"
          className="blog-pagination-arrow"
          aria-label="Page suivante"
        >
          <span className="blog-pagination-arrow-label">Suivant</span>
          <ChevronRight className="blog-pagination-icon" />
        </Link>
      ) : (
        <span
          className="blog-pagination-arrow blog-pagination-arrow--disabled"
          aria-hidden
        >
          <span className="blog-pagination-arrow-label">Suivant</span>
          <ChevronRight className="blog-pagination-icon" />
        </span>
      )}

      <style>{`
        .blog-pagination {
          display: flex;
          align-items: center;
          justify-content: center;
          flex-wrap: wrap;
          gap: 8px;
          margin-top: 36px;
        }
        @media (min-width: 768px) {
          .blog-pagination {
            gap: 12px;
            margin-top: 44px;
          }
        }
        .blog-pagination-list {
          display: flex;
          align-items: center;
          gap: 6px;
          list-style: none;
          margin: 0;
          padding: 0;
          flex-wrap: wrap;
          justify-content: center;
        }
        .blog-pagination-page,
        .blog-pagination-arrow {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          min-height: 40px;
          min-width: 40px;
          padding: 0 12px;
          border-radius: 999px;
          border: 1px solid var(--color-line);
          background: #fff;
          color: var(--color-ink-2);
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 500;
          text-decoration: none;
          transition: all 0.15s;
        }
        .blog-pagination-page:hover,
        .blog-pagination-arrow:hover {
          border-color: rgba(30, 58, 140, 0.4);
          color: var(--color-blue);
        }
        .blog-pagination-page--active,
        .blog-pagination-page--active:hover {
          background: var(--color-blue);
          border-color: var(--color-blue);
          color: #fff;
        }
        .blog-pagination-arrow--disabled {
          opacity: 0.4;
          pointer-events: none;
        }
        .blog-pagination-icon {
          width: 16px;
          height: 16px;
        }
        .blog-pagination-arrow-label {
          display: none;
        }
        @media (min-width: 640px) {
          .blog-pagination-arrow-label {
            display: inline;
          }
        }
        .blog-pagination-gap {
          padding: 0 2px;
          color: var(--color-muted-2);
          font-size: 14px;
        }
      `}</style>
    </nav>
  );
}
