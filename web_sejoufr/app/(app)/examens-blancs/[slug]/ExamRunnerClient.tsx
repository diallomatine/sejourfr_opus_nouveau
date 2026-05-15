"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { MediaView } from "../../../_components/MediaView";
import { ApiException, attemptApi } from "@/lib/api";
import type {
  AttemptQuestionResponse,
  AttemptResponse,
  ExamTemplateSummary,
  TargetLevel,
} from "@/lib/types";

type Stage = "briefing" | "running" | "result";

export function ExamRunnerClient({ exam }: { exam: ExamTemplateSummary }) {
  const [stage, setStage] = useState<Stage>("briefing");
  const [attempt, setAttempt] = useState<AttemptResponse | null>(null);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [selected, setSelected] = useState<Record<string, string[]>>({});
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [blocker, setBlocker] = useState<"auth" | "premium" | null>(null);
  const [loading, setLoading] = useState(false);

  async function startExam() {
    setLoading(true);
    setError(null);
    setBlocker(null);
    try {
      const a = await attemptApi.start(
        {
          type: "MOCK_EXAM",
          module: exam.module,
          examTemplateId: exam.id,
        },
        { auth: true },
      );
      setAttempt(a);
      setCurrentIdx(0);
      setSelected({});
      setSecondsLeft(a.timeLimitSeconds ?? null);
      setStage("running");
    } catch (err) {
      if (err instanceof ApiException) {
        if (err.status === 401) setBlocker("auth");
        else if (err.status === 403) setBlocker("premium");
        else setError(err.message);
      } else {
        setError(
          "Le serveur d'examen est indisponible. Vérifiez que le backend tourne sur le port 8080.",
        );
      }
    } finally {
      setLoading(false);
    }
  }

  // Timer
  useEffect(() => {
    if (stage !== "running" || secondsLeft == null) return;
    if (secondsLeft <= 0) {
      void finishExam();
      return;
    }
    const id = window.setTimeout(
      () => setSecondsLeft((s) => (s ?? 0) - 1),
      1000,
    );
    return () => window.clearTimeout(id);
  }, [stage, secondsLeft]); // eslint-disable-line react-hooks/exhaustive-deps

  const formattedTime = useMemo(() => {
    if (secondsLeft == null) return "—";
    const m = Math.floor(secondsLeft / 60)
      .toString()
      .padStart(2, "0");
    const s = (secondsLeft % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  }, [secondsLeft]);

  const currentAq: AttemptQuestionResponse | null = attempt
    ? (attempt.questions[currentIdx] ?? null)
    : null;

  function toggleChoice(choiceId: string) {
    if (!currentAq) return;
    setSelected((prev) => ({ ...prev, [currentAq.id]: [choiceId] }));
  }

  async function submitCurrent() {
    if (!currentAq || !attempt) return;
    const choiceIds = selected[currentAq.id] ?? [];
    if (choiceIds.length === 0) {
      next();
      return;
    }
    try {
      await attemptApi.submitAnswer(attempt.id, {
        attemptQuestionId: currentAq.id,
        choiceIds,
      });
    } catch {
      // silencieux en MOCK_EXAM
    }
    next();
  }

  function next() {
    if (!attempt) return;
    if (currentIdx >= attempt.totalQuestions - 1) {
      void finishExam();
    } else {
      setCurrentIdx((i) => i + 1);
    }
  }

  function prev() {
    setCurrentIdx((i) => Math.max(0, i - 1));
  }

  const finishExam = useCallback(async () => {
    if (!attempt) return;
    try {
      const final = await attemptApi.finish(attempt.id);
      setAttempt(final);
    } finally {
      setStage("result");
    }
  }, [attempt]);

  const answeredCount = Object.values(selected).filter(
    (v) => v && v.length > 0,
  ).length;
  const totalQs = attempt?.totalQuestions ?? exam.totalQuestions;
  const progressPct =
    attempt && totalQs > 0 ? ((currentIdx + 1) / totalQs) * 100 : 0;

  return (
    <>
      {stage === "briefing" && (
        <Briefing
          exam={exam}
          loading={loading}
          error={error}
          blocker={blocker}
          onStart={startExam}
          onDismissBlocker={() => setBlocker(null)}
        />
      )}

      {stage === "running" && attempt && currentAq && (
        <Runner
          attempt={attempt}
          currentAq={currentAq}
          currentIdx={currentIdx}
          totalQs={totalQs}
          progressPct={progressPct}
          formattedTime={formattedTime}
          selected={selected[currentAq.id] ?? []}
          unansweredCount={totalQs - answeredCount}
          onToggle={toggleChoice}
          onPrev={prev}
          onNext={submitCurrent}
        />
      )}

      {stage === "result" && attempt && (
        <Result
          attempt={attempt}
          exam={exam}
          onRetry={() => {
            setAttempt(null);
            setSelected({});
            setSecondsLeft(null);
            setCurrentIdx(0);
            setStage("briefing");
          }}
        />
      )}
    </>
  );
}

// ============================================================================
// BRIEFING
// ============================================================================
function Briefing({
  exam,
  loading,
  error,
  blocker,
  onStart,
  onDismissBlocker,
}: {
  exam: ExamTemplateSummary;
  loading: boolean;
  error: string | null;
  blocker: "auth" | "premium" | null;
  onStart: () => void;
  onDismissBlocker: () => void;
}) {
  const minutes = Math.round(exam.durationSeconds / 60);
  const isTcf = exam.module === "TCF";

  return (
    <section style={{ padding: "56px 0 80px" }}>
      <div className="container-x" style={{ maxWidth: 880 }}>
        <div className="brief-card">
          <div className="brief-head">
            <div className="tag">
              {isTcf ? "TCF IRN" : "Examen civique"}
              {exam.free && " · Gratuit"}
              {!exam.free && " · Premium"}
            </div>
            <h2>{exam.name}</h2>
            {exam.description && <p>{exam.description}</p>}
          </div>

          <div className="brief-body">
            <div className="brief-stats">
              <div className="brief-stat">
                <div className="l">Questions</div>
                <div className="v">{exam.totalQuestions}</div>
              </div>
              <div className="brief-stat">
                <div className="l">Temps</div>
                <div className="v">{minutes} min</div>
              </div>
              {!isTcf && (
                <div className="brief-stat">
                  <div className="l">Seuil de réussite</div>
                  <div className="v green">
                    {exam.passingScore}/{exam.totalQuestions}
                  </div>
                </div>
              )}
              {isTcf && (
                <div className="brief-stat">
                  <div className="l">Restitution</div>
                  <div className="v">Niveau CECRL</div>
                </div>
              )}
              <div className="brief-stat">
                <div className="l">Cible</div>
                <div className="v">
                  {exam.module === "CIVIQUE"
                    ? (exam.targetProcedure ?? "Tous parcours")
                    : (exam.targetLevel ?? "Diagnostic")}
                </div>
              </div>
            </div>

            <div className="brief-rules">
              <h3>Règles de l&apos;examen</h3>
              <ul>
                <li>
                  <span className="ico">1</span>
                  Vous avez {minutes} minutes pour répondre aux {exam.totalQuestions}{" "}
                  questions. Le chronomètre est visible en haut.
                </li>
                <li>
                  <span className="ico">2</span>
                  Une seule bonne réponse par question. Pas de pénalité pour les
                  mauvaises : tentez toujours.
                </li>
                <li>
                  <span className="ico">3</span>
                  Les corrections n&apos;apparaissent qu&apos;à la fin, comme en condition réelle.
                </li>
                {isTcf && (
                  <li>
                    <span className="ico">4</span>
                    Votre niveau CECRL (A2 / B1 / B2) est calculé d&apos;après vos
                    réussites sur chaque strate.
                  </li>
                )}
                <li>
                  <span className="ico">{isTcf ? 5 : 4}</span>
                  Si vous quittez la page, votre tentative est perdue.
                </li>
              </ul>
            </div>

            {error && <div className="form-error">{error}</div>}

            {blocker === "auth" && (
              <BlockerCard
                title="Créez un compte gratuit"
                body="Pour passer cet examen et sauvegarder votre score, vous devez d'abord créer un compte. C'est rapide et gratuit."
                ctaHref="/inscription"
                ctaLabel="Créer un compte"
                onDismiss={onDismissBlocker}
              />
            )}

            {blocker === "premium" && (
              <BlockerCard
                title="Cet examen est réservé aux abonnés"
                body="Débloquez les 19 autres examens blancs (et toute la plateforme) avec l'abonnement Premium. À partir de 9.99 €/mois, sans engagement."
                ctaHref="/paiement"
                ctaLabel="Découvrir Premium"
                onDismiss={onDismissBlocker}
              />
            )}

            {!blocker && (
              <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                <button
                  onClick={onStart}
                  disabled={loading}
                  className="btn btn-red btn-lg"
                >
                  {loading ? "Préparation..." : "Démarrer l'examen"}
                  <span>→</span>
                </button>
                <Link href="/examens-blancs" className="btn btn-link-soft">
                  ← Choisir un autre examen
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>

      <style>{briefingStyles}</style>
    </section>
  );
}

function BlockerCard({
  title,
  body,
  ctaHref,
  ctaLabel,
  onDismiss,
}: {
  title: string;
  body: string;
  ctaHref: string;
  ctaLabel: string;
  onDismiss: () => void;
}) {
  return (
    <div className="blocker">
      <div>
        <div className="blocker-title">{title}</div>
        <div className="blocker-body">{body}</div>
      </div>
      <div className="blocker-actions">
        <Link href={ctaHref} className="btn btn-red">
          {ctaLabel}
        </Link>
        <button type="button" onClick={onDismiss} className="btn btn-link-soft">
          Retour
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// RUNNER
// ============================================================================
function Runner({
  attempt,
  currentAq,
  currentIdx,
  totalQs,
  progressPct,
  formattedTime,
  selected,
  unansweredCount,
  onToggle,
  onPrev,
  onNext,
}: {
  attempt: AttemptResponse;
  currentAq: AttemptQuestionResponse;
  currentIdx: number;
  totalQs: number;
  progressPct: number;
  formattedTime: string;
  selected: string[];
  unansweredCount: number;
  onToggle: (choiceId: string) => void;
  onPrev: () => void;
  onNext: () => void;
}) {
  const q = currentAq.question;

  return (
    <section style={{ padding: "32px 0 80px" }}>
      <div className="container-x" style={{ maxWidth: 880 }}>
        <div className="exam-ui">
          <div className="exam-bar">
            <div className="timer">
              <span className="pulse" />
              {formattedTime} restants
            </div>
            <div className="progressbar">
              <div className="fill" style={{ width: `${progressPct}%` }} />
            </div>
            <div className="progress-text">
              Question {currentIdx + 1} / {totalQs}
            </div>
          </div>

          <div className="exam-cat">
            {q.themeName} · Question {currentIdx + 1}
          </div>
          <h3 className="exam-q">{q.statement}</h3>

          {q.media && (
            <div className="exam-media">
              <MediaView media={q.media} />
            </div>
          )}

          {q.passageText && (
            <div className="exam-passage">{q.passageText}</div>
          )}

          <div className="exam-options">
            {q.choices.map((c, i) => {
              const isSelected = selected.includes(c.id);
              const letter = String.fromCharCode(65 + i);
              return (
                <button
                  type="button"
                  key={c.id}
                  className={`exam-opt ${isSelected ? "selected" : ""}`}
                  onClick={() => onToggle(c.id)}
                >
                  <span className="letter">{letter}</span>
                  {c.label}
                </button>
              );
            })}
          </div>

          <div className="exam-actions">
            <span className="meta">
              {unansweredCount === 0
                ? "Toutes les questions sont répondues"
                : `${unansweredCount} questions sans réponse`}
            </span>
            <div style={{ display: "flex", gap: 10 }}>
              <button
                type="button"
                onClick={onPrev}
                disabled={currentIdx === 0}
                className="btn btn-ghost"
              >
                ← Précédent
              </button>
              <button type="button" onClick={onNext} className="btn">
                {currentIdx === totalQs - 1 ? "Terminer" : "Suivant →"}
              </button>
            </div>
          </div>
        </div>
      </div>

      <style>{runnerStyles}</style>
    </section>
  );
}

// ============================================================================
// RESULT
// ============================================================================
function Result({
  attempt,
  exam,
  onRetry,
}: {
  attempt: AttemptResponse;
  exam: ExamTemplateSummary;
  onRetry: () => void;
}) {
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const pct = Math.round((score / total) * 100);
  const isTcf = attempt.module === "TCF";

  if (isTcf) {
    return <TcfResult attempt={attempt} score={score} pct={pct} onRetry={onRetry} />;
  }

  const threshold = attempt.passThreshold ?? Math.ceil(total * 0.8);
  const passed = score >= threshold;

  return (
    <section style={{ padding: "56px 0 80px" }}>
      <div className="container-x" style={{ maxWidth: 720 }}>
        <div className="result-card">
          <span
            className="result-tag"
            style={{
              background: passed
                ? "rgba(22,143,91,0.12)"
                : "var(--color-red-light)",
              color: passed ? "var(--color-green)" : "var(--color-red-dark)",
            }}
          >
            {passed ? "● Réussi" : "● Non atteint"}
          </span>

          <h1 className="result-h1">
            {passed ? (
              <>
                Vous avez <em>réussi</em>.
              </>
            ) : (
              <>
                Pas encore <em>tout à fait</em>.
              </>
            )}
          </h1>

          <div className="score-block">
            <div className="score-big">
              {score}
              <span className="of">/ {total}</span>
            </div>
            <div className="score-pct">{pct} %</div>
            <div className="score-thresh">
              Seuil de réussite&nbsp;: {threshold}/{total}
            </div>
          </div>

          <p className="result-msg">
            {passed
              ? "Excellent travail. Continuez à vous entraîner pour consolider votre niveau et garder le rythme jusqu'au jour J."
              : `Cet examen "${exam.name}" est un bon indicateur des thématiques à travailler. Continuez avec un autre examen blanc.`}
          </p>

          <div className="result-actions">
            <Link href="/examens-blancs" className="btn btn-red btn-lg">
              Voir les autres examens
            </Link>
            <button onClick={onRetry} type="button" className="btn btn-ghost btn-lg">
              Recommencer
            </button>
          </div>
        </div>
      </div>

      <style>{resultStyles}</style>
    </section>
  );
}

function TcfResult({
  attempt,
  score,
  pct,
  onRetry,
}: {
  attempt: AttemptResponse;
  score: number;
  pct: number;
  onRetry: () => void;
}) {
  const level: TargetLevel | null = attempt.levelAchieved;
  const label = level ? `Niveau ${level}` : "Niveau inférieur à A2";
  const subtitle = level
    ? levelMessage(level)
    : "Vous n'atteignez pas encore le seuil A2. Continuez à vous entraîner.";

  return (
    <section style={{ padding: "56px 0 80px" }}>
      <div className="container-x" style={{ maxWidth: 720 }}>
        <div className="result-card">
          <span
            className="result-tag"
            style={{
              background: "var(--color-blue-light)",
              color: "var(--color-blue)",
            }}
          >
            ● Diagnostic TCF
          </span>

          <h1 className="result-h1">
            Votre niveau estimé&nbsp;: <em>{label}</em>
          </h1>

          <div className="score-block">
            <div className="score-big">
              {score}
              <span className="of"> / {attempt.totalQuestions}</span>
            </div>
            <div className="score-pct">{pct} % de bonnes réponses</div>
            <div className="score-thresh">{subtitle}</div>
          </div>

          <div className="result-actions">
            <Link href="/examens-blancs?module=TCF" className="btn btn-red btn-lg">
              Refaire un diagnostic
            </Link>
            <button onClick={onRetry} type="button" className="btn btn-ghost btn-lg">
              Recommencer cet examen
            </button>
          </div>
        </div>
      </div>

      <style>{resultStyles}</style>
    </section>
  );
}

function levelMessage(level: TargetLevel): string {
  switch (level) {
    case "A2":
      return "A2 ouvre l'accès à la carte de séjour (CSP). Continuez vers B1 pour la carte de résident.";
    case "B1":
      return "B1 est requis pour la carte de résident. Visez B2 pour la naturalisation.";
    case "B2":
      return "B2 est le niveau requis pour la naturalisation. Bravo, vous y êtes.";
  }
}

// ============================================================================
// STYLES
// ============================================================================
const briefingStyles = `
  .brief-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    overflow: hidden;
  }
  .brief-head {
    background: var(--color-blue);
    color: #fff;
    padding: 36px 40px;
    position: relative;
    overflow: hidden;
  }
  .brief-head::before {
    content: ''; position: absolute;
    top: -100px; right: -100px;
    width: 300px; height: 300px;
    background: radial-gradient(circle, rgba(225, 55, 47, 0.25), transparent 70%);
    pointer-events: none;
  }
  .brief-head .tag {
    font-family: var(--font-mono);
    font-size: 11px; letter-spacing: 0.18em; text-transform: uppercase;
    color: rgba(255, 255, 255, 0.65); margin-bottom: 10px;
  }
  .brief-head h2 {
    font-family: var(--font-display); font-weight: 500; font-size: 32px;
    margin: 0 0 8px; letter-spacing: -0.02em; line-height: 1.15;
    color: #fff; position: relative;
  }
  .brief-head p { color: rgba(255, 255, 255, 0.78); font-size: 15px; margin: 0; max-width: 600px; position: relative; }

  .brief-body { padding: 36px 40px; }
  .brief-stats {
    display: grid; grid-template-columns: repeat(4, 1fr); gap: 24px;
    padding-bottom: 28px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 28px;
  }
  .brief-stat .l {
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.12em; text-transform: uppercase; color: var(--color-muted);
    margin-bottom: 4px;
  }
  .brief-stat .v {
    font-family: var(--font-display); font-size: 24px; font-weight: 500;
    letter-spacing: -0.02em;
  }
  .brief-stat .v.green { color: var(--color-green); }

  .brief-rules h3 {
    font-family: var(--font-sans); font-weight: 700; font-size: 14px;
    margin: 0 0 16px; color: var(--color-ink);
  }
  .brief-rules ul {
    list-style: none; padding: 0; margin: 0 0 28px;
    display: flex; flex-direction: column; gap: 12px;
  }
  .brief-rules li {
    display: flex; gap: 12px; align-items: flex-start;
    font-size: 14.5px; color: var(--color-ink-2); line-height: 1.5;
  }
  .brief-rules .ico {
    width: 20px; height: 20px; border-radius: 50%;
    background: var(--color-blue-light); color: var(--color-blue);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0; margin-top: 1px;
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
  }

  .blocker {
    background: var(--color-blue-soft);
    border: 1px solid var(--color-blue-light);
    border-left: 3px solid var(--color-blue);
    border-radius: 12px;
    padding: 18px 22px;
    margin-bottom: 22px;
    display: flex; gap: 20px; align-items: center; justify-content: space-between;
    flex-wrap: wrap;
  }
  .blocker-title {
    font-family: var(--font-display); font-weight: 500; font-size: 17px;
    color: var(--color-ink); margin-bottom: 4px;
  }
  .blocker-body {
    color: var(--color-ink-2); font-size: 13.5px; line-height: 1.5;
    max-width: 480px;
  }
  .blocker-actions { display: flex; gap: 8px; align-items: center; }

  @media (max-width: 760px) {
    .brief-head { padding: 28px 24px; }
    .brief-head h2 { font-size: 26px; }
    .brief-body { padding: 28px 24px; }
    .brief-stats { grid-template-columns: 1fr 1fr; gap: 20px; }
  }
`;

const runnerStyles = `
  .exam-ui {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 28px 32px;
    box-shadow: 0 20px 50px -25px rgba(15, 24, 57, 0.15);
  }
  .exam-bar {
    display: flex; justify-content: space-between; align-items: center;
    padding-bottom: 18px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 24px;
  }
  .timer {
    display: flex; align-items: center; gap: 8px;
    font-family: var(--font-mono); font-size: 14px;
    color: var(--color-red); font-weight: 600;
  }
  .timer .pulse {
    width: 8px; height: 8px; border-radius: 50%; background: var(--color-red);
    animation: pulse 1.4s infinite;
  }
  @keyframes pulse {
    0%, 100% { opacity: 1; transform: scale(1); }
    50% { opacity: 0.4; transform: scale(0.8); }
  }
  .progressbar {
    flex: 1; max-width: 320px; margin: 0 24px;
    height: 4px; background: var(--color-line);
    border-radius: 100px; overflow: hidden;
  }
  .progressbar .fill {
    height: 100%;
    background: linear-gradient(90deg, var(--color-blue), var(--color-red));
    border-radius: 100px;
    transition: width 0.3s;
  }
  .progress-text {
    font-family: var(--font-mono); font-size: 13px; color: var(--color-muted);
  }
  .exam-cat {
    font-family: var(--font-mono); font-size: 11px;
    letter-spacing: 0.14em; text-transform: uppercase; color: var(--color-blue);
    margin-bottom: 12px;
  }
  .exam-q {
    font-family: var(--font-display); font-weight: 500; font-size: 26px;
    line-height: 1.25; letter-spacing: -0.015em;
    margin: 0 0 20px;
  }
  .exam-passage {
    background: var(--color-paper);
    border-left: 3px solid var(--color-blue);
    border-radius: 6px;
    padding: 14px 16px; margin: 0 0 22px;
    font-size: 14px; color: var(--color-ink-2); line-height: 1.55;
    white-space: pre-wrap;
  }
  .exam-options { display: flex; flex-direction: column; gap: 10px; margin-bottom: 28px; }
  .exam-opt {
    border: 1.5px solid var(--color-line); border-radius: 12px;
    padding: 16px 18px;
    display: flex; align-items: center; gap: 14px;
    background: #fff;
    cursor: pointer;
    transition: all 0.15s;
    font-size: 15px;
    color: var(--color-ink-2);
    text-align: left;
    font-family: inherit;
    width: 100%;
  }
  .exam-opt:hover { border-color: var(--color-blue); background: var(--color-blue-soft); }
  .exam-opt.selected {
    border-color: var(--color-blue); background: var(--color-blue-light);
    color: var(--color-ink);
  }
  .exam-opt .letter {
    width: 28px; height: 28px; border-radius: 50%;
    background: var(--color-paper-2); color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 13px; font-weight: 500;
    flex-shrink: 0;
    transition: all 0.15s;
  }
  .exam-opt.selected .letter { background: var(--color-blue); color: #fff; }

  .exam-actions {
    display: flex; justify-content: space-between; align-items: center;
    padding-top: 20px; border-top: 1px solid var(--color-line-2);
  }
  .exam-actions .meta {
    font-family: var(--font-mono); font-size: 11px;
    color: var(--color-muted); letter-spacing: 0.08em;
  }

  @media (max-width: 760px) {
    .exam-ui { padding: 22px 20px; }
    .exam-bar { flex-wrap: wrap; gap: 10px; }
    .progressbar { margin: 0; order: 3; flex-basis: 100%; }
    .exam-q { font-size: 20px; }
  }
`;

const resultStyles = `
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
    font-family: var(--font-mono);
    font-size: 11px; letter-spacing: 0.16em; text-transform: uppercase;
    padding: 6px 12px; border-radius: 100px;
    margin-bottom: 22px;
    font-weight: 500;
  }
  .result-h1 {
    font-family: var(--font-display); font-weight: 500; font-size: 36px;
    line-height: 1.1; letter-spacing: -0.025em;
    margin: 0 0 36px;
  }
  .result-h1 em { font-style: italic; color: var(--color-red); }
  .score-block {
    padding: 32px 0;
    border-top: 1px solid var(--color-line-2);
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 28px;
  }
  .score-big {
    font-family: var(--font-display); font-weight: 500;
    font-size: 76px; line-height: 1; letter-spacing: -0.04em;
    color: var(--color-blue);
  }
  .score-big .of { font-size: 32px; color: var(--color-muted-2); margin-left: 6px; }
  .score-pct {
    font-family: var(--font-mono); font-size: 14px;
    color: var(--color-muted); letter-spacing: 0.1em;
    margin-top: 6px;
  }
  .score-thresh {
    font-size: 13px; color: var(--color-muted); margin-top: 10px;
    max-width: 480px; margin-left: auto; margin-right: auto;
  }
  .result-msg {
    font-size: 16px; color: var(--color-ink-2);
    line-height: 1.6; margin: 0 0 32px;
    max-width: 480px; margin-left: auto; margin-right: auto;
  }
  .result-actions {
    display: flex; gap: 12px; justify-content: center; flex-wrap: wrap;
  }
  @media (max-width: 560px) {
    .result-card { padding: 36px 24px; }
    .result-h1 { font-size: 28px; }
    .score-big { font-size: 58px; }
  }
`;
