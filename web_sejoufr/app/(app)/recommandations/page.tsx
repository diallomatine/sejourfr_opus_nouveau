"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ChevronRight, Sparkles, Star, XCircle } from "lucide-react";
import { ReinforceRow } from "@/app/_components/ReinforceRow";
import { dashboardApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { DashboardSummaryResponse } from "@/lib/types";

/**
 * Recommandations : liste complète des catégories à renforcer (les deux
 * modules confondus, triées de la plus faible à la plus forte ; les
 * catégories jamais travaillées ferment la liste) + accès rapide aux
 * erreurs / favoris (/revision), qui n'ont plus d'entrée de sidebar
 * depuis la refonte.
 */
export default function RecommandationsPage() {
  const { user, status } = useAuth();

  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [wrongCount, setWrongCount] = useState<number | null>(null);
  const [favCount, setFavCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    (async () => {
      const [sum, wrong, favs] = await Promise.all([
        dashboardApi.summaryCached().catch((): DashboardSummaryResponse | null => null),
        userContentApi.wrong().then((q) => q.length).catch((): number | null => null),
        userContentApi.favorites().then((q) => q.length).catch((): number | null => null),
      ]);
      if (cancelled) return;
      setSummary(sum);
      setWrongCount(wrong);
      setFavCount(favs);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  // Catégories travaillées d'abord (faibles → fortes), puis jamais
  // travaillées ("À découvrir") en fin de liste.
  const ranked = useMemo(() => {
    if (!summary) return [];
    return [...summary.civique, ...summary.tcf].sort((a, b) => {
      if (a.percent === null && b.percent === null) return 0;
      if (a.percent === null) return 1;
      if (b.percent === null) return -1;
      return a.percent - b.percent;
    });
  }, [summary]);

  if (status === "loading" || (loading && status === "authenticated")) {
    return (
      <div className="reco reco-loading" aria-busy>
        <div className="reco-sk" />
        <div className="reco-sk reco-sk-tall" />
        <style>{recoStyles}</style>
      </div>
    );
  }
  if (!user) {
    return (
      <div className="reco-empty">
        <p>
          Session expirée.{" "}
          <Link href="/connexion" className="reco-empty-link">
            Se reconnecter
          </Link>
        </p>
        <style>{recoStyles}</style>
      </div>
    );
  }

  return (
    <main className="reco">
      <header className="reco-head">
        <span className="reco-eyebrow">
          <Sparkles size={14} aria-hidden />
          Recommandations
        </span>
        <h1>Vos priorités de révision</h1>
        <p>
          Concentrez vos efforts sur les catégories les plus fragiles — c&apos;est
          le chemin le plus court vers votre examen.
        </p>
      </header>

      <section className="reco-shortcuts" aria-label="Révision ciblée">
        <Link href="/revision?tab=erreurs" className="reco-shortcut">
          <span className="reco-shortcut-icon reco-shortcut-red" aria-hidden>
            <XCircle size={18} />
          </span>
          <span className="reco-shortcut-body">
            <span className="reco-shortcut-title">Mes erreurs</span>
            <span className="reco-shortcut-sub">
              {wrongCount !== null
                ? `${wrongCount} question${wrongCount > 1 ? "s" : ""} à retravailler`
                : "Questions à retravailler"}
            </span>
          </span>
          <ChevronRight size={16} aria-hidden className="reco-shortcut-arrow" />
        </Link>
        <Link href="/revision?tab=favoris" className="reco-shortcut">
          <span className="reco-shortcut-icon reco-shortcut-blue" aria-hidden>
            <Star size={18} />
          </span>
          <span className="reco-shortcut-body">
            <span className="reco-shortcut-title">Mes favoris</span>
            <span className="reco-shortcut-sub">
              {favCount !== null
                ? `${favCount} question${favCount > 1 ? "s" : ""} mise${favCount > 1 ? "s" : ""} de côté`
                : "Questions mises de côté"}
            </span>
          </span>
          <ChevronRight size={16} aria-hidden className="reco-shortcut-arrow" />
        </Link>
      </section>

      <section className="reco-card" aria-label="Catégories à renforcer">
        <h2>À renforcer, de la plus fragile à la plus solide</h2>
        {ranked.length === 0 ? (
          <p className="reco-none">
            Entraînez-vous pour obtenir des recommandations personnalisées.
          </p>
        ) : (
          <ul className="reco-list">
            {ranked.map((cat) => (
              <ReinforceRow key={cat.code} cat={cat} showModuleTag />
            ))}
          </ul>
        )}
      </section>

      <style>{recoStyles}</style>
    </main>
  );
}

const recoStyles = `
  .reco {
    max-width: 920px;
    margin: 0 auto;
    padding: 30px 28px 48px;
  }

  .reco-head { margin-bottom: 22px; }
  .reco-eyebrow {
    display: inline-flex; align-items: center; gap: 7px;
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--color-blue);
    margin-bottom: 10px;
  }
  .reco-head h1 {
    margin: 0 0 8px;
    font-family: var(--font-sans);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--color-ink);
    line-height: 1.1;
  }
  .reco-head p {
    margin: 0;
    font-size: 15px;
    color: var(--color-muted);
    line-height: 1.5;
    max-width: 56ch;
  }

  /* ===== raccourcis erreurs / favoris ===== */
  .reco-shortcuts {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
    margin-bottom: 22px;
  }
  .reco-shortcut {
    display: flex; align-items: center; gap: 13px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    padding: 16px;
    text-decoration: none;
    min-width: 0;
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  .reco-shortcut:hover {
    border-color: color-mix(in srgb, var(--color-blue) 35%, var(--color-line));
    box-shadow: 0 4px 14px rgba(15, 24, 57, 0.06);
  }
  .reco-shortcut-icon {
    width: 40px; height: 40px;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .reco-shortcut-red { background: var(--color-red-light); color: var(--color-red); }
  .reco-shortcut-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .reco-shortcut-body { flex: 1; min-width: 0; display: flex; flex-direction: column; }
  .reco-shortcut-title {
    font-size: 14.5px; font-weight: 700;
    color: var(--color-ink);
  }
  .reco-shortcut-sub {
    font-size: 12.5px; color: var(--color-muted);
    margin-top: 2px;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .reco-shortcut-arrow { color: var(--color-muted-2); flex-shrink: 0; }

  /* ===== liste complète ===== */
  .reco-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px;
  }
  .reco-card h2 {
    margin: 0 0 16px;
    font-family: var(--font-sans);
    font-size: 17px;
    font-weight: 800;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .reco-list {
    list-style: none;
    margin: 0; padding: 0;
    display: flex; flex-direction: column; gap: 10px;
  }
  .reco-none { margin: 0; font-size: 14px; color: var(--color-muted); }

  /* ===== états ===== */
  .reco-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px;
    color: var(--color-muted);
  }
  .reco-empty-link { color: var(--color-blue); font-weight: 700; }
  .reco-sk {
    height: 90px;
    border-radius: 16px;
    margin-bottom: 16px;
    background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
    background-size: 200% 100%;
    animation: reco-shimmer 1.4s infinite;
  }
  .reco-sk-tall { height: 380px; }
  @keyframes reco-shimmer {
    to { background-position: -200% 0; }
  }

  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .reco { padding: 64px 18px 40px; }
    .reco-shortcuts { grid-template-columns: 1fr; }
  }
`;
