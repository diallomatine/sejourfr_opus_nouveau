"use client";

import * as Icons from "lucide-react";
import { HelpCircle, type LucideIcon } from "lucide-react";
import type {
  FAQCategory as FAQCategoryType,
  FAQCategoryColor,
  FAQItem as FAQItemType,
} from "@/content/faq/faq-data";
import { FAQItem } from "./FAQItem";

function colorVar(color: FAQCategoryColor): string {
  switch (color) {
    case "blue":
      return "var(--color-blue)";
    case "red":
      return "var(--color-red)";
    case "amber":
      return "var(--color-amber)";
    case "success":
      return "var(--color-green)";
    case "grey":
    default:
      return "var(--color-ink-2)";
  }
}

function colorTintVar(color: FAQCategoryColor): string {
  switch (color) {
    case "blue":
      return "var(--color-blue-light)";
    case "red":
      return "var(--color-red-light)";
    case "amber":
      return "rgba(232, 163, 23, 0.14)";
    case "success":
      return "rgba(22, 143, 91, 0.14)";
    case "grey":
    default:
      return "var(--color-paper-2)";
  }
}

function getIcon(name: string): LucideIcon {
  const found = (Icons as unknown as Record<string, LucideIcon>)[name];
  return found ?? HelpCircle;
}

interface Props {
  category: FAQCategoryType;
  /** Liste filtrée des items à afficher (peut être vide → on n'affiche pas la catégorie). */
  visibleItems: FAQItemType[];
  /** Items à forcer ouverts (matches de recherche). */
  forceOpenIds: Set<string>;
  /** Terme à surligner. */
  highlight?: string;
}

export function FAQCategory({
  category,
  visibleItems,
  forceOpenIds,
  highlight,
}: Props) {
  const Icon = getIcon(category.icon);

  if (visibleItems.length === 0) return null;

  const tint = colorVar(category.color);
  const tintSoft = colorTintVar(category.color);

  return (
    <section
      id={category.id}
      className="faq-cat"
      style={{
        ["--cat-tint" as string]: tint,
        ["--cat-tint-soft" as string]: tintSoft,
      }}
    >
      <div className="faq-cat-head">
        <span className="faq-cat-icon">
          <Icon />
        </span>
        <div className="faq-cat-text">
          <h2 className="faq-cat-title">{category.name}</h2>
          {category.description && (
            <p className="faq-cat-desc">{category.description}</p>
          )}
        </div>
        <span className="faq-cat-count">
          {visibleItems.length} / {category.items.length}
        </span>
      </div>

      <ul className="faq-cat-list">
        {visibleItems.map((item) => (
          <FAQItem
            key={item.id}
            item={item}
            forceOpen={forceOpenIds.has(item.id) ? true : undefined}
            highlight={highlight}
          />
        ))}
      </ul>

      <style>{`
        .faq-cat {
          scroll-margin-top: 120px;
        }
        .faq-cat-head {
          display: flex;
          align-items: flex-start;
          gap: 14px;
          margin-bottom: 22px;
        }
        .faq-cat-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 42px;
          height: 42px;
          border-radius: 14px;
          background: var(--cat-tint-soft);
          color: var(--cat-tint);
          flex-shrink: 0;
        }
        .faq-cat-icon svg { width: 20px; height: 20px; }
        .faq-cat-text {
          min-width: 0;
          flex: 1;
        }
        .faq-cat-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          font-size: clamp(22px, 2.4vw, 30px);
          line-height: 1.15;
          letter-spacing: -0.015em;
          color: var(--color-ink);
        }
        .faq-cat-desc {
          margin: 6px 0 0;
          font-size: 14.5px;
          color: var(--color-muted);
          line-height: 1.55;
          max-width: 640px;
        }
        .faq-cat-count {
          display: none;
          padding: 5px 10px;
          border-radius: 999px;
          font-family: var(--font-mono);
          font-size: 11px;
          font-weight: 600;
          background: var(--cat-tint-soft);
          color: var(--cat-tint);
          flex-shrink: 0;
          font-variant-numeric: tabular-nums;
        }
        .faq-cat-list {
          list-style: none;
          margin: 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          gap: 12px;
        }
        @media (min-width: 640px) {
          .faq-cat-count { display: inline-flex; align-items: center; }
        }
        @media (min-width: 1024px) {
          .faq-cat-head { gap: 16px; margin-bottom: 26px; }
          .faq-cat-icon { width: 46px; height: 46px; }
        }
      `}</style>
    </section>
  );
}
