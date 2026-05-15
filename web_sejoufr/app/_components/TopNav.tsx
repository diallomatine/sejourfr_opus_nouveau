"use client";

import Link from "next/link";
import { Brand } from "./Brand";

const navStyles: React.CSSProperties = {
  position: "sticky",
  top: 0,
  zIndex: 50,
  background: "rgba(250,250,247,0.85)",
  backdropFilter: "blur(14px)",
  WebkitBackdropFilter: "blur(14px)",
  borderBottom: "1px solid var(--color-line)",
};

const innerStyles: React.CSSProperties = {
  maxWidth: 1180,
  margin: "0 auto",
  padding: "16px 28px",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  gap: 32,
};

const linksStyles: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 28,
  fontSize: 14,
  fontWeight: 500,
  color: "var(--color-ink-2)",
};

const ctasStyles: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 10,
};

export function TopNav() {
  return (
    <nav style={navStyles} aria-label="Navigation principale">
      <div style={innerStyles}>
        <Brand />
        <div className="nav-links-hide-mobile" style={linksStyles}>
          <Link href="/#examens">Examens</Link>
          <Link href="/#methode">Méthode</Link>
          <Link href="/#tarifs">Tarifs</Link>
          <Link href="/#temoignages">Témoignages</Link>
          <Link href="/#faq">FAQ</Link>
        </div>
        <div style={ctasStyles}>
          <Link href="/connexion" className="btn btn-link-soft hide-on-mobile">
            Connexion
          </Link>
          <Link href="/inscription" className="btn">
            Commencer gratuitement
          </Link>
        </div>
      </div>

      {/* Style local pour cacher les links nav sur mobile */}
      <style>{`
        @media (max-width: 960px) {
          .nav-links-hide-mobile { display: none !important; }
        }
        @media (max-width: 480px) {
          .hide-on-mobile { display: none !important; }
        }
      `}</style>
    </nav>
  );
}
