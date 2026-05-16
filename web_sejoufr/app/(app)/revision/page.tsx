"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { ModuleSwitch } from "@/app/_components/ModuleSwitch";
import { ApiException, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type {
  Module as ModuleEnum,
  QuestionReviewResponse,
} from "@/lib/types";

type Tab = "errors" | "favorites";

export default function RevisionPage() {
  const { user, status } = useAuth();
  const [module, setModule] = useState<ModuleEnum>("CIVIQUE");
  const [tab, setTab] = useState<Tab>("errors");
  const [data, setData] = useState<{
    loading: boolean;
    errors: QuestionReviewResponse[];
    favorites: QuestionReviewResponse[];
    error: string | null;
    loadedFor: ModuleEnum | null;
  }>({
    loading: true,
    errors: [],
    favorites: [],
    error: null,
    loadedFor: null,
  });
  const [selectedQuestion, setSelectedQuestion] = useState<QuestionReviewResponse | null>(null);

  const refresh = useCallback(
    async (m: ModuleEnum) => {
      try {
        const [wrongList, favList] = await Promise.all([
          userContentApi.wrong(m),
          userContentApi.favorites(m),
        ]);
        setData({
          loading: false,
          errors: wrongList,
          favorites: favList,
          error: null,
          loadedFor: m,
        });
      } catch (e) {
        setData({
          loading: false,
          errors: [],
          favorites: [],
          error:
            e instanceof ApiException
              ? e.message
              : "Impossible de charger la révision.",
          loadedFor: m,
        });
      }
    },
    [],
  );

  useEffect(() => {
    let cancelled = false;
    refresh(module).then(() => {
      if (cancelled) return;
    });
    return () => {
      cancelled = true;
    };
  }, [module, refresh]);

  const isLoadedForCurrent = data.loadedFor === module;
  const errors = isLoadedForCurrent ? data.errors : [];
  const favorites = isLoadedForCurrent ? data.favorites : [];
  const list = tab === "errors" ? errors : favorites;
  const loading = data.loading || !isLoadedForCurrent;

  // Toggle favori : maj optimiste, refresh global après pour resynchroniser
  // les compteurs des deux onglets.
  const onToggleFavorite = useCallback(
    async (q: QuestionReviewResponse, wasFavorite: boolean) => {
      // Optimistic : on retire de la liste favoris si on l'enlève, on l'ajoute si on l'ajoute.
      setData((d) => {
        if (wasFavorite) {
          return { ...d, favorites: d.favorites.filter((x) => x.id !== q.id) };
        }
        return { ...d, favorites: [q, ...d.favorites.filter((x) => x.id !== q.id)] };
      });
      try {
        if (wasFavorite) {
          await userContentApi.removeFavorite(q.id);
        } else {
          await userContentApi.addFavorite(q.id);
        }
      } catch {
        // Rollback en revenant à l'état réel
        await refresh(module);
      }
    },
    [module, refresh],
  );

  if (status === "loading") return <div className="rv-loading" />;
  if (!user) {
    return (
      <main className="rv-gate">
        <p>Connectez-vous pour réviser vos questions.</p>
        <Link href="/connexion?next=/revision" className="btn btn-blue">
          Se connecter
        </Link>
      </main>
    );
  }

  return (
    <main className="rv">
      <section className="rv-head">
        <div className="rv-wrap">
          <span className="eyebrow">Révision</span>
          <h1>
            Vos <em>erreurs</em> et vos favoris.
          </h1>
          <p>
            Retravaillez les questions ratées et gardez sous le coude celles que
            vous voulez revoir. Le détail montre la bonne réponse et
            l&apos;explication.
          </p>
          <div className="rv-module">
            <ModuleSwitch value={module} onChange={setModule} />
          </div>
        </div>
      </section>

      <section className="rv-body">
        <div className="rv-wrap">
          <div className="rv-tabs" role="tablist">
            <button
              type="button"
              role="tab"
              aria-selected={tab === "errors"}
              className={`rv-tab ${tab === "errors" ? "is-active" : ""}`}
              onClick={() => setTab("errors")}
            >
              <span className="rv-tab-label">Erreurs récentes</span>
              <span className="rv-tab-count">{errors.length}</span>
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={tab === "favorites"}
              className={`rv-tab ${tab === "favorites" ? "is-active" : ""}`}
              onClick={() => setTab("favorites")}
            >
              <span className="rv-tab-label">Favoris</span>
              <span className="rv-tab-count">{favorites.length}</span>
            </button>
          </div>

          {loading && <ListLoading />}
          {data.error && !loading && <div className="form-error">{data.error}</div>}

          {!loading && !data.error && list.length === 0 && (
            <EmptyState tab={tab} module={module} />
          )}

          {!loading && list.length > 0 && (
            <div className="rv-list">
              {list.map((q) => (
                <QuestionRow
                  key={q.id}
                  question={q}
                  tab={tab}
                  isFavorite={favorites.some((f) => f.id === q.id)}
                  onClick={() => setSelectedQuestion(q)}
                />
              ))}
            </div>
          )}
        </div>
      </section>

      {selectedQuestion && (
        <QuestionDetailModal
          question={selectedQuestion}
          isFavorite={favorites.some((f) => f.id === selectedQuestion.id)}
          onClose={() => setSelectedQuestion(null)}
          onToggleFavorite={(was) => onToggleFavorite(selectedQuestion, was)}
        />
      )}

      <style>{styles}</style>
    </main>
  );
}

// ============================================================================
// QUESTION ROW
// ============================================================================
function QuestionRow({
  question,
  tab,
  isFavorite,
  onClick,
}: {
  question: QuestionReviewResponse;
  tab: Tab;
  isFavorite: boolean;
  onClick: () => void;
}) {
  return (
    <button type="button" className="rv-row" onClick={onClick}>
      <div className="rv-row-marker" data-tab={tab} aria-hidden>
        {tab === "errors" ? (
          <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 6 6 18M6 6l12 12" />
          </svg>
        ) : (
          <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor">
            <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
          </svg>
        )}
      </div>
      <div className="rv-row-body">
        <div className="rv-row-meta">
          <span className="rv-tag rv-tag-blue">{question.themeName}</span>
          <span className="rv-tag rv-tag-mono">{question.difficulty}</span>
          {isFavorite && tab !== "favorites" && (
            <span className="rv-tag rv-tag-fav" aria-label="En favoris">
              <svg viewBox="0 0 24 24" width="11" height="11" fill="currentColor">
                <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
              </svg>
            </span>
          )}
        </div>
        <div className="rv-row-statement">{question.statement}</div>
      </div>
      <div className="rv-row-arrow">›</div>
    </button>
  );
}

// ============================================================================
// QUESTION DETAIL MODAL
// ============================================================================
function QuestionDetailModal({
  question,
  isFavorite,
  onClose,
  onToggleFavorite,
}: {
  question: QuestionReviewResponse;
  isFavorite: boolean;
  onClose: () => void;
  onToggleFavorite: (wasFavorite: boolean) => Promise<void>;
}) {
  const [toggling, setToggling] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [onClose]);

  const handleToggle = async () => {
    if (toggling) return;
    setToggling(true);
    try {
      await onToggleFavorite(isFavorite);
    } finally {
      setToggling(false);
    }
  };

  return (
    <div className="rvd" role="dialog" aria-modal="true" onClick={onClose}>
      <div className="rvd-backdrop" />
      <div className="rvd-sheet" onClick={(e) => e.stopPropagation()}>
        <button type="button" className="rvd-close" onClick={onClose} aria-label="Fermer">
          ✕
        </button>

        <div className="rvd-head">
          <div className="rvd-tags">
            <span className="rv-tag rv-tag-blue">{question.themeName}</span>
            <span className="rv-tag rv-tag-mono">{question.difficulty}</span>
            <span className="rv-tag rv-tag-mono">
              {question.questionType === "KNOWLEDGE" ? "Connaissance" : "Situation"}
            </span>
          </div>
          <button
            type="button"
            className={`rvd-fav ${isFavorite ? "is-on" : ""}`}
            onClick={handleToggle}
            disabled={toggling}
            aria-label={isFavorite ? "Retirer des favoris" : "Ajouter aux favoris"}
          >
            <svg viewBox="0 0 24 24" width="16" height="16" fill={isFavorite ? "currentColor" : "none"} stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
            </svg>
          </button>
        </div>

        {question.passageText && (
          <div className="rvd-passage">
            <div className="rvd-passage-label">Document à lire</div>
            <div className="rvd-passage-body">{question.passageText}</div>
          </div>
        )}

        <h2 className="rvd-statement">{question.statement}</h2>

        <div className="rvd-choices">
          {question.choices.map((c, i) => {
            const letter = String.fromCharCode(65 + i);
            return (
              <div
                key={c.id}
                className={`rvd-choice ${c.correct ? "is-correct" : ""}`}
              >
                <span className="rvd-letter">{letter}</span>
                <span className="rvd-choice-label">{c.label}</span>
                {c.correct && (
                  <span className="rvd-check" aria-label="Bonne réponse">
                    <svg viewBox="0 0 16 16" width="16" height="16">
                      <circle cx="8" cy="8" r="8" fill="currentColor" />
                      <path d="M4.5 8.5l2.4 2.2 4.6-5" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" fill="none" />
                    </svg>
                  </span>
                )}
              </div>
            );
          })}
        </div>

        {question.explanation && (
          <div className="rvd-explain">
            <div className="rvd-explain-head">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M9 18h6M10 22h4M12 2a7 7 0 0 0-4 13l1 2h6l1-2a7 7 0 0 0-4-13z" />
              </svg>
              <span>Explication</span>
            </div>
            <p>{question.explanation}</p>
          </div>
        )}
      </div>
      <style>{detailStyles}</style>
    </div>
  );
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================
function EmptyState({ tab, module }: { tab: Tab; module: ModuleEnum }) {
  const moduleLabel = module === "TCF" ? "TCF" : "civique";
  if (tab === "errors") {
    return (
      <div className="rv-empty">
        <div className="rv-empty-icon good" aria-hidden>
          <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
            <path d="m9 11 3 3L22 4" />
          </svg>
        </div>
        <h2>Aucune erreur récente {moduleLabel}</h2>
        <p>Bravo&nbsp;! Continuez à vous entraîner pour faire émerger les zones à retravailler.</p>
        <Link href="/entrainement" className="btn btn-blue">
          Lancer un entraînement →
        </Link>
      </div>
    );
  }
  return (
    <div className="rv-empty">
      <div className="rv-empty-icon" aria-hidden>
        <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
        </svg>
      </div>
      <h2>Aucun favori {moduleLabel}</h2>
      <p>
        Pendant un entraînement, tapez sur l&apos;icône signet (ou la touche{" "}
        <kbd>B</kbd>) pour mettre une question de côté.
      </p>
      <Link href="/entrainement" className="btn btn-blue">
        Lancer un entraînement →
      </Link>
    </div>
  );
}

function ListLoading() {
  return (
    <div className="rv-list">
      {[0, 1, 2, 3].map((i) => (
        <div key={i} className="rv-row rv-row-skeleton" />
      ))}
    </div>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const styles = `
  .rv { background: var(--color-paper); min-height: calc(100vh - 110px); }
  .rv-loading { min-height: 60vh; }
  .rv-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px; color: var(--color-muted);
  }
  .rv-wrap { max-width: 760px; margin: 0 auto; }

  .rv-head { padding: 40px 16px 24px; text-align: center; }
  .rv-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 40px); line-height: 1.05; letter-spacing: -0.025em;
    margin: 10px 0 12px;
  }
  .rv-head h1 em { font-style: italic; color: var(--color-red); }
  .rv-head p {
    color: var(--color-muted); font-size: 15px; line-height: 1.55;
    margin: 0 auto 22px; max-width: 540px;
  }
  .rv-module { max-width: 460px; margin: 0 auto; }

  .rv-body { padding: 8px 16px 80px; }

  .rv-tabs {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 6px;
    padding: 4px;
    background: var(--color-paper-2);
    border-radius: 12px;
    margin: 18px 0 18px;
  }
  .rv-tab {
    display: flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 14px;
    background: transparent;
    border: none;
    border-radius: 9px;
    cursor: pointer;
    transition: all 0.15s;
    font-family: var(--font-sans);
    color: var(--color-muted);
  }
  .rv-tab:hover { color: var(--color-ink); }
  .rv-tab.is-active {
    background: #fff;
    color: var(--color-ink);
    box-shadow: 0 4px 12px -4px rgba(15, 24, 57, 0.15);
  }
  .rv-tab-label { font-weight: 700; font-size: 13.5px; }
  .rv-tab-count {
    font-family: var(--font-mono);
    background: var(--color-line-2);
    color: var(--color-muted);
    padding: 2px 7px; border-radius: 100px;
    font-size: 10.5px; font-weight: 700; letter-spacing: 0.06em;
  }
  .rv-tab.is-active .rv-tab-count {
    background: var(--color-blue-light); color: var(--color-blue);
  }

  .rv-list { display: flex; flex-direction: column; gap: 8px; }

  .rv-row {
    display: grid;
    grid-template-columns: 36px 1fr 24px;
    align-items: center; gap: 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 14px 16px;
    text-align: left;
    cursor: pointer;
    font-family: var(--font-sans);
    transition: all 0.15s;
    width: 100%;
  }
  .rv-row:hover {
    border-color: var(--color-blue);
    box-shadow: 0 8px 20px -10px rgba(30, 58, 140, 0.18);
  }
  .rv-row-skeleton {
    height: 76px;
    animation: rv-pulse 1.4s ease-in-out infinite;
  }
  @keyframes rv-pulse {
    0%, 100% { opacity: 0.55; }
    50% { opacity: 1; }
  }

  .rv-row-marker {
    width: 32px; height: 32px;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .rv-row-marker[data-tab="errors"] {
    background: var(--color-red-light);
    color: var(--color-red);
  }
  .rv-row-marker[data-tab="favorites"] {
    background: var(--color-blue-light);
    color: var(--color-blue);
  }

  .rv-row-body { min-width: 0; }
  .rv-row-meta {
    display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
    margin-bottom: 6px;
  }
  .rv-row-statement {
    font-weight: 600; font-size: 14.5px; line-height: 1.4;
    color: var(--color-ink);
    overflow: hidden; text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
  .rv-row-arrow {
    color: var(--color-muted-2); font-size: 20px;
    flex-shrink: 0;
  }

  .rv-tag {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.12em; text-transform: uppercase;
    padding: 3px 7px; border-radius: 4px;
    font-weight: 700;
  }
  .rv-tag-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .rv-tag-mono { background: var(--color-paper-2); color: var(--color-muted); }
  .rv-tag-fav {
    background: var(--color-blue-light);
    color: var(--color-blue);
    display: inline-flex; align-items: center;
    padding: 3px 5px;
  }

  /* ----- Empty state ----- */
  .rv-empty {
    background: #fff;
    border: 1px dashed var(--color-line);
    border-radius: 16px;
    padding: 48px 32px;
    text-align: center;
    margin-top: 16px;
  }
  .rv-empty-icon {
    width: 56px; height: 56px;
    margin: 0 auto 14px;
    background: var(--color-blue-light); color: var(--color-blue);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
  }
  .rv-empty-icon.good {
    background: rgba(22, 143, 91, 0.12); color: var(--color-green);
  }
  .rv-empty h2 {
    font-family: var(--font-display); font-weight: 500; font-size: 22px;
    color: var(--color-ink); margin: 0 0 8px;
    letter-spacing: -0.015em;
  }
  .rv-empty p {
    color: var(--color-muted); font-size: 13.5px; line-height: 1.55;
    margin: 0 auto 18px; max-width: 380px;
  }
  .rv-empty kbd {
    background: var(--color-paper-2);
    padding: 1px 6px; border-radius: 4px;
    font-family: var(--font-mono); font-size: 11px;
    color: var(--color-ink);
  }
`;

const detailStyles = `
  .rvd {
    position: fixed; inset: 0;
    z-index: 100;
    display: flex; align-items: flex-end; justify-content: center;
  }
  .rvd-backdrop {
    position: absolute; inset: 0;
    background: rgba(15, 24, 57, 0.45);
    animation: rvd-fade-in 0.18s ease-out;
  }
  @keyframes rvd-fade-in { from { opacity: 0; } to { opacity: 1; } }
  @keyframes rvd-slide-up {
    from { transform: translateY(20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  .rvd-sheet {
    position: relative;
    background: #fff;
    border-radius: 22px 22px 0 0;
    padding: 24px 24px 22px;
    width: 100%;
    max-width: 640px;
    box-shadow: 0 -10px 50px -10px rgba(15, 24, 57, 0.25);
    animation: rvd-slide-up 0.22s ease-out;
    max-height: 92vh;
    overflow-y: auto;
  }
  @media (min-width: 640px) {
    .rvd { align-items: center; }
    .rvd-sheet { border-radius: 18px; }
  }

  .rvd-close {
    position: absolute; top: 14px; right: 14px;
    width: 32px; height: 32px;
    background: var(--color-paper-2);
    border: none; border-radius: 8px;
    font-size: 14px;
    color: var(--color-muted);
    cursor: pointer;
    z-index: 2;
  }
  .rvd-close:hover { background: var(--color-line); color: var(--color-ink); }

  .rvd-head {
    display: flex; align-items: flex-start; justify-content: space-between;
    gap: 16px; margin-bottom: 14px;
    padding-right: 40px;
  }
  .rvd-tags {
    display: flex; flex-wrap: wrap; gap: 6px;
  }
  .rvd-fav {
    background: none; border: 1px solid var(--color-line);
    color: var(--color-ink);
    width: 32px; height: 32px;
    border-radius: 8px;
    display: inline-flex; align-items: center; justify-content: center;
    cursor: pointer;
    transition: all 0.15s;
    flex-shrink: 0;
  }
  .rvd-fav:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .rvd-fav.is-on { color: var(--color-red); border-color: rgba(225, 55, 47, 0.3); background: var(--color-red-light); }

  .rvd-passage {
    background: var(--color-blue-soft);
    border: 1px solid rgba(30, 58, 140, 0.15);
    border-radius: 10px;
    padding: 12px 14px;
    margin: 0 0 14px;
  }
  .rvd-passage-label {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.16em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 6px;
  }
  .rvd-passage-body {
    font-size: 13.5px; color: var(--color-ink-2); line-height: 1.55;
    white-space: pre-wrap;
  }

  .rvd-statement {
    font-family: var(--font-display); font-weight: 600;
    font-size: 19px; line-height: 1.35;
    color: var(--color-ink);
    margin: 0 0 18px;
  }

  .rvd-choices { display: flex; flex-direction: column; gap: 8px; margin-bottom: 16px; }
  .rvd-choice {
    display: flex; align-items: center; gap: 12px;
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 12px;
    padding: 12px 14px;
    font-size: 14px; color: var(--color-ink-2);
  }
  .rvd-choice.is-correct {
    border-color: var(--color-green);
    background: rgba(22, 143, 91, 0.06);
    box-shadow: 0 0 0 1px var(--color-green);
  }
  .rvd-letter {
    width: 26px; height: 26px;
    border-radius: 50%;
    background: var(--color-line-2);
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 12px; font-weight: 700;
    flex-shrink: 0;
  }
  .rvd-choice.is-correct .rvd-letter {
    background: rgba(22, 143, 91, 0.15); color: var(--color-green);
  }
  .rvd-choice-label { flex: 1; }
  .rvd-check { color: var(--color-green); display: inline-flex; align-items: center; flex-shrink: 0; }

  .rvd-explain {
    background: var(--color-blue-soft);
    border: 1px solid rgba(30, 58, 140, 0.15);
    border-radius: 12px;
    padding: 14px 16px;
  }
  .rvd-explain-head {
    display: inline-flex; align-items: center; gap: 6px;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-blue); font-weight: 700;
    margin-bottom: 6px;
  }
  .rvd-explain p {
    font-size: 13.5px; line-height: 1.55; color: var(--color-ink-2); margin: 0;
  }
`;
