"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ApiException, attemptApi, publicAttemptApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
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
 *    jouable, quota DEMO_LIMIT_REACHED intercepté pour pousser au compte).
 */
export function ExamBriefingClient({ exam }: { exam: ExamTemplateSummary }) {
  const { status } = useAuth();
  if (status === "loading") return <div className="brf-loading" />;
  if (status === "authenticated") {
    return (
      <DualChromeShell>
        <ExamBriefingInner exam={exam} />
      </DualChromeShell>
    );
  }
  return <ExamBriefingInner exam={exam} />;
}

function ExamBriefingInner({ exam }: { exam: ExamTemplateSummary }) {
  const router = useRouter();
  const { user, status } = useAuth();
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPaywall, setShowPaywall] = useState(false);
  const [demoQuotaReached, setDemoQuotaReached] = useState(false);

  const isTcf = exam.module === "TCF";
  const minutes = Math.round(exam.durationSeconds / 60);
  const isGuest = status === "guest";
  const isPremiumForModule = user !== null && canAccessModule(user, exam.module);
  // Connecté : free OU premium pour ce module. Guest : seul un examen free est jouable.
  const accessGranted = isGuest ? exam.free : exam.free || isPremiumForModule;

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
          });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      if (
        e instanceof ApiException &&
        e.status === 429 &&
        e.payload?.error === "DEMO_LIMIT_REACHED"
      ) {
        setDemoQuotaReached(true);
      } else if (e instanceof ApiException && e.status === 403) {
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
                      Votre niveau CECRL (A2&nbsp;/&nbsp;B1&nbsp;/&nbsp;B2) est
                      calculé d&apos;après vos réussites sur chaque strate.
                    </div>
                  </li>
                )}
                <li>
                  <span className="ico">{isTcf ? 5 : 4}</span>
                  <div>
                    Vous pouvez revenir sur une question précédente avant de
                    terminer. Le score n&apos;est calculé qu&apos;à la fin.
                  </div>
                </li>
              </ol>
            </div>

            {error && <div className="form-error">{error}</div>}

            {demoQuotaReached ? (
              <div className="brf-paywall">
                <div>
                  <div className="brf-paywall-title">
                    Démo déjà utilisée ce mois-ci
                  </div>
                  <div className="brf-paywall-body">
                    Vous avez déjà passé un examen blanc{" "}
                    {isTcf ? "TCF" : "civique"} en démo ce mois-ci. Créez un
                    compte gratuit pour en passer plusieurs et conserver vos
                    résultats.
                  </div>
                </div>
                <Link href="/inscription" className="btn btn-red">
                  Créer mon compte →
                </Link>
              </div>
            ) : isGuest && !exam.free ? (
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
                      ? "Démarrer la démo →"
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
        plan={isTcf ? "INTEGRAL_3MOIS" : "CIVIQUE_3MOIS"}
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
`;
