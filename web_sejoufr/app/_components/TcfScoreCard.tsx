"use client";

import type {AttemptResponse, TargetLevel} from "@/lib/types";

/**
 * Petite carte de synthèse TCF affichée en tête du détail d'un examen/lot TCF
 * consulté : points obtenus + niveau CECRL atteint (A2/B1/B2, ou « < A2 »).
 * Le niveau vient de `levelAchieved` (examen module) ou, à défaut, du niveau
 * des questions (lot d'un niveau donné).
 */
export function TcfScoreCard({attempt}: {attempt: AttemptResponse}) {
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const level = resolveLevel(attempt);
  const tone = level === "A2" ? "green" : level === "B1" ? "amber" : level === "B2" ? "red" : "muted";

  return (
    <section className="tsc">
      <div className="tsc-card">
        <div className="tsc-cell">
          <span className="tsc-eyebrow">Points obtenus</span>
          <span className="tsc-points">
            {score}
            <span className="tsc-of"> / {total}</span>
          </span>
        </div>
        <div className="tsc-sep" aria-hidden />
        <div className="tsc-cell tsc-cell-right">
          <span className="tsc-eyebrow">Niveau atteint</span>
          <span className={`tsc-level tsc-${tone}`}>{level ?? "< A2"}</span>
        </div>
      </div>

      <style>{`
        .tsc { padding: 24px 16px 0; }
        .tsc-card {
          max-width: 760px; margin: 0 auto;
          display: flex; align-items: stretch;
          background: #fff; border: 1px solid var(--color-line);
          border-radius: 16px; padding: 18px 22px;
          box-shadow: 0 16px 40px -28px rgba(15, 24, 57, 0.25);
        }
        .tsc-cell { flex: 1; display: flex; flex-direction: column; gap: 6px; }
        .tsc-cell-right { align-items: flex-end; }
        .tsc-eyebrow {
          font-family: var(--font-mono); font-size: 9.5px; letter-spacing: 0.14em;
          text-transform: uppercase; color: var(--color-muted); font-weight: 700;
        }
        .tsc-points {
          font-family: var(--font-display); font-weight: 600; font-size: 30px;
          line-height: 1; letter-spacing: -0.02em; color: var(--color-ink);
          font-variant-numeric: tabular-nums;
        }
        .tsc-of { font-size: 0.5em; color: var(--color-muted-2); }
        .tsc-sep { width: 1px; background: var(--color-line-2); margin: 0 22px; }
        .tsc-level {
          font-family: var(--font-display); font-weight: 600; font-size: 30px;
          line-height: 1; letter-spacing: -0.01em;
        }
        .tsc-green { color: var(--color-green); }
        .tsc-amber { color: var(--color-amber); }
        .tsc-red { color: var(--color-red); }
        .tsc-muted { color: var(--color-muted); }
        @media (max-width: 480px) {
          .tsc-points, .tsc-level { font-size: 24px; }
          .tsc-sep { margin: 0 14px; }
        }
      `}</style>
    </section>
  );
}

function resolveLevel(attempt: AttemptResponse): TargetLevel | null {
  if (attempt.levelAchieved) return attempt.levelAchieved;
  const d = attempt.questions[0]?.question.difficulty;
  return d === "A2" || d === "B1" || d === "B2" ? d : null;
}
