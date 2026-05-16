import Link from "next/link";
import { categories } from "@/lib/blog/categories";
import type { ArticleCategorySlug } from "@/lib/blog/types";

interface Props {
  active?: ArticleCategorySlug | "all";
}

export function CategoryFilter({ active = "all" }: Props) {
  const items: { slug: ArticleCategorySlug | "all"; name: string; href: string }[] = [
    { slug: "all", name: "Tous", href: "/blog" },
    ...categories.map((c) => ({
      slug: c.slug,
      name: c.name,
      href: `/blog/category/${c.slug}`,
    })),
  ];

  return (
    <nav aria-label="Filtrer par catégorie" className="category-filter">
      {items.map((item) => {
        const isActive = active === item.slug;
        return (
          <Link
            key={item.slug}
            href={item.href}
            aria-current={isActive ? "page" : undefined}
            className={
              isActive
                ? "category-filter-item category-filter-item--active"
                : "category-filter-item"
            }
          >
            {item.name}
          </Link>
        );
      })}
      <style>{`
        .category-filter {
          display: flex;
          gap: 8px;
          overflow-x: auto;
          padding-bottom: 6px;
        }
        .category-filter-item {
          flex-shrink: 0;
          display: inline-flex;
          align-items: center;
          padding: 9px 16px;
          min-height: 40px;
          border-radius: 999px;
          background: #fff;
          border: 1px solid var(--color-line);
          color: var(--color-ink-2);
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 500;
          letter-spacing: -0.005em;
          transition: all 0.15s;
          text-decoration: none;
        }
        .category-filter-item:hover {
          border-color: rgba(30, 58, 140, 0.4);
          color: var(--color-blue);
        }
        .category-filter-item--active {
          background: var(--color-blue);
          border-color: var(--color-blue);
          color: #fff;
        }
        .category-filter-item--active:hover {
          background: var(--color-blue-dark);
          border-color: var(--color-blue-dark);
          color: #fff;
        }
      `}</style>
    </nav>
  );
}
