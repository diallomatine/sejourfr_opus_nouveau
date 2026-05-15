"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Brand } from "../_components/Brand";
import { ApiException, attemptApi } from "@/lib/api";
import type {
  AttemptResponse,
  AttemptQuestionResponse,
  Module as ModuleEnum,
} from "@/lib/types";

type Stage = "choice" | "briefing" | "running" | "result";

export default function ExamenBlancPage() {
  const [stage, setStage] = useState<Stage>("choice");
  const [module, setModule] = useState<ModuleEnum>("CIVIQUE");
  const [attempt, setAttempt] = useState<AttemptResponse | null>(null);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [selected, setSelected] = useState<Record<string, string[]>>({}); // attemptQuestionId -> choiceIds
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // ============ Démarrage ============
  function pickModule(m: ModuleEnum) {
    setModule(m);
    setStage("briefing");
    setError(null);
  }

  async function startExam() {
    setLoading(true);
    setError(null);
    try {
      // Note : sans compte, l'appel échouera en 401 si /api/attempts exige auth.
      // En production, on aurait soit /api/attempts/demo public, soit on force
      // l'inscription avant. Ici on tente et on affiche l'erreur si besoin.
      const a = await attemptApi.start(
        { type: "MOCK_EXAM", module },
        { auth: true },
      );
      setAttempt(a);
      setCurrentIdx(0);
      setSelected({});
      setSecondsLeft(a.timeLimitSeconds ?? null);
      setStage("running");
    } catch (err) {
      if (err instanceof ApiException && err.status === 401) {
        setError(
          "Pour passer un examen blanc, vous devez d'abord créer un compte gratuit. C'est rapide.",
        );
      } else if (err instanceof ApiException) {
        setError(err.message);
      } else {
        setError(
          "Le serveur d'examen est indisponible. Vérifiez que le backend tourne sur le port 8080.",
        );
      }
    } finally {
      setLoading(false);
    }
  }

  // ============ Timer ============
  useEffect(() => {
    if (stage !== "running" || secondsLeft == null) return;
    if (secondsLeft <= 0) {
      void finishExam();
      return;
    }
    const id = window.setTimeout(() => setSecondsLeft((s) => (s ?? 0) - 1), 1000);
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

  // ============ Réponse ============
  const currentAq: AttemptQuestionResponse | null = attempt
    ? attempt.questions[currentIdx] ?? null
    : null;

  function toggleChoice(choiceId: string) {
    if (!currentAq) return;
    setSelected((prev) => {
      const existing = prev[currentAq.id] ?? [];
      // Mode mono-sélection (typique QCM)
      return { ...prev, [currentAq.id]: [choiceId] };
    });
  }

  async function submitCurrent() {
    if (!currentAq || !attempt) return;
    const choiceIds = selected[currentAq.id] ?? [];
    if (choiceIds.length === 0) {
      // skip silencieux : on permet de passer sans répondre
      next();
      return;
    }
    try {
      await attemptApi.submitAnswer(attempt.id, {
        attemptQuestionId: currentAq.id,
        choiceIds,
      });
    } catch {
      // En MOCK_EXAM, on n'affiche pas de feedback. On garde silencieux pour ne pas
      // casser le flux, et le finish() reconstruira l'état au besoin.
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

  // ============ Compteurs ============
  const answeredCount = Object.values(selected).filter(
    (v) => v && v.length > 0,
  ).length;
  const totalQs = attempt?.totalQuestions ?? 0;
  const progressPct =
    attempt && totalQs > 0 ? ((currentIdx + 1) / totalQs) * 100 : 0;

  return (
    <>
      <NavBar />

      {stage === "choice" && (
        <ChoiceStage onPick={pickModule} />
      )}

      {stage === "briefing" && (
        <BriefingStage
          module={module}
          loading={loading}
          error={error}
          onStart={startExam}
          onBack={() => setStage("choice")}
        />
      )}

      {stage === "running" && attempt && currentAq && (
        <RunnerStage
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
        <ResultStage
          attempt={attempt}
          onReset={() => {
            setAttempt(null);
            setSelected({});
            setSecondsLeft(null);
            setCurrentIdx(0);
            setStage("choice");
          }}
        />
      )}
    </>
  );
}

// ============================================================================
// NAV BAR
// ============================================================================
function NavBar() {
  return (
    <nav
      style={{
        background: "#fff",
        borderBottom: "1px solid var(--color-line)",
        padding: "14px 28px",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        position: "sticky",
        top: 0,
        zIndex: 50,
      }}
    >
      <Brand />
      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <Link href="/connexion" className="btn btn-ghost">
          Se connecter
        </Link>
        <Link href="/inscription" className="btn">
          Créer un compte
        </Link>
      </div>
    </nav>
  );
}

// ============================================================================
// STAGE 1 — CHOICE
// ============================================================================
function ChoiceStage({ onPick }: { onPick: (m: ModuleEnum) => void }) {
  return (
    <>
      <header style={{ padding: "64px 0 24px", textAlign: "center" }}>
        <div className="container-x">
          <span className="eyebrow" style={{ display: "inline-block", marginBottom: 16 }}>
            Examen blanc gratuit
          </span>
          <h1 className="choice-h1">
            Testez votre niveau, <em>sans inscription.</em>
          </h1>
          <p className="choice-lede">
            Sélectionnez l'examen que vous souhaitez préparer. Vous pourrez
            sauvegarder votre score après en créant un compte gratuit.
          </p>
        </div>
      </header>

      <div className="container-x">
        <div className="choice-grid">
          <button
            type="button"
            className="choice-card"
            onClick={() => onPick("CIVIQUE")}
          >
            <span className="choice-tag">● Examen civique</span>
            <h3>Civique</h3>
            <p>
              Principes républicains, institutions, droits et devoirs, histoire,
              vie en société.
            </p>
            <div className="choice-stats">
              <div className="ch-stat"><div className="v">40</div><div className="l">Questions</div></div>
              <div className="ch-stat"><div className="v">45 min</div><div className="l">Durée</div></div>
              <div className="ch-stat"><div className="v">32/40</div><div className="l">Seuil</div></div>
            </div>
            <div className="choice-cta">
              Choisir le civique <span className="arrow">→</span>
            </div>
          </button>

          <button
            type="button"
            className="choice-card tcf"
            onClick={() => onPick("TCF")}
          >
            <span className="choice-tag">● TCF IRN</span>
            <h3>TCF IRN</h3>
            <p>
              Compréhension orale, écrite, structure de la langue. Niveaux A2,
              B1, B2.
            </p>
            <div className="choice-stats">
              <div className="ch-stat"><div className="v">3</div><div className="l">Épreuves</div></div>
              <div className="ch-stat"><div className="v">60 min</div><div className="l">Durée</div></div>
              <div className="ch-stat"><div className="v">A2 → B2</div><div className="l">Niveaux</div></div>
            </div>
            <div className="choice-cta">
              Choisir le TCF <span className="arrow">→</span>
            </div>
          </button>
        </div>
      </div>

      <style>{`
        .choice-h1 {
          font-family: var(--font-display); font-weight: 500; font-size: 44px;
          line-height: 1.05; letter-spacing: -0.025em; margin: 0 0 14px;
        }
        .choice-h1 em { font-style: italic; color: var(--color-red); }
        .choice-lede { color: var(--color-muted); font-size: 17px; margin: 0 auto; max-width: 560px; }
        .choice-grid {
          display: grid; grid-template-columns: 1fr 1fr; gap: 20px;
          padding: 48px 0 80px;
        }
        .choice-card {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          padding: 32px 28px;
          cursor: pointer;
          transition: all 0.2s;
          text-align: left;
          display: flex; flex-direction: column;
          font-family: inherit; color: inherit;
        }
        .choice-card:hover {
          border-color: var(--color-blue); transform: translateY(-4px);
          box-shadow: 0 24px 40px -20px rgba(30, 58, 140, 0.18);
        }
        .choice-card.tcf:hover { border-color: var(--color-red); box-shadow: 0 24px 40px -20px rgba(225, 55, 47, 0.18); }
        .choice-tag {
          display: inline-flex; align-items: center; gap: 6px;
          padding: 4px 10px;
          background: var(--color-blue-light); color: var(--color-blue);
          border-radius: 100px;
          font-family: var(--font-mono);
          font-size: 10px; letter-spacing: 0.12em; text-transform: uppercase;
          font-weight: 500;
          align-self: flex-start;
          margin-bottom: 18px;
        }
        .choice-card.tcf .choice-tag { background: var(--color-red-light); color: var(--color-red-dark); }
        .choice-card h3 {
          font-family: var(--font-display); font-weight: 500; font-size: 28px;
          margin: 0 0 8px; letter-spacing: -0.02em;
        }
        .choice-card p { color: var(--color-muted); font-size: 14.5px; margin: 0 0 22px; line-height: 1.5; }
        .choice-stats {
          display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px;
          padding: 16px 0;
          border-top: 1px solid var(--color-line-2);
          border-bottom: 1px solid var(--color-line-2);
          margin-bottom: 22px;
        }
        .ch-stat .v {
          font-family: var(--font-display); font-size: 20px; font-weight: 500;
          letter-spacing: -0.015em;
        }
        .ch-stat .l {
          font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.1em; text-transform: uppercase; color: var(--color-muted);
          margin-top: 2px;
        }
        .choice-cta { display: flex; align-items: center; gap: 8px; color: var(--color-blue); font-weight: 600; font-size: 14px; }
        .choice-card.tcf .choice-cta { color: var(--color-red); }
        .choice-cta .arrow { transition: transform 0.15s; }
        .choice-card:hover .arrow { transform: translateX(4px); }

        @media (max-width: 760px) {
          .choice-grid { grid-template-columns: 1fr; padding: 32px 0 60px; }
          .choice-h1 { font-size: 32px; }
        }
      `}</style>
    </>
  );
}

// ============================================================================
// STAGE 2 — BRIEFING
// ============================================================================
function BriefingStage({
  module,
  loading,
  error,
  onStart,
  onBack,
}: {
  module: ModuleEnum;
  loading: boolean;
  error: string | null;
  onStart: () => void;
  onBack: () => void;
}) {
  return (
    <section style={{ padding: "56px 0 80px" }}>
      <div className="container-x" style={{ maxWidth: 880 }}>
        <div className="brief-card">
          <div className="brief-head">
            <div className="tag">
              Examen blanc · {module === "CIVIQUE" ? "Civique" : "TCF IRN"}
            </div>
            <h2>
              Conditions <em>réelles</em>.<br />
              Pas de seconde chance.
            </h2>
            <p>
              Une fois lancé, le chronomètre court. Lisez attentivement les
              règles avant de démarrer.
            </p>
          </div>
          <div className="brief-body">
            <div className="brief-stats">
              <div className="brief-stat">
                <div className="l">Questions</div>
                <div className="v">40</div>
              </div>
              <div className="brief-stat">
                <div className="l">Temps</div>
                <div className="v">45 min</div>
              </div>
              <div className="brief-stat">
                <div className="l">Seuil de réussite</div>
                <div className="v green">32/40</div>
              </div>
              <div className="brief-stat">
                <div className="l">Tentatives</div>
                <div className="v">1 / mois</div>
              </div>
            </div>

            <div className="brief-rules">
              <h3>Règles de l'examen</h3>
              <ul>
                <li><span className="ico">1</span>Vous avez 45 minutes pour répondre aux 40 questions. Le chronomètre est visible en haut de l'écran.</li>
                <li><span className="ico">2</span>Une seule bonne réponse par question. Pas de pénalité pour les mauvaises réponses : il est préférable de tenter.</li>
                <li><span className="ico">3</span>Vous pouvez revenir en arrière et modifier vos réponses tant que le temps n'est pas écoulé.</li>
                <li><span className="ico">4</span>Vous ne verrez les corrections qu'à la fin de l'examen, comme en condition réelle.</li>
                <li><span className="ico">5</span>Si vous quittez la page, votre tentative est perdue. Préparez-vous au calme.</li>
              </ul>
            </div>

            <div className="brief-warn">
              <strong>Bon à savoir.</strong> Cet examen blanc est gratuit.{" "}
              <Link href="/inscription" style={{ color: "var(--color-blue)", textDecoration: "underline" }}>
                Créez un compte gratuit
              </Link>{" "}
              pour sauvegarder votre score, voir vos statistiques par thématique
              et accéder à 10 QCM par catégorie.
            </div>

            {error && <div className="form-error">{error}</div>}

            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <button onClick={onStart} disabled={loading} className="btn btn-red btn-lg">
                {loading ? "Préparation..." : "Démarrer l'examen"}
                <span>→</span>
              </button>
              <button type="button" onClick={onBack} className="btn btn-link-soft">
                ← Choisir un autre module
              </button>
            </div>
          </div>
        </div>
      </div>

      <style>{`
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
          font-family: var(--font-display); font-weight: 500; font-size: 36px;
          margin: 0 0 8px; letter-spacing: -0.02em; line-height: 1.1;
          color: #fff; position: relative;
        }
        .brief-head h2 em { font-style: italic; color: #ffb3b0; }
        .brief-head p { color: rgba(255, 255, 255, 0.7); font-size: 15px; margin: 0; max-width: 520px; position: relative; }

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
          font-family: var(--font-display); font-size: 28px; font-weight: 500;
          letter-spacing: -0.02em;
        }
        .brief-stat .v.green { color: var(--color-green); }

        .brief-rules h3 {
          font-family: var(--font-sans); font-weight: 700; font-size: 14px;
          margin: 0 0 16px; color: var(--color-ink);
        }
        .brief-rules ul {
          list-style: none; padding: 0; margin: 0 0 32px;
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

        .brief-warn {
          background: var(--color-blue-soft);
          border-left: 3px solid var(--color-blue);
          border-radius: 8px;
          padding: 14px 18px;
          font-size: 13.5px;
          color: var(--color-ink-2);
          line-height: 1.5;
          margin-bottom: 22px;
        }
        .brief-warn strong { color: var(--color-blue); font-weight: 600; }

        @media (max-width: 760px) {
          .brief-head { padding: 28px 24px; }
          .brief-head h2 { font-size: 28px; }
          .brief-body { padding: 28px 24px; }
          .brief-stats { grid-template-columns: 1fr 1fr; gap: 20px; }
        }
      `}</style>
    </section>
  );
}

// ============================================================================
// STAGE 3 — RUNNER
// ============================================================================
function RunnerStage({
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

      <style>{`
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
          margin: 0 0 28px;
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
      `}</style>
    </section>
  );
}

// ============================================================================
// STAGE 4 — RESULT
// ============================================================================
function ResultStage({
  attempt,
  onReset,
}: {
  attempt: AttemptResponse;
  onReset: () => void;
}) {
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const threshold = attempt.passThreshold ?? Math.ceil(total * 0.8);
  const passed = score >= threshold;
  const pct = Math.round((score / total) * 100);

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
              : "C'est un excellent indicateur des thématiques à travailler. Créez un compte gratuit pour identifier vos points faibles et progresser ciblé."}
          </p>

          <div className="result-actions">
            <Link href="/inscription" className="btn btn-red btn-lg">
              Créer un compte pour sauvegarder
            </Link>
            <button onClick={onReset} type="button" className="btn btn-ghost btn-lg">
              Recommencer
            </button>
          </div>
        </div>
      </div>

      <style>{`
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
          font-family: var(--font-display); font-weight: 500; font-size: 42px;
          line-height: 1.05; letter-spacing: -0.025em;
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
          font-size: 84px; line-height: 1; letter-spacing: -0.04em;
          color: var(--color-blue);
        }
        .score-big .of { font-size: 36px; color: var(--color-muted-2); margin-left: 6px; }
        .score-pct {
          font-family: var(--font-mono); font-size: 14px;
          color: var(--color-muted); letter-spacing: 0.1em;
          margin-top: 6px;
        }
        .score-thresh {
          font-size: 13px; color: var(--color-muted); margin-top: 10px;
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
          .result-h1 { font-size: 32px; }
          .score-big { font-size: 64px; }
        }
      `}</style>
    </section>
  );
}
