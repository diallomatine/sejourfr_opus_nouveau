"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { attemptApi, statsApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type {
  AttemptSummaryResponse,
  Module as ModuleEnum,
  TargetProcedure,
  UserStatsResponse,
} from "@/lib/types";

type StatsByModule = Partial<Record<ModuleEnum, UserStatsResponse | null>>;
const EXAM_DATE_KEY = "sejourfr.examDate";

export default function DashboardPage() {
  const { user, status } = useAuth();

  const [stats, setStats] = useState<StatsByModule>({});
  const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [wrongCount, setWrongCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [examDate, setExamDate] = useState<string | null>(null);
  const [showExamPicker, setShowExamPicker] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const v = window.localStorage.getItem(EXAM_DATE_KEY);
    if (v) setExamDate(v);
  }, []);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    (async () => {
      const result: StatsByModule = {};
      const promises: Array<Promise<unknown>> = [];
      if (user.hasCivique !== false) {
        promises.push(
          statsApi
            .get("CIVIQUE")
            .then((s) => {
              result.CIVIQUE = s;
            })
            .catch(() => {
              result.CIVIQUE = null;
            }),
        );
      }
      if (user.hasTcf !== false) {
        promises.push(
          statsApi
            .get("TCF")
            .then((s) => {
              result.TCF = s;
            })
            .catch(() => {
              result.TCF = null;
            }),
        );
      }
      const attemptsP = attemptApi
        .listMine({ limit: 30 })
        .catch((): AttemptSummaryResponse[] => []);
      const wrongP = userContentApi
        .wrong()
        .then((q) => q.length)
        .catch(() => 0);

      const [, atts, w] = await Promise.all([
        Promise.all(promises),
        attemptsP,
        wrongP,
      ]);
      if (cancelled) return;
      setStats(result);
      setAttempts(atts);
      setWrongCount(w);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  const inProgressAttempt = useMemo(
    () => attempts.find((a) => !a.finishedAt) ?? null,
    [attempts],
  );

  // ============ KPIs ============
  const totalQuestionsAnswered = useMemo(() => {
    const c = stats.CIVIQUE?.questionsAnswered ?? 0;
    const t = stats.TCF?.questionsAnswered ?? 0;
    return c + t;
  }, [stats]);

  const totalCorrect = useMemo(() => {
    const c = stats.CIVIQUE?.questionsCorrect ?? 0;
    const t = stats.TCF?.questionsCorrect ?? 0;
    return c + t;
  }, [stats]);

  const overallSuccessPct = useMemo(() => {
    if (totalQuestionsAnswered === 0) return 0;
    return Math.round((totalCorrect / totalQuestionsAnswered) * 100);
  }, [totalCorrect, totalQuestionsAnswered]);

  const streak = useMemo(() => computeStreak(attempts), [attempts]);
  const cumulativeMinutes = useMemo(
    () => computeCumulativeMinutes(attempts),
    [attempts],
  );

  // ============ Banner copy ============
  const civiqueMockExams = useMemo(
    () =>
      attempts.filter(
        (a) =>
          a.type === "MOCK_EXAM" &&
          a.module === "CIVIQUE" &&
          a.finishedAt &&
          a.score !== null &&
          a.score !== undefined,
      ),
    [attempts],
  );

  const lastFiveAvg = useMemo(() => {
    const slice = civiqueMockExams.slice(0, 5);
    if (slice.length === 0) return null;
    const total = slice.reduce((sum, a) => sum + (a.score ?? 0), 0);
    return total / slice.length;
  }, [civiqueMockExams]);

  const bannerCopy = useMemo(
    () =>
      buildBannerCopy({
        user: user
          ? {
              firstName: user.firstName,
              targetProcedure: user.targetProcedure ?? null,
            }
          : null,
        avgScore: lastFiveAvg,
      }),
    [user, lastFiveAvg],
  );

  // ============ Theme mastery (CIVIQUE) ============
  const themeRows = useMemo(() => {
    const civiqueThemes = stats.CIVIQUE?.byTheme ?? [];
    const sorted = [...civiqueThemes].sort(
      (a, b) => b.themeName.localeCompare(a.themeName), // stable for display
    );
    return sorted.slice(0, 5).map((t, i) => {
      const pct = t.answered > 0 ? Math.round((t.correct / t.answered) * 100) : 0;
      const tone: "green" | "blue" | "amber" | "red" =
        pct >= 80 ? "green" : pct >= 65 ? "blue" : pct >= 45 ? "amber" : "red";
      return {
        num: String(i + 1).padStart(2, "0"),
        name: t.themeName,
        pct,
        tone,
      };
    });
  }, [stats.CIVIQUE]);

  // ============ Chart : last 10 mock exams scores ============
  const chartData = useMemo(
    () => buildChartData(attempts),
    [attempts],
  );

  // ============ Loading / unauthenticated ============
  if (status === "loading") return <DashSkeleton />;
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

  return (
    <main className="dash">
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            ACCUEIL <span className="sep">/</span> TABLEAU DE BORD
          </div>
          <h1>
            Bonjour {user.firstName ?? "à vous"}, prêt à <em>progresser</em> ?
          </h1>
        </div>
        <div className="topbar-actions">
          <Link href="/examens-blancs" className="btn-outline">
            <ClockIcon /> Examen blanc
          </Link>
          {inProgressAttempt ? (
            <Link href={`/sessions/${inProgressAttempt.id}`} className="btn-primary">
              Reprendre <ArrowIcon />
            </Link>
          ) : (
            <Link href="/entrainement" className="btn-primary">
              Démarrer <ArrowIcon />
            </Link>
          )}
        </div>
      </header>

      {/* ============ HERO BANNER ============ */}
      <section className="hero-banner">
        <div className="hero-banner-text">
          <div className="hero-eyebrow">
            PROCHAIN OBJECTIF · {procedureLabelShort(user.targetProcedure)}
          </div>
          <h2>{bannerCopy.title}</h2>
          <p>{bannerCopy.body}</p>
          <div className="hero-actions">
            <Link href="/examens-blancs" className="btn-primary">
              Lancer un examen blanc <ArrowIcon />
            </Link>
            <Link href="/statistiques" className="btn-outline-light">
              Voir mes faiblesses
            </Link>
          </div>
        </div>
        <Countdown
          examDate={examDate}
          onEdit={() => setShowExamPicker(true)}
        />
        {showExamPicker && (
          <ExamDatePicker
            current={examDate}
            onClose={() => setShowExamPicker(false)}
            onSave={(d) => {
              setExamDate(d);
              if (d) window.localStorage.setItem(EXAM_DATE_KEY, d);
              else window.localStorage.removeItem(EXAM_DATE_KEY);
              setShowExamPicker(false);
            }}
          />
        )}
      </section>

      {/* ============ STATS GRID ============ */}
      <section className="stats-grid">
        <StatCard
          tone="blue"
          icon={<StreakIcon />}
          label="JOURS D'AFFILÉE"
          value={String(streak)}
          trend={streak > 0 ? { tone: "up", text: `${streak === 1 ? "Aujourd'hui" : "Série en cours"}` } : null}
        />
        <StatCard
          tone="red"
          icon={<CheckBadgeIcon />}
          label="QUESTIONS RÉSOLUES"
          value={String(totalQuestionsAnswered)}
          trend={
            totalQuestionsAnswered > 0
              ? { tone: "up", text: `${totalCorrect} bonnes` }
              : null
          }
        />
        <StatCard
          tone="green"
          icon={<TrendingIcon />}
          label="TAUX DE RÉUSSITE"
          value={`${overallSuccessPct}%`}
          trend={
            totalQuestionsAnswered > 0
              ? { tone: overallSuccessPct >= 70 ? "up" : "neutral", text: "Tous modules" }
              : null
          }
        />
        <StatCard
          tone="amber"
          icon={<ClockIcon />}
          label="TEMPS CUMULÉ"
          value={formatMinutes(cumulativeMinutes)}
          trend={
            attempts.length > 0
              ? { tone: "neutral", text: `${attempts.filter((a) => a.finishedAt).length} sessions` }
              : null
          }
        />
      </section>

      {/* ============ SHORTCUTS ============ */}
      <section className="shortcuts">
        <Shortcut
          tone="civique"
          href="/entrainement?module=CIVIQUE"
          icon={<ShieldIcon />}
          title={`Civique · ${procedureLabelShort(user.targetProcedure)}`}
          desc="Entraînement par thématique"
        />
        <Shortcut
          tone="tcf"
          href={user.hasTcf ? "/entrainement?module=TCF" : "/paiement"}
          icon={<BookIcon />}
          title={`TCF · ${tcfLevelLabel(user.targetProcedure)}`}
          desc={user.hasTcf ? "CO · CE · Structure" : "Premium Intégral requis"}
        />
        <Shortcut
          tone="exam"
          href="/examens-blancs"
          icon={<ClockIcon />}
          title="Examen blanc"
          desc="40 questions · 45 minutes"
        />
        <Shortcut
          tone="review"
          href="/revision"
          icon={<RefreshIcon />}
          title="Mes erreurs"
          desc={
            wrongCount > 0
              ? `${wrongCount} questions à retravailler`
              : "Aucune erreur en attente"
          }
        />
      </section>

      {/* ============ CHART + THEMES ============ */}
      <section className="row-2">
        <ScoreChart data={chartData} />
        <ThemeMastery rows={themeRows} loading={loading} />
      </section>

      {/* ============ RECENT SESSIONS ============ */}
      <RecentSessions attempts={attempts.slice(0, 5)} />

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// SUB-COMPONENTS
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
  trend: { tone: "up" | "down" | "neutral"; text: string } | null;
}) {
  return (
    <div className="stat-card">
      <div className={`stat-icon stat-icon-${tone}`}>{icon}</div>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
      {trend && <div className={`stat-trend stat-trend-${trend.tone}`}>{trend.text}</div>}
    </div>
  );
}

function Shortcut({
  tone,
  href,
  icon,
  title,
  desc,
}: {
  tone: "civique" | "tcf" | "exam" | "review";
  href: string;
  icon: React.ReactNode;
  title: string;
  desc: string;
}) {
  return (
    <Link href={href} className={`shortcut shortcut-${tone}`}>
      <span className="shortcut-arrow">→</span>
      <div className="shortcut-icon">{icon}</div>
      <h4>{title}</h4>
      <p>{desc}</p>
    </Link>
  );
}

function ScoreChart({ data }: { data: ChartDatum[] }) {
  if (data.length < 2) {
    return (
      <div className="card">
        <div className="card-head">
          <div>
            <h3>Évolution de vos scores</h3>
            <p>Vos derniers examens blancs</p>
          </div>
        </div>
        <div className="chart-empty">
          <p>Pas encore assez d&apos;examens blancs pour tracer une courbe.</p>
          <Link href="/examens-blancs" className="chart-empty-cta">
            Lancer un examen blanc →
          </Link>
        </div>
      </div>
    );
  }

  const w = 600;
  const h = 200;
  const padX = 24;
  const padTop = 20;
  const padBottom = 36;
  const innerW = w - padX * 2;
  const innerH = h - padTop - padBottom;

  const civiqueY = (score: number) => {
    // score on /40, threshold at 32. Map to (padTop, padTop + innerH).
    const ratio = 1 - Math.min(1, Math.max(0, score / 40));
    return padTop + ratio * innerH;
  };
  const thresholdY = civiqueY(32);

  const x = (i: number) => padX + (innerW * i) / (data.length - 1);

  const civPath = data
    .map((d, i) => {
      const xi = x(i);
      const yi = d.civique !== null ? civiqueY(d.civique) : null;
      if (yi === null) return null;
      return `${i === 0 ? "M" : "L"}${xi.toFixed(1)},${yi.toFixed(1)}`;
    })
    .filter(Boolean)
    .join(" ");

  const tcfPath = data
    .map((d, i) => {
      const xi = x(i);
      const yi = d.tcfPct !== null ? padTop + (1 - d.tcfPct / 100) * innerH : null;
      if (yi === null) return null;
      return `${i === 0 ? "M" : "L"}${xi.toFixed(1)},${yi.toFixed(1)}`;
    })
    .filter(Boolean)
    .join(" ");

  return (
    <div className="card">
      <div className="card-head">
        <div>
          <h3>Évolution de vos scores</h3>
          <p>{data.length} derniers examens blancs</p>
        </div>
        <Link href="/historique" className="card-head-link">
          Voir tout →
        </Link>
      </div>
      <div className="chart-legend">
        <span className="legend-item">
          <span className="legend-dot blue" /> Civique
        </span>
        <span className="legend-item">
          <span className="legend-dot red" /> TCF
        </span>
        <span className="legend-item">
          <span className="legend-dot line" /> Seuil 32/40
        </span>
      </div>
      <svg className="chart-svg" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
        {[0.25, 0.5, 0.75].map((r) => (
          <line
            key={r}
            x1="0"
            y1={padTop + innerH * r}
            x2={w}
            y2={padTop + innerH * r}
            stroke="#EEF0F8"
            strokeWidth="1"
          />
        ))}
        <line
          x1="0"
          y1={thresholdY}
          x2={w}
          y2={thresholdY}
          stroke="#168F5B"
          strokeWidth="1.5"
          strokeDasharray="4 4"
        />
        <text
          x={w - 6}
          y={thresholdY - 5}
          fontFamily="JetBrains Mono"
          fontSize="10"
          fill="#168F5B"
          fontWeight="700"
          textAnchor="end"
        >
          32 / 40
        </text>
        {tcfPath && (
          <path
            d={tcfPath}
            fill="none"
            stroke="#E1372F"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        )}
        {civPath && (
          <path
            d={civPath}
            fill="none"
            stroke="#1E3A8C"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        )}
        {data.map((d, i) => {
          const xi = x(i);
          const civY = d.civique !== null ? civiqueY(d.civique) : null;
          const tcfY = d.tcfPct !== null ? padTop + (1 - d.tcfPct / 100) * innerH : null;
          return (
            <g key={i}>
              {tcfY !== null && <circle cx={xi} cy={tcfY} r="3" fill="#E1372F" />}
              {civY !== null && (
                <circle
                  cx={xi}
                  cy={civY}
                  r={i === data.length - 1 ? "5" : "3.5"}
                  fill="#1E3A8C"
                  stroke={i === data.length - 1 ? "#fff" : "none"}
                  strokeWidth="2"
                />
              )}
            </g>
          );
        })}
        <g fontFamily="JetBrains Mono" fontSize="9" fill="#9CA2BD">
          {data.map((d, i) => {
            const labelEvery = Math.ceil(data.length / 5);
            if (i % labelEvery !== 0 && i !== data.length - 1) return null;
            return (
              <text key={i} x={x(i)} y={h - 12} textAnchor="middle">
                {d.label}
              </text>
            );
          })}
        </g>
      </svg>
    </div>
  );
}

function ThemeMastery({
  rows,
  loading,
}: {
  rows: { num: string; name: string; pct: number; tone: "green" | "blue" | "amber" | "red" }[];
  loading: boolean;
}) {
  return (
    <div className="card">
      <div className="card-head">
        <div>
          <h3>Maîtrise par thématique</h3>
          <p>Examen civique</p>
        </div>
        <Link href="/statistiques" className="card-head-link">
          Détails →
        </Link>
      </div>
      {loading ? (
        <div className="theme-skel" />
      ) : rows.length === 0 ? (
        <div className="theme-empty">
          <p>Faites quelques questions pour voir apparaître votre maîtrise par thématique.</p>
        </div>
      ) : (
        <div className="theme-list">
          {rows.map((r) => (
            <div className="theme-row" key={r.name}>
              <span className="theme-num">{r.num}</span>
              <div className="theme-row-content">
                <div className="theme-name">{r.name}</div>
                <div className="theme-bar">
                  <div
                    className={`theme-bar-fill theme-bar-${r.tone}`}
                    style={{ width: `${Math.max(2, r.pct)}%` }}
                  />
                </div>
              </div>
              <span className="theme-score">
                {r.pct}
                <span className="theme-score-suf">%</span>
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function RecentSessions({ attempts }: { attempts: AttemptSummaryResponse[] }) {
  if (attempts.length === 0) return null;
  return (
    <div className="card">
      <div className="card-head">
        <div>
          <h3>Sessions récentes</h3>
          <p>Vos {attempts.length} dernières activités</p>
        </div>
        <Link href="/historique" className="card-head-link">
          Voir l&apos;historique complet →
        </Link>
      </div>

      {/* Desktop : tableau classique */}
      <div className="table-wrap recent-desktop">
        <table>
          <thead>
            <tr>
              <th>DATE</th>
              <th>TYPE</th>
              <th>MODULE</th>
              <th>DURÉE</th>
              <th>SCORE</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {attempts.map((a) => (
              <RecentRow key={a.id} a={a} />
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile : cards empilées, tactile-friendly */}
      <ul className="recent-list">
        {attempts.map((a) => (
          <RecentCardMobile key={a.id} a={a} />
        ))}
      </ul>
    </div>
  );
}

function RecentCardMobile({ a }: { a: AttemptSummaryResponse }) {
  const isTcf = a.module === "TCF";
  const isExam = a.type === "MOCK_EXAM";
  const minutes =
    a.finishedAt && a.startedAt
      ? Math.max(1, Math.round((Date.parse(a.finishedAt) - Date.parse(a.startedAt)) / 60000))
      : null;
  const passed =
    isExam && a.passThreshold != null && a.score != null
      ? a.score >= a.passThreshold
      : null;
  const finished = a.finishedAt && a.score != null;

  return (
    <li>
      <Link href={`/sessions/${a.id}`} className="recent-card">
        <div className="recent-card-row recent-card-top">
          <span className={`tag tag-${isExam ? "exam" : "train"}`}>
            {isExam ? "EXAMEN" : "ENTRAÎN."}
          </span>
          <span className="recent-card-date">{formatDate(a.startedAt)}</span>
        </div>
        <div className="recent-card-row recent-card-meta">
          <span className="recent-card-module">{isTcf ? "TCF" : "Civique"}</span>
          <span className="recent-card-dot" aria-hidden>·</span>
          <span className="recent-card-time">
            {minutes != null ? `${minutes} min` : "en cours"}
          </span>
        </div>
        <div className="recent-card-row recent-card-bottom">
          {finished ? (
            <span className={`score-pill score-pill-${passed === false ? "fail" : "pass"}`}>
              <span className="score-pill-ico">{passed === false ? "✕" : "✓"}</span>
              {a.score} / {a.totalQuestions}
            </span>
          ) : (
            <span className="score-pill score-pill-neutral">En cours</span>
          )}
          <span className="recent-card-chev" aria-hidden>›</span>
        </div>
      </Link>
    </li>
  );
}

function RecentRow({ a }: { a: AttemptSummaryResponse }) {
  const isTcf = a.module === "TCF";
  const isExam = a.type === "MOCK_EXAM";
  const minutes =
    a.finishedAt && a.startedAt
      ? Math.max(1, Math.round((Date.parse(a.finishedAt) - Date.parse(a.startedAt)) / 60000))
      : null;
  const passed =
    isExam && a.passThreshold != null && a.score != null
      ? a.score >= a.passThreshold
      : null;

  return (
    <tr onClick={() => (window.location.href = `/sessions/${a.id}`)}>
      <td>{formatDate(a.startedAt)}</td>
      <td>
        <span className={`tag tag-${isExam ? "exam" : "train"}`}>
          {isExam ? "EXAMEN" : "ENTRAÎN."}
        </span>
      </td>
      <td>{isTcf ? "TCF" : "Civique"}</td>
      <td>{minutes != null ? `${minutes} min` : "—"}</td>
      <td>
        {a.finishedAt && a.score != null ? (
          <span className={`score-pill score-pill-${passed === false ? "fail" : "pass"}`}>
            <span className="score-pill-ico">{passed === false ? "✕" : "✓"}</span>{" "}
            {a.score} / {a.totalQuestions}
          </span>
        ) : (
          <span className="score-pill score-pill-neutral">En cours</span>
        )}
      </td>
      <td className="recent-chevron">›</td>
    </tr>
  );
}

// ============================================================================
// COUNTDOWN
// ============================================================================
function Countdown({
  examDate,
  onEdit,
}: {
  examDate: string | null;
  onEdit: () => void;
}) {
  // Refresh every minute to keep the minutes block alive.
  const [, force] = useState(0);
  useEffect(() => {
    const id = setInterval(() => force((v) => v + 1), 60_000);
    return () => clearInterval(id);
  }, []);

  if (!examDate) {
    return (
      <button type="button" className="countdown countdown-empty" onClick={onEdit}>
        <div className="countdown-label">DATE D&apos;EXAMEN</div>
        <div className="countdown-empty-text">
          Définir ma date d&apos;examen <ArrowIcon />
        </div>
      </button>
    );
  }

  const target = new Date(examDate).getTime();
  const now = Date.now();
  const diff = target - now;

  if (diff <= 0) {
    return (
      <button type="button" className="countdown" onClick={onEdit}>
        <div className="countdown-label">EXAMEN PASSÉ</div>
        <div className="countdown-empty-text">Mettre à jour ma date</div>
      </button>
    );
  }

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff / (1000 * 60 * 60)) % 24);
  const minutes = Math.floor((diff / (1000 * 60)) % 60);

  return (
    <button type="button" className="countdown" onClick={onEdit}>
      <div className="countdown-label">EXAMEN DANS</div>
      <div className="countdown-blocks">
        <div className="cdblock">
          <div className="cdblock-num">{String(days).padStart(2, "0")}</div>
          <div className="cdblock-unit">JOURS</div>
        </div>
        <div className="cdblock">
          <div className="cdblock-num">{String(hours).padStart(2, "0")}</div>
          <div className="cdblock-unit">HEURES</div>
        </div>
        <div className="cdblock">
          <div className="cdblock-num">{String(minutes).padStart(2, "0")}</div>
          <div className="cdblock-unit">MIN</div>
        </div>
      </div>
    </button>
  );
}

function ExamDatePicker({
  current,
  onSave,
  onClose,
}: {
  current: string | null;
  onSave: (d: string | null) => void;
  onClose: () => void;
}) {
  const [value, setValue] = useState(() => current ?? "");
  const minDate = new Date().toISOString().slice(0, 10);

  return (
    <div className="exam-picker-overlay" onClick={onClose}>
      <div
        className="exam-picker"
        role="dialog"
        aria-label="Date d'examen"
        onClick={(e) => e.stopPropagation()}
      >
        <h3>Quelle est votre date d&apos;examen ?</h3>
        <p>On affichera le compte à rebours sur votre tableau de bord.</p>
        <input
          type="date"
          min={minDate}
          value={value.slice(0, 10)}
          onChange={(e) => setValue(e.target.value)}
          className="exam-picker-input"
        />
        <div className="exam-picker-actions">
          {current && (
            <button
              type="button"
              className="exam-picker-clear"
              onClick={() => onSave(null)}
            >
              Effacer
            </button>
          )}
          <button type="button" className="exam-picker-cancel" onClick={onClose}>
            Annuler
          </button>
          <button
            type="button"
            className="exam-picker-save"
            disabled={!value}
            onClick={() => value && onSave(value)}
          >
            Enregistrer
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
function procedureLabelShort(p: TargetProcedure | null | undefined): string {
  switch (p) {
    case "NAT": return "NATURALISATION";
    case "CR": return "RÉSIDENT";
    case "CSP": return "CSP";
    default: return "VOTRE PARCOURS";
  }
}

function tcfLevelLabel(p: TargetProcedure | null | undefined): string {
  switch (p) {
    case "NAT": return "B2";
    case "CR": return "B1";
    case "CSP": return "A2";
    default: return "Tous niveaux";
  }
}

function buildBannerCopy({
  user,
  avgScore,
}: {
  user: { firstName: string; targetProcedure: TargetProcedure | null } | null;
  avgScore: number | null;
}): { title: string; body: string } {
  if (!user || avgScore === null) {
    return {
      title: "Bienvenue dans votre espace SejourFR.",
      body: "Commencez par un examen blanc pour vous situer, ou attaquez l'entraînement par thématique. Tout est gratuit pour vos premières questions.",
    };
  }
  const gap = 32 - avgScore;
  if (gap <= 0) {
    return {
      title: "Vous êtes au-dessus du seuil. Maintenez le cap.",
      body: `Score moyen sur vos 5 derniers examens blancs civiques : ${avgScore.toFixed(1)}/40. Continuez à varier les thèmes pour ne pas reculer.`,
    };
  }
  return {
    title: `Vous êtes à ${gap.toFixed(1)} points du seuil du civique.`,
    body: `Score moyen sur vos 5 derniers examens blancs : ${avgScore.toFixed(1)}/40. Le seuil officiel est de 32/40. Trois sessions ciblées devraient suffire.`,
  };
}

function computeStreak(attempts: AttemptSummaryResponse[]): number {
  if (attempts.length === 0) return 0;
  const days = new Set<string>();
  for (const a of attempts) {
    days.add(new Date(a.startedAt).toISOString().slice(0, 10));
  }
  let streak = 0;
  const cursor = new Date();
  cursor.setHours(0, 0, 0, 0);
  // Allow yesterday-only too: if today missing but yesterday present, start at 1.
  const today = cursor.toISOString().slice(0, 10);
  if (!days.has(today)) {
    cursor.setDate(cursor.getDate() - 1);
  }
  while (days.has(cursor.toISOString().slice(0, 10))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

function computeCumulativeMinutes(attempts: AttemptSummaryResponse[]): number {
  let total = 0;
  for (const a of attempts) {
    if (!a.finishedAt || !a.startedAt) continue;
    total += (Date.parse(a.finishedAt) - Date.parse(a.startedAt)) / 60000;
  }
  return Math.round(total);
}

function formatMinutes(m: number): string {
  if (m < 60) return `${m} min`;
  const h = Math.floor(m / 60);
  const r = m % 60;
  if (h < 100) {
    return r > 0 ? `${h}h${String(r).padStart(2, "0")}` : `${h}h`;
  }
  return `${h}h`;
}

const SHORT_MONTHS = [
  "janv", "févr", "mars", "avr", "mai", "juin",
  "juil", "août", "sept", "oct", "nov", "déc",
];

function formatDate(iso: string): string {
  const d = new Date(iso);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const day = new Date(d);
  day.setHours(0, 0, 0, 0);
  const diffDays = Math.round((today.getTime() - day.getTime()) / (1000 * 60 * 60 * 24));
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  if (diffDays === 0) return `Aujourd'hui · ${hh}:${mm}`;
  if (diffDays === 1) return `Hier · ${hh}:${mm}`;
  return `${d.getDate()} ${SHORT_MONTHS[d.getMonth()]} · ${hh}:${mm}`;
}

type ChartDatum = {
  label: string;
  civique: number | null;
  tcfPct: number | null;
};

function buildChartData(attempts: AttemptSummaryResponse[]): ChartDatum[] {
  const finished = attempts
    .filter(
      (a) =>
        a.type === "MOCK_EXAM" &&
        a.finishedAt !== null &&
        a.finishedAt !== undefined &&
        a.score !== null &&
        a.score !== undefined,
    )
    .sort((a, b) => Date.parse(a.startedAt) - Date.parse(b.startedAt))
    .slice(-10);

  return finished.map((a, idx) => {
    const score = a.score ?? 0;
    const tcfPct = a.module === "TCF" ? Math.round((score / a.totalQuestions) * 100) : null;
    const civique = a.module === "CIVIQUE" ? score : null;
    const d = new Date(a.startedAt);
    const label =
      idx === finished.length - 1
        ? "HIER"
        : `${d.getDate()}/${d.getMonth() + 1}`;
    return { label, civique, tcfPct };
  });
}

// ============================================================================
// SKELETONS / EMPTY
// ============================================================================
function DashSkeleton() {
  return (
    <div className="dash-loading">
      <p>Chargement…</p>
      <style>{`
        .dash-loading {
          padding: 120px 36px; text-align: center;
          color: var(--color-muted);
          font-family: var(--font-mono);
          font-size: 12px; letter-spacing: 0.1em;
        }
      `}</style>
    </div>
  );
}
const emptyStyle = `
  .dash-empty { padding: 120px 36px; text-align: center; color: var(--color-muted); }
  .dash-empty-link { color: var(--color-blue); text-decoration: underline; }
`;

// ============================================================================
// ICONS
// ============================================================================
const I = (props: React.SVGProps<SVGSVGElement>) => (
  <svg
    width="14"
    height="14"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    {...props}
  />
);
const ArrowIcon = () => (
  <I width="14" height="14">
    <path d="M5 12h14m-6 -6 6 6 -6 6" />
  </I>
);
const ClockIcon = () => (
  <I>
    <circle cx="12" cy="12" r="10" />
    <polyline points="12 6 12 12 16 14" />
  </I>
);
const StreakIcon = () => (
  <I width="18" height="18">
    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
  </I>
);
const CheckBadgeIcon = () => (
  <I width="18" height="18">
    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
    <polyline points="22 4 12 14.01 9 11.01" />
  </I>
);
const TrendingIcon = () => (
  <I width="18" height="18">
    <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
    <polyline points="17 6 23 6 23 12" />
  </I>
);
const ShieldIcon = () => (
  <I width="20" height="20">
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </I>
);
const BookIcon = () => (
  <I width="20" height="20">
    <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
    <path d="M21 19a2 2 0 0 1-2 2h-1v-7h3zM3 19a2 2 0 0 0 2 2h1v-7H3z" />
  </I>
);
const RefreshIcon = () => (
  <I width="20" height="20">
    <path d="M3 12a9 9 0 1 0 9-9" />
    <polyline points="3 5 3 12 10 12" />
  </I>
);

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .dash { padding: 24px 36px 60px; max-width: 1320px; margin: 0 auto; }
  @media (max-width: 760px) { .dash { padding: 20px 16px 56px; } }

  /* ========== TOPBAR ========== */
  .topbar {
    display: flex; justify-content: space-between; align-items: flex-start;
    margin-bottom: 26px;
    gap: 16px;
    flex-wrap: wrap;
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
  .topbar-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }

  .btn-primary, .btn-outline, .btn-outline-light {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 16px; border-radius: 10px;
    font-family: var(--font-sans);
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid transparent;
    cursor: pointer;
    transition: all 0.15s;
    white-space: nowrap;
  }
  .btn-primary { background: var(--color-blue); color: #fff; }
  .btn-primary:hover { background: var(--color-blue-dark); transform: translateY(-1px); }
  .btn-outline {
    background: #fff; color: var(--color-ink); border-color: var(--color-line);
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .btn-outline-light {
    background: transparent; color: #fff;
    border-color: rgba(255, 255, 255, 0.3);
  }
  .btn-outline-light:hover {
    background: rgba(255, 255, 255, 0.1);
    border-color: #fff;
  }

  /* ========== HERO BANNER ========== */
  .hero-banner {
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
    border-radius: 22px;
    padding: 28px 32px;
    color: #fff;
    margin-bottom: 24px;
    position: relative;
    overflow: hidden;
    display: grid;
    grid-template-columns: 1.5fr 1fr;
    gap: 32px;
    align-items: center;
  }
  .hero-banner::before {
    content: '';
    position: absolute;
    width: 280px; height: 280px;
    border-radius: 50%;
    background: var(--color-red);
    opacity: 0.2;
    top: -120px; right: -60px;
  }
  .hero-banner::after {
    content: '';
    position: absolute;
    width: 180px; height: 180px;
    border-radius: 50%;
    background: #fff;
    opacity: 0.06;
    bottom: -80px; right: 120px;
  }
  .hero-banner-text { position: relative; z-index: 1; }
  .hero-eyebrow {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    opacity: 0.75;
    margin-bottom: 10px;
  }
  .hero-banner h2 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: clamp(20px, 2.4vw, 26px);
    line-height: 1.2;
    letter-spacing: -0.015em;
    margin: 0 0 8px;
  }
  .hero-banner h2 em { color: #FFB3B0; font-style: italic; font-weight: 500; }
  .hero-banner p {
    margin: 0 0 18px;
    opacity: 0.85;
    font-size: 14.5px;
    max-width: 460px;
    line-height: 1.55;
  }
  .hero-actions { display: flex; gap: 10px; flex-wrap: wrap; }
  .hero-banner .btn-primary {
    background: #fff;
    color: var(--color-blue);
  }
  .hero-banner .btn-primary:hover {
    background: var(--color-paper);
  }

  .countdown {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 16px;
    padding: 18px;
    position: relative;
    z-index: 1;
    cursor: pointer;
    transition: background 0.15s;
    color: #fff;
    text-align: left;
    font-family: inherit;
  }
  .countdown:hover { background: rgba(255, 255, 255, 0.15); }
  .countdown-label {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    opacity: 0.75;
    margin-bottom: 12px;
  }
  .countdown-blocks { display: flex; gap: 10px; }
  .cdblock {
    flex: 1; text-align: center;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 10px 4px;
  }
  .cdblock-num {
    font-family: var(--font-display);
    font-size: 28px;
    font-weight: 600;
    line-height: 1;
    letter-spacing: -0.02em;
  }
  .cdblock-unit {
    font-family: var(--font-mono);
    font-size: 9px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    opacity: 0.75;
    margin-top: 4px;
  }
  .countdown-empty { padding: 20px; }
  .countdown-empty-text {
    font-size: 14px;
    font-weight: 600;
    display: flex; align-items: center; gap: 6px;
  }

  /* exam date picker */
  .exam-picker-overlay {
    position: fixed; inset: 0;
    background: rgba(15, 24, 57, 0.55);
    backdrop-filter: blur(4px);
    display: flex; align-items: center; justify-content: center;
    z-index: 100; padding: 24px;
  }
  .exam-picker {
    background: #fff;
    border-radius: 18px;
    padding: 32px;
    max-width: 420px; width: 100%;
    color: var(--color-ink);
    box-shadow: 0 30px 60px -20px rgba(15, 24, 57, 0.4);
  }
  .exam-picker h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 22px;
    margin: 0 0 8px;
    letter-spacing: -0.015em;
  }
  .exam-picker p {
    color: var(--color-muted);
    font-size: 14px;
    margin: 0 0 22px;
  }
  .exam-picker-input {
    width: 100%;
    padding: 12px 14px;
    border: 1px solid var(--color-line);
    border-radius: 10px;
    font-size: 15px;
    font-family: inherit;
    margin-bottom: 22px;
    color: var(--color-ink);
  }
  .exam-picker-input:focus {
    outline: none;
    border-color: var(--color-blue);
    box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.12);
  }
  .exam-picker-actions {
    display: flex; gap: 8px; justify-content: flex-end;
    align-items: center;
  }
  .exam-picker-clear {
    margin-right: auto;
    background: none; border: none;
    color: var(--color-red);
    font-size: 13px; font-weight: 600;
    cursor: pointer;
    padding: 8px 4px;
  }
  .exam-picker-cancel, .exam-picker-save {
    padding: 10px 16px;
    border-radius: 10px;
    font-size: 13px; font-weight: 600;
    cursor: pointer;
    border: 1px solid transparent;
    font-family: inherit;
  }
  .exam-picker-cancel {
    background: #fff;
    border-color: var(--color-line);
    color: var(--color-ink);
  }
  .exam-picker-cancel:hover { border-color: var(--color-ink); }
  .exam-picker-save {
    background: var(--color-blue);
    color: #fff;
  }
  .exam-picker-save:hover { background: var(--color-blue-dark); }
  .exam-picker-save:disabled { opacity: 0.5; cursor: not-allowed; }

  /* ========== STATS GRID ========== */
  .stats-grid {
    display: grid;
    /* minmax(0, 1fr) au lieu de 1fr : autorise les items à rétrécir sous
       leur taille de contenu intrinsèque. Sans ça, le contenu d'un card
       peut pousser la grille au-delà du viewport sur mobile. */
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 16px;
    margin-bottom: 26px;
  }
  .stat-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
    min-width: 0;
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
  .stat-trend {
    font-size: 12px;
    margin-top: 6px;
    font-weight: 500;
  }
  .stat-trend-up { color: var(--color-green); }
  .stat-trend-down { color: var(--color-red); }
  .stat-trend-neutral { color: var(--color-muted); }

  /* ========== SHORTCUTS ========== */
  .shortcuts {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
    margin-bottom: 26px;
  }
  .shortcut {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px;
    min-width: 0;
    text-decoration: none;
    color: inherit;
    transition: all 0.15s;
    position: relative;
    display: block;
  }
  .shortcut:hover {
    border-color: var(--color-blue);
    transform: translateY(-2px);
  }
  .shortcut-icon {
    width: 40px; height: 40px;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    margin-bottom: 14px;
  }
  .shortcut-civique .shortcut-icon { background: var(--color-blue-light); color: var(--color-blue); }
  .shortcut-tcf .shortcut-icon { background: var(--color-red-light); color: var(--color-red); }
  .shortcut-exam .shortcut-icon { background: rgba(232, 163, 23, 0.12); color: var(--color-amber); }
  .shortcut-review .shortcut-icon { background: rgba(22, 143, 91, 0.1); color: var(--color-green); }
  .shortcut h4 {
    margin: 0 0 4px;
    font-size: 14.5px;
    font-weight: 700;
    color: var(--color-ink);
  }
  .shortcut p { margin: 0; color: var(--color-muted); font-size: 12.5px; }
  .shortcut-arrow {
    position: absolute;
    top: 18px; right: 18px;
    color: var(--color-muted-2);
    transition: transform 0.15s, color 0.15s;
  }
  .shortcut:hover .shortcut-arrow {
    color: var(--color-blue);
    transform: translateX(3px);
  }

  /* ========== ROW 2 cols ========== */
  .row-2 {
    display: grid;
    grid-template-columns: 1.4fr 1fr;
    gap: 20px;
    margin-bottom: 26px;
  }
  .card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px;
    /* En tant que grid item, .card doit pouvoir rétrécir sous la taille
       intrinsèque de son contenu (notamment les <table min-width: 540px>
       qui scrollent à l'intérieur via .table-wrap). Sans min-width: 0,
       la card pousserait la grille au-delà du viewport. */
    min-width: 0;
  }
  .card-head {
    display: flex; justify-content: space-between; align-items: flex-start;
    margin-bottom: 18px;
    gap: 12px;
  }
  .card-head h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    margin: 0 0 4px;
    letter-spacing: -0.01em;
  }
  .card-head p { margin: 0; color: var(--color-muted); font-size: 13px; }
  .card-head-link {
    font-size: 13px;
    color: var(--color-blue);
    font-weight: 600;
    text-decoration: none;
    flex-shrink: 0;
  }
  .card-head-link:hover { text-decoration: underline; }

  .chart-legend {
    display: flex; gap: 16px; flex-wrap: wrap;
    margin-bottom: 18px;
  }
  .legend-item {
    display: flex; align-items: center; gap: 7px;
    font-size: 12px; color: var(--color-muted);
  }
  .legend-dot { width: 10px; height: 10px; border-radius: 3px; flex-shrink: 0; }
  .legend-dot.blue { background: var(--color-blue); }
  .legend-dot.red { background: var(--color-red); }
  .legend-dot.line { background: var(--color-green); }
  .chart-svg { width: 100%; height: 220px; display: block; }
  .chart-empty {
    text-align: center;
    padding: 40px 20px;
    color: var(--color-muted);
  }
  .chart-empty p { margin: 0 0 12px; font-size: 14px; }
  .chart-empty-cta {
    font-size: 13.5px; font-weight: 700;
    color: var(--color-blue);
  }

  /* ========== THEMES ========== */
  .theme-list { display: flex; flex-direction: column; gap: 14px; }
  .theme-row {
    display: grid;
    grid-template-columns: 28px 1fr 60px;
    gap: 12px;
    align-items: center;
  }
  .theme-num {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--color-blue);
    font-weight: 700;
  }
  .theme-row-content { min-width: 0; }
  .theme-name {
    font-size: 13.5px; font-weight: 600; color: var(--color-ink);
    margin-bottom: 5px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .theme-bar {
    height: 6px;
    background: var(--color-line-2);
    border-radius: 3px;
    overflow: hidden;
  }
  .theme-bar-fill {
    height: 100%; border-radius: 3px;
    background: var(--color-blue);
  }
  .theme-bar-green { background: var(--color-green); }
  .theme-bar-blue { background: var(--color-blue); }
  .theme-bar-amber { background: var(--color-amber); }
  .theme-bar-red { background: var(--color-red); }
  .theme-score {
    text-align: right;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 700;
    color: var(--color-ink);
  }
  .theme-score-suf { color: var(--color-muted); font-weight: 500; }
  .theme-skel {
    height: 200px;
    background: var(--color-paper-2);
    border-radius: 10px;
    animation: dash-pulse 1.4s ease-in-out infinite;
  }
  @keyframes dash-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }
  .theme-empty p {
    color: var(--color-muted);
    font-size: 13.5px;
    text-align: center;
    margin: 30px 10px;
    line-height: 1.5;
  }

  /* ========== TABLE ========== */
  .table-wrap {
    overflow: hidden;
    border-radius: 14px;
    border: 1px solid var(--color-line);
    margin-top: -4px;
  }
  table { width: 100%; border-collapse: collapse; }
  th, td { text-align: left; padding: 13px 16px; }
  th {
    background: var(--color-paper);
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--color-muted);
    font-weight: 600;
    border-bottom: 1px solid var(--color-line);
  }
  td {
    font-size: 13.5px;
    color: var(--color-ink-2);
    border-bottom: 1px solid var(--color-line-2);
  }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr {
    transition: background 0.15s;
    cursor: pointer;
  }
  tbody tr:hover { background: var(--color-blue-soft); }
  .recent-chevron { text-align: right; color: var(--color-muted-2); }

  .tag {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 10px;
    padding: 3px 8px;
    border-radius: 5px;
    letter-spacing: 0.08em;
    font-weight: 700;
  }
  .tag-exam { background: rgba(232, 163, 23, 0.18); color: var(--color-amber); }
  .tag-train { background: var(--color-line-2); color: var(--color-ink-2); }

  .score-pill {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 700;
  }
  .score-pill-pass { color: var(--color-green); }
  .score-pill-fail { color: var(--color-red); }
  .score-pill-neutral { color: var(--color-muted); font-weight: 600; }
  .score-pill-ico {
    width: 14px; height: 14px;
    border-radius: 50%;
    display: inline-flex; align-items: center; justify-content: center;
    color: #fff;
    font-size: 9px;
    background: var(--color-green);
  }
  .score-pill-fail .score-pill-ico { background: var(--color-red); }

  /* ========== RECENT SESSIONS — cards mobile (cachées sur desktop) ========== */
  .recent-list { display: none; }
  .recent-card {
    display: flex;
    flex-direction: column;
    gap: 6px;
    padding: 14px;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    background: var(--color-paper);
    text-decoration: none;
    color: inherit;
    transition: background 0.15s, border-color 0.15s, transform 0.1s;
  }
  .recent-card:active { transform: scale(0.99); }
  .recent-card-row { display: flex; align-items: center; gap: 8px; }
  .recent-card-top { justify-content: space-between; }
  .recent-card-date {
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.06em;
    color: var(--color-muted);
  }
  .recent-card-meta { color: var(--color-ink-2); font-size: 13.5px; }
  .recent-card-module { font-weight: 600; color: var(--color-ink); }
  .recent-card-dot { color: var(--color-muted-2); }
  .recent-card-bottom { justify-content: space-between; margin-top: 2px; }
  .recent-card-chev {
    color: var(--color-muted-2);
    font-size: 22px;
    line-height: 1;
  }

  /* ========== RESPONSIVE ========== */
  @media (max-width: 1100px) {
    .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .shortcuts { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .row-2 { grid-template-columns: minmax(0, 1fr); }
    .hero-banner { grid-template-columns: minmax(0, 1fr); }
  }
  @media (max-width: 680px) {
    .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .shortcuts { grid-template-columns: minmax(0, 1fr); }
    /* Bascule table → cards empilées (plus de scroll horizontal) */
    .recent-desktop { display: none; }
    .recent-list {
      display: flex;
      flex-direction: column;
      gap: 8px;
      list-style: none;
      padding: 0;
      margin: 0;
    }
  }
  @media (max-width: 480px) {
    .hero-banner { padding: 22px 20px; border-radius: 18px; }
    .hero-banner h2 { font-size: 22px; }
    .hero-actions { flex-direction: column; align-items: stretch; }
    .hero-actions .btn-primary,
    .hero-actions .btn-outline-light { width: 100%; }
    .stats-grid { grid-template-columns: 1fr; }
    .topbar h1 { font-size: 22px; }
    /* Card-head : titre + lien empilés verticalement pour ne pas déborder */
    .card { padding: 16px; border-radius: 14px; }
    .card-head {
      flex-direction: column;
      align-items: flex-start;
      gap: 6px;
    }
    .card-head-link { flex-shrink: 1; }
    /* Table : padding cellules réduit pour gagner un peu sur la largeur scrollable */
    th, td { padding: 11px 12px; }
  }
`;
