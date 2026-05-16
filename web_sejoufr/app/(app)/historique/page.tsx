"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { ApiException, attemptApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { AttemptSummaryResponse } from "@/lib/types";

export default function HistoriquePage() {
  const { user, status } = useAuth();
  const [data, setData] = useState<{
    loading: boolean;
    attempts: AttemptSummaryResponse[];
    error: string | null;
  }>({ loading: true, attempts: [], error: null });

  useEffect(() => {
    let cancelled = false;
    attemptApi
      .listMine({ type: "MOCK_EXAM", limit: 20 })
      .then((list) => {
        if (cancelled) return;
        setData({ loading: false, attempts: list, error: null });
      })
      .catch((e) => {
        if (cancelled) return;
        setData({
          loading: false,
          attempts: [],
          error:
            e instanceof ApiException
              ? e.message
              : "Impossible de charger l'historique.",
        });
      });
    return () => {
      cancelled = true;
    };
  }, []);

  // Tri par date desc (le backend renvoie sans doute déjà trié, on sécurise).
  const sorted = useMemo(
    () =>
      [...data.attempts].sort(
        (a, b) => Date.parse(b.startedAt) - Date.parse(a.startedAt),
      ),
    [data.attempts],
  );

  const finished = sorted.filter((a) => a.finishedAt && a.score !== null);
  const avgPct = useMemo(() => {
    if (finished.length < 2) return null;
    const ratios = finished.map((a) =>
      a.totalQuestions > 0 ? (a.score ?? 0) / a.totalQuestions : 0,
    );
    return Math.round((ratios.reduce((acc, r) => acc + r, 0) / ratios.length) * 100);
  }, [finished]);

  if (status === "loading") return <div className="hi-loading" />;
  if (!user) {
    return (
      <main className="hi-gate">
        <p>Connectez-vous pour voir votre historique.</p>
        <Link href="/connexion?next=/historique" className="btn btn-blue">
          Se connecter
        </Link>
      </main>
    );
  }

  return (
    <main className="hi">
      <section className="hi-head">
        <div className="hi-wrap">
          <span className="eyebrow">Historique</span>
          <h1>
            Vos <em>examens blancs</em> passés.
          </h1>
          <p>
            Retrouvez toutes vos sessions et la progression dans le temps. Cliquez
            sur une session pour revoir le résultat détaillé.
          </p>
        </div>
      </section>

      <section className="hi-body">
        <div className="hi-wrap">
          {data.loading && <ListLoading />}
          {data.error && !data.loading && <div className="form-error">{data.error}</div>}

          {!data.loading && !data.error && sorted.length === 0 && (
            <div className="hi-empty">
              <div className="hi-empty-icon" aria-hidden>
                <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="13" r="8" />
                  <path d="M12 9v4l3 2M9 3h6" />
                </svg>
              </div>
              <h2>Aucun examen blanc passé</h2>
              <p>
                Lancez votre premier examen pour mesurer votre niveau en
                conditions réelles. Le résultat apparaîtra ici.
              </p>
              <Link href="/examens-blancs" className="btn btn-blue">
                Choisir un examen blanc →
              </Link>
            </div>
          )}

          {!data.loading && finished.length >= 2 && (
            <div className="hi-summary">
              <div className="hi-summary-stat">
                <span className="hi-summary-pct" data-tone={avgPct! >= 70 ? "good" : "warn"}>
                  {avgPct}%
                </span>
                <span className="hi-summary-label">Taux moyen sur {finished.length} sessions</span>
              </div>
              <ProgressChart attempts={finished.slice(0, 6).reverse()} />
            </div>
          )}

          {sorted.length > 0 && (
            <div className="hi-list">
              {sorted.map((a) => (
                <AttemptRow key={a.id} attempt={a} />
              ))}
            </div>
          )}
        </div>
      </section>

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// PROGRESS CHART (custom SVG, 6 derniers attempts en barres)
// ============================================================================
function ProgressChart({ attempts }: { attempts: AttemptSummaryResponse[] }) {
  const W = 320;
  const H = 110;
  const PAD = { top: 14, right: 8, bottom: 22, left: 30 };
  const innerW = W - PAD.left - PAD.right;
  const innerH = H - PAD.top - PAD.bottom;
  const n = attempts.length;
  if (n === 0) return null;

  const barWidth = innerW / n - 6;

  return (
    <div className="hi-chart">
      <svg viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Évolution des derniers résultats">
        {/* Lignes horizontales 0/50/100% */}
        {[0, 0.5, 1].map((r) => {
          const y = PAD.top + innerH - r * innerH;
          return (
            <g key={r}>
              <line x1={PAD.left} y1={y} x2={PAD.left + innerW} y2={y} stroke="#EEF0F8" strokeWidth={1} />
              <text x={PAD.left - 6} y={y + 3} textAnchor="end" fontSize={8.5} fill="#9CA2BD" fontFamily="var(--font-mono)">
                {Math.round(r * 100)}
              </text>
            </g>
          );
        })}

        {attempts.map((a, i) => {
          const ratio = a.totalQuestions > 0 ? (a.score ?? 0) / a.totalQuestions : 0;
          const x = PAD.left + i * (innerW / n) + 3;
          const h = Math.max(2, ratio * innerH);
          const y = PAD.top + innerH - h;
          const thresholdRatio =
            a.passThreshold && a.totalQuestions > 0
              ? a.passThreshold / a.totalQuestions
              : null;
          const passed = thresholdRatio !== null && ratio >= thresholdRatio;
          const isLast = i === attempts.length - 1;
          const color = isLast
            ? "#1E3A8C"
            : passed
              ? "#168F5B"
              : "#E8A317";
          return (
            <g key={a.id}>
              <rect
                x={x}
                y={y}
                width={barWidth}
                height={h}
                rx={3}
                fill={color}
                opacity={isLast ? 1 : 0.75}
              />
              {thresholdRatio !== null && (
                <line
                  x1={x - 1}
                  y1={PAD.top + innerH - thresholdRatio * innerH}
                  x2={x + barWidth + 1}
                  y2={PAD.top + innerH - thresholdRatio * innerH}
                  stroke="#E1372F"
                  strokeWidth={1.2}
                  strokeDasharray="2 2"
                />
              )}
              <text
                x={x + barWidth / 2}
                y={H - 8}
                textAnchor="middle"
                fontSize={8.5}
                fill="#6B7299"
                fontFamily="var(--font-mono)"
              >
                {a.score ?? "—"}
              </text>
            </g>
          );
        })}
      </svg>
      <div className="hi-chart-legend">
        <span className="hi-chart-legend-item">
          <span className="hi-chart-dot" style={{ background: "#168F5B" }} /> Réussi
        </span>
        <span className="hi-chart-legend-item">
          <span className="hi-chart-dot" style={{ background: "#E8A317" }} /> Échoué
        </span>
        <span className="hi-chart-legend-item">
          <span className="hi-chart-dot" style={{ background: "#1E3A8C" }} /> Dernier
        </span>
        <span className="hi-chart-legend-item">
          <span className="hi-chart-dash" /> Seuil
        </span>
      </div>
    </div>
  );
}

// ============================================================================
// ATTEMPT ROW
// ============================================================================
function AttemptRow({ attempt }: { attempt: AttemptSummaryResponse }) {
  const isTcf = attempt.module === "TCF";
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const pct = total > 0 ? Math.round((score / total) * 100) : 0;
  const passed =
    attempt.passThreshold !== null &&
    attempt.passThreshold !== undefined &&
    score >= attempt.passThreshold;
  const isFinished = !!attempt.finishedAt;

  let badgeLabel: string;
  let badgeTone: "good" | "warn" | "neutral";
  if (!isFinished) {
    badgeLabel = "En cours";
    badgeTone = "neutral";
  } else if (isTcf) {
    badgeLabel = "Diagnostic TCF";
    badgeTone = "neutral";
  } else {
    badgeLabel = passed ? "Réussi" : "Non atteint";
    badgeTone = passed ? "good" : "warn";
  }

  const duration =
    attempt.finishedAt
      ? Math.max(
          1,
          Math.round(
            (Date.parse(attempt.finishedAt) - Date.parse(attempt.startedAt)) /
              60000,
          ),
        )
      : null;

  const targetTag = attempt.difficulty ? String(attempt.difficulty) : null;

  return (
    <Link href={`/sessions/${attempt.id}`} className="hi-row">
      <div className="hi-row-date">
        <span className="hi-row-day">{formatDay(attempt.startedAt)}</span>
        <span className="hi-row-month">{formatMonth(attempt.startedAt)}</span>
      </div>
      <div className="hi-row-body">
        <div className="hi-row-meta">
          <span className={`hi-tag ${isTcf ? "tcf" : "civique"}`}>
            {isTcf ? "TCF IRN" : "Civique"}
          </span>
          {targetTag && <span className="hi-tag-mono">{targetTag}</span>}
          <span className={`hi-badge ${badgeTone}`}>{badgeLabel}</span>
        </div>
        <div className="hi-row-stats">
          {isFinished ? (
            <>
              <strong>{score}</strong>/{total} bonnes réponses · {pct}%
              {duration !== null && <> · {duration} min</>}
              {!isTcf && attempt.passThreshold !== null && attempt.passThreshold !== undefined && (
                <> · seuil {attempt.passThreshold}</>
              )}
            </>
          ) : (
            <>Démarré il y a {timeAgo(attempt.startedAt)}</>
          )}
        </div>
      </div>
      <div className="hi-row-arrow">›</div>
    </Link>
  );
}

// ============================================================================
// HELPERS
// ============================================================================
const MONTHS = [
  "janv.", "févr.", "mars", "avr.", "mai", "juin",
  "juil.", "août", "sept.", "oct.", "nov.", "déc.",
];

function formatDay(iso: string): string {
  return new Date(iso).getDate().toString().padStart(2, "0");
}

function formatMonth(iso: string): string {
  return MONTHS[new Date(iso).getMonth()];
}

function timeAgo(iso: string): string {
  const diffMs = Date.now() - Date.parse(iso);
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return "moins d'une minute";
  if (diffMin < 60) return `${diffMin} min`;
  const diffH = Math.floor(diffMin / 60);
  if (diffH < 24) return `${diffH} h`;
  const diffD = Math.floor(diffH / 24);
  return `${diffD} j`;
}

// ============================================================================
// SUB
// ============================================================================
function ListLoading() {
  return (
    <div className="hi-list">
      {[0, 1, 2, 3].map((i) => (
        <div key={i} className="hi-row hi-row-skeleton" />
      ))}
    </div>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .hi { background: var(--color-paper); min-height: calc(100vh - 110px); }
  .hi-loading { min-height: 60vh; }
  .hi-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px; color: var(--color-muted);
  }
  .hi-wrap { max-width: 760px; margin: 0 auto; }

  .hi-head { padding: 40px 16px 24px; text-align: center; }
  .hi-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 40px); line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 12px;
  }
  .hi-head h1 em { font-style: italic; color: var(--color-red); }
  .hi-head p {
    color: var(--color-muted); font-size: 15px; line-height: 1.55;
    margin: 0 auto 22px; max-width: 540px;
  }

  .hi-body { padding: 8px 16px 80px; }

  .hi-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 16px;
    padding: 48px 32px;
    text-align: center;
    margin-top: 16px;
  }
  .hi-empty-icon {
    width: 56px; height: 56px;
    margin: 0 auto 14px;
    background: var(--color-blue-light); color: var(--color-blue);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
  }
  .hi-empty h2 {
    font-family: var(--font-display); font-weight: 500; font-size: 22px;
    color: var(--color-ink); margin: 0 0 8px;
    letter-spacing: -0.015em;
  }
  .hi-empty p {
    color: var(--color-muted); font-size: 13.5px; line-height: 1.55;
    margin: 0 auto 18px; max-width: 380px;
  }

  /* ----- SUMMARY ----- */
  .hi-summary {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px 24px;
    margin: 18px 0 28px;
    display: grid;
    grid-template-columns: minmax(140px, 200px) 1fr;
    gap: 24px;
    align-items: center;
  }
  @media (max-width: 640px) {
    .hi-summary { grid-template-columns: 1fr; }
  }
  .hi-summary-stat { display: flex; flex-direction: column; gap: 4px; }
  .hi-summary-pct {
    font-family: var(--font-display); font-weight: 500;
    font-size: 48px; line-height: 1; letter-spacing: -0.04em;
  }
  .hi-summary-pct[data-tone="good"] { color: var(--color-green); }
  .hi-summary-pct[data-tone="warn"] { color: var(--color-amber); }
  .hi-summary-label {
    font-family: var(--font-mono); font-size: 10.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
  }

  .hi-chart {
    display: flex; flex-direction: column; gap: 10px;
  }
  .hi-chart svg { width: 100%; height: auto; max-width: 360px; display: block; }
  .hi-chart-legend {
    display: flex; flex-wrap: wrap; gap: 10px;
    font-family: var(--font-mono); font-size: 10px;
    color: var(--color-muted); letter-spacing: 0.08em;
  }
  .hi-chart-legend-item {
    display: inline-flex; align-items: center; gap: 5px;
  }
  .hi-chart-dot { width: 8px; height: 8px; border-radius: 2px; display: inline-block; }
  .hi-chart-dash {
    display: inline-block; width: 12px; height: 1.5px;
    background: repeating-linear-gradient(
      to right, var(--color-red), var(--color-red) 2px, transparent 2px, transparent 4px
    );
  }

  /* ----- LIST ----- */
  .hi-list { display: flex; flex-direction: column; gap: 8px; }
  .hi-row {
    display: grid;
    grid-template-columns: 44px 1fr 24px;
    align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 14px 16px;
    text-decoration: none;
    color: inherit;
    transition: all 0.15s;
  }
  .hi-row:hover {
    border-color: var(--color-blue);
    box-shadow: 0 8px 20px -10px rgba(30, 58, 140, 0.18);
  }
  .hi-row-skeleton {
    height: 76px;
    animation: hi-pulse 1.4s ease-in-out infinite;
  }
  @keyframes hi-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }
  .hi-row-date {
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    background: var(--color-paper);
    border-radius: 10px;
    padding: 6px 8px;
    text-align: center;
  }
  .hi-row-day {
    font-family: var(--font-display); font-weight: 500;
    font-size: 18px; line-height: 1; color: var(--color-ink);
  }
  .hi-row-month {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.1em; text-transform: uppercase;
    color: var(--color-muted); margin-top: 2px;
  }
  .hi-row-body { min-width: 0; }
  .hi-row-meta {
    display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
    margin-bottom: 6px;
  }
  .hi-row-stats {
    font-size: 12.5px; color: var(--color-muted); line-height: 1.4;
  }
  .hi-row-stats strong {
    color: var(--color-ink); font-weight: 700; font-family: var(--font-mono);
  }
  .hi-row-arrow {
    color: var(--color-muted-2); font-size: 20px;
    flex-shrink: 0;
  }

  .hi-tag {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 7px; border-radius: 4px;
    font-weight: 700;
  }
  .hi-tag.civique { background: var(--color-blue-light); color: var(--color-blue); }
  .hi-tag.tcf { background: var(--color-red-light); color: var(--color-red); }
  .hi-tag-mono {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 7px; border-radius: 4px;
    font-weight: 700;
    background: var(--color-paper-2); color: var(--color-muted);
  }
  .hi-badge {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 8px; border-radius: 100px;
    font-weight: 700;
  }
  .hi-badge.good {
    background: rgba(22, 143, 91, 0.12); color: var(--color-green);
  }
  .hi-badge.warn {
    background: var(--color-red-light); color: var(--color-red);
  }
  .hi-badge.neutral {
    background: var(--color-paper-2); color: var(--color-muted);
  }
`;
