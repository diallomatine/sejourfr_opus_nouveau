"use client";

import * as Icons from "lucide-react";
import { HelpCircle, type LucideIcon } from "lucide-react";
import type { FAQCategory, FAQCategoryColor } from "@/content/faq/faq-data";

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

function getIcon(name: string): LucideIcon {
  const found = (Icons as unknown as Record<string, LucideIcon>)[name];
  return found ?? HelpCircle;
}

interface Props {
  categories: FAQCategory[];
  activeId: string | null;
  onItemClick: (id: string) => void;
  /** "sidebar" : desktop colonne gauche. "chips" : barre horizontale. */
  variant: "sidebar" | "chips";
  className?: string;
}

export function FAQCategoryNav({
  categories,
  activeId,
  onItemClick,
  variant,
  className,
}: Props) {
  if (variant === "chips") {
    return (
      <nav
        aria-label="Catégories de la FAQ"
        className={`faq-cnav-chips ${className ?? ""}`}
      >
        {categories.map((c) => {
          const Icon = getIcon(c.icon);
          const active = activeId === c.id;
          const tint = colorVar(c.color);
          return (
            <button
              key={c.id}
              type="button"
              onClick={() => onItemClick(c.id)}
              aria-current={active ? "true" : undefined}
              className={`faq-cnav-chip ${active ? "is-active" : ""}`}
              style={{ ["--chip-tint" as string]: tint }}
            >
              <Icon className="faq-cnav-chip-icon" />
              <span className="faq-cnav-chip-label">{c.name}</span>
            </button>
          );
        })}

        <style>{`
          .faq-cnav-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
          }
          .faq-cnav-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 14px;
            min-height: 40px;
            max-width: 100%;
            border-radius: 999px;
            background: #fff;
            border: 1px solid var(--color-line);
            font-family: var(--font-sans);
            font-size: 13px;
            font-weight: 500;
            color: var(--color-muted);
            cursor: pointer;
            transition: color 0.15s, border-color 0.15s, background 0.15s;
          }
          .faq-cnav-chip:hover {
            color: var(--color-blue);
            border-color: rgba(30, 58, 140, 0.4);
          }
          .faq-cnav-chip.is-active {
            background: var(--chip-tint);
            border-color: var(--chip-tint);
            color: #fff;
            box-shadow: 0 0 0 2px color-mix(in srgb, var(--chip-tint) 28%, transparent);
          }
          .faq-cnav-chip-icon {
            width: 14px;
            height: 14px;
            flex-shrink: 0;
            color: var(--chip-tint);
          }
          .faq-cnav-chip.is-active .faq-cnav-chip-icon { color: #fff; }
          .faq-cnav-chip-label {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }
        `}</style>
      </nav>
    );
  }

  return (
    <nav
      aria-label="Catégories de la FAQ"
      className={`faq-cnav ${className ?? ""}`}
    >
      {categories.map((c) => {
        const Icon = getIcon(c.icon);
        const active = activeId === c.id;
        const tint = colorVar(c.color);
        return (
          <button
            key={c.id}
            type="button"
            onClick={() => onItemClick(c.id)}
            aria-current={active ? "true" : undefined}
            className={`faq-cnav-item ${active ? "is-active" : ""}`}
            style={{ ["--item-tint" as string]: tint }}
          >
            <span className="faq-cnav-bullet">
              <Icon />
            </span>
            <span className="faq-cnav-text">
              <span className="faq-cnav-name">{c.name}</span>
              <span className="faq-cnav-meta">
                {c.items.length} question{c.items.length > 1 ? "s" : ""}
              </span>
            </span>
          </button>
        );
      })}

      <style>{`
        .faq-cnav {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }
        .faq-cnav-item {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          padding: 10px 12px;
          border-radius: 12px;
          background: transparent;
          border: 0;
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 500;
          color: var(--color-muted);
          text-align: left;
          cursor: pointer;
          transition: background 0.15s, color 0.15s;
          width: 100%;
        }
        .faq-cnav-item:hover {
          background: var(--color-paper-2);
          color: var(--color-ink);
        }
        .faq-cnav-item.is-active {
          background: var(--color-blue-light);
          color: var(--color-blue);
        }
        .faq-cnav-bullet {
          margin-top: 2px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 28px;
          height: 28px;
          border-radius: 8px;
          background: var(--color-paper-2);
          color: var(--item-tint);
          flex-shrink: 0;
        }
        .faq-cnav-item.is-active .faq-cnav-bullet {
          background: var(--color-blue);
          color: #fff;
        }
        .faq-cnav-bullet svg { width: 14px; height: 14px; }
        .faq-cnav-text {
          min-width: 0;
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }
        .faq-cnav-name {
          line-height: 1.25;
        }
        .faq-cnav-meta {
          font-family: var(--font-mono);
          font-size: 10.5px;
          letter-spacing: 0.08em;
          color: var(--color-muted-2);
        }
      `}</style>
    </nav>
  );
}
