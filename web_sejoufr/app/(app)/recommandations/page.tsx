"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import {
  ChevronRight,
  CircleHelp,
  Compass,
  PartyPopper,
  Sparkles,
  Star,
  Target,
  TrendingDown,
  XCircle,
} from "lucide-react";
import { ReinforceRow } from "@/app/_components/ReinforceRow";
import { dashboardApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { categoryExamsHref, categoryHref } from "@/lib/dashboard";
import type { DashboardCategoryStat, DashboardSummaryResponse } from "@/lib/types";

type ModuleFilter = "ALL" | "TCF" | "CIVIQUE";

// ============================================================================
// Règles des priorités (validées 2026-06-06) — max 5 cards, 1 par catégorie,
// dérivées des CategoryStat du dashboard + du compteur d'erreurs :
//   1. En baisse      dernier examen < avant-dernier
//   2. Point faible   progression < 60 % avec ≥ 20 répondues (EE/EO : note basse)
//   3. À confirmer    réussite brute ≥ 70 % mais confiance incomplète (< 40 rép.)
//   4. Jamais travaillé   percent null (EE/EO d'abord : épreuves obligatoires)
//   5. Erreurs        ≥ 5 erreurs non revues → /revision
// Tri : n° de règle puis progression croissante.
// ============================================================================

interface Priority {
  rule: 1 | 2 | 3 | 4 | 5;
  key: string;
  badge: string;
  tone: "red" | "amber" | "blue" | "slate";
  icon: React.ReactNode;
  title: string;
  reason: string;
  ctaLabel: string;
  href: string;
  percent: number | null;
}

const MAX_PRIORITIES = 5;
const WEAK_THRESHOLD = 60;
const CONFIRM_SUCCESS_THRESHOLD = 70;
const QCM_CONFIDENCE_SAMPLE = 40;
const MIN_WRONG_FOR_CARD = 5;

function isProductionCat(cat: DashboardCategoryStat): boolean {
  return cat.code === "TCF_EE" || cat.code === "TCF_EO";
}

function examOutOf(cat: DashboardCategoryStat): number {
  return isProductionCat(cat) ? 20 : cat.code.startsWith("TCF") ? 25 : 20;
}

/** Réussite brute estimée (progression ÷ confiance) pour la règle 3. */
function rawSuccess(cat: DashboardCategoryStat): number | null {
  if (cat.percent === null || isProductionCat(cat)) return null;
  const sample = Math.max(1, Math.min(QCM_CONFIDENCE_SAMPLE, cat.total || QCM_CONFIDENCE_SAMPLE));
  const confiance = Math.min(1, cat.answered / sample);
  if (confiance === 0) return null;
  return Math.round(cat.percent / confiance);
}

function buildPriorities(
  summary: DashboardSummaryResponse,
  wrongCount: number | null,
): Priority[] {
  const cats = [...summary.civique, ...summary.tcf];
  // EE/EO en tête pour la règle 4 (épreuves obligatoires du TCF IRN).
  cats.sort((a, b) => Number(isProductionCat(b)) - Number(isProductionCat(a)));

  const out: Priority[] = [];
  const taken = new Set<string>();
  const push = (p: Priority) => {
    if (!taken.has(p.key)) {
      taken.add(p.key);
      out.push(p);
    }
  };

  for (const cat of cats) {
    // 1. En baisse
    if (
      cat.lastMockScore != null &&
      cat.prevMockScore != null &&
      cat.lastMockScore < cat.prevMockScore
    ) {
      push({
        rule: 1,
        key: cat.code,
        badge: "En baisse",
        tone: "red",
        icon: <TrendingDown size={17} />,
        title: cat.label,
        reason: `${cat.prevMockScore}/${examOutOf(cat)} → ${cat.lastMockScore}/${examOutOf(cat)} au dernier examen.`,
        ctaLabel: "Refaire un examen",
        href: categoryExamsHref(cat),
        percent: cat.percent,
      });
    }
  }
  for (const cat of cats) {
    // 2. Point faible
    const enoughPractice = isProductionCat(cat) ? cat.percent !== null : cat.answered >= 20;
    if (cat.percent !== null && cat.percent < WEAK_THRESHOLD && enoughPractice) {
      push({
        rule: 2,
        key: cat.code,
        badge: "Point faible",
        tone: "amber",
        icon: <Target size={17} />,
        title: cat.label,
        reason: isProductionCat(cat)
          ? `Note moyenne basse (${cat.percent} %) sur vos dernières soumissions.`
          : `${cat.percent} % de réussite — c'est votre priorité d'entraînement.`,
        ctaLabel: isProductionCat(cat) ? "S'exercer" : "Série ciblée",
        href: categoryHref(cat),
        percent: cat.percent,
      });
    }
  }
  for (const cat of cats) {
    // 3. À confirmer
    const success = rawSuccess(cat);
    if (
      success !== null &&
      success >= CONFIRM_SUCCESS_THRESHOLD &&
      cat.answered < Math.min(QCM_CONFIDENCE_SAMPLE, cat.total || QCM_CONFIDENCE_SAMPLE)
    ) {
      push({
        rule: 3,
        key: cat.code,
        badge: "À confirmer",
        tone: "blue",
        icon: <CircleHelp size={17} />,
        title: cat.label,
        reason: `${Math.min(100, success)} % de réussite mais sur ${cat.answered} question${cat.answered > 1 ? "s" : ""} seulement — confirmez.`,
        ctaLabel: "Examen blanc",
        href: categoryExamsHref(cat),
        percent: cat.percent,
      });
    }
  }
  for (const cat of cats) {
    // 4. Jamais travaillé
    if (cat.percent === null) {
      push({
        rule: 4,
        key: cat.code,
        badge: "À découvrir",
        tone: "slate",
        icon: <Compass size={17} />,
        title: cat.label,
        reason: isProductionCat(cat)
          ? "Épreuve obligatoire du TCF IRN, jamais évaluée."
          : "Jamais travaillée pour l'instant.",
        ctaLabel: isProductionCat(cat) ? "S'exercer" : "Découvrir",
        href: categoryHref(cat),
        percent: null,
      });
    }
  }
  // 5. Erreurs à recycler
  if (wrongCount != null && wrongCount >= MIN_WRONG_FOR_CARD) {
    push({
      rule: 5,
      key: "__erreurs__",
      badge: "Erreurs",
      tone: "red",
      icon: <XCircle size={17} />,
      title: "Vos erreurs",
      reason: `${wrongCount} question${wrongCount > 1 ? "s" : ""} ratée${wrongCount > 1 ? "s" : ""} à retravailler.`,
      ctaLabel: "Mes erreurs",
      href: "/revision?tab=erreurs",
      percent: null,
    });
  }

  out.sort(
    (a, b) =>
      a.rule - b.rule ||
      (a.percent ?? 101) - (b.percent ?? 101),
  );
  return out.slice(0, MAX_PRIORITIES);
}

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
  const [filter, setFilter] = useState<ModuleFilter>("ALL");
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

  const priorities = useMemo(
    () => (summary ? buildPriorities(summary, wrongCount) : []),
    [summary, wrongCount],
  );

  // Catégories travaillées d'abord (faibles → fortes), puis jamais
  // travaillées ("À découvrir") en fin de liste. Filtrables par parcours
  // (même filtre que /historique).
  const ranked = useMemo(() => {
    if (!summary) return [];
    const all = [...summary.civique, ...summary.tcf].sort((a, b) => {
      if (a.percent === null && b.percent === null) return 0;
      if (a.percent === null) return 1;
      if (b.percent === null) return -1;
      return a.percent - b.percent;
    });
    if (filter === "ALL") return all;
    return all.filter((c) =>
      filter === "TCF" ? c.code.startsWith("TCF") : !c.code.startsWith("TCF"),
    );
  }, [summary, filter]);

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

      <section className="reco-card" aria-label="Vos priorités">
        <h2>Vos priorités</h2>
        {priorities.length === 0 ? (
          <div className="reco-allgood">
            <PartyPopper size={18} aria-hidden />
            <p>
              Rien d&apos;urgent — tout est solide. Entretenez votre niveau avec un{" "}
              <Link href="/examens-blancs">examen blanc complet</Link>.
            </p>
          </div>
        ) : (
          <ul className="reco-prio-list">
            {priorities.map((p) => (
              <li key={p.key} className="reco-prio">
                <span className={`reco-prio-icon reco-prio-${p.tone}`} aria-hidden>
                  {p.icon}
                </span>
                <span className="reco-prio-body">
                  <span className="reco-prio-top">
                    <span className={`reco-prio-badge reco-prio-badge-${p.tone}`}>
                      {p.badge}
                    </span>
                    <span className="reco-prio-title">{p.title}</span>
                  </span>
                  <span className="reco-prio-reason">{p.reason}</span>
                </span>
                <Link href={p.href} className="reco-prio-cta">
                  {p.ctaLabel}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="reco-card" aria-label="Catégories à renforcer">
        <h2>À renforcer, de la plus fragile à la plus solide</h2>
        <div className="reco-filters">
          {(
            [
              ["ALL", "Tous"],
              ["TCF", "TCF IRN"],
              ["CIVIQUE", "Examen civique"],
            ] as [ModuleFilter, string][]
          ).map(([key, label]) => (
            <button
              key={key}
              type="button"
              className={`reco-chip ${filter === key ? "is-active" : ""}`}
              onClick={() => setFilter(key)}
            >
              {label}
            </button>
          ))}
        </div>
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

  /* ===== priorités ===== */
  .reco-prio-list {
    list-style: none;
    margin: 0; padding: 0;
    display: flex; flex-direction: column; gap: 10px;
  }
  .reco-prio {
    display: flex; align-items: center; gap: 14px;
    border: 1px solid var(--color-line);
    border-radius: 13px;
    padding: 14px 16px;
    min-width: 0;
    background: #fff;
  }
  .reco-prio-icon {
    width: 38px; height: 38px;
    border-radius: 10px;
    display: grid; place-items: center;
    flex-shrink: 0;
  }
  .reco-prio-red { background: var(--color-red-light); color: var(--color-red); }
  .reco-prio-amber { background: color-mix(in srgb, var(--color-amber) 18%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .reco-prio-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .reco-prio-slate { background: var(--color-paper-2); color: var(--color-muted); }
  .reco-prio-body { flex: 1; min-width: 0; }
  .reco-prio-top {
    display: flex; align-items: center; gap: 8px;
    margin-bottom: 4px;
    min-width: 0;
  }
  .reco-prio-badge {
    font-family: var(--font-mono);
    font-size: 10px; font-weight: 700;
    letter-spacing: 0.08em; text-transform: uppercase;
    padding: 2px 7px; border-radius: 6px;
    flex-shrink: 0;
  }
  .reco-prio-badge-red { background: var(--color-red-light); color: var(--color-red); }
  .reco-prio-badge-amber { background: color-mix(in srgb, var(--color-amber) 18%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .reco-prio-badge-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .reco-prio-badge-slate { background: var(--color-paper-2); color: var(--color-muted); }
  .reco-prio-title {
    font-size: 14px; font-weight: 700;
    color: var(--color-ink);
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .reco-prio-reason {
    display: block;
    font-size: 12.5px; color: var(--color-muted);
    line-height: 1.45;
  }
  .reco-prio-cta {
    background: var(--color-blue-light);
    color: var(--color-blue);
    border-radius: 999px;
    padding: 9px 16px;
    font-size: 13px; font-weight: 700;
    text-decoration: none;
    flex-shrink: 0;
    white-space: nowrap;
    transition: background 0.15s, color 0.15s;
  }
  .reco-prio-cta:hover { background: var(--color-blue); color: #fff; }
  .reco-allgood {
    display: flex; align-items: center; gap: 10px;
    background: color-mix(in srgb, var(--color-green) 10%, #fff);
    border: 1px solid color-mix(in srgb, var(--color-green) 30%, transparent);
    border-radius: 12px;
    padding: 14px 16px;
    color: var(--color-green);
  }
  .reco-allgood p { margin: 0; font-size: 14px; color: var(--color-ink-2); }
  .reco-allgood a { color: var(--color-blue); font-weight: 700; }
  @media (max-width: 560px) {
    .reco-prio { flex-wrap: wrap; }
    .reco-prio-body { order: 3; flex-basis: 100%; }
  }

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
  .reco-filters {
    display: flex; flex-wrap: wrap; gap: 8px;
    margin-bottom: 16px;
  }
  .reco-chip {
    padding: 8px 16px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 999px;
    font-family: var(--font-sans);
    font-size: 13px; font-weight: 600;
    color: var(--color-ink-2);
    cursor: pointer;
    transition: all 0.15s;
  }
  .reco-chip:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .reco-chip.is-active {
    background: var(--color-blue);
    border-color: var(--color-blue);
    color: #fff;
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
