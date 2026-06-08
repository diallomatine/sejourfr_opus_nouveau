"use client";

import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { Check, FileStack, GraduationCap, Mic, PenLine, Play, Sparkles } from "lucide-react";
import { ApiException, fullTcfExamApi, productionApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  cecrlIndex,
  isSubmissionPending,
  niveauCecrlLabel,
  type NiveauCecrl,
  productionTaskTitle,
  type ProductionSubmissionDto,
  type ProductionTaskDto,
  resolveTcfLevel,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, DetailStatCard } from "@/app/_components/hub/DetailParts";
import { EeWritingForm, clearEeDraft } from "./EeWritingForm";
import { EoRecordingForm } from "./EoRecordingForm";
import { type ProductionConfig } from "./config";
import detail from "@/app/_components/hub/detail.module.css";
import prod from "./production.module.css";

const TACHES = [1, 2, 3] as const;
const POLL_MS = 3000;
const MAX_POLLS = 40;

/**
 * Session d'examen blanc d'une épreuve productive : 3 tâches enchaînées
 * partageant un même attempt, puis bilan avec niveau CECRL plancher. La phase
 * (saisie vs bilan) est dérivée des soumissions existantes (resume naturel).
 */
export function ProductionSession({ config }: { config: ProductionConfig }) {
  const params = useParams<{ attemptId: string }>();
  const attemptId = params?.attemptId ?? "";
  const router = useRouter();
  const searchParams = useSearchParams();
  /** Présent quand cette session est une épreuve d'un examen blanc TCF complet :
   *  on saute le bilan individuel et on retourne au hub de progression. */
  const fullExamId = searchParams.get("fullExamId");
  const { user, status } = useAuth();
  const level = resolveTcfLevel(user);

  const [tasks, setTasks] = useState<ProductionTaskDto[]>([]);
  const [subsByTache, setSubsByTache] = useState<Map<number, ProductionSubmissionDto>>(new Map());
  const [phase, setPhase] = useState<"loading" | "writing" | "bilan">("loading");
  const [currentTache, setCurrentTache] = useState<number>(1);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pollsRef = useRef(0);
  const cancelledRef = useRef(false);

  const pickTasks = useCallback((all: ProductionTaskDto[]): ProductionTaskDto[] => {
    const out: ProductionTaskDto[] = [];
    for (const n of TACHES) {
      const candidates = all
        .filter((t) => t.tacheNumero === n)
        .sort((a, b) => a.id.localeCompare(b.id));
      if (candidates[0]) out.push(candidates[0]);
    }
    return out;
  }, []);

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
        const subs = await fetchSubs();
        if (cancelledRef.current) return;
        setSubsByTache(subs);
        const allDone = TACHES.every((n) => {
          const s = subs.get(n);
          return s && !isSubmissionPending(s);
        });
        if (!allDone && pollsRef.current < MAX_POLLS) {
          pollsRef.current += 1;
          timerRef.current = setTimeout(tick, POLL_MS);
        }
      } catch {
        // garde l'état courant ; on réessaiera au prochain montage
      }
    };
    void tick();
  }, [fetchSubs]);

  useEffect(() => {
    if (status !== "authenticated" || !attemptId) return;
    cancelledRef.current = false;
    (async () => {
      try {
        const [allTasks, subs] = await Promise.all([
          productionApi.listTasks({ epreuve: config.epreuve, niveau: level }),
          fetchSubs(),
        ]);
        if (cancelledRef.current) return;
        setTasks(pickTasks(allTasks));
        setSubsByTache(subs);
        const nextTodo = TACHES.find((n) => !subs.has(n));
        if (nextTodo === undefined) {
          // Reprise d'une épreuve d'examen complet déjà soumise : pas de bilan
          // individuel, on renvoie au hub (la sous-épreuve y est déjà terminée).
          if (fullExamId) {
            router.replace(`/tcf/examen-blanc/${fullExamId}`);
            return;
          }
          setPhase("bilan");
          startBilanPolling();
        } else {
          setCurrentTache(nextTodo);
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
  }, [status, attemptId, level, config.epreuve]);

  const currentTask = tasks.find((t) => t.tacheNumero === currentTache) ?? null;

  async function send(go: (attemptId: string) => Promise<ProductionSubmissionDto>) {
    if (submitting || !currentTask) return;
    setError(null);
    setSubmitting(true);
    try {
      // Attend uniquement la persistance backend (~500 ms, retourne SUBMITTED).
      // L'évaluation IA tourne en arrière-plan — on n'attend pas EVALUATED ici,
      // exactement comme le mobile : T1/T2 enchaînent sans latence d'éval.
      const sub = await go(attemptId);
      if (config.mode === "text") clearEeDraft(currentTask.id);
      const next = new Map(subsByTache);
      next.set(currentTache, sub);
      setSubsByTache(next);
      const nextTodo = TACHES.find((n) => !next.has(n));
      if (nextTodo === undefined) {
        // T3 soumise : dernière tâche de l'épreuve.
        if (fullExamId) {
          // Examen complet : signaler la sous-épreuve terminée (sans attendre
          // l'IA) puis revenir au hub, qui débloque l'épreuve suivante.
          try {
            await fullTcfExamApi.markSubDone(fullExamId, config.epreuve);
          } catch {
            // Fallback : le backend pose finishedAt dès que la 3ᵉ submission
            // est traitée (ProductionEvaluationService.finishSubAttemptIfFullExam).
          }
          router.push(`/tcf/examen-blanc/${fullExamId}`);
        } else {
          setPhase("bilan");
          startBilanPolling();
        }
      } else {
        setCurrentTache(nextTodo);
      }
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) setPaywallOpen(true);
      else setError(e instanceof ApiException ? e.message : "Impossible d'envoyer votre réponse.");
    } finally {
      setSubmitting(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/session/${attemptId}`} />;

  const submitLabel =
    currentTache < 3
      ? "Valider et continuer"
      : fullExamId
        ? "Valider et passer à l'épreuve suivante"
        : "Valider et terminer";

  return (
    <DualChromeShell>
      <DetailShell
        backHref={fullExamId ? `/tcf/examen-blanc/${fullExamId}` : `${config.base}/examens`}
        backLabel={fullExamId ? "Examen complet" : "Examens blancs"}
        eyebrowIcon={
          config.mode === "audio" ? (
            <Mic size={18} strokeWidth={2} />
          ) : (
            <PenLine size={18} strokeWidth={2} />
          )
        }
        eyebrow={config.label}
        title={phase === "bilan" ? "Bilan de l'examen blanc" : "Examen blanc"}
        subtitle={
          phase === "writing"
            ? `3 tâches enchaînées, niveau ${level} — évaluation IA à la fin.`
            : `Niveau ${level} · le niveau global retenu est le plancher de vos 3 tâches.`
        }
      >
        {/* Stepper T1 → T2 → T3 */}
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

        {error && <div className={detail.error}>{error}</div>}

        {phase === "loading" ? (
          <div className={detail.loading}>Chargement de la session…</div>
        ) : phase === "writing" ? (
          currentTask ? (
            config.mode === "audio" ? (
              <EoRecordingForm
                key={currentTask.id}
                task={currentTask}
                submitting={submitting}
                submitLabel={submitLabel}
                onSubmit={(audio) =>
                  send((aid) => productionApi.submitAudio(currentTask.id, aid, audio))
                }
              />
            ) : (
              <EeWritingForm
                key={currentTask.id}
                task={currentTask}
                submitting={submitting}
                submitLabel={submitLabel}
                onSubmit={(texte) =>
                  send((aid) =>
                    productionApi.submitText({ productionTaskId: currentTask.id, attemptId: aid, texte }),
                  )
                }
              />
            )
          ) : (
            <p className={detail.empty}>
              Sujets indisponibles pour le niveau {level} pour l&apos;instant.
            </p>
          )
        ) : (
          <BilanView
            config={config}
            subsByTache={subsByTache}
            onOpenResult={(id) => router.push(`${config.base}/resultats/${id}`)}
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

function BilanView({
  config,
  subsByTache,
  onOpenResult,
}: {
  config: ProductionConfig;
  subsByTache: Map<number, ProductionSubmissionDto>;
  onOpenResult: (submissionId: string) => void;
}) {
  const evaluated = TACHES.map((n) => subsByTache.get(n)).filter(
    (s): s is ProductionSubmissionDto => !!s && s.statut === "EVALUATED",
  );
  const anyPending = TACHES.some((n) => {
    const s = subsByTache.get(n);
    return s && isSubmissionPending(s);
  });

  let plancher: NiveauCecrl | null = null;
  for (const s of evaluated) {
    const niv = s.evaluation?.niveauCecrl ?? null;
    if (!niv) continue;
    if (plancher === null || cecrlIndex(niv) < cecrlIndex(plancher)) plancher = niv;
  }
  const notes = evaluated
    .map((s) => s.evaluation?.noteSurVingt)
    .filter((v): v is number => v != null);
  const avgNote = notes.length
    ? Math.round((notes.reduce((sum, v) => sum + v, 0) / notes.length) * 10) / 10
    : null;

  return (
    <>
      <div className={detail.statCards}>
        <DetailStatCard
          icon={<GraduationCap size={20} />}
          tone="green"
          value={
            anyPending && evaluated.length < TACHES.length
              ? "…"
              : niveauCecrlLabel(plancher)
          }
          label="Niveau global"
          sub="plancher des 3 tâches"
        />
        <DetailStatCard
          icon={<Sparkles size={20} />}
          tone="blue"
          value={avgNote != null ? `${formatNote(avgNote)}/20` : "—"}
          label="Note moyenne"
          sub="sur les tâches évaluées"
        />
        <DetailStatCard
          icon={<FileStack size={20} />}
          tone="red"
          value={`${evaluated.length}/3`}
          label="Tâches évaluées"
          sub={anyPending ? "évaluation IA en cours…" : "par l'IA"}
        />
      </div>

      <div className={detail.serieGrid}>
        {TACHES.map((n) => {
          const s = subsByTache.get(n);
          const pending = s ? isSubmissionPending(s) : false;
          const evaluatedOk = s?.statut === "EVALUATED";
          const note = s?.evaluation?.noteSurVingt;
          const sub = !s
            ? "Non soumise"
            : s.statut === "FAILED"
              ? "Évaluation échouée"
              : pending
                ? "Évaluation en cours…"
                : `Niveau ${niveauCecrlLabel(s.evaluation?.niveauCecrl)}`;
          return (
            <button
              key={n}
              type="button"
              className={detail.serieCard}
              disabled={!s}
              onClick={() => s && onOpenResult(s.id)}
            >
              <span
                className={`${detail.serieNum} ${evaluatedOk ? detail.serieNumDone : ""}`}
              >
                T{n}
                {evaluatedOk && (
                  <span className={detail.serieCheck} aria-hidden>
                    <Check size={11} strokeWidth={3} />
                  </span>
                )}
              </span>
              <span className={detail.serieBody}>
                <span className={detail.serieTitle}>
                  {productionTaskTitle(config.epreuve, n)}
                </span>
                <span className={detail.serieSub}>{sub}</span>
                {note != null && evaluatedOk && (
                  <span className={`${detail.serieBadge} ${detail.serieBadgeDone}`}>
                    <Check size={12} aria-hidden /> {formatNote(note)}/20
                  </span>
                )}
              </span>
              {s && (
                <span className={detail.serieAction} aria-hidden>
                  <Play size={18} />
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div className={prod.bilanFoot}>
        <Link href={`${config.base}/examens`} className="btn btn-blue">
          Terminer
        </Link>
      </div>
    </>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
