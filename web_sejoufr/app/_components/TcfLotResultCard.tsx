"use client";

import Link from "next/link";
import {useState} from "react";
import type {AttemptResponse} from "@/lib/types";
import {ExamReport} from "@/app/_components/ExamReport";

/**
 * Bilan d'un lot TCF — donut de score + résumé + conseil + CTAs, miroir de
 * `TcfLotResultScreen` mobile. Servi par la page session en fin de lot TCF
 * (query `result=tcfLot`). « Voir le rapport » déplie le détail question par
 * question (ExamReport) ; « Retour aux lots » renvoie au niveau.
 */
export function TcfLotResultCard({
  attempt,
  returnHref,
  level,
}: {
  attempt: AttemptResponse;
  returnHref: string;
  level?: string | null;
}) {
  const [showReport, setShowReport] = useState(false);
  const total = attempt.totalQuestions;
  const score = attempt.score ?? 0;
  const pct = total > 0 ? Math.round((score / total) * 100) : 0;
  const tier = pct >= 70 ? "good" : pct >= 40 ? "mid" : "low";
  const color =
    tier === "good" ? "var(--color-green)" : tier === "mid" ? "var(--color-amber)" : "var(--color-red)";

  const title = pct >= 70 ? "Bravo !" : pct >= 40 ? "Bien joué !" : "Continue !";
  const advice =
    pct >= 70
      ? "Excellent niveau sur ce lot. Enchaîne sur un lot plus difficile pour progresser."
      : pct >= 40
        ? "Bon début. Revois les questions ratées puis refais ce lot pour consolider."
        : "Ne lâche rien : relis les corrections, c'est là que la progression se joue.";

  const seconds = elapsedSeconds(attempt.startedAt, attempt.finishedAt);

  // Donut SVG
  const r = 52;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - pct / 100);

  return (
    <section className="tlr">
      <div className="tlr-card">
        <div className="tlr-eyebrow">SÉRIE TERMINÉE</div>
        <h1>{title}</h1>

        <div className="tlr-donut">
          <svg width="128" height="128" viewBox="0 0 128 128">
            <circle cx="64" cy="64" r={r} fill="none" stroke="var(--color-line-2)" strokeWidth="10" />
            <circle
              cx="64"
              cy="64"
              r={r}
              fill="none"
              stroke={color}
              strokeWidth="10"
              strokeLinecap="round"
              strokeDasharray={c}
              strokeDashoffset={offset}
              transform="rotate(-90 64 64)"
            />
          </svg>
          <div className="tlr-donut-label">
            <span className="tlr-score">
              {score}
              <span className="tlr-of">/{total}</span>
            </span>
            <span className="tlr-pct">{pct}%</span>
          </div>
        </div>

        <div className="tlr-summary">
          <Cell value={String(score)} label="Bonnes" />
          <Cell value={String(Math.max(0, total - score))} label="Erreurs" />
          <Cell value={formatTime(seconds)} label="Temps" />
          <Cell value={(level ?? "—").toUpperCase()} label="Niveau" />
        </div>

        <div className="tlr-advice" style={{borderLeftColor: color}}>
          <span className="tlr-advice-label">À TRAVAILLER</span>
          {advice}
        </div>

        <div className="tlr-cta">
          <button type="button" className="btn btn-ghost" onClick={() => setShowReport((v) => !v)}>
            {showReport ? "Masquer le rapport" : "Voir le rapport détaillé"}
          </button>
          <Link href={returnHref} className="btn btn-blue">
            Retour aux lots →
          </Link>
        </div>
      </div>

      {showReport && (
        <div className="tlr-report">
          <ExamReport attempt={attempt} />
        </div>
      )}

      <style>{`
        .tlr { padding: 40px 16px 72px; background: var(--color-paper); min-height: calc(100vh - 110px); }
        .tlr-card {
          max-width: 540px; margin: 0 auto;
          background: #fff; border: 1px solid var(--color-line);
          border-radius: 18px; padding: 36px 32px; text-align: center;
          box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
        }
        .tlr-eyebrow {
          font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.16em;
          color: var(--color-muted); font-weight: 700; margin-bottom: 8px;
        }
        .tlr-card h1 {
          font-family: var(--font-display); font-weight: 500;
          font-size: clamp(28px, 5vw, 34px); letter-spacing: -0.02em;
          color: var(--color-ink); margin: 0 0 20px;
        }
        .tlr-donut { position: relative; width: 128px; height: 128px; margin: 0 auto 24px; }
        .tlr-donut-label {
          position: absolute; inset: 0; display: flex; flex-direction: column;
          align-items: center; justify-content: center;
        }
        .tlr-score {
          font-family: var(--font-display); font-weight: 600; font-size: 28px;
          color: var(--color-ink); line-height: 1; font-variant-numeric: tabular-nums;
        }
        .tlr-of { font-size: 0.5em; color: var(--color-muted-2); }
        .tlr-pct { font-family: var(--font-mono); font-size: 12px; color: var(--color-muted); margin-top: 4px; }
        .tlr-summary {
          display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-bottom: 20px;
        }
        .tlr-cell {
          background: var(--color-paper); border: 1px solid var(--color-line);
          border-radius: 12px; padding: 12px 6px;
        }
        .tlr-cell-val {
          font-family: var(--font-display); font-weight: 600; font-size: 18px;
          color: var(--color-ink); line-height: 1; font-variant-numeric: tabular-nums;
        }
        .tlr-cell-label { font-size: 10.5px; color: var(--color-muted); margin-top: 5px; }
        .tlr-advice {
          background: var(--color-paper); border-radius: 12px; padding: 14px 16px;
          border-left: 3px solid var(--color-blue); text-align: left;
          font-size: 13px; color: var(--color-muted); line-height: 1.5; margin-bottom: 24px;
        }
        .tlr-advice-label {
          display: block; font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.12em; color: var(--color-ink); font-weight: 700; margin-bottom: 5px;
        }
        .tlr-cta { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; }
        .tlr-report { max-width: 720px; margin: 24px auto 0; }
        @media (max-width: 480px) {
          .tlr-card { padding: 28px 20px; }
          .tlr-summary { grid-template-columns: repeat(2, 1fr); }
        }
      `}</style>
    </section>
  );
}

function Cell({value, label}: {value: string; label: string}) {
  return (
    <div className="tlr-cell">
      <div className="tlr-cell-val">{value}</div>
      <div className="tlr-cell-label">{label}</div>
    </div>
  );
}

function elapsedSeconds(startedAt: string, finishedAt?: string | null): number {
  if (!finishedAt) return 0;
  const s = new Date(startedAt).getTime();
  const f = new Date(finishedAt).getTime();
  if (Number.isNaN(s) || Number.isNaN(f) || f < s) return 0;
  return Math.round((f - s) / 1000);
}

function formatTime(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}
