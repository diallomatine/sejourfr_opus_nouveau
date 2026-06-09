"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { Check, Lock, Timer } from "lucide-react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate } from "@/app/_components/module_detail/parts";
import { ConfirmSheet } from "@/app/_components/hub/ConfirmSheet";
import { ApiException, attemptApi, fullTcfExamApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  FULL_TCF_EXAM_DURATION_SEC,
  FULL_TCF_EXAM_EPREUVES,
  niveauCecrlLabel,
  type FullTcfExamResponse,
  type FullTcfExamSubAttempt,
} from "@/lib/types";
import s from "../tcfFullExam.module.css";

const EPREUVE_ORDER = FULL_TCF_EXAM_EPREUVES;

const EPREUVE_META: Record<string, { icon: string; label: string; duration: string }> = {
  TCF_CO: { icon: "🎧", label: "Compréhension orale", duration: "20 min · 25 questions" },
  TCF_CE: { icon: "📖", label: "Compréhension écrite", duration: "30 min · 25 questions" },
  TCF_EE: { icon: "✍️", label: "Expression écrite", duration: "30 min · 3 tâches" },
  TCF_EO: { icon: "🎙️", label: "Expression orale", duration: "10 min · 3 tâches" },
};

function formatTimer(sec: number): string {
  const s = Math.max(0, Math.round(sec));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const ss = s % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  return `${String(m).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
}

// Le chrono ne court qu'une fois `startedAt` posé (1re épreuve lancée). Tant
// qu'il est null, on affiche la durée pleine sans décompter.
function useCountdown(startedAt: string | null, limitSec = FULL_TCF_EXAM_DURATION_SEC) {
  const calcRemaining = useCallback(
    () =>
      startedAt === null
        ? limitSec
        : Math.max(0, limitSec - (Date.now() - new Date(startedAt).getTime()) / 1000),
    [startedAt, limitSec],
  );
  const [remaining, setRemaining] = useState(calcRemaining);

  useEffect(() => {
    // Pas de décompte tant que le chrono n'a pas démarré (startedAt null) :
    // la valeur initiale (durée pleine) reste affichée jusqu'au lancement.
    if (startedAt === null) return;
    const id = setInterval(() => setRemaining(calcRemaining()), 1000);
    return () => clearInterval(id);
  }, [calcRemaining, startedAt]);

  return remaining;
}

export default function TcfFullExamProgressPage() {
  return (
    <DualChromeShell>
      <ProgressInner />
    </DualChromeShell>
  );
}

function ProgressInner() {
  const params = useParams<{ id: string }>();
  const examId = params?.id ?? "";
  const router = useRouter();
  const { user, status } = useAuth();

  const [exam, setExam] = useState<FullTcfExamResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [finishing, setFinishing] = useState(false);
  const [quitConfirmOpen, setQuitConfirmOpen] = useState(false);
  const timedOutRef = useRef(false);

  const load = useCallback(async () => {
    try {
      const data = await fullTcfExamApi.get(examId);
      setExam(data);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de charger l'examen.");
    } finally {
      setLoading(false);
    }
  }, [examId]);

  useEffect(() => {
    if (status !== "authenticated") return;
    void load();
  }, [status, load]);

  const remaining = useCountdown(exam?.timerStartedAt ?? null);
  const [starting, setStarting] = useState(false);

  // Finalise l'examen et va au bilan. Toute épreuve non terminée est finalisée
  // (CO/CE = score sur les réponses données, 0 si aucune ; EE/EO = markSubDone),
  // sinon le `finish` parent échouerait (le backend exige les 4 terminées).
  const finalizeAndGoToBilan = useCallback(async () => {
    if (finishing) return;
    setFinishing(true);
    const subs = exam?.subAttempts ?? [];
    for (const sa of subs) {
      if (sa.finishedAt) continue;
      try {
        if (sa.epreuve === "TCF_CO" || sa.epreuve === "TCF_CE") {
          await attemptApi.finish(sa.attemptId);
        } else {
          await fullTcfExamApi.markSubDone(examId, sa.epreuve);
        }
      } catch {
        // best-effort : on tente quand même le finish parent ci-dessous
      }
    }
    try {
      await fullTcfExamApi.finish(examId);
    } catch {
      // idempotent / déjà finalisé — le bilan se chargera de l'état réel
    }
    router.push(`/examens-blancs/tcf/${examId}/bilan`);
  }, [exam, examId, finishing, router]);

  // Chrono à 0 → finaliser automatiquement (sans avertissement)
  useEffect(() => {
    if (!exam || remaining > 0 || timedOutRef.current || finishing) return;
    timedOutRef.current = true;
    void finalizeAndGoToBilan();
  }, [exam, remaining, finishing, finalizeAndGoToBilan]);

  if (status === "loading") return <div className={s.loading}>Chargement…</div>;
  if (!user) return <ModuleDetailGate next={`/examens-blancs/tcf/${examId}`} />;

  if (loading) return <div className={s.loading}>Chargement de l&apos;examen…</div>;
  if (error) {
    return (
      <div className={s.page}>
        <div className={s.error}>{error}</div>
        <Link href="/examens-blancs" className="btn btn-ghost">
          Retour aux examens
        </Link>
      </div>
    );
  }
  if (!exam) return null;

  const ordered = EPREUVE_ORDER.map(
    (ep) => exam.subAttempts.find((sa) => sa.epreuve === ep)!,
  ).filter(Boolean);

  // Première épreuve non terminée = current
  const currentIdx = ordered.findIndex((sa) => !sa.finishedAt);
  const allDone = currentIdx === -1;
  const current = allDone ? null : ordered[currentIdx];
  const isUrgent = remaining <= 300 && remaining > 0;

  return (
    <div className={s.page}>
      {/* Hero */}
      <div className={s.hero}>
        <div className={s.heroEyebrow}>
          {allDone ? "TERMINÉ" : `ÉTAPE ${currentIdx + 1} / ${ordered.length}`} · EXAMEN BLANC
        </div>
        <div className={s.heroTitle}>TCF IRN complet</div>
        <div className={s.heroSub}>
          {allDone ? "Toutes les épreuves sont terminées." : `En cours · ${current ? EPREUVE_META[current.epreuve]?.label : ""}`}
        </div>
        {!allDone && (
          <div className={`${s.timerBadge} ${isUrgent ? s.urgent : ""}`}>
            <Timer size={16} />
            {formatTimer(remaining)}
          </div>
        )}
      </div>

      {/* Étapes */}
      <div className={s.stepList}>
        {ordered.map((sa, idx) => (
          <StepCard
            key={sa.epreuve}
            sub={sa}
            state={getStepState(sa, idx, currentIdx)}
          />
        ))}
      </div>

      {/* CTA */}
      <div className={s.ctaZone}>
        {allDone ? (
          <Link href={`/examens-blancs/tcf/${examId}/bilan`} className="btn btn-red btn-lg">
            Voir mon résultat
          </Link>
        ) : current ? (
          <>
            <button
              type="button"
              className="btn btn-red btn-lg"
              disabled={starting}
              onClick={async () => {
                if (starting) return;
                const href = subAttemptHref(current, examId);
                // Le chrono 90 min ne démarre qu'ici (1re épreuve lancée).
                if (!exam.timerStartedAt) {
                  setStarting(true);
                  try {
                    await fullTcfExamApi.begin(examId);
                  } catch {
                    // best-effort : on lance quand même l'épreuve
                  }
                }
                router.push(href);
              }}
            >
              {starting
                ? "Démarrage…"
                : `Commencer · ${EPREUVE_META[current.epreuve]?.label}`}
            </button>
            <button
              type="button"
              className="btn btn-ghost"
              onClick={() => setQuitConfirmOpen(true)}
              disabled={finishing}
            >
              Abandonner l&apos;examen
            </button>
          </>
        ) : null}
      </div>

      <ConfirmSheet
        open={quitConfirmOpen}
        tone="warning"
        title="Abandonner l'examen ?"
        message="Vous perdez tout ce qui n'a pas été terminé : les épreuves restantes sont comptées 0 et l'examen est finalisé. Vous verrez votre résultat. Cette action est définitive."
        confirmLabel="Abandonner et voir le résultat"
        cancelLabel="Continuer l'examen"
        onConfirm={() => {
          setQuitConfirmOpen(false);
          void finalizeAndGoToBilan();
        }}
        onClose={() => setQuitConfirmOpen(false)}
      />
    </div>
  );
}

type StepState = "done" | "current" | "locked";

function getStepState(sa: FullTcfExamSubAttempt, idx: number, currentIdx: number): StepState {
  if (sa.finishedAt) return "done";
  if (idx === currentIdx) return "current";
  return "locked";
}

function subAttemptHref(sa: FullTcfExamSubAttempt, examId: string): string {
  if (sa.epreuve === "TCF_CO" || sa.epreuve === "TCF_CE") {
    return `/sessions/${sa.attemptId}?fullExamId=${examId}`;
  }
  if (sa.epreuve === "TCF_EE") {
    return `/entrainement/tcf/ee/session/${sa.attemptId}?fullExamId=${examId}`;
  }
  return `/entrainement/tcf/eo/session/${sa.attemptId}?fullExamId=${examId}`;
}

function StepCard({
  sub,
  state,
}: {
  sub: FullTcfExamSubAttempt;
  state: StepState;
}) {
  const meta = EPREUVE_META[sub.epreuve];
  if (!meta) return null;

  const isProduction = sub.epreuve === "TCF_EE" || sub.epreuve === "TCF_EO";
  const evaluating = sub.finishedAt && isProduction && sub.cecrlLevel === null;

  return (
    <div
      className={`${s.stepCard} ${state === "current" ? s.current : ""} ${state === "done" ? s.done : ""} ${state === "locked" ? s.locked : ""}`}
    >
      <span className={s.stepIcon}>{meta.icon}</span>
      <span className={s.stepBody}>
        <span className={s.stepLabel}>{meta.label}</span>
        <span className={s.stepMeta}>{meta.duration}</span>
      </span>
      {state === "done" && (
        <span className={`${s.stepBadge} ${evaluating ? s.evaluating : s.done}`}>
          {evaluating ? (
            "Éval en cours…"
          ) : sub.cecrlLevel ? (
            niveauCecrlLabel(sub.cecrlLevel)
          ) : sub.score != null && sub.maxScore != null ? (
            `${sub.score}/${sub.maxScore}`
          ) : (
            <Check size={13} />
          )}
        </span>
      )}
      {state === "locked" && <Lock size={16} style={{ color: "var(--color-muted-2)", flexShrink: 0 }} />}
      {state === "current" && (
        <span className={s.stepBadge}>Maintenant</span>
      )}
    </div>
  );
}
