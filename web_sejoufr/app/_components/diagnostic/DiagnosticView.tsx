"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useRef, useState, type ReactNode} from "react";
import {
  AlertCircle,
  ArrowLeft,
  ArrowRight,
  Check,
  ChevronDown,
  Clock3,
  FilePenLine,
  Headphones,
  Info,
  Mic,
  RotateCcw,
  Sparkles,
  Target,
  TrendingUp,
  Zap,
} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {EeWritingForm, clearEeDraft} from "@/app/_components/production/EeWritingForm";
import {EoRecordingForm} from "@/app/_components/production/EoRecordingForm";
import {ApiException, diagnosticApi, productionApi} from "@/lib/api";
import {
  trackAudienceEvent,
  withTrafficSource,
} from "@/lib/audience";
import {useAuth} from "@/lib/auth-context";
import {
  DIAGNOSTIC_COMMUNICATION_LABEL,
  DIAGNOSTIC_COMMUNICATION_TONE,
  DIAGNOSTIC_TASK_COMPLETION_LABEL,
  DIAGNOSTIC_TASK_COMPLETION_TONE,
  type DiagnosticExerciseContent,
  type DiagnosticSignalTone,
  diagnosticExerciseAsProductionTask,
  LEARNING_PLAN_SKILL_STATUS_LABEL,
  LEARNING_PLAN_SKILL_STATUS_TONE,
  niveauEstimateLabel,
  productionSectionLabel,
  recommendedExerciseHref,
} from "@/lib/diagnostic";
import {
  clearLocalDiagnostic,
  isLocalDiagnosticComplete,
  readLatestLocalDiagnostic,
  readLocalDiagnostic,
  saveLocalOral,
  saveLocalWritten,
  type LocalDiagnosticProductions,
} from "@/lib/diagnostic-local-store";
import {countEeWords} from "@/lib/ee-word-bounds";
import { evidenceExcerpt } from "@/lib/evidence-excerpt";
import type {
  DiagnosticProductionResultDto,
  DiagnosticResponse,
  DiagnosticSkillObservationDto,
  PublicDiagnosticResponse,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {DiagnosticAccountGate} from "./DiagnosticAccountGate";
import styles from "./diagnostic.module.css";

const POLL_MS = 2_500;

function errorMessage(error: unknown, fallback: string): string {
  return error instanceof ApiException ? error.message : fallback;
}

/**
 * Point d'entrée de `/diagnostic`, ouvert aux visiteurs depuis le 2026-08-10.
 *
 * Deux régimes, volontairement séparés en deux composants :
 *
 * - **invité** — les sujets viennent de l'endpoint public, les deux productions
 *   sont gardées sur l'appareil (IndexedDB), et l'écran de compte n'arrive
 *   qu'une fois l'écrit ET l'oral faits ;
 * - **connecté** — le parcours serveur historique, inchangé : la session décide
 *   de l'étape, l'analyse est pollée, la reprise est cross-device.
 *
 * Le passage de l'un à l'autre ne transporte rien en mémoire : au moment où
 * l'inscription réussit, le composant invité disparaît et le composant connecté
 * relit les productions **sur le disque**. C'est ce qui rend le parcours
 * insensible à un sign-in social qui quitte la page.
 */
export function DiagnosticView() {
  const {status} = useAuth();
  if (status === "loading") return <DiagnosticSkeleton />;
  // `DualChromeShell` porte les deux chromes de la route : sidebar pour un
  // compte, fond applicatif nu pour un visiteur (qui garde le header et le
  // pied de page publics du layout racine).
  return (
    <DualChromeShell>
      {status === "authenticated" ? <ConnectedDiagnostic /> : <GuestDiagnostic />}
    </DualChromeShell>
  );
}

// ============================================================================
// Parcours INVITÉ — produire d'abord, créer le compte ensuite
// ============================================================================

/** Ce qu'on peut encore faire avec les productions déjà posées sur l'appareil. */
type GuestStep = "presentation" | "written" | "oral" | "account";

function guestStep(
  local: LocalDiagnosticProductions | null,
  started: boolean,
): GuestStep {
  const hasWritten = Boolean(local?.writtenText?.trim());
  if (isLocalDiagnosticComplete(local)) return "account";
  if (hasWritten) return "oral";
  return started ? "written" : "presentation";
}

function GuestDiagnostic() {
  const [subjects, setSubjects] = useState<PublicDiagnosticResponse | null>(null);
  const [local, setLocal] = useState<LocalDiagnosticProductions | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [started, setStarted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Faux quand le navigateur a refusé l'écriture disque : la production vit
  // alors seulement dans l'onglet, et on le dit au lieu de le taire.
  const [storedOnDevice, setStoredOnDevice] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const current = await diagnosticApi.publicCurrent();
      setSubjects(current);
      setLocal(
        await readLocalDiagnostic(current.diagnosticCode, current.diagnosticVersion),
      );
    } catch (cause) {
      setError(errorMessage(cause, "Impossible de charger le diagnostic."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const current = await diagnosticApi.publicCurrent();
        if (cancelled) return;
        setSubjects(current);
        const stored = await readLocalDiagnostic(
          current.diagnosticCode,
          current.diagnosticVersion,
        );
        if (!cancelled) setLocal(stored);
      } catch (cause) {
        if (!cancelled) setError(errorMessage(cause, "Impossible de charger le diagnostic."));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    trackAudienceEvent("/diagnostic", "DIAGNOSTIC_VIEWED", {once: true});
  }, []);

  const step = guestStep(local, started);

  useEffect(() => {
    if (step === "account") {
      trackAudienceEvent("/diagnostic", "DIAGNOSTIC_ACCOUNT_REQUIRED", {once: true});
    }
  }, [step]);

  async function keepWritten(text: string) {
    if (!subjects || saving) return;
    setSaving(true);
    setError(null);
    const ok = await saveLocalWritten(
      subjects.diagnosticCode,
      subjects.diagnosticVersion,
      subjects.written.productionTaskId,
      text,
    );
    if (!ok) setStoredOnDevice(false);
    // La mémoire fait foi pour l'écran courant : même si le disque a refusé,
    // le candidat continue son parcours sans rien retaper.
    setLocal((previous) => ({
      diagnosticCode: subjects.diagnosticCode,
      diagnosticVersion: subjects.diagnosticVersion,
      writtenTaskId: subjects.written.productionTaskId,
      writtenText: text,
      oralTaskId: previous?.oralTaskId ?? null,
      oralAudio: previous?.oralAudio ?? null,
      oralDurationSec: previous?.oralDurationSec ?? null,
      savedAt: Date.now(),
    }));
    trackAudienceEvent("/diagnostic", "DIAGNOSTIC_WRITTEN_COMPLETED", {once: true});
    setSaving(false);
  }

  async function keepOral(audio: Blob, durationSec: number) {
    if (!subjects || saving) return;
    setSaving(true);
    setError(null);
    const ok = await saveLocalOral(
      subjects.diagnosticCode,
      subjects.diagnosticVersion,
      subjects.oral.productionTaskId,
      audio,
      durationSec,
    );
    if (!ok) setStoredOnDevice(false);
    setLocal((previous) => ({
      diagnosticCode: subjects.diagnosticCode,
      diagnosticVersion: subjects.diagnosticVersion,
      writtenTaskId: previous?.writtenTaskId ?? null,
      writtenText: previous?.writtenText ?? null,
      oralTaskId: subjects.oral.productionTaskId,
      oralAudio: audio,
      oralDurationSec: durationSec,
      savedAt: Date.now(),
    }));
    trackAudienceEvent("/diagnostic", "DIAGNOSTIC_ORAL_COMPLETED", {once: true});
    setSaving(false);
  }

  if (loading) return <DiagnosticSkeleton />;

  if (!subjects) {
    return (
      <DiagnosticShell guest>
        <StateCard
          icon={<RotateCcw size={26} />}
          title="Le diagnostic n'a pas pu être chargé"
          text={error ?? "Réessayez dans un instant."}
          role="alert"
        >
          <button className={styles.primaryButton} type="button" onClick={() => void load()}>
            Réessayer
          </button>
        </StateCard>
      </DiagnosticShell>
    );
  }

  if (step === "account") {
    return (
      <DiagnosticShell guest>
        <DiagnosticAccountGate
          writtenWords={countEeWords(local?.writtenText ?? "")}
          oralDurationSec={local?.oralDurationSec ?? null}
          storedOnDevice={storedOnDevice}
        />
      </DiagnosticShell>
    );
  }

  if (step === "oral") {
    return (
      <DiagnosticShell guest compact>
        <ExerciseHeader
          kind="oral"
          note={
            storedOnDevice
              ? "Votre écrit est conservé sur cet appareil."
              : "Votre écrit est conservé dans cet onglet."
          }
        />
        <EoRecordingForm
          task={diagnosticExerciseAsProductionTask(subjects.oral)}
          submitting={saving}
          error={error}
          submitLabel="Terminer et analyser"
          promptSlot={<ExercisePrompt exercise={subjects.oral} kind="oral" />}
          criteriaSlot={null}
          maxDurationSec={subjects.oral.durationMaxSeconds}
          onSubmit={(audio, durationSec) => void keepOral(audio, durationSec)}
        />
      </DiagnosticShell>
    );
  }

  if (step === "written") {
    return (
      <DiagnosticShell guest compact>
        <ExerciseHeader kind="written" />
        <EeWritingForm
          task={diagnosticExerciseAsProductionTask(subjects.written)}
          submitting={saving}
          error={error}
          submitLabel="Continuer vers l'oral"
          promptSlot={<ExercisePrompt exercise={subjects.written} kind="written" />}
          criteriaSlot={null}
          onSubmit={(text) => void keepWritten(text)}
        />
      </DiagnosticShell>
    );
  }

  return (
    <DiagnosticShell guest>
      <DiagnosticIntro
        error={error}
        submitting={false}
        guest
        onStart={() => {
          setStarted(true);
          trackAudienceEvent("/diagnostic", "DIAGNOSTIC_STARTED", {once: true});
        }}
      />
    </DiagnosticShell>
  );
}

// ============================================================================
// Parcours CONNECTÉ — la session serveur décide de tout
// ============================================================================

/**
 * Reprise des productions faites en invité, une fois le compte créé.
 *
 * `idle` = rien à reprendre (parcours connecté normal). Les trois états
 * terminaux disent une vérité différente au candidat, et **aucun** n'efface le
 * travail local : seul un envoi complet le fait.
 */
type Handoff =
  | {kind: "idle"}
  | {kind: "running"; label: string}
  | {kind: "error"; message: string}
  /** Le compte porte déjà un diagnostic terminé : rien n'est envoyé. */
  | {kind: "already-completed"}
  /** Les sujets ont changé de version depuis la production locale. */
  | {kind: "version-mismatch"}
  /** Une des deux tâches avait déjà une soumission : on n'a envoyé que l'autre. */
  | {kind: "partially-reused"};

function ConnectedDiagnostic() {
  const {user} = useAuth();
  const [diagnostic, setDiagnostic] = useState<DiagnosticResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [handoff, setHandoff] = useState<Handoff>({kind: "idle"});
  const [pendingLocal, setPendingLocal] = useState<LocalDiagnosticProductions | null>(null);
  const trafficSource = useTrafficSource();
  const previousJourneyStatus = useRef<DiagnosticResponse["status"] | null>(null);

  const loadCurrent = useCallback(async () => {
    setError(null);
    setLoading(true);
    try {
      setDiagnostic(await diagnosticApi.current());
    } catch (cause) {
      setError(errorMessage(cause, "Impossible de charger votre diagnostic."));
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Relit la session jusqu'à ce qu'elle reconnaisse la soumission qu'on vient
   * de faire. La création de la submission et le calcul de l'étape de reprise
   * peuvent tomber dans deux transactions successives : quelques relectures
   * courtes évitent de redemander une production déjà reçue.
   */
  const refreshAfterSubmission = useCallback(
    async (sessionId: string, submittedStep: "WRITTEN" | "ORAL") => {
      let fresh = await diagnosticApi.get(sessionId);
      setDiagnostic(fresh);
      for (let attempt = 0; attempt < 6; attempt += 1) {
        const submitted = submittedStep === "WRITTEN" ? fresh.written : fresh.oral;
        if (
          fresh.status !== "IN_PROGRESS" ||
          fresh.nextStep !== submittedStep ||
          submitted?.submissionId != null
        ) {
          return fresh;
        }
        await new Promise((resolve) => setTimeout(resolve, 700));
        fresh = await diagnosticApi.get(sessionId);
        setDiagnostic(fresh);
      }
      return fresh;
    },
    [],
  );

  /**
   * Envoie au serveur les deux productions faites en invité.
   *
   * Ordre **strict** : session d'abord, écrit ensuite, oral enfin, et le
   * stockage local n'est effacé qu'une fois que la session reconnaît les
   * **deux** soumissions. Toute sortie anticipée (erreur réseau, diagnostic
   * déjà terminé, sujets d'une autre version) laisse le travail intact.
   */
  const runHandoff = useCallback(
    async (local: LocalDiagnosticProductions) => {
      setPendingLocal(local);
      setHandoff({kind: "running", label: "Création de votre diagnostic…"});
      try {
        let session = await diagnosticApi.start();
        setDiagnostic(session);

        if (
          session.diagnosticCode != null &&
          session.diagnosticVersion != null &&
          (session.diagnosticCode !== local.diagnosticCode ||
            session.diagnosticVersion !== local.diagnosticVersion)
        ) {
          setHandoff({kind: "version-mismatch"});
          return;
        }

        if (session.status === "COMPLETED" || session.nextStep === "RESULT") {
          setHandoff({kind: "already-completed"});
          return;
        }

        const sessionId = session.sessionId;
        if (!sessionId) {
          setHandoff({
            kind: "error",
            message: "Le serveur n'a pas ouvert de session de diagnostic.",
          });
          return;
        }

        let reusedExisting = false;

        if (session.written) {
          if (session.written.submissionId == null && local.writtenText) {
            setHandoff({kind: "running", label: "Envoi de votre réponse écrite…"});
            await productionApi.submitText({
              productionTaskId: session.written.productionTaskId,
              attemptId: session.written.attemptId,
              texte: local.writtenText,
            });
            session = await refreshAfterSubmission(sessionId, "WRITTEN");
          } else if (session.written.submissionId != null) {
            reusedExisting = true;
          }
        }

        if (session.oral) {
          if (session.oral.submissionId == null && local.oralAudio) {
            setHandoff({kind: "running", label: "Envoi de votre enregistrement…"});
            await productionApi.submitAudio(
              session.oral.productionTaskId,
              session.oral.attemptId,
              local.oralAudio,
            );
            session = await refreshAfterSubmission(sessionId, "ORAL");
          } else if (session.oral.submissionId != null) {
            reusedExisting = true;
          }
        }

        const bothReceived =
          session.written?.submissionId != null && session.oral?.submissionId != null;
        if (!bothReceived) {
          setHandoff({
            kind: "error",
            message: "Le serveur n'a pas confirmé la réception de vos deux réponses.",
          });
          return;
        }

        // Accusé de réception des DEUX productions : c'est seulement ici qu'on
        // a le droit d'effacer ce qui est gardé sur l'appareil.
        await clearLocalDiagnostic(local.diagnosticCode, local.diagnosticVersion);
        if (local.writtenTaskId) clearEeDraft(local.writtenTaskId);
        setPendingLocal(null);
        setHandoff(reusedExisting ? {kind: "partially-reused"} : {kind: "idle"});
      } catch (cause) {
        setHandoff({
          kind: "error",
          message: errorMessage(
            cause,
            "Vos réponses n'ont pas pu être envoyées. Elles sont toujours sur cet appareil.",
          ),
        });
      } finally {
        setLoading(false);
      }
    },
    [refreshAfterSubmission],
  );

  // Le démarrage ne joue qu'UNE fois par montage : `user` change d'identité à
  // chaque `refreshUser()`, et rejouer la reprise enverrait une deuxième fois
  // des productions déjà parties.
  const bootstrappedRef = useRef(false);

  useEffect(() => {
    if (!user || bootstrappedRef.current) return;
    bootstrappedRef.current = true;
    let cancelled = false;
    (async () => {
      const local = await readLatestLocalDiagnostic().catch(() => null);
      if (cancelled) return;
      if (isLocalDiagnosticComplete(local)) {
        await runHandoff(local);
        return;
      }
      try {
        const current = await diagnosticApi.current();
        if (cancelled) return;
        setDiagnostic(current);
        setError(null);
      } catch (cause) {
        if (!cancelled) {
          setError(errorMessage(cause, "Impossible de charger votre diagnostic."));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [user, runHandoff]);

  useEffect(() => {
    if (!user) return;
    trackAudienceEvent("/diagnostic", "DIAGNOSTIC_VIEWED", {once: true});
  }, [user]);

  useEffect(() => {
    if (!diagnostic) return;
    if (diagnostic.status === "COMPLETED") {
      if (previousJourneyStatus.current && previousJourneyStatus.current !== "COMPLETED") {
        trackAudienceEvent("/diagnostic", "DIAGNOSTIC_COMPLETED", {once: true});
      }
      trackAudienceEvent("/diagnostic", "DIAGNOSTIC_RESULT_VIEWED", {once: true});
    }
    previousJourneyStatus.current = diagnostic.status;
  }, [diagnostic]);

  // L'analyse des productions est asynchrone. La session, et non le front,
  // décide de l'étape suivante ; ce polling ne fait que relire cette décision.
  useEffect(() => {
    if (!diagnostic?.sessionId) return;
    const activeExercise =
      diagnostic.nextStep === "WRITTEN"
        ? diagnostic.written
        : diagnostic.nextStep === "ORAL"
          ? diagnostic.oral
          : null;
    const activeSubmissionPending =
      activeExercise?.submissionId != null &&
      activeExercise.submissionStatus !== "EVALUATED" &&
      activeExercise.submissionStatus !== "FAILED";
    const shouldPoll =
      diagnostic.status === "ANALYZING" ||
      diagnostic.nextStep === "ANALYSIS" ||
      activeSubmissionPending;
    if (!shouldPoll) return;

    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | null = null;
    const poll = async () => {
      try {
        const fresh = await diagnosticApi.get(diagnostic.sessionId!);
        if (cancelled) return;
        setDiagnostic(fresh);
        setError(null);
        if (
          fresh.status === "ANALYZING" ||
          fresh.nextStep === "ANALYSIS" ||
          ((fresh.nextStep === "WRITTEN" ? fresh.written : fresh.oral)?.submissionId != null &&
            (fresh.nextStep === "WRITTEN" ? fresh.written : fresh.oral)?.submissionStatus !==
              "EVALUATED" &&
            (fresh.nextStep === "WRITTEN" ? fresh.written : fresh.oral)?.submissionStatus !==
              "FAILED")
        ) {
          timer = setTimeout(poll, POLL_MS);
        }
      } catch (cause) {
        if (!cancelled) {
          setError(errorMessage(cause, "L'analyse prend plus de temps que prévu."));
          timer = setTimeout(poll, POLL_MS * 2);
        }
      }
    };
    timer = setTimeout(poll, POLL_MS);
    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
  }, [diagnostic]);

  async function start() {
    if (submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      setDiagnostic(await diagnosticApi.start());
      trackAudienceEvent("/diagnostic", "DIAGNOSTIC_STARTED", {once: true});
    } catch (cause) {
      setError(errorMessage(cause, "Impossible de démarrer le diagnostic."));
    } finally {
      setSubmitting(false);
    }
  }

  async function submitWritten(exercise: NonNullable<DiagnosticResponse["written"]>, text: string) {
    if (!diagnostic?.sessionId || submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      await productionApi.submitText({
        productionTaskId: exercise.productionTaskId,
        attemptId: exercise.attemptId,
        texte: text,
      });
      trackAudienceEvent("/diagnostic", "DIAGNOSTIC_WRITTEN_COMPLETED", {once: true});
      clearEeDraft(exercise.productionTaskId);
      await refreshAfterSubmission(diagnostic.sessionId, "WRITTEN");
    } catch (cause) {
      setError(errorMessage(cause, "Impossible d'envoyer votre réponse écrite."));
    } finally {
      setSubmitting(false);
    }
  }

  async function submitOral(exercise: NonNullable<DiagnosticResponse["oral"]>, audio: Blob) {
    if (!diagnostic?.sessionId || submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      await productionApi.submitAudio(exercise.productionTaskId, exercise.attemptId, audio);
      trackAudienceEvent("/diagnostic", "DIAGNOSTIC_ORAL_COMPLETED", {once: true});
      await refreshAfterSubmission(diagnostic.sessionId, "ORAL");
    } catch (cause) {
      setError(errorMessage(cause, "Impossible d'envoyer votre enregistrement."));
    } finally {
      setSubmitting(false);
    }
  }

  async function retryAnalysis() {
    if (!diagnostic?.sessionId || submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      setDiagnostic(await diagnosticApi.retryAnalysis(diagnostic.sessionId));
    } catch (cause) {
      setError(errorMessage(cause, "Impossible de relancer l'analyse."));
    } finally {
      setSubmitting(false);
    }
  }

  async function discardPendingLocal() {
    if (!pendingLocal) return;
    await clearLocalDiagnostic(pendingLocal.diagnosticCode, pendingLocal.diagnosticVersion);
    if (pendingLocal.writtenTaskId) clearEeDraft(pendingLocal.writtenTaskId);
    setPendingLocal(null);
    setHandoff({kind: "idle"});
  }

  if (!user || loading) return <DiagnosticSkeleton />;

  if (handoff.kind === "running") {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<Sparkles size={26} />}
          title="Nous enregistrons vos deux réponses"
          text={`${handoff.label} Elles restent sur cet appareil tant que le serveur ne les a pas confirmées.`}
          busy
        />
      </DiagnosticShell>
    );
  }

  if (handoff.kind === "error") {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<RotateCcw size={26} />}
          title="Vos réponses n'ont pas été envoyées"
          text={`${handoff.message} Rien n'est perdu : elles sont toujours conservées sur cet appareil.`}
          role="alert"
        >
          <button
            className={styles.primaryButton}
            type="button"
            onClick={() => {
              if (pendingLocal) void runHandoff(pendingLocal);
            }}
          >
            Réessayer l&apos;envoi
          </button>
        </StateCard>
      </DiagnosticShell>
    );
  }

  if (handoff.kind === "version-mismatch") {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<Info size={26} />}
          title="Vos réponses portent sur d'autres sujets"
          text="Les sujets du diagnostic ont changé depuis que vous les avez rédigés. Nous ne pouvons pas les faire analyser tels quels — vous pouvez repartir des sujets actuels."
          role="alert"
        >
          <button
            className={styles.primaryButton}
            type="button"
            onClick={() => void discardPendingLocal().then(() => loadCurrent())}
          >
            Recommencer avec les sujets actuels
          </button>
        </StateCard>
      </DiagnosticShell>
    );
  }

  if (!diagnostic) {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<RotateCcw size={26} />}
          title="Le diagnostic n'a pas pu être chargé"
          text={error ?? "Réessayez dans un instant."}
          role="alert"
        >
          <button className={styles.primaryButton} type="button" onClick={() => void loadCurrent()}>
            Réessayer
          </button>
        </StateCard>
      </DiagnosticShell>
    );
  }

  const notice =
    handoff.kind === "already-completed" ? (
      <HandoffNotice
        title="Ce compte a déjà passé le diagnostic"
        text="Nous n'avons donc rien envoyé : chaque exercice n'accepte qu'une réponse. Voici le résultat déjà obtenu. Les réponses que vous venez de rédiger restent sur cet appareil tant que vous ne les supprimez pas."
        onDiscard={() => void discardPendingLocal()}
      />
    ) : handoff.kind === "partially-reused" ? (
      <HandoffNotice
        title="Une de vos réponses avait déjà été enregistrée"
        text="Ce compte avait déjà envoyé un des deux exercices : nous n'avons ajouté que celui qui manquait. L'analyse porte sur les réponses enregistrées côté serveur."
      />
    ) : null;

  if (diagnostic.status === "NOT_STARTED" || diagnostic.nextStep === "PRESENTATION") {
    return (
      <DiagnosticShell>
        <DiagnosticIntro error={error} submitting={submitting} onStart={() => void start()} />
      </DiagnosticShell>
    );
  }

  if (diagnostic.status === "FAILED") {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<RotateCcw size={26} />}
          title="L'analyse n'a pas pu aboutir"
          text={diagnostic.errorMessage ?? "Vos deux réponses sont conservées. Vous n'avez rien à refaire."}
          role="alert"
        >
          {diagnostic.canRetry && (
            <button className={styles.primaryButton} type="button" disabled={submitting} onClick={() => void retryAnalysis()}>
              {submitting ? "Relance…" : "Relancer l'analyse"}
            </button>
          )}
          <Link className={styles.secondaryButton} href="/plan">Retour au plan</Link>
        </StateCard>
      </DiagnosticShell>
    );
  }

  if (diagnostic.status === "COMPLETED" || diagnostic.nextStep === "RESULT") {
    return (
      <DiagnosticResult
        diagnostic={diagnostic}
        targetLevel={user.targetLevel ?? null}
        planHref={withTrafficSource("/plan", trafficSource)}
        notice={notice}
      />
    );
  }

  const currentExercise =
    diagnostic.nextStep === "WRITTEN"
      ? diagnostic.written
      : diagnostic.nextStep === "ORAL"
        ? diagnostic.oral
        : null;
  if (
    diagnostic.status === "ANALYZING" ||
    diagnostic.nextStep === "ANALYSIS" ||
    currentExercise?.submissionId != null
  ) {
    return (
      <DiagnosticShell>
        {notice}
        <StateCard
          icon={<Sparkles size={26} />}
          title={
            diagnostic.nextStep === "WRITTEN"
              ? "Votre écrit est bien reçu"
              : diagnostic.nextStep === "ORAL"
                ? "Votre oral est bien reçu"
                : "Nous analysons vos deux réponses"
          }
          text="Vos réponses sont conservées. Vous pouvez quitter cet écran et reprendre plus tard, sans rien refaire."
          busy
        >
          {error && <p className={styles.error} role="status">{error}</p>}
          <Link className={styles.secondaryButton} href="/dashboard">Revenir au tableau de bord</Link>
        </StateCard>
      </DiagnosticShell>
    );
  }

  if (diagnostic.nextStep === "WRITTEN" && diagnostic.written) {
    const exercise = diagnostic.written;
    return (
      <DiagnosticShell compact>
        <ExerciseHeader kind="written" />
        <EeWritingForm
          task={diagnosticExerciseAsProductionTask(exercise)}
          submitting={submitting}
          error={error}
          submitLabel="Continuer vers l'oral"
          promptSlot={<ExercisePrompt exercise={exercise} kind="written" />}
          criteriaSlot={null}
          onSubmit={(text) => void submitWritten(exercise, text)}
        />
      </DiagnosticShell>
    );
  }

  if (diagnostic.nextStep === "ORAL" && diagnostic.oral) {
    const exercise = diagnostic.oral;
    return (
      <DiagnosticShell compact>
        <ExerciseHeader kind="oral" />
        <EoRecordingForm
          task={diagnosticExerciseAsProductionTask(exercise)}
          submitting={submitting}
          error={error}
          submitLabel="Analyser mes deux réponses"
          promptSlot={<ExercisePrompt exercise={exercise} kind="oral" />}
          criteriaSlot={null}
          maxDurationSec={exercise.durationMaxSeconds}
          onSubmit={(audio) => void submitOral(exercise, audio)}
        />
      </DiagnosticShell>
    );
  }

  return (
    <DiagnosticShell>
      <StateCard
        icon={<Sparkles size={26} />}
        title="Nous analysons vos deux réponses"
        text="Votre écrit et votre oral sont comparés aux compétences réellement observables. Cela prend généralement moins de deux minutes."
        busy
      >
        {error && <p className={styles.error} role="status">{error}</p>}
        <Link className={styles.secondaryButton} href="/dashboard">Revenir au tableau de bord</Link>
      </StateCard>
    </DiagnosticShell>
  );
}

// ============================================================================
// Chrome partagé par les deux régimes
// ============================================================================

function DiagnosticShell({
  children,
  compact = false,
  guest = false,
}: {
  children: ReactNode;
  compact?: boolean;
  guest?: boolean;
}) {
  return (
    <main className={`${styles.page} ${compact ? styles.pageCompact : ""}`}>
      <nav className={styles.backNav} aria-label="Sortir du diagnostic">
        <Link href={guest ? "/" : "/dashboard"}>
          <ArrowLeft size={16} aria-hidden /> {guest ? "Accueil" : "Tableau de bord"}
        </Link>
        <span>
          {guest
            ? "Vos réponses restent sur cet appareil"
            : "Votre progression est enregistrée"}
        </span>
      </nav>
      {children}
    </main>
  );
}

/** Écran de présentation, identique pour un visiteur et pour un compte : c'est
 *  le même parcours, seul le moment où l'on demande le compte change. */
function DiagnosticIntro({
  error,
  submitting,
  guest = false,
  onStart,
}: {
  error: string | null;
  submitting: boolean;
  guest?: boolean;
  onStart: () => void;
}) {
  return (
    <section className={styles.intro}>
      <span className={styles.heroIcon} aria-hidden>
        <Target size={30} />
      </span>
      <p className={styles.eyebrow}>Diagnostic TCF SejourFR</p>
      <h1>Découvrez vos priorités TCF</h1>
      <p className={styles.lead}>
        Un écrit et un oral suffisent pour construire une première feuille de route
        personnalisée.
      </p>
      <div className={styles.duration}>
        <Clock3 size={18} aria-hidden />
        2 exercices · environ 8 à 10 min
      </div>
      <ul className={styles.introList}>
        <li><FilePenLine size={19} aria-hidden /><span><b>1 écrit</b> pour observer votre façon de structurer et développer.</span></li>
        <li><Mic size={19} aria-hidden /><span><b>1 oral enregistré</b>, sans conversation en temps réel.</span></li>
        <li><Sparkles size={19} aria-hidden /><span><b>Une analyse personnalisée</b> avec trois priorités maximum.</span></li>
      </ul>
      {error && <p className={styles.error} role="alert">{error}</p>}
      <button className={styles.primaryButton} type="button" disabled={submitting} onClick={onStart}>
        {submitting ? "Préparation…" : "Commencer mon diagnostic gratuit"}
        {!submitting && <ArrowRight size={17} aria-hidden />}
      </button>
      <p className={styles.disclaimer}>
        {guest
          ? "Commencez sans compte. Il ne vous sera demandé qu'au moment de l'analyse. Estimation d'entraînement, non officielle."
          : "Estimation d'entraînement, non officielle."}
      </p>
    </section>
  );
}

function ExerciseHeader({kind, note}: {kind: "written" | "oral"; note?: string}) {
  return (
    <header className={styles.exerciseHeader}>
      <p className={styles.eyebrow}>Diagnostic TCF SejourFR</p>
      <h1>{kind === "written" ? "Votre exercice écrit" : "Votre exercice oral"}</h1>
      <p className={styles.exerciseSub}>
        {kind === "written" ? "Premier exercice sur deux" : "Deuxième et dernier exercice"} ·
        aucune note sur 20.
      </p>
      {note && <p className={styles.exerciseNote}>{note}</p>}
    </header>
  );
}

function ExercisePrompt({
  exercise,
  kind,
}: {
  exercise: DiagnosticExerciseContent;
  kind: "written" | "oral";
}) {
  return (
    <section className={styles.prompt} aria-labelledby={`${kind}-prompt-title`}>
      <span className={styles.promptTag}>{kind === "written" ? "Expression écrite" : "Expression orale"}</span>
      <h2 id={`${kind}-prompt-title`}>{exercise.title}</h2>
      <p className={styles.instruction}>{exercise.instruction}</p>
      {exercise.helperText && <p className={styles.helper}>{exercise.helperText}</p>}
      <div className={styles.constraints}>
        {kind === "written" && exercise.wordsMin != null && exercise.wordsMax != null && (
          <span><FilePenLine size={14} aria-hidden /> {exercise.wordsMin}–{exercise.wordsMax} mots</span>
        )}
        {kind === "oral" && exercise.durationMaxSeconds != null && (
          <span><Clock3 size={14} aria-hidden /> Jusqu&apos;à {Math.ceil(exercise.durationMaxSeconds / 60)} min</span>
        )}
      </div>
      {kind === "oral" && exercise.instructionAudioUrl && (
        <div className={styles.audioInstruction}>
          <span><Headphones size={18} aria-hidden /> Écouter la consigne</span>
          <audio controls preload="metadata" src={exercise.instructionAudioUrl}>
            Votre navigateur ne peut pas lire cette consigne audio.
          </audio>
        </div>
      )}
    </section>
  );
}

/** Message honnête quand la reprise n'a pas pu se passer comme prévu. Il ne
 *  masque jamais le résultat servi par le serveur : il l'explique. */
function HandoffNotice({
  title,
  text,
  onDiscard,
}: {
  title: string;
  text: string;
  onDiscard?: () => void;
}) {
  return (
    <section className={styles.handoffNotice} role="status">
      <span aria-hidden><Info size={18} /></span>
      <div>
        <b>{title}</b>
        <p>{text}</p>
        {onDiscard && (
          <button type="button" onClick={onDiscard}>
            Supprimer les réponses gardées sur cet appareil
          </button>
        )}
      </div>
    </section>
  );
}

function StateCard({
  icon,
  title,
  text,
  children,
  busy = false,
  role,
}: {
  icon: ReactNode;
  title: string;
  text: string;
  children?: React.ReactNode;
  busy?: boolean;
  role?: "alert";
}) {
  return (
    <section className={styles.stateCard} role={role} aria-busy={busy || undefined}>
      <span className={`${styles.stateIcon} ${busy ? styles.stateIconBusy : ""}`} aria-hidden>{icon}</span>
      <h1>{title}</h1>
      <p>{text}</p>
      <div className={styles.actions}>{children}</div>
      {busy && <span className={styles.loadingBar} aria-hidden />}
    </section>
  );
}

function DiagnosticResult({
  diagnostic,
  targetLevel,
  planHref,
  notice,
}: {
  diagnostic: DiagnosticResponse;
  targetLevel: string | null;
  planHref: string;
  notice?: ReactNode;
}) {
  const result = diagnostic.result;
  const observations = useMemo(() => {
    const unique = new Map<string, DiagnosticSkillObservationDto>();
    for (const skill of [...(result?.written?.skills ?? []), ...(result?.oral?.skills ?? [])]) {
      if (skill.observed) unique.set(skill.skillId, skill);
    }
    return [...unique.values()];
  }, [result]);

  if (!result) {
    return (
      <DiagnosticShell>
        {notice}
        <StateCard icon={<Sparkles size={26} />} title="Votre résultat se prépare" text="L'analyse est terminée, mais sa synthèse n'est pas encore disponible." busy />
      </DiagnosticShell>
    );
  }

  const mainPriority = result.priorities[0] ?? null;
  const otherPriorities = result.priorities.slice(1, 3);

  return (
    <DiagnosticShell>
      <div className={styles.result}>
        {notice}
        <header className={styles.resultHeader}>
          <span className={styles.doneBadge}>
            <i aria-hidden><Check size={11} strokeWidth={3.4} /></i> Diagnostic terminé
          </span>
          <h1>On sait maintenant quoi travailler.</h1>
          <p className={styles.resultLead}>
            Vos productions écrite et orale ont permis d&apos;identifier les compétences qui
            vous feront progresser le plus vite.
          </p>
        </header>

        {/* Bandeau : les deux niveaux estimés, seuls chiffres mis en avant. */}
        <section className={styles.levelHero} aria-label="Niveaux estimés">
          <p className={styles.levelHeroLabel}>Niveaux estimés aujourd&apos;hui</p>
          <div className={styles.levelHeroGrid}>
            <div>
              <span><FilePenLine size={13} aria-hidden /> Expression écrite</span>
              <b>{niveauEstimateLabel(result.written?.levelEstimate)}</b>
            </div>
            <div>
              <span><Mic size={13} aria-hidden /> Expression orale</span>
              <b>{niveauEstimateLabel(result.oral?.levelEstimate)}</b>
            </div>
          </div>
          <p className={styles.levelHeroFoot}>
            <span>Objectif&nbsp;: <b>{targetLevel ?? "à définir"}</b></span>
            <span>Estimation d&apos;entraînement, non officielle.</span>
          </p>
        </section>

        <p className={styles.note}>
          <Info size={15} aria-hidden />
          Cette estimation est pédagogique : elle ne remplace pas un résultat officiel du TCF.
        </p>

        {/* ------------------------------------ ce que le diagnostic révèle */}
        <section aria-labelledby="reveal-title">
          <ResultBlockHead
            id="reveal-title"
            title="Ce que votre diagnostic révèle"
            text="Pas une liste de vingt erreurs : seulement ce qui est le plus utile pour avancer."
          />
          <div className={styles.snapshot}>
            {result.strengths.length > 0 && (
              <div className={styles.snapshotStrengths}>
                <b>Ce qui fonctionne déjà</b>
                <ul>
                  {result.strengths.slice(0, 3).map((item) => <li key={item}>{item}</li>)}
                </ul>
              </div>
            )}
            {observations.length === 0 ? (
              <p className={styles.emptyText}>
                Aucune compétence n&apos;a été observée avec assez de confiance sur ces deux productions.
              </p>
            ) : (
              observations.map((skill) => <SkillDisclosure key={skill.skillId} skill={skill} />)
            )}
          </div>
        </section>

        {/* ------------------------------------------------- priorité n°1 */}
        {mainPriority && (
          <section aria-labelledby="priority-title">
            <ResultBlockHead
              id="priority-title"
              title="Votre priorité n°1"
              text="C'est ici que votre plan commencera."
            />
            <article className={styles.priorityCard}>
              <div className={styles.priorityTop}>
                <span className={styles.priorityImpact}><Zap size={13} aria-hidden /> Impact élevé</span>
                <span className={styles.priorityRank}>Priorité 1/{result.priorities.length}</span>
              </div>
              <h3>{mainPriority.skillTitle}</h3>
              {(result.mainPriorityExplanation ?? mainPriority.explanation) && (
                <p>{result.mainPriorityExplanation ?? mainPriority.explanation}</p>
              )}
              {mainPriority.evidence && (
                <blockquote className={styles.priorityEvidence}>
                  <span>Extrait de votre production</span>
                  «&nbsp;{evidenceExcerpt(mainPriority.evidence)}&nbsp;»
                </blockquote>
              )}
              {result.nextAction && (
                <Link className={styles.priorityCta} href={recommendedExerciseHref(result.nextAction)}>
                  <span>{result.nextAction.title}</span>
                  <span className={styles.priorityCtaMeta}>
                    {result.nextAction.estimatedMinutes} min ·{" "}
                    {productionSectionLabel(result.nextAction.section)}
                    <ArrowRight size={15} aria-hidden />
                  </span>
                </Link>
              )}
            </article>
            {otherPriorities.length > 0 && (
              <ol className={styles.nextPriorities}>
                {otherPriorities.map((priority, index) => (
                  <li key={priority.skillId}>
                    <span aria-hidden>{index + 2}</span>
                    <div>
                      <b>{priority.skillTitle}</b>
                      {priority.explanation && <small>{priority.explanation}</small>}
                    </div>
                  </li>
                ))}
              </ol>
            )}
          </section>
        )}

        {/* ---------------------------------------------- vos 2 productions */}
        <section aria-labelledby="productions-title">
          <ResultBlockHead
            id="productions-title"
            title="Vos deux productions"
            text="Ce que chacune a montré, avant le détail complet."
          />
          <div className={styles.productions}>
            <ProductionSummary kind="written" production={result.written} />
            <ProductionSummary kind="oral" production={result.oral} />
          </div>
        </section>

        {/* ------------------------------------------------------ CTA final */}
        <section className={styles.ctaBox}>
          <span className={styles.ctaSpark} aria-hidden><Sparkles size={20} /></span>
          <h2>Votre plan est prêt</h2>
          <p>
            Il commence par vos priorités les plus importantes, puis se réordonne avec chacune
            de vos nouvelles productions.
          </p>
          <Link href={planHref} className={styles.primaryButton}>
            Découvrir mon plan <ArrowRight size={17} aria-hidden />
          </Link>

          <details className={styles.details}>
            <summary>Voir le diagnostic complet</summary>
            <div className={styles.observations}>
              {observations.length === 0 ? (
                <p>Aucune autre compétence n&apos;a été observée avec assez de confiance.</p>
              ) : observations.map((skill) => (
                <article key={skill.skillId}>
                  <div>
                    <b>{skill.skillTitle}</b>
                    <span data-status={skill.status}>{LEARNING_PLAN_SKILL_STATUS_LABEL[skill.status]}</span>
                  </div>
                  {skill.evidence && <p><strong>Exemple observé :</strong> {evidenceExcerpt(skill.evidence)}</p>}
                  {skill.explanation && <p>{skill.explanation}</p>}
                </article>
              ))}
            </div>
          </details>
        </section>
      </div>
    </DiagnosticShell>
  );
}

/** Intertitre + phrase d'un bloc du résultat. */
function ResultBlockHead({id, title, text}: {id: string; title: string; text: string}) {
  return (
    <div className={styles.blockHead}>
      <h2 id={id}>{title}</h2>
      <p>{text}</p>
    </div>
  );
}

/**
 * Une compétence observée, **repliée par défaut**.
 *
 * Déplié, le diagnostic alignait une douzaine d'explications de trois à quatre
 * lignes : le candidat y voyait un mur de texte et n'en lisait aucune. Replié,
 * il lit d'abord le verdict (titre + statut) et n'ouvre que ce qui l'intéresse.
 * Rien n'est retiré — tout est à un clic.
 *
 * `<details>` plutôt qu'un état React : le repli natif est accessible au clavier
 * et survit à un rendu sans qu'on ait à le gérer. Miroir de
 * `_SkillSnapshotRow` côté mobile.
 */
function SkillDisclosure({skill}: {skill: DiagnosticSkillObservationDto}) {
  const tone = LEARNING_PLAN_SKILL_STATUS_TONE[skill.status];
  const head = (
    <>
      <span className={styles.snapshotIcon} aria-hidden><ToneIcon tone={tone} /></span>
      <b>{skill.skillTitle}</b>
      <span className={styles.snapshotStatus}>
        {LEARNING_PLAN_SKILL_STATUS_LABEL[skill.status]}
      </span>
    </>
  );

  // Sans détail, l'encart n'a rien à ouvrir : il reste une simple ligne.
  if (!skill.explanation && !skill.evidence) {
    return (
      <article className={styles.snapshotRow} data-tone={tone}>
        <div className={styles.snapshotHead}>{head}</div>
      </article>
    );
  }

  return (
    <details className={styles.snapshotRow} data-tone={tone}>
      <summary className={styles.snapshotHead}>
        {head}
        <ChevronDown className={styles.snapshotChevron} size={16} aria-hidden />
      </summary>
      <div className={styles.snapshotDetail}>
        {skill.explanation && <p>{skill.explanation}</p>}
        {skill.evidence && (
          <p className={styles.snapshotEvidence}>«&nbsp;{evidenceExcerpt(skill.evidence)}&nbsp;»</p>
        )}
      </div>
    </details>
  );
}

/** Pictogramme du signal : acquis / à consolider / prioritaire. */
function ToneIcon({tone}: {tone: DiagnosticSignalTone}) {
  if (tone === "good") return <Check size={16} strokeWidth={3} />;
  if (tone === "mid") return <TrendingUp size={16} strokeWidth={2.6} />;
  if (tone === "weak") return <AlertCircle size={16} strokeWidth={2.6} />;
  return <Info size={16} strokeWidth={2.6} />;
}

/**
 * Carte d'une production du diagnostic.
 *
 * Elle expose `summary`, `taskCompletion`, `communicationStatus` et
 * `weaknesses` — quatre champs servis depuis le premier jour et qu'aucun écran
 * n'affichait, alors que c'est exactement ce qui rend le résultat
 * compréhensible : ce que le candidat a réussi à faire passer, et ce qui
 * manquait.
 */
function ProductionSummary({
  kind,
  production,
}: {
  kind: "written" | "oral";
  production: DiagnosticProductionResultDto | null;
}) {
  const label = kind === "written" ? "Expression écrite" : "Expression orale";
  const icon = kind === "written" ? <FilePenLine size={17} /> : <Mic size={17} />;

  if (!production) {
    return (
      <article className={styles.production}>
        <div className={styles.productionHead}>
          <span className={styles.productionIcon} aria-hidden>{icon}</span>
          <div><b>{label}</b></div>
        </div>
        <p className={styles.emptyText}>Cette production n&apos;a pas encore été analysée.</p>
      </article>
    );
  }

  // Replié par défaut, même raison que les compétences observées : un résumé de
  // cinq lignes, deux signaux et jusqu'à trois points à travailler, fois deux
  // productions, se lisaient comme un mur. On montre l'épreuve et son niveau
  // estimé ; le reste est à un clic. Miroir de `_ProductionCard` côté mobile.
  return (
    <details className={styles.production}>
      <summary className={styles.productionHead}>
        <span className={styles.productionIcon} aria-hidden>{icon}</span>
        <div>
          <b>{label}</b>
          <span>Estimation : {niveauEstimateLabel(production.levelEstimate)}</span>
        </div>
        <ChevronDown className={styles.productionChevron} size={16} aria-hidden />
      </summary>

      <div className={styles.productionDetail}>
        {production.summary && <p className={styles.productionSummary}>{production.summary}</p>}

        <ul className={styles.productionSignals}>
          <li data-tone={DIAGNOSTIC_TASK_COMPLETION_TONE[production.taskCompletion]}>
            {DIAGNOSTIC_TASK_COMPLETION_LABEL[production.taskCompletion]}
          </li>
          <li data-tone={DIAGNOSTIC_COMMUNICATION_TONE[production.communicationStatus]}>
            {DIAGNOSTIC_COMMUNICATION_LABEL[production.communicationStatus]}
          </li>
        </ul>

        {production.weaknesses.length > 0 && (
          <div className={styles.productionWeak}>
            <b>À travailler</b>
            <ul>
              {production.weaknesses.slice(0, 3).map((item) => <li key={item}>{item}</li>)}
            </ul>
          </div>
        )}
      </div>
    </details>
  );
}

function DiagnosticSkeleton() {
  return (
    <main className={styles.page} aria-busy="true" aria-label="Chargement du diagnostic">
      <div className={styles.skeletonHeader} />
      <div className={styles.skeletonCard} />
    </main>
  );
}
