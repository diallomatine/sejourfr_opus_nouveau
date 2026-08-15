"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { Lock, RotateCw, TriangleAlert } from "lucide-react";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ModuleDetailGate } from "@/app/_components/module_detail/parts";
import { ApiException, fullTcfExamApi, productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  examIsStale,
  floorMarks,
  floorRuleSentence,
  floorScope,
  subAttemptView,
  type SubAttemptView,
} from "@/lib/exam-levels";
import {
  FULL_TCF_EXAM_EPREUVES,
  fullTcfExamContinuiteLabel,
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

  /** Prochain tour de polling, indirect via une ref : le tour suivant est
   *  planifié depuis le tour courant, et une auto-référence dans un
   *  `useCallback` figerait la version initiale de la fonction. */
  const nextPollRef = useRef<() => void>(() => {});

  const schedulePoll = useCallback(() => {
    const elapsed = Date.now() - pollStartRef.current;
    if (elapsed >= POLL_MAX_MS) {
      setPollExhausted(true);
      return;
    }
    const delay = elapsed < POLL_SLOWDOWN_MS ? POLL_FAST_MS : POLL_SLOW_MS;
    pollTimerRef.current = setTimeout(() => nextPollRef.current(), delay);
  }, []);

  /** Poller un examen mort n'apprend rien : plus aucune évaluation ne tourne
   *  derrière (parité mobile `_examIsStale`). On bascule directement sur l'état
   *  terminal + relance manuelle au lieu d'un spinner éternel. */
  const continueOrStop = useCallback(
    (data: FullTcfExamResponse) => {
      if (data.status === "COMPLETED") return;
      if (examIsStale(data)) {
        setPollExhausted(true);
        return;
      }
      schedulePoll();
    },
    [schedulePoll],
  );

  const fetchAndMaybePoll = useCallback(async () => {
    if (cancelledRef.current) return;
    try {
      const data = await fullTcfExamApi.get(examId);
      if (cancelledRef.current) return;
      setExam(data);
      continueOrStop(data);
    } catch {
      if (cancelledRef.current) return;
      // On garde l'état courant et on retentera
      schedulePoll();
    }
  }, [examId, continueOrStop, schedulePoll]);

  useEffect(() => {
    nextPollRef.current = () => void fetchAndMaybePoll();
  }, [fetchAndMaybePoll]);

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
        continueOrStop(data);
      })
      .catch(() => {
        // Fallback : charger sans finish
        fullTcfExamApi
          .get(examId)
          .then((data) => {
            if (cancelledRef.current) return;
            setExam(data);
            continueOrStop(data);
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

  const handleRefresh = useCallback(() => {
    stopPolling();
    setPollExhausted(false);
    pollStartRef.current = Date.now();
    return fullTcfExamApi
      .get(examId)
      .then((data) => {
        if (cancelledRef.current) return;
        setExam(data);
        continueOrStop(data);
      })
      .catch(() => {});
  }, [examId, continueOrStop, stopPolling]);

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
  const ordered = EPREUVE_ORDER.map((ep) =>
    exam.subAttempts.find((sa) => sa.epreuve === ep),
  ).filter((sa): sa is FullTcfExamSubAttempt => sa != null);

  // Plus rien ne tourne derrière : soit 5 min de polling sans succès, soit
  // l'examen est finalisé depuis trop longtemps (pipeline IA bloqué).
  const scope = floorScope(exam);
  const stalled = pollExhausted || examIsStale(exam);
  const views = ordered.map((sa) => subAttemptView(sa, { stale: stalled }));
  const marks = floorMarks(
    views.map((v) => v.level),
    level,
  );
  const failedCount = views.reduce((n, v) => n + v.failedSubmissionIds.length, 0);
  // Comment l'examen a été mené : d'une traite, ou repris en plusieurs fois.
  // Un constat, pas un reproche — s'arrêter entre deux épreuves est prévu.
  // `null` tant que l'examen n'est pas terminé : rien ne s'affiche.
  const continuiteLabel = fullTcfExamContinuiteLabel(exam.continuite);

  return (
    <div className={s.page}>
      {/* Hero CECRL */}
      <div className={s.bilanHero}>
        <div className={s.bilanEyebrow}>TON NIVEAU TCF IRN</div>
        {isPending && !stalled ? (
          <div className={s.bilanPending}>
            <div className={s.spinner} />
            <span className={s.bilanPendingText}>L&apos;IA évalue tes productions…</span>
          </div>
        ) : isPending ? (
          // Terminal sans niveau : on le dit, on ne fait pas semblant d'attendre.
          <div className={s.bilanPending}>
            <span className={s.bilanLevelSub}>Bilan incomplet</span>
            <span className={s.bilanPendingText}>
              {failedCount > 0
                ? "Une ou plusieurs évaluations n'ont pas abouti. Relance-les ci-dessous pour obtenir ton niveau final."
                : "Ton niveau final n'a pas encore pu être calculé. Actualise dans un instant."}
            </span>
          </div>
        ) : (
          <>
            <div className={s.bilanLevel}>{niveauCecrlLabel(level)}</div>
            <div className={s.bilanLevelSub}>
              {scope.partial ? "bilan partiel · niveau plancher" : "niveau plancher (règle TCF IRN)"}
            </div>
            <p className={s.bilanRule}>{floorRuleSentence(scope)}</p>
          </>
        )}
        {continuiteLabel && <div className={s.bilanContinuite}>{continuiteLabel}</div>}
      </div>

      {/* Bannière si plus rien ne tourne */}
      {stalled && isPending && (
        <div className={s.pollBanner}>
          <span>
            {failedCount > 0
              ? "Des évaluations n'ont pas abouti — relance-les sur l'épreuve concernée."
              : "L'évaluation prend plus longtemps que prévu."}
          </span>
          <button type="button" className="btn-link-soft" onClick={() => void handleRefresh()}>
            Actualiser
          </button>
        </div>
      )}

      {/* Cards par épreuve */}
      <div className={s.bilanCards}>
        {ordered.map((sa, i) => (
          <SubAttemptCard
            key={sa.epreuve}
            sa={sa}
            view={views[i]}
            examId={examId}
            isFloor={marks[i]}
            onRefresh={handleRefresh}
          />
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
  view,
  examId,
  isFloor,
  onRefresh,
}: {
  sa: FullTcfExamSubAttempt;
  view: SubAttemptView;
  examId: string;
  /** Épreuve qui tire le résultat global vers le bas. Signalée **en toutes
   *  lettres** : la couleur, elle, ne dit que le palier (cf. `epreuveLevelTone`). */
  isFloor: boolean;
  onRefresh: () => Promise<void>;
}) {
  const router = useRouter();
  const meta = EPREUVE_META[sa.epreuve];
  const [retrying, setRetrying] = useState(false);
  if (!meta) return null;

  const isProduction = sa.epreuve === "TCF_EE" || sa.epreuve === "TCF_EO";
  const failed = view.failedSubmissionIds;

  // Le détail d'une épreuve revient au bilan de l'examen (pas vers les examens
  // de l'épreuve) : on transmet `backTo` aux sessions de production.
  const backTo = `/examens-blancs/tcf/${examId}/bilan`;
  const href = isProduction
    ? `/entrainement/tcf/${sa.epreuve === "TCF_EE" ? "ee" : "eo"}/session/${sa.attemptId}?backTo=${encodeURIComponent(backTo)}`
    : `/sessions/${sa.attemptId}`;

  async function handleRetry() {
    if (retrying || failed.length === 0) return;
    setRetrying(true);
    // Best-effort tâche par tâche : une relance refusée ne doit pas empêcher
    // les autres de repartir. Le rafraîchissement dira le nouvel état.
    await Promise.allSettled(failed.map((id) => productionApi.retrySubmission(id)));
    await onRefresh();
    setRetrying(false);
  }

  const clickable = view.state !== "locked" && sa.finishedAt != null;

  const trailing =
    view.state === "locked" ? (
      <span className={s.bilanCardLevelPending} aria-label="Épreuve verrouillée">
        <Lock size={16} />
      </span>
    ) : view.level != null ? (
      <span className={s.bilanCardLevel} data-tone={view.tone}>
        {niveauCecrlLabel(view.level)}
      </span>
    ) : view.showSpinner ? (
      <span className={s.bilanCardLevelPending}>…</span>
    ) : view.state === "stalled" ? (
      <span className={s.bilanCardRefresh} role="presentation">
        <RotateCw size={13} /> Actualiser
      </span>
    ) : view.state === "failed" ? (
      <span className={s.bilanCardAlert} aria-hidden>
        <TriangleAlert size={16} />
      </span>
    ) : (
      <span className={s.bilanCardLevelPending}>—</span>
    );

  const inner = (
    <>
      <span className={s.bilanCardIcon}>{meta.icon}</span>
      <span className={s.bilanCardBody}>
        <span className={s.bilanCardLabel}>{meta.label}</span>
        <span className={s.bilanCardSub}>
          {view.subtitle}
          {isFloor && <span className={s.bilanCardFloor}> · niveau retenu</span>}
        </span>
      </span>
      {trailing}
    </>
  );

  return (
    <div className={s.bilanCardWrap}>
      {view.state === "stalled" ? (
        <button type="button" className={s.bilanCard} onClick={() => void onRefresh()}>
          {inner}
        </button>
      ) : clickable ? (
        <button type="button" className={s.bilanCard} onClick={() => router.push(href)}>
          {inner}
        </button>
      ) : (
        <div className={s.bilanCard}>{inner}</div>
      )}

      {failed.length > 0 && (
        <div className={s.retryBanner}>
          <span className={s.retryBannerText}>
            {failed.length} évaluation{failed.length > 1 ? "s" : ""} IA en échec
          </span>
          <button
            type="button"
            className={s.retryBtn}
            onClick={() => void handleRetry()}
            disabled={retrying}
          >
            {retrying ? "Relance…" : "Réessayer"}
          </button>
        </div>
      )}
    </div>
  );
}
