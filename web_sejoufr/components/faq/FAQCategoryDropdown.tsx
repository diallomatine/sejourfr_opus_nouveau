"use client";

import { useEffect, useRef, useState } from "react";
import * as Icons from "lucide-react";
import { Check, ChevronDown, HelpCircle, Layers, type LucideIcon } from "lucide-react";
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
  /** `null` = aucun filtre, affiche toutes les catégories. */
  activeId: string | null;
  onChange: (id: string | null) => void;
  className?: string;
}

export function FAQCategoryDropdown({
  categories,
  activeId,
  onChange,
  className,
}: Props) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  const active = activeId ? categories.find((c) => c.id === activeId) : null;
  const ActiveIcon = active ? getIcon(active.icon) : Layers;
  const activeLabel = active ? active.name : "Toutes les catégories";
  const activeTint = active ? colorVar(active.color) : "var(--color-blue)";
  const totalItems = categories.reduce((s, c) => s + c.items.length, 0);

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
    <div ref={ref} className={`faq-dd ${className ?? ""}`}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label="Filtrer par catégorie"
        className="faq-dd-trigger"
      >
        <ActiveIcon
          className="faq-dd-trigger-icon"
          style={{ color: activeTint }}
        />
        <span className="faq-dd-trigger-label">{activeLabel}</span>
        <ChevronDown className={`faq-dd-chevron ${open ? "is-open" : ""}`} />
      </button>

      {open && (
        <ul role="listbox" className="faq-dd-list">
          <li>
            <button
              type="button"
              onClick={() => {
                onChange(null);
                setOpen(false);
              }}
              role="option"
              aria-selected={activeId === null}
              className={`faq-dd-opt ${activeId === null ? "is-active" : ""}`}
            >
              <Layers className="faq-dd-opt-icon" />
              <span className="faq-dd-opt-label">Toutes les catégories</span>
              <span className="faq-dd-opt-count">{totalItems}</span>
              {activeId === null && (
                <Check className="faq-dd-opt-check" />
              )}
            </button>
          </li>
          <li role="separator" className="faq-dd-sep" />
          {categories.map((c) => {
            const Icon = getIcon(c.icon);
            const isActive = c.id === activeId;
            const tint = colorVar(c.color);
            return (
              <li key={c.id}>
                <button
                  type="button"
                  onClick={() => {
                    onChange(c.id);
                    setOpen(false);
                  }}
                  role="option"
                  aria-selected={isActive}
                  className={`faq-dd-opt ${isActive ? "is-active" : ""}`}
                >
                  <Icon
                    className="faq-dd-opt-icon"
                    style={{ color: isActive ? "var(--color-blue)" : tint }}
                  />
                  <span className="faq-dd-opt-label">{c.name}</span>
                  <span className="faq-dd-opt-count">{c.items.length}</span>
                  {isActive && <Check className="faq-dd-opt-check" />}
                </button>
              </li>
            );
          })}
        </ul>
      )}

      <style>{`
        .faq-dd { position: relative; }
        .faq-dd-trigger {
          width: 100%;
          height: 48px;
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 0 16px;
          border-radius: 14px;
          background: #fff;
          border: 1px solid var(--color-line);
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 500;
          color: var(--color-ink);
          text-align: left;
          box-shadow: 0 1px 2px rgba(15, 24, 57, 0.04);
          cursor: pointer;
          transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .faq-dd-trigger:focus {
          outline: none;
          border-color: var(--color-blue);
          box-shadow: 0 0 0 4px rgba(30, 58, 140, 0.12);
        }
        .faq-dd-trigger-icon {
          width: 16px; height: 16px; flex-shrink: 0;
        }
        .faq-dd-trigger-label {
          flex: 1;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .faq-dd-chevron {
          width: 16px; height: 16px; flex-shrink: 0;
          color: var(--color-muted-2);
          transition: transform 0.18s ease;
        }
        .faq-dd-chevron.is-open { transform: rotate(180deg); }
        .faq-dd-list {
          position: absolute;
          z-index: 30;
          margin: 4px 0 0;
          padding: 4px;
          left: 0;
          right: 0;
          max-height: 60vh;
          overflow-y: auto;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 14px;
          box-shadow: 0 12px 32px -16px rgba(15, 24, 57, 0.25);
          list-style: none;
        }
        .faq-dd-opt {
          width: 100%;
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 12px;
          border-radius: 10px;
          background: transparent;
          border: 0;
          font-family: var(--font-sans);
          font-size: 14px;
          color: var(--color-ink-2);
          cursor: pointer;
          text-align: left;
          transition: background 0.15s ease, color 0.15s ease;
        }
        .faq-dd-opt:hover {
          background: var(--color-paper-2);
        }
        .faq-dd-opt.is-active {
          background: var(--color-blue-light);
          color: var(--color-blue);
        }
        .faq-dd-opt-icon { width: 16px; height: 16px; flex-shrink: 0; }
        .faq-dd-opt-label {
          flex: 1;
          font-weight: 500;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .faq-dd-opt-count {
          font-family: var(--font-mono);
          font-size: 11px;
          color: var(--color-muted-2);
          flex-shrink: 0;
        }
        .faq-dd-opt.is-active .faq-dd-opt-count { color: var(--color-blue); }
        .faq-dd-opt-check {
          width: 16px; height: 16px; flex-shrink: 0;
          color: var(--color-blue);
        }
        .faq-dd-sep {
          list-style: none;
          height: 1px;
          margin: 4px 8px;
          background: var(--color-line);
        }
      `}</style>
    </div>
  );
}
