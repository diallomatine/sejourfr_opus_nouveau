"use client";

import { useEffect, useState } from "react";

/**
 * Barre de lecture sticky tout en haut, qui se remplit selon le scroll de la
 * page. Calculée à partir de `scrollY` rapporté à la hauteur totale du
 * document moins la hauteur de la fenêtre.
 */
export function ArticleProgressBar() {
  const [pct, setPct] = useState(0);

  useEffect(() => {
    const onScroll = () => {
      const h = document.documentElement;
      const max = h.scrollHeight - h.clientHeight || 1;
      const value = Math.max(0, Math.min(100, (window.scrollY / max) * 100));
      setPct(value);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    };
  }, []);

  return (
    <div
      className="article-progress"
      role="progressbar"
      aria-label="Progression de lecture"
      aria-valuenow={Math.round(pct)}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div className="article-progress-bar" style={{ width: `${pct}%` }} />
      <style>{`
        .article-progress {
          position: sticky;
          top: 0;
          z-index: 40;
          height: 3px;
          width: 100%;
          background: transparent;
          pointer-events: none;
        }
        .article-progress-bar {
          height: 100%;
          background: linear-gradient(
            90deg,
            var(--color-blue),
            var(--color-ink-2),
            var(--color-red)
          );
          transition: width 0.12s linear;
        }
      `}</style>
    </div>
  );
}
