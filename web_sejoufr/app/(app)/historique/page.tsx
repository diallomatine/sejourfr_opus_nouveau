"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";
import { Landmark, Languages, Mic, PenLine, Smartphone } from "lucide-react";
import {
  type ProductionKind,
  ProductionMobileSheet,
} from "@/app/_components/ProductionMobileSheet";
import { ApiException, attemptApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  type AttemptSummaryResponse,
  isProductionAttempt,
  type Module as ModuleEnum,
} from "@/lib/types";

type TypeFilter = "ALL" | "EXAM" | "TRAIN" | "PROD";
type PeriodFilter = "7D" | "30D" | "ALL";

export default function HistoriquePage() {
  return (
    <Suspense fallback={<HistoriqueSkeleton />}>
      <HistoriqueInner />
    </Suspense>
  );
}

function HistoriqueInner() {
  const { user, status } = useAuth();
  const searchParams = useSearchParams();
  const moduleParam = searchParams.get("module");
  const moduleView: ModuleEnum | null =
    moduleParam === "TCF" ? "TCF" : moduleParam === "CIVIQUE" ? "CIVIQUE" : null;

  const [attempts, setAttempts] = useState<AttemptSummaryResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [typeFilter, setTypeFilter] = useState<TypeFilter>("ALL");
  const [periodFilter, setPeriodFilter] = useState<PeriodFilter>("ALL");
  const [query, setQuery] = useState("");
  const [productionSheet, setProductionSheet] = useState<ProductionKind | null>(null);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    attemptApi
      .listMine({ limit: 100 })
      .then((list) => {
        if (cancelled) return;
        setAttempts(list);
        setError(null);
        setLoading(false);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(
          e instanceof ApiException
            ? e.message
            : "Impossible de charger l'historique.",
        );
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status]);

  // ========== FILTRES ==========
  const filtered = useMemo(() => {
    // eslint-disable-next-line react-hooks/purity
    const now = Date.now();
    const periodMs =
      periodFilter === "7D"
        ? 7 * 86_400_000
        : periodFilter === "30D"
          ? 30 * 86_400_000
          : null;
    const q = query.trim().toLowerCase();

    return [...attempts]
      .sort((a, b) => Date.parse(b.startedAt) - Date.parse(a.startedAt))
      .filter((a) => {
        // En mode liste (catégorie choisie) : uniquement les examens de ce
        // module (sous-examens thème/module + examens blancs complets),
        // jamais les entraînements/lots.
        if (moduleView) {
          if (a.module !== moduleView) return false;
          if (a.type !== "MOCK_EXAM") return false;
        }
        const isProd = isProductionAttempt(a);
        // type
        // EXAM = MOCK_EXAM QCM uniquement (les productions EO/EE sont TRAINING).
        // TRAIN = TRAINING QCM (hors productions).
        // PROD = productions EO/EE.
        if (typeFilter === "EXAM" && (a.type !== "MOCK_EXAM" || isProd)) return false;
        if (typeFilter === "TRAIN" && (a.type !== "TRAINING" || isProd)) return false;
        if (typeFilter === "PROD" && !isProd) return false;
        // période
        if (periodMs != null && now - Date.parse(a.startedAt) > periodMs)
          return false;
        // recherche : module + type + difficulty + production
        if (q) {
          const moduleLabel = (a.module === "TCF" ? "tcf" : "civique").toLowerCase();
          const typeLabel = isProd
            ? "production expression " + (a.epreuve === "TCF_EO" ? "orale eo" : a.epreuve === "TCF_EE" ? "écrite ecrite ee" : "")
            : a.type === "MOCK_EXAM"
              ? "examen blanc exam"
              : "entraînement training";
          const diffLabel = a.difficulty ? String(a.difficulty).toLowerCase() : "";
          if (
            !moduleLabel.includes(q) &&
            !typeLabel.includes(q) &&
            !diffLabel.includes(q)
          ) {
            return false;
          }
        }
        return true;
      });
  }, [attempts, moduleView, typeFilter, periodFilter, query]);

  // ========== STATS GLOBALES ==========
  // Les productions EO/EE n'ont ni totalQuestions ni score : elles sont
  // exclues des metriques de pourcentage (passRate, bestScore) et comptees
  // separement dans le total. On considere une production "finie" si elle a
  // un finishedAt (le score IA est sur une autre route).
  const stats = useMemo(() => {
    // En mode liste, les stats résument le module choisi (examens de ce module).
    const base = moduleView ? attempts.filter((a) => a.module === moduleView) : attempts;
    const qcm = base.filter((a) => !isProductionAttempt(a));
    const productions = base.filter((a) => isProductionAttempt(a));
    const finishedQcm = qcm.filter(
      (a) => a.finishedAt && a.score !== null && a.score !== undefined,
    );
    const exams = finishedQcm.filter((a) => a.type === "MOCK_EXAM");
    const totalSessions = finishedQcm.length + productions.length;
    if (totalSessions === 0) {
      return {
        total: 0,
        examsCount: 0,
        examsFinished: 0,
        examsPassed: 0,
        trainCount: 0,
        prodCount: 0,
        passRate: null as number | null,
        bestLabel: null as string | null,
        bestDetail: null as string | null,
      };
    }
    const passed = exams.filter((a) => {
      const total = a.totalQuestions ?? 0;
      if (a.module === "CIVIQUE" && a.passThreshold != null) {
        return (a.score ?? 0) >= a.passThreshold;
      }
      return total > 0 && (a.score ?? 0) / total >= 0.6;
    }).length;
    const passRate = exams.length > 0 ? Math.round((passed / exams.length) * 100) : null;
    let bestPct = -1;
    let best: AttemptSummaryResponse | null = null;
    for (const a of exams) {
      const total = a.totalQuestions ?? 0;
      if (total === 0) continue;
      const pct = (a.score ?? 0) / total;
      if (pct > bestPct) {
        bestPct = pct;
        best = a;
      }
    }
    const bestLabel = best ? `${best.score}/${best.totalQuestions ?? "—"}` : null;
    const bestDetail = best
      ? `${best.module === "TCF" ? "TCF" : "Civique"} · ${formatShortDate(best.startedAt)}`
      : null;
    return {
      total: totalSessions,
      examsCount: base.filter((a) => a.type === "MOCK_EXAM" && !isProductionAttempt(a)).length,
      examsFinished: exams.length,
      examsPassed: passed,
      trainCount: base.filter((a) => a.type === "TRAINING" && !isProductionAttempt(a)).length,
      prodCount: productions.length,
      passRate,
      bestLabel,
      bestDetail,
    };
  }, [attempts, moduleView]);

  if (status === "loading") return <HistoriqueSkeleton />;
  if (!user) {
    return (
      <main className="hi-gate">
        <p>Connectez-vous pour voir votre historique.</p>
        <Link href="/connexion?next=/historique" className="hi-gate-cta">
          Se connecter →
        </Link>
        <style>{gateStyles}</style>
      </main>
    );
  }

  // ============ HUB (façon "Mes historiques" mobile) ============
  if (!moduleView) {
    return (
      <main className="hi">
        <header className="topbar">
          <div>
            <div className="breadcrumb">
              ACCUEIL <span className="sep">/</span> HISTORIQUE
            </div>
            <h1>
              Mes <em>historiques</em>.
            </h1>
          </div>
        </header>
        <p className="hub-intro">
          Consultez vos examens blancs et sessions IA passés.
        </p>

        <div className="hub-summary">
          <div className="hub-summary-item">
            <span className="hub-summary-val">{stats.examsFinished}</span>
            <span className="hub-summary-lbl">Examens passés</span>
          </div>
          <div className="hub-summary-item">
            <span className="hub-summary-val hub-summary-val-green">{stats.examsPassed}</span>
            <span className="hub-summary-lbl">Réussis</span>
          </div>
          <div className="hub-summary-item">
            <span className="hub-summary-val">
              {stats.passRate != null ? `${stats.passRate}%` : "—"}
            </span>
            <span className="hub-summary-lbl">Taux de réussite</span>
          </div>
          <div className="hub-summary-item">
            <span className="hub-summary-val">{stats.bestLabel ?? "—"}</span>
            <span className="hub-summary-lbl">Meilleur score</span>
          </div>
        </div>

        <div className="hub-section-label">§ EXAMENS BLANCS</div>
        <div className="hub-cats">
          <Link href="/historique?module=CIVIQUE" className="hub-cat">
            <span className="hub-cat-ico ico-blue" aria-hidden>
              <Landmark size={22} />
            </span>
            <span className="hub-cat-body">
              <span className="hub-cat-title">Examens civique</span>
              <span className="hub-cat-sub">
                40 questions tous thèmes, seuil 32. Score et progression dans le temps.
              </span>
            </span>
            <span className="hub-cat-arrow" aria-hidden>›</span>
          </Link>
          <Link href="/historique?module=TCF" className="hub-cat">
            <span className="hub-cat-ico ico-red" aria-hidden>
              <Languages size={22} />
            </span>
            <span className="hub-cat-body">
              <span className="hub-cat-title">Examens TCF</span>
              <span className="hub-cat-sub">
                CO et CE en conditions réelles, score pondéré par niveau (A2 → B2).
              </span>
            </span>
            <span className="hub-cat-arrow" aria-hidden>›</span>
          </Link>
        </div>

        <div className="hub-section-label">§ SESSIONS IA</div>
        <div className="hub-cats">
          <button type="button" className="hub-cat" onClick={() => setProductionSheet("EE")}>
            <span className="hub-cat-ico ico-green" aria-hidden>
              <PenLine size={22} />
            </span>
            <span className="hub-cat-body">
              <span className="hub-cat-title">Expression écrite</span>
              <span className="hub-cat-sub">
                Rédactions notées par IA, niveau CECRL et feedback détaillé. Sur l&apos;app mobile.
              </span>
            </span>
            <span className="hub-cat-arrow" aria-hidden>
              <Smartphone size={16} />
            </span>
          </button>
          <button type="button" className="hub-cat" onClick={() => setProductionSheet("EO")}>
            <span className="hub-cat-ico ico-red" aria-hidden>
              <Mic size={22} />
            </span>
            <span className="hub-cat-body">
              <span className="hub-cat-title">Expression orale</span>
              <span className="hub-cat-sub">
                Enregistrements transcrits par Whisper et évalués par IA. Sur l&apos;app mobile.
              </span>
            </span>
            <span className="hub-cat-arrow" aria-hidden>
              <Smartphone size={16} />
            </span>
          </button>
        </div>

        <ProductionMobileSheet
          open={productionSheet !== null}
          kind={productionSheet}
          onClose={() => setProductionSheet(null)}
        />
        <style>{styles}{hubStyles}</style>
      </main>
    );
  }

  // ============ MODE LISTE (catégorie choisie) ============
  const moduleLabel = moduleView === "TCF" ? "TCF" : "civique";
  return (
    <main className="hi">
      {/* ============ TOPBAR ============ */}
      <header className="topbar">
        <div>
          <div className="breadcrumb">
            <Link href="/historique">HISTORIQUE</Link>{" "}
            <span className="sep">/</span> EXAMENS {moduleLabel.toUpperCase()}
          </div>
          <h1>
            Examens <em>{moduleLabel}</em>.
          </h1>
        </div>
        <div className="topbar-actions">
          <Link href="/historique" className="btn-outline">
            ← Mes historiques
          </Link>
        </div>
      </header>

      {error && <div className="form-error hi-error">{error}</div>}

      {/* ============ STATS ============ */}
      <section className="stats-grid">
        <StatCard
          tone="blue"
          icon={<ListIcon />}
          label="SESSIONS TOTALES"
          value={String(stats.total)}
          trend={
            stats.total > 0
              ? [
                  stats.examsCount > 0 ? `${stats.examsCount} examens` : null,
                  stats.trainCount > 0 ? `${stats.trainCount} entraînements` : null,
                  stats.prodCount > 0 ? `${stats.prodCount} productions` : null,
                ]
                  .filter(Boolean)
                  .join(" · ")
              : "Pas encore"
          }
        />
        <StatCard
          tone="green"
          icon={<CheckIcon />}
          label="TAUX DE RÉUSSITE EXAMENS"
          value={stats.passRate != null ? `${stats.passRate}%` : "—"}
          trend={stats.passRate != null ? "Sur vos examens blancs" : "À débloquer"}
        />
        <StatCard
          tone="amber"
          icon={<TrophyIcon />}
          label="MEILLEUR SCORE"
          value={stats.bestLabel ?? "—"}
          trend={stats.bestDetail ?? "À jouer"}
        />
      </section>

      {/* ============ FILTERS (examens du module : période + recherche) ============ */}
      <section className="filters">
        <div className="period-chips">
          {(
            [
              ["7D", "7 jours"],
              ["30D", "30 jours"],
              ["ALL", "Tout"],
            ] as const
          ).map(([k, lbl]) => (
            <button
              key={k}
              type="button"
              className={`chip ${periodFilter === k ? "is-active" : ""}`}
              onClick={() => setPeriodFilter(k)}
            >
              {lbl}
            </button>
          ))}
        </div>

        <div className="search-wrap">
          <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden
          >
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Civique, TCF, NAT…"
            aria-label="Filtrer les sessions"
          />
        </div>
      </section>

      {/* ============ TABLE ============ */}
      <section className="hi-card">
        {loading && attempts.length === 0 ? (
          <TableSkeleton />
        ) : filtered.length === 0 ? (
          <EmptyState
            hasAny={attempts.length > 0}
            onReset={() => {
              setTypeFilter("ALL");
              setPeriodFilter("ALL");
              setQuery("");
            }}
          />
        ) : (
          <>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>DATE</th>
                    <th>TYPE</th>
                    <th>MODULE</th>
                    <th>QUESTIONS</th>
                    <th>DURÉE</th>
                    <th>SCORE</th>
                    <th>STATUT</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((a) =>
                    isProductionAttempt(a) ? (
                      <ProductionRow
                        key={a.id}
                        a={a}
                        onOpen={(kind) => setProductionSheet(kind)}
                      />
                    ) : (
                      <AttemptRow key={a.id} a={a} />
                    ),
                  )}
                </tbody>
              </table>
            </div>
            <div className="hi-footer">
              <span>
                {filtered.length} session{filtered.length > 1 ? "s" : ""} affichée
                {filtered.length > 1 ? "s" : ""} sur {attempts.length}
              </span>
            </div>
          </>
        )}
      </section>

      <ProductionMobileSheet
        open={productionSheet !== null}
        kind={productionSheet}
        onClose={() => setProductionSheet(null)}
      />

      <style>{styles}{hubStyles}</style>
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
// ROW
// ============================================================================
function AttemptRow({ a }: { a: AttemptSummaryResponse }) {
  const isTcf = a.module === "TCF";
  const isExam = a.type === "MOCK_EXAM";
  const score = a.score ?? 0;
  const total = a.totalQuestions ?? 0;
  const pct = total > 0 ? Math.round((score / total) * 100) : 0;
  const isFinished = !!a.finishedAt;

  const minutes =
    isFinished && a.finishedAt
      ? Math.max(
          1,
          Math.round((Date.parse(a.finishedAt) - Date.parse(a.startedAt)) / 60000),
        )
      : null;

  let statusLabel: string;
  let statusTone: "good" | "warn" | "neutral";
  if (!isFinished) {
    statusLabel = "EN COURS";
    statusTone = "neutral";
  } else if (isExam) {
    if (isTcf) {
      statusLabel = "DIAGNOSTIC";
      statusTone = "neutral";
    } else if (a.passThreshold != null) {
      const passed = score >= a.passThreshold;
      statusLabel = passed ? "RÉUSSI" : "ÉCHEC";
      statusTone = passed ? "good" : "warn";
    } else {
      statusLabel = `${pct}%`;
      statusTone = pct >= 70 ? "good" : "warn";
    }
  } else {
    statusLabel = `${pct}%`;
    statusTone = pct >= 70 ? "good" : pct >= 50 ? "neutral" : "warn";
  }

  return (
    <tr onClick={() => (window.location.href = `/sessions/${a.id}`)}>
      <td>{formatRowDate(a.startedAt)}</td>
      <td>
        <span className={`tag tag-${isExam ? "exam" : "train"}`}>
          {isExam ? "EXAMEN" : "ENTRAÎN."}
        </span>
      </td>
      <td>
        <span className={`module-pill module-pill-${isTcf ? "red" : "blue"}`}>
          {isTcf ? "TCF" : "Civique"}
        </span>
        {a.difficulty && (
          <span className="row-target">{String(a.difficulty)}</span>
        )}
      </td>
      <td className="num">{total}</td>
      <td className="num">{minutes != null ? `${minutes} min` : "—"}</td>
      <td>
        {isFinished && a.score != null ? (
          <span
            className={`score-pill score-pill-${
              statusTone === "good" ? "pass" : statusTone === "warn" ? "fail" : "neutral"
            }`}
          >
            <span className="score-pill-ico">
              {statusTone === "good" ? "✓" : statusTone === "warn" ? "✕" : "·"}
            </span>{" "}
            {a.score} / {total}
          </span>
        ) : (
          <span className="score-pill score-pill-neutral">—</span>
        )}
      </td>
      <td>
        <span className={`status-text status-text-${statusTone}`}>{statusLabel}</span>
      </td>
      <td className="row-chevron">›</td>
    </tr>
  );
}

// ============================================================================
// PRODUCTION ROW (EO / EE) — pas de QCM, pas de score affiché ici, click ouvre
// le sheet de redirection vers l'app mobile (l'evaluation IA vit cote mobile).
// ============================================================================
function ProductionRow({
  a,
  onOpen,
}: {
  a: AttemptSummaryResponse;
  onOpen: (kind: ProductionKind) => void;
}) {
  const isOral = a.epreuve === "TCF_EO";
  const isComplet = a.epreuve === "TCF_COMPLET";
  const kind: ProductionKind = isOral ? "EO" : "EE";
  const label = isComplet
    ? "Examen blanc EO+EE"
    : isOral
      ? "Expression orale"
      : "Expression écrite";
  const Icon = isOral ? Mic : PenLine;

  const isFinished = !!a.finishedAt;
  const minutes =
    isFinished && a.finishedAt
      ? Math.max(
          1,
          Math.round((Date.parse(a.finishedAt) - Date.parse(a.startedAt)) / 60000),
        )
      : null;

  return (
    <tr className="prod-row" onClick={() => onOpen(kind)}>
      <td>{formatRowDate(a.startedAt)}</td>
      <td>
        <span className="tag tag-prod">PRODUCTION</span>
      </td>
      <td>
        <span className="module-pill module-pill-red">TCF</span>
        <span className="prod-row-label">
          <Icon size={12} strokeWidth={2.2} aria-hidden /> {label}
        </span>
      </td>
      <td className="num">—</td>
      <td className="num">{minutes != null ? `${minutes} min` : "—"}</td>
      <td>
        <span className="score-pill score-pill-neutral">
          <Smartphone size={12} strokeWidth={2} aria-hidden /> Évaluation IA
        </span>
      </td>
      <td>
        <span className="status-text status-text-mobile">APP MOBILE</span>
      </td>
      <td className="row-chevron">›</td>
    </tr>
  );
}

// ============================================================================
// EMPTY / SKELETON
// ============================================================================
function EmptyState({
  hasAny,
  onReset,
}: {
  hasAny: boolean;
  onReset: () => void;
}) {
  if (!hasAny) {
    return (
      <div className="hi-empty">
        <div className="hi-empty-icon" aria-hidden>
          <svg
            viewBox="0 0 24 24"
            width="28"
            height="28"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="12" cy="13" r="8" />
            <path d="M12 9v4l3 2M9 3h6" />
          </svg>
        </div>
        <h3>Aucune session pour le moment</h3>
        <p>
          Lancez votre premier entraînement ou examen blanc. Le résultat
          apparaîtra ici.
        </p>
        <div className="hi-empty-cta-wrap">
          <Link href="/entrainement" className="btn-primary">
            S&apos;entraîner
          </Link>
          <Link href="/examens-blancs" className="btn-outline">
            Examens blancs
          </Link>
        </div>
      </div>
    );
  }
  return (
    <div className="hi-empty">
      <h3>Aucune session ne correspond aux filtres</h3>
      <p>Essayez d&apos;élargir la période ou de changer le type de session.</p>
      <button type="button" className="btn-primary" onClick={onReset}>
        Réinitialiser les filtres
      </button>
    </div>
  );
}

function TableSkeleton() {
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>DATE</th>
            <th>TYPE</th>
            <th>MODULE</th>
            <th>QUESTIONS</th>
            <th>DURÉE</th>
            <th>SCORE</th>
            <th>STATUT</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {[0, 1, 2, 3, 4].map((i) => (
            <tr key={i} className="skel-row">
              {Array.from({ length: 8 }).map((_, j) => (
                <td key={j}>
                  <span className="skel-cell" />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function HistoriqueSkeleton() {
  return (
    <div className="hi-loading">
      <style>{`.hi-loading { min-height: calc(100vh - 80px); background: #F7F8FC; }`}</style>
    </div>
  );
}

const gateStyles = `
  .hi-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px;
    color: var(--color-muted);
    padding: 36px;
  }
  .hi-gate-cta { color: var(--color-blue); font-weight: 700; text-decoration: none; }
`;

// Hub "Mes historiques" : sections + cartes catégories (façon mobile).
const hubStyles = `
  .breadcrumb a { color: var(--color-blue); text-decoration: none; }
  .breadcrumb a:hover { text-decoration: underline; }
  .hub-intro {
    color: var(--color-muted); font-size: 14px; line-height: 1.55;
    margin: 0 0 18px; max-width: 640px;
  }
  .hub-summary {
    display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px;
    margin-bottom: 26px;
  }
  .hub-summary-item {
    background: #fff; border: 1px solid var(--color-line); border-radius: 14px;
    padding: 14px 16px; display: flex; flex-direction: column; gap: 4px;
  }
  .hub-summary-val {
    font-family: var(--font-display); font-weight: 600; font-size: 26px;
    line-height: 1; color: var(--color-ink); letter-spacing: -0.02em;
    font-variant-numeric: tabular-nums;
  }
  .hub-summary-val-green { color: var(--color-green); }
  .hub-summary-lbl {
    font-family: var(--font-mono); font-size: 10px; font-weight: 600;
    letter-spacing: 0.1em; text-transform: uppercase; color: var(--color-muted);
  }
  @media (max-width: 680px) {
    .hub-summary { grid-template-columns: repeat(2, 1fr); }
  }
  .hub-section-label {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    letter-spacing: 0.2em; color: var(--color-muted);
    margin: 0 0 10px;
  }
  .hub-cats { display: flex; flex-direction: column; gap: 10px; margin-bottom: 26px; }
  .hub-cat {
    display: flex; align-items: center; gap: 14px;
    width: 100%; text-align: left; font-family: inherit; cursor: pointer;
    background: #fff; border: 1px solid var(--color-line); border-radius: 14px;
    padding: 14px; text-decoration: none;
    transition: transform 0.15s, border-color 0.15s, box-shadow 0.15s;
  }
  .hub-cat:hover {
    transform: translateY(-2px); border-color: var(--color-blue);
    box-shadow: 0 14px 32px -20px rgba(30,58,140,0.3);
  }
  .hub-cat-ico {
    width: 42px; height: 42px; flex-shrink: 0; border-radius: 12px;
    display: inline-flex; align-items: center; justify-content: center;
  }
  .hub-cat-ico.ico-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .hub-cat-ico.ico-red { background: var(--color-red-light); color: var(--color-red); }
  .hub-cat-ico.ico-green { background: rgba(22,143,91,0.12); color: var(--color-green); }
  .hub-cat-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
  .hub-cat-title { font-family: var(--font-sans); font-weight: 700; font-size: 14.5px; color: var(--color-ink); }
  .hub-cat-sub { font-size: 12.5px; color: var(--color-muted); line-height: 1.4; }
  .hub-cat-arrow {
    flex-shrink: 0; color: var(--color-muted-2); font-size: 20px;
    display: inline-flex; align-items: center;
  }
`;

// ============================================================================
// HELPERS
// ============================================================================
const SHORT_MONTHS = ["janv", "févr", "mars", "avr", "mai", "juin", "juil", "août", "sept", "oct", "nov", "déc"];

function formatRowDate(iso: string): string {
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

function formatShortDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getDate()} ${SHORT_MONTHS[d.getMonth()]}`;
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
const ListIcon = () => (
  <I>
    <line x1="8" y1="6" x2="21" y2="6" />
    <line x1="8" y1="12" x2="21" y2="12" />
    <line x1="8" y1="18" x2="21" y2="18" />
    <circle cx="4" cy="6" r="1" />
    <circle cx="4" cy="12" r="1" />
    <circle cx="4" cy="18" r="1" />
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
  .hi { padding: 24px 36px 64px; max-width: 1320px; }
  @media (max-width: 760px) { .hi { padding: 20px 16px 56px; } }

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
    cursor: pointer;
    font-family: inherit;
  }
  .btn-outline:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .btn-primary {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 600;
    text-decoration: none;
    border: 1px solid transparent;
    background: var(--color-blue); color: #fff;
    cursor: pointer;
    transition: all 0.15s;
    font-family: inherit;
  }
  .btn-primary:hover { background: var(--color-blue-dark); }

  .hi-error { margin-bottom: 18px; }

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

  /* ========== FILTERS ========== */
  .filters {
    display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
    margin-bottom: 18px;
  }
  .filter-tabs {
    display: inline-flex;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 4px;
    gap: 2px;
  }
  .tab {
    display: inline-flex; align-items: center; gap: 7px;
    padding: 8px 16px;
    background: transparent;
    border: none;
    border-radius: 8px;
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    color: var(--color-muted);
    cursor: pointer;
    transition: all 0.15s;
  }
  .tab:hover { color: var(--color-ink); }
  .tab.is-active {
    background: var(--color-blue);
    color: #fff;
  }
  .tab-count {
    font-family: var(--font-mono);
    font-size: 10px;
    background: rgba(255, 255, 255, 0.25);
    padding: 1px 6px;
    border-radius: 100px;
    font-weight: 700;
  }

  .period-chips {
    display: flex; gap: 6px;
  }
  .chip {
    padding: 8px 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 10px;
    font-family: inherit;
    font-size: 12.5px;
    font-weight: 600;
    color: var(--color-ink-2);
    cursor: pointer;
    transition: all 0.15s;
  }
  .chip:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .chip.is-active {
    background: var(--color-ink);
    color: #fff;
    border-color: var(--color-ink);
  }

  .search-wrap {
    position: relative;
    margin-left: auto;
  }
  .search-wrap svg {
    position: absolute;
    left: 12px; top: 50%;
    transform: translateY(-50%);
    color: var(--color-muted);
  }
  .search-wrap input {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 10px;
    padding: 9px 14px 9px 36px;
    font-family: inherit;
    font-size: 13px;
    width: 240px;
    color: var(--color-ink);
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  .search-wrap input:focus {
    outline: none;
    border-color: var(--color-blue);
    box-shadow: 0 0 0 3px rgba(30, 58, 140, 0.12);
  }

  /* ========== TABLE CARD ========== */
  .hi-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    overflow: hidden;
  }
  .table-wrap {
    overflow-x: auto;
  }
  table { width: 100%; border-collapse: collapse; min-width: 700px; }
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
    white-space: nowrap;
  }
  td {
    font-size: 13.5px;
    color: var(--color-ink-2);
    border-bottom: 1px solid var(--color-line-2);
    white-space: nowrap;
  }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr {
    transition: background 0.15s;
    cursor: pointer;
  }
  tbody tr:hover { background: var(--color-blue-soft); }
  .num { font-family: var(--font-mono); font-size: 13px; color: var(--color-ink-2); }
  .row-chevron { text-align: right; color: var(--color-muted-2); font-size: 18px; }

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
  .tag-prod { background: var(--color-red-light); color: var(--color-red); }

  .module-pill {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 10.5px;
    letter-spacing: 0.08em;
    padding: 3px 8px;
    border-radius: 5px;
    font-weight: 700;
    margin-right: 6px;
  }
  .module-pill-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .module-pill-red { background: var(--color-red-light); color: var(--color-red); }
  .row-target {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    color: var(--color-muted);
    font-weight: 600;
  }

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
  .score-pill-neutral .score-pill-ico { background: var(--color-muted-2); }

  .status-text {
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.06em;
  }
  .status-text-good { color: var(--color-green); }
  .status-text-warn { color: var(--color-red); }
  .status-text-neutral { color: var(--color-muted); }
  .status-text-mobile { color: var(--color-blue); }

  /* ===== production rows (EO/EE) ===== */
  .prod-row td { color: var(--color-ink-2); }
  .prod-row-label {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.05em;
    color: var(--color-red);
    font-weight: 600;
    margin-left: 2px;
  }
  .prod-row .score-pill-neutral {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: var(--color-blue);
  }

  /* ===== skeleton ===== */
  .skel-row td { padding: 16px; }
  .skel-cell {
    display: block;
    height: 14px;
    background: var(--color-paper-2);
    border-radius: 4px;
    animation: skel-pulse 1.4s ease-in-out infinite;
  }
  @keyframes skel-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }

  /* ===== footer ===== */
  .hi-footer {
    padding: 14px 20px;
    border-top: 1px solid var(--color-line-2);
    font-size: 13px;
    color: var(--color-muted);
    background: var(--color-paper);
  }

  /* ===== empty ===== */
  .hi-empty {
    padding: 60px 24px;
    text-align: center;
  }
  .hi-empty-icon {
    width: 52px; height: 52px;
    margin: 0 auto 16px;
    background: var(--color-blue-light);
    color: var(--color-blue);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
  }
  .hi-empty h3 {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: 19px;
    color: var(--color-ink);
    margin: 0 0 8px;
    letter-spacing: -0.01em;
  }
  .hi-empty p {
    color: var(--color-muted);
    font-size: 13.5px;
    line-height: 1.55;
    margin: 0 auto 18px;
    max-width: 380px;
  }
  .hi-empty-cta-wrap {
    display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;
  }

  /* ========== RESPONSIVE ========== */
  @media (max-width: 760px) {
    .filters { flex-direction: column; align-items: stretch; }
    .filter-tabs { width: 100%; justify-content: space-between; }
    .tab { flex: 1; justify-content: center; }
    .period-chips { width: 100%; }
    .chip { flex: 1; }
    .search-wrap { margin-left: 0; width: 100%; }
    .search-wrap input { width: 100%; }
  }
`;
