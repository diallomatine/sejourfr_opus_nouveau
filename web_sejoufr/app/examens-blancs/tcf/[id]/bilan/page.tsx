"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate } from "@/app/_components/module_detail/parts";
import { ApiException, fullTcfExamApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  FULL_TCF_EXAM_EPREUVES,
  niveauCecrlLabel,
  type FullTcfExamResponse,
  type FullTcfExamSubAttempt,
} from "@/lib/types";
import s from "../../tcfFullExam.module.css";

// Polling : rapide les 30 premières secondes, puis ralenti, max 5 min
const POLL_FAST_MS = 3_000;
const POLL_SLOW_MS = 8_000;
const POLL_SLOWDOWN_MS = 30_000;
const POLL_MAX_MS = 5 * 60 * 1_000;

const EPREUVE_ORDER = FULL_TCF_EXAM_EPREUVES;

const EPREUVE_META: Record<string, { icon: string; label: string }> = {
  TCF_CO: { icon: "🎧", label: "Compréhension orale" },
  TCF_CE: { icon: "📖", label: "Compréhension écrite" },
  TCF_EE: { icon: "✍️", label: "Expression écrite" },
  TCF_EO: { icon: "🎙️", label: "Expression orale" },
};

export default function TcfFullExamBilanPage() {
  return (
    <DualChromeShell>
      <BilanInner />
    </DualChromeShell>
  );
}

function BilanInner() {
  const params = useParams<{ id: string }>();
  const examId = params?.id ?? "";
  const router = useRouter();
  const { user, status } = useAuth();

  const [exam, setExam] = useState<FullTcfExamResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pollExhausted, setPollExhausted] = useState(false);

  const cancelledRef = useRef(false);
  const pollStartRef = useRef<number>(0);
  const pollTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const stopPolling = useCallback(() => {
    if (pollTimerRef.current) {
      clearTimeout(pollTimerRef.current);
      pollTimerRef.current = null;
    }
  }, []);

  const isFullyEvaluated = useCallback((e: FullTcfExamResponse): boolean => {
    return e.status === "COMPLETED";
  }, []);

  const schedulePoll = useCallback(
    (fetchFn: () => Promise<void>) => {
      const elapsed = Date.now() - pollStartRef.current;
      if (elapsed >= POLL_MAX_MS) {
        setPollExhausted(true);
        return;
      }
      const delay = elapsed < POLL_SLOWDOWN_MS ? POLL_FAST_MS : POLL_SLOW_MS;
      pollTimerRef.current = setTimeout(fetchFn, delay);
    },
    [],
  );

  const fetchAndMaybePoll = useCallback(async () => {
    if (cancelledRef.current) return;
    try {
      const data = await fullTcfExamApi.get(examId);
      if (cancelledRef.current) return;
      setExam(data);
      if (!isFullyEvaluated(data)) {
        schedulePoll(fetchAndMaybePoll);
      }
    } catch (e) {
      if (cancelledRef.current) return;
      // On garde l'état courant et on retentera
      schedulePoll(fetchAndMaybePoll);
    }
  }, [examId, isFullyEvaluated, schedulePoll]);

  useEffect(() => {
    if (status !== "authenticated") return;
    cancelledRef.current = false;
    pollStartRef.current = Date.now();

    // Finaliser l'examen (idempotent) puis charger l'état
    fullTcfExamApi
      .finish(examId)
      .then((data) => {
        if (cancelledRef.current) return;
        setExam(data);
        setLoading(false);
        if (!isFullyEvaluated(data)) {
          schedulePoll(fetchAndMaybePoll);
        }
      })
      .catch((e) => {
        // Fallback : charger sans finish
        fullTcfExamApi
          .get(examId)
          .then((data) => {
            if (cancelledRef.current) return;
            setExam(data);
            if (!isFullyEvaluated(data)) {
              schedulePoll(fetchAndMaybePoll);
            }
          })
          .catch((e2) => {
            if (cancelledRef.current) return;
            setError(e2 instanceof ApiException ? e2.message : "Impossible de charger le bilan.");
          })
          .finally(() => {
            if (!cancelledRef.current) setLoading(false);
          });
      });

    return () => {
      cancelledRef.current = true;
      stopPolling();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status, examId]);

  if (status === "loading") return <div className={s.loading}>Chargement…</div>;
  if (!user) return <ModuleDetailGate next={`/examens-blancs/tcf/${examId}/bilan`} />;
  if (loading) return <div className={s.loading}>Calcul du bilan…</div>;
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

  const isPending = exam.status !== "COMPLETED";
  const level = exam.finalCecrlLevel;
  const ordered = EPREUVE_ORDER.map((ep) => exam.subAttempts.find((sa) => sa.epreuve === ep)!).filter(Boolean);

  function handleRefresh() {
    setPollExhausted(false);
    pollStartRef.current = Date.now();
    setLoading(true);
    fullTcfExamApi
      .get(examId)
      .then((data) => {
        setExam(data);
        if (!isFullyEvaluated(data)) schedulePoll(fetchAndMaybePoll);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }

  return (
    <div className={s.page}>
      {/* Hero CECRL */}
      <div className={s.bilanHero}>
        <div className={s.bilanEyebrow}>TON NIVEAU TCF IRN</div>
        {isPending ? (
          <div className={s.bilanPending}>
            <div className={s.spinner} />
            <span className={s.bilanPendingText}>L&apos;IA évalue tes productions…</span>
          </div>
        ) : (
          <>
            <div className={s.bilanLevel}>{niveauCecrlLabel(level)}</div>
            <div className={s.bilanLevelSub}>niveau plancher (règle TCF IRN)</div>
          </>
        )}
      </div>

      {/* Bannière si polling épuisé */}
      {pollExhausted && isPending && (
        <div className={s.pollBanner}>
          <span>L&apos;évaluation prend plus longtemps que prévu.</span>
          <button type="button" className="btn-link-soft" onClick={handleRefresh}>
            Actualiser
          </button>
        </div>
      )}

      {/* Cards par épreuve */}
      <div className={s.bilanCards}>
        {ordered.map((sa) => (
          <SubAttemptCard key={sa.epreuve} sa={sa} examId={examId} />
        ))}
      </div>

      <Link href="/examens-blancs" className="btn btn-ghost" style={{ width: "100%" }}>
        Retour aux examens
      </Link>
    </div>
  );
}

function SubAttemptCard({
  sa,
  examId,
}: {
  sa: FullTcfExamSubAttempt;
  examId: string;
}) {
  const meta = EPREUVE_META[sa.epreuve];
  if (!meta) return null;

  const isProduction = sa.epreuve === "TCF_EE" || sa.epreuve === "TCF_EO";
  const evaluated = sa.cecrlLevel !== null;
  const pending = sa.finishedAt && !evaluated;

  const href = isProduction
    ? sa.epreuve === "TCF_EE"
      ? `/entrainement/tcf/ee/session/${sa.attemptId}`
      : `/entrainement/tcf/eo/session/${sa.attemptId}`
    : `/sessions/${sa.attemptId}`;

  const sub = !sa.finishedAt
    ? "Non terminée"
    : pending
      ? "Évaluation en cours…"
      : isProduction
        ? `${sa.submissionsCount ?? 0}/3 tâches évaluées`
        : sa.score != null && sa.maxScore != null
          ? `Score ${sa.score}/${sa.maxScore}`
          : "Terminée";

  return (
    <button
      type="button"
      className={`${s.bilanCard} ${evaluated ? s.evaluated : ""}`}
      onClick={() => (window.location.href = href)}
      disabled={!sa.finishedAt}
    >
      <span className={s.bilanCardIcon}>{meta.icon}</span>
      <span className={s.bilanCardBody}>
        <span className={s.bilanCardLabel}>{meta.label}</span>
        <span className={s.bilanCardSub}>{sub}</span>
      </span>
      {evaluated ? (
        <span className={s.bilanCardLevel}>{niveauCecrlLabel(sa.cecrlLevel)}</span>
      ) : (
        <span className={s.bilanCardLevelPending}>
          {pending ? "…" : "—"}
        </span>
      )}
    </button>
  );
}
