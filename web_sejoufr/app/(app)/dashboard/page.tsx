"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import {
  ArrowRight,
  ChevronRight,
  Flame,
  GraduationCap,
  LayoutGrid,
  Lightbulb,
  Target,
  Trophy,
  Waves,
  Zap,
} from "lucide-react";
import { CategoryBarLine, ReinforceRow } from "@/app/_components/ReinforceRow";
import { attemptApi, dashboardApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { masteryHint, moduleAverage } from "@/lib/dashboard";
import {
  type AttemptSummaryResponse,
  type DashboardCategoryStat,
  type DashboardSummaryResponse,
  isProductionAttempt,
} from "@/lib/types";

/**
 * Tableau de bord (refonte web_refonte) : un seul appel agrégé
 * GET /api/me/dashboard (streak, examens blancs, réussite globale, niveau
 * TCF estimé, catégories par module) + listMine pour le bandeau "reprendre".
 * Les recommandations complètes vivent sur /recommandations.
 */

/** Niveau CECRL compact pour la stat card ("A1 non atteint" → "<A1"). */
function shortLevel(level: DashboardSummaryResponse["estimatedTcfLevel"]): string {
  if (!level) return "—";
  return level === "A1_NON_ATTEINT" ? "<A1" : level;
}

export default function DashboardPage() {
  const { user, status } = useAuth();

  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    (async () => {
      const [sum, atts] = await Promise.all([
        dashboardApi.summaryCached().catch((): DashboardSummaryResponse | null => null),
        attemptApi.listMine({ limit: 10 }).catch((): AttemptSummaryResponse[] => []),
      ]);
      if (cancelled) return;
      setSummary(sum);
      setAttempts(atts);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  // Session QCM non terminée (les productions EE/EO ont leur propre flux).
  const inProgressAttempt = useMemo(
    () => attempts.find((a) => !a.finishedAt && !isProductionAttempt(a)) ?? null,
    [attempts],
  );

  // Top 3 des catégories travaillées les plus faibles, tous modules confondus.
  const weakest = useMemo(() => {
    if (!summary) return [];
    return [...summary.civique, ...summary.tcf]
      .filter((c) => c.percent !== null)
      .sort((a, b) => (a.percent ?? 0) - (b.percent ?? 0))
      .slice(0, 3);
  }, [summary]);

  if (status === "loading" || (loading && status === "authenticated")) {
    return <DashSkeleton />;
  }
  if (!user) {
    return (
      <div className="dash-empty">
        <p>
          Session expirée.{" "}
          <Link href="/connexion" className="dash-empty-link">
            Se reconnecter
          </Link>
        </p>
        <style>{emptyStyle}</style>
      </div>
    );
  }

  const trainingHref =
    user.hasTcf !== false ? "/entrainement?module=TCF" : "/entrainement?module=CIVIQUE";

  return (
    <main className="dash">
      {!user.targetProcedure && (
        <Link href="/parcours?from=/dashboard" className="dash-banner">
          <span>
            <strong>Choisissez votre parcours</strong> (CSP, carte de résident ou
            naturalisation) pour personnaliser votre préparation.
          </span>
          <ArrowRight size={16} aria-hidden />
        </Link>
      )}

      {inProgressAttempt && (
        <Link
          href={`/sessions/${inProgressAttempt.id}`}
          className="dash-banner dash-banner-resume"
        >
          <span>
            <strong>
              {inProgressAttempt.type === "MOCK_EXAM"
                ? "Examen blanc en cours"
                : "Session en cours"}
            </strong>{" "}
            — reprenez là où vous vous êtes arrêté.
          </span>
          <ArrowRight size={16} aria-hidden />
        </Link>
      )}

      <header className="dash-head">
        <div className="dash-head-text">
          <span className="dash-eyebrow">
            <LayoutGrid size={14} aria-hidden />
            Tableau de bord
          </span>
          <h1>
            Bonjour {user.firstName ?? "à vous"} <span aria-hidden>👋</span>
          </h1>
          <p>
            Voici où vous en êtes dans votre préparation. Continuez sur votre
            lancée.
          </p>
        </div>
        <Link href={trainingHref} className="dash-cta">
          <Zap size={16} aria-hidden />
          Entraînement du jour
        </Link>
      </header>

      <section className="stat-grid" aria-label="Vos indicateurs">
        <article className="stat-card">
          <span className="stat-icon stat-icon-blue" aria-hidden>
            <Target size={20} />
          </span>
          <div className="stat-body">
            <span className="stat-value">
              {summary?.globalSuccessPercent !== null &&
              summary?.globalSuccessPercent !== undefined
                ? `${summary.globalSuccessPercent}%`
                : "—"}
            </span>
            <span className="stat-label">Maîtrise globale</span>
            <span className="stat-sub">
              {masteryHint(summary?.globalSuccessPercent ?? null)}
            </span>
          </div>
        </article>

        <article className="stat-card">
          <span className="stat-icon stat-icon-green" aria-hidden>
            <Trophy size={20} />
          </span>
          <div className="stat-body">
            <span className="stat-value">{summary?.mockExamsTotal ?? 0}</span>
            <span className="stat-label">Examens blancs</span>
            <span className="stat-sub">passés au total</span>
          </div>
        </article>

        <article className="stat-card">
          <span className="stat-icon stat-icon-red" aria-hidden>
            <Flame size={20} />
          </span>
          <div className="stat-body">
            <span className="stat-value">{summary?.currentStreakDays ?? 0} j</span>
            <span className="stat-label">Série en cours</span>
            <span className="stat-sub">
              {summary && summary.recordStreakDays > 0
                ? `record : ${summary.recordStreakDays} jours`
                : "lancez votre série !"}
            </span>
          </div>
        </article>

        <article className="stat-card">
          <span className="stat-icon stat-icon-blue" aria-hidden>
            <GraduationCap size={20} />
          </span>
          <div className="stat-body">
            <span className="stat-value">
              {shortLevel(summary?.estimatedTcfLevel ?? null)}
            </span>
            <span className="stat-label">Niveau TCF estimé</span>
            <span className="stat-sub">équivalence CECRL</span>
          </div>
        </article>
      </section>

      <section className="modules-grid" aria-label="Progression par parcours">
        <ModuleCard
          accent="blue"
          icon={<Waves size={20} />}
          title="TCF IRN"
          href="/entrainement?module=TCF"
          categories={summary?.tcf ?? []}
        />
        <ModuleCard
          accent="red"
          icon={<Lightbulb size={20} />}
          title="Examen civique"
          href="/entrainement?module=CIVIQUE"
          categories={summary?.civique ?? []}
        />
      </section>

      <section className="reinforce-card" aria-label="À renforcer en priorité">
        <header className="reinforce-head">
          <h2>À renforcer en priorité</h2>
          <Link href="/recommandations" className="reinforce-all">
            Tout voir <ChevronRight size={15} aria-hidden />
          </Link>
        </header>

        {weakest.length === 0 ? (
          <div className="reinforce-empty">
            <p>
              Entraînez-vous pour obtenir des recommandations personnalisées.
            </p>
            <Link href={trainingHref} className="dash-cta dash-cta-sm">
              <Zap size={15} aria-hidden />
              Commencer
            </Link>
          </div>
        ) : (
          <ul className="reinforce-list">
            {weakest.map((cat) => (
              <ReinforceRow key={cat.code} cat={cat} />
            ))}
          </ul>
        )}
      </section>

      <style>{dashStyles}</style>
    </main>
  );
}

function ModuleCard({
  accent,
  icon,
  title,
  href,
  categories,
}: {
  accent: "blue" | "red";
  icon: React.ReactNode;
  title: string;
  href: string;
  categories: DashboardCategoryStat[];
}) {
  const average = moduleAverage(categories);
  return (
    <article className={`module-card module-card-${accent}`}>
      <header className="module-head">
        <Link href={href} className="module-id">
          <span className={`module-icon module-icon-${accent}`} aria-hidden>
            {icon}
          </span>
          <span className="module-titles">
            <span className="module-title">{title}</span>
            <span className="module-sub">{categories.length} catégories</span>
          </span>
        </Link>
        <span className={`module-pct module-pct-${accent}`}>
          {average !== null ? `${average}%` : "—"}
        </span>
      </header>

      <ul className="module-rows">
        {categories.map((cat) => (
          <li key={cat.code} className="module-row">
            <span className="module-row-label">{cat.label}</span>
            <CategoryBarLine percent={cat.percent} fallback={cat.level ?? "—"} />
          </li>
        ))}
      </ul>
    </article>
  );
}

function DashSkeleton() {
  return (
    <div className="dash dash-skeleton" aria-busy>
      <div className="sk sk-head" />
      <div className="sk-grid">
        <div className="sk sk-card" />
        <div className="sk sk-card" />
        <div className="sk sk-card" />
        <div className="sk sk-card" />
      </div>
      <div className="sk-grid sk-grid-2">
        <div className="sk sk-module" />
        <div className="sk sk-module" />
      </div>
      <style>{dashStyles}</style>
      <style>{`
        .sk {
          background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
          background-size: 200% 100%;
          animation: sk-shimmer 1.4s infinite;
          border-radius: 16px;
        }
        @keyframes sk-shimmer {
          to { background-position: -200% 0; }
        }
        .sk-head { height: 92px; margin-bottom: 22px; }
        .sk-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
          margin-bottom: 22px;
        }
        .sk-grid-2 { grid-template-columns: 1fr 1fr; }
        .sk-card { height: 110px; }
        .sk-module { height: 280px; }
        @media (max-width: 1000px) {
          .sk-grid { grid-template-columns: 1fr 1fr; }
          .sk-grid-2 { grid-template-columns: 1fr; }
        }
        @media (max-width: 560px) {
          .sk-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </div>
  );
}

const emptyStyle = `
  .dash-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px;
    color: var(--color-muted);
  }
  .dash-empty-link { color: var(--color-blue); font-weight: 700; }
`;

const dashStyles = `
  .dash {
    max-width: 1180px;
    margin: 0 auto;
    padding: 30px 28px 48px;
  }

  /* ===== bandeaux ===== */
  .dash-banner {
    display: flex; align-items: center; justify-content: space-between; gap: 14px;
    background: var(--color-blue-light);
    border: 1px solid color-mix(in srgb, var(--color-blue) 18%, transparent);
    color: var(--color-ink);
    border-radius: 14px;
    padding: 13px 18px;
    font-size: 14px;
    text-decoration: none;
    margin-bottom: 14px;
    transition: filter 0.15s;
  }
  .dash-banner:hover { filter: brightness(0.98); }
  .dash-banner strong { color: var(--color-blue); }
  .dash-banner-resume {
    background: var(--color-red-light);
    border-color: color-mix(in srgb, var(--color-red) 18%, transparent);
  }
  .dash-banner-resume strong { color: var(--color-red); }

  /* ===== header ===== */
  .dash-head {
    display: flex; align-items: flex-start; justify-content: space-between;
    gap: 20px;
    margin: 8px 0 24px;
  }
  .dash-head-text { min-width: 0; }
  .dash-eyebrow {
    display: inline-flex; align-items: center; gap: 7px;
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--color-blue);
    margin-bottom: 10px;
  }
  .dash-head h1 {
    margin: 0 0 8px;
    font-family: var(--font-sans);
    font-size: clamp(26px, 4vw, 36px);
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--color-ink);
    line-height: 1.1;
  }
  .dash-head p {
    margin: 0;
    font-size: 15px;
    color: var(--color-muted);
    line-height: 1.5;
  }
  .dash-cta {
    display: inline-flex; align-items: center; gap: 8px;
    background: var(--color-blue);
    color: #fff;
    border-radius: 999px;
    padding: 12px 22px;
    font-size: 14px;
    font-weight: 700;
    text-decoration: none;
    flex-shrink: 0;
    margin-top: 6px;
    transition: background 0.15s;
  }
  .dash-cta:hover { background: var(--color-blue-dark); }
  .dash-cta-sm { padding: 9px 16px; font-size: 13px; margin-top: 0; }

  /* ===== stat cards ===== */
  .stat-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 22px;
  }
  .stat-card {
    display: flex; align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 20px 18px;
    min-width: 0;
  }
  .stat-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .stat-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .stat-icon-green { background: color-mix(in srgb, var(--color-green) 12%, #fff); color: var(--color-green); }
  .stat-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .stat-body { display: flex; flex-direction: column; min-width: 0; }
  .stat-value {
    font-family: var(--font-sans);
    font-size: 24px;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--color-ink);
    line-height: 1.15;
  }
  .stat-label {
    font-size: 13px;
    font-weight: 700;
    color: var(--color-ink-2);
    margin-top: 2px;
  }
  .stat-sub {
    font-size: 12px;
    color: var(--color-muted);
    margin-top: 1px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* ===== module cards ===== */
  .modules-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    margin-bottom: 22px;
  }
  .module-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px;
    min-width: 0;
  }
  .module-head {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    margin-bottom: 18px;
  }
  .module-id {
    display: flex; align-items: center; gap: 12px;
    text-decoration: none;
    min-width: 0;
  }
  .module-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .module-icon-blue { background: var(--color-blue); color: #fff; }
  .module-icon-red { background: var(--color-red); color: #fff; }
  .module-titles { display: flex; flex-direction: column; min-width: 0; }
  .module-title {
    font-size: 17px;
    font-weight: 800;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .module-id:hover .module-title { color: var(--color-blue); }
  .module-sub { font-size: 12.5px; color: var(--color-muted); margin-top: 1px; }
  .module-pct {
    font-family: var(--font-sans);
    font-size: 24px;
    font-weight: 800;
    letter-spacing: -0.02em;
    flex-shrink: 0;
  }
  .module-pct-blue { color: var(--color-blue); }
  .module-pct-red { color: var(--color-red); }

  .module-rows {
    list-style: none;
    margin: 0; padding: 0;
    display: flex; flex-direction: column; gap: 13px;
  }
  .module-row {
    display: grid;
    grid-template-columns: minmax(120px, 190px) 1fr;
    align-items: center;
    gap: 12px;
    min-width: 0;
  }
  .module-row-label {
    font-size: 13.5px;
    color: var(--color-ink-2);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* ===== à renforcer ===== */
  .reinforce-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px;
  }
  .reinforce-head {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    margin-bottom: 16px;
  }
  .reinforce-head h2 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 18px;
    font-weight: 800;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .reinforce-all {
    display: inline-flex; align-items: center; gap: 3px;
    font-size: 13.5px;
    font-weight: 700;
    color: var(--color-blue);
    text-decoration: none;
  }
  .reinforce-all:hover { text-decoration: underline; }

  .reinforce-list {
    list-style: none;
    margin: 0; padding: 0;
    display: flex; flex-direction: column; gap: 10px;
  }
  .reinforce-empty {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    flex-wrap: wrap;
  }
  .reinforce-empty p { margin: 0; font-size: 14px; color: var(--color-muted); }

  /* ===== responsive ===== */
  @media (max-width: 1000px) {
    .stat-grid { grid-template-columns: 1fr 1fr; }
    .modules-grid { grid-template-columns: 1fr; }
  }
  @media (max-width: 768px) {
    /* padding-top dégage le burger fixed du drawer mobile (.ms-toggle). */
    .dash { padding: 64px 18px 40px; }
    .dash-head { flex-direction: column; }
    .dash-cta { margin-top: 0; }
  }
  @media (max-width: 560px) {
    .stat-grid { grid-template-columns: 1fr; }
    .module-row { grid-template-columns: 1fr; gap: 6px; }
  }
`;
