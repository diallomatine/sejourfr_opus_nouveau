"use client";
import { useEffect, useState } from "react";
import { ChevronUp } from "lucide-react";

/**
 * Bouton flottant qui apparaît après 300px de scroll vertical.
 * Tap target ≥ 44 px, transition CSS simple (pas de framer-motion).
 */
export function BackToTopButton() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const onScroll = () => setVisible(window.scrollY > 300);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <button
      type="button"
      aria-label="Revenir en haut de la page"
      aria-hidden={!visible}
      tabIndex={visible ? 0 : -1}
      onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      className={`back-to-top${visible ? " is-visible" : ""}`}
    >
      <ChevronUp className="back-to-top-icon" />
      <style>{`
        .back-to-top {
          position: fixed;
          bottom: 16px;
          right: 16px;
          z-index: 40;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 48px;
          height: 48px;
          border: 0;
          border-radius: 999px;
          background: var(--color-blue);
          color: #fff;
          box-shadow: 0 6px 20px rgba(15, 24, 57, 0.18);
          cursor: pointer;
          opacity: 0;
          transform: translateY(12px);
          pointer-events: none;
          transition: opacity 0.2s, transform 0.2s, background 0.15s;
        }
        .back-to-top.is-visible {
          opacity: 1;
          transform: translateY(0);
          pointer-events: auto;
        }
        .back-to-top:hover {
          background: var(--color-blue-dark);
        }
        .back-to-top:focus-visible {
          outline: none;
          box-shadow: 0 0 0 4px rgba(30, 58, 140, 0.30);
        }
        @media (min-width: 1024px) {
          .back-to-top {
            bottom: 24px;
            right: 24px;
          }
        }
        .back-to-top-icon {
          width: 20px;
          height: 20px;
        }
      `}</style>
    </button>
  );
}
