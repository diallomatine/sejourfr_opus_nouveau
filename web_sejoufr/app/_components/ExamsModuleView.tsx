"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ApiException, attemptApi, examApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type AttemptSummaryResponse,
  type ExamTemplateSummary,
  type Module as ModuleEnum,
  type TargetLevel,
  type TargetProcedure,
} from "@/lib/types";

/**
 * Affiche tous les examens blancs d'un module (Civique OU TCF) :
 * – breadcrumb retour vers /examens-blancs
 * – stats spécifiques au module
 * – card featured (l'exam principal selon le parcours user) + liste des autres
 * – paywall si non-premium pour le module.
 */
export function ExamsModuleView({ module }: { module: ModuleEnum }) {
  const { user, status } = useAuth();
  const router = useRouter();
  const isCivique = module === "CIVIQUE";
  const tone: "blue" | "red" = isCivique ? "blue" : "red";

  const [exams, setExams] = useState<ExamTemplateSummary[]>([]);
  const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Guests : on les renvoie sur le hub /examens-blancs (qui expose les
  // 2 modules en démo). Les sous-routes /civique et /tcf sont conçues pour
  // l'espace connecté (stats par module).
  useEffect(() => {
    if (status === "guest") {
      router.replace("/examens-blancs");
    }
  }, [status, router]);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    setLoading(true);
    Promise.all([
      examApi.list(module).catch((e: unknown) => {
        if (e instanceof ApiException) throw e;
        throw new Error("Impossible de charger les examens.");
      }),
      attemptApi
        .listMine({ type: "MOCK_EXAM", module, limit: 50 })
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
  }, [module, status]);

  const isPremium = user !== null && canAccessModule(user, module);

  // ========== Stats du module ==========
  const moduleStats = useMemo(() => {
    const finished = attempts.filter(
      (a) => a.finishedAt && a.score !== null && a.score !== undefined,
    );
    if (finished.length === 0) {
      return { total: 0, passed: 0, passRate: 0, bestLabel: null as string | null };
    }
    const passed = finished.filter((a) => {
      if (isCivique && a.passThreshold != null) {
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
    return {
      total: finished.length,
      passed,
      passRate: Math.round((passed / finished.length) * 100),
      bestLabel: best ? `${best.score}/${best.totalQuestions}` : null,
    };
  }, [attempts, isCivique]);

  // ========== Featured + autres ==========
  const partitioned = useMemo(() => {
    const sorted = [...exams].sort((a, b) => a.position - b.position);
    if (sorted.length === 0) {
      return { featured: null as ExamTemplateSummary | null, others: [] };
    }
    const userProc = user?.targetProcedure ?? null;
    const userLevel = user?.targetLevel ?? null;
    const featured = isCivique
      ? (sorted.find((e) => e.targetProcedure === userProc) ??
        sorted.find((e) => e.targetProcedure === "NAT") ??
        sorted[0])
      : (sorted.find((e) => e.targetLevel === userLevel) ??
        sorted.find((e) => e.targetLevel === "B2") ??
        sorted[0]);
    const others = sorted.filter((e) => e.id !== featured.id);
    return { featured, others };
  }, [exams, user, isCivique]);

  // ========== Dernier attempt fini par template ==========
  // On ne garde qu'un attempt par template : le plus récent (basé sur finishedAt).
  // Sert à afficher le badge "Fait" + score, et le lien vers le résultat.
  const lastByTemplateId = useMemo(() => {
    const map = new Map<string, AttemptSummaryResponse>();
    for (const a of attempts) {
      if (!a.examTemplateId || !a.finishedAt) continue;
      const current = map.get(a.examTemplateId);
      if (!current || new Date(a.finishedAt) > new Date(current.finishedAt ?? 0)) {
        map.set(a.examTemplateId, a);
      }
    }
    return map;
  }, [attempts]);

  if (status === "loading" || status === "guest" || !user) return <ModuleSkeleton />;

  const isLocked = (e: ExamTemplateSummary) => {
    if (e.free) return false;
    return !isPremium;
  };

  return (
    <main className={`mod mod-${tone}`}>
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            <Link href="/examens-blancs" className="breadcrumb-link">
              EXAMENS BLANCS
            </Link>
            <span className="sep">/</span>
            {isCivique ? "CIVIQUE" : "TCF IRN"}
          </div>
          <h1>
            {isCivique ? (
              <>
                Examen <em>civique</em>.
              </>
            ) : (
              <>
                <em>TCF</em> IRN.
              </>
            )}
          </h1>
        </div>
        <div className="topbar-actions">
          <Link href="/examens-blancs" className="btn-outline">
            ← Retour
          </Link>
          <Link href="/historique" className="btn-outline">
            Mes résultats
          </Link>
        </div>
      </header>

      {error && <div className="form-error mod-error">{error}</div>}

      {/* ============ STATS DU MODULE ============ */}
      <section className="stats-grid">
        <StatCard
          tone={tone}
          icon={<ShieldIcon />}
          label="EXAMENS PASSÉS"
          value={String(moduleStats.total)}
          trend={moduleStats.total > 0 ? `${moduleStats.passed} ${isCivique ? "réussite(s)" : "≥ 60%"}` : "Pas encore"}
        />
        <StatCard
          tone="green"
          icon={<CheckIcon />}
          label="TAUX DE RÉUSSITE"
          value={moduleStats.total > 0 ? `${moduleStats.passRate}%` : "—"}
          trend={moduleStats.total > 0 ? `${moduleStats.passed} sur ${moduleStats.total}` : "À débloquer"}
        />
        <StatCard
          tone="amber"
          icon={<TrophyIcon />}
          label="MEILLEUR SCORE"
          value={moduleStats.bestLabel ?? "—"}
          trend={moduleStats.bestLabel ? "Score record" : "À jouer"}
        />
      </section>

      {/* ============ FEATURED ============ */}
      {loading && exams.length === 0 ? (
        <FeaturedSkeleton />
      ) : partitioned.featured ? (
        <FeaturedCard
          exam={partitioned.featured}
          tone={tone}
          locked={isLocked(partitioned.featured)}
          lastAttempt={lastByTemplateId.get(partitioned.featured.id) ?? null}
          onLockedClick={() => setPaywallOpen(true)}
        />
      ) : (
        !loading && (
          <div className="mod-empty">Aucun examen blanc publié pour ce module.</div>
        )
      )}

      {/* ============ AUTRES EXAMENS ============ */}
      {partitioned.others.length > 0 && (
        <section className="others-wrap">
          <h3 className="others-title">
            Autres examens disponibles{" "}
            <span className="others-count">{partitioned.others.length}</span>
          </h3>
          <div className="others-grid">
            {partitioned.others.map((e, i) => (
              <ExamRow
                key={e.id}
                exam={e}
                index={i + 2}
                tone={tone}
                locked={isLocked(e)}
                lastAttempt={lastByTemplateId.get(e.id) ?? null}
                onLockedClick={() => setPaywallOpen(true)}
              />
            ))}
          </div>
        </section>
      )}

      <PaywallSheet
        open={paywallOpen}
        onClose={() => setPaywallOpen(false)}
        title={
          isCivique
            ? "Débloquez tous les examens civiques"
            : "Débloquez tous les examens TCF"
        }
        message={
          isCivique
            ? "Vous avez 1 examen blanc civique offert. L'abonnement débloque les examens CSP, CR et naturalisation, plus tout l'entraînement illimité."
            : "Vous avez 1 examen blanc TCF offert. L'abonnement Intégral débloque les diagnostics A2/B1/B2, le civique illimité et la révision des erreurs."
        }
        plan={isCivique ? "CIVIQUE_3MOIS" : "INTEGRAL_3MOIS"}
      />

      <style>{styles}</style>
    </main>
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
// FEATURED CARD
// ============================================================================
function FeaturedCard({
  exam,
  tone,
  locked,
  lastAttempt,
  onLockedClick,
}: {
  exam: ExamTemplateSummary;
  tone: "blue" | "red";
  locked: boolean;
  lastAttempt: AttemptSummaryResponse | null;
  onLockedClick: () => void;
}) {
  const isCivique = exam.module === "CIVIQUE";
  const minutes = Math.round(exam.durationSeconds / 60);
  const targetLabel = isCivique
    ? procedureFullLabel(exam.targetProcedure)
    : levelFullLabel(exam.targetLevel);
  const isDone = lastAttempt !== null;

  const Inner = (
    <>
      <div className="featured-head">
        <span className={`featured-tag featured-tag-${tone}`}>
          {isDone ? "DÉJÀ FAIT" : "RECOMMANDÉ POUR VOUS"}
        </span>
        {exam.free && <span className="featured-free">GRATUIT</span>}
        {isDone && (
          <span className="featured-done">
            <CheckBadgeIcon /> {lastAttempt.score}/{lastAttempt.totalQuestions}
            {lastAttempt.finishedAt && (
              <span className="featured-done-date">
                · {formatShortDate(lastAttempt.finishedAt)}
              </span>
            )}
          </span>
        )}
      </div>
      <h3 className="featured-title">{targetLabel}</h3>
      <p className="featured-sub">
        {exam.subtitle ??
          (isCivique
            ? "Examen blanc en conditions réelles, répartition officielle par thématique."
            : "Compréhension orale et écrite, score sur 699 avec niveau attribué.")}
      </p>
      <div className="featured-meta">
        <div className="meta-item">
          <div className="meta-label">QUESTIONS</div>
          <div className="meta-value">{exam.totalQuestions}</div>
        </div>
        <div className="meta-item">
          <div className="meta-label">DURÉE</div>
          <div className="meta-value">{minutes} min</div>
        </div>
        <div className="meta-item">
          <div className="meta-label">{isCivique ? "SEUIL" : "VISÉ"}</div>
          <div className={`meta-value ${tone === "blue" ? "meta-value-blue" : "meta-value-red"}`}>
            {isCivique
              ? `${exam.passingScore}/${exam.totalQuestions}`
              : (exam.targetLevel ?? "DIAGNOSTIC")}
          </div>
        </div>
      </div>
      <span className={`featured-cta featured-cta-${tone} ${locked ? "is-locked" : ""}`}>
        {locked ? (
          <>
            <LockIcon /> Débloquer
          </>
        ) : isDone ? (
          <>Voir détails ou refaire →</>
        ) : (
          <>Démarrer l&apos;examen blanc →</>
        )}
      </span>
    </>
  );

  if (locked) {
    return (
      <button
        type="button"
        className={`featured-card featured-${tone}`}
        onClick={onLockedClick}
      >
        {Inner}
      </button>
    );
  }
  return (
    <Link
      href={`/examens-blancs/${exam.slug}`}
      className={`featured-card featured-${tone}`}
    >
      {Inner}
    </Link>
  );
}

// ============================================================================
// EXAM ROW
// ============================================================================
function ExamRow({
  exam,
  index,
  tone,
  locked,
  lastAttempt,
  onLockedClick,
}: {
  exam: ExamTemplateSummary;
  index: number;
  tone: "blue" | "red";
  locked: boolean;
  lastAttempt: AttemptSummaryResponse | null;
  onLockedClick: () => void;
}) {
  const isTcf = exam.module === "TCF";
  const minutes = Math.round(exam.durationSeconds / 60);
  const targetLabel = isTcf
    ? (exam.targetLevel ?? "DIAGNOSTIC")
    : (exam.targetProcedure ?? "TOUS");
  const seuilLabel = isTcf
    ? null
    : `${exam.passingScore}/${exam.totalQuestions}`;
  const isDone = lastAttempt !== null;

  const Body = (
    <>
      <span className={`row-rank row-rank-${tone}`}>
        {String(index).padStart(2, "0")}
      </span>
      <div className="row-body">
        <div className="row-head">
          <span className={`row-target row-target-${tone}`}>{targetLabel}</span>
          {exam.free && <span className="row-free">GRATUIT</span>}
          {isDone && (
            <span className="row-done">
              <CheckBadgeIcon /> {lastAttempt.score}/{lastAttempt.totalQuestions}
            </span>
          )}
        </div>
        <h4 className="row-title">{exam.name}</h4>
        {exam.subtitle && <p className="row-sub">{exam.subtitle}</p>}
        <div className="row-stats">
          <span>
            <strong>{exam.totalQuestions}</strong> QCM
          </span>
          <span className="dot">·</span>
          <span>
            <strong>{minutes}</strong> min
          </span>
          {seuilLabel && (
            <>
              <span className="dot">·</span>
              <span>
                seuil <strong>{seuilLabel}</strong>
              </span>
            </>
          )}
        </div>
      </div>
      <span className={`row-cta row-cta-${tone} ${locked ? "is-locked" : ""}`}>
        {locked ? (
          <>
            <LockIcon /> Premium
          </>
        ) : isDone ? (
          <>Voir / refaire →</>
        ) : (
          <>Démarrer →</>
        )}
      </span>
    </>
  );

  if (locked) {
    return (
      <button type="button" className="exam-row exam-row-locked" onClick={onLockedClick}>
        {Body}
      </button>
    );
  }
  return (
    <Link href={`/examens-blancs/${exam.slug}`} className="exam-row">
      {Body}
    </Link>
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

function procedureFullLabel(p: TargetProcedure | null): string {
  switch (p) {
    case "CSP": return "Mention pluriannuelle";
    case "CR":  return "Mention résident";
    case "NAT": return "Mention naturalisation";
    default:    return "Examen civique";
  }
}
function levelFullLabel(l: TargetLevel | null): string {
  switch (l) {
    case "A2": return "Niveau A2";
    case "B1": return "Niveau B1";
    case "B2": return "Niveau B2";
    default:   return "Diagnostic TCF";
  }
}

// ============================================================================
// SKELETONS / EMPTY
// ============================================================================
function ModuleSkeleton() {
  return (
    <div className="mod-loading">
      <style>{`.mod-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
    </div>
  );
}

function FeaturedSkeleton() {
  return (
    <div className="featured-skel">
      <style>{`
        .featured-skel {
          height: 260px;
          background: var(--color-paper-2);
          border: 1px solid var(--color-line);
          border-radius: 22px;
          margin-bottom: 26px;
          animation: feat-pulse 1.4s ease-in-out infinite;
        }
        @keyframes feat-pulse {
          0%, 100% { opacity: 0.55; }
          50% { opacity: 1; }
        }
      `}</style>
    </div>
  );
}

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
const LockIcon = () => (
  <I width="14" height="14">
    <rect x="3" y="11" width="18" height="11" rx="2" />
    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
  </I>
);
const CheckBadgeIcon = () => (
  <I width="13" height="13">
    <path d="M9 11l3 3L22 4" />
    <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
  </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .mod { padding: 24px 36px 64px; max-width: 1320px; }
  @media (max-width: 760px) { .mod { padding: 20px 16px 56px; } }

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
  .breadcrumb-link {
    color: var(--color-muted);
    text-decoration: none;
    transition: color 0.15s;
  }
  .breadcrumb-link:hover { color: var(--color-blue); }
  .breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .topbar h1 {
    font-family: var(--font-display);
    font-size: clamp(24px, 3.2vw, 32px);
    font-weight: 600;
    letter-spacing: -0.02em;
    margin: 0;
    line-height: 1.15;
  }
  .topbar h1 em { font-style: italic; font-weight: 500; }
  .mod-blue .topbar h1 em { color: var(--color-blue); }
  .mod-red .topbar h1 em { color: var(--color-red); }
  .topbar-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
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

  .mod-error { margin-bottom: 18px; }

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

  /* ========== FEATURED ========== */
  .featured-card {
    display: flex;
    flex-direction: column;
    border-radius: 22px;
    padding: 32px;
    border: 1px solid var(--color-line);
    text-align: left;
    font-family: inherit;
    text-decoration: none;
    color: inherit;
    cursor: pointer;
    transition: all 0.2s;
    margin-bottom: 26px;
    width: 100%;
  }
  .featured-card:hover {
    transform: translateY(-3px);
    border-color: var(--color-ink);
    box-shadow: 0 20px 40px -20px rgba(15, 24, 57, 0.18);
  }
  .featured-blue {
    background: linear-gradient(135deg, var(--color-blue-soft) 0%, #fff 100%);
    border-color: var(--color-blue-light);
  }
  .featured-red {
    background: linear-gradient(135deg, var(--color-red-light) 0%, #fff 100%);
    border-color: rgba(225, 55, 47, 0.2);
  }
  .featured-head {
    display: flex; align-items: center; gap: 8px;
    margin-bottom: 16px;
    flex-wrap: wrap;
  }
  .featured-tag {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    color: #fff;
    padding: 5px 10px;
    border-radius: 6px;
    font-weight: 600;
  }
  .featured-tag-blue { background: var(--color-blue); }
  .featured-tag-red { background: var(--color-red); }
  .featured-free {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    background: rgba(22, 143, 91, 0.12);
    color: var(--color-green);
    padding: 4px 8px;
    border-radius: 5px;
    font-weight: 700;
  }
  .featured-done {
    display: inline-flex; align-items: center; gap: 5px;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.06em;
    background: var(--color-green);
    color: #fff;
    padding: 4px 9px;
    border-radius: 100px;
    font-weight: 700;
  }
  .featured-done-date {
    color: rgba(255, 255, 255, 0.78);
    font-weight: 600;
  }
  .featured-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 28px;
    margin: 0 0 10px;
    letter-spacing: -0.015em;
    line-height: 1.15;
  }
  .featured-sub {
    color: var(--color-muted);
    margin: 0 0 22px;
    font-size: 14.5px;
    line-height: 1.55;
    max-width: 600px;
  }
  .featured-meta {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
    margin-bottom: 24px;
    max-width: 600px;
  }
  .meta-item {
    padding: 12px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 10px;
  }
  .meta-label {
    font-family: var(--font-mono);
    font-size: 9px;
    color: var(--color-muted);
    letter-spacing: 0.12em;
  }
  .meta-value { font-weight: 700; font-size: 15px; margin-top: 3px; color: var(--color-ink); }
  .meta-value-blue { color: var(--color-blue); }
  .meta-value-red { color: var(--color-red); }
  .featured-cta {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 13px 20px;
    border-radius: 12px;
    font-size: 14px;
    font-weight: 700;
    color: #fff;
    align-self: flex-start;
    transition: filter 0.15s;
  }
  .featured-cta-blue { background: var(--color-blue); }
  .featured-cta-red { background: var(--color-red); }
  .featured-card:hover .featured-cta { filter: brightness(1.1); }
  .featured-cta.is-locked {
    background: var(--color-paper-2);
    color: var(--color-ink-2);
    border: 1px solid var(--color-line);
  }

  /* ========== OTHERS ========== */
  .others-wrap { margin-top: 6px; }
  .others-title {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    margin: 0 0 14px;
    letter-spacing: -0.01em;
    display: flex; align-items: center; gap: 10px;
  }
  .others-count {
    font-family: var(--font-mono);
    font-size: 11px;
    background: var(--color-line-2);
    color: var(--color-muted);
    padding: 3px 9px;
    border-radius: 100px;
    font-weight: 700;
    letter-spacing: 0.08em;
  }
  .others-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }
  @media (max-width: 980px) {
    .others-grid { grid-template-columns: 1fr; }
  }

  .exam-row {
    display: grid;
    grid-template-columns: 48px 1fr auto;
    align-items: center;
    gap: 16px;
    padding: 16px 18px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 14px;
    text-decoration: none;
    color: inherit;
    font-family: inherit;
    text-align: left;
    cursor: pointer;
    transition: all 0.18s;
    width: 100%;
  }
  .exam-row:hover {
    transform: translateY(-2px);
    box-shadow: 0 14px 28px -16px rgba(15, 24, 57, 0.18);
  }
  .mod-blue .exam-row:hover { border-color: var(--color-blue); }
  .mod-red .exam-row:hover { border-color: var(--color-red); }
  .exam-row-locked {
    background:
      repeating-linear-gradient(45deg, var(--color-paper) 0 6px, #fff 6px 14px);
    cursor: pointer;
  }
  .exam-row-locked:hover {
    transform: none; box-shadow: none;
    border-color: var(--color-muted-2) !important;
  }
  .row-rank {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 600;
    letter-spacing: -0.03em;
    line-height: 1;
    text-align: center;
  }
  .row-rank-blue { color: var(--color-blue); }
  .row-rank-red { color: var(--color-red); }
  .exam-row-locked .row-rank { color: var(--color-muted-2); }
  .row-body { min-width: 0; }
  .row-head {
    display: flex; align-items: center; gap: 8px;
    margin-bottom: 4px;
    flex-wrap: wrap;
  }
  .row-target {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.14em;
    padding: 3px 8px;
    border-radius: 4px;
    font-weight: 700;
  }
  .row-target-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .row-target-red { background: var(--color-red-light); color: var(--color-red); }
  .row-free {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.12em;
    background: rgba(22, 143, 91, 0.12);
    color: var(--color-green);
    padding: 3px 7px;
    border-radius: 4px;
    font-weight: 700;
  }
  .row-done {
    display: inline-flex; align-items: center; gap: 4px;
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.06em;
    background: var(--color-green);
    color: #fff;
    padding: 3px 7px;
    border-radius: 100px;
    font-weight: 700;
  }
  .row-title {
    font-family: var(--font-sans);
    font-weight: 700;
    font-size: 15px;
    margin: 0;
    color: var(--color-ink);
    line-height: 1.25;
  }
  .row-sub {
    color: var(--color-muted);
    font-size: 12.5px;
    margin: 3px 0 0;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .row-stats {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-muted);
    letter-spacing: 0.04em;
    margin-top: 8px;
    display: flex; flex-wrap: wrap; align-items: center; gap: 4px;
  }
  .row-stats strong { color: var(--color-ink); font-weight: 700; }
  .row-stats .dot { color: var(--color-muted-2); }
  .row-cta {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: 13px;
    font-weight: 700;
    flex-shrink: 0;
  }
  .row-cta-blue { color: var(--color-blue); }
  .row-cta-red { color: var(--color-red); }
  .row-cta.is-locked { color: var(--color-muted); }

  /* ========== EMPTY ========== */
  .mod-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 14px;
    padding: 48px 16px;
    text-align: center;
    color: var(--color-muted);
    font-size: 14px;
    margin-bottom: 26px;
  }
`;
