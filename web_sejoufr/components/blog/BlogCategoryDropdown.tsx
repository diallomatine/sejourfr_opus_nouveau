"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Check, ChevronDown, Layers } from "lucide-react";
import { categories, categoryTone } from "@/lib/blog/categories";
import type { ArticleCategorySlug } from "@/lib/blog/types";

interface Props {
  active: ArticleCategorySlug | "all";
}

export function BlogCategoryDropdown({ active }: Props) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  const activeCategory =
    active === "all" ? null : categories.find((c) => c.slug === active) ?? null;
  const activeDot = activeCategory ? categoryTone(activeCategory.color).dot : null;
  const activeLabel = activeCategory ? activeCategory.name : "Toutes les catégories";

  useEffect(() => {
    if (!open) return;
    const onClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("mousedown", onClick);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onClick);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <div ref={ref} className="cat-dropdown">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label="Filtrer par catégorie"
        className="cat-dropdown-trigger"
      >
        {activeDot ? (
          <span
            aria-hidden
            className="cat-dropdown-dot"
            style={{ background: activeDot }}
          />
        ) : (
          <Layers className="cat-dropdown-icon" />
        )}
        <span className="cat-dropdown-label">{activeLabel}</span>
        <ChevronDown
          className={
            open
              ? "cat-dropdown-chevron cat-dropdown-chevron--open"
              : "cat-dropdown-chevron"
          }
        />
      </button>

      {open && (
        <ul role="listbox" className="cat-dropdown-list">
          <li>
            <Link
              href="/blog"
              onClick={() => setOpen(false)}
              role="option"
              aria-selected={active === "all"}
              className={
                active === "all"
                  ? "cat-dropdown-option cat-dropdown-option--active"
                  : "cat-dropdown-option"
              }
            >
              <Layers className="cat-dropdown-icon" />
              <span className="cat-dropdown-option-label">
                Toutes les catégories
              </span>
              {active === "all" && (
                <Check className="cat-dropdown-check" />
              )}
            </Link>
          </li>
          <li role="separator" className="cat-dropdown-sep" />
          {categories.map((c) => {
            const isActive = c.slug === active;
            const dot = categoryTone(c.color).dot;
            return (
              <li key={c.slug}>
                <Link
                  href={`/blog/category/${c.slug}`}
                  onClick={() => setOpen(false)}
                  role="option"
                  aria-selected={isActive}
                  className={
                    isActive
                      ? "cat-dropdown-option cat-dropdown-option--active"
                      : "cat-dropdown-option"
                  }
                >
                  <span
                    aria-hidden
                    className="cat-dropdown-dot"
                    style={{ background: dot }}
                  />
                  <span className="cat-dropdown-option-label">{c.name}</span>
                  {isActive && <Check className="cat-dropdown-check" />}
                </Link>
              </li>
            );
          })}
        </ul>
      )}

      <style>{`
        .cat-dropdown {
          position: relative;
        }
        .cat-dropdown-trigger {
          width: 100%;
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 0 16px;
          height: 48px;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 12px;
          font-family: var(--font-sans);
          font-size: 14.5px;
          font-weight: 500;
          color: var(--color-ink);
          cursor: pointer;
          text-align: left;
          transition: border-color 0.15s;
          box-shadow: 0 1px 0 rgba(15, 24, 57, 0.02);
        }
        .cat-dropdown-trigger:focus {
          outline: none;
          border-color: var(--color-blue);
          box-shadow: 0 0 0 4px rgba(30, 58, 140, 0.1);
        }
        .cat-dropdown-icon {
          width: 16px;
          height: 16px;
          flex-shrink: 0;
          color: var(--color-blue);
        }
        .cat-dropdown-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          flex-shrink: 0;
        }
        .cat-dropdown-label {
          flex: 1;
          min-width: 0;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .cat-dropdown-chevron {
          width: 16px;
          height: 16px;
          color: var(--color-muted-2);
          transition: transform 0.2s;
          flex-shrink: 0;
        }
        .cat-dropdown-chevron--open {
          transform: rotate(180deg);
        }
        .cat-dropdown-list {
          position: absolute;
          z-index: 30;
          top: calc(100% + 4px);
          left: 0;
          right: 0;
          max-height: 60vh;
          overflow-y: auto;
          margin: 0;
          padding: 4px;
          list-style: none;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 12px;
          box-shadow: 0 12px 32px -12px rgba(15, 24, 57, 0.18);
        }
        .cat-dropdown-option {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 12px;
          border-radius: 8px;
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 500;
          color: var(--color-ink-2);
          text-decoration: none;
          transition: background 0.15s, color 0.15s;
        }
        .cat-dropdown-option:hover {
          background: var(--color-paper);
        }
        .cat-dropdown-option--active {
          background: rgba(30, 58, 140, 0.08);
          color: var(--color-blue);
        }
        .cat-dropdown-option-label {
          flex: 1;
          min-width: 0;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .cat-dropdown-check {
          width: 16px;
          height: 16px;
          color: var(--color-blue);
          flex-shrink: 0;
        }
        .cat-dropdown-sep {
          height: 1px;
          margin: 4px 8px;
          background: var(--color-line-2);
          list-style: none;
        }
      `}</style>
    </div>
  );
}
