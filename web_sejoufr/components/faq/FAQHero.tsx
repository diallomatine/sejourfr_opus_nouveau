"use client";

import { Search, X } from "lucide-react";

interface Props {
  query: string;
  onQueryChange: (q: string) => void;
  matchCount: number | null;
  totalCount: number;
}

export function FAQHero({ query, onQueryChange, matchCount, totalCount }: Props) {
  const showCount = query.trim().length > 0;
  return (
    <header className="faq-hero">
      <p className="eyebrow faq-hero-eyebrow">Foire aux questions</p>
      <h1 className="faq-hero-title editorial">
        Vos démarches,{" "}
        <em>expliquées clairement</em>.
      </h1>
      <p className="faq-hero-sub">
        Tout ce qu&apos;il faut savoir sur l&apos;examen civique, l&apos;entretien
        de naturalisation et la procédure de demande — sans jargon.
      </p>

      <div className="faq-hero-search-wrap">
        <label htmlFor="faq-search" className="sr-only">
          Rechercher dans la FAQ
        </label>
        <div className="faq-hero-search">
          <Search aria-hidden className="faq-hero-search-icon" />
          <input
            id="faq-search"
            type="search"
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
            placeholder="Rechercher une question (ex : prix examen civique...)"
            className="faq-hero-input"
            autoComplete="off"
          />
          {query && (
            <button
              type="button"
              onClick={() => onQueryChange("")}
              aria-label="Effacer la recherche"
              className="faq-hero-clear"
            >
              <X />
            </button>
          )}
        </div>
        {showCount && (
          <p className="faq-hero-count">
            {matchCount === 0 ? (
              <span>Aucun résultat — essayez d&apos;autres mots-clés</span>
            ) : (
              <span>
                <strong>{matchCount}</strong> résultat
                {(matchCount ?? 0) > 1 ? "s" : ""} sur{" "}
                <span className="faq-hero-count-total">{totalCount}</span>
              </span>
            )}
          </p>
        )}
      </div>

      <style>{`
        .faq-hero { margin-bottom: 36px; }
        .faq-hero-eyebrow { margin-bottom: 12px; display: block; }
        .faq-hero-title {
          font-size: clamp(34px, 5.5vw, 60px);
          line-height: 1.05;
          margin: 0 0 16px;
          color: var(--color-ink);
        }
        .faq-hero-sub {
          margin: 0;
          color: var(--color-muted);
          font-size: 17px;
          line-height: 1.55;
          max-width: 640px;
        }
        .faq-hero-search-wrap {
          margin-top: 28px;
          position: sticky;
          top: 64px;
          z-index: 30;
          margin-left: -16px;
          margin-right: -16px;
          padding: 12px 16px;
          background: rgba(250, 250, 247, 0.88);
          backdrop-filter: blur(10px);
        }
        .faq-hero-search {
          position: relative;
        }
        .faq-hero-search-icon {
          pointer-events: none;
          position: absolute;
          left: 16px;
          top: 50%;
          transform: translateY(-50%);
          width: 16px;
          height: 16px;
          color: var(--color-muted-2);
        }
        .faq-hero-input {
          width: 100%;
          height: 48px;
          padding-left: 44px;
          padding-right: 48px;
          border-radius: 14px;
          background: #fff;
          border: 1px solid var(--color-line);
          font-family: var(--font-sans);
          font-size: 15px;
          color: var(--color-ink);
          box-shadow: 0 1px 2px rgba(15, 24, 57, 0.04);
          transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .faq-hero-input::placeholder { color: var(--color-muted-2); }
        .faq-hero-input:focus {
          outline: none;
          border-color: var(--color-blue);
          box-shadow: 0 0 0 4px rgba(30, 58, 140, 0.12);
        }
        .faq-hero-clear {
          position: absolute;
          right: 10px;
          top: 50%;
          transform: translateY(-50%);
          width: 32px;
          height: 32px;
          border-radius: 999px;
          border: 0;
          background: transparent;
          color: var(--color-muted-2);
          cursor: pointer;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          transition: background 0.15s ease, color 0.15s ease;
        }
        .faq-hero-clear:hover {
          background: var(--color-paper-2);
          color: var(--color-ink);
        }
        .faq-hero-clear svg { width: 16px; height: 16px; }
        .faq-hero-count {
          margin: 10px 0 0;
          font-size: 13px;
          color: var(--color-muted);
        }
        .faq-hero-count strong {
          font-weight: 600;
          color: var(--color-ink);
        }
        .faq-hero-count-total {
          font-variant-numeric: tabular-nums;
        }
        .sr-only {
          position: absolute;
          width: 1px; height: 1px;
          padding: 0; margin: -1px; overflow: hidden;
          clip: rect(0,0,0,0); white-space: nowrap; border: 0;
        }
        @media (min-width: 640px) {
          .faq-hero-search-wrap {
            margin-left: 0;
            margin-right: 0;
            padding: 0;
            background: transparent;
            backdrop-filter: none;
          }
        }
        @media (min-width: 1024px) {
          .faq-hero { margin-bottom: 44px; }
          .faq-hero-input { height: 56px; font-size: 16px; }
          .faq-hero-sub { font-size: 18px; }
        }
      `}</style>
    </header>
  );
}
