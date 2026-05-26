"use client";

import { useMemo, useState } from "react";
import { orderedChoices } from "@/lib/types";
import type {
  AttemptQuestionResponse,
  AttemptResponse,
} from "@/lib/types";

type Filter = "all" | "wrong" | "right" | "skipped";

/**
 * Rapport détaillé d'un examen blanc finalisé : liste des questions avec le
 * choix de l'utilisateur, la bonne réponse et l'explication. Filtrable.
 *
 * Le backend renvoie `choice.correct: boolean` et `question.explanation`
 * uniquement quand `attempt.finishedAt !== null` (cf AttemptService :
 * revealCorrect). On peut donc traiter `AttemptResponse` directement.
 */
export function ExamReport({ attempt }: { attempt: AttemptResponse }) {
  const [filter, setFilter] = useState<Filter>("all");
  const [openIds, setOpenIds] = useState<Set<string>>(new Set());

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

  function expandAll() {
    setOpenIds(new Set(filtered.map((q) => q.id)));
  }
  function collapseAll() {
    setOpenIds(new Set());
  }

  return (
    <section className="rpt">
      <div className="rpt-wrap">
        <header className="rpt-head">
          <span className="eyebrow">Rapport détaillé</span>
          <h2>Vos réponses, une par une</h2>
          <p>
            Filtrez par état pour cibler ce qu&apos;il y a à retravailler. Chaque
            question affiche la bonne réponse et l&apos;explication.
          </p>
        </header>

        {/* Stats résumé */}
        <div className="rpt-stats">
          <StatTile label="Bonnes" value={counts.right} tone="good" />
          <StatTile label="Mauvaises" value={counts.wrong} tone="bad" />
          <StatTile label="Non répondues" value={counts.skipped} tone="neutral" />
        </div>

        {/* Filtres */}
        <div className="rpt-filters">
          <FilterChip active={filter === "all"} onClick={() => setFilter("all")}>
            Toutes <span className="rpt-count">{counts.all}</span>
          </FilterChip>
          <FilterChip
            active={filter === "wrong"}
            onClick={() => setFilter("wrong")}
            disabled={counts.wrong === 0}
            tone="bad"
          >
            Mauvaises <span className="rpt-count">{counts.wrong}</span>
          </FilterChip>
          <FilterChip
            active={filter === "right"}
            onClick={() => setFilter("right")}
            disabled={counts.right === 0}
            tone="good"
          >
            Bonnes <span className="rpt-count">{counts.right}</span>
          </FilterChip>
          {counts.skipped > 0 && (
            <FilterChip
              active={filter === "skipped"}
              onClick={() => setFilter("skipped")}
              tone="neutral"
            >
              Non répondues <span className="rpt-count">{counts.skipped}</span>
            </FilterChip>
          )}

          <div className="rpt-bulk">
            <button type="button" className="rpt-bulk-btn" onClick={expandAll}>
              Tout déplier
            </button>
            <button type="button" className="rpt-bulk-btn" onClick={collapseAll}>
              Replier
            </button>
          </div>
        </div>

        {/* Liste */}
        {filtered.length === 0 ? (
          <div className="rpt-empty">Aucune question dans cette catégorie.</div>
        ) : (
          <ol className="rpt-list">
            {filtered.map((aq) => (
              <ReportRow
                key={aq.id}
                aq={aq}
                open={openIds.has(aq.id)}
                onToggle={() => toggle(aq.id)}
              />
            ))}
          </ol>
        )}
      </div>
      <style>{styles}</style>
    </section>
  );
}

// ============================================================================
// REPORT ROW
// ============================================================================
function ReportRow({
  aq,
  open,
  onToggle,
}: {
  aq: AttemptQuestionResponse;
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
    <li className={`rpt-row rpt-row-${state}`}>
      <button type="button" className="rpt-row-head" onClick={onToggle} aria-expanded={open}>
        <span className="rpt-row-num">{aq.position + 1}</span>
        <span className="rpt-row-body">
          <span className="rpt-row-tags">
            <StateBadge state={state} />
            <span className="rpt-tag-mono">{q.difficulty}</span>
            <span className="rpt-tag-theme">{q.themeName}</span>
          </span>
          <span className={`rpt-row-statement ${open ? "is-open" : ""}`}>
            {q.statement}
          </span>
        </span>
        <span className={`rpt-row-chevron ${open ? "is-open" : ""}`} aria-hidden>
          ▾
        </span>
      </button>

      {open && (
        <div className="rpt-row-content">
          {q.passageText && (
            <div className="rpt-passage">
              <div className="rpt-passage-label">Document</div>
              <div className="rpt-passage-body">{q.passageText}</div>
            </div>
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

// ============================================================================
// SUB
// ============================================================================
function StatTile({
  label,
  value,
  tone,
}: {
  label: string;
  value: number;
  tone: "good" | "bad" | "neutral";
}) {
  return (
    <div className={`rpt-stat rpt-stat-${tone}`}>
      <span className="rpt-stat-value">{value}</span>
      <span className="rpt-stat-label">{label}</span>
    </div>
  );
}

function StateBadge({ state }: { state: "right" | "wrong" | "skipped" }) {
  const label =
    state === "right" ? "Correct" : state === "wrong" ? "Incorrect" : "Non répondu";
  return <span className={`rpt-state-badge rpt-state-${state}`}>{label}</span>;
}

function FilterChip({
  active,
  onClick,
  disabled,
  tone = "neutral",
  children,
}: {
  active: boolean;
  onClick: () => void;
  disabled?: boolean;
  tone?: "good" | "bad" | "neutral";
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      className={`rpt-chip rpt-chip-${tone} ${active ? "is-active" : ""}`}
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
  .rpt { padding: 16px 16px 64px; }
  .rpt-wrap { max-width: 760px; margin: 0 auto; }

  .rpt-head { text-align: center; margin: 0 0 24px; }
  .rpt-head h2 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(22px, 3.5vw, 30px); line-height: 1.15; letter-spacing: -0.02em;
    margin: 8px 0 8px;
    color: var(--color-ink);
  }
  .rpt-head p {
    color: var(--color-muted); font-size: 14px;
    margin: 0 auto; max-width: 480px; line-height: 1.55;
  }

  .rpt-stats {
    display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px;
    margin: 0 0 22px;
  }
  .rpt-stat {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 14px 12px;
    text-align: center;
  }
  .rpt-stat-value {
    display: block;
    font-family: var(--font-display); font-weight: 500;
    font-size: 28px; line-height: 1; letter-spacing: -0.03em;
    margin-bottom: 4px;
  }
  .rpt-stat-label {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
  }
  .rpt-stat-good .rpt-stat-value { color: var(--color-green); }
  .rpt-stat-bad .rpt-stat-value { color: var(--color-red); }
  .rpt-stat-neutral .rpt-stat-value { color: var(--color-muted); }

  /* Filters */
  .rpt-filters {
    display: flex; flex-wrap: wrap; gap: 8px;
    margin: 0 0 18px;
    align-items: center;
  }
  .rpt-chip {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 7px 12px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 100px;
    font-family: var(--font-sans);
    font-size: 13px; font-weight: 600;
    color: var(--color-ink-2);
    cursor: pointer;
    transition: all 0.15s;
  }
  .rpt-chip:hover:not(:disabled) {
    border-color: var(--color-blue); color: var(--color-blue);
  }
  .rpt-chip:disabled { opacity: 0.4; cursor: not-allowed; }
  .rpt-chip.is-active {
    background: var(--color-ink);
    color: #fff;
    border-color: var(--color-ink);
  }
  .rpt-chip-good.is-active { background: var(--color-green); border-color: var(--color-green); }
  .rpt-chip-bad.is-active { background: var(--color-red); border-color: var(--color-red); }

  .rpt-count {
    background: rgba(0, 0, 0, 0.06);
    color: inherit;
    font-family: var(--font-mono); font-size: 10px;
    padding: 1px 6px; border-radius: 100px;
    font-weight: 700; letter-spacing: 0.04em;
  }
  .rpt-chip.is-active .rpt-count {
    background: rgba(255, 255, 255, 0.2); color: #fff;
  }

  .rpt-bulk {
    margin-left: auto;
    display: flex; gap: 6px;
  }
  .rpt-bulk-btn {
    background: none; border: none;
    font-family: var(--font-sans); font-size: 12px; font-weight: 600;
    color: var(--color-muted);
    cursor: pointer;
    padding: 7px 6px;
    transition: color 0.15s;
  }
  .rpt-bulk-btn:hover { color: var(--color-blue); }

  /* Liste */
  .rpt-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 12px;
    padding: 36px 16px;
    text-align: center;
    color: var(--color-muted);
    font-size: 13.5px;
  }
  .rpt-list {
    list-style: none; padding: 0; margin: 0;
    display: flex; flex-direction: column; gap: 8px;
  }

  .rpt-row {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    overflow: hidden;
  }
  .rpt-row-right .rpt-row-head { border-left: 3px solid var(--color-green); }
  .rpt-row-wrong .rpt-row-head { border-left: 3px solid var(--color-red); }
  .rpt-row-skipped .rpt-row-head { border-left: 3px solid var(--color-muted-2); }

  .rpt-row-head {
    display: grid;
    grid-template-columns: 36px 1fr 20px;
    align-items: flex-start; gap: 12px;
    width: 100%;
    background: none; border: none;
    padding: 14px 16px;
    cursor: pointer;
    text-align: left;
    font-family: var(--font-sans);
  }
  .rpt-row-head:hover { background: var(--color-paper); }
  .rpt-row-num {
    font-family: var(--font-mono); font-size: 13px; font-weight: 700;
    color: var(--color-muted);
    letter-spacing: 0.05em;
    padding-top: 1px;
  }
  .rpt-row-body { min-width: 0; }
  .rpt-row-tags {
    display: flex; flex-wrap: wrap; align-items: center; gap: 6px;
    margin-bottom: 6px;
  }
  .rpt-row-statement {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden; text-overflow: ellipsis;
    font-size: 14px; line-height: 1.4;
    color: var(--color-ink-2);
  }
  .rpt-row-statement.is-open {
    -webkit-line-clamp: unset;
    color: var(--color-ink); font-weight: 600;
  }
  .rpt-row-chevron {
    color: var(--color-muted-2); font-size: 14px;
    transition: transform 0.18s;
    padding-top: 4px;
  }
  .rpt-row-chevron.is-open { transform: rotate(180deg); }

  .rpt-state-badge {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 8px; border-radius: 100px;
    font-weight: 700;
  }
  .rpt-state-right { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .rpt-state-wrong { background: var(--color-red-light); color: var(--color-red); }
  .rpt-state-skipped { background: var(--color-paper-2); color: var(--color-muted); }

  .rpt-tag-mono {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 7px; border-radius: 4px;
    background: var(--color-paper-2); color: var(--color-muted);
    font-weight: 700;
  }
  .rpt-tag-theme {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    color: var(--color-muted);
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    max-width: 180px;
  }

  /* Contenu déplié */
  .rpt-row-content {
    padding: 0 16px 16px 64px;
    border-top: 1px solid var(--color-line-2);
    padding-top: 16px;
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
`;
