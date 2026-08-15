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
import { examIsStale, qcmScoreLabel, subAttemptView, type SubAttemptView } from "@/lib/exam-levels";
import {
  epreuvesAClore,
  fullExamSuspendMessage,
  FULL_EXAM_SUSPEND_CANCEL,
  FULL_EXAM_SUSPEND_CONFIRM,
  FULL_EXAM_SUSPEND_TITLE,
} from "@/lib/full-exam-exit";
import {
  EPREUVE_PRESENTATION,
  secondsUntil,
  subAttemptDurationLabel,
} from "@/lib/exam-durations";
import {
  FULL_TCF_EXAM_EPREUVES,
  niveauCecrlLabel,
  type FullTcfExamResponse,
  type FullTcfExamSubAttempt,
} from "@/lib/types";
import s from "../tcfFullExam.module.css";

const EPREUVE_ORDER = FULL_TCF_EXAM_EPREUVES;

function epreuveMeta(epreuve: string) {
  return EPREUVE_PRESENTATION[epreuve as keyof typeof EPREUVE_PRESENTATION] ?? null;
}

function formatTimer(sec: number): string {
  const s = Math.max(0, Math.round(sec));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const ss = s % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  return `${String(m).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
}

/**
 * Décompte de l'épreuve COURANTE, sur la seule échéance servie par le serveur.
 *
 * Il n'y a plus de chrono global : chaque épreuve a le sien, il ne part qu'au
 * `POST /begin`, et il continue de courir pendant une absence — d'où le calcul
 * sur `deadlineAt` et jamais sur une durée locale. `null` = épreuve pas encore
 * lancée (aucune échéance) ou épreuve sans chrono (EO, chronométrée par tâche).
 */
function useEpreuveCountdown(deadlineAt: string | null | undefined) {
  const [remaining, setRemaining] = useState<number | null>(() => secondsUntil(deadlineAt));

  useEffect(() => {
    setRemaining(secondsUntil(deadlineAt));
    if (!deadlineAt) return;
    const id = setInterval(() => setRemaining(secondsUntil(deadlineAt)), 1000);
    return () => clearInterval(id);
  }, [deadlineAt]);

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
  const [suspending, setSuspending] = useState(false);
  const [suspendConfirmOpen, setSuspendConfirmOpen] = useState(false);
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

  // Épreuve courante = la première non terminée. Calculée AVANT les retours
  // anticipés : c'est son échéance qui alimente le décompte (règle des hooks).
  const ordered = (exam?.subAttempts ?? []).length
    ? EPREUVE_ORDER.map((ep) => exam!.subAttempts.find((sa) => sa.epreuve === ep)).filter(
        (sa): sa is FullTcfExamSubAttempt => sa != null,
      )
    : [];
  const currentIdx = ordered.findIndex((sa) => !sa.finishedAt);
  const allDone = ordered.length > 0 && currentIdx === -1;
  const current = currentIdx === -1 ? null : ordered[currentIdx];

  const remaining = useEpreuveCountdown(current?.deadlineAt);
  const [starting, setStarting] = useState(false);

  /** Les épreuves que « suspendre » va clôturer (commencées, pas terminées). */
  const aClore = exam ? epreuvesAClore(exam) : [];

  /**
   * Suspend l'examen : on clôture sur-le-champ l'épreuve **commencée** (elle ne
   * se reprend jamais), on **épargne** celles qui n'ont jamais été ouvertes, et
   * on sort de la page.
   *
   * 🛑 Aucun `finish` du parent, aucune navigation vers le bilan : **il n'y a
   * pas de résultat tant que les 4 épreuves ne sont pas terminées**, et un
   * examen suspendu reste « en cours » indéfiniment, reprenable, occupant son
   * slot dans la grille. C'est voulu.
   */
  const suspendAndLeave = useCallback(async () => {
    if (suspending) return;
    setSuspending(true);
    for (const sa of exam ? epreuvesAClore(exam) : []) {
      try {
        if (sa.epreuve === "TCF_CO" || sa.epreuve === "TCF_CE") {
          await attemptApi.finish(sa.attemptId);
        } else {
          await fullTcfExamApi.markSubDone(examId, sa.epreuve);
        }
      } catch {
        // best-effort : la sortie ne doit jamais être bloquée par un aléa réseau
      }
    }
    router.push("/examens-blancs");
  }, [exam, examId, suspending, router]);

  // Une nouvelle épreuve courante remet le garde à plat : chaque épreuve a sa
  // propre échéance, donc sa propre expiration. Déclaré AVANT l'effet
  // d'expiration pour qu'un changement d'épreuve ne le rouvre pas après coup.
  useEffect(() => {
    timedOutRef.current = false;
  }, [current?.attemptId]);

  // Échéance de l'épreuve courante atteinte : c'est le SERVEUR qui la clôture
  // (avec ce qui était enregistré) — on se contente de relire l'examen pour
  // afficher l'épreuve suivante. Aucune finalisation locale : rien n'est perdu,
  // et il n'existe aucun flux « recommencer une épreuve interrompue ».
  useEffect(() => {
    if (!exam || remaining == null || remaining > 0 || timedOutRef.current || suspending) return;
    timedOutRef.current = true;
    void load();
  }, [exam, remaining, suspending, load]);

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

  // Le décompte n'existe que pour une épreuve DÉJÀ lancée et qui porte un
  // chrono : l'EO n'en a pas (elle se chronomètre tâche par tâche), et une
  // épreuve pas encore commencée n'a aucune échéance — on n'en affiche pas.
  const showTimer = !allDone && remaining != null;
  const isUrgent = remaining != null && remaining <= 300 && remaining > 0;

  return (
    <div className={s.page}>
      {/* Hero */}
      <div className={s.hero}>
        <div className={s.heroEyebrow}>
          {allDone ? "TERMINÉ" : `ÉTAPE ${currentIdx + 1} / ${ordered.length}`} · EXAMEN BLANC
        </div>
        <div className={s.heroTitle}>TCF IRN complet</div>
        <div className={s.heroSub}>
          {allDone
            ? "Toutes les épreuves sont terminées."
            : `En cours · ${current ? (epreuveMeta(current.epreuve)?.label ?? "") : ""}`}
        </div>
        {showTimer && (
          <div className={`${s.timerBadge} ${isUrgent ? s.urgent : ""}`}>
            <Timer size={16} />
            {formatTimer(remaining!)}
          </div>
        )}
        {!allDone && current && !showTimer && (
          <div className={s.heroSub}>
            {current.epreuve === "TCF_EO"
              ? "Chaque tâche est chronométrée : le temps ne part qu'au moment où vous lancez la tâche."
              : `Le chrono de cette épreuve (${subAttemptDurationLabel(current)}) démarre quand vous la lancez.`}
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
            stale={examIsStale(exam)}
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
                // Pose l'échéance PROPRE de l'épreuve au moment de son
                // lancement réel. Obligatoire sur les 4 épreuves : sans lui
                // l'épreuve n'a aucune échéance (et l'EE, qui a un chrono, la
                // lirait à null). Idempotent côté backend : une reprise ne
                // remet rien à zéro et rend le temps réellement restant.
                setStarting(true);
                try {
                  await fullTcfExamApi.begin(examId, current.epreuve);
                } catch {
                  // best-effort : on lance quand même l'épreuve
                }
                router.push(href);
              }}
            >
              {starting
                ? "Démarrage…"
                : `Commencer · ${epreuveMeta(current.epreuve)?.label ?? ""}`}
            </button>
            <button
              type="button"
              className="btn btn-ghost"
              onClick={() => setSuspendConfirmOpen(true)}
              disabled={suspending}
            >
              Suspendre l&apos;examen
            </button>
          </>
        ) : null}
      </div>

      <ConfirmSheet
        open={suspendConfirmOpen}
        tone="warning"
        title={FULL_EXAM_SUSPEND_TITLE}
        message={fullExamSuspendMessage(aClore)}
        confirmLabel={FULL_EXAM_SUSPEND_CONFIRM}
        cancelLabel={FULL_EXAM_SUSPEND_CANCEL}
        onConfirm={() => {
          setSuspendConfirmOpen(false);
          void suspendAndLeave();
        }}
        onClose={() => setSuspendConfirmOpen(false)}
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
  stale,
}: {
  sub: FullTcfExamSubAttempt;
  state: StepState;
  /** Plus aucune évaluation ne tourne derrière (cf. `examIsStale`). */
  stale: boolean;
}) {
  const meta = epreuveMeta(sub.epreuve);
  const view = subAttemptView(sub, { stale });
  if (!meta) return null;
  // Durée servie par le DTO quand elle existe, repli sur la table de référence
  // sinon — jamais une minute écrite dans cet écran.
  const durationMeta = `${subAttemptDurationLabel(sub)} · ${meta.volume}`;

  // EE/EO verrouillées (compte gratuit ayant déjà utilisé l'expression offerte
  // une fois) : on affiche un cadenas + le motif, sans badge de niveau.
  if (sub.locked) {
    return (
      <div className={`${s.stepCard} ${s.locked}`}>
        <span className={s.stepIcon}>{meta.icon}</span>
        <span className={s.stepBody}>
          <span className={s.stepLabel}>{meta.label}</span>
          <span className={s.stepMeta}>Réservé à l&apos;abonnement Intégral</span>
        </span>
        <Lock size={16} style={{ color: "var(--color-muted-2)", flexShrink: 0 }} />
      </div>
    );
  }

  return (
    <div
      className={`${s.stepCard} ${state === "current" ? s.current : ""} ${state === "done" ? s.done : ""} ${state === "locked" ? s.locked : ""}`}
    >
      <span className={s.stepIcon}>{meta.icon}</span>
      <span className={s.stepBody}>
        <span className={s.stepLabel}>{meta.label}</span>
        <span className={s.stepMeta}>{durationMeta}</span>
      </span>
      {state === "done" && <StepBadge sub={sub} view={view} />}
      {state === "locked" && <Lock size={16} style={{ color: "var(--color-muted-2)", flexShrink: 0 }} />}
      {state === "current" && (
        <span className={s.stepBadge}>Maintenant</span>
      )}
    </div>
  );
}

/** Badge d'une épreuve terminée. Un NIVEAU prend la teinte de son palier
 *  (`view.tone`) ; un simple état (score, check) reste neutre — « fait » n'est
 *  pas « réussi ». Une évaluation en échec le dit, au lieu de tourner à vide. */
function StepBadge({ sub, view }: { sub: FullTcfExamSubAttempt; view: SubAttemptView }) {
  if (view.level != null) {
    return (
      <span className={s.stepBadge} data-tone={view.tone}>
        {niveauCecrlLabel(view.level)}
      </span>
    );
  }
  if (view.state === "failed") {
    return <span className={`${s.stepBadge} ${s.alert}`}>Éval en échec</span>;
  }
  if (view.showSpinner) {
    return <span className={`${s.stepBadge} ${s.evaluating}`}>Éval en cours…</span>;
  }
  if (view.state === "stalled") {
    return <span className={`${s.stepBadge} ${s.evaluating}`}>Éval interrompue</span>;
  }
  {
    // Échelle du relevé TCF (100-499) dès que le backend a calibré ; le score
    // pondéré interne (« 23/50 ») ne reste qu'en repli — il ne veut rien dire
    // pour un candidat.
    const scoreLabel = qcmScoreLabel(sub);
    if (scoreLabel) {
      return <span className={`${s.stepBadge} ${s.done}`}>{scoreLabel}</span>;
    }
  }
  return (
    <span className={`${s.stepBadge} ${s.done}`}>
      <Check size={13} />
    </span>
  );
}
