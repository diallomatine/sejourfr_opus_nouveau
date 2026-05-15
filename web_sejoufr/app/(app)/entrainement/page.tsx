"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { MediaView } from "../../_components/MediaView";
import { ApiException, attemptApi, themeApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type {
  AnswerResultResponse,
  AttemptQuestionResponse,
  AttemptResponse,
  Module as ModuleEnum,
  ThemeUserResponse,
} from "@/lib/types";

type Stage = "setup" | "running" | "result";

const FREE_MAX = 20;
const SIZE_OPTIONS = [5, 10, 15, 20] as const;

export default function EntrainementPage() {
  const { user, status } = useAuth();
  const [module, setModule] = useState<ModuleEnum>("CIVIQUE");
  const [themes, setThemes] = useState<ThemeUserResponse[]>([]);
  const [themeId, setThemeId] = useState<string | "">("");
  const [size, setSize] = useState<(typeof SIZE_OPTIONS)[number]>(10);
  const [stage, setStage] = useState<Stage>("setup");
  const [attempt, setAttempt] = useState<AttemptResponse | null>(null);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [feedback, setFeedback] = useState<AnswerResultResponse | null>(null);
  const [selected, setSelected] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Charge la liste des thèmes du module sélectionné.
  useEffect(() => {
    let cancelled = false;
    setThemes([]);
    setThemeId("");
    themeApi
      .list(module)
      .then((list) => {
        if (cancelled) return;
        setThemes(list);
        if (list.length > 0) setThemeId(list[0].id);
      })
      .catch(() => {
        if (cancelled) return;
        setError("Impossible de charger les thèmes.");
      });
    return () => {
      cancelled = true;
    };
  }, [module]);

  async function startTraining() {
    setLoading(true);
    setError(null);
    try {
      const a = await attemptApi.start(
        {
          type: "TRAINING",
          module,
          themeId: themeId || undefined,
          size,
        },
        { auth: true },
      );
      setAttempt(a);
      setCurrentIdx(0);
      setFeedback(null);
      setSelected(null);
      setStage("running");
    } catch (err) {
      if (err instanceof ApiException) setError(err.message);
      else setError("Impossible de démarrer l'entraînement.");
    } finally {
      setLoading(false);
    }
  }

  async function submitAnswer() {
    if (!attempt || !selected) return;
    const aq = attempt.questions[currentIdx];
    setLoading(true);
    try {
      const res = await attemptApi.submitAnswer(attempt.id, {
        attemptQuestionId: aq.id,
        choiceIds: [selected],
      });
      setFeedback(res);
    } catch (err) {
      if (err instanceof ApiException) setError(err.message);
      else setError("Erreur lors de la soumission.");
    } finally {
      setLoading(false);
    }
  }

  function next() {
    if (!attempt) return;
    if (currentIdx + 1 >= attempt.questions.length) {
      // Fin de session : on finalise pour stocker le score côté back.
      void finishTraining();
      return;
    }
    setCurrentIdx((i) => i + 1);
    setSelected(null);
    setFeedback(null);
  }

  async function finishTraining() {
    if (!attempt) return;
    try {
      const final = await attemptApi.finish(attempt.id);
      setAttempt(final);
    } finally {
      setStage("result");
    }
  }

  const currentAq: AttemptQuestionResponse | null = useMemo(
    () => (attempt ? (attempt.questions[currentIdx] ?? null) : null),
    [attempt, currentIdx],
  );

  if (status === "loading") return null;
  if (!user) return null;

  return (
    <main className="train">
      {stage === "setup" && (
        <Setup
          module={module}
          onModule={setModule}
          themes={themes}
          themeId={themeId}
          onTheme={setThemeId}
          size={size}
          onSize={setSize}
          onStart={startTraining}
          loading={loading}
          error={error}
        />
      )}

      {stage === "running" && currentAq && attempt && (
        <Runner
          attempt={attempt}
          aq={currentAq}
          currentIdx={currentIdx}
          totalQuestions={attempt.totalQuestions}
          selected={selected}
          feedback={feedback}
          loading={loading}
          onSelect={(id) => {
            if (feedback) return; // verrouille après réponse
            setSelected(id);
          }}
          onSubmit={submitAnswer}
          onNext={next}
        />
      )}

      {stage === "result" && attempt && (
        <Result
          attempt={attempt}
          onAgain={() => {
            setAttempt(null);
            setStage("setup");
            setCurrentIdx(0);
            setFeedback(null);
            setSelected(null);
          }}
        />
      )}

      <style>{trainStyles}</style>
    </main>
  );
}

// ============================================================================
// SETUP
// ============================================================================
function Setup({
  module,
  onModule,
  themes,
  themeId,
  onTheme,
  size,
  onSize,
  onStart,
  loading,
  error,
}: {
  module: ModuleEnum;
  onModule: (m: ModuleEnum) => void;
  themes: ThemeUserResponse[];
  themeId: string;
  onTheme: (id: string) => void;
  size: (typeof SIZE_OPTIONS)[number];
  onSize: (s: (typeof SIZE_OPTIONS)[number]) => void;
  onStart: () => void;
  loading: boolean;
  error: string | null;
}) {
  return (
    <section className="setup">
      <div className="container-x">
        <header className="setup-head">
          <span className="eyebrow">Entraînement</span>
          <h1>
            10 minutes par jour, <em>et vous y êtes</em>.
          </h1>
          <p>
            Choisissez un thème et lancez-vous. Le web est limité à{" "}
            <strong>{FREE_MAX} questions par session</strong> : l&apos;entraînement
            illimité, les favoris et la révision des erreurs se trouvent dans
            l&apos;app mobile.
          </p>
        </header>

        <div className="setup-card">
          <div className="setup-row">
            <label className="setup-label">Module</label>
            <div className="seg">
              <button
                type="button"
                className={`seg-opt ${module === "CIVIQUE" ? "seg-active" : ""}`}
                onClick={() => onModule("CIVIQUE")}
              >
                Civique
              </button>
              <button
                type="button"
                className={`seg-opt ${module === "TCF" ? "seg-active" : ""}`}
                onClick={() => onModule("TCF")}
              >
                TCF IRN
              </button>
            </div>
          </div>

          <div className="setup-row">
            <label className="setup-label" htmlFor="theme-select">
              Thème
            </label>
            <select
              id="theme-select"
              className="setup-select"
              value={themeId}
              onChange={(e) => onTheme(e.target.value)}
            >
              {themes.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                  {t.questionCount ? ` · ${t.questionCount} questions` : ""}
                </option>
              ))}
            </select>
          </div>

          <div className="setup-row">
            <label className="setup-label">Nombre de questions</label>
            <div className="seg">
              {SIZE_OPTIONS.map((n) => (
                <button
                  key={n}
                  type="button"
                  className={`seg-opt ${size === n ? "seg-active" : ""}`}
                  onClick={() => onSize(n)}
                >
                  {n}
                </button>
              ))}
            </div>
          </div>

          {error && <div className="form-error">{error}</div>}

          <button
            type="button"
            className="btn btn-red btn-lg setup-cta"
            disabled={loading || !themeId}
            onClick={onStart}
          >
            {loading ? "Préparation…" : `Lancer ${size} questions`}
            <span>→</span>
          </button>

          <div className="setup-note">
            Pour s&apos;entraîner sans limite — favoris, hors-ligne, statistiques
            par thématique —{" "}
            <Link href="#telecharger" style={{ color: "var(--color-red)" }}>
              installez l&apos;app mobile
            </Link>
            .
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// RUNNER — correction immédiate, calque sur la capture mobile
// ============================================================================
function Runner({
  attempt,
  aq,
  currentIdx,
  totalQuestions,
  selected,
  feedback,
  loading,
  onSelect,
  onSubmit,
  onNext,
}: {
  attempt: AttemptResponse;
  aq: AttemptQuestionResponse;
  currentIdx: number;
  totalQuestions: number;
  selected: string | null;
  feedback: AnswerResultResponse | null;
  loading: boolean;
  onSelect: (id: string) => void;
  onSubmit: () => void;
  onNext: () => void;
}) {
  const q = aq.question;
  const correctIds = feedback?.correctChoiceIds ?? [];
  const isCorrect = feedback?.correct === true;
  const moduleLabel = attempt.module === "CIVIQUE" ? "Civique" : "TCF IRN";

  return (
    <section className="runner">
      <div className="runner-frame">
        <div className="runner-topbar">
          <Link href="/entrainement" className="runner-x" aria-label="Quitter">
            ✕
          </Link>
          <div className="runner-topbar-center">
            <span className="eyebrow">Entraînement</span>
            <span className="runner-count">Question {currentIdx + 1}</span>
          </div>
          <span className="runner-progress">
            {currentIdx + 1} / {totalQuestions}
          </span>
        </div>

        <div className="runner-tags">
          <span className="rtag rtag-red">{moduleLabel}</span>
          <span className="rtag rtag-blue">{q.themeName}</span>
        </div>

        <h2 className="runner-q">{q.statement}</h2>

        {q.media && (
          <div className="runner-media">
            {/* key=q.id force le remount du <audio> au changement de question :
                le navigateur detruit l'element et arrete la lecture en cours. */}
            <MediaView key={q.id} media={q.media} />
          </div>
        )}

        {q.passageText && (
          <div className="runner-passage">{q.passageText}</div>
        )}

        <div className="runner-options">
          {q.choices.map((c, i) => {
            const letter = String.fromCharCode(65 + i);
            const isSel = selected === c.id;
            const isThisCorrect = feedback && correctIds.includes(c.id);
            const isWrongPick = feedback && isSel && !isCorrect;

            const cls = [
              "ropt",
              isSel && !feedback ? "ropt-sel" : "",
              isThisCorrect ? "ropt-correct" : "",
              isWrongPick ? "ropt-wrong" : "",
            ]
              .filter(Boolean)
              .join(" ");

            return (
              <button
                type="button"
                key={c.id}
                className={cls}
                onClick={() => onSelect(c.id)}
                disabled={loading || !!feedback}
              >
                <span className="ropt-letter">{letter}</span>
                <span className="ropt-label">{c.label}</span>
                {isThisCorrect && (
                  <span className="ropt-check" aria-hidden>
                    <svg viewBox="0 0 16 16" width="16" height="16">
                      <circle cx="8" cy="8" r="8" fill="currentColor" />
                      <path
                        d="M4.5 8.5l2.4 2.2 4.6-5"
                        stroke="#fff"
                        strokeWidth="1.6"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        fill="none"
                      />
                    </svg>
                  </span>
                )}
                {isWrongPick && (
                  <span className="ropt-x" aria-hidden>
                    ✕
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {feedback && (
          <div className={`runner-explain ${isCorrect ? "good" : "bad"}`}>
            <div className="runner-explain-head">
              <span className="runner-explain-title">
                {isCorrect ? "✓ Bonne réponse" : "✗ Mauvaise réponse"}
              </span>
              <span className="runner-explain-tag">EXPLICATION</span>
            </div>
            {feedback.explanation && <p>{feedback.explanation}</p>}
          </div>
        )}

        <div className="runner-action">
          {!feedback ? (
            <button
              type="button"
              className="btn btn-blue btn-lg full"
              onClick={onSubmit}
              disabled={!selected || loading}
            >
              {loading ? "..." : "Valider ma réponse"}
            </button>
          ) : (
            <button
              type="button"
              className="btn btn-blue btn-lg full"
              onClick={onNext}
            >
              {currentIdx + 1 === totalQuestions ? "Voir le résultat" : "Question suivante"}{" "}
              →
            </button>
          )}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// RESULT
// ============================================================================
function Result({ attempt, onAgain }: { attempt: AttemptResponse; onAgain: () => void }) {
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const pct = total > 0 ? Math.round((score / total) * 100) : 0;
  const passed = pct >= 70;

  return (
    <section className="result">
      <div className="container-x" style={{ maxWidth: 640 }}>
        <div className="result-card">
          <span className={`result-tag ${passed ? "good" : "bad"}`}>
            {passed ? "Belle session" : "Continuez à pratiquer"}
          </span>
          <h1>
            {score} <span className="of">/ {total}</span>
          </h1>
          <p className="result-pct">{pct} % de bonnes réponses</p>

          <div className="result-cta">
            <button type="button" className="btn btn-ghost" onClick={onAgain}>
              ↻ Nouvel entraînement
            </button>
            <Link href="#telecharger" className="btn btn-red">
              Continuer sur l&apos;app mobile →
            </Link>
          </div>

          <div className="result-note">
            Sur le web, c&apos;est 20 questions maximum par session. L&apos;app mobile,
            elle, vous propose tout le pool (1 200+ questions) avec révision
            ciblée des erreurs et favoris.
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// STYLES
// ============================================================================
const trainStyles = `
  .train { background: var(--color-paper); min-height: calc(100vh - 110px); }

  .setup { padding: 56px 0 80px; }
  .setup-head { text-align: center; max-width: 720px; margin: 0 auto 40px; }
  .setup-head h1 {
    font-family: var(--font-display); font-weight: 500; font-size: clamp(32px, 4vw, 44px);
    line-height: 1.05; letter-spacing: -0.025em; margin: 14px 0 14px;
  }
  .setup-head h1 em { font-style: italic; color: var(--color-red); }
  .setup-head p { color: var(--color-muted); font-size: 16px; line-height: 1.55; margin: 0; }
  .setup-head p strong { color: var(--color-ink); font-weight: 600; }

  .setup-card {
    max-width: 520px; margin: 0 auto;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 32px;
    box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.18);
  }
  .setup-row { margin-bottom: 22px; }
  .setup-label {
    display: block;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-muted);
    margin-bottom: 10px;
  }
  .setup-select {
    width: 100%;
    padding: 12px 14px;
    border: 1px solid var(--color-line);
    border-radius: 10px;
    background: #fff;
    font-family: var(--font-sans); font-size: 14.5px;
    color: var(--color-ink);
  }
  .seg {
    display: inline-flex; padding: 4px;
    background: var(--color-paper-2);
    border-radius: 100px;
    gap: 4px;
  }
  .seg-opt {
    padding: 8px 18px;
    border: none; background: none;
    border-radius: 100px;
    font-family: var(--font-sans); font-weight: 600;
    font-size: 13.5px;
    color: var(--color-muted);
    cursor: pointer;
    transition: all 0.15s;
  }
  .seg-opt:hover { color: var(--color-ink); }
  .seg-active {
    background: #fff;
    color: var(--color-ink);
    box-shadow: 0 4px 12px -4px rgba(15, 24, 57, 0.15);
  }

  .setup-cta { width: 100%; margin-top: 8px; }
  .setup-note {
    margin-top: 20px;
    text-align: center;
    font-size: 13px;
    color: var(--color-muted);
    line-height: 1.5;
  }

  /* ----- runner ----- */
  .runner { padding: 32px 0 64px; }
  .runner-frame {
    max-width: 560px; margin: 0 auto;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 22px 26px 24px;
    box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.18);
  }

  .runner-topbar {
    display: flex; align-items: center; justify-content: space-between;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 18px;
  }
  .runner-x {
    text-decoration: none; color: var(--color-ink);
    width: 32px; height: 32px;
    display: flex; align-items: center; justify-content: center;
    font-size: 18px;
    border-radius: 8px;
  }
  .runner-x:hover { background: var(--color-paper-2); }
  .runner-topbar-center { display: flex; flex-direction: column; align-items: center; }
  .runner-count {
    font-family: var(--font-sans); font-weight: 700; font-size: 15px;
    margin-top: 2px;
  }
  .runner-progress {
    font-family: var(--font-mono); font-size: 11.5px;
    color: var(--color-muted); letter-spacing: 0.06em;
  }

  .runner-tags { display: flex; gap: 6px; margin-bottom: 16px; }
  .rtag {
    padding: 4px 10px;
    border-radius: 6px;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.1em; font-weight: 600;
    border: 1px solid;
  }
  .rtag-red { background: var(--color-red-light); color: var(--color-red); border-color: rgba(225, 55, 47, 0.3); }
  .rtag-blue { background: var(--color-blue-light); color: var(--color-blue); border-color: rgba(30, 58, 140, 0.3); }

  .runner-q {
    font-family: var(--font-sans); font-weight: 700;
    font-size: 20px; line-height: 1.3;
    color: var(--color-ink); margin: 0 0 18px;
  }
  .runner-passage {
    background: var(--color-paper);
    border-left: 3px solid var(--color-blue);
    border-radius: 8px;
    padding: 12px 14px;
    font-size: 14px; color: var(--color-ink-2); line-height: 1.55;
    margin: 0 0 18px;
    white-space: pre-wrap;
  }

  .runner-options { display: flex; flex-direction: column; gap: 8px; margin-bottom: 16px; }
  .ropt {
    background: #fff;
    border: 1.5px solid var(--color-line);
    border-radius: 12px;
    padding: 13px 14px;
    display: flex; align-items: center; gap: 12px;
    font-family: var(--font-sans);
    font-size: 14.5px; color: var(--color-ink-2);
    text-align: left;
    cursor: pointer;
    transition: all 0.15s;
    width: 100%;
  }
  .ropt:hover:not(:disabled) { border-color: var(--color-blue); background: var(--color-blue-soft); }
  .ropt:disabled { cursor: default; }
  .ropt-letter {
    width: 28px; height: 28px;
    border-radius: 50%;
    background: var(--color-line-2);
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 12px; font-weight: 600;
    flex-shrink: 0;
  }
  .ropt-label { flex: 1; }
  .ropt-sel { border-color: var(--color-blue); background: var(--color-blue-light); }
  .ropt-sel .ropt-letter { background: var(--color-blue); color: #fff; }

  .ropt-correct {
    border-color: var(--color-green);
    background: rgba(22, 143, 91, 0.06);
    box-shadow: 0 0 0 1px var(--color-green);
  }
  .ropt-correct .ropt-letter { background: rgba(22, 143, 91, 0.15); color: var(--color-green); }
  .ropt-check { color: var(--color-green); display: flex; align-items: center; }

  .ropt-wrong {
    border-color: var(--color-red);
    background: rgba(225, 55, 47, 0.05);
    box-shadow: 0 0 0 1px var(--color-red);
  }
  .ropt-wrong .ropt-letter { background: rgba(225, 55, 47, 0.15); color: var(--color-red); }
  .ropt-x { color: var(--color-red); font-weight: 700; font-size: 15px; margin-left: auto; }

  .runner-explain {
    border-radius: 12px;
    padding: 14px 16px;
    margin-bottom: 16px;
    border: 1px solid;
  }
  .runner-explain.good {
    background: rgba(22, 143, 91, 0.06);
    border-color: rgba(22, 143, 91, 0.25);
  }
  .runner-explain.bad {
    background: rgba(225, 55, 47, 0.05);
    border-color: rgba(225, 55, 47, 0.25);
  }
  .runner-explain-head {
    display: flex; align-items: center; justify-content: space-between;
    margin-bottom: 6px;
  }
  .runner-explain.good .runner-explain-title { color: var(--color-green); }
  .runner-explain.bad .runner-explain-title { color: var(--color-red); }
  .runner-explain-title {
    font-family: var(--font-sans); font-weight: 700; font-size: 14px;
  }
  .runner-explain-tag {
    font-family: var(--font-mono); font-size: 9px;
    letter-spacing: 0.14em; font-weight: 600;
    background: rgba(0,0,0,0.06);
    padding: 2px 8px; border-radius: 4px;
  }
  .runner-explain.good .runner-explain-tag {
    background: rgba(22, 143, 91, 0.12);
    color: var(--color-green);
  }
  .runner-explain.bad .runner-explain-tag {
    background: rgba(225, 55, 47, 0.12);
    color: var(--color-red);
  }
  .runner-explain p {
    font-size: 13.5px; line-height: 1.5;
    color: var(--color-ink-2); margin: 0;
  }

  .runner-action { margin-top: 6px; }
  .full { width: 100%; }
  .btn-blue {
    background: var(--color-blue); color: #fff;
    border: none; border-radius: 12px;
    padding: 14px 22px; font-size: 15px; font-weight: 700;
    font-family: var(--font-sans);
    cursor: pointer; transition: all 0.15s;
    display: flex; align-items: center; justify-content: center; gap: 8px;
  }
  .btn-blue:hover { background: var(--color-blue-dark); }
  .btn-blue:disabled { opacity: 0.5; cursor: not-allowed; }

  /* ----- result ----- */
  .result { padding: 64px 0 80px; }
  .result-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 48px 44px;
    text-align: center;
    box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
  }
  .result-tag {
    display: inline-block;
    font-family: var(--font-mono); font-size: 11px;
    letter-spacing: 0.16em; text-transform: uppercase;
    padding: 6px 12px; border-radius: 100px;
    margin-bottom: 22px; font-weight: 600;
  }
  .result-tag.good { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .result-tag.bad { background: var(--color-red-light); color: var(--color-red-dark); }
  .result-card h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: 84px; line-height: 1; letter-spacing: -0.04em;
    color: var(--color-blue);
    margin: 0 0 6px;
  }
  .result-card h1 .of { font-size: 36px; color: var(--color-muted-2); }
  .result-pct {
    font-family: var(--font-mono); font-size: 13px;
    color: var(--color-muted); letter-spacing: 0.1em;
    margin: 0 0 32px;
  }
  .result-cta {
    display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;
    margin-bottom: 24px;
  }
  .result-note {
    font-size: 13px; color: var(--color-muted);
    line-height: 1.5; max-width: 460px; margin: 0 auto;
    padding-top: 22px;
    border-top: 1px solid var(--color-line-2);
  }

  @media (max-width: 560px) {
    .setup-card { padding: 24px 20px; }
    .setup-card .seg-opt { padding: 8px 14px; }
    .runner-frame { padding: 18px 20px; }
    .result-card { padding: 32px 22px; }
    .result-card h1 { font-size: 56px; }
  }
`;
