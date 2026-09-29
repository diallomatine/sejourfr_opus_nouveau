"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { FAQ_DATA, getAllFaqItems } from "@/content/faq/faq-data";
import type { FAQCategory as FAQCategoryType, FAQItem } from "@/content/faq/faq-data";
import { FAQHero } from "./FAQHero";
import { FAQCategoryNav } from "./FAQCategoryNav";
import { FAQCategoryDropdown } from "./FAQCategoryDropdown";
import { FAQCategory } from "./FAQCategory";
import { FAQContactCTA } from "./FAQContactCTA";

const norm = (s: string) =>
  s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

type FilteredCategory = FAQCategoryType & { visibleItems: FAQItem[] };

export function FAQContent() {
  const [query, setQuery] = useState("");
  const [activeCat, setActiveCat] = useState<string | null>(FAQ_DATA[0].id);
  // Filtre par catégorie utilisé par le dropdown mobile.
  const [mobileFilterCat, setMobileFilterCat] = useState<string | null>(null);
  const suppressSpyUntil = useRef(0);

  const totalCount = useMemo(() => getAllFaqItems().length, []);

  const { filteredCategories, forceOpenIds, matchCount } = useMemo(() => {
    const q = query.trim();
    let cats: FilteredCategory[];
    const ids = new Set<string>();
    let count: number | null = null;

    if (!q) {
      cats = FAQ_DATA.map((c) => ({ ...c, visibleItems: c.items }));
    } else {
      const needle = norm(q);
      let c = 0;
      cats = FAQ_DATA.map((cat) => {
        const visibleItems = cat.items.filter((it) => {
          const hay = norm(`${it.question} ${it.answer}`);
          const match = hay.includes(needle);
          if (match) {
            c++;
            ids.add(it.id);
          }
          return match;
        });
        return { ...cat, visibleItems };
      }).filter((cat) => cat.visibleItems.length > 0);
      count = c;
    }

    if (mobileFilterCat) {
      cats = cats.filter((cat) => cat.id === mobileFilterCat);
    }

    return { filteredCategories: cats, forceOpenIds: ids, matchCount: count };
  }, [query, mobileFilterCat]);

  const handleNavClick = (id: string) => {
    setMobileFilterCat(null);
    setActiveCat(id);
    suppressSpyUntil.current = Date.now() + 700;
    const target = document.getElementById(id);
    if (target) {
      target.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  const handleMobileFilterChange = (id: string | null) => {
    setMobileFilterCat(id);
    if (id) setActiveCat(id);
  };

  useEffect(() => {
    if (typeof window === "undefined") return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (Date.now() < suppressSpyUntil.current) return;
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
        if (visible) setActiveCat(visible.target.id);
      },
      {
        rootMargin: "-120px 0px -60% 0px",
        threshold: 0,
      },
    );
    FAQ_DATA.forEach((c) => {
      const el = document.getElementById(c.id);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, []);

  return (
    <div className="container-x faq-content">
      <FAQHero
        query={query}
        onQueryChange={setQuery}
        matchCount={matchCount}
        totalCount={totalCount}
      />

      {/* Dropdown mobile sticky */}
      <div className="faq-mobile-filter">
        <FAQCategoryDropdown
          categories={FAQ_DATA}
          activeId={mobileFilterCat}
          onChange={handleMobileFilterChange}
        />
      </div>

      <div className="faq-layout">
        <aside className="faq-side">
          <div className="faq-side-sticky">
            <FAQCategoryNav
              categories={FAQ_DATA}
              activeId={activeCat}
              onItemClick={handleNavClick}
              variant="sidebar"
            />
            <p className="faq-sources">
              Sources : Service-Public.fr, ministère de l&apos;Intérieur,
              formation-civique.interieur.gouv.fr, France Éducation
              International.
            </p>
          </div>
        </aside>

        <main className="faq-main">
          {filteredCategories.length === 0 ? (
            <div className="faq-empty">
              Aucune question ne correspond à votre recherche.
            </div>
          ) : (
            filteredCategories.map((c) => (
              <FAQCategory
                key={c.id}
                category={c}
                visibleItems={c.visibleItems}
                forceOpenIds={forceOpenIds}
                highlight={query.trim() || undefined}
              />
            ))
          )}

          <FAQContactCTA />

          <p className="faq-sources faq-sources-mobile">
            Sources : Service-Public.fr, ministère de l&apos;Intérieur,
            formation-civique.interieur.gouv.fr, France Éducation
            International.
          </p>
        </main>
      </div>

      <style>{`
        .faq-content {
          padding-top: 32px;
          padding-bottom: 48px;
        }
        .faq-mobile-filter {
          margin-bottom: 28px;
          position: sticky;
          top: 64px;
          z-index: 20;
          margin-left: -16px;
          margin-right: -16px;
          padding: 12px 16px;
          background: rgba(250, 250, 247, 0.88);
          backdrop-filter: blur(10px);
        }
        .faq-layout {
          display: grid;
          grid-template-columns: 1fr;
          gap: 32px;
        }
        .faq-side { display: none; }
        .faq-side-sticky { position: sticky; top: 96px; }
        .faq-sources {
          margin-top: 24px;
          padding: 0 12px;
          font-size: 11.5px;
          color: var(--color-muted-2);
          line-height: 1.55;
        }
        .faq-sources-mobile {
          padding: 0;
        }
        .faq-main {
          min-width: 0;
          display: flex;
          flex-direction: column;
          gap: 48px;
        }
        .faq-empty {
          border: 1px dashed var(--color-line);
          background: #fff;
          border-radius: 16px;
          padding: 40px;
          text-align: center;
          color: var(--color-muted);
          font-size: 14.5px;
        }
        @media (min-width: 1024px) {
          .faq-content { padding-top: 48px; padding-bottom: 64px; }
          .faq-mobile-filter { display: none; }
          .faq-layout {
            grid-template-columns: 260px 1fr;
            gap: 48px;
          }
          .faq-side { display: block; }
          .faq-sources-mobile { display: none; }
          .faq-main { gap: 64px; }
        }
      `}</style>
    </div>
  );
}
