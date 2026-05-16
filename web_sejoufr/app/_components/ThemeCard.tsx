"use client";

import type { ThemeUserResponse } from "@/lib/types";

interface ThemeCardProps {
  /** null = carte "Toutes les thématiques". */
  theme: ThemeUserResponse | null;
  selected: boolean;
  locked: boolean;
  onClick: () => void;
}

export function ThemeCard({ theme, selected, locked, onClick }: ThemeCardProps) {
  const isAll = theme === null;
  const showSelected = selected && !locked;

  return (
    <button
      type="button"
      className={`tc ${showSelected ? "is-selected" : ""} ${locked && !isAll ? "is-locked" : ""}`}
      onClick={onClick}
      aria-pressed={showSelected}
    >
      <span className={`tc-radio ${showSelected || (locked && isAll) ? "is-on" : ""}`} aria-hidden>
        {(showSelected || (locked && isAll)) && (
          <svg viewBox="0 0 16 16" width="12" height="12">
            <path d="M3.5 8l3 3 6-7" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
          </svg>
        )}
      </span>
      <span className="tc-body">
        <span className="tc-title">{isAll ? "Toutes les thématiques" : theme!.name}</span>
        <span className="tc-desc">
          {isAll
            ? "Un mélange varié de toutes les thématiques"
            : `${theme!.questionCount ?? 0} questions disponibles`}
        </span>
      </span>
      {locked && !isAll && (
        <span className="tc-lock" aria-label="Réservé aux abonnés">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
        </span>
      )}
      {!isAll && !locked && (
        <span className="tc-count" aria-hidden>{theme!.questionCount ?? 0} Q</span>
      )}

      <style>{`
        .tc {
          display: flex; align-items: center; gap: 12px;
          width: 100%;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 14px;
          padding: 14px;
          cursor: pointer;
          text-align: left;
          font-family: var(--font-sans);
          transition: all 0.18s ease-out;
          box-shadow: 0 2px 10px -4px rgba(30, 58, 140, 0.04);
        }
        .tc:hover:not(.is-locked) {
          border-color: var(--color-blue);
          background: var(--color-blue-soft);
        }
        .tc.is-selected {
          border-color: var(--color-blue);
          border-width: 1.5px;
          background: var(--color-blue-soft);
          box-shadow: 0 4px 14px -4px rgba(30, 58, 140, 0.18);
        }
        .tc.is-locked {
          background: var(--color-blue-soft);
          cursor: pointer;
        }
        .tc.is-locked .tc-title,
        .tc.is-locked .tc-desc { opacity: 0.55; }

        .tc-radio {
          width: 22px; height: 22px;
          border: 2px solid var(--color-line);
          border-radius: 50%;
          display: inline-flex; align-items: center; justify-content: center;
          flex-shrink: 0;
          transition: all 0.18s;
        }
        .tc-radio.is-on {
          border-color: var(--color-blue);
          background: var(--color-blue);
        }

        .tc-body { flex: 1; min-width: 0; }
        .tc-title {
          display: block;
          font-weight: 700; font-size: 14.5px;
          color: var(--color-ink);
          line-height: 1.25;
        }
        .tc.is-selected .tc-title { color: var(--color-blue-dark); }
        .tc-desc {
          display: block;
          font-size: 12.5px; color: var(--color-muted);
          margin-top: 3px; line-height: 1.35;
        }

        .tc-lock {
          color: var(--color-muted-2);
          flex-shrink: 0;
          display: inline-flex; align-items: center;
        }

        .tc-count {
          font-family: var(--font-mono);
          background: var(--color-line-2);
          color: var(--color-muted);
          padding: 4px 8px; border-radius: 6px;
          font-size: 10px; letter-spacing: 0.1em;
          flex-shrink: 0;
        }
        .tc.is-selected .tc-count {
          background: #fff;
          color: var(--color-blue);
        }
      `}</style>
    </button>
  );
}
