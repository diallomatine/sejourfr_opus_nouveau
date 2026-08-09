"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useRef, useState, type ReactNode} from "react";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ClipboardCheck,
  Clock3,
  FilePenLine,
  Headphones,
  Mic,
  RotateCcw,
  Sparkles,
  Target,
} from "lucide-react";
import {EeWritingForm, clearEeDraft} from "@/app/_components/production/EeWritingForm";
import {EoRecordingForm} from "@/app/_components/production/EoRecordingForm";
import {ApiException, diagnosticApi, productionApi} from "@/lib/api";
import {
  trackAudienceEvent,
  withTrafficSource,
} from "@/lib/audience";
import {useAuth} from "@/lib/auth-context";
import {
  diagnosticExerciseAsProductionTask,
  LEARNING_PLAN_SKILL_STATUS_LABEL,
  niveauEstimateLabel,
  recommendedExerciseHref,
} from "@/lib/diagnostic";
import type {
  DiagnosticExerciseDto,
  DiagnosticResponse,
  DiagnosticSkillObservationDto,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import styles from "./diagnostic.module.css";

const POLL_MS = 2_500;

function errorMessage(error: unknown, fallback: string): string {
  return error instanceof ApiException ? error.message : fallback;
}

export function DiagnosticView() {
  const {status: authStatus, user} = useAuth();
  const [diagnostic, setDiagnostic] = useState<DiagnosticResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
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

  useEffect(() => {
    if (authStatus === "loading") return;
    if (!user) return;
    let cancelled = false;
    diagnosticApi.current().then(
      (current) => {
        if (cancelled) return;
        setDiagnostic(current);
        setError(null);
      },
      (cause: unknown) => {
        if (!cancelled) setError(errorMessage(cause, "Impossible de charger votre diagnostic."));
      },
    ).finally(() => {
      if (!cancelled) setLoading(false);
    });
    return () => { cancelled = true; };
  }, [authStatus, user]);

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

  async function refreshAfterSubmission(
    sessionId: string,
    submittedStep: "WRITTEN" | "ORAL",
  ) {
    // La création de la submission et le calcul de l'étape de reprise peuvent
    // tomber dans deux transactions successives : quelques relectures courtes
    // évitent de redemander une production déjà reçue.
    for (let attempt = 0; attempt < 6; attempt += 1) {
      const fresh = await diagnosticApi.get(sessionId);
      setDiagnostic(fresh);
      const submittedExercise =
        submittedStep === "WRITTEN" ? fresh.written : fresh.oral;
      if (
        fresh.status !== "IN_PROGRESS" ||
        fresh.nextStep !== submittedStep ||
        submittedExercise?.submissionId != null
      ) {
        return;
      }
      await new Promise((resolve) => setTimeout(resolve, 700));
    }
  }

  async function submitWritten(exercise: DiagnosticExerciseDto, text: string) {
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

  async function submitOral(exercise: DiagnosticExerciseDto, audio: Blob) {
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

  if (authStatus === "loading" || (Boolean(user) && loading)) return <DiagnosticSkeleton />;
  if (!user) {
    const diagnosticHref = withTrafficSource("/diagnostic", trafficSource);
    return (
      <DiagnosticShell>
        <StateCard
          icon={<ClipboardCheck size={26} />}
          title="Connectez-vous pour reprendre sur tous vos appareils"
          text="Votre écrit, votre oral et votre résultat restent attachés à votre compte."
        >
          <Link className={styles.primaryButton} href={`/connexion?next=${encodeURIComponent(diagnosticHref)}`}>
            Se connecter <ArrowRight size={17} aria-hidden />
          </Link>
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

  if (diagnostic.status === "NOT_STARTED" || diagnostic.nextStep === "PRESENTATION") {
    return (
      <DiagnosticShell>
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
          <button className={styles.primaryButton} type="button" disabled={submitting} onClick={() => void start()}>
            {submitting ? "Préparation…" : "Commencer mon diagnostic gratuit"}
            {!submitting && <ArrowRight size={17} aria-hidden />}
          </button>
          <p className={styles.disclaimer}>Estimation d&apos;entraînement, non officielle.</p>
        </section>
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

function DiagnosticShell({children, compact = false}: {children: ReactNode; compact?: boolean}) {
  return (
    <main className={`${styles.page} ${compact ? styles.pageCompact : ""}`}>
      <nav className={styles.backNav} aria-label="Sortir du diagnostic">
        <Link href="/dashboard"><ArrowLeft size={16} aria-hidden /> Tableau de bord</Link>
        <span>Votre progression est enregistrée</span>
      </nav>
      {children}
    </main>
  );
}

function ExerciseHeader({kind}: {kind: "written" | "oral"}) {
  return (
    <header className={styles.exerciseHeader}>
      <p className={styles.eyebrow}>Diagnostic TCF SejourFR</p>
      <h1>{kind === "written" ? "Votre exercice écrit" : "Votre exercice oral"}</h1>
      <p>{kind === "written" ? "Premier exercice sur deux" : "Deuxième et dernier exercice"} · aucune note sur 20.</p>
    </header>
  );
}

function ExercisePrompt({exercise, kind}: {exercise: DiagnosticExerciseDto; kind: "written" | "oral"}) {
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
}: {
  diagnostic: DiagnosticResponse;
  targetLevel: string | null;
  planHref: string;
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
        <StateCard icon={<Sparkles size={26} />} title="Votre résultat se prépare" text="L'analyse est terminée, mais sa synthèse n'est pas encore disponible." busy />
      </DiagnosticShell>
    );
  }

  return (
    <DiagnosticShell>
      <section className={styles.result}>
        <header className={styles.resultHeader}>
          <span className={styles.successIcon} aria-hidden><Check size={24} /></span>
          <p className={styles.eyebrow}>Votre diagnostic TCF</p>
          <h1>Voici votre point de départ</h1>
          <p>Une estimation prudente de vos productions, puis une action concrète.</p>
        </header>

        <div className={styles.levelGrid} aria-label="Niveaux de production estimés">
          <article><span>Expression écrite</span><b>{niveauEstimateLabel(result.written?.levelEstimate)}</b></article>
          <article><span>Expression orale</span><b>{niveauEstimateLabel(result.oral?.levelEstimate)}</b></article>
          <article><span>Votre objectif</span><b>{targetLevel ?? "À définir"}</b></article>
        </div>
        <p className={styles.disclaimer}>Estimation d&apos;entraînement, non officielle.</p>

        <div className={styles.resultColumns}>
          <ResultList title="Vos points solides" icon={<Check size={18} />} items={result.strengths.slice(0, 3)} empty="Ils apparaîtront avec vos prochaines productions." />
          <section className={styles.resultCard}>
            <h2><Target size={18} aria-hidden /> Vos priorités</h2>
            {result.priorities.length > 0 ? (
              <ol className={styles.priorityList}>
                {result.priorities.slice(0, 3).map((priority) => (
                  <li key={priority.skillId}>
                    <b>{priority.skillTitle}</b>
                    {priority.explanation && <span>{priority.explanation}</span>}
                  </li>
                ))}
              </ol>
            ) : <p className={styles.emptyText}>Aucune priorité fiable n&apos;a pu être isolée.</p>}
          </section>
        </div>

        {result.nextAction && (
          <section className={styles.nextAction}>
            <span className={styles.eyebrow}>À travailler maintenant</span>
            <h2>{result.nextAction.title}</h2>
            {result.mainPriorityExplanation && <p>{result.mainPriorityExplanation}</p>}
            <span>{result.nextAction.estimatedMinutes} min · {result.nextAction.section === "EE" ? "écrit" : "oral"}</span>
          </section>
        )}

        <div className={styles.resultActions}>
          <Link href={planHref} className={styles.primaryButton}>Voir mon plan <ArrowRight size={17} aria-hidden /></Link>
          {result.nextAction && <Link href={recommendedExerciseHref(result.nextAction)} className={styles.secondaryButton}>Commencer l&apos;exercice recommandé</Link>}
        </div>

        <details className={styles.details}>
          <summary>Voir le diagnostic complet</summary>
          <div className={styles.observations}>
            {observations.length === 0 ? <p>Aucune autre compétence n&apos;a été observée avec assez de confiance.</p> : observations.map((skill) => (
              <article key={skill.skillId}>
                <div><b>{skill.skillTitle}</b><span data-status={skill.status}>{LEARNING_PLAN_SKILL_STATUS_LABEL[skill.status]}</span></div>
                {skill.evidence && <p><strong>Exemple observé :</strong> {skill.evidence}</p>}
                {skill.explanation && <p>{skill.explanation}</p>}
              </article>
            ))}
          </div>
        </details>
      </section>
    </DiagnosticShell>
  );
}

function ResultList({title, icon, items, empty}: {title: string; icon: ReactNode; items: string[]; empty: string}) {
  return (
    <section className={styles.resultCard}>
      <h2>{icon}{title}</h2>
      {items.length > 0 ? <ul>{items.map((item) => <li key={item}>{item}</li>)}</ul> : <p className={styles.emptyText}>{empty}</p>}
    </section>
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
