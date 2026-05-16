"use client";

import { useEffect, useId, useState } from "react";
import { ChevronDown, Link2 } from "lucide-react";
import type { FAQItem as FAQItemType } from "@/content/faq/faq-data";
import { MarkdownLight } from "./MarkdownLight";

interface Props {
  item: FAQItemType;
  /** Forcer l'état ouvert (ex: si la recherche match, on déplie). */
  forceOpen?: boolean;
  /** Terme à surligner dans la réponse. */
  highlight?: string;
}

export function FAQItem({ item, forceOpen, highlight }: Props) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const baseId = useId();
  const panelId = `${baseId}-panel`;
  const buttonId = `${baseId}-button`;

  // Ouverture initiale si l'URL pointe sur cette question.
  useEffect(() => {
    if (typeof window === "undefined") return;
    if (window.location.hash === `#${item.id}`) {
      setOpen(true);
      requestAnimationFrame(() => {
        document.getElementById(item.id)?.scrollIntoView({ block: "start" });
      });
    }
  }, [item.id]);

  // Quand la recherche force l'ouverture (ou la fermeture), on suit.
  useEffect(() => {
    if (forceOpen === undefined) return;
    setOpen(forceOpen);
  }, [forceOpen]);

  const toggle = () => {
    setOpen((s) => {
      const next = !s;
      if (next && typeof window !== "undefined") {
        window.history.replaceState(null, "", `#${item.id}`);
      }
      return next;
    });
  };

  const copyLink = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (typeof window === "undefined") return;
    const url = `${window.location.origin}${window.location.pathname}#${item.id}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    } catch {
      // pas de retour visible si clipboard indisponible
    }
  };

  return (
    <li
      id={item.id}
      className={`faq-item ${open ? "is-open" : ""}`}
    >
      <button
        type="button"
        id={buttonId}
        onClick={toggle}
        aria-expanded={open}
        aria-controls={panelId}
        className="faq-item-trigger"
      >
        <span className="faq-item-question">{item.question}</span>
        <span
          onClick={copyLink}
          role="button"
          tabIndex={-1}
          aria-hidden
          className="faq-item-copy"
          title={copied ? "Lien copié" : "Copier le lien"}
        >
          <Link2 className="faq-item-copy-icon" />
        </span>
        <ChevronDown className="faq-item-chevron" />
      </button>

      {open && (
        <div
          id={panelId}
          role="region"
          aria-labelledby={buttonId}
          className="faq-item-panel"
        >
          <MarkdownLight source={item.answer} highlight={highlight} />
        </div>
      )}

      <style>{`
        .faq-item {
          list-style: none;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          scroll-margin-top: 120px;
          transition: box-shadow 0.18s ease, border-color 0.18s ease;
        }
        .faq-item.is-open {
          box-shadow: 0 14px 32px -22px rgba(30, 58, 140, 0.28);
          border-color: var(--color-line-2);
        }
        .faq-item-trigger {
          width: 100%;
          background: none;
          border: 0;
          cursor: pointer;
          display: flex;
          align-items: flex-start;
          gap: 14px;
          padding: 18px 20px;
          text-align: left;
          min-height: 64px;
          border-radius: 16px;
          color: inherit;
        }
        .faq-item-trigger:focus-visible {
          outline: none;
          box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.18);
        }
        .faq-item-question {
          flex: 1;
          min-width: 0;
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 16.5px;
          line-height: 1.4;
          letter-spacing: -0.01em;
          color: var(--color-ink);
        }
        .faq-item-copy {
          display: none;
          align-items: center;
          justify-content: center;
          width: 36px;
          height: 36px;
          border-radius: 10px;
          color: var(--color-muted-2);
          transition: background 0.15s ease, color 0.15s ease;
          flex-shrink: 0;
          margin-top: -4px;
        }
        .faq-item-copy:hover {
          background: var(--color-paper-2);
          color: var(--color-blue);
        }
        .faq-item-copy-icon {
          width: 16px;
          height: 16px;
        }
        .faq-item-chevron {
          flex-shrink: 0;
          width: 20px;
          height: 20px;
          margin-top: 2px;
          color: var(--color-muted-2);
          transition: transform 0.2s ease, color 0.2s ease;
        }
        .faq-item.is-open .faq-item-chevron {
          transform: rotate(180deg);
          color: var(--color-blue);
        }
        .faq-item-panel {
          padding: 16px 20px 22px;
          border-top: 1px solid var(--color-line-2);
          margin-top: 0;
        }
        @media (min-width: 640px) {
          .faq-item-copy { display: inline-flex; }
        }
        @media (min-width: 1024px) {
          .faq-item-trigger { padding: 22px 26px; }
          .faq-item-question { font-size: 18px; }
          .faq-item-panel { padding: 20px 26px 26px; }
        }
      `}</style>
    </li>
  );
}
