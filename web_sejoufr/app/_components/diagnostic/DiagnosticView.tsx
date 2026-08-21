"use client";

import Link from "next/link";
import {useCallback, useEffect, useRef, useState, type ReactNode} from "react";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ChevronDown,
  Clock3,
  FilePenLine,
  Headphones,
  Info,
  Lock,
  RotateCcw,
  Sparkles,
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
  type DiagnosticExerciseContent,
  diagnosticExerciseAsProductionTask,
  LEARNING_PLAN_SKILL_STATUS_LABEL,
  LEARNING_PLAN_SKILL_STATUS_TONE,
  productionSectionLabel,
  recommendedExerciseHref,
  skillTaskNumber,
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
import type {
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
import {DiagnosticLevelCard} from "./DiagnosticLevelCard";
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
  /** Le code de la compétence (`EE2-C3`), d'où se lit le numéro de tâche du
   *  repère de ligne. `null` sur le repli « points relevés », qui ne vient
   *  d'aucune compétence. */
  skillCode: string | null;
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
    skillCode: skill.skillCode,
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
        skillCode: null,
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
        skillCode: null,
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
 * **Les libellés du rapport**, déclarés une seule fois.
 *
 * ⚠️ **Miroirs mot pour mot du mobile** (`diagnostic_report_labels.dart`) : ces
 * chaînes ne transitent pas par le réseau, chaque front en tient sa copie. Un
 * libellé qui bouge, ce sont deux fichiers à changer dans la même passe.
 *
 * ⚠️ **Vouvoiement.** La maquette du propriétaire tutoie, mais elle ne donne que
 * la direction **visuelle** — structure, ordre des blocs, densité, ce qu'on
 * retire. Le registre reste celui de l'application : le rapport et le Plan
 * vouvoient, seul le module Compétences tutoie.
 */
const REPORT_TITLE = "Votre rapport";
const REPORT_SUB_PREMIUM = "Rapport complet";
const REPORT_SUB_FREE = "Estimation d'entraînement Séjour";
/** La seule phrase de l'écran qui dise ce que vaut l'estimation. Elle est
 *  gardée sous la carte de niveau, là où le palier est annoncé. */
const ESTIMATION_NOTE =
  "Estimation d'entraînement Séjour, non officielle. Elle ne remplace pas le résultat du TCF.";

const PRIORITIES_TITLE = "Vos principales priorités";
const PRIORITIES_TEXT =
  "Le diagnostic ne liste pas vos erreurs : il désigne les compétences qui feront bouger votre niveau.";
/** Repli : le serveur n'a désigné aucune priorité classée. On ne promeut pas des
 *  points relevés en priorités mesurées. */
const PRIORITIES_TITLE_UNRANKED = "Ce qu'il y a à travailler";
const PRIORITIES_TEXT_UNRANKED =
  "Ces points viennent de vos deux productions. Ils ne sont pas encore classés en priorités.";
/** Le repère d'une ligne qui ne porte aucun domaine (repli sans compétence). */
const PRIORITY_RANK_LABEL = "Priorité détectée";
const POINT_LABEL = "Point à travailler";

const STRENGTHS_TITLE = "Vos points forts";
const STRENGTHS_TEXT = "Ce que vos deux productions ont déjà montré de solide.";

const PLAN_READY_TITLE = "Votre plan personnalisé est prêt";
const PLAN_READY_TEXT =
  "Il commence par votre priorité n°1 et se réordonne à chacune de vos nouvelles productions.";

const PLAN_TODAY_LABEL = "Aujourd'hui";
/** La nature d'une ligne de l'aperçu de séance, dite en deux mots. */
const PLAN_STEP_TARGETED = "Exercice ciblé";
const PLAN_STEP_REASSESSMENT = "Vérification en situation";

const UNLOCK_PLAN_CTA = "Débloquer mon plan";
const CTA_PLAN = "Voir mon plan";
/** Mêmes libellés que le Plan : un candidat ne doit pas lire deux formulations
 *  pour la même action. */
const EXERCISE_CTA_LOCKED = "Débloquer cet exercice";
const EXERCISE_CTA_REASSESSMENT = "Vérifier ma progression";
const EXERCISE_CTA_START = "Commencer";

/**
 * Le repère d'une compétence : son domaine, et le numéro de tâche quand elle en
 * a un (l'expression seule). `null` quand la ligne ne vient d'aucune
 * compétence — on n'invente pas de domaine.
 */
function skillMetaLine(section: SkillSection | null, skillCode: string | null): string | null {
  if (!section) return null;
  const label = productionSectionLabel(section);
  const task = skillCode ? skillTaskNumber(skillCode) : null;
  return task ? `${label} · Tâche ${task}` : label;
}

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
  targetLevel,
  hasTcf,
  planHref,
  notice,
}: {
  diagnostic: DiagnosticResponse;
  targetLevel: string | null;
  /** Accès TCF du compte : il ne masque **aucune** mesure du candidat, il ne
   *  décide que de ce qui reste à faire — priorités suivantes, points forts
   *  suivants, entraînements du plan. */
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
  // Aperçu du plan : deux étapes à venir au plus, comme avant. Le compteur d'un
  // compte gratuit, lui, porte sur le total réel — pas sur cet aperçu.
  const nextSteps = measured ? levers.slice(1, 3) : [];

  // ------------------------------------------------------------ freemium
  // 🛑 **Ce qui est masqué, c'est ce qui RESTE À FAIRE — jamais ce que le
  // candidat a établi.** Restent entiers pour tout le monde : le palier global
  // estimé, l'objectif, le rail, les quatre domaines du profil et la première
  // priorité avec son explication. Ce sont **ses** productions et **ses**
  // mesures ; on tease la suite, on ne lui retire pas son résultat.
  //
  // ⚠️ Cette bascule vaut pour le **rapport de diagnostic**, écran de
  // conversion, et **pas** pour `/plan` : la règle « le Plan reste
  // intégralement visible sans abonnement » est intacte chez lui.
  //
  // Les découpes se lisent toutes de la même façon : ce qui est visible, puis
  // **exactement le reste**. Aucun compteur n'est écrit en dur, et une liste
  // plus courte que le seuil ne produit aucun teaser.
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
              meta: skillMetaLine(skill.section, skill.skillCode),
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
          <h1>{REPORT_TITLE}</h1>
          <p className={styles.reportSub}>{hasTcf ? REPORT_SUB_PREMIUM : REPORT_SUB_FREE}</p>
        </header>

        {/* --------------- une seule carte : niveau, objectif, 4 domaines */}
        <DiagnosticLevelCard targetLevel={targetLevel} />

        {/* ----------------------------------------------- les priorités */}
        {levers.length > 0 && (
          <section aria-labelledby="levers-title">
            <ResultBlockHead
              id="levers-title"
              title={measured ? PRIORITIES_TITLE : PRIORITIES_TITLE_UNRANKED}
              text={measured ? PRIORITIES_TEXT : PRIORITIES_TEXT_UNRANKED}
            />
            <ol className={styles.leverList}>
              {visibleLevers.map((lever, index) => (
                <li key={lever.key}>
                  <LeverRow lever={lever} rank={index + 1} measured={measured} />
                </li>
              ))}
            </ol>
            {leverTease.hidden > 0 && (
              <LockedTease
                rows={leverTease.sample.map((lever) => ({
                  key: lever.key,
                  title: lever.title,
                  meta: skillMetaLine(lever.section, lever.skillCode),
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

        {/* ------------------------------------------------- vos points forts */}
        {(visibleSolid.length > 0 || visibleTexts.length > 0) && (
          <section aria-labelledby="strengths-title">
            <ResultBlockHead
              id="strengths-title"
              title={STRENGTHS_TITLE}
              text={STRENGTHS_TEXT}
            />
            <ul className={styles.strengthList}>
              {visibleSolid.map((skill) => (
                <li key={skill.skillId}>
                  <span className={styles.strengthMark} aria-hidden>
                    <Check size={13} strokeWidth={3} />
                  </span>
                  <b>{skill.skillTitle}</b>
                  <span>{skillMetaLine(skill.section, skill.skillCode)}</span>
                </li>
              ))}
              {visibleTexts.map((item) => (
                <li key={item}>
                  <span className={styles.strengthMark} aria-hidden>
                    <Check size={13} strokeWidth={3} />
                  </span>
                  <b>{item}</b>
                </li>
              ))}
            </ul>
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
          </section>
        )}

        {/* ---------------------------------------------------- votre plan */}
        {nextAction && (
          <section aria-labelledby="plan-title">
            <ResultBlockHead id="plan-title" title={PLAN_READY_TITLE} text={PLAN_READY_TEXT} />
            <div className={styles.planShell}>
              {/* Le bandeau « Priorité actuelle » a été retiré le 2026-08-21 :
                  cette même priorité est déjà la première ligne de « Vos
                  principales priorités », une section plus haut. La redire ici
                  n'ajoutait rien et allongeait la carte. Ne pas la réintroduire. */}

              <p className={styles.planTodayLabel}>
                {PLAN_TODAY_LABEL} · {nextAction.estimatedMinutes} min
              </p>

              <ul className={styles.planSteps}>
                <li>
                  <b>{nextAction.title}</b>
                  <span>
                    {nextAction.kind === "REASSESSMENT"
                      ? PLAN_STEP_REASSESSMENT
                      : PLAN_STEP_TARGETED}{" "}
                    · {productionSectionLabel(nextAction.section)} ·{" "}
                    {nextAction.estimatedMinutes} min
                  </span>
                </li>
                {hasTcf &&
                  nextSteps.map((step) => (
                    <li key={step.key}>
                      <b>{step.title}</b>
                      <span>
                        {PLAN_STEP_TARGETED}
                        {skillMetaLine(step.section, step.skillCode)
                          ? ` · ${skillMetaLine(step.section, step.skillCode)}`
                          : ""}
                      </span>
                    </li>
                  ))}
              </ul>

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

              {/* Le verrou est celui du SERVEUR (`locked`), jamais l'accès du
                  compte : un exercice fermé ouvre l'offre au lieu de mener à une
                  page qui refusera. */}
              {nextAction.locked ? (
                <PremiumLink className={styles.planStepCta}>
                  <Lock size={15} aria-hidden /> {EXERCISE_CTA_LOCKED}
                </PremiumLink>
              ) : (
                <Link className={styles.planStepCta} href={recommendedExerciseHref(nextAction)}>
                  {nextAction.kind === "REASSESSMENT"
                    ? EXERCISE_CTA_REASSESSMENT
                    : EXERCISE_CTA_START}
                  <ArrowRight size={15} aria-hidden />
                </Link>
              )}
            </div>
          </section>
        )}

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
                {CTA_PLAN} <ArrowRight size={17} aria-hidden />
              </Link>
            </div>
          </section>
        ) : (
          <section className={styles.unlockCard} aria-labelledby="unlock-title">
            <span className={styles.finalSpark} aria-hidden><Sparkles size={20} /></span>
            {/* Le `<em>` est un habillage : le texte lu reste exactement le
                libellé miroir du mobile (`kDiagnosticUnlockTitle`). */}
            <h2 id="unlock-title">
              Débloquez <em>votre plan complet</em>
            </h2>
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
                {UNLOCK_PLAN_CTA} <ArrowRight size={17} aria-hidden />
              </PremiumLink>
              <Link href={planHref} className={styles.finalGhost}>
                {CTA_PLAN}
              </Link>
            </div>
          </section>
        )}

        {/* La seule phrase qui dise ce que vaut l'estimation : en pied de
            rapport, comme la maquette, et pour tout le monde. */}
        <p className={styles.note}>
          <Info size={15} aria-hidden />
          {ESTIMATION_NOTE}
        </p>
      </div>

      {/* Barre collante mobile : la réserve de pied de page est posée sur
          `.result`, elle ne masque donc aucun contenu. */}
      <div className={styles.stickyCta}>
        <Link href={planHref} className={styles.primaryButton}>
          {CTA_PLAN} <ArrowRight size={17} aria-hidden />
        </Link>
      </div>
    </DiagnosticShell>
  );
}

/**
 * Une ligne de « Vos principales priorités », **repliée par défaut**.
 *
 * Elle porte tout ce que le serveur publie sur une priorité et que le candidat
 * a le droit de lire : son explication (`mainPriorityExplanation` sur le rang 1)
 * et sa preuve — la phrase de sa propre production. `confidence` en est
 * volontairement absente : elle n'est **jamais** montrée au candidat.
 *
 * Repliée, la ligne porte le verdict (rang, libellé, domaine, état) ; le détail
 * vit derrière un clic. Dépliées, une douzaine d'explications de trois lignes se
 * lisaient comme un mur et le candidat n'en lisait aucune — rien n'est retiré,
 * tout est à un clic.
 *
 * `<details>` plutôt qu'un état React : le repli natif est accessible au clavier
 * et survit à un rendu. Miroir de `_FocusRow` côté mobile ; une ligne sans rien
 * à déplier reste **inerte**, sans chevron.
 */
function LeverRow({
  lever,
  rank,
  measured,
}: {
  lever: ResultLever;
  rank: number;
  measured: boolean;
}) {
  const meta = skillMetaLine(lever.section, lever.skillCode)
    ?? (measured ? PRIORITY_RANK_LABEL : POINT_LABEL);
  const head = (
    <>
      <span className={styles.leverRank} data-rank={rank} aria-hidden>
        {rank}
      </span>
      <span className={styles.leverBody}>
        <b>{lever.title}</b>
        <span className={styles.leverMeta}>{meta}</span>
      </span>
      {lever.status && (
        <span
          className={styles.leverStatus}
          data-tone={LEARNING_PLAN_SKILL_STATUS_TONE[lever.status]}
        >
          {LEARNING_PLAN_SKILL_STATUS_LABEL[lever.status]}
        </span>
      )}
    </>
  );

  if (!lever.detail && !lever.evidence) {
    return <div className={styles.leverHead}>{head}</div>;
  }

  return (
    <details className={styles.leverRow}>
      <summary className={styles.leverHead}>
        {head}
        <ChevronDown className={styles.leverChevron} size={16} aria-hidden />
      </summary>
      <div className={styles.leverDetail}>
        {lever.detail && <p>{lever.detail}</p>}
        {lever.evidence && (
          <blockquote className={styles.leverQuote}>
            «&nbsp;{lever.evidence}&nbsp;»
          </blockquote>
        )}
      </div>
    </details>
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

function DiagnosticSkeleton() {
  return (
    <main className={styles.page} aria-busy="true" aria-label="Chargement du diagnostic">
      <div className={styles.skeletonHeader} />
      <div className={styles.skeletonCard} />
    </main>
  );
}
