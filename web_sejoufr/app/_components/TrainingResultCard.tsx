"use client";

import Link from "next/link";
import type {AttemptResponse} from "@/lib/types";
import {Check} from "lucide-react";
import {
    PASS_FEATURES,
    PASS_OFFER_CTA,
    PASS_OFFER_PLAN,
    PASS_OFFER_TITLE,
    PASS_ONE_TIME_NOTE,
    PASS_SERIES_DONE_TITLE,
    passModuleOfExam,
    passSeriesDoneText,
} from "@/lib/passes";

/**
 * Carte de résultat affichée après finalisation d'une session d'entraînement.
 * Adapte le ton selon l'accès au module (pass ou non) et succès/échec.
 *
 * Utilisée par :
 *   - /entrainement (après finalisation interne — pas utilisé directement, on
 *     redirige vers la route [attemptId])
 *   - /entrainement/[attemptId] (résumé en fin de session ou attempt déjà finalisé)
 */
export function TrainingResultCard({
                                       attempt,
                                       isPremium,
                                       variant = "primary",
                                       lotReturnHref,
                                   }: {
    attempt: AttemptResponse;
    isPremium: boolean;
    /** "primary" = fin de session interactive. "resume" = attempt déjà finalisé. */
    variant?: "primary" | "resume";
    /** Si défini, la session est un lot : le CTA renvoie vers le détail du thème. */
    lotReturnHref?: string;
}) {
    const score = attempt.score ?? 0;
    const total = attempt.totalQuestions;
    const pct = total > 0 ? Math.round((score / total) * 100) : 0;
    const passed = pct >= 70;
    const passModule = passModuleOfExam(attempt.module);

    const tag = variant === "resume"
        ? "Session déjà terminée"
        : isPremium
            ? passed
                ? "Belle session"
                : "Continuez à pratiquer"
            : PASS_SERIES_DONE_TITLE;
    const tagClass = variant === "resume"
        ? "neutral"
        : passed
            ? "good"
            : "bad";

    return (
        <section className="trc-wrap">
            <div className="trc-card">
                <span className={`trc-tag ${tagClass}`}>{tag}</span>
                <h1>
                    {score} <span className="of">/ {total}</span>
                </h1>
                <p className="trc-pct">{pct} % de bonnes réponses</p>

                {!isPremium && variant === "primary" && (
                    <div className="trc-paywall">
                        <p className="trc-offer-title">
                            {PASS_OFFER_TITLE[passModule].lead}
                            <em>{PASS_OFFER_TITLE[passModule].em}</em>
                        </p>
                        <p className="trc-offer-text">{passSeriesDoneText(passModule, total)}</p>
                        <ul className="trc-offer-feats">
                            {PASS_FEATURES[passModule].map((f) => (
                                <li key={f}>
                                    <Check size={14} strokeWidth={2.4} aria-hidden/>
                                    <span>{f}</span>
                                </li>
                            ))}
                        </ul>
                        <p className="trc-offer-note">{PASS_ONE_TIME_NOTE}</p>
                    </div>
                )}

                <div className="trc-cta">
                    {lotReturnHref ? (
                        <>
                            <Link href="/dashboard" className="btn btn-ghost">
                                Accueil
                            </Link>
                            <Link href={lotReturnHref} className="btn btn-blue">
                                Retour au thème →
                            </Link>
                        </>
                    ) : (
                        <>
                            <Link href="/entrainement" className="btn btn-ghost">
                                ↻ Nouvel entraînement
                            </Link>
                            {isPremium ? (
                                <Link href="/dashboard" className="btn btn-blue">
                                    Accueil →
                                </Link>
                            ) : (
                                <Link
                                    href={`/paiement?plan=${PASS_OFFER_PLAN[passModule]}`}
                                    className="btn btn-red"
                                >
                                    {PASS_OFFER_CTA} →
                                </Link>
                            )}
                        </>
                    )}
                </div>
            </div>

            <style>{`
        .trc-wrap { padding: 56px 16px 80px; }
        .trc-card {
          max-width: 560px; margin: 0 auto;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 18px;
          padding: 44px 40px;
          text-align: center;
          box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
        }
        .trc-tag {
          display: inline-block;
          font-family: var(--font-mono); font-size: 11px;
          letter-spacing: 0.16em; text-transform: uppercase;
          padding: 6px 12px; border-radius: 100px;
          margin-bottom: 20px; font-weight: 600;
        }
        .trc-tag.good { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
        .trc-tag.bad { background: var(--color-red-light); color: var(--color-red-dark); }
        .trc-tag.neutral { background: var(--color-paper-2); color: var(--color-muted); }
        .trc-card h1 {
          font-family: var(--font-display); font-weight: 500;
          font-size: clamp(56px, 10vw, 80px); line-height: 1; letter-spacing: -0.04em;
          color: var(--color-blue);
          margin: 0 0 6px;
        }
        .trc-card h1 .of { font-size: 0.42em; color: var(--color-muted-2); }
        .trc-pct {
          font-family: var(--font-mono); font-size: 13px;
          color: var(--color-muted); letter-spacing: 0.1em;
          margin: 0 0 28px;
        }
        .trc-paywall {
          background: var(--color-paper);
          border-radius: 12px;
          padding: 14px 16px;
          margin-bottom: 24px;
          font-size: 13px; color: var(--color-muted);
          line-height: 1.55;
          border-left: 3px solid var(--color-red);
          text-align: left;
        }
        .trc-offer-title {
          margin: 0 0 6px;
          font-family: var(--font-display);
          font-size: 19px; font-weight: 500;
          letter-spacing: -0.01em;
          color: var(--color-ink);
        }
        .trc-offer-title em { font-style: italic; color: var(--color-red); }
        .trc-offer-text { margin: 0 0 10px; }
        .trc-offer-feats {
          list-style: none; margin: 0 0 10px; padding: 0;
          display: flex; flex-direction: column; gap: 6px;
          color: var(--color-ink-2);
        }
        .trc-offer-feats li { display: flex; align-items: flex-start; gap: 8px; }
        .trc-offer-feats svg { flex: none; margin-top: 3px; color: var(--color-green); }
        .trc-offer-note {
          margin: 0;
          font-family: var(--font-mono);
          font-size: 11px;
          color: var(--color-muted);
        }
        .trc-cta {
          display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;
        }
        @media (max-width: 560px) {
          .trc-card { padding: 32px 22px; }
        }
      `}</style>
        </section>
    );
}
