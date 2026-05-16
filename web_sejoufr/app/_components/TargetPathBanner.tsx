"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { TargetProcedure, TargetLevel } from "@/lib/types";

const PROC_INFO: Record<TargetProcedure, { title: string; sub: string }> = {
  CSP: {
    title: "Titre de séjour pluriannuel",
    sub: "Vous préparez la procédure CSP. Difficulté A1/A2 pour l'examen civique.",
  },
  CR: {
    title: "Carte de résident",
    sub: "Vous préparez la procédure CR. Difficulté A2/B1 pour l'examen civique.",
  },
  NAT: {
    title: "Naturalisation française",
    sub: "Vous préparez la procédure NAT. Difficulté B1/B2 pour l'examen civique.",
  },
};

const LEVEL_INFO: Record<TargetLevel, { title: string; sub: string }> = {
  A2: { title: "Niveau A2", sub: "Utilisateur élémentaire — usage de la vie quotidienne." },
  B1: { title: "Niveau B1", sub: "Utilisateur indépendant — sujets familiers, échanges courants." },
  B2: { title: "Niveau B2", sub: "Utilisateur indépendant avancé — opinions, argumentation." },
};

export function TargetPathBanner({
  procedure,
  level,
}: {
  procedure?: TargetProcedure | null;
  level?: TargetLevel | null;
}) {
  const pathname = usePathname();
  const proc = procedure ? PROC_INFO[procedure] : null;
  const lvl = level ? LEVEL_INFO[level] : null;
  const primary = proc ?? lvl;
  const code = procedure ?? level;
  if (!primary || !code) return null;
  const editHref = `/parcours?from=${encodeURIComponent(pathname || "/profil")}`;

  return (
    <Link href={editHref} className="tpb" aria-label="Modifier mon parcours">
      <div className="tpb-icon" aria-hidden>
        <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
          <circle cx="12" cy="10" r="3" />
        </svg>
      </div>
      <div className="tpb-content">
        <div className="tpb-head">
          <span className="tpb-eyebrow">VOTRE PARCOURS</span>
          <span className="tpb-badge">{code}</span>
        </div>
        <div className="tpb-title">{primary.title}</div>
        <div className="tpb-sub">{primary.sub}</div>
      </div>
      <div className="tpb-arrow" aria-hidden>›</div>

      <style>{`
        .tpb {
          display: flex; align-items: center; gap: 14px;
          background: linear-gradient(135deg, var(--color-blue-soft) 0%, #fff 100%);
          border: 1px solid var(--color-blue-light);
          border-radius: 14px;
          padding: 14px 16px;
          text-decoration: none;
          color: inherit;
          transition: all 0.15s;
        }
        .tpb:hover {
          border-color: var(--color-blue);
          box-shadow: 0 8px 24px -10px rgba(30, 58, 140, 0.18);
        }
        .tpb-icon {
          width: 40px; height: 40px;
          background: var(--color-blue);
          color: #fff;
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          flex-shrink: 0;
        }
        .tpb-content { flex: 1; min-width: 0; }
        .tpb-head { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
        .tpb-eyebrow {
          font-family: var(--font-mono);
          font-size: 9.5px; letter-spacing: 0.14em;
          color: var(--color-muted); font-weight: 600;
        }
        .tpb-badge {
          font-family: var(--font-mono);
          background: var(--color-blue);
          color: #fff;
          padding: 2px 7px; border-radius: 4px;
          font-size: 10px; font-weight: 700; letter-spacing: 0.08em;
        }
        .tpb-title {
          font-family: var(--font-sans);
          font-weight: 700; font-size: 14.5px;
          color: var(--color-ink);
        }
        .tpb-sub {
          font-size: 12.5px; color: var(--color-muted);
          line-height: 1.4; margin-top: 2px;
        }
        .tpb-arrow {
          font-size: 24px; color: var(--color-muted-2);
          flex-shrink: 0;
        }
      `}</style>
    </Link>
  );
}
