"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import {
  ArrowRight,
  BarChart3,
  Check,
  ChevronDown,
  Minus,
  RotateCw,
  Target,
  Trophy,
  X,
} from "lucide-react";
import { MediaView } from "./MediaView";
import { niveauCecrlLabel, orderedChoices } from "@/lib/types";
import type {
  AttemptQuestionResponse,
  AttemptResponse,
} from "@/lib/types";

type Filter = "all" | "wrong" | "right" | "skipped";

/** Icône + libellé des épreuves d'un examen TCF multi-épreuves. */
const EPREUVE_META: Record<string, { icon: string; label: string }> = {
  CO: { icon: "🎧", label: "Compréhension orale" },
  CE: { icon: "📖", label: "Compréhension écrite" },
  STRUCTURE: { icon: "🧩", label: "Structures de la langue" },
};

/**
 * Rapport d'un examen blanc / d'une série finalisée (maquette
 * sejour_fr.html) : hero teinté (donut bonnes réponses, % obtenu, temps,
 * niveau estimé TCF ou seuil civique), « Réussite par sous-thème »
 * (uniquement quand l'attempt couvre ≥ 2 thèmes — examens complets),
 * « Et maintenant ? » (point à renforcer + CTAs posés par le parent), puis
 * « Corrigé détaillé » en accordéon filtrable.
 *
 * `embedded` (bilan série TCF) : rend uniquement le corrigé détaillé.
 */
export function ExamReport({
  attempt,
  embedded = false,
  contextLabel,
  onRetry,
  retryLabel = "Refaire cet examen",
  retrying = false,
  moreHref,
  moreLabel = "Autres examens blancs",
  progressHref,
}: {
  attempt: AttemptResponse;
  embedded?: boolean;
  /** Sous-titre du hero, ex. "Compréhension orale · Examen blanc". */
  contextLabel?: string;
  onRetry?: () => void;
  retryLabel?: string;
  retrying?: boolean;
  moreHref?: string;
  moreLabel?: string;
  /** Lien "Voir ma progression" (omis pour les guests). */
  progressHref?: string;
}) {
  const [filter, setFilter] = useState<Filter>("all");
  const [openIds, setOpenIds] = useState<Set<string>>(new Set());
  /** Détail par épreuve (examens TCF CO→CE) — niveau global = plancher. */
  const epreuves = attempt.epreuveResults ?? [];

  const sorted = useMemo(
    () => [...attempt.questions].sort((a, b) => a.position - b.position),
    [attempt.questions],
  );

  const counts = useMemo(() => {
    let right = 0;
    let wrong = 0;
    let skipped = 0;
    for (const aq of sorted) {
      if (!aq.answered) skipped++;
      else if (aq.correct) right++;
      else wrong++;
    }
    return { all: sorted.length, right, wrong, skipped };
  }, [sorted]);

  // Réussite par thème — exposée seulement quand l'attempt couvre plusieurs
  // thèmes (examen complet). Les examens scopés à un thème / une épreuve
  // n'affichent pas la section. Trié du plus fragile au plus solide.
  const byTheme = useMemo(() => {
    const map = new Map<string, { right: number; total: number }>();
    for (const aq of sorted) {
      const name = aq.question.themeName ?? "Autre";
      const entry = map.get(name) ?? { right: 0, total: 0 };
      entry.total++;
      if (aq.answered && aq.correct) entry.right++;
      map.set(name, entry);
    }
    if (map.size < 2) return [];
    return [...map.entries()]
      .map(([name, v]) => ({ name, ...v }))
      .sort((a, b) => a.right / a.total - b.right / b.total);
  }, [sorted]);

  const filtered = useMemo(() => {
    if (filter === "all") return sorted;
    return sorted.filter((aq) => {
      if (filter === "wrong") return aq.answered && aq.correct === false;
      if (filter === "right") return aq.answered && aq.correct === true;
      return !aq.answered;
    });
  }, [sorted, filter]);

  function toggle(id: string) {
    setOpenIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  const total = counts.all;
  const pct = total > 0 ? Math.round((counts.right / total) * 100) : 0;
  const passed =
    attempt.passThreshold != null
      ? counts.right >= attempt.passThreshold
      : pct >= 50;
  const seconds = elapsedSeconds(attempt.startedAt, attempt.finishedAt);
  const weakest = byTheme[0] ?? null;

  const corrige = (
    <section className="rpt-card rpt-corrige">
      <h2 className="rpt-card-title">Corrigé détaillé</h2>
      <p className="rpt-card-sub">
        Le détail de chaque question lors de votre dernier essai.
      </p>

      <div className="rpt-filters">
        <FilterChip active={filter === "all"} onClick={() => setFilter("all")}>
          Toutes · {counts.all}
        </FilterChip>
        <FilterChip
          active={filter === "wrong"}
          onClick={() => setFilter("wrong")}
          disabled={counts.wrong === 0}
        >
          Ratées · {counts.wrong}
        </FilterChip>
        <FilterChip
          active={filter === "right"}
          onClick={() => setFilter("right")}
          disabled={counts.right === 0}
        >
          Réussies · {counts.right}
        </FilterChip>
        {counts.skipped > 0 && (
          <FilterChip
            active={filter === "skipped"}
            onClick={() => setFilter("skipped")}
          >
            Non répondues · {counts.skipped}
          </FilterChip>
        )}
      </div>

      {filtered.length === 0 ? (
        <div className="rpt-empty">Aucune question dans cette catégorie.</div>
      ) : (
        <ol className="rpt-list">
          {filtered.map((aq) => (
            <ReportRow
              key={aq.id}
              aq={aq}
              showTheme={byTheme.length > 0}
              open={openIds.has(aq.id)}
              onToggle={() => toggle(aq.id)}
            />
          ))}
        </ol>
      )}
    </section>
  );

  if (embedded) {
    return (
      <section className="rpt">
        <div className="rpt-wrap">{corrige}</div>
        <style>{styles}</style>
      </section>
    );
  }

  return (
    <section className="rpt">
      <div className="rpt-wrap">
        {/* ===== hero ===== */}
        <header className={`rpt-hero ${passed ? "rpt-hero-pass" : "rpt-hero-fail"}`}>
          <HeroDonut right={counts.right} total={total} passed={passed} />
          <div className="rpt-hero-body">
            <span className="rpt-hero-pill">
              <Trophy size={13} aria-hidden /> Rapport du dernier score
            </span>
            <h1>Vous avez obtenu {pct}%</h1>
            {contextLabel && <p className="rpt-hero-context">{contextLabel}</p>}
            <dl className="rpt-hero-stats">
              {/* Examens TCF stratifiés : score calibré 100-499 (échelle TCF),
                  le brut vit dans le donut. Sinon, score brut classique. */}
              {attempt.calibratedScore != null ? (
                <div>
                  <dt>Score TCF</dt>
                  <dd>{attempt.calibratedScore}/499</dd>
                </div>
              ) : (
                <div>
                  <dt>Score</dt>
                  <dd>
                    {counts.right}/{total}
                  </dd>
                </div>
              )}
              <div>
                <dt>Temps</dt>
                <dd>{formatDuration(seconds)}</dd>
              </div>
              {attempt.cecrlLevel ? (
                <div>
                  <dt>{epreuves.length >= 2 ? "Niveau global" : "Niveau estimé"}</dt>
                  <dd className="rpt-hero-level">
                    {niveauCecrlLabel(attempt.cecrlLevel)}
                  </dd>
                </div>
              ) : attempt.passThreshold != null ? (
                <div>
                  <dt>Seuil</dt>
                  <dd>
                    {attempt.passThreshold}/{total}
                  </dd>
                </div>
              ) : null}
            </dl>
          </div>
        </header>

        {/* ===== niveau par épreuve (examens TCF multi-épreuves) ===== */}
        {epreuves.length >= 2 && (
          <section className="rpt-card rpt-epreuves">
            <h2 className="rpt-card-title">Votre niveau par épreuve</h2>
            <ul className="rpt-epv-list">
              {epreuves.map((e) => {
                const meta = EPREUVE_META[e.epreuve] ?? { icon: "📋", label: e.epreuve };
                const isFloor =
                  attempt.cecrlLevel != null && e.cecrlLevel === attempt.cecrlLevel;
                return (
                  <li key={e.epreuve} className="rpt-epv">
                    <span className="rpt-epv-ico" aria-hidden>
                      {meta.icon}
                    </span>
                    <span className="rpt-epv-name">{meta.label}</span>
                    <span className="rpt-epv-meta">
                      {e.correct}/{e.total} bonnes réponses · {e.calibratedScore}/499
                    </span>
                    <span className={`rpt-epv-level ${isFloor ? "is-floor" : ""}`}>
                      {niveauCecrlLabel(e.cecrlLevel)}
                    </span>
                  </li>
                );
              })}
            </ul>
            <p className="rpt-epv-note">
              Comme au TCF IRN, votre niveau global correspond à votre épreuve
              la <strong>plus faible</strong> — il faut atteindre le niveau
              dans chaque épreuve pour le valider (l&apos;expression écrite et
              orale comptent aussi le jour J). Faites monter votre point
              faible pour faire monter l&apos;ensemble.
            </p>
          </section>
        )}

        {/* ===== sous-thèmes + et maintenant ===== */}
        <div className={`rpt-grid ${byTheme.length === 0 ? "rpt-grid-solo" : ""}`}>
          {byTheme.length > 0 && (
            <section className="rpt-card">
              <h2 className="rpt-card-title">Réussite par sous-thème</h2>
              <ul className="rpt-themes">
                {byTheme.map((t) => (
                  <li key={t.name} className="rpt-theme">
                    <div className="rpt-theme-top">
                      <span className="rpt-theme-name">{t.name}</span>
                      <span className="rpt-theme-score">
                        {t.right}/{t.total}
                      </span>
                    </div>
                    <div className="rpt-theme-track">
                      <span
                        className={`rpt-theme-fill ${fillTone(t.right, t.total)}`}
                        style={{ width: `${Math.round((t.right / t.total) * 100)}%` }}
                      />
                    </div>
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="rpt-card">
            <h2 className="rpt-card-title">Et maintenant ?</h2>
            <div className="rpt-advice">
              <span className="rpt-advice-head">
                <Target size={14} aria-hidden /> Point à renforcer
              </span>
              <p>
                {weakest && weakest.right < weakest.total ? (
                  <>
                    Concentrez-vous sur <strong>{weakest.name}</strong> (
                    {weakest.right}/{weakest.total}). Un entraînement ciblé
                    devrait vite faire monter votre score.
                  </>
                ) : counts.wrong + counts.skipped > 0 ? (
                  <>
                    Revoyez les{" "}
                    <strong>
                      {counts.wrong + counts.skipped} question
                      {counts.wrong + counts.skipped > 1 ? "s" : ""}
                    </strong>{" "}
                    à retravailler dans le corrigé ci-dessous, puis retentez
                    votre chance.
                  </>
                ) : (
                  <>Sans faute — enchaînez sur l&apos;examen suivant pour confirmer.</>
                )}
              </p>
            </div>

            {onRetry && (
              <button
                type="button"
                className="rpt-cta rpt-cta-primary"
                onClick={onRetry}
                disabled={retrying}
              >
                <RotateCw size={16} aria-hidden />
                {retrying ? "Préparation…" : retryLabel}
              </button>
            )}
            {moreHref && (
              <Link href={moreHref} className="rpt-cta rpt-cta-outline">
                {moreLabel} <ArrowRight size={15} aria-hidden />
              </Link>
            )}
            {progressHref && (
              <Link href={progressHref} className="rpt-progress-link">
                <BarChart3 size={15} aria-hidden /> Voir ma progression
              </Link>
            )}
          </section>
        </div>

        {corrige}
      </div>
      <style>{styles}</style>
    </section>
  );
}

function fillTone(right: number, total: number): string {
  const r = total > 0 ? right / total : 0;
  if (r >= 0.8) return "rpt-fill-green";
  if (r < 0.6) return "rpt-fill-amber";
  return "rpt-fill-blue";
}

function HeroDonut({
  right,
  total,
  passed,
}: {
  right: number;
  total: number;
  passed: boolean;
}) {
  const r = 56;
  const c = 2 * Math.PI * r;
  const ratio = total > 0 ? right / total : 0;
  return (
    <div className="rpt-donut" role="presentation">
      <svg width="132" height="132" viewBox="0 0 132 132">
        <circle cx="66" cy="66" r={r} fill="none" stroke="rgba(255,255,255,0.55)" strokeWidth="11" />
        <circle
          cx="66"
          cy="66"
          r={r}
          fill="none"
          stroke={passed ? "var(--color-green)" : "var(--color-red)"}
          strokeWidth="11"
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - ratio)}
          transform="rotate(-90 66 66)"
        />
      </svg>
      <div className="rpt-donut-center">
        <span className="rpt-donut-score">
          {right}/{total}
        </span>
        <span className="rpt-donut-label">bonnes réponses</span>
      </div>
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

function formatDuration(sec: number): string {
  if (sec <= 0) return "—";
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return m > 0 ? `${m} min ${String(s).padStart(2, "0")}` : `${s} s`;
}

// ============================================================================
// REPORT ROW
// ============================================================================
function ReportRow({
  aq,
  showTheme,
  open,
  onToggle,
}: {
  aq: AttemptQuestionResponse;
  showTheme: boolean;
  open: boolean;
  onToggle: () => void;
}) {
  const q = aq.question;
  const state: "right" | "wrong" | "skipped" = !aq.answered
    ? "skipped"
    : aq.correct
      ? "right"
      : "wrong";

  return (
    <li className="rpt-row">
      <button type="button" className="rpt-row-head" onClick={onToggle} aria-expanded={open}>
        <span className={`rpt-row-state rpt-row-state-${state}`} aria-hidden>
          {state === "right" ? (
            <Check size={13} strokeWidth={3} />
          ) : state === "wrong" ? (
            <X size={13} strokeWidth={3} />
          ) : (
            <Minus size={13} strokeWidth={3} />
          )}
        </span>
        <span className={`rpt-row-statement ${open ? "is-open" : ""}`}>
          {aq.position + 1}. {q.statement}
        </span>
        {showTheme && q.themeName && (
          <span className="rpt-row-theme">{q.themeName}</span>
        )}
        <ChevronDown
          size={16}
          className={`rpt-row-chevron ${open ? "is-open" : ""}`}
          aria-hidden
        />
      </button>

      {open && (
        <div className="rpt-row-content">
          {q.passageText && (
            <div className="rpt-passage">
              <div className="rpt-passage-label">Document</div>
              <div className="rpt-passage-body">{q.passageText}</div>
            </div>
          )}

          {/* Médias de la question (audio CO, image CO_IMAGE…) — lecteur
              libre dans le corrigé : on peut réécouter autant qu'on veut. */}
          {q.media && <MediaView key={q.id} media={q.media} />}
          {q.audioMedia && (
            <MediaView key={`${q.id}-audio`} media={q.audioMedia} />
          )}

          <div className="rpt-choices">
            {orderedChoices(q.choices).map((c, i) => {
              // FULL_AUDIO : label réduit à une lettre (clé citée par
              // l'explication) → on l'affiche dans la pastille, on masque le
              // texte redondant ; les choix sont déjà triés A→D.
              const letterOnly = /^(?:r[ée]ponse\s+)?([A-D])$/i.exec(c.label.trim());
              const letter = letterOnly
                ? letterOnly[1].toUpperCase()
                : String.fromCharCode(65 + i);
              const wasSelected = aq.selectedChoiceIds.includes(c.id);
              const isCorrect = c.correct === true;
              const isWrongPick = wasSelected && !isCorrect;
              const cls = [
                "rpt-choice",
                isCorrect ? "is-correct" : "",
                isWrongPick ? "is-wrong" : "",
              ]
                .filter(Boolean)
                .join(" ");
              return (
                <div key={c.id} className={cls}>
                  <span className="rpt-letter">{letter}</span>
                  <span className="rpt-choice-label">{letterOnly ? "" : c.label}</span>
                  {isCorrect && (
                    <span className="rpt-icon-good" aria-label="Bonne réponse">
                      ✓
                    </span>
                  )}
                  {isWrongPick && (
                    <span className="rpt-pick-label">Votre réponse</span>
                  )}
                </div>
              );
            })}
          </div>

          {q.explanation && (
            <div className="rpt-explain">
              <div className="rpt-explain-head">
                <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 18h6M10 22h4M12 2a7 7 0 0 0-4 13l1 2h6l1-2a7 7 0 0 0-4-13z" />
                </svg>
                <span>Explication</span>
              </div>
              <p>{q.explanation}</p>
            </div>
          )}
        </div>
      )}
    </li>
  );
}

function FilterChip({
  active,
  onClick,
  disabled,
  children,
}: {
  active: boolean;
  onClick: () => void;
  disabled?: boolean;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      className={`rpt-chip ${active ? "is-active" : ""}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .rpt { padding: 24px 18px 64px; }
  .rpt-wrap { max-width: 880px; margin: 0 auto; }

  /* ===== hero ===== */
  .rpt-hero {
    display: flex; align-items: center; gap: 26px;
    border-radius: 20px;
    padding: 28px 30px;
    margin-bottom: 18px;
  }
  .rpt-hero-pass { background: color-mix(in srgb, var(--color-green) 13%, #fff); }
  .rpt-hero-fail { background: var(--color-red-light); }

  .rpt-donut { position: relative; width: 132px; height: 132px; flex-shrink: 0; }
  .rpt-donut-center {
    position: absolute; inset: 0;
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    text-align: center;
  }
  .rpt-donut-score {
    font-family: var(--font-sans);
    font-size: 26px; font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.1;
  }
  .rpt-donut-label { font-size: 10.5px; color: var(--color-muted); }

  .rpt-hero-body { min-width: 0; }
  .rpt-hero-pill {
    display: inline-flex; align-items: center; gap: 6px;
    background: rgba(255, 255, 255, 0.75);
    color: var(--color-ink-2);
    font-size: 12px; font-weight: 600;
    padding: 5px 12px; border-radius: 999px;
    margin-bottom: 10px;
  }
  .rpt-hero h1 {
    margin: 0 0 4px;
    font-family: var(--font-sans);
    font-size: clamp(24px, 4vw, 32px);
    font-weight: 800; letter-spacing: -0.02em;
    color: var(--color-ink); line-height: 1.15;
  }
  .rpt-hero-context { margin: 0 0 14px; font-size: 14.5px; color: var(--color-muted); }
  .rpt-hero-stats {
    display: flex; flex-wrap: wrap; gap: 28px;
    margin: 0;
  }
  .rpt-hero-stats dt {
    font-size: 12px; color: var(--color-muted); margin-bottom: 2px;
  }
  .rpt-hero-stats dd {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 18px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .rpt-hero-level { color: var(--color-blue) !important; }

  /* ===== grid sous-thèmes / et maintenant ===== */
  .rpt-epreuves { margin-bottom: 18px; }
  .rpt-epv-list {
    list-style: none; padding: 0; margin: 0 0 12px;
    display: flex; flex-direction: column; gap: 8px;
  }
  .rpt-epv {
    display: flex; align-items: center; gap: 12px;
    background: var(--color-paper);
    border: 1px solid var(--color-line-2);
    border-radius: 12px;
    padding: 12px 14px;
  }
  .rpt-epv-ico { font-size: 18px; line-height: 1; flex-shrink: 0; }
  .rpt-epv-name {
    font-weight: 700; font-size: 14px; color: var(--color-ink);
    flex-shrink: 0;
  }
  .rpt-epv-meta {
    flex: 1; min-width: 0; text-align: right;
    font-family: var(--font-mono); font-size: 11.5px;
    color: var(--color-muted); letter-spacing: 0.02em;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  .rpt-epv-level {
    flex-shrink: 0;
    font-family: var(--font-mono); font-size: 11px; font-weight: 700;
    letter-spacing: 0.08em;
    background: var(--color-blue-light); color: var(--color-blue);
    padding: 4px 10px; border-radius: 100px;
  }
  .rpt-epv-level.is-floor {
    background: var(--color-red-light); color: var(--color-red);
  }
  .rpt-epv-note {
    margin: 0;
    font-size: 13px; line-height: 1.55; color: var(--color-muted);
    background: var(--color-blue-soft);
    border-left: 3px solid var(--color-blue);
    border-radius: 10px;
    padding: 10px 14px;
  }
  .rpt-epv-note strong { color: var(--color-ink); }
  @media (max-width: 640px) {
    .rpt-epv { flex-wrap: wrap; }
    .rpt-epv-meta { flex-basis: 100%; order: 4; text-align: left; }
  }

  .rpt-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 18px;
    margin-bottom: 18px;
  }
  .rpt-grid-solo { grid-template-columns: 1fr; }

  .rpt-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 22px;
    min-width: 0;
  }
  .rpt-card-title {
    margin: 0 0 6px;
    font-family: var(--font-sans);
    font-size: 17px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .rpt-card-sub { margin: 0 0 16px; font-size: 13.5px; color: var(--color-muted); }

  .rpt-themes {
    list-style: none; margin: 10px 0 0; padding: 0;
    display: flex; flex-direction: column; gap: 14px;
  }
  .rpt-theme-top {
    display: flex; align-items: center; justify-content: space-between; gap: 10px;
    margin-bottom: 6px;
  }
  .rpt-theme-name {
    font-size: 13.5px; color: var(--color-ink-2);
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .rpt-theme-score {
    font-family: var(--font-mono); font-size: 12px; font-weight: 600;
    color: var(--color-ink-2); flex-shrink: 0;
  }
  .rpt-theme-track {
    height: 8px; border-radius: 999px;
    background: var(--color-line-2); overflow: hidden;
  }
  .rpt-theme-fill { display: block; height: 100%; border-radius: 999px; }
  .rpt-fill-green { background: var(--color-green); }
  .rpt-fill-blue { background: var(--color-blue); }
  .rpt-fill-amber { background: var(--color-amber); }

  .rpt-advice {
    background: color-mix(in srgb, var(--color-amber) 12%, #fff);
    border: 1px solid color-mix(in srgb, var(--color-amber) 35%, transparent);
    border-radius: 12px;
    padding: 14px 16px;
    margin: 10px 0 16px;
  }
  .rpt-advice-head {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: 13px; font-weight: 700;
    color: color-mix(in srgb, var(--color-amber) 70%, var(--color-ink));
    margin-bottom: 6px;
  }
  .rpt-advice p { margin: 0; font-size: 13.5px; line-height: 1.55; color: var(--color-ink-2); }

  .rpt-cta {
    display: flex; align-items: center; justify-content: center; gap: 8px;
    width: 100%;
    padding: 12px 18px;
    border-radius: 999px;
    font-family: var(--font-sans);
    font-size: 14.5px; font-weight: 700;
    cursor: pointer;
    text-decoration: none;
    margin-bottom: 10px;
    transition: background 0.15s, border-color 0.15s, color 0.15s;
  }
  .rpt-cta:disabled { opacity: 0.6; cursor: progress; }
  .rpt-cta-primary {
    background: var(--color-blue); color: #fff; border: none;
  }
  .rpt-cta-primary:hover { background: var(--color-blue-dark); }
  .rpt-cta-outline {
    background: #fff; color: var(--color-ink);
    border: 1px solid var(--color-line);
  }
  .rpt-cta-outline:hover { border-color: var(--color-muted-2); }
  .rpt-progress-link {
    display: flex; align-items: center; justify-content: center; gap: 7px;
    font-size: 13.5px; font-weight: 600;
    color: var(--color-muted);
    text-decoration: none;
    padding: 6px;
  }
  .rpt-progress-link:hover { color: var(--color-blue); }

  /* ===== corrigé ===== */
  .rpt-filters {
    display: flex; flex-wrap: wrap; gap: 8px;
    margin: 0 0 16px;
  }
  .rpt-chip {
    padding: 7px 13px;
    background: var(--color-blue-soft);
    border: 1px solid var(--color-line);
    border-radius: 999px;
    font-family: var(--font-sans);
    font-size: 12.5px; font-weight: 600;
    color: var(--color-ink-2);
    cursor: pointer;
    transition: all 0.15s;
  }
  .rpt-chip:hover:not(:disabled) { border-color: var(--color-blue); color: var(--color-blue); }
  .rpt-chip:disabled { opacity: 0.4; cursor: not-allowed; }
  .rpt-chip.is-active {
    background: var(--color-blue);
    color: #fff;
    border-color: var(--color-blue);
  }

  .rpt-empty {
    border: 1px dashed var(--color-line);
    border-radius: 12px;
    padding: 32px 16px;
    text-align: center;
    color: var(--color-muted);
    font-size: 13.5px;
  }
  .rpt-list {
    list-style: none; padding: 0; margin: 0;
    display: flex; flex-direction: column; gap: 10px;
  }

  .rpt-row {
    border: 1px solid var(--color-line);
    border-radius: 13px;
    overflow: hidden;
    background: #fff;
  }
  .rpt-row-head {
    display: flex; align-items: center; gap: 12px;
    width: 100%;
    background: none; border: none;
    padding: 14px 16px;
    cursor: pointer;
    text-align: left;
    font-family: var(--font-sans);
    min-width: 0;
  }
  .rpt-row-head:hover { background: var(--color-blue-soft); }
  .rpt-row-state {
    width: 24px; height: 24px; border-radius: 50%;
    display: grid; place-items: center;
    flex-shrink: 0;
    color: #fff;
  }
  .rpt-row-state-right { background: var(--color-green); }
  .rpt-row-state-wrong { background: var(--color-red); }
  .rpt-row-state-skipped { background: var(--color-muted-2); }
  .rpt-row-statement {
    flex: 1; min-width: 0;
    display: -webkit-box;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
    overflow: hidden; text-overflow: ellipsis;
    font-size: 14px; line-height: 1.4;
    color: var(--color-ink-2);
  }
  .rpt-row-statement.is-open {
    -webkit-line-clamp: unset;
    color: var(--color-ink); font-weight: 600;
  }
  .rpt-row-theme {
    font-size: 11.5px; font-weight: 600;
    color: var(--color-muted);
    background: var(--color-line-2);
    padding: 4px 10px; border-radius: 999px;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    max-width: 170px;
    flex-shrink: 0;
  }
  .rpt-row-chevron {
    color: var(--color-muted-2);
    flex-shrink: 0;
    transition: transform 0.18s;
  }
  .rpt-row-chevron.is-open { transform: rotate(180deg); }

  /* Contenu déplié */
  .rpt-row-content {
    padding: 16px 16px 16px 52px;
    border-top: 1px solid var(--color-line-2);
  }
  @media (max-width: 560px) {
    .rpt-row-content { padding-left: 16px; }
  }

  .rpt-passage {
    background: var(--color-blue-soft);
    border-radius: 10px;
    padding: 10px 12px;
    margin: 0 0 14px;
  }
  .rpt-passage-label {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 6px;
  }
  .rpt-passage-body {
    font-size: 13px; line-height: 1.55;
    color: var(--color-ink-2);
    white-space: pre-wrap;
  }

  .rpt-choices { display: flex; flex-direction: column; gap: 6px; margin-bottom: 14px; }
  .rpt-choice {
    display: flex; align-items: center; gap: 10px;
    padding: 10px 12px;
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 10px;
    font-size: 13.5px; color: var(--color-ink-2);
  }
  .rpt-choice.is-correct {
    border-color: var(--color-green);
    background: rgba(22, 143, 91, 0.06);
  }
  .rpt-choice.is-wrong {
    border-color: var(--color-red);
    background: rgba(225, 55, 47, 0.05);
  }
  .rpt-letter {
    width: 24px; height: 24px;
    border-radius: 50%;
    background: var(--color-line-2);
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 11px; font-weight: 700;
    flex-shrink: 0;
  }
  .rpt-choice.is-correct .rpt-letter {
    background: rgba(22, 143, 91, 0.15); color: var(--color-green);
  }
  .rpt-choice.is-wrong .rpt-letter {
    background: rgba(225, 55, 47, 0.15); color: var(--color-red);
  }
  .rpt-choice-label { flex: 1; }
  .rpt-icon-good {
    color: var(--color-green); font-weight: 700; font-size: 15px;
    flex-shrink: 0;
  }
  .rpt-pick-label {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.12em; text-transform: uppercase;
    color: var(--color-red); font-weight: 700;
    background: rgba(225, 55, 47, 0.12);
    padding: 3px 7px; border-radius: 4px;
    flex-shrink: 0;
  }

  .rpt-explain {
    background: var(--color-blue-soft);
    border: 1px solid rgba(30, 58, 140, 0.15);
    border-radius: 10px;
    padding: 12px 14px;
  }
  .rpt-explain-head {
    display: inline-flex; align-items: center; gap: 6px;
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 6px;
  }
  .rpt-explain p {
    font-size: 13px; line-height: 1.55; color: var(--color-ink-2); margin: 0;
  }

  /* ===== responsive ===== */
  @media (max-width: 860px) {
    .rpt-grid { grid-template-columns: 1fr; }
  }
  @media (max-width: 640px) {
    .rpt-hero { flex-direction: column; text-align: center; gap: 16px; padding: 24px 18px; }
    .rpt-hero-stats { justify-content: center; gap: 20px; }
    .rpt-row-theme { display: none; }
  }
`;
