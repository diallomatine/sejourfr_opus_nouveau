"use client";

import Link from "next/link";
import {useParams, useRouter} from "next/navigation";
import {useCallback, useEffect, useRef, useState} from "react";
import {ChevronRight} from "lucide-react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  cecrlIndex,
  eeTaskTitle,
  isSubmissionPending,
  niveauCecrlLabel,
  type NiveauCecrl,
  type ProductionSubmissionDto,
  type ProductionTaskDto,
  resolveTcfLevel,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {EeWritingForm, clearEeDraft} from "@/app/_components/production/EeWritingForm";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "@/app/_components/production/production.module.css";

const TACHES = [1, 2, 3] as const;
const POLL_MS = 3000;
const MAX_POLLS = 40;

/**
 * Session d'examen blanc EE : 3 tâches enchaînées partageant un même attempt,
 * puis bilan avec niveau CECRL plancher. Parité `EeSessionController` +
 * `HistorySessionScreen` mobile. La phase (rédaction vs bilan) est dérivée des
 * soumissions existantes — pas de query param (resume naturel + compat SSR).
 */
export default function EeSessionPage() {
  const params = useParams<{attemptId: string}>();
  const attemptId = params?.attemptId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();
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

  /** Pioche une tâche par numéro (1/2/3) au niveau visé, déterministe. */
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
    const list = await productionApi.listMine({epreuve: "TCF_EE", limit: 100});
    const m = new Map<number, ProductionSubmissionDto>();
    for (const s of list) {
      if (s.attemptId === attemptId && s.tacheNumero != null) m.set(s.tacheNumero, s);
    }
    return m;
  }, [attemptId]);

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

  // Chargement initial : tâches + soumissions existantes → décide la phase.
  useEffect(() => {
    if (status !== "authenticated" || !attemptId) return;
    cancelledRef.current = false;
    (async () => {
      try {
        const [allTasks, subs] = await Promise.all([
          productionApi.listTasks({epreuve: "TCF_EE", niveau: level}),
          fetchSubs(),
        ]);
        if (cancelledRef.current) return;
        setTasks(pickTasks(allTasks));
        setSubsByTache(subs);
        const nextTodo = TACHES.find((n) => !subs.has(n));
        if (nextTodo === undefined) {
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
  }, [status, attemptId, level]);

  const currentTask = tasks.find((t) => t.tacheNumero === currentTache) ?? null;

  async function submit(texte: string) {
    if (submitting || !currentTask) return;
    setError(null);
    setSubmitting(true);
    try {
      const sub = await productionApi.submitText({
        productionTaskId: currentTask.id,
        attemptId,
        texte,
      });
      clearEeDraft(currentTask.id);
      const next = new Map(subsByTache);
      next.set(currentTache, sub);
      setSubsByTache(next);
      const nextTodo = TACHES.find((n) => !next.has(n));
      if (nextTodo === undefined) {
        setPhase("bilan");
        startBilanPolling();
      } else {
        setCurrentTache(nextTodo);
      }
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) setPaywallOpen(true);
      else setError(e instanceof ApiException ? e.message : "Impossible d'envoyer votre texte.");
    } finally {
      setSubmitting(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/ee/session/${attemptId}`} />;

  const doneCount = TACHES.filter((n) => subsByTache.has(n)).length;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement/tcf/ee/examens"
          title="Examen blanc EE"
          subtitle={
            phase === "writing"
              ? `Tâche ${currentTache} sur 3 · niveau ${level}`
              : `Bilan · niveau ${level}`
          }
        />

        <div className={prod.steps}>
          {TACHES.map((n) => (
            <span
              key={n}
              className={`${prod.step} ${
                subsByTache.has(n)
                  ? prod.stepDone
                  : phase === "writing" && n === currentTache
                    ? prod.stepCurrent
                    : ""
              }`}
            />
          ))}
        </div>

        {error && <div className={prod.error}>{error}</div>}

        {phase === "loading" ? (
          <p className={prod.loading}>Chargement de la session…</p>
        ) : phase === "writing" ? (
          currentTask ? (
            <EeWritingForm
              key={currentTask.id}
              task={currentTask}
              submitting={submitting}
              submitLabel={currentTache < 3 ? "Valider et continuer" : "Valider et terminer"}
              onSubmit={submit}
            />
          ) : (
            <p className={prod.empty}>
              Sujets indisponibles pour le niveau {level} pour l&apos;instant.
            </p>
          )
        ) : (
          <BilanView
            subsByTache={subsByTache}
            doneCount={doneCount}
            onOpenResult={(id) => router.push(`/entrainement/tcf/ee/resultats/${id}`)}
          />
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title="Débloquez l'examen blanc EE"
          message="L'examen blanc d'expression écrite est réservé aux abonnés Intégral."
        />
      </main>
    </DualChromeShell>
  );
}

function BilanView({
  subsByTache,
  doneCount,
  onOpenResult,
}: {
  subsByTache: Map<number, ProductionSubmissionDto>;
  doneCount: number;
  onOpenResult: (submissionId: string) => void;
}) {
  // Niveau plancher = le plus bas des niveaux évalués.
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

  return (
    <>
      <div className={prod.scoreCard} style={{justifyContent: "center", textAlign: "center"}}>
        <div className={prod.scoreSide} style={{flex: "unset"}}>
          <div className={prod.cecrlPill}>
            <span className={prod.cecrlPillLabel}>Niveau global</span>
            <span className={prod.cecrlPillVal}>
              {anyPending && evaluated.length < TACHES.length ? "…" : niveauCecrlLabel(plancher)}
            </span>
          </div>
          <p className={prod.scoreJustif}>
            {anyPending
              ? `Évaluation en cours (${doneCount}/3 tâches soumises)…`
              : "Le niveau global retenu est le plancher de vos 3 tâches."}
          </p>
        </div>
      </div>

      <div className={hub.list}>
        {TACHES.map((n) => {
          const s = subsByTache.get(n);
          const pending = s ? isSubmissionPending(s) : false;
          const note = s?.evaluation?.noteSurVingt;
          const sub = !s
            ? "Non soumise"
            : s.statut === "FAILED"
              ? "Évaluation échouée"
              : pending
                ? "Évaluation en cours…"
                : niveauCecrlLabel(s.evaluation?.niveauCecrl);
          return (
            <button
              key={n}
              type="button"
              className={prod.row}
              disabled={!s}
              onClick={() => s && onOpenResult(s.id)}
            >
              <span className={prod.rowChip}>T{n}</span>
              <span className={prod.rowBody}>
                <span className={prod.rowTitle}>{eeTaskTitle(n)}</span>
                <span className={prod.rowSub}>{sub}</span>
              </span>
              {note != null && s?.statut === "EVALUATED" ? (
                <span
                  className={prod.rowScore}
                  style={{background: "var(--color-blue-soft)", color: "var(--color-blue)"}}
                >
                  {formatNote(note)}/20
                </span>
              ) : null}
              {s ? <ChevronRight size={20} className={prod.rowChevron} /> : null}
            </button>
          );
        })}
      </div>

      <div className={prod.actions}>
        <Link href="/entrainement/tcf/ee" className="btn btn-blue">
          Terminer
        </Link>
      </div>
    </>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}
