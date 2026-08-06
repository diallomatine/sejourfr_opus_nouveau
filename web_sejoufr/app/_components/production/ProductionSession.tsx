"use client";

import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { Check, ChevronRight, Lightbulb, Mic, PenLine, Timer } from "lucide-react";
import { ApiException, attemptApi, fullTcfExamApi, productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  cecrlIndex,
  correspondanceTcfPhrase,
  formatNoteSur20,
  isSubmissionPending,
  niveauCecrlLabel,
  type NiveauCecrl,
  type ProductionBilanResponse,
  productionTaskTitle,
  type ProductionSubmissionDto,
  type ProductionTaskDto,
  type RealtimeSessionDescriptor,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell } from "@/app/_components/hub/DetailParts";
import { EeWritingForm, clearEeDraft } from "./EeWritingForm";
import { EoRecordingForm } from "./EoRecordingForm";
import { RealtimeLaunchSheet } from "./RealtimeLaunchSheet";
import { RealtimeEoRunner } from "./RealtimeEoRunner";
import { useRealtimeEo } from "./useRealtimeEo";
import { type ProductionConfig } from "./config";
import detail from "@/app/_components/hub/detail.module.css";
import prod from "./production.module.css";
import skill from "@/app/_components/skill-ui/skill.module.css";

const TACHES = [1, 2, 3] as const;
const POLL_MS = 3000;
const MAX_POLLS = 40;
/** Durée de l'examen EE quand le backend ne porte pas de `timeLimitSeconds`
 *  (sous-attempt EE d'un examen TCF complet) : 30 min côté front. */
const EE_FALLBACK_LIMIT_SEC = 1800;

function fmtChrono(sec: number): string {
  const s = Math.max(0, Math.round(sec));
  const m = Math.floor(s / 60);
  const ss = s % 60;
  return `${String(m).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
}

/**
 * Session d'examen blanc d'une épreuve productive : exactement 3 tâches
 * (composition déterministe backend via `production-exam-tasks`) enchaînées sur
 * un même attempt, chronométrées, puis bilan avec niveau CECRL plancher. La
 * phase (saisie vs bilan) est dérivée des soumissions existantes (resume).
 *
 * EE : chrono 30:00 global ancré sur `attempt.startedAt + timeLimitSeconds`
 * (survit au refresh) ; à 0:00 auto-soumission recevable + finish + bilan.
 * EO : chrono par tâche dans le recorder (auto-stop + soumission immédiate).
 */
export function ProductionSession({ config }: { config: ProductionConfig }) {
  const params = useParams<{ attemptId: string }>();
  const attemptId = params?.attemptId ?? "";
  const router = useRouter();
  const searchParams = useSearchParams();
  /** Présent quand cette session est une épreuve d'un examen blanc TCF complet :
   *  on saute le bilan individuel et on retourne au hub de progression. */
  const fullExamId = searchParams.get("fullExamId");
  /** URL de retour quand on CONSULTE le bilan de l'épreuve (depuis le bilan de
   *  l'examen complet) — distinct de fullExamId qui pilote une épreuve ACTIVE. */
  const backTo = searchParams.get("backTo");
  const { user, status } = useAuth();

  const [tasks, setTasks] = useState<ProductionTaskDto[]>([]);
  const [subsByTache, setSubsByTache] = useState<Map<number, ProductionSubmissionDto>>(new Map());
  const [bilan, setBilan] = useState<ProductionBilanResponse | null>(null);
  const [phase, setPhase] = useState<"loading" | "writing" | "bilan">("loading");
  const [currentTache, setCurrentTache] = useState<number>(1);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Temps réel (EO Tâches 1 & 2). `taskMode` pilote l'UI de la tâche courante :
  // "classic" = enregistrement (montre le sujet + le bouton micro) ; "choosing" =
  // modal de choix du mode (ouvert sur le bouton micro) ; "realtime" = runner.
  const rt = useRealtimeEo(status === "authenticated" && config.mode === "audio");
  const [taskMode, setTaskMode] = useState<"choosing" | "classic" | "realtime">("classic");
  const [activeDescriptor, setActiveDescriptor] = useState<RealtimeSessionDescriptor | null>(null);
  const [rtStarting, setRtStarting] = useState(false);
  const [rtError, setRtError] = useState<string | null>(null);
  /** Le temps réel a été refusé sur cette tâche (quota, broker indisponible,
   *  session refusée) : on ne repropose plus le choix, le prochain tap sur le
   *  micro enregistre directement. Remis à zéro à la tâche suivante. */
  const [rtRefused, setRtRefused] = useState(false);

  /** Entre dans la tâche `n` : on affiche d'abord le sujet (mode "classic" =
   *  EoRecordingForm). Le choix du mode EO T1/T2 est proposé sur le bouton
   *  « démarrer » du formulaire (askMode), une fois le sujet lu. */
  const enterTask = useCallback(
    (n: number) => {
      setCurrentTache(n);
      setActiveDescriptor(null);
      setRtError(null);
      setRtRefused(false);
      setTaskMode("classic");
    },
    [],
  );

  /** Deadline absolue du chrono EE (ms epoch). Null = pas de chrono (EO, ou
   *  attempt pas encore chargé). */
  const [deadline, setDeadline] = useState<number | null>(null);
  const [remaining, setRemaining] = useState<number | null>(null);
  /** Signal d'expiration envoyé au formulaire de la tâche courante quand le
   *  chrono tombe à 0 : EE lit son texte, EO coupe sa capture. */
  const [autoSubmitSignal, setAutoSubmitSignal] = useState(0);

  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pollsRef = useRef(0);
  const cancelledRef = useRef(false);
  const timedOutRef = useRef(false);
  /** Garde l'abandon (finish au démontage en cours d'examen) idempotent. */
  const finishedRef = useRef(false);
  /** Timeout d'abandon programmé au démontage (annulé par un remount StrictMode). */
  const abandonTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const fetchSubs = useCallback(async (): Promise<Map<number, ProductionSubmissionDto>> => {
    const list = await productionApi.listMine({ epreuve: config.epreuve, limit: 100 });
    const m = new Map<number, ProductionSubmissionDto>();
    for (const s of list) {
      if (s.attemptId === attemptId && s.tacheNumero != null) m.set(s.tacheNumero, s);
    }
    return m;
  }, [attemptId, config.epreuve]);

  const startBilanPolling = useCallback(() => {
    pollsRef.current = 0;
    const tick = async () => {
      try {
        const [subs, bil] = await Promise.all([
          fetchSubs(),
          productionApi.getBilan(attemptId).catch(() => null),
        ]);
        if (cancelledRef.current) return;
        setSubsByTache(subs);
        if (bil) setBilan(bil);
        // On arrête quand tout est évalué OU quand l'attempt est finalisé et
        // qu'aucune soumission n'est plus en attente (tâches manquantes = 0).
        const noPending = TACHES.every((n) => {
          const s = subs.get(n);
          return !s || !isSubmissionPending(s);
        });
        const allDone = bil
          ? bil.evaluatedCount >= bil.expectedCount || (bil.finished && noPending)
          : noPending;
        if (!allDone && pollsRef.current < MAX_POLLS) {
          pollsRef.current += 1;
          timerRef.current = setTimeout(tick, POLL_MS);
        }
      } catch {
        // garde l'état courant ; on réessaiera au prochain montage
      }
    };
    void tick();
  }, [fetchSubs, attemptId]);

  useEffect(() => {
    if (status !== "authenticated" || !attemptId) return;
    cancelledRef.current = false;
    (async () => {
      try {
        const [examTasks, subs, attempt] = await Promise.all([
          productionApi.getExamTasks(attemptId),
          fetchSubs(),
          attemptApi.get(attemptId).catch(() => null),
        ]);
        if (cancelledRef.current) return;
        const ordered = [...examTasks].sort((a, b) => a.tacheNumero - b.tacheNumero);
        setTasks(ordered);
        setSubsByTache(subs);

        // Chrono d'épreuve :
        // - Examen module EE (30 min) ou EO (15 min) : ancré sur
        //   `startedAt + timeLimitSeconds` backend (survit au refresh, source
        //   de vérité — c'est lui qui refuse les soumissions hors délai).
        // - Sous-épreuve EE d'examen complet : le backend ne pose pas
        //   `timeLimitSeconds` et ne réaligne pas `startedAt` à l'entrée EE → on
        //   démarre un décompte 30 min côté front à l'arrivée dans l'épreuve.
        // - Sous-épreuve EO d'examen complet : AUCUN chrono local, le temps y
        //   est tenu par le compteur global des 90 min du hub (deux décomptes
        //   concurrents finiraient par se contredire).
        if (attempt && !attempt.finishedAt) {
          if (attempt.timeLimitSeconds != null) {
            const start = new Date(attempt.startedAt).getTime();
            setDeadline(start + attempt.timeLimitSeconds * 1000);
          } else if (config.mode === "text") {
            setDeadline(Date.now() + EE_FALLBACK_LIMIT_SEC * 1000);
          }
        }

        const nextTodo = TACHES.find((n) => !subs.has(n));
        const allSubmitted = nextTodo === undefined;
        // Un attempt déjà finalisé (examen blanc terminé ou abandonné, même
        // avec 0 tâche rendue) ne doit JAMAIS rouvrir l'écriture : on affiche
        // le bilan. Les tâches non rendues apparaissent « Non rendue » et le
        // niveau plancher (A1_NON_ATTEINT) vient du backend (tâches = 0).
        const attemptFinished = attempt?.finishedAt != null;
        if (allSubmitted || attemptFinished) {
          // Flux ACTIF d'un examen complet (l'épreuve vient d'être terminée)
          // → retour au hub de progression. En CONSULTATION depuis le bilan de
          // l'examen complet on a `backTo` (et pas `fullExamId`) → on reste sur
          // le bilan de l'épreuve.
          if (fullExamId && allSubmitted) {
            router.replace(`/examens-blancs/tcf/${fullExamId}`);
            return;
          }
          finishedRef.current = true;
          setPhase("bilan");
          startBilanPolling();
        } else {
          enterTask(nextTodo);
          setPhase("writing");
        }
      } catch (e) {
        if (cancelledRef.current) return;
        setError(e instanceof ApiException ? e.message : "Impossible de charger la session.");
        setPhase("writing");
      }
    })();
    return () => {
      cancelledRef.current = true;
      if (timerRef.current) clearTimeout(timerRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status, attemptId, config.epreuve, config.mode]);

  // Tick du chrono d'épreuve (1 s). On dérive la valeur affichée de la deadline pour
  // survivre à un refresh ; à 0 on déclenche l'auto-soumission une seule fois.
  useEffect(() => {
    if (deadline == null || phase !== "writing") return;
    const tick = () => {
      const left = Math.max(0, (deadline - Date.now()) / 1000);
      setRemaining(left);
      if (left <= 0 && !timedOutRef.current) {
        timedOutRef.current = true;
        setAutoSubmitSignal((s) => s + 1);
      }
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [deadline, phase]);

  // Abandon : si on quitte la page en cours d'examen, on finalise l'attempt
  // (copie ramassée par le backend). Pas pour un examen complet (le hub gère
  // l'abandon globalement) ni quand tout est déjà fini. On programme le finish
  // en `setTimeout(0)` au démontage et on l'annule au (re)montage : en dev le
  // double-montage StrictMode remonte aussitôt → le finish programmé est annulé
  // avant de partir (faux-positif évité), alors qu'un vrai départ de page laisse
  // le timeout s'exécuter.
  useEffect(() => {
    if (abandonTimerRef.current) {
      clearTimeout(abandonTimerRef.current);
      abandonTimerRef.current = null;
    }
    return () => {
      if (finishedRef.current || fullExamId) return;
      abandonTimerRef.current = setTimeout(() => {
        if (finishedRef.current) return;
        finishedRef.current = true;
        void attemptApi.finish(attemptId).catch(() => undefined);
      }, 0);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [attemptId]);

  const currentTask = tasks.find((t) => t.tacheNumero === currentTache) ?? null;

  /** Bascule en bilan après la 3ᵉ tâche (ou auto-finish), avec finish préalable. */
  const goToBilan = useCallback(async () => {
    finishedRef.current = true;
    if (timerRef.current) clearTimeout(timerRef.current);
    await attemptApi.finish(attemptId).catch(() => undefined);
    if (cancelledRef.current) return;
    setPhase("bilan");
    startBilanPolling();
  }, [attemptId, startBilanPolling]);

  async function send(go: (attemptId: string) => Promise<ProductionSubmissionDto>) {
    if (submitting || !currentTask) return;
    setError(null);
    setSubmitting(true);
    try {
      // Attend uniquement la persistance backend (~500 ms, retourne SUBMITTED).
      // L'évaluation IA tourne en arrière-plan — on n'attend pas EVALUATED ici.
      const sub = await go(attemptId);
      if (config.mode === "text") clearEeDraft(currentTask.id);
      const next = new Map(subsByTache);
      next.set(currentTache, sub);
      setSubsByTache(next);
      const nextTodo = TACHES.find((n) => !next.has(n));
      if (nextTodo === undefined) {
        // T3 soumise : dernière tâche de l'épreuve.
        if (fullExamId) {
          finishedRef.current = true;
          try {
            await fullTcfExamApi.markSubDone(fullExamId, config.epreuve);
          } catch {
            // Fallback : le backend pose finishedAt dès que la 3ᵉ submission
            // est traitée (ProductionEvaluationService.finishSubAttemptIfFullExam).
          }
          router.push(`/examens-blancs/tcf/${fullExamId}`);
        } else {
          await goToBilan();
        }
      } else {
        enterTask(nextTodo);
      }
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) setPaywallOpen(true);
      else setError(e instanceof ApiException ? e.message : "Impossible d'envoyer votre réponse.");
    } finally {
      setSubmitting(false);
    }
  }

  /** Lance la session temps réel pour la tâche courante. */
  async function startRealtimeTask() {
    if (!currentTask || rtStarting) return;
    setRtError(null);
    setRtStarting(true);
    try {
      const res = await rt.start(currentTask.id, attemptId);
      if (res.kind === "realtime") {
        setActiveDescriptor(res.descriptor);
        setTaskMode("realtime");
      } else if (res.kind === "paywall") {
        setRtRefused(true);
        setPaywallOpen(true);
        setTaskMode("classic");
      } else if (res.kind === "error") {
        // Refus du backend (épreuve terminée, temps écoulé, tâche déjà rendue)
        // ou panne de connexion : on montre le message dans la feuille et on
        // laisse l'enregistrement classique comme seule voie.
        setRtRefused(true);
        setRtError(res.message);
      } else {
        // Quota épuisé / non éligible : bascule silencieuse en classique.
        setRtRefused(true);
        setTaskMode("classic");
      }
    } finally {
      setRtStarting(false);
    }
  }

  // Choix du mode EO T1/T2, déclenché par le bouton « démarrer » du formulaire une
  // fois le sujet lu. askMode ouvre la modal et rend une promesse résolue par ses
  // callbacks : « classic » → EoRecordingForm enregistre ; « realtime » →
  // startRealtimeTask ; « cancel » → retour au sujet.
  const modeResolverRef = useRef<((c: "classic" | "realtime" | "cancel") => void) | null>(null);
  const askMode = useCallback((): Promise<"classic" | "realtime" | "cancel"> => {
    setTaskMode("choosing");
    return new Promise((resolve) => {
      modeResolverRef.current = resolve;
    });
  }, []);
  const resolveMode = useCallback((choice: "classic" | "realtime" | "cancel") => {
    modeResolverRef.current?.(choice);
    modeResolverRef.current = null;
  }, []);

  /** Après une session temps réel, le backend a créé la submission : on la
   *  détecte (poll court) puis on avance le stepper, comme `send()` en async. */
  async function advanceAfterRealtime(evaluated: boolean) {
    let subs = subsByTache;
    // On ne poll la submission que si le candidat a parlé (sinon aucune n'est
    // créée : session sans réponse → tâche sautée, comptée « non rendue » au bilan).
    if (evaluated) {
      for (let i = 0; i < 5; i++) {
        const fresh = await fetchSubs().catch(() => null);
        if (fresh && fresh.has(currentTache)) {
          subs = fresh;
          break;
        }
        await new Promise((r) => setTimeout(r, 700));
      }
    }
    setSubsByTache(subs);
    // La tâche courante est traitée (évaluée OU sautée sans prise de parole) :
    // on l'exclut pour ne pas y revenir en boucle quand il n'y a pas de submission.
    const handled = new Set(subs.keys());
    handled.add(currentTache);
    const nextTodo = TACHES.find((n) => !handled.has(n));
    if (nextTodo === undefined) {
      if (fullExamId) {
        finishedRef.current = true;
        await fullTcfExamApi.markSubDone(fullExamId, config.epreuve).catch(() => undefined);
        router.push(`/examens-blancs/tcf/${fullExamId}`);
      } else {
        await goToBilan();
      }
    } else {
      enterTask(nextTodo);
    }
  }

  /** Chrono à 0:00 (examen entier) : auto-soumet la production de la tâche
   *  courante si elle est recevable, puis finalise l'épreuve — quelle que soit la
   *  tâche en cours (les tâches non rendues sont comptées 0). */
  const finalizeExam = useCallback(async () => {
    if (finishedRef.current) return;
    finishedRef.current = true;
    if (timerRef.current) clearTimeout(timerRef.current);
    if (fullExamId) {
      await fullTcfExamApi.markSubDone(fullExamId, config.epreuve).catch(() => undefined);
      if (!cancelledRef.current) router.push(`/examens-blancs/tcf/${fullExamId}`);
    } else {
      await attemptApi.finish(attemptId).catch(() => undefined);
      if (cancelledRef.current) return;
      setPhase("bilan");
      startBilanPolling();
    }
  }, [attemptId, fullExamId, config.epreuve, router, startBilanPolling]);

  const onEeTimeout = useCallback(
    async (texte: string, recevable: boolean) => {
      if (recevable && texte && currentTask && !submitting) {
        setSubmitting(true);
        try {
          await productionApi.submitText({
            productionTaskId: currentTask.id,
            attemptId,
            texte,
          });
          clearEeDraft(currentTask.id);
        } catch {
          // best-effort : la copie courante est ramassée par le finish backend
        } finally {
          setSubmitting(false);
        }
      }
      await finalizeExam();
    },
    [submitting, currentTask, attemptId, finalizeExam],
  );

  /** Idem côté oral : la capture coupée à 0:00 part quand même en évaluation
   *  (le backend tolère 60 s de grâce), puis l'épreuve est finalisée. */
  const onEoTimeout = useCallback(
    async (audio: Blob | null) => {
      if (audio && audio.size > 0 && currentTask && !submitting) {
        setSubmitting(true);
        try {
          await productionApi.submitAudio(currentTask.id, attemptId, audio);
        } catch {
          // best-effort : les tâches non rendues sont comptées 0 par le bilan
        } finally {
          setSubmitting(false);
        }
      }
      await finalizeExam();
    },
    [submitting, currentTask, attemptId, finalizeExam],
  );

  // Expiration pendant un échange avec l'examinateur temps réel : le runner ne
  // reçoit pas de signal (il n'a rien à rendre), on finalise directement.
  useEffect(() => {
    if (autoSubmitSignal <= 0 || taskMode !== "realtime") return;
    void finalizeExam();
  }, [autoSubmitSignal, taskMode, finalizeExam]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/session/${attemptId}`} />;

  const submitLabel =
    currentTache < 3
      ? "Valider et continuer"
      : fullExamId
        ? "Valider et passer à l'épreuve suivante"
        : "Valider et terminer";

  const chronoActive = deadline != null && phase === "writing";
  const chronoSec = remaining ?? 0;
  const chronoUrgent = chronoActive && chronoSec <= 300;

  return (
    <DualChromeShell>
      <DetailShell
        backHref={
          backTo ?? (fullExamId ? `/examens-blancs/tcf/${fullExamId}` : `${config.base}/examens`)
        }
        backLabel={backTo ? "Bilan de l'examen" : fullExamId ? "Examen complet" : "Examens blancs"}
        eyebrowIcon={
          config.mode === "audio" ? (
            <Mic size={18} strokeWidth={2} />
          ) : (
            <PenLine size={18} strokeWidth={2} />
          )
        }
        eyebrow={config.label}
        title={phase === "bilan" ? "Bilan de la session" : "Examen blanc"}
        subtitle={
          phase === "bilan"
            ? "Le niveau global est calculé sur vos 3 tâches une fois évaluées."
            : config.mode === "text"
              ? "3 tâches enchaînées en 30 minutes — évaluation IA à la fin."
              : chronoActive
                ? "3 tâches enchaînées en 15 minutes, chacune limitée en temps de parole — évaluation IA à la fin."
                : "3 tâches enchaînées, chronométrées par tâche — évaluation IA à la fin."
        }
      >
        {/* Chrono d'épreuve permanent (EE 30:00, EO 15:00) */}
        {chronoActive && (
          <div className={`${skill.chrono} ${chronoUrgent ? skill.chronoUrgent : ""}`}>
            <span className={skill.chronoLabel}>
              <Timer size={15} strokeWidth={2} aria-hidden />
              Temps restant
            </span>
            <span className={skill.chronoTime}>{fmtChrono(chronoSec)}</span>
          </div>
        )}

        {/* Stepper T1 → T2 → T3 (pendant la saisie uniquement) */}
        {phase !== "bilan" && (
          <ol className={prod.stepper} aria-label="Progression des tâches">
            {TACHES.map((n) => {
              const done = subsByTache.has(n);
              const current = phase === "writing" && n === currentTache;
              return (
                <li
                  key={n}
                  className={`${prod.stepperItem} ${
                    done ? prod.stepperDone : current ? prod.stepperCurrent : ""
                  }`}
                >
                  <span className={prod.stepperDot} aria-hidden>
                    {done ? <Check size={13} strokeWidth={3} /> : n}
                  </span>
                  <span className={prod.stepperLabel}>Tâche {n}</span>
                </li>
              );
            })}
          </ol>
        )}

        {error && <div className={detail.error}>{error}</div>}

        {phase === "loading" ? (
          <div className={detail.loading}>Chargement de la session…</div>
        ) : phase === "writing" ? (
          currentTask ? (
            config.mode === "audio" ? (
              taskMode === "realtime" && activeDescriptor ? (
                <RealtimeEoRunner
                  descriptor={activeDescriptor}
                  task={currentTask}
                  taskTitle={productionTaskTitle(config.epreuve, currentTask.tacheNumero)}
                  onFinished={(evaluated) => advanceAfterRealtime(evaluated)}
                  onFatalError={(m) => {
                    setRtError(m);
                    setTaskMode("classic");
                  }}
                />
              ) : (
                <EoRecordingForm
                  key={currentTask.id}
                  task={currentTask}
                  submitting={submitting}
                  error={rtError}
                  submitLabel={submitLabel}
                  exerciseTitle={productionTaskTitle(config.epreuve, currentTask.tacheNumero)}
                  examMode
                  timeoutSignal={autoSubmitSignal}
                  onTimeout={onEoTimeout}
                  onModeChoice={
                    !rtRefused &&
                    (currentTask.tacheNumero === 1 || currentTask.tacheNumero === 2)
                      ? askMode
                      : undefined
                  }
                  onSubmit={(audio) =>
                    send((aid) => productionApi.submitAudio(currentTask.id, aid, audio))
                  }
                />
              )
            ) : (
              <EeWritingForm
                key={currentTask.id}
                task={currentTask}
                submitting={submitting}
                submitLabel={submitLabel}
                exerciseTitle={productionTaskTitle(config.epreuve, currentTask.tacheNumero)}
                autoSubmitSignal={autoSubmitSignal}
                onAutoSubmit={onEeTimeout}
                onSubmit={(texte) =>
                  send((aid) =>
                    productionApi.submitText({ productionTaskId: currentTask.id, attemptId: aid, texte }),
                  )
                }
              />
            )
          ) : (
            <p className={detail.empty}>Sujets indisponibles pour l&apos;instant.</p>
          )
        ) : (
          <BilanView
            config={config}
            subsByTache={subsByTache}
            bilan={bilan}
            backTo={backTo}
            onOpenResult={(id) => {
              // `back` = ce bilan (URL courante) pour que le bouton retour du
              // rapport de tâche revienne ici, pas au hub de l'épreuve.
              const back = encodeURIComponent(
                `${window.location.pathname}${window.location.search}`,
              );
              router.push(`${config.base}/resultats/${id}?back=${back}`);
            }}
          />
        )}

        {phase === "writing" && currentTask && config.mode === "audio" && (
          <RealtimeLaunchSheet
            open={taskMode === "choosing"}
            tacheNumero={currentTask.tacheNumero}
            taskTitle={productionTaskTitle(config.epreuve, currentTask.tacheNumero)}
            sessionsRemaining={rt.remaining}
            cap={rt.cap}
            starting={rtStarting}
            error={rtError}
            onPickRealtime={() => {
              resolveMode("realtime");
              startRealtimeTask();
            }}
            onPickClassic={() => {
              setTaskMode("classic");
              resolveMode("classic");
            }}
            // Paywall par-dessus le modal ; on résout « cancel » (rien n'a été
            // lancé) et on revient au sujet — retaper « démarrer » rouvre le choix.
            onPaywall={() => {
              setTaskMode("classic");
              resolveMode("cancel");
              setPaywallOpen(true);
            }}
            onClose={() => {
              setTaskMode("classic");
              resolveMode("cancel");
            }}
          />
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title={`Débloquez l'examen blanc ${config.shortLabel}`}
          message="L'examen blanc complet est réservé aux abonnés Intégral."
        />
      </DetailShell>
    </DualChromeShell>
  );
}

const CECRL_SCALE: NiveauCecrl[] = ["A1", "A2", "B1", "B2"];

/** Conseil « prochaines étapes » selon le niveau plancher (calqué mobile). */
function nextStepsMessage(level: NiveauCecrl | null): string {
  switch (level) {
    case "C2":
    case "C1":
      return "Bravo, votre français est avancé. Le TCF IRN, lui, s'arrête à B2 : vous êtes au-dessus du palier le plus haut demandé.";
    case "B2":
      return "Excellent — niveau B2 sur cette épreuve, le palier demandé pour la naturalisation. Il se juge dans les 4 épreuves sans moyenne : gardez ce niveau partout.";
    case "B1":
      return "Niveau B1 sur cette épreuve — le palier demandé pour la carte de résident, à condition de l'atteindre aussi dans les 3 autres épreuves. Travaillez la richesse du vocabulaire pour viser B2.";
    case "A2":
      return "Niveau A2 sur cette épreuve — le palier demandé pour la carte de séjour pluriannuelle, à condition de l'atteindre aussi dans les 3 autres épreuves. Renforcez la grammaire et la longueur de vos productions pour viser B1.";
    case "A1":
      return "Les bases sont là. Entraînez-vous régulièrement sur des phrases plus complètes pour progresser vers A2.";
    case "A1_NON_ATTEINT":
      return "Reprenez les bases : des phrases courtes et correctes d'abord. Chaque entraînement compte.";
    default:
      return "Dès que l'IA a évalué vos 3 tâches, votre niveau plancher s'affiche ici avec des conseils ciblés.";
  }
}

/**
 * Bilan d'une session de production (3 tâches), calqué sur le mobile : hero bleu
 * (note moyenne + niveau global du backend + échelle CECRL), détail par tâche
 * cliquable, conseil « prochaines étapes » dérivé du niveau global. Quand
 * l'attempt est `finished` mais < 3 tâches évaluées, les tâches jamais rendues
 * s'affichent « Non rendue » (pas de polling infini) et le niveau global
 * s'affiche dès que le backend le renvoie (manquantes comptées 0).
 */
function BilanView({
  config,
  subsByTache,
  bilan,
  backTo,
  onOpenResult,
}: {
  config: ProductionConfig;
  subsByTache: Map<number, ProductionSubmissionDto>;
  bilan: ProductionBilanResponse | null;
  backTo: string | null;
  onOpenResult: (submissionId: string) => void;
}) {
  const finished = bilan?.finished ?? false;
  // Tant que l'attempt n'est pas finalisé, une tâche soumise non évaluée reste
  // « en cours ». Une fois finalisé, plus aucune attente (les manquantes = 0).
  const anyPending =
    !finished &&
    TACHES.some((n) => {
      const s = subsByTache.get(n);
      return s && isSubmissionPending(s);
    });

  const avgNote = bilan?.moyenneSur20 ?? null;
  const niveauGlobal = bilan?.niveauGlobal ?? null;
  const targetIdx = niveauGlobal != null ? cecrlIndex(niveauGlobal) : -1;
  const correspondance = correspondanceTcfPhrase(bilan?.correspondanceTcf);

  return (
    <>
      {/* Hero bleu : note moyenne + niveau global (examen blanc) + échelle CECRL */}
      <div className={prod.sessHero}>
        <div className={prod.sessHeroEyebrow}>BILAN DE LA SESSION</div>
        <div className={prod.sessHeroRow}>
          <div>
            <div className={prod.sessHeroNoteLabel}>Note moyenne</div>
            <div className={prod.sessHeroNote}>
              {avgNote != null ? formatNoteSur20(avgNote) : "—"}
              <span className={prod.sessHeroNoteOf}>/20</span>
            </div>
          </div>
          <div className={prod.sessHeroSide}>
            <div className={prod.sessHeroSideLabel}>Niveau global</div>
            {niveauGlobal != null ? (
              <span className={prod.sessHeroBadge}>{niveauCecrlLabel(niveauGlobal)}</span>
            ) : (
              <span className={prod.sessHeroBadgePending}>Évaluation en cours…</span>
            )}
          </div>
        </div>
        {niveauGlobal != null && (
          <>
            <div className={prod.sessScale} aria-hidden>
              {CECRL_SCALE.map((lvl, i) => (
                <span
                  key={lvl}
                  className={`${prod.sessSeg} ${
                    i === targetIdx
                      ? prod.sessSegTarget
                      : i < targetIdx
                        ? prod.sessSegOn
                        : ""
                  }`}
                />
              ))}
            </div>
            <div className={prod.sessScaleLabels} aria-hidden>
              {CECRL_SCALE.map((lvl) => (
                <span key={lvl}>{lvl}</span>
              ))}
            </div>
          </>
        )}
        {correspondance && (
          <div className={prod.sessTcf}>
            <p className={prod.sessTcfPhrase}>{correspondance}</p>
            <p className={prod.sessTcfSource}>
              Grille officielle du TCF IRN. Notre note ci-dessus utilise la même
              échelle et porte, comme au TCF, sur l&apos;épreuve entière.
            </p>
          </div>
        )}
      </div>

      {anyPending && (
        <div className={prod.sessEvalBanner}>
          <span className={prod.spinner} aria-hidden />
          L&apos;IA évalue vos productions — encore quelques secondes…
        </div>
      )}

      <div className={prod.sessSectionLabel}>DÉTAIL PAR TÂCHE</div>
      <p className={prod.sessSectionSub}>
        Touchez une tâche pour revoir l&apos;évaluation détaillée.
      </p>

      <div className={prod.sessTacheList}>
        {TACHES.map((n) => {
          const s = subsByTache.get(n);
          const pending = s ? isSubmissionPending(s) : false;
          const evaluatedOk = s?.statut === "EVALUATED";
          const failed = s?.statut === "FAILED";
          const note = s?.evaluation?.noteSurVingt;
          return (
            <button
              key={n}
              type="button"
              className={prod.sessTache}
              disabled={!s || pending}
              onClick={() => s && onOpenResult(s.id)}
            >
              <span className={`${prod.sessTacheNum} ${evaluatedOk ? prod.sessTacheNumDone : ""}`}>
                {evaluatedOk ? <Check size={15} strokeWidth={3} /> : n}
              </span>
              <span className={prod.sessTacheBody}>
                <span className={prod.sessTacheTitle}>
                  {productionTaskTitle(config.epreuve, n)}
                </span>
                <span
                  className={`${prod.sessTacheSub} ${
                    pending ? prod.sessTacheSubPending : failed ? prod.sessTacheSubFail : ""
                  }`}
                >
                  {!s
                    ? finished
                      ? "Non rendue"
                      : "Non soumise"
                    : failed
                      ? "Évaluation échouée — à relancer"
                      : pending
                        ? "Évaluation IA en cours…"
                        : note != null
                          ? `Note ${formatNoteSur20(note)}/20`
                          : "Évaluée"}
                </span>
              </span>
              {/* La note vit dans le sous-titre (« Note 10/20 »), comme sur
                  mobile : la pastille la répétait mot pour mot sur la même
                  ligne. */}
              {s && !pending && (
                <ChevronRight size={18} className={prod.sessTacheChevron} aria-hidden />
              )}
            </button>
          );
        })}
      </div>

      {niveauGlobal != null && (
        <div className={prod.sessNext}>
          <p className={prod.sessNextTitle}>
            <Lightbulb size={16} aria-hidden /> Tes prochaines étapes
          </p>
          <p className={prod.sessNextBody}>{nextStepsMessage(niveauGlobal)}</p>
        </div>
      )}

      <div className={prod.bilanFoot}>
        {backTo ? (
          <Link href={backTo} className="btn btn-blue">
            Retour au bilan de l&apos;examen
          </Link>
        ) : (
          <Link href={`${config.base}/examens`} className="btn btn-blue">
            Voir les examens blancs
          </Link>
        )}
      </div>
    </>
  );
}
