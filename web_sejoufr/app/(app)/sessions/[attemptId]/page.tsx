"use client";

import Link from "next/link";
import { use, useEffect, useState } from "react";
import { QuestionRunner } from "@/app/_components/QuestionRunner";
import { TrainingResultCard } from "@/app/_components/TrainingResultCard";
import { ExamResultCard } from "@/app/_components/ExamResultCard";
import { ExamReport } from "@/app/_components/ExamReport";
import { ApiException, attemptApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import type { AttemptResponse } from "@/lib/types";

interface PageProps {
  params: Promise<{ attemptId: string }>;
}

type Phase = "loading" | "running" | "result" | "error";

const PREMIUM_BATCH_SIZE = 30;

/**
 * Page générique d'une session : training ou examen blanc. Le type de
 * l'attempt détermine le mode du runner et la carte de résultat à afficher.
 *
 * Cette route remplace l'ancienne /entrainement/[attemptId] (sortie en V1) :
 * elle accueille les deux flows pour partager le composant QuestionRunner.
 */
export default function SessionRunnerPage({ params }: PageProps) {
  const { attemptId } = use(params);
  const { user, status } = useAuth();
  const isPremium = user?.isPremium ?? false;

  const [phase, setPhase] = useState<Phase>("loading");
  const [attempt, setAttempt] = useState<AttemptResponse | null>(null);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  /** True si l'attempt était déjà finalisé à l'ouverture (reprise sur session close). */
  const [openedAsFinished, setOpenedAsFinished] = useState(false);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    (async () => {
      try {
        const a = await attemptApi.get(attemptId);
        if (cancelled) return;

        if (a.finishedAt) {
          setAttempt(a);
          setOpenedAsFinished(true);
          setPhase("result");
          return;
        }

        let favs: string[] = [];
        try {
          const favList = await userContentApi.favorites(a.module);
          favs = favList.map((q) => q.id);
        } catch {
          // best-effort
        }
        if (cancelled) return;
        setAttempt(a);
        setFavoriteIds(new Set(favs));
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

  if (!user) {
    return (
      <main className="sess-gate">
        <p>Connectez-vous pour reprendre votre session.</p>
        <Link href={`/connexion?next=/sessions/${attemptId}`} className="btn btn-blue">
          Se connecter
        </Link>
      </main>
    );
  }

  if (phase === "error") {
    return (
      <main className="sess-error">
        <h1>Session indisponible</h1>
        <p>{errorMsg ?? "Cette session n'existe plus."}</p>
        <Link href="/dashboard" className="btn btn-blue">
          Retour au tableau de bord →
        </Link>
        <style>{errorStyles}</style>
      </main>
    );
  }

  if (phase === "result" && attempt) {
    const isExam = attempt.type === "MOCK_EXAM";
    return (
      <main className="sess">
        {isExam ? (
          <>
            <ExamResultCard attempt={attempt} />
            <ExamReport attempt={attempt} />
          </>
        ) : (
          <TrainingResultCard
            attempt={attempt}
            isPremium={isPremium}
            variant={openedAsFinished ? "resume" : "primary"}
          />
        )}
        <style>{`.sess { background: var(--color-paper); min-height: calc(100vh - 110px); }`}</style>
      </main>
    );
  }

  if (phase === "running" && attempt) {
    const isExam = attempt.type === "MOCK_EXAM";
    // En training : extension auto si user premium pour ce module.
    // En exam : pas d'extension (batch fixe), mais un timer.
    const canExtend = !isExam && isPremium;
    const firstThemeId = attempt.questions[0]?.question.themeId;
    const allSameTheme =
      firstThemeId !== undefined &&
      attempt.questions.every((q) => q.question.themeId === firstThemeId);

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
        eyebrow={isExam ? "Examen blanc" : "Entraînement"}
        quitHref={isExam ? "/examens-blancs" : "/entrainement"}
        timeLimitSeconds={isExam ? attempt.timeLimitSeconds : undefined}
        startedAt={isExam ? attempt.startedAt : undefined}
        onCompleted={(finalAttempt) => {
          setAttempt(finalAttempt);
          setPhase("result");
        }}
      />
    );
  }

  return null;
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
