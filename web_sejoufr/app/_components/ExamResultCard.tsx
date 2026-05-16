"use client";

import Link from "next/link";
import type { AttemptResponse, TargetLevel } from "@/lib/types";

/**
 * Carte de résultat affichée après finalisation d'un examen blanc.
 *
 * - Civique : comparaison score vs passThreshold → succès/échec.
 * - TCF : affichage du levelAchieved (A2/B1/B2 ou "< A2") + message contextuel.
 *
 * Utilisée par /sessions/[attemptId] et n'importe quelle page qui affiche un
 * attempt finalisé de type MOCK_EXAM.
 */
export function ExamResultCard({ attempt }: { attempt: AttemptResponse }) {
  const isTcf = attempt.module === "TCF";
  const score = attempt.score ?? 0;
  const total = attempt.totalQuestions;
  const pct = total > 0 ? Math.round((score / total) * 100) : 0;

  if (isTcf) {
    return <TcfResult attempt={attempt} score={score} pct={pct} />;
  }

  const threshold = attempt.passThreshold ?? Math.ceil(total * 0.8);
  const passed = score >= threshold;
  const wrong = total - score;

  return (
    <section className="erc-wrap">
      <div className="erc-card">
        <span className={`erc-tag ${passed ? "good" : "bad"}`}>
          {passed ? "● Examen réussi" : "● Pas encore atteint"}
        </span>

        <h1 className="erc-h1">
          {passed ? (
            <>Vous avez <em>réussi</em>.</>
          ) : (
            <>Pas encore <em>tout à fait</em>.</>
          )}
        </h1>

        <div className="erc-score-block">
          <div className="erc-score-big">
            {score}<span className="of">/ {total}</span>
          </div>
          <div className="erc-pct">{pct} % de bonnes réponses</div>
          <div className="erc-thresh">
            Seuil officiel&nbsp;: {threshold}/{total}
            {!passed && wrong > 0 && (
              <> · {threshold - score} bonne{threshold - score > 1 ? "s" : ""} manquante{threshold - score > 1 ? "s" : ""}</>
            )}
          </div>
        </div>

        <p className="erc-msg">
          {passed
            ? "Excellent travail. Continuez à varier les examens pour consolider votre niveau jusqu'au jour J."
            : "Un examen blanc raté est un bon indicateur des thématiques à retravailler. Repassez la révision ciblée, puis tentez un autre examen."}
        </p>

        <div className="erc-actions">
          <Link href="/examens-blancs" className="btn btn-red btn-lg">
            Voir les autres examens →
          </Link>
          <Link href="/dashboard" className="btn btn-ghost btn-lg">
            Tableau de bord
          </Link>
        </div>
      </div>
      <style>{styles}</style>
    </section>
  );
}

function TcfResult({
  attempt,
  score,
  pct,
}: {
  attempt: AttemptResponse;
  score: number;
  pct: number;
}) {
  const level: TargetLevel | null = attempt.levelAchieved;
  const heading = level ? `Niveau ${level}` : "Niveau inférieur à A2";
  const subtitle = level
    ? LEVEL_MESSAGES[level]
    : "Vous n'atteignez pas encore le seuil A2. Continuez à vous entraîner sur les fondamentaux.";

  return (
    <section className="erc-wrap">
      <div className="erc-card">
        <span className="erc-tag tcf">● Diagnostic TCF</span>

        <h1 className="erc-h1">
          Votre niveau estimé&nbsp;: <em>{heading}</em>
        </h1>

        <div className="erc-score-block">
          <div className="erc-score-big">
            {score}<span className="of">/ {attempt.totalQuestions}</span>
          </div>
          <div className="erc-pct">{pct} % de bonnes réponses</div>
          <div className="erc-thresh">{subtitle}</div>
        </div>

        <div className="erc-actions">
          <Link href="/examens-blancs?module=TCF" className="btn btn-red btn-lg">
            Refaire un diagnostic TCF →
          </Link>
          <Link href="/dashboard" className="btn btn-ghost btn-lg">
            Tableau de bord
          </Link>
        </div>
      </div>
      <style>{styles}</style>
    </section>
  );
}

const LEVEL_MESSAGES: Record<TargetLevel, string> = {
  A2: "A2 ouvre l'accès au titre de séjour (CSP). Continuez vers B1 pour la carte de résident.",
  B1: "B1 est requis pour la carte de résident. Visez B2 pour la naturalisation.",
  B2: "B2 est le niveau requis pour la naturalisation. Bravo, vous y êtes.",
};

const styles = `
  .erc-wrap { padding: 56px 16px 80px; }
  .erc-card {
    max-width: 640px; margin: 0 auto;
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 44px 40px;
    text-align: center;
    box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
  }
  .erc-tag {
    display: inline-block;
    font-family: var(--font-mono); font-size: 11px;
    letter-spacing: 0.16em; text-transform: uppercase;
    padding: 6px 12px; border-radius: 100px;
    margin-bottom: 22px; font-weight: 600;
  }
  .erc-tag.good { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .erc-tag.bad { background: var(--color-red-light); color: var(--color-red-dark); }
  .erc-tag.tcf { background: var(--color-blue-light); color: var(--color-blue); }
  .erc-h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(28px, 4vw, 36px); line-height: 1.1; letter-spacing: -0.025em;
    margin: 0 0 28px;
  }
  .erc-h1 em { font-style: italic; color: var(--color-red); }
  .erc-score-block {
    padding: 24px 0;
    border-top: 1px solid var(--color-line-2);
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 24px;
  }
  .erc-score-big {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(60px, 11vw, 86px);
    line-height: 1; letter-spacing: -0.04em;
    color: var(--color-blue);
  }
  .erc-score-big .of {
    font-size: 0.42em; color: var(--color-muted-2); margin-left: 8px;
  }
  .erc-pct {
    font-family: var(--font-mono); font-size: 13px;
    color: var(--color-muted); letter-spacing: 0.1em;
    margin-top: 8px;
  }
  .erc-thresh {
    font-size: 13px; color: var(--color-muted);
    margin: 10px auto 0; max-width: 460px; line-height: 1.5;
  }
  .erc-msg {
    font-size: 15px; color: var(--color-ink-2); line-height: 1.6;
    margin: 0 auto 28px; max-width: 480px;
  }
  .erc-actions {
    display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;
  }
  @media (max-width: 560px) {
    .erc-card { padding: 32px 22px; }
  }
`;
