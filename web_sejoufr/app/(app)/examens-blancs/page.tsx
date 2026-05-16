"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ApiException, attemptApi, examApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type {
  AttemptSummaryResponse,
  ExamTemplateSummary,
} from "@/lib/types";

/**
 * Accueil /examens-blancs : épurée à l'extrême — un topbar, un panneau de
 * stats globales sur les examens passés, puis 2 grosses tuiles (Civique / TCF)
 * qui pointent chacune vers leur sous-route. Toute la logique de liste est
 * dans ExamsModuleView, monté sur /examens-blancs/civique et /examens-blancs/tcf.
 */
export default function ExamensBlancsHomePage() {
  const { user, status } = useAuth();

  const [exams, setExams] = useState<ExamTemplateSummary[]>([]);
  const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    setLoading(true);
    Promise.all([
      examApi.list().catch((e: unknown) => {
        if (e instanceof ApiException) throw e;
        throw new Error("Impossible de charger les examens.");
      }),
      attemptApi
        .listMine({ type: "MOCK_EXAM", limit: 50 })
        .catch((): AttemptSummaryResponse[] => []),
    ])
      .then(([list, atts]) => {
        if (cancelled) return;
        setExams(list);
        setAttempts(atts);
        setError(null);
        setLoading(false);
      })
      .catch((e: Error) => {
        if (cancelled) return;
        setError(e.message);
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status]);

  const counts = useMemo(() => {
    return {
      civique: exams.filter((e) => e.module === "CIVIQUE").length,
      tcf: exams.filter((e) => e.module === "TCF").length,
    };
  }, [exams]);

  const examStats = useMemo(() => {
    const finished = attempts.filter(
      (a) =>
        a.type === "MOCK_EXAM" &&
        a.finishedAt &&
        a.score !== null &&
        a.score !== undefined,
    );
    if (finished.length === 0) {
      return {
        total: 0,
        passed: 0,
        passRate: 0,
        breakdown: "Pas encore d'examen",
        bestLabel: null as string | null,
        bestDetail: null as string | null,
      };
    }
    const civiqueCount = finished.filter((a) => a.module === "CIVIQUE").length;
    const tcfCount = finished.filter((a) => a.module === "TCF").length;
    const passed = finished.filter((a) => {
      if (a.module === "CIVIQUE" && a.passThreshold != null) {
        return (a.score ?? 0) >= a.passThreshold;
      }
      return (a.score ?? 0) / a.totalQuestions >= 0.6;
    }).length;
    let bestPct = -1;
    let best: AttemptSummaryResponse | null = null;
    for (const a of finished) {
      const pct = (a.score ?? 0) / a.totalQuestions;
      if (pct > bestPct) {
        bestPct = pct;
        best = a;
      }
    }
    const breakdown =
      [
        civiqueCount ? `${civiqueCount} civique${civiqueCount > 1 ? "s" : ""}` : null,
        tcfCount ? `${tcfCount} TCF` : null,
      ]
        .filter(Boolean)
        .join(" · ") || "—";
    const bestLabel = best ? `${best.score}/${best.totalQuestions}` : null;
    const bestDetail = best
      ? `${best.module === "TCF" ? "TCF" : "Civique"} · ${formatShortDate(best.startedAt)}`
      : null;
    return {
      total: finished.length,
      passed,
      passRate: Math.round((passed / finished.length) * 100),
      breakdown,
      bestLabel,
      bestDetail,
    };
  }, [attempts]);

  if (status === "loading") return <HomeSkeleton />;
  if (!user) {
    return (
      <main className="ebh-gate">
        <p>Connectez-vous pour passer un examen blanc.</p>
        <Link href="/connexion?next=/examens-blancs" className="ebh-gate-cta">
          Se connecter →
        </Link>
        <style>{gateStyles}</style>
      </main>
    );
  }

  return (
    <main className="ebh">
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            ACCUEIL <span className="sep">/</span> EXAMENS BLANCS
          </div>
          <h1>
            Préparez-vous en <em>conditions réelles</em>.
          </h1>
        </div>
        <div className="topbar-actions">
          <Link href="/historique" className="btn-outline">
            Mes résultats →
          </Link>
        </div>
      </header>

      {error && <div className="form-error ebh-error">{error}</div>}

      {/* ============ STATS ============ */}
      <section className="stats-grid">
        <StatCard
          tone="blue"
          icon={<ShieldIcon />}
          label="EXAMENS PASSÉS"
          value={String(examStats.total)}
          trend={examStats.breakdown}
        />
        <StatCard
          tone="green"
          icon={<CheckIcon />}
          label="TAUX DE RÉUSSITE"
          value={examStats.total > 0 ? `${examStats.passRate}%` : "—"}
          trend={
            examStats.total > 0
              ? `${examStats.passed} réussites sur ${examStats.total}`
              : "Pas encore d'examen"
          }
        />
        <StatCard
          tone="amber"
          icon={<TrophyIcon />}
          label="MEILLEUR SCORE"
          value={examStats.bestLabel ?? "—"}
          trend={examStats.bestDetail ?? "À débloquer"}
        />
      </section>

      {/* ============ MODULE TILES ============ */}
      <section className="tiles">
        <ModuleTile
          tone="blue"
          href="/examens-blancs/civique"
          tag="EXAMEN CIVIQUE"
          title="Civique"
          desc="Connaissance des valeurs et principes de la République. Pour la CSP, la carte de résident et la naturalisation."
          count={counts.civique}
          loading={loading}
        />
        <ModuleTile
          tone="red"
          href="/examens-blancs/tcf"
          tag="TCF IRN"
          title="TCF"
          desc="Compréhension orale, compréhension écrite, structure de la langue. Diagnostic CECRL A2 / B1 / B2."
          count={counts.tcf}
          loading={loading}
        />
      </section>

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// MODULE TILE
// ============================================================================
function ModuleTile({
  tone,
  href,
  tag,
  title,
  desc,
  count,
  loading,
}: {
  tone: "blue" | "red";
  href: string;
  tag: string;
  title: string;
  desc: string;
  count: number;
  loading: boolean;
}) {
  return (
    <Link href={href} className={`tile tile-${tone}`}>
      <div className="tile-pattern" aria-hidden />
      <div className="tile-body">
        <span className={`tile-tag tile-tag-${tone}`}>{tag}</span>
        <h2 className="tile-title">{title}</h2>
        <p className="tile-desc">{desc}</p>
        <div className="tile-footer">
          <span className="tile-count">
            {loading ? (
              <span className="tile-count-skel">···</span>
            ) : (
              <>
                <strong>{count}</strong> {count > 1 ? "examens" : "examen"}{" "}
                disponible{count > 1 ? "s" : ""}
              </>
            )}
          </span>
          <span className={`tile-cta tile-cta-${tone}`}>
            Voir les examens
            <span className="tile-arrow">→</span>
          </span>
        </div>
      </div>
    </Link>
  );
}

// ============================================================================
// STAT CARD
// ============================================================================
function StatCard({
  tone,
  icon,
  label,
  value,
  trend,
}: {
  tone: "blue" | "red" | "green" | "amber";
  icon: React.ReactNode;
  label: string;
  value: string;
  trend?: string;
}) {
  return (
    <div className="stat-card">
      <div className={`stat-icon stat-icon-${tone}`}>{icon}</div>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
      {trend && <div className="stat-trend">{trend}</div>}
    </div>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
const SHORT_MONTHS = ["janv", "févr", "mars", "avr", "mai", "juin", "juil", "août", "sept", "oct", "nov", "déc"];
function formatShortDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getDate()} ${SHORT_MONTHS[d.getMonth()]}`;
}

function HomeSkeleton() {
  return (
    <div className="ebh-loading">
      <style>{`.ebh-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
    </div>
  );
}

const gateStyles = `
  .ebh-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .ebh-gate-cta {
    color: var(--color-blue); font-weight: 700; text-decoration: none;
  }
`;

// ============================================================================
// ICONS
// ============================================================================
const I = (props: React.SVGProps<SVGSVGElement>) => (
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    {...props}
  />
);
const ShieldIcon = () => (
  <I>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </I>
);
const CheckIcon = () => (
  <I>
    <polyline points="20 6 9 17 4 12" />
  </I>
);
const TrophyIcon = () => (
  <I>
    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
  </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .ebh { padding: 24px 36px 64px; max-width: 1320px; }
  @media (max-width: 760px) { .ebh { padding: 20px 16px 56px; } }

  /* ========== TOPBAR ========== */
  .topbar {
    display: flex; justify-content: space-between; align-items: flex-start;
    gap: 16px; flex-wrap: wrap;
    margin-bottom: 26px;
  }
  .breadcrumb {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 6px;
  }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.2vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0;
    line-height: 1.15;
  }
  .topbar h1 em {
    color: var(--color-blue);
    font-style: italic;
    font-weight: 500;
  }
  .topbar-actions { display: flex; gap: 10px; align-items: center; }
  .btn-outline {
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid var(--color-line);
    background: #fff;
    color: var(--color-ink);
    transition: all 0.15s;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }

  .ebh-error { margin-bottom: 18px; }

  /* ========== STATS ========== */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 26px;
  }
  .stat-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
  }
  .stat-icon {
    width: 36px; height: 36px;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    margin-bottom: 14px;
  }
  .stat-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .stat-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .stat-icon-green { background: rgba(22, 143, 91, 0.1); color: var(--color-green); }
  .stat-icon-amber { background: rgba(232, 163, 23, 0.12); color: var(--color-amber); }
  .stat-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted);
    margin-bottom: 6px;
    font-weight: 600;
  }
  .stat-value {
    font-family: var(--font-display);
    font-size: 30px;
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.1;
    color: var(--color-ink);
  }
  .stat-trend { font-size: 12px; margin-top: 6px; color: var(--color-muted); }
  @media (max-width: 760px) {
    .stats-grid { grid-template-columns: 1fr; }
  }

  /* ========== TILES — 2 grosses tuiles cliquables ========== */
  .tiles {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 22px;
  }
  @media (max-width: 980px) {
    .tiles { grid-template-columns: 1fr; }
  }
  .tile {
    position: relative;
    display: flex; flex-direction: column;
    min-height: 320px;
    border-radius: 24px;
    padding: 36px;
    color: #fff;
    text-decoration: none;
    overflow: hidden;
    transition: transform 0.25s, box-shadow 0.25s;
    cursor: pointer;
  }
  .tile:hover {
    transform: translateY(-4px);
    box-shadow: 0 30px 60px -20px rgba(15, 24, 57, 0.35);
  }
  .tile-blue {
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
  }
  .tile-red {
    background: linear-gradient(135deg, var(--color-red) 0%, var(--color-red-dark) 100%);
  }
  .tile-pattern {
    position: absolute;
    inset: 0;
    background:
      radial-gradient(circle at 100% 0%, rgba(255, 255, 255, 0.18) 0px, transparent 40%),
      radial-gradient(circle at 0% 100%, rgba(255, 255, 255, 0.08) 0px, transparent 50%);
    pointer-events: none;
  }
  .tile-blue .tile-pattern {
    background:
      radial-gradient(circle at 100% 0%, var(--color-red) 0px, transparent 35%),
      radial-gradient(circle at 0% 100%, rgba(255, 255, 255, 0.08) 0px, transparent 50%);
    opacity: 0.55;
  }
  .tile-red .tile-pattern {
    background:
      radial-gradient(circle at 100% 0%, var(--color-blue) 0px, transparent 35%),
      radial-gradient(circle at 0% 100%, rgba(255, 255, 255, 0.08) 0px, transparent 50%);
    opacity: 0.5;
  }
  .tile-body {
    position: relative;
    z-index: 1;
    flex: 1;
    display: flex;
    flex-direction: column;
  }
  .tile-tag {
    display: inline-flex; align-self: flex-start;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.18em;
    padding: 6px 12px;
    border-radius: 100px;
    background: rgba(255, 255, 255, 0.15);
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
    color: #fff;
    font-weight: 600;
    margin-bottom: 24px;
  }
  .tile-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(48px, 6vw, 68px);
    letter-spacing: -0.03em;
    line-height: 1;
    margin: 0 0 18px;
    color: #fff;
  }
  .tile-desc {
    color: rgba(255, 255, 255, 0.82);
    font-size: 15px;
    line-height: 1.55;
    margin: 0 0 28px;
    max-width: 380px;
    flex: 1;
  }
  .tile-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding-top: 18px;
    border-top: 1px solid rgba(255, 255, 255, 0.18);
    gap: 12px;
  }
  .tile-count {
    font-family: var(--font-mono);
    font-size: 12px;
    letter-spacing: 0.06em;
    color: rgba(255, 255, 255, 0.8);
  }
  .tile-count strong {
    color: #fff;
    font-weight: 700;
    font-size: 16px;
  }
  .tile-count-skel {
    color: rgba(255, 255, 255, 0.5);
    letter-spacing: 0.2em;
  }
  .tile-cta {
    display: inline-flex; align-items: center; gap: 8px;
    background: #fff;
    padding: 10px 18px;
    border-radius: 12px;
    font-size: 13.5px;
    font-weight: 700;
    transition: transform 0.15s;
  }
  .tile-cta-blue { color: var(--color-blue); }
  .tile-cta-red { color: var(--color-red); }
  .tile:hover .tile-cta { transform: translateX(2px); }
  .tile-arrow {
    transition: transform 0.15s;
  }
  .tile:hover .tile-arrow { transform: translateX(3px); }
`;
