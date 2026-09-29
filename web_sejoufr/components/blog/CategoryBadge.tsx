import Link from "next/link";
import { categoryTone, getCategory } from "@/lib/blog/categories";
import type { ArticleCategorySlug } from "@/lib/blog/types";

interface Props {
  slug: ArticleCategorySlug;
  asLink?: boolean;
  size?: "sm" | "md";
}

export function CategoryBadge({ slug, asLink = false, size = "sm" }: Props) {
  const meta = getCategory(slug);
  const tone = categoryTone(meta.color);

  const className =
    size === "md" ? "category-badge category-badge--md" : "category-badge";

  const inner = (
    <span
      className={className}
      style={{ background: tone.badgeBg, color: tone.fg }}
    >
      <span
        aria-hidden
        className="category-badge-dot"
        style={{ background: tone.dot }}
      />
      {meta.name}
      <style>{`
        .category-badge {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 4px 10px;
          border-radius: 999px;
          font-family: var(--font-mono);
          font-size: 11px;
          font-weight: 600;
          letter-spacing: 0.06em;
          text-transform: uppercase;
          line-height: 1;
        }
        .category-badge--md {
          padding: 6px 12px;
          font-size: 12px;
        }
        .category-badge-dot {
          width: 6px;
          height: 6px;
          border-radius: 50%;
          flex-shrink: 0;
        }
      `}</style>
    </span>
  );

  if (asLink) {
    return (
      <Link
        href={`/blog/category/${meta.slug}`}
        className="category-badge-link"
      >
        {inner}
        <style>{`
          .category-badge-link {
            display: inline-block;
            transition: opacity 0.15s;
          }
          .category-badge-link:hover {
            opacity: 0.8;
          }
        `}</style>
      </Link>
    );
  }
  return inner;
}
