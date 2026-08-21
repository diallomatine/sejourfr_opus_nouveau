"use client";

import Link from "next/link";
import {useCallback, useEffect, useRef, useState, type ReactNode} from "react";
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
  Lock,
  Mic,
  RotateCcw,
  Sparkles,
  TrendingUp,
} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ActionPlanExemple} from "@/app/_components/skill-ui/ActionPlan";
import {SkillAccent} from "@/app/_components/skill-ui/SkillLayout";
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
  DiagnosticExempleCibleDto,
  DiagnosticProductionResultDto,
  DiagnosticResponse,
  DiagnosticResultDto,
  DiagnosticSkillObservationDto,
  LearningPlanSkillStatus,
  PublicDiagnosticResponse,
  SkillSection,
} from "@/lib/types";
import {useTrafficSource, useTrafficSourceHref} from "@/lib/use-traffic-source";
import {DiagnosticAccountGate} from "./DiagnosticAccountGate";
import {DiagnosticIntro, type DiagnosticParcours} from "./DiagnosticIntro";
import {DiagnosticProfileCard} from "./DiagnosticProfile";
import {DiagnosticSteps} from "./DiagnosticSteps";
import styles from "./diagnostic.module.css";

const POLL_MS = 2_500;

/** Au-delà, on cesse d'afficher un squelette : on rend la main avec une erreur. */
const LOADING_WATCHDOG_MS = 20_000;

function errorMessage(error: unknown, fallback: string): string {
  return error instanceof ApiException ? error.message : fallback;
}

/**
 * Textes de l'écran d'échec d'analyse. Miroir mot pour mot du mobile
 * (`widgets/diagnostic_analysis.dart` + `diagnostic_controller.dart`) : ces
 * chaînes ne transitent pas par le réseau, chaque front en tient sa copie.
 */
const ANALYSIS_FAILED_TITLE = "L'analyse n'a pas pu aboutir";
const ANALYSIS_FAILED_TEXT =
  "Vos deux réponses sont conservées. Vous n'avez rien à refaire.";
const ANALYSIS_RETRY_EXHAUSTED =
  "Le nombre de relances automatiques est épuisé. Vos deux productions restent enregistrées : vous n'avez rien à refaire. L'analyse a échoué de notre côté, et votre plan reste accessible en attendant.";
/**
 * La route de relance est rate-limitée serveur (`RateLimitGuard
 * .checkProductionSubmission`). Son message brut — « Trop de tentatives.
 * Reessayez dans 573s. » — est sans accents et compté en secondes : on ne le
 * sert pas tel quel à un candidat.
 */
const ANALYSIS_RETRY_RATE_LIMITED =
  "Trop de relances en peu de temps. Patientez quelques minutes, puis réessayez : vos deux réponses restent conservées.";
const ANALYSIS_RETRY_FAILED =
  "La relance n'a pas pu être lancée. Vérifiez votre connexion, puis réessayez.";

/**
 * L'échec de la relance qu'on VIENT de tenter — à ne jamais confondre avec
 * `diagnostic.errorMessage`, qui dit pourquoi l'analyse elle-même a échoué.
 */
function retryErrorMessage(cause: unknown): string {
  if (cause instanceof ApiException && cause.status === 429) {
    return ANALYSIS_RETRY_RATE_LIMITED;
  }
  return errorMessage(cause, ANALYSIS_RETRY_FAILED);
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
  // 🛑 **La variante choisie à l'entrée ne quitte JAMAIS la mémoire.** Elle
  // vit ici, au-dessus de la bascule invité ⇄ connecté, précisément pour
  // survivre à l'inscription — qui se fait *en place*, sans quitter la page —
  // et au sign-in Google, qui s'ouvre en popup. Rien n'est écrit en base, sur
  // l'appareil ni dans l'URL : le profil réel se lit sur les domaines mesurés
  // (`LearningPlanDto`), jamais sur une intention. Cf. `DiagnosticIntro`.
  const [parcours, setParcours] = useState<DiagnosticParcours>("RAPIDE");
  if (status === "loading") return <DiagnosticSkeleton />;
  // `DualChromeShell` porte les deux chromes de la route : sidebar pour un
  // compte, fond applicatif nu pour un visiteur (qui garde le header et le
  // pied de page publics du layout racine).
  return (
    <DualChromeShell>
      {status === "authenticated" ? (
        <ConnectedDiagnostic parcours={parcours} onChooseParcours={setParcours} />
      ) : (
        <GuestDiagnostic parcours={parcours} onChooseParcours={setParcours} />
      )}
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

function GuestDiagnostic({
  parcours,
  onChooseParcours,
}: {
  parcours: DiagnosticParcours;
  onChooseParcours: (parcours: DiagnosticParcours) => void;
}) {
  const complete = parcours === "COMPLET";
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
        <DiagnosticSteps current="account" guest complete={complete} />
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
        <DiagnosticSteps current="oral" guest complete={complete} />
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
        <DiagnosticSteps current="written" guest complete={complete} />
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
        written={subjects.written}
        oral={subjects.oral}
        onStart={(chosen) => {
          // Le choix ne change QUE ce qu'on enchaînera après le rapport : les
          // deux cartes ouvrent le même écrit, puis le même oral.
          onChooseParcours(chosen);
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

function ConnectedDiagnostic({
  parcours,
  onChooseParcours,
}: {
  parcours: DiagnosticParcours;
  onChooseParcours: (parcours: DiagnosticParcours) => void;
}) {
  const complete = parcours === "COMPLET";
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
    // 🛑 Ce corps async n'a VOLONTAIREMENT plus de drapeau `cancelled`.
    //
    // Le nettoyage de cet effet se déclenche à chaque nouvelle identité de
    // `user` — donc à chaque `refreshUser()`, donc juste après l'inscription
    // qui ouvre ce parcours — et systématiquement au premier montage en
    // StrictMode. Interrompre le corps à ce moment-là sortait **sans** lancer
    // `runHandoff` et **sans** repasser `loading` à `false`, tandis que le
    // garde ci-dessus interdisait toute reprise : l'écran restait bloqué sur le
    // squelette pour toujours et aucune session de diagnostic n'était créée.
    // En React 18+, un `setState` après démontage est un no-op silencieux :
    // laisser ce travail aller jusqu'au bout est à la fois plus simple et plus
    // sûr que de l'annuler. Le « exactement une fois » reste tenu par le `ref`,
    // qui est posé de façon **synchrone** avant le premier `await`.
    void (async () => {
      const local = await readLatestLocalDiagnostic().catch(() => null);
      if (isLocalDiagnosticComplete(local)) {
        await runHandoff(local);
        return;
      }
      try {
        const current = await diagnosticApi.current();
        setDiagnostic(current);
        setError(null);
      } catch (cause) {
        setError(errorMessage(cause, "Impossible de charger votre diagnostic."));
      } finally {
        setLoading(false);
      }
    })();
  }, [user, runHandoff]);

  // Filet de sécurité : un squelette est un état de CHARGEMENT, pas un état
  // d'échec. Si rien n'a abouti au bout de ce délai — bug imprévu, IndexedDB
  // qui ne répond jamais, requête suspendue — on rend la main au candidat avec
  // la carte « Le diagnostic n'a pas pu être chargé » et son bouton
  // « Réessayer », au lieu de le laisser devant un écran gris indéfiniment. Un
  // transfert en cours a son propre écran : il n'est jamais interrompu ici.
  useEffect(() => {
    if (!loading || handoff.kind === "running") return;
    const timer = setTimeout(() => {
      setLoading(false);
      setError(
        (previous) =>
          previous ?? "Le diagnostic met anormalement longtemps à répondre.",
      );
    }, LOADING_WATCHDOG_MS);
    return () => clearTimeout(timer);
  }, [loading, handoff.kind]);

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

  async function start(chosen: DiagnosticParcours) {
    if (submitting) return;
    onChooseParcours(chosen);
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
      setError(retryErrorMessage(cause));
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

  // ⚠️ L'ordre compte. `loading` reste vrai pendant TOUT le transfert des
  // productions faites en invité (création de session + deux envois + leurs
  // relectures) : tester le squelette avant l'état du transfert affichait deux
  // blocs gris pendant une minute au lieu de dire ce qui se passe. Un transfert
  // en cours prime donc toujours sur le chargement.
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

  // Chargement initial d'un parcours connecté normal, une fois écartés les
  // états de transfert ci-dessus.
  if (!user || loading) return <DiagnosticSkeleton />;

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
        <DiagnosticIntro
          error={error}
          submitting={submitting}
          written={diagnostic.written}
          oral={diagnostic.oral}
          onStart={(chosen) => void start(chosen)}
        />
      </DiagnosticShell>
    );
  }

  if (diagnostic.status === "FAILED") {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<RotateCcw size={26} />}
          title={ANALYSIS_FAILED_TITLE}
          // La carte dit d'abord, en langage clair, ce que le candidat doit
          // savoir. Le message brut du serveur (« Sortie diagnostic invalide
          // après réparation : EO2-C3 … ») n'est pas écrit pour lui : il passe
          // en second plan, sans jamais disparaître — le support s'en sert.
          text={ANALYSIS_FAILED_TEXT}
          role="alert"
          busy={submitting}
          extra={
            <>
              {/* Échec de la relance qu'on vient de tenter. Distinct du message
                  d'échec stocké de la session, affiché en bas de carte. */}
              {error && (
                <p className={styles.retryError} role="alert">
                  {error}
                </p>
              )}
              {!diagnostic.canRetry && (
                <p className={styles.stateNote}>{ANALYSIS_RETRY_EXHAUSTED}</p>
              )}
            </>
          }
          footnote={
            diagnostic.errorMessage ? (
              <p className={styles.stateDetail}>Détail technique : {diagnostic.errorMessage}</p>
            ) : null
          }
        >
          {diagnostic.canRetry && (
            <button
              className={styles.primaryButton}
              type="button"
              disabled={submitting}
              aria-busy={submitting || undefined}
              onClick={() => void retryAnalysis()}
            >
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
        parcours={parcours}
        targetLevel={user.targetLevel ?? null}
        hasTcf={user.hasTcf ?? false}
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

  // L'analyse IA elle-même : c'est le seul moment où le candidat attend un
  // rapport, et il doit savoir ce qui tourne.
  if (diagnostic.status === "ANALYZING" || diagnostic.nextStep === "ANALYSIS") {
    return (
      <DiagnosticShell>
        {notice}
        {/* Dernière marche du fil : le rapport est en cours de production. Le
            parcours complet y voit encore « Compréhension » en attente, ce qui
            annonce la suite avant même que le rapport ne la propose. */}
        <DiagnosticSteps current="report" guest={false} complete={complete} />
        <AnalysisWaiting diagnostic={diagnostic} transientMessage={error} />
      </DiagnosticShell>
    );
  }

  // Production reçue, mais la session n'a pas encore basculé sur l'étape
  // suivante : rien n'est analysé à ce stade, on ne le prétend pas.
  if (currentExercise?.submissionId != null) {
    return (
      <DiagnosticShell>
        {notice}
        <StateCard
          icon={<Sparkles size={26} />}
          title={
            diagnostic.nextStep === "WRITTEN"
              ? "Votre écrit est bien reçu"
              : "Votre oral est bien reçu"
          }
          text="Vos réponses sont conservées. Vous pouvez quitter cet écran et reprendre plus tard, sans rien refaire."
          busy
        >
          {error && <p className={styles.waitTransient} role="status">{error}</p>}
          <Link className={styles.secondaryButton} href="/dashboard">Revenir au tableau de bord</Link>
        </StateCard>
      </DiagnosticShell>
    );
  }

  if (diagnostic.nextStep === "WRITTEN" && diagnostic.written) {
    const exercise = diagnostic.written;
    return (
      <DiagnosticShell compact>
        <DiagnosticSteps current="written" guest={false} complete={complete} />
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
        <DiagnosticSteps current="oral" guest={false} complete={complete} />
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

  // Même écran que ci-dessus, à la même place dans l'arbre : une bascule entre
  // les deux branches ne remonte pas le composant, donc ne remet pas le
  // compteur d'attente à zéro.
  return (
    <DiagnosticShell>
      {notice}
      <DiagnosticSteps current="report" guest={false} complete={complete} />
      <AnalysisWaiting diagnostic={diagnostic} transientMessage={error} />
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
  extra,
  footnote,
  children,
  busy = false,
  role,
}: {
  icon: ReactNode;
  title: string;
  text: string;
  /** Rendu entre le texte et les actions (message transitoire, explication). */
  extra?: ReactNode;
  /** Rendu sous les actions : information de second plan (détail technique). */
  footnote?: ReactNode;
  children?: React.ReactNode;
  busy?: boolean;
  role?: "alert";
}) {
  return (
    <section className={styles.stateCard} role={role} aria-busy={busy || undefined}>
      <span className={`${styles.stateIcon} ${busy ? styles.stateIconBusy : ""}`} aria-hidden>{icon}</span>
      <h1>{title}</h1>
      <p>{text}</p>
      {extra}
      <div className={styles.actions}>{children}</div>
      {footnote}
      {busy && <span className={styles.loadingBar} aria-hidden />}
    </section>
  );
}

/** Au-delà, on cesse d'annoncer « moins de deux minutes » : ce serait faux. */
const SLOW_ANALYSIS_MS = 120_000;

function formatElapsed(elapsedMs: number): string {
  const totalSeconds = Math.max(0, Math.floor(elapsedMs / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

/**
 * Attente de l'analyse IA — le seul écran où le candidat n'a plus rien à faire
 * et où le rapport n'est pas encore là.
 *
 * Il a été muet pendant des mois : une carte discrète, aucune mention de l'IA,
 * aucun repère de temps. Un candidat venu des réseaux voyait un écran gris et
 * partait. On nomme donc ce qui tourne, on montre les étapes franchies et on
 * fait tourner un compteur — une attente chiffrée est une attente supportable.
 *
 * Le compteur démarre à l'ENTRÉE dans cet écran, pas au montage de la page :
 * c'est le composant lui-même qui le porte.
 */
function AnalysisWaiting({
  diagnostic,
  transientMessage,
}: {
  diagnostic: DiagnosticResponse;
  transientMessage: string | null;
}) {
  const [elapsedMs, setElapsedMs] = useState(0);

  useEffect(() => {
    const startedAt = Date.now();
    const timer = setInterval(() => setElapsedMs(Date.now() - startedAt), 1_000);
    return () => clearInterval(timer);
  }, []);

  const writtenReceived = diagnostic.written?.submissionId != null;
  const oralReceived = diagnostic.oral?.submissionId != null;
  const slow = elapsedMs >= SLOW_ANALYSIS_MS;

  const steps: Array<{key: string; done: boolean; label: string}> = [
    {
      key: "written",
      done: writtenReceived,
      label: writtenReceived ? "Réponse écrite reçue" : "Réponse écrite en attente",
    },
    {
      key: "oral",
      done: oralReceived,
      label: oralReceived ? "Réponse orale reçue" : "Réponse orale en attente",
    },
    {key: "analysis", done: false, label: "Analyse IA en cours"},
  ];

  return (
    <section className={styles.stateCard} aria-busy="true">
      <span className={`${styles.stateIcon} ${styles.stateIconBusy}`} aria-hidden>
        <Sparkles size={26} />
      </span>
      <h1>Analyse IA de vos deux productions en cours</h1>
      <p>
        Votre écrit et votre oral sont analysés ensemble pour repérer les compétences
        réellement observables. Votre rapport s&apos;affichera ici tout seul.
      </p>

      <div className={styles.waitPanel}>
        <ol className={styles.waitSteps} role="status">
          {steps.map((step) => (
            <li key={step.key} data-state={step.done ? "done" : "running"}>
              <span aria-hidden>
                {step.done ? <Check size={13} strokeWidth={3.2} /> : <Sparkles size={13} />}
              </span>
              {step.label}
            </li>
          ))}
        </ol>
        <p className={styles.waitTimer}>
          <Clock3 size={14} aria-hidden />
          <span>Temps écoulé</span>
          {/* Pas de région live sur le chiffre : un lecteur d'écran ne doit pas
              énoncer une nouvelle valeur chaque seconde. */}
          <b aria-live="off">{formatElapsed(elapsedMs)}</b>
        </p>
      </div>

      <p className={styles.waitReassurance}>
        {slow
          ? "C'est plus long que d'habitude. L'analyse continue côté serveur : rien n'est perdu. Vous pouvez fermer cet écran et revenir plus tard, votre rapport vous attendra."
          : "L'analyse prend généralement moins de deux minutes. Vous pouvez quitter cet écran et revenir plus tard : elle continue côté serveur et rien n'est perdu."}
      </p>

      {transientMessage && <p className={styles.waitTransient}>{transientMessage}</p>}

      <div className={styles.actions}>
        <Link className={styles.secondaryButton} href="/dashboard">
          Revenir au tableau de bord
        </Link>
      </div>
      <span className={styles.loadingBar} aria-hidden />
    </section>
  );
}

/**
 * Les compétences **réellement observées** sur les deux productions, dédoublonnées
 * par identifiant. Une observation non effective n'y entre jamais : « je n'ai pas
 * pu observer » n'est pas « le candidat est faible ».
 */
function observedSkills(result: DiagnosticResultDto): DiagnosticSkillObservationDto[] {
  const unique = new Map<string, DiagnosticSkillObservationDto>();
  for (const skill of [...(result.written?.skills ?? []), ...(result.oral?.skills ?? [])]) {
    if (skill.observed) unique.set(skill.skillId, skill);
  }
  return [...unique.values()];
}

const FRAGILE_STATUSES: LearningPlanSkillStatus[] = ["PRIORITY", "TO_REINFORCE"];

/**
 * Ce que l'écran met en tête : les priorités mesurées par l'analyse, ou — quand
 * le serveur n'en a désigné aucune — les points à travailler relevés sur chaque
 * production.
 *
 * ⚠️ `priorities` peut être **vide** : c'est un état normal, pas une panne. Le
 * repli ne prétend jamais que ces points sont des priorités classées, et le
 * drapeau `measured` est ce qui fait changer les libellés de l'écran.
 *
 * 🛑 **Cette fonction ne tronque RIEN.** `priorities` est plafonné à **3** côté
 * serveur — règle produit — donc la liste est complétée par les autres
 * fragilités réellement observées : sans ça, un abonné n'aurait jamais vu ce que
 * le teaser d'un compte gratuit lui promet.
 *
 * 🛑 **`total` vient du SERVEUR** (`fragileSkillCount`), jamais d'un comptage
 * local : c'est lui qui fait le « + N autres ». Le `Math.max` n'est qu'un
 * garde-fou — on n'annonce jamais moins que ce qu'on affiche.
 */
interface ResultLever {
  key: string;
  title: string;
  detail: string | null;
  evidence: string | null;
  status: LearningPlanSkillStatus | null;
  section: SkillSection | null;
}

function resultLevers(result: DiagnosticResultDto): {
  levers: ResultLever[];
  measured: boolean;
  total: number;
} {
  const fragile = observedSkills(result).filter((skill) =>
    FRAGILE_STATUSES.includes(skill.status),
  );
  const toLever = (skill: DiagnosticSkillObservationDto, rank: number): ResultLever => ({
    key: skill.skillId,
    title: skill.skillTitle,
    detail: (rank === 0 ? result.mainPriorityExplanation : null) ?? skill.explanation,
    evidence: skill.evidence,
    status: skill.status,
    section: skill.section,
  });

  if (result.priorities.length > 0) {
    const ranked = result.priorities.map(toLever);
    const seen = new Set(ranked.map((lever) => lever.key));
    const rest = fragile
      .filter((skill) => !seen.has(skill.skillId))
      .map((skill) => toLever(skill, -1));
    const levers = [...ranked, ...rest];
    return {measured: true, levers, total: Math.max(result.fragileSkillCount, levers.length)};
  }

  if (fragile.length > 0) {
    const levers = fragile.map((skill) => toLever(skill, -1));
    return {measured: false, levers, total: Math.max(result.fragileSkillCount, levers.length)};
  }

  // Dernier repli : on alterne écrit et oral pour ne pas servir trois points
  // d'une seule production quand les deux en portent.
  const written = result.written?.weaknesses ?? [];
  const oral = result.oral?.weaknesses ?? [];
  const fallback: ResultLever[] = [];
  for (let i = 0; i < Math.max(written.length, oral.length); i += 1) {
    if (written[i]) {
      fallback.push({
        key: `ee-${i}`,
        title: written[i],
        detail: null,
        evidence: null,
        status: null,
        section: "EE",
      });
    }
    if (oral[i]) {
      fallback.push({
        key: `eo-${i}`,
        title: oral[i],
        detail: null,
        evidence: null,
        status: null,
        section: "EO",
      });
    }
  }
  return {measured: false, levers: fallback, total: fallback.length};
}

/**
 * Les **points forts** : les compétences que les deux productions ont montrées
 * solides, et rien d'autre.
 *
 * ⚠️ Les phrases `strengths` du résumé ne sont qu'un **repli** : elles sont
 * plafonnées à 3 **à l'écriture** côté serveur, donc leur longueur ne dit rien du
 * nombre réel et elles ne peuvent porter aucun compteur. Dès qu'une compétence
 * solide existe, ce sont les compétences qui font foi — elles portent en plus
 * leur explication et leur extrait.
 */
function resultStrengths(result: DiagnosticResultDto): {
  skills: DiagnosticSkillObservationDto[];
  texts: string[];
  total: number;
} {
  const skills = observedSkills(result).filter((skill) => skill.status === "SOLID");
  const texts = skills.length > 0 ? [] : result.strengths;
  return {
    skills,
    texts,
    total: Math.max(result.solidSkillCount, skills.length || texts.length),
  };
}

/** Lien vers l'offre, avec sa mesure de conversion. Deux emplacements l'ouvrent
 *  (paywall du plan, CTA final) : l'événement est émis au même endroit pour les
 *  deux, jamais recopié dans un `onClick` de composant. La provenance suit le
 *  candidat jusqu'à la page d'achat — c'est ce qui relie une campagne à un
 *  paiement. */
function PremiumLink({
  className,
  children,
}: {
  className: string;
  children: ReactNode;
}) {
  const href = useTrafficSourceHref("/paiement?module=INTEGRAL");
  return (
    <Link
      className={className}
      href={href}
      onClick={() => trackAudienceEvent("/diagnostic", "DIAGNOSTIC_TO_PREMIUM_CLICKED")}
    >
      {children}
    </Link>
  );
}

/* --------------------------------------------------- rapport et abonnement */

/**
 * Combien de lignes un compte SANS accès TCF voit en clair avant le rideau :
 * **une seule**, de chaque côté. Deux lignes réelles sont ensuite floutées, puis
 * le compteur annonce **tout** ce qui reste.
 *
 * 🛑 **Ces deux nombres bornent l'AFFICHAGE, jamais la donnée.** Le compte
 * annoncé, lui, vient du serveur (`fragileSkillCount` / `solidSkillCount`) — cf.
 * `LockedTease`. Miroirs mobile : `_kFreeFocusVisible` / `_kFreeSolidVisible`.
 */
const FREE_PRIORITIES = 1;
const FREE_STRENGTHS = 1;

/**
 * Combien de lignes **réelles** le rideau laisse deviner. C'est un échantillon,
 * jamais le compte : le compte, lui, est exact et porte sur tout ce qui reste.
 * Miroir mobile : `_kBlurredSample`.
 */
const TEASE_SAMPLE = 2;

/**
 * Les lignes à flouter et le nombre à annoncer, à partir d'une liste affichée en
 * partie et d'un **total servi par le serveur**.
 *
 * 🛑 `hidden === 0` ⇒ **aucun bloc** : une liste plus courte que le seuil
 * s'affiche entièrement en clair, on ne fabrique jamais de reste à vendre.
 */
function teaseFrom<T>(
  rows: T[],
  visible: number,
  total: number,
): {hidden: number; sample: T[]} {
  const hidden = Math.max(0, total - Math.min(visible, rows.length));
  return {hidden, sample: rows.slice(visible, visible + Math.min(TEASE_SAMPLE, hidden))};
}

/**
 * Le chapeau du rapport, qui dit d'emblée si le candidat lit tout ou une partie.
 *
 * ⚠️ **Vouvoiement, comme tout le rapport et tout le Plan** — le tutoiement est
 * réservé au module Compétences. La maquette tutoie parce que ses écrans
 * décrivent un visiteur d'AVANT l'inscription ; ce rapport-ci n'existe qu'une
 * fois le compte créé, et le sous-titre de la même carte dit déjà « vos
 * erreurs ». Nommées ici pour qu'un aller-retour coûte une ligne.
 */
const REPORT_EYEBROW_PREMIUM = "Rapport complet";
const REPORT_EYEBROW_FREE = "Votre rapport de diagnostic";

/**
 * Ce que l'abonnement ouvre, dit du point de vue du candidat qui vient de lire
 * son diagnostic.
 *
 * ⚠️ **Liste distincte de celle du Plan** et de celle de `/tarifs` : elle ne
 * vend pas le catalogue, elle nomme la suite de CE rapport. Ne pas la fusionner
 * avec un argumentaire commercial générique.
 */
const PREMIUM_BENEFITS = [
  "Toutes vos priorités détectées",
  "Les petits sujets ciblés, compétence par compétence",
  "Les corrections IA et la version au niveau visé",
  "Votre plan qui se réordonne à chaque production",
  "Le moment où vous êtes prêt pour un examen blanc",
];

/** « + 2 autres priorités détectées », accordé sur un compte RÉEL. */
function moreLabel(count: number, singular: string, plural: string): string {
  return `+ ${count} ${count > 1 ? plural : singular}`;
}

/**
 * Bloc « il y en a d'autres » : le contenu RÉEL du candidat, flouté.
 *
 * 🛑 **Rien n'est fabriqué pour remplir le flou.** Les lignes montrées sont
 * celles que le serveur a réellement renvoyées, et l'abonnement les révèle
 * telles quelles — un compteur de teaser n'est honnête que si le
 * déverrouillage montre vraiment ce nombre-là. C'est aussi pourquoi le bloc
 * **n'existe pas** quand il n'y a rien de plus à montrer : l'appelant ne le
 * rend que sur une liste non vide, il ne fabrique jamais de reste.
 *
 * Le flou est purement décoratif, donc `aria-hidden` : c'est le pied du bloc —
 * net, lisible, sélectionnable — qui porte l'information pour tout le monde, y
 * compris un lecteur d'écran.
 *
 * Le clic passe par `PremiumLink`, **le seul chemin instrumenté** de cet écran
 * vers l'offre : aucun second chemin, aucun événement d'audience nouveau.
 */
function LockedTease({
  rows,
  label,
}: {
  rows: {key: string; title: string; meta: string | null}[];
  label: string;
}) {
  return (
    <PremiumLink className={styles.tease}>
      {/* Illisible à l'œil ET au lecteur d'écran : `aria-hidden` le sort de
          l'arbre d'accessibilité, `inert` le rend en plus non focusable et
          non atteignable au clavier. Sans les deux, le contenu verrouillé
          resterait lisible en synthèse vocale — un contournement, et un
          mensonge d'accessibilité. */}
      <span className={styles.teaseBlur} aria-hidden inert>
        {rows.map((row) => (
          <span key={row.key} className={styles.teaseRow}>
            <span className={styles.teaseDot} />
            <span className={styles.teaseBody}>
              <b>{row.title}</b>
              {row.meta && <span>{row.meta}</span>}
            </span>
          </span>
        ))}
      </span>
      <span className={styles.teaseFoot}>
        <Lock size={15} aria-hidden />
        <span className={styles.teaseCount}>{label}</span>
        <span className={styles.teaseCta}>Débloquer</span>
      </span>
    </PremiumLink>
  );
}

/**
 * Écran de RÉSULTAT du diagnostic.
 *
 * Géométrie de la maquette « diagnostic premium », couleurs et fontes de
 * l'application (même méthode que `skill-ui/`). Trois choses de la maquette sont
 * volontairement absentes, et ne doivent pas revenir :
 *
 * - **les barres de progression chiffrées** — le score de maîtrise n'est exposé
 *   à aucun front, exprès. On affiche l'**état d'observation** de la compétence
 *   (libellés gelés `LEARNING_PLAN_SKILL_STATUS_LABEL`) ;
 * - **le calendrier « Semaine 1 · Étape 1 à 4 »** — le Plan n'a aucune notion de
 *   semaine ni de jour. Ce qui existe vraiment, c'est l'exercice recommandé et,
 *   le cas échéant, sa **vérification** (`kind === "REASSESSMENT"`) ;
 * - **les emojis en texte brut** — le projet utilise `lucide-react`.
 */
function DiagnosticResult({
  diagnostic,
  parcours,
  targetLevel,
  hasTcf,
  planHref,
  notice,
}: {
  diagnostic: DiagnosticResponse;
  /** Ce que le candidat a choisi à l'entrée. **Rien d'autre n'en dépend** : il
   *  ne décide que de la PLACE de « Votre profil TCF » et du ton de sa phrase —
   *  la suite immédiate, ou une invitation sans pression. Les données servies
   *  sont exactement les mêmes dans les deux cas. */
  parcours: DiagnosticParcours;
  targetLevel: string | null;
  /** Accès TCF du compte : il ne masque **aucune information** du Plan, il ne
   *  décide que de l'affichage des cadenas d'accès et de l'invitation à
   *  l'offre. */
  hasTcf: boolean;
  planHref: string;
  notice?: ReactNode;
}) {
  const result = diagnostic.result;

  if (!result) {
    return (
      <DiagnosticShell>
        {notice}
        <StateCard icon={<Sparkles size={26} />} title="Votre résultat se prépare" text="L'analyse est terminée, mais sa synthèse n'est pas encore disponible." busy />
      </DiagnosticShell>
    );
  }

  const {levers, measured, total: leverTotal} = resultLevers(result);
  const strengths = resultStrengths(result);
  const nextAction = result.nextAction;
  const exemple = result.exempleCible;
  // Aperçu du plan : deux étapes à venir au plus, comme avant. Le compteur d'un
  // compte gratuit, lui, porte sur le total réel — pas sur cet aperçu.
  const nextSteps = measured ? levers.slice(1, 3) : [];
  // Parcours complet : la compréhension est la suite immédiate, elle se lit
  // juste sous le niveau estimé. Parcours rapide : le rapport mène d'abord au
  // plan, et le profil reste à compléter plus bas, sans pression.
  const complete = parcours === "COMPLET";

  // ------------------------------------------------------------ freemium
  // 🛑 **Ce qui est masqué, c'est ce qui RESTE À FAIRE — jamais ce que le
  // candidat a établi.** Restent entiers pour tout le monde : les niveaux
  // estimés, l'objectif, le rail, le résumé, le « avant / après », le détail
  // des deux productions et les quatre domaines du profil. Ce sont **ses**
  // productions et **ses** mesures ; on tease la suite, on ne lui retire pas
  // son résultat.
  //
  // ⚠️ Cette bascule vaut pour le **rapport de diagnostic**, écran de
  // conversion, et **pas** pour `/plan` : la règle « le Plan reste
  // intégralement visible sans abonnement » est intacte chez lui.
  //
  // Les trois découpes se lisent toutes de la même façon : ce qui est visible,
  // puis **exactement le reste**. Aucun compteur n'est écrit en dur, et une
  // liste plus courte que le seuil ne produit aucun teaser (`slice` rend un
  // tableau vide, l'appelant ne rend rien).
  const visibleLevers = hasTcf ? levers : levers.slice(0, FREE_PRIORITIES);
  const leverTease = hasTcf
    ? {hidden: 0, sample: [] as ResultLever[]}
    : teaseFrom(levers, FREE_PRIORITIES, leverTotal);
  // ⚠️ Un abonné voit **tous** ses points forts : le teaser annonce « + N
  // autres », il faut donc que le déverrouillage en montre réellement N de plus.
  const visibleSolid = hasTcf ? strengths.skills : strengths.skills.slice(0, FREE_STRENGTHS);
  const visibleTexts = hasTcf ? strengths.texts : strengths.texts.slice(0, FREE_STRENGTHS);
  const strengthTease = hasTcf
    ? {hidden: 0, sample: [] as {key: string; title: string; meta: string | null}[]}
    : teaseFrom<{key: string; title: string; meta: string | null}>(
        strengths.skills.length > 0
          ? strengths.skills.map((skill) => ({
              key: skill.skillId,
              title: skill.skillTitle,
              meta: productionSectionLabel(skill.section),
            }))
          : strengths.texts.map((item) => ({key: item, title: item, meta: null})),
        FREE_STRENGTHS,
        strengths.total,
      );

  return (
    <DiagnosticShell>
      <div className={styles.result}>
        {notice}

        <header className={styles.resultHeader}>
          <span className={styles.doneBadge}>
            <i aria-hidden><Check size={11} strokeWidth={3.4} /></i> Diagnostic terminé
          </span>
          <p className={styles.resultEyebrow}>
            {hasTcf ? REPORT_EYEBROW_PREMIUM : REPORT_EYEBROW_FREE} · 2 productions
            analysées
          </p>
          <h1>
            Vous savez maintenant <em>quoi travailler en priorité</em>.
          </h1>
          <p className={styles.resultLead}>
            Vos deux productions ont été analysées ensemble. Inutile de tout revoir : voici
            ce qui vous fera progresser le plus vite, et par quoi commencer.
          </p>
          {!hasTcf && (
            <PremiumLink className={styles.headUnlock}>
              Débloquer mon plan <ArrowRight size={16} aria-hidden />
            </PremiumLink>
          )}
        </header>

        {/* ------------------------------ niveaux estimés + carte de décision */}
        <div className={styles.heroGrid}>
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

          <aside className={styles.convCard}>
            <h2>Votre prochain niveau se joue ici.</h2>
            <p className={styles.convLead}>
              {measured
                ? "Votre plan commence par ces priorités, puis se réordonne à chacune de vos nouvelles productions."
                : "Votre plan part de ces points, puis se réordonne à chacune de vos nouvelles productions."}
            </p>
            {/* Le même découpage que la section « Vos priorités » plus bas :
                deux surfaces qui montreraient un nombre différent de priorités
                se contrediraient, et l'une démentirait le teaser de l'autre. */}
            {visibleLevers.length > 0 && (
              <ol className={styles.convList}>
                {visibleLevers.map((lever, index) => (
                  <li key={lever.key} className={styles.convItem}>
                    <span className={styles.convRank} data-rank={index + 1} aria-hidden>
                      {index + 1}
                    </span>
                    <div className={styles.convCopy}>
                      <b>{lever.title}</b>
                      {lever.detail && <span>{lever.detail}</span>}
                    </div>
                  </li>
                ))}
              </ol>
            )}
            <Link href={planHref} className={styles.primaryButton}>
              Voir mon plan personnalisé <ArrowRight size={17} aria-hidden />
            </Link>
            {exemple && (
              <a href="#exemple" className={styles.secondaryButton}>
                Voir un exemple d&apos;amélioration
              </a>
            )}
            <p className={styles.convMicro}>
              <Check size={13} aria-hidden />
              {nextAction && !nextAction.locked
                ? "Le premier exercice de votre plan est accessible sans payer."
                : "Consulter votre plan ne demande aucun paiement."}
            </p>
          </aside>
        </div>

        <p className={styles.note}>
          <Info size={15} aria-hidden />
          Cette estimation est pédagogique : elle ne remplace pas un résultat officiel du TCF.
        </p>

        {/* ------------------------------------------------ avant / après */}
        {exemple && (
          <section id="exemple" aria-labelledby="exemple-title">
            <ResultBlockHead
              id="exemple-title"
              title="Concrètement, à quoi ressemble le niveau visé ?"
              text="Votre phrase, puis la même idée écrite au niveau que vous visez."
            />
            <BeforeAfter exemple={exemple} />
          </section>
        )}

        {/* ----------------------------------------------- les priorités */}
        {levers.length > 0 && (
          <section aria-labelledby="levers-title">
            <ResultBlockHead
              id="levers-title"
              title={measured ? "Vos priorités, dans l'ordre" : "Ce qu'il y a à travailler"}
              text={
                measured
                  ? "Le diagnostic ne liste pas vos erreurs : il désigne les compétences qui feront bouger votre niveau."
                  : "Ces points viennent de vos deux productions. Ils ne sont pas encore classés en priorités."
              }
            />
            <div className={styles.leverGrid}>
              {visibleLevers.map((lever, index) => (
                <article key={lever.key} className={styles.leverCard}>
                  <p className={styles.leverNum}>
                    {measured ? `Priorité ${index + 1}` : "Point à travailler"}
                  </p>
                  <h3>{lever.title}</h3>
                  {lever.detail && <p className={styles.leverText}>{lever.detail}</p>}
                  <div className={styles.leverMeta}>
                    {lever.status && (
                      <span
                        className={styles.leverStatus}
                        data-tone={LEARNING_PLAN_SKILL_STATUS_TONE[lever.status]}
                      >
                        {LEARNING_PLAN_SKILL_STATUS_LABEL[lever.status]}
                      </span>
                    )}
                    {lever.section && (
                      <span className={styles.leverSection}>
                        {productionSectionLabel(lever.section)}
                      </span>
                    )}
                  </div>
                  {lever.evidence && (
                    <blockquote className={styles.leverQuote}>
                      «&nbsp;{evidenceExcerpt(lever.evidence)}&nbsp;»
                    </blockquote>
                  )}
                </article>
              ))}
            </div>
            {leverTease.hidden > 0 && (
              <LockedTease
                rows={leverTease.sample.map((lever) => ({
                  key: lever.key,
                  title: lever.title,
                  meta: lever.section ? productionSectionLabel(lever.section) : null,
                }))}
                /* Le teaser parle la même langue que sa section : sans
                   priorités mesurées, ce ne sont pas des « priorités » mais des
                   points relevés — le repli ne doit pas les promouvoir. */
                label={
                  measured
                    ? moreLabel(
                        leverTease.hidden,
                        "autre priorité détectée",
                        "autres priorités détectées",
                      )
                    : moreLabel(
                        leverTease.hidden,
                        "autre point à travailler",
                        "autres points à travailler",
                      )
                }
              />
            )}
          </section>
        )}

        {/* ---------------------------------------------------- votre plan */}
        {nextAction && (
          <section aria-labelledby="plan-title">
            <ResultBlockHead
              id="plan-title"
              title="Votre plan est déjà construit"
              text="Il commence par votre priorité n°1 et se réordonne à chacune de vos nouvelles productions."
            />
            <div className={styles.planShell}>
              <article className={styles.planStep}>
                <p className={styles.planStepNum}>
                  {nextAction.kind === "REASSESSMENT" ? "Vérification" : "Étape 1"}
                </p>
                <h3>{nextAction.title}</h3>
                <p className={styles.planStepMeta}>
                  <Clock3 size={13} aria-hidden /> {nextAction.estimatedMinutes} min ·{" "}
                  {productionSectionLabel(nextAction.section)}
                </p>
                <Link className={styles.planStepCta} href={recommendedExerciseHref(nextAction)}>
                  {nextAction.kind === "REASSESSMENT"
                    ? "Vérifier ma progression"
                    : "Commencer cet exercice"}
                  <ArrowRight size={15} aria-hidden />
                </Link>
              </article>

              {hasTcf &&
                nextSteps.map((step, index) => (
                  <article key={step.key} className={styles.planStep}>
                    <p className={styles.planStepNum}>Étape {index + 2}</p>
                    <h3>{step.title}</h3>
                    {step.detail && <p className={styles.planStepText}>{step.detail}</p>}
                  </article>
                ))}

              {/* Sans abonnement, un seul entraînement est jouable : les
                  suivants se comptent au lieu de s'afficher en double. Leurs
                  compétences sont déjà nommées plus haut, dans les priorités —
                  ce qui est fermé ici, c'est l'exercice, pas le diagnostic. */}
              {!hasTcf && leverTease.hidden > 0 && (
                <PremiumLink className={styles.planMore}>
                  <Lock size={15} aria-hidden />
                  <span className={styles.planMoreCount}>
                    {moreLabel(
                      leverTease.hidden,
                      "autre entraînement personnalisé",
                      "autres entraînements personnalisés",
                    )}
                  </span>
                  <span className={styles.planMoreCta}>Débloquer</span>
                </PremiumLink>
              )}
            </div>
          </section>
        )}

        {/* ------------------------------------------------- vos points forts */}
        {/* 🛑 **Cette section a REMPLACÉ « Le détail reste disponible »**, qui
            listait en clair *toutes* les compétences observées — donc, dix
            lignes plus bas, exactement ce que les deux rideaux prétendaient
            cacher. Ce qui est fragile se lit dans « Vos priorités », ce qui est
            solide se lit ici, et rien n'est affiché deux fois. */}
        {(visibleSolid.length > 0 || visibleTexts.length > 0) && (
          <section aria-labelledby="strengths-title">
            <ResultBlockHead
              id="strengths-title"
              title="Vos points forts"
              text="Ce que vos deux productions ont déjà montré de solide. Ouvrez seulement ce qui vous intéresse."
            />
            <div className={styles.snapshot}>
              {visibleTexts.length > 0 && (
                <div className={styles.snapshotStrengths}>
                  <b>Ce qui fonctionne déjà</b>
                  <ul>
                    {visibleTexts.map((item) => <li key={item}>{item}</li>)}
                  </ul>
                </div>
              )}
              {visibleSolid.map((skill) => (
                <SkillDisclosure key={skill.skillId} skill={skill} />
              ))}
              {strengthTease.hidden > 0 && (
                <LockedTease
                  rows={strengthTease.sample}
                  label={moreLabel(
                    strengthTease.hidden,
                    "autre compétence déjà solide",
                    "autres compétences déjà solides",
                  )}
                />
              )}
            </div>
          </section>
        )}

        {/* ------------------------------------------ compléter mon profil */}
        {/* ⚠️ **Un seul emplacement, celui de l'ordre demandé** : priorités →
            points forts → compléter mon profil → carte d'abonnement. Le bloc
            n'existe que s'il reste un domaine à mesurer (`domainesAEvaluer`
            vide = profil complet, l'état visé) ; `emphasis` ne change que la
            phrase, jamais la place. **Le Plan continue de le servir chez lui** :
            ce rapport ne se lit qu'une fois, sans le rappel du Plan un candidat
            qui passe outre garderait un profil incomplet sans le savoir. */}
        <DiagnosticProfileCard emphasis={complete ? "next" : "later"} />

        {/* ---------------------------------------------- vos 2 productions */}
        <section aria-labelledby="productions-title">
          <ResultBlockHead
            id="productions-title"
            title="Vos deux productions"
            text="Ce que chacune a montré, dans le détail."
          />
          <div className={styles.productions}>
            <ProductionSummary kind="written" production={result.written} hasTcf={hasTcf} />
            <ProductionSummary kind="oral" production={result.oral} hasTcf={hasTcf} />
          </div>
        </section>

        {/* ------------------------------------------------------ CTA final */}
        {/* Un seul bloc de fin, jamais deux empilés : l'abonné est renvoyé vers
            son plan, le compte gratuit vers ce que l'abonnement ouvre — sans
            perdre l'accès au plan, qui reste gratuit et entièrement lisible. */}
        {hasTcf ? (
          <section className={styles.finalCard}>
            <span className={styles.finalSpark} aria-hidden><Sparkles size={20} /></span>
            <h2>
              Le diagnostic a trouvé <em>quoi</em> travailler. Le plan vous le fait travailler.
            </h2>
            <p>
              Commencez par votre priorité n°1, obtenez une correction IA, puis laissez le plan
              se réordonner selon vos progrès.
            </p>
            <div className={styles.finalActions}>
              <Link href={planHref} className={styles.finalPrimary}>
                Découvrir mon plan <ArrowRight size={17} aria-hidden />
              </Link>
            </div>
          </section>
        ) : (
          <section className={styles.unlockCard} aria-labelledby="unlock-title">
            <span className={styles.finalSpark} aria-hidden><Sparkles size={20} /></span>
            <h2 id="unlock-title">
              Débloquez <em>votre plan complet</em>.
            </h2>
            <p>
              Le diagnostic a trouvé quoi travailler. Le plan vous le fait travailler.
            </p>
            <ul className={styles.unlockList}>
              {PREMIUM_BENEFITS.map((benefit) => (
                <li key={benefit}>
                  <Check size={15} strokeWidth={2.8} aria-hidden />
                  {benefit}
                </li>
              ))}
            </ul>
            <div className={styles.finalActions}>
              <PremiumLink className={styles.finalPrimary}>
                Débloquer mon plan <ArrowRight size={17} aria-hidden />
              </PremiumLink>
              <Link href={planHref} className={styles.finalGhost}>
                Voir mon plan
              </Link>
            </div>
          </section>
        )}
      </div>

      {/* Barre collante mobile : la réserve de pied de page est posée sur
          `.result`, elle ne masque donc aucun contenu. */}
      <div className={styles.stickyCta}>
        <Link href={planHref} className={styles.primaryButton}>
          Voir mon plan personnalisé <ArrowRight size={17} aria-hidden />
        </Link>
      </div>
    </DiagnosticShell>
  );
}

/**
 * La phrase du candidat, puis sa réécriture au niveau visé.
 *
 * Le « après » réutilise **`ActionPlanExemple`** — la brique partagée du plan
 * d'action (rapport de correction EE/EO et micro-exercice de compétence) : elle
 * sait déjà surligner les segments par recherche de chaîne en nœuds React et
 * rendre la puce d'apport de chacun. Le seul ajout du diagnostic est le
 * « avant ». `SkillAccent` pose `--skill-accent`, dont cette brique dépend et
 * que le chrome du diagnostic ne porte pas.
 */
function BeforeAfter({exemple}: {exemple: DiagnosticExempleCibleDto}) {
  return (
    <article className={styles.revealCard}>
      <div className={styles.revealTop}>
        <h3>Exemple tiré de votre production écrite</h3>
        <span className={styles.revealImpact}>
          <TrendingUp size={13} aria-hidden /> Vers {niveauEstimateLabel(exemple.niveauVise)}
        </span>
      </div>
      <div className={styles.beforeAfter}>
        <div className={styles.phrase}>
          <p className={styles.phraseLabel}>Votre formulation</p>
          <blockquote>«&nbsp;{exemple.original}&nbsp;»</blockquote>
        </div>
        <div className={styles.arrowBox} aria-hidden>
          <span><ArrowRight size={20} strokeWidth={2.6} /></span>
        </div>
        <div className={styles.phraseAfter}>
          <p className={styles.phraseLabel}>Au niveau visé</p>
          <SkillAccent>
            <ActionPlanExemple exemple={exemple} />
          </SkillAccent>
        </div>
      </div>
    </article>
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
  hasTcf,
}: {
  kind: "written" | "oral";
  production: DiagnosticProductionResultDto | null;
  /** 🛑 **Sans accès, la liste « À travailler » n'est pas rendue.** Elle nomme
   *  en clair les fragilités que le rideau des priorités vient de flouter :
   *  l'afficher ici démentirait le teaser trois sections plus haut. Ce n'est pas
   *  un retrait d'information — la priorité n°1 reste lisible en entier, avec
   *  son extrait, et le compteur dit combien il en reste. */
  hasTcf: boolean;
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

        {hasTcf && production.weaknesses.length > 0 && (
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
