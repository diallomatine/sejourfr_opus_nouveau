"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ApiException, attemptApi, publicAttemptApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type AttemptSummaryResponse,
  type ExamTemplateSummary,
} from "@/lib/types";

/**
 * Page de briefing d'un examen blanc : présentation, stats, règles. Au clic
 * "Démarrer", on POST l'attempt (auth ou /api/public/attempts/demo selon
 * l'utilisateur) et on redirige vers /sessions/<attemptId>.
 *
 * Dual-mode :
 *  - utilisateur connecté : attemptApi.start + gating premium/paywall classique
 *  - visiteur guest : publicAttemptApi.startDemo (seul un examen free est
 *    jouable, démo illimitée mais déterministe — mêmes questions à chaque
 *    lancement, l'objectif est de convertir).
 */
export function ExamBriefingClient({
  exam,
  slotNumber,
}: {
  exam: ExamTemplateSummary;
  slotNumber?: number;
}) {
  const { status } = useAuth();
  if (status === "loading") return <div className="brf-loading" />;
  if (status === "authenticated") {
    return (
      <DualChromeShell>
        <ExamBriefingInner exam={exam} slotNumber={slotNumber} />
      </DualChromeShell>
    );
  }
  return <ExamBriefingInner exam={exam} slotNumber={slotNumber} />;
}

function ExamBriefingInner({
  exam,
  slotNumber,
}: {
  exam: ExamTemplateSummary;
  slotNumber?: number;
}) {
  const router = useRouter();
  const { user, status } = useAuth();
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPaywall, setShowPaywall] = useState(false);
  const [pastAttempts, setPastAttempts] = useState<AttemptSummaryResponse[]>([]);

  const isTcf = exam.module === "TCF";
  const minutes = Math.round(exam.durationSeconds / 60);
  const isGuest = status === "guest";
  const isPremiumForModule = user !== null && canAccessModule(user, exam.module);
  // Connecté : free OU premium pour ce module. Guest : seul un examen free est jouable.
  const accessGranted = isGuest ? exam.free : exam.free || isPremiumForModule;

  // On charge les tentatives passées sur CET examen pour proposer "voir
  // détails" + "refaire" si l'utilisateur l'a déjà passé. Aucun appel en mode
  // guest (pas de compte → pas d'historique).
  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    attemptApi
      .listMine({ type: "MOCK_EXAM", module: exam.module, limit: 100 })
      .then((list) => {
        if (cancelled) return;
        setPastAttempts(
          list.filter((a) => {
            if (a.examTemplateId !== exam.id || !a.finishedAt) return false;
            // TCF : ne compter que les attempts avec un niveau CECRL calculé
            // (la calibration backend tourne uniquement si ≥ 1 réponse soumise).
            // Exclut les sessions abandonnées / auto-finalisées à 0.
            if (exam.module === "TCF") return a.cecrlLevel != null;
            return true;
          }),
        );
      })
      .catch(() => {
        /* silencieux : pas de blocage si l'historique échoue */
      });
    return () => {
      cancelled = true;
    };
  }, [status, exam.id, exam.module]);

  const lastAttempt = pastAttempts.length > 0
    ? [...pastAttempts].sort(
        (a, b) =>
          new Date(b.finishedAt ?? 0).getTime() -
          new Date(a.finishedAt ?? 0).getTime(),
      )[0]
    : null;
  const bestScore = pastAttempts.reduce(
    (best, a) => Math.max(best, a.score ?? 0),
    0,
  );
  const isPassed =
    !isTcf && lastAttempt && exam.passingScore
      ? (lastAttempt.score ?? 0) >= exam.passingScore
      : null;

  async function startExam() {
    if (!accessGranted) {
      setShowPaywall(true);
      return;
    }
    setError(null);
    setStarting(true);
    try {
      const a = isGuest
        ? await publicAttemptApi.startDemo({
            type: "MOCK_EXAM",
            module: exam.module,
            examTemplateId: exam.id,
          })
        : await attemptApi.start({
            type: "MOCK_EXAM",
            module: exam.module,
            examTemplateId: exam.id,
            slotNumber,
          });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) {
        setShowPaywall(true);
      } else {
        setError(e instanceof ApiException ? e.message : "Démarrage impossible.");
      }
      setStarting(false);
    }
  }

  return (
    <main className="brf">
      <div className="brf-wrap">
        <Link href="/examens-blancs" className="brf-back">
          ← Tous les examens
        </Link>

        <div className="brf-card">
          <div className="brf-head">
            <span className={`brf-tag ${isTcf ? "tcf" : "civique"}`}>
              {isTcf ? "TCF IRN" : "Examen civique"}
              {exam.free ? " · Offert" : " · Abonnés"}
            </span>
            <h1>{exam.name}</h1>
            {exam.subtitle && <p className="brf-subtitle">{exam.subtitle}</p>}
            {exam.description && (
              <p className="brf-desc">{exam.description}</p>
            )}
          </div>

          <div className="brf-body">
            <div className="brf-stats">
              <div className="brf-stat">
                <div className="l">Questions</div>
                <div className="v">{exam.totalQuestions}</div>
              </div>
              <div className="brf-stat">
                <div className="l">Durée</div>
                <div className="v">{minutes} min</div>
              </div>
              {!isTcf && (
                <div className="brf-stat">
                  <div className="l">Seuil de réussite</div>
                  <div className="v green">
                    {exam.passingScore}/{exam.totalQuestions}
                  </div>
                </div>
              )}
              {isTcf && (
                <div className="brf-stat">
                  <div className="l">Restitution</div>
                  <div className="v">Niveau CECRL</div>
                </div>
              )}
              <div className="brf-stat">
                <div className="l">Cible</div>
                <div className="v">
                  {exam.module === "CIVIQUE"
                    ? (exam.targetProcedure ?? "Tous parcours")
                    : (exam.targetLevel ?? "Diagnostic")}
                </div>
              </div>
            </div>

            {isTcf && (
              <div className="brf-deroule-block">
                <div className="brf-section-label">LES 4 ÉPREUVES DU TCF IRN</div>
                <div className="brf-deroule">
                  <div className="brf-dr-row">
                    <span className="brf-dr-ico" aria-hidden>🎧</span>
                    <span className="brf-dr-label">Compréhension orale</span>
                    <span className="brf-dr-meta">25 questions · 20 min</span>
                  </div>
                  <div className="brf-dr-row">
                    <span className="brf-dr-ico" aria-hidden>📖</span>
                    <span className="brf-dr-label">Compréhension écrite</span>
                    <span className="brf-dr-meta">25 questions · 35 min</span>
                  </div>
                  {isGuest ? (
                    <>
                      {/* Guest : EE/EO exigent un compte — rangées grisées,
                          pas de lien vers leurs examens. */}
                      <div className="brf-dr-row is-prod is-locked">
                        <span className="brf-dr-ico" aria-hidden>✍️</span>
                        <span className="brf-dr-label">Expression écrite</span>
                        <span className="brf-dr-badge">🔒 Compte requis</span>
                      </div>
                      <div className="brf-dr-row is-prod is-locked">
                        <span className="brf-dr-ico" aria-hidden>🎙️</span>
                        <span className="brf-dr-label">Expression orale</span>
                        <span className="brf-dr-badge">🔒 Compte requis</span>
                      </div>
                    </>
                  ) : (
                    <>
                      <Link href="/entrainement/tcf/ee/examens" className="brf-dr-row is-prod">
                        <span className="brf-dr-ico" aria-hidden>✍️</span>
                        <span className="brf-dr-label">Expression écrite</span>
                        <span className="brf-dr-badge">Épreuve dédiée · IA →</span>
                      </Link>
                      <Link href="/entrainement/tcf/eo/examens" className="brf-dr-row is-prod">
                        <span className="brf-dr-ico" aria-hidden>🎙️</span>
                        <span className="brf-dr-label">Expression orale</span>
                        <span className="brf-dr-badge">Épreuve dédiée · IA →</span>
                      </Link>
                    </>
                  )}
                </div>
                {isGuest ? (
                  <p className="brf-mobile-note">
                    Sans compte, cet examen couvre les épreuves de{" "}
                    <strong>compréhension</strong> (orale puis écrite).
                    L&apos;<strong>expression écrite et orale</strong>, évaluées
                    par l&apos;IA, ne sont pas disponibles en démo —{" "}
                    <Link href="/inscription?next=/examens-blancs">
                      créez un compte gratuit
                    </Link>{" "}
                    pour les passer. Le niveau <strong>CECRL global</strong> du
                    TCF IRN se calcule sur les 4 épreuves.
                  </p>
                ) : (
                  <p className="brf-mobile-note">
                    Cet examen couvre les épreuves de <strong>compréhension</strong>{" "}
                    (orale + écrite). L&apos;<strong>expression écrite et orale</strong>,
                    évaluées par l&apos;IA, se passent aussi sur le web — depuis leurs
                    examens blancs dédiés (liens ci-dessus). Le niveau{" "}
                    <strong>CECRL global</strong> du TCF IRN se calcule sur les 4
                    épreuves.
                  </p>
                )}
              </div>
            )}

            {lastAttempt && (
              <div className="brf-past">
                <div className="brf-past-icon" aria-hidden>
                  <svg
                    viewBox="0 0 24 24"
                    width="20"
                    height="20"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M9 11l3 3L22 4" />
                    <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
                  </svg>
                </div>
                <div className="brf-past-body">
                  <div className="brf-past-title">
                    Vous avez déjà passé cet examen
                    {isPassed === true && (
                      <span className="brf-past-tag tag-pass">RÉUSSI</span>
                    )}
                    {isPassed === false && (
                      <span className="brf-past-tag tag-fail">À RETRAVAILLER</span>
                    )}
                  </div>
                  <div className="brf-past-stats">
                    {isTcf ? (
                      <span>
                        Dernier niveau :{" "}
                        <strong>
                          {lastAttempt.cecrlLevel ??
                            `${lastAttempt.calibratedScore ?? lastAttempt.score ?? 0}/499`}
                        </strong>
                      </span>
                    ) : (
                      <span>
                        Dernier score :{" "}
                        <strong>
                          {lastAttempt.score}/{lastAttempt.totalQuestions}
                        </strong>
                      </span>
                    )}
                    {pastAttempts.length > 1 && (
                      <>
                        <span className="dot">·</span>
                        {isTcf ? (
                          <span>{pastAttempts.length} tentatives</span>
                        ) : (
                          <>
                            <span>
                              Meilleur : <strong>{bestScore}/{exam.totalQuestions}</strong>
                            </span>
                            <span className="dot">·</span>
                            <span>{pastAttempts.length} tentatives</span>
                          </>
                        )}
                      </>
                    )}
                  </div>
                </div>
                <Link
                  href={`/sessions/${lastAttempt.id}`}
                  className="btn btn-ghost brf-past-cta"
                >
                  Voir détails →
                </Link>
              </div>
            )}

            <div className="brf-rules">
              <h3>Règles de l&apos;examen</h3>
              <ol>
                <li>
                  <span className="ico">1</span>
                  <div>
                    Vous avez <strong>{minutes} minutes</strong> pour répondre aux{" "}
                    {exam.totalQuestions} questions. Un chronomètre reste visible en haut.
                  </div>
                </li>
                <li>
                  <span className="ico">2</span>
                  <div>
                    Une seule bonne réponse par question. Pas de pénalité pour les
                    mauvaises&nbsp;: tentez toujours.
                  </div>
                </li>
                <li>
                  <span className="ico">3</span>
                  <div>
                    Les corrections n&apos;apparaissent qu&apos;à la fin, comme en
                    conditions réelles.
                  </div>
                </li>
                {isTcf && (
                  <li>
                    <span className="ico">4</span>
                    <div>
                      L&apos;examen enchaîne deux parties, comme le vrai
                      TCF&nbsp;: la <strong>compréhension orale</strong>
                      d&apos;abord, puis la <strong>compréhension écrite</strong>.
                      Un écran vous annonce chaque partie. En orale, chaque
                      audio se lance seul et n&apos;est joué qu&apos;<strong>une
                      seule fois</strong> — pas de pause ni de réécoute.
                    </div>
                  </li>
                )}
                {isTcf && (
                  <li>
                    <span className="ico">5</span>
                    <div>
                      Votre niveau CECRL (A2&nbsp;/&nbsp;B1&nbsp;/&nbsp;B2) est
                      calculé d&apos;après vos réussites sur chaque strate.
                    </div>
                  </li>
                )}
                <li>
                  <span className="ico">{isTcf ? 6 : 4}</span>
                  <div>
                    {isTcf ? (
                      <>
                        Vous pouvez revenir sur une question précédente avant de
                        terminer — sauf en compréhension orale (une question
                        passée ne se rejoue pas). Le score n&apos;est calculé
                        qu&apos;à la fin.
                      </>
                    ) : (
                      <>
                        Comme le jour de l&apos;examen, vous ne pouvez{" "}
                        <strong>pas revenir en arrière</strong>&nbsp;: une
                        réponse validée est définitive. Le score n&apos;est
                        calculé qu&apos;à la fin.
                      </>
                    )}
                  </div>
                </li>
              </ol>
            </div>

            {error && <div className="form-error">{error}</div>}

            {isGuest && !exam.free ? (
              <div className="brf-paywall">
                <div>
                  <div className="brf-paywall-title">
                    Cet examen est réservé aux comptes abonnés
                  </div>
                  <div className="brf-paywall-body">
                    En démo gratuite, vous pouvez passer un examen marqué{" "}
                    <strong>Offert</strong>. Créez un compte pour accéder à
                    tous les examens (CSP, CR, naturalisation, A2/B1/B2).
                  </div>
                </div>
                <Link href="/inscription" className="btn btn-red">
                  Créer un compte →
                </Link>
              </div>
            ) : !accessGranted ? (
              <div className="brf-paywall">
                <div>
                  <div className="brf-paywall-title">Cet examen est réservé aux abonnés</div>
                  <div className="brf-paywall-body">
                    {isTcf
                      ? "L'abonnement Intégral débloque tous les examens TCF + Civique illimité + révision des erreurs."
                      : "L'abonnement débloque tous les examens civiques + l'entraînement illimité + la révision des erreurs."}
                  </div>
                </div>
                <button
                  type="button"
                  className="btn btn-red"
                  onClick={() => setShowPaywall(true)}
                >
                  Voir l&apos;abonnement →
                </button>
              </div>
            ) : (
              <div className="brf-cta-row">
                <button
                  type="button"
                  className="btn btn-red btn-lg"
                  onClick={startExam}
                  disabled={starting}
                >
                  {starting
                    ? "Préparation…"
                    : isGuest
                      ? "Commencer →"
                      : lastAttempt
                        ? "Refaire l'examen →"
                        : "Démarrer l'examen →"}
                </button>
                <Link href="/examens-blancs" className="btn btn-ghost">
                  Choisir un autre
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>

      <PaywallSheet
        open={showPaywall}
        onClose={() => setShowPaywall(false)}
        title={
          isTcf
            ? "Débloquez tous les examens TCF"
            : "Débloquez tous les examens civiques"
        }
        message={
          isTcf
            ? "1 examen TCF offert pour découvrir. L'abonnement Intégral débloque le reste + tout le civique + la révision."
            : "1 examen civique offert. L'abonnement débloque CSP, CR, Naturalisation, l'entraînement illimité et la révision."
        }
        module={isTcf ? "INTEGRAL" : "CIVIQUE"}
      />

      <style>{styles}</style>
    </main>
  );
}

const styles = `
  .brf { background: var(--color-paper); min-height: calc(100vh - 110px); padding: 32px 16px 80px; }
  .brf-loading { min-height: 60vh; }
  .brf-gate {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 14px; color: var(--color-muted);
  }
  .brf-wrap { max-width: 760px; margin: 0 auto; }

  /* ===== Déroulé TCF complet (4 épreuves) — aligné sur le mobile ===== */
  .brf-deroule-block { margin: 4px 0 22px; }
  .brf-section-label {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    letter-spacing: 0.16em; color: var(--color-muted);
    margin-bottom: 10px;
  }
  .brf-deroule { display: flex; flex-direction: column; gap: 8px; }
  .brf-dr-row {
    display: flex; align-items: center; gap: 12px;
    background: var(--color-blue-soft);
    border-radius: 12px; padding: 12px 14px;
  }
  .brf-dr-ico { font-size: 18px; line-height: 1; flex-shrink: 0; }
  .brf-dr-label {
    flex: 1; min-width: 0; font-weight: 700; font-size: 14px;
    color: var(--color-ink);
  }
  .brf-dr-meta {
    font-family: var(--font-sans); font-weight: 800; font-size: 12.5px;
    color: var(--color-blue); flex-shrink: 0;
  }
  .brf-dr-row.is-prod {
    background: var(--color-paper-2);
    text-decoration: none;
    transition: background 0.15s;
  }
  .brf-dr-row.is-prod:hover { background: var(--color-blue-light); }
  .brf-dr-row.is-locked { opacity: 0.75; }
  .brf-dr-row.is-locked:hover { background: var(--color-paper-2); }
  .brf-dr-row.is-locked .brf-dr-label { color: var(--color-muted); }
  .brf-mobile-note a { color: var(--color-blue); font-weight: 700; }
  .brf-dr-badge {
    flex-shrink: 0;
    font-family: var(--font-mono); font-size: 9.5px; font-weight: 700;
    letter-spacing: 0.06em; text-transform: uppercase;
    color: var(--color-blue);
    background: #fff; border: 1px solid var(--color-line);
    padding: 4px 9px; border-radius: 100px;
  }
  .brf-mobile-note {
    margin: 12px 0 0;
    font-size: 13px; line-height: 1.55; color: var(--color-muted);
    background: var(--color-blue-soft);
    border-left: 3px solid var(--color-blue);
    border-radius: 10px; padding: 12px 14px;
  }
  .brf-mobile-note strong { color: var(--color-ink); font-weight: 700; }

  .brf-back {
    display: inline-block;
    color: var(--color-muted);
    text-decoration: none;
    font-size: 13px;
    margin-bottom: 16px;
    transition: color 0.15s;
  }
  .brf-back:hover { color: var(--color-blue); }

  .brf-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    overflow: hidden;
    box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.18);
  }
  .brf-head {
    background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
    color: #fff;
    padding: 32px 36px;
    position: relative;
    overflow: hidden;
  }
  .brf-head::before {
    content: '';
    position: absolute; top: -100px; right: -80px;
    width: 280px; height: 280px;
    background: radial-gradient(circle, rgba(225, 55, 47, 0.32), transparent 70%);
    pointer-events: none;
  }
  .brf-tag {
    display: inline-block;
    font-family: var(--font-mono); font-size: 10px;
    letter-spacing: 0.14em; text-transform: uppercase;
    padding: 4px 10px; border-radius: 4px;
    margin-bottom: 14px;
    font-weight: 700;
    position: relative;
  }
  .brf-tag.civique { background: rgba(255, 255, 255, 0.15); color: #fff; }
  .brf-tag.tcf { background: rgba(225, 55, 47, 0.32); color: #fff; }

  .brf-head h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: clamp(24px, 4vw, 32px);
    line-height: 1.15; letter-spacing: -0.02em;
    margin: 0 0 8px;
    color: #fff;
    position: relative;
  }
  .brf-subtitle {
    font-size: 15px;
    color: rgba(255, 255, 255, 0.85);
    margin: 0 0 6px;
    position: relative;
  }
  .brf-desc {
    font-size: 14px;
    color: rgba(255, 255, 255, 0.7);
    line-height: 1.55;
    margin: 8px 0 0;
    max-width: 580px;
    position: relative;
  }

  .brf-body { padding: 32px 36px; }
  .brf-stats {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
    padding-bottom: 26px;
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 26px;
  }
  @media (max-width: 640px) {
    .brf-stats { grid-template-columns: repeat(2, 1fr); }
    .brf-head { padding: 26px 22px; }
    .brf-body { padding: 24px 22px; }
  }
  .brf-stat .l {
    font-family: var(--font-mono); font-size: 9.5px;
    letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--color-muted); font-weight: 600;
    margin-bottom: 6px;
  }
  .brf-stat .v {
    font-family: var(--font-display); font-weight: 500;
    font-size: 22px; line-height: 1; letter-spacing: -0.02em;
    color: var(--color-ink);
  }
  .brf-stat .v.green { color: var(--color-green); }

  .brf-rules h3 {
    font-family: var(--font-sans); font-weight: 800; font-size: 13px;
    text-transform: uppercase; letter-spacing: 0.08em;
    color: var(--color-muted);
    margin: 0 0 14px;
  }
  .brf-rules ol {
    list-style: none; padding: 0; margin: 0 0 24px;
    display: flex; flex-direction: column; gap: 10px;
  }
  .brf-rules li {
    display: flex; gap: 12px; align-items: flex-start;
    font-size: 14px; line-height: 1.55; color: var(--color-ink-2);
  }
  .brf-rules li strong { color: var(--color-ink); font-weight: 700; }
  .brf-rules .ico {
    width: 22px; height: 22px;
    border-radius: 50%;
    background: var(--color-blue-light); color: var(--color-blue);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0; margin-top: 1px;
    font-family: var(--font-mono); font-size: 10.5px; font-weight: 700;
  }

  .brf-paywall {
    display: flex; align-items: center; justify-content: space-between;
    gap: 16px; flex-wrap: wrap;
    background: var(--color-blue-soft);
    border: 1px solid var(--color-blue-light);
    border-left: 3px solid var(--color-blue);
    border-radius: 12px;
    padding: 16px 18px;
  }
  .brf-paywall-title {
    font-weight: 700; font-size: 14.5px; color: var(--color-ink);
    margin-bottom: 4px;
  }
  .brf-paywall-body {
    font-size: 13px; color: var(--color-muted); line-height: 1.5;
    max-width: 440px;
  }

  .brf-cta-row {
    display: flex; gap: 10px; flex-wrap: wrap; align-items: center;
  }

  .brf-past {
    display: flex; align-items: center; gap: 14px;
    background: rgba(22, 143, 91, 0.06);
    border: 1px solid rgba(22, 143, 91, 0.28);
    border-left: 3px solid var(--color-green);
    border-radius: 12px;
    padding: 14px 16px;
    margin-bottom: 24px;
    flex-wrap: wrap;
  }
  .brf-past-icon {
    width: 38px; height: 38px;
    flex-shrink: 0;
    border-radius: 50%;
    background: var(--color-green);
    color: #fff;
    display: flex; align-items: center; justify-content: center;
  }
  .brf-past-body { flex: 1; min-width: 0; }
  .brf-past-title {
    font-weight: 700; font-size: 14px;
    color: var(--color-ink); margin-bottom: 4px;
    display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
  }
  .brf-past-tag {
    font-family: var(--font-mono);
    font-size: 9.5px;
    letter-spacing: 0.12em;
    padding: 3px 7px;
    border-radius: 100px;
    font-weight: 700;
  }
  .tag-pass { background: rgba(22, 143, 91, 0.12); color: var(--color-green); }
  .tag-fail { background: var(--color-red-light); color: var(--color-red); }
  .brf-past-stats {
    font-size: 13px;
    color: var(--color-muted);
    display: flex; gap: 6px; flex-wrap: wrap; align-items: center;
  }
  .brf-past-stats strong { color: var(--color-ink); font-weight: 700; }
  .brf-past-stats .dot { opacity: 0.5; }
  .brf-past-cta {
    flex-shrink: 0;
    padding: 8px 14px;
    background: #fff;
    border: 1px solid var(--color-line);
    color: var(--color-green);
    border-radius: 10px;
    font-weight: 700;
    font-size: 13px;
    text-decoration: none;
    transition: all 0.15s;
  }
  .brf-past-cta:hover { background: var(--color-green); color: #fff; border-color: var(--color-green); }
`;
