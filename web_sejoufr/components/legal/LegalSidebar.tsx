"use client";
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

export interface SidebarSection {
  id: string;
  title: string;
}

interface Props {
  sections: SidebarSection[];
  /** "desktop" : sticky sidebar avec scroll-spy. "mobile" : accordéon collapsible. */
  variant: "desktop" | "mobile";
}

const RELATED_LINKS = [
  { href: "/mentions-legales", label: "Mentions légales" },
  { href: "/cgu", label: "Conditions d'utilisation" },
  { href: "/confidentialite", label: "Politique de confidentialité" },
];

export function LegalSidebar({ sections, variant }: Props) {
  const pathname = usePathname();
  const [activeId, setActiveId] = useState<string | null>(sections[0]?.id ?? null);
  const [open, setOpen] = useState(false);
  const suppressSpyUntil = useRef(0);

  useEffect(() => {
    if (variant !== "desktop") return;
    if (typeof window === "undefined") return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (Date.now() < suppressSpyUntil.current) return;
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
        if (visible) setActiveId(visible.target.id);
      },
      { rootMargin: "-100px 0px -65% 0px", threshold: 0 },
    );
    sections.forEach((s) => {
      const el = document.getElementById(s.id);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, [sections, variant]);

  const handleClick = (e: React.MouseEvent<HTMLAnchorElement>, id: string) => {
    e.preventDefault();
    const el = document.getElementById(id);
    if (!el) return;
    suppressSpyUntil.current = Date.now() + 700;
    setActiveId(id);
    el.scrollIntoView({ behavior: "smooth", block: "start" });
    if (typeof window !== "undefined") {
      window.history.replaceState(null, "", `#${id}`);
    }
    if (variant === "mobile") setOpen(false);
  };

  if (variant === "mobile") {
    return (
      <details
        open={open}
        onToggle={(e) => setOpen((e.target as HTMLDetailsElement).open)}
        className="legal-side-mobile"
      >
        <summary className="legal-side-mobile-sum">
          <span className="legal-side-mobile-sum-label">
            <span className="legal-side-mobile-sum-emoji">📋</span>
            Sommaire
            <span className="legal-side-mobile-sum-count">
              ({sections.length} sections)
            </span>
          </span>
          <span
            aria-hidden
            className={`legal-side-mobile-caret${open ? " is-open" : ""}`}
          >
            ▾
          </span>
        </summary>
        <ol className="legal-side-mobile-list">
          {sections.map((s, i) => (
            <li key={s.id}>
              <a
                href={`#${s.id}`}
                onClick={(e) => handleClick(e, s.id)}
                className="legal-side-mobile-link"
              >
                <span className="legal-side-mobile-num">{i + 1}.</span>
                {s.title}
              </a>
            </li>
          ))}
        </ol>
        <style>{`
          .legal-side-mobile {
            margin-bottom: 32px;
            border: 1px solid var(--color-line);
            border-radius: 16px;
            background: #fff;
            overflow: hidden;
          }
          @media (min-width: 1024px) {
            .legal-side-mobile {
              display: none;
            }
          }
          .legal-side-mobile-sum {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            padding: 12px 16px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            color: var(--color-ink);
            user-select: none;
            min-height: 48px;
            list-style: none;
          }
          .legal-side-mobile-sum::-webkit-details-marker {
            display: none;
          }
          .legal-side-mobile-sum-label {
            display: inline-flex;
            align-items: center;
            gap: 8px;
          }
          .legal-side-mobile-sum-emoji {
            color: var(--color-blue);
          }
          .legal-side-mobile-sum-count {
            font-size: 12px;
            font-weight: 400;
            color: var(--color-muted);
            font-variant-numeric: tabular-nums;
          }
          .legal-side-mobile-caret {
            color: var(--color-muted-2);
            transition: transform 0.15s;
          }
          .legal-side-mobile-caret.is-open {
            transform: rotate(180deg);
          }
          .legal-side-mobile-list {
            list-style: none;
            margin: 0;
            padding: 0 12px 12px 12px;
            display: flex;
            flex-direction: column;
            gap: 2px;
          }
          .legal-side-mobile-link {
            display: block;
            padding: 10px 12px;
            border-radius: 8px;
            font-size: 14px;
            color: var(--color-ink-2);
            min-height: 44px;
            transition: background 0.15s;
          }
          .legal-side-mobile-link:hover {
            background: var(--color-line-2);
          }
          .legal-side-mobile-num {
            color: var(--color-muted-2);
            font-variant-numeric: tabular-nums;
            margin-right: 8px;
          }
        `}</style>
      </details>
    );
  }

  return (
    <aside className="legal-side-desktop">
      <div className="legal-side-desktop-inner">
        <p className="legal-side-desktop-eyebrow">Sommaire</p>
        <ol className="legal-side-desktop-list">
          {sections.map((s, i) => {
            const active = activeId === s.id;
            return (
              <li key={s.id}>
                <a
                  href={`#${s.id}`}
                  onClick={(e) => handleClick(e, s.id)}
                  aria-current={active ? "true" : undefined}
                  className={`legal-side-desktop-link${active ? " is-active" : ""}`}
                >
                  <span className="legal-side-desktop-num">{i + 1}.</span>
                  {s.title}
                </a>
              </li>
            );
          })}
        </ol>

        <hr className="legal-side-desktop-hr" />

        <p className="legal-side-desktop-eyebrow">Voir aussi</p>
        <ul className="legal-side-desktop-rel">
          {RELATED_LINKS.map((l) => {
            const isCurrent = pathname === l.href;
            return (
              <li key={l.href}>
                {isCurrent ? (
                  <span className="legal-side-desktop-rel-cur">{l.label}</span>
                ) : (
                  <Link href={l.href} className="legal-side-desktop-rel-link">
                    {l.label}
                  </Link>
                )}
              </li>
            );
          })}
        </ul>
      </div>
      <style>{`
        .legal-side-desktop {
          display: none;
        }
        @media (min-width: 1024px) {
          .legal-side-desktop {
            display: block;
          }
        }
        .legal-side-desktop-inner {
          position: sticky;
          top: 96px;
          max-height: calc(100vh - 7rem);
          overflow-y: auto;
          padding-right: 16px;
          border-right: 1px solid var(--color-line);
        }
        .legal-side-desktop-eyebrow {
          font-size: 11px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.1em;
          color: var(--color-muted);
          margin: 0 0 12px 0;
        }
        .legal-side-desktop-list {
          list-style: none;
          margin: 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          gap: 2px;
          font-size: 14px;
        }
        .legal-side-desktop-link {
          display: block;
          padding: 6px 8px;
          margin: 0 -8px;
          border-radius: 6px;
          color: var(--color-muted);
          line-height: 1.4;
          transition: color 0.15s, background 0.15s;
        }
        .legal-side-desktop-link:hover {
          color: var(--color-blue);
        }
        .legal-side-desktop-link.is-active {
          color: var(--color-blue);
          font-weight: 600;
          background: rgba(30, 58, 140, 0.05);
        }
        .legal-side-desktop-num {
          color: var(--color-muted-2);
          font-variant-numeric: tabular-nums;
          margin-right: 6px;
        }
        .legal-side-desktop-hr {
          margin: 24px 0;
          border: 0;
          border-top: 1px solid var(--color-line);
        }
        .legal-side-desktop-rel {
          list-style: none;
          margin: 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          gap: 4px;
          font-size: 14px;
        }
        .legal-side-desktop-rel-cur {
          display: block;
          padding: 4px 0;
          color: var(--color-muted-2);
          cursor: default;
        }
        .legal-side-desktop-rel-link {
          display: block;
          padding: 4px 0;
          color: var(--color-muted);
          transition: color 0.15s;
        }
        .legal-side-desktop-rel-link:hover {
          color: var(--color-blue);
        }
      `}</style>
    </aside>
  );
}
