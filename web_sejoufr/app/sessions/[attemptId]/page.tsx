"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, use, useEffect, useState } from "react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import {
  QuestionRunner,
  type RunnerBackend,
} from "@/app/_components/QuestionRunner";
import { TrainingResultCard } from "@/app/_components/TrainingResultCard";
import { ExamResultCard } from "@/app/_components/ExamResultCard";
import { ExamReport } from "@/app/_components/ExamReport";
import {
  ApiException,
  attemptApi,
  publicAttemptApi,
  userContentApi,
} from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { AttemptResponse } from "@/lib/types";

interface PageProps {
  params: Promise<{ attemptId: string }>;
}

type Phase = "loading" | "running" | "result" | "error";
/** "auth" = attempt récupéré via endpoints authentifiés ; "guest" = via /api/public. */
type SessionMode = "auth" | "guest";

const PREMIUM_BATCH_SIZE = 30;

const GUEST_BACKEND: RunnerBackend = {
  submitAnswer: (id, body) => publicAttemptApi.submitAnswer(id, body),
  finish: (id) => publicAttemptApi.finish(id),
  // Pas d'extension ni de favoris pour la démo guest : volontairement omis
  // pour cacher les fonctionnalités réservées aux comptes.
};

/** Chemin de retour après un lot, dérivé du module/épreuve de l'attempt :
 *  civique → détail du thème, TCF → page lots de l'épreuve × niveau. */
function lotReturnPath(attempt: AttemptResponse): string | null {
  const q = attempt.questions[0]?.question;
  if (!q) return null;
  if (attempt.module === "CIVIQUE") {
    return q.themeId ? `/entrainement/civique/${q.themeId}` : null;
  }
  const code = q.questionType?.toLowerCase();
  const level = q.difficulty?.toLowerCase();
  if (code && level && (code === "co" || code === "ce" || code === "structure")) {
    return `/entrainement/tcf/${code}/${level}`;
  }
  return null;
}

/**
 * Page générique d'une session : training ou examen blanc. Le type de
 * l'attempt détermine le mode du runner et la carte de résultat à afficher.
 *
 * Dual-mode :
 *  - utilisateur connecté → attemptApi.get + flux complet (favoris, extension)
 *  - visiteur guest → publicAttemptApi.getById (IP must match) + démo limitée
 */
export default function SessionRunnerPage({ params }: PageProps) {
  return (
    <Suspense fallback={<div className="sess-loading" />}>
      <SessionRunnerGate params={params} />
    </Suspense>
  );
}

function SessionRunnerGate({ params }: PageProps) {
  const { status } = useAuth();
  if (status === "loading") return <div className="sess-loading" />;
  if (status === "authenticated") {
    return (
      <DualChromeShell>
        <SessionRunnerInner params={params} />
      </DualChromeShell>
    );
  }
  return <SessionRunnerInner params={params} />;
}

function SessionRunnerInner({ params }: PageProps) {
  const { attemptId } = use(params);
  const { user, status } = useAuth();
  const isPremium = user?.isPremium ?? false;
  const searchParams = useSearchParams();
  /** Numéro de lot quand la session est un lot d'entraînement (batch fixe, pas d'extension). */
  const lotParam = searchParams.get("lot");
  const lotNumero = lotParam && /^\d+$/.test(lotParam) ? Number(lotParam) : null;

  const [phase, setPhase] = useState<Phase>("loading");
  const [sessionMode, setSessionMode] = useState<SessionMode>("auth");
  const [attempt, setAttempt] = useState<AttemptResponse | null>(null);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  /** True si l'attempt était déjà finalisé à l'ouverture (reprise sur session close). */
  const [openedAsFinished, setOpenedAsFinished] = useState(false);

  useEffect(() => {
    if (status === "loading") return;
    let cancelled = false;
    (async () => {
      try {
        // Stratégie : si connecté, on tente d'abord l'endpoint auth. En cas
        // de 404/403 on retombe sur le public (cas exotique : connecté mais
        // attempt créé en guest avant login). Pour un guest, on va direct
        // sur le public.
        let a: AttemptResponse | null = null;
        let mode: SessionMode = "auth";

        if (status === "authenticated") {
          try {
            a = await attemptApi.get(attemptId);
          } catch (e) {
            if (
              e instanceof ApiException &&
              (e.status === 404 || e.status === 403)
            ) {
              try {
                a = await publicAttemptApi.getById(attemptId);
                mode = "guest";
              } catch {
                throw e;
              }
            } else {
              throw e;
            }
          }
        } else {
          a = await publicAttemptApi.getById(attemptId);
          mode = "guest";
        }

        if (cancelled || !a) return;
        setSessionMode(mode);

        if (a.finishedAt) {
          setAttempt(a);
          setOpenedAsFinished(true);
          setPhase("result");
          return;
        }

        // Favoris : seulement en mode auth (l'API publique n'expose pas /me).
        if (mode === "auth") {
          try {
            const favList = await userContentApi.favorites(a.module);
            if (!cancelled) setFavoriteIds(new Set(favList.map((q) => q.id)));
          } catch {
            // best-effort
          }
        }
        if (cancelled) return;
        setAttempt(a);
        setPhase("running");
      } catch (e) {
        if (cancelled) return;
        setErrorMsg(e instanceof ApiException ? e.message : "Session introuvable.");
        setPhase("error");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [attemptId, status]);

  if (status === "loading" || phase === "loading") {
    return <div className="sess-loading" />;
  }

  if (phase === "error") {
    const fallbackHref =
      status === "authenticated" ? "/dashboard" : "/entrainement";
    const fallbackLabel =
      status === "authenticated"
        ? "Retour au tableau de bord →"
        : "Retour à l'entraînement →";
    return (
      <main className="sess-error">
        <h1>Session indisponible</h1>
        <p>{errorMsg ?? "Cette session n'existe plus."}</p>
        <Link href={fallbackHref} className="btn btn-blue">
          {fallbackLabel}
        </Link>
        <style>{errorStyles}</style>
      </main>
    );
  }

  if (phase === "result" && attempt) {
    const isExam = attempt.type === "MOCK_EXAM";
    const isGuest = sessionMode === "guest";
    const lotReturnHref =
      lotNumero != null && !isGuest ? (lotReturnPath(attempt) ?? undefined) : undefined;
    return (
      <main className="sess">
        {isExam ? (
          <>
            <ExamResultCard attempt={attempt} />
            <ExamReport attempt={attempt} />
            {isGuest && <GuestResultCta />}
          </>
        ) : (
          <>
            <TrainingResultCard
              attempt={attempt}
              isPremium={isPremium}
              variant={openedAsFinished ? "resume" : "primary"}
              lotReturnHref={lotReturnHref}
            />
            {isGuest && <GuestResultCta />}
          </>
        )}
        <style>{`.sess { background: var(--color-paper); min-height: calc(100vh - 110px); }`}</style>
      </main>
    );
  }

  if (phase === "running" && attempt) {
    const isExam = attempt.type === "MOCK_EXAM";
    const isGuest = sessionMode === "guest";
    // Un lot = batch fixe déterministe : pas d'extension, même pour un premium.
    const isLot = lotNumero != null && !isExam && !isGuest;
    // En training auth premium : extension auto. En guest : pas d'extension
    // (un seul batch de 20Q par démo). En exam / lot : pas d'extension.
    const canExtend = !isExam && isPremium && !isGuest && !isLot;
    const firstThemeId = attempt.questions[0]?.question.themeId;
    const allSameTheme =
      firstThemeId !== undefined &&
      attempt.questions.every((q) => q.question.themeId === firstThemeId);
    const lotQuitHref = isLot ? lotReturnPath(attempt) : null;

    return (
      <QuestionRunner
        initialAttempt={attempt}
        mode={isExam ? "exam" : "training"}
        infinite={canExtend}
        extensionParams={
          canExtend
            ? {
                module: attempt.module,
                themeId: allSameTheme ? firstThemeId : undefined,
                batchSize: PREMIUM_BATCH_SIZE,
              }
            : undefined
        }
        initialFavoriteIds={favoriteIds}
        eyebrow={
          isGuest
            ? isExam
              ? "Examen blanc · Démo"
              : "Entraînement · Démo"
            : isExam
              ? "Examen blanc"
              : isLot
                ? `Lot ${lotNumero}`
                : "Entraînement"
        }
        quitHref={
          isExam ? "/examens-blancs" : (lotQuitHref ?? "/entrainement")
        }
        timeLimitSeconds={isExam ? attempt.timeLimitSeconds : undefined}
        startedAt={isExam ? attempt.startedAt : undefined}
        backend={isGuest ? GUEST_BACKEND : undefined}
        onCompleted={(finalAttempt) => {
          setAttempt(finalAttempt);
          setPhase("result");
        }}
      />
    );
  }

  return null;
}

function GuestResultCta() {
  return (
    <section className="sess-guest-cta">
      <div className="sess-guest-cta-inner">
        <div className="sess-guest-cta-eyebrow">DÉMO TERMINÉE</div>
        <h2>
          Sauvegardez vos résultats et continuez à progresser.
        </h2>
        <p>
          Vos réponses ne sont pas conservées tant que vous n&apos;avez pas de
          compte. Créez-en un gratuitement pour suivre vos statistiques par
          thème, réviser vos erreurs et lancer un entraînement illimité.
        </p>
        <div className="sess-guest-cta-actions">
          <Link href="/inscription" className="btn btn-red btn-lg">
            Créer mon compte gratuit →
          </Link>
          <Link href="/connexion" className="btn btn-ghost">
            J&apos;ai déjà un compte
          </Link>
        </div>
      </div>
      <style>{`
        .sess-guest-cta {
          max-width: 720px;
          margin: 0 auto;
          padding: 0 16px 48px;
        }
        .sess-guest-cta-inner {
          background: linear-gradient(135deg, var(--color-blue) 0%, var(--color-blue-dark) 100%);
          color: #fff;
          padding: 32px 36px;
          border-radius: 20px;
          box-shadow: 0 30px 60px -30px rgba(15, 24, 57, 0.4);
        }
        .sess-guest-cta-eyebrow {
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.14em;
          opacity: 0.7;
          font-weight: 700;
          margin-bottom: 12px;
        }
        .sess-guest-cta-inner h2 {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: clamp(22px, 3vw, 28px);
          line-height: 1.2;
          letter-spacing: -0.015em;
          margin: 0 0 12px;
          color: #fff;
        }
        .sess-guest-cta-inner p {
          color: rgba(255, 255, 255, 0.82);
          font-size: 14.5px;
          line-height: 1.55;
          margin: 0 0 22px;
          max-width: 540px;
        }
        .sess-guest-cta-actions {
          display: flex; gap: 10px; flex-wrap: wrap; align-items: center;
        }
      `}</style>
    </section>
  );
}

const errorStyles = `
  .sess-error {
    min-height: 60vh;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    text-align: center; padding: 40px 24px; gap: 14px;
  }
  .sess-error h1 {
    font-family: var(--font-display); font-weight: 500;
    font-size: 28px; letter-spacing: -0.02em;
    color: var(--color-ink); margin: 0;
  }
  .sess-error p {
    color: var(--color-muted); font-size: 14px;
    max-width: 420px; line-height: 1.55; margin: 0 0 8px;
  }
`;
