"use client";

import Link from "next/link";
import { ProgresMouvement } from "@/app/_components/progres/ProgresMouvement";
import { useEffect, useState } from "react";
import {
  BarChart3,
  BookOpen,
  Gavel,
  Globe,
  Headphones,
  Landmark,
  Lightbulb,
  Mic,
  Minus,
  PenLine,
  Scale,
  SpellCheck,
  TrendingDown,
  TrendingUp,
  Users,
  Waves,
} from "lucide-react";
import { CategoryBarLine } from "@/app/_components/ReinforceRow";
import { ProgressDonut } from "@/app/_components/hub/ModuleHubParts";
import { PlanDomainsSummary } from "@/app/_components/plan/PlanDomainsSummary";
import { dashboardApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { categoryBadge, categoryHref, moduleAverage, successHint } from "@/lib/dashboard";
import {
  type DashboardCategoryStat,
  type DashboardSummaryResponse,
  estimatedTcfLevelScopeLabel,
  niveauCecrlLabel,
} from "@/lib/types";

/** Tonalité d'une catégorie (mêmes couleurs que les cards des hubs). */
const CATEGORY_TONES: Record<string, string> = {
  TCF_CO: "blue",
  TCF_CE: "green",
  TCF_STRUCTURE: "amber",
  TCF_EE: "slate",
  TCF_EO: "red",
  CIV_PRINCIPES: "blue",
  CIV_INSTITUTIONS: "green",
  CIV_DROITS_DEVOIRS: "amber",
  CIV_HISTOIRE_GEO: "red",
  CIV_SOCIETE: "slate",
};

/** Icône d'une catégorie (mêmes pictos que les hubs). */
const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  TCF_CO: <Headphones size={18} strokeWidth={1.8} />,
  TCF_CE: <BookOpen size={18} strokeWidth={1.8} />,
  TCF_STRUCTURE: <SpellCheck size={18} strokeWidth={1.8} />,
  TCF_EE: <PenLine size={18} strokeWidth={1.8} />,
  TCF_EO: <Mic size={18} strokeWidth={1.8} />,
  CIV_PRINCIPES: <Scale size={18} strokeWidth={1.8} />,
  CIV_INSTITUTIONS: <Landmark size={18} strokeWidth={1.8} />,
  CIV_DROITS_DEVOIRS: <Gavel size={18} strokeWidth={1.8} />,
  CIV_HISTOIRE_GEO: <Globe size={18} strokeWidth={1.8} />,
  CIV_SOCIETE: <Users size={18} strokeWidth={1.8} />,
};

/**
 * /statistiques — « Ma progression » (maquette sejour_fr.html) : 3 cards
 * donut (maîtrise globale / TCF avec niveau estimé / civique) + une section
 * par parcours listant chaque catégorie (icône, nb d'examens + record,
 * barre de réussite, tendance dernier vs avant-dernier examen, badge).
 * Chaque ligne ouvre l'entraînement de la catégorie.
 */
export default function StatistiquesPage() {
  const { user, status } = useAuth();
  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    dashboardApi
      .summaryCached()
      .then((d) => {
        if (cancelled) return;
        setSummary(d);
        setLoading(false);
      })
      .catch(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  if (status === "loading" || (loading && status === "authenticated")) {
    return (
      <div className="prog prog-loading" aria-busy>
        <div className="prog-sk" />
        <div className="prog-sk prog-sk-tall" />
        <style>{styles}</style>
      </div>
    );
  }
  if (!user) {
    return (
      <div className="prog-empty">
        <p>
          Session expirée.{" "}
          <Link href="/connexion" className="prog-empty-link">
            Se reconnecter
          </Link>
        </p>
        <style>{styles}</style>
      </div>
    );
  }

  const tcfAvg = summary ? moduleAverage(summary.tcf) : null;
  const civiqueAvg = summary ? moduleAverage(summary.civique) : null;
  const globalAvg = summary?.globalSuccessPercent ?? null;

  return (
    <main className="prog">
      <header className="prog-head">
        <div className="prog-eyebrow">
          <BarChart3 size={16} aria-hidden />
          <span>Suivi</span>
        </div>
        <h1>Ma progression</h1>
        <p>Votre maîtrise par parcours et par catégorie, au fil de vos entraînements.</p>
      </header>

      <section className="prog-donuts" aria-label="Vue d'ensemble">
        <DonutCard
          label="Maîtrise globale"
          percent={globalAvg}
          headline={successHint(globalAvg)}
          chip="Tous parcours confondus"
          chipTone="neutral"
        />
        <DonutCard
          label="TCF IRN"
          percent={tcfAvg}
          headline={
            summary?.estimatedTcfLevel
              ? `Niveau estimé ${niveauCecrlLabel(summary.estimatedTcfLevel)}`
              : successHint(tcfAvg)
          }
          /* Un niveau qui ne porte pas sur les 4 épreuves le dit ici. */
          hint={estimatedTcfLevelScopeLabel(summary)}
          chip={`${summary?.tcf.length ?? 5} catégories`}
          chipTone="blue"
        />
        <DonutCard
          label="Examen civique"
          percent={civiqueAvg}
          headline={successHint(civiqueAvg)}
          chip={`${summary?.civique.length ?? 5} catégories`}
          chipTone="red"
        />
      </section>

      {/* 🛑 **Ce qui a BOUGÉ** (T28, `30_` §7), greffé ici plutôt que sur une
          troisième page « progression » : le dépôt en a déjà deux, et elles
          répondent à « où j'en suis ». Ce bloc répond à « qu'est-ce qui a
          bougé ». */}
      <ProgresMouvement />

      {/* Les 4 domaines du TCF, dans l'ordre d'urgence décidé par le serveur :
          un pourcentage global ne dit pas OÙ le candidat bloque, une épreuve
          jamais mesurée si. */}
      <PlanDomainsSummary />

      <ModuleProgressSection
        icon={<Waves size={18} strokeWidth={2} />}
        title="TCF IRN"
        categories={summary?.tcf ?? []}
        examOutOf={25}
      />
      <ModuleProgressSection
        icon={<Lightbulb size={18} strokeWidth={2} />}
        title="Examen civique"
        categories={summary?.civique ?? []}
        examOutOf={20}
      />

      <style>{styles}</style>
    </main>
  );
}

function DonutCard({
  label,
  percent,
  headline,
  hint,
  chip,
  chipTone,
}: {
  label: string;
  percent: number | null;
  headline: string;
  /** Précision facultative sous le titre (périmètre d'un niveau estimé
   *  partiel). Absente ⇒ la carte garde exactement sa forme d'origine. */
  hint?: string | null;
  chip: string;
  chipTone: "neutral" | "blue" | "red";
}) {
  return (
    <article className="prog-donut-card">
      <span className="prog-donut-label">{label}</span>
      <div className="prog-donut-row">
        <ProgressDonut percent={percent} />
        <div className="prog-donut-text">
          <span className="prog-donut-headline">{headline}</span>
          {hint && <span className="prog-donut-hint">{hint}</span>}
          <span className={`prog-chip prog-chip-${chipTone}`}>{chip}</span>
        </div>
      </div>
    </article>
  );
}

function ModuleProgressSection({
  icon,
  title,
  categories,
  examOutOf,
}: {
  icon: React.ReactNode;
  title: string;
  categories: DashboardCategoryStat[];
  examOutOf: number;
}) {
  return (
    <section className="prog-module">
      <header className="prog-module-head">
        <span className="prog-module-icon" aria-hidden>
          {icon}
        </span>
        <h2>{title}</h2>
      </header>
      <ul className="prog-rows">
        {categories.map((cat) => (
          <CategoryRow key={cat.code} cat={cat} examOutOf={examOutOf} />
        ))}
      </ul>
    </section>
  );
}

function CategoryRow({
  cat,
  examOutOf,
}: {
  cat: DashboardCategoryStat;
  examOutOf: number;
}) {
  const isProduction = cat.code === "TCF_EE" || cat.code === "TCF_EO";
  const stat = categoryBadge(cat.percent);

  const sub = isProduction
    ? cat.level
      ? `Niveau estimé ${niveauCecrlLabel(cat.level)}`
      : "Évaluation IA · pas encore évaluée"
    : cat.mockExams > 0
      ? `${cat.mockExams} examen${cat.mockExams > 1 ? "s" : ""}${
          cat.bestMockScore != null ? ` · record ${cat.bestMockScore}/${examOutOf}` : ""
        }`
      : "Pas encore d'examen";

  // Tendance : dernier examen vs avant-dernier (— si moins de 2 examens).
  const trend =
    cat.lastMockScore != null && cat.prevMockScore != null
      ? cat.lastMockScore > cat.prevMockScore
        ? "up"
        : cat.lastMockScore < cat.prevMockScore
          ? "down"
          : "flat"
      : null;

  return (
    <li>
      <Link href={categoryHref(cat)} className="prog-row">
        <span
          className={`prog-row-icon prog-icon-${CATEGORY_TONES[cat.code] ?? "blue"}`}
          aria-hidden
        >
          {CATEGORY_ICONS[cat.code] ?? <BarChart3 size={18} strokeWidth={1.8} />}
        </span>
        <span className="prog-row-titles">
          <span className="prog-row-title">{cat.label}</span>
          <span className="prog-row-sub">{sub}</span>
        </span>
        <span className="prog-row-bar">
          <CategoryBarLine percent={cat.percent} fallback={cat.level ?? "—"} />
        </span>
        <span className={`prog-trend prog-trend-${trend ?? "none"}`} aria-hidden>
          {trend === "up" ? (
            <TrendingUp size={17} />
          ) : trend === "down" ? (
            <TrendingDown size={17} />
          ) : (
            <Minus size={15} />
          )}
        </span>
        <span className={`prog-badge prog-badge-${stat.tone}`}>{stat.label}</span>
      </Link>
    </li>
  );
}

const styles = `
  .prog {
    max-width: 1180px;
    margin: 0 auto;
    padding: 30px 40px 80px;
  }

  /* ===== header ===== */
  .prog-head { margin-bottom: 22px; }
  .prog-eyebrow {
    display: inline-flex; align-items: center; gap: 8px;
    font-size: 13px; font-weight: 700;
    letter-spacing: 0.04em; text-transform: uppercase;
    color: var(--color-blue);
    margin-bottom: 8px;
  }
  .prog-head h1 {
    margin: 0 0 8px;
    font-family: var(--font-sans);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.1;
  }
  .prog-head p {
    margin: 0;
    color: var(--color-muted);
    font-size: 15.5px; line-height: 1.5;
  }

  /* ===== donut cards ===== */
  .prog-donuts {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 22px;
  }
  .prog-donut-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px 20px;
    min-width: 0;
  }
  .prog-donut-label {
    display: block;
    font-size: 12.5px; font-weight: 600;
    color: var(--color-muted-2);
    margin-bottom: 12px;
  }
  .prog-donut-row { display: flex; align-items: center; gap: 16px; }
  .prog-donut-text { min-width: 0; }
  .prog-donut-headline {
    display: block;
    font-family: var(--font-sans);
    font-size: 19px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
    margin-bottom: 7px;
  }
  /* Périmètre d'un niveau estimé partiel : une précision, pas une alerte. */
  .prog-donut-hint {
    display: block;
    font-family: var(--font-sans);
    font-size: 12px; font-weight: 500; line-height: 1.35;
    color: var(--color-muted-2);
    margin: -3px 0 7px;
    overflow-wrap: anywhere;
  }
  .prog-chip {
    display: inline-block;
    font-size: 11.5px; font-weight: 700;
    padding: 4px 10px; border-radius: 999px;
    white-space: nowrap;
  }
  .prog-chip-neutral { background: var(--color-line-2); color: var(--color-muted); }
  .prog-chip-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .prog-chip-red { background: var(--color-red-light); color: var(--color-red); }

  /* ===== sections module ===== */
  .prog-module {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 0 0 8px;
    margin-bottom: 22px;
    overflow: hidden;
  }
  .prog-module-head {
    display: flex; align-items: center; gap: 10px;
    padding: 14px 22px;
    background: var(--color-blue-soft);
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 4px;
  }
  .prog-module-icon { color: var(--color-blue); display: flex; }
  .prog-module-head h2 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 15.5px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
  }

  .prog-rows { list-style: none; margin: 0; padding: 0; }
  .prog-row {
    display: grid;
    grid-template-columns: 38px minmax(180px, 1.1fr) 1.4fr 28px 110px;
    align-items: center;
    gap: 14px;
    padding: 14px 22px;
    text-decoration: none;
    border-bottom: 1px solid var(--color-line-2);
    transition: background 0.15s;
    min-width: 0;
  }
  .prog-rows li:last-child .prog-row { border-bottom: none; }
  .prog-row:hover { background: var(--color-blue-soft); }

  .prog-row-icon {
    width: 38px; height: 38px;
    border-radius: 11px;
    display: grid; place-items: center;
  }
  .prog-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .prog-icon-green { background: color-mix(in srgb, var(--color-green) 14%, #fff); color: var(--color-green); }
  .prog-icon-amber { background: color-mix(in srgb, var(--color-amber) 18%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .prog-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .prog-icon-slate { background: var(--color-paper-2); color: var(--color-muted); }
  .prog-row-titles { min-width: 0; }
  .prog-row-title {
    display: block;
    font-size: 14px; font-weight: 700;
    color: var(--color-ink);
    line-height: 1.3;
  }
  .prog-row-sub {
    display: block;
    font-size: 12px; color: var(--color-muted);
    margin-top: 2px;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .prog-row-bar { min-width: 0; }

  .prog-trend { display: flex; justify-content: center; }
  .prog-trend-up { color: var(--color-green); }
  .prog-trend-down { color: var(--color-red); }
  .prog-trend-flat { color: var(--color-muted-2); }
  .prog-trend-none { color: var(--color-muted-2); opacity: 0.5; }

  .prog-badge {
    font-size: 12px; font-weight: 600;
    padding: 5px 11px; border-radius: 999px;
    text-align: center;
    white-space: nowrap;
  }
  .prog-badge-green { background: color-mix(in srgb, var(--color-green) 12%, #fff); color: var(--color-green); }
  .prog-badge-blue { background: var(--color-blue-light); color: var(--color-blue-dark); }
  .prog-badge-amber { background: color-mix(in srgb, var(--color-amber) 14%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .prog-badge-none { background: var(--color-line-2); color: var(--color-muted); }

  /* ===== états ===== */
  .prog-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px; color: var(--color-muted);
  }
  .prog-empty-link { color: var(--color-blue); font-weight: 700; }
  .prog-sk {
    height: 120px; border-radius: 16px; margin-bottom: 16px;
    background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
    background-size: 200% 100%;
    animation: prog-shimmer 1.4s infinite;
  }
  .prog-sk-tall { height: 420px; }
  @keyframes prog-shimmer { to { background-position: -200% 0; } }

  /* ===== responsive ===== */
  @media (max-width: 1000px) {
    .prog-donuts { grid-template-columns: 1fr; }
    .prog-row {
      grid-template-columns: 38px 1fr 28px 110px;
    }
    .prog-row-bar { grid-column: 2 / -1; grid-row: 2; }
  }
  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .prog { padding: 64px 18px 48px; }
    .prog-badge { display: none; }
    .prog-row { grid-template-columns: 38px 1fr 28px; gap: 10px; }
  }
`;
