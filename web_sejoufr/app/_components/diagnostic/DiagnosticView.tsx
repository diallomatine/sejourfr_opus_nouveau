"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {retourOuRepli} from "@/lib/retour";
import {useCallback, useEffect, useRef, useState, type ReactNode} from "react";
import {
  ArrowLeft,
  Check,
  Clock3,
  Headphones,
  Info,
  PenLine,
  RotateCcw,
  Sparkles,
} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {EeWritingForm, clearEeDraft} from "@/app/_components/production/EeWritingForm";
import {EoRecordingForm} from "@/app/_components/production/EoRecordingForm";
import {ApiException, diagnosticApi, productionApi} from "@/lib/api";
import {useSubmissionKey} from "@/lib/idempotency";
import {
  rememberDiagnosticType,
  track,
  trackDiagnostic,
} from "@/lib/analytics";
import {useAuth} from "@/lib/auth-context";
import {
  bindQuickTcfSession,
  ensureDiagnosticRun,
  quickTcfRunForHandoff,
  submitQuickTcfRun,
  trackDiagnosticReportViewed,
} from "@/lib/diagnostic-run";
import {
  DIAGNOSTIC_EDIT_CANCEL,
  DIAGNOSTIC_EDIT_SUBMIT,
  DIAGNOSTIC_EXERCISE_KICKER,
  DIAGNOSTIC_EXERCISE_TITLE,
  DIAGNOSTIC_SUBJECT_TAG,
  DIAGNOSTIC_WRITTEN_EDITOR_TITLE,
  type DiagnosticExerciseContent,
  type DiagnosticExerciseKind,
  diagnosticEditNote,
  diagnosticExerciseAsProductionTask,
  diagnosticExerciseSub,
  diagnosticWordRangeLabel,
  diagnosticWrittenSubmitLabel,
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
  PublicDiagnosticResponse,
} from "@/lib/types";
import {DiagnosticAccountGate} from "./DiagnosticAccountGate";
import {DiagnosticConsigne} from "./DiagnosticConsigne";
import {DiagnosticChoice} from "./DiagnosticChoice";
import {demarrageDirectDemande, diagnosticRapportHref} from "@/lib/preparation";
import {planHref} from "@/lib/module-switch";
import {DiagnosticIntro} from "./DiagnosticIntro";
import {
  DIAGNOSTIC_RAPPORT_INDISPONIBLE,
  DIAGNOSTIC_RAPPORT_LOAD_ERROR,
  DIAGNOSTIC_REPORT_BACK_HREF,
  diagnosticReponseHref,
  diagnosticTransitionHref,
} from "@/lib/diagnostic-rapport";
import {DiagnosticPlanTransition} from "./DiagnosticPlanTransition";
import {DiagnosticReponse} from "./DiagnosticReponse";
import {DiagnosticReport} from "./DiagnosticReport";
import {DiagnosticSteps} from "./DiagnosticSteps";
import {
  DIAGNOSTIC_ANALYSIS_FAILED_TITLE,
  DIAGNOSTIC_ANALYSIS_HOME_CTA,
  DIAGNOSTIC_ANALYSIS_KICKER,
  DIAGNOSTIC_ANALYSIS_LEAD,
  DIAGNOSTIC_ANALYSIS_USUAL,
  DIAGNOSTIC_ANALYSIS_USUAL_MS,
  DIAGNOSTIC_ELAPSED_LABEL,
  DIAGNOSTIC_OUTCOMES_TITLE,
  DIAGNOSTIC_SEND_RETRY_CTA,
  type DiagnosticSendingStage,
  type DiagnosticWaitStep,
  diagnosticAnalysisFailedText,
  diagnosticAnalysisRetryExhausted,
  diagnosticAnalysisSlow,
  diagnosticAnalysisSteps,
  diagnosticAnalysisTitle,
  diagnosticRetryRateLimited,
  diagnosticSendFailedText,
  diagnosticSendFailedTitle,
  diagnosticSendingSteps,
  diagnosticSendingText,
  diagnosticSendingTitle,
  diagnosticSendUnconfirmed,
} from "./analysis-labels";
import {TCF_DIAGNOSTIC_PANEL} from "../auth/auth-panels";
import styles from "./diagnostic.module.css";

const POLL_MS = 2_500;

/** Au-delà, on cesse d'afficher un squelette : on rend la main avec une erreur. */
const LOADING_WATCHDOG_MS = 20_000;

function errorMessage(error: unknown, fallback: string): string {
  return error instanceof ApiException ? error.message : fallback;
}

const ANALYSIS_RETRY_FAILED =
  "La relance n'a pas pu être lancée. Vérifiez votre connexion, puis réessayez.";

/**
 * L'échec de la relance qu'on VIENT de tenter — à ne jamais confondre avec
 * `diagnostic.errorMessage`, qui dit pourquoi l'analyse elle-même a échoué.
 */
function retryErrorMessage(cause: unknown, hasOral: boolean): string {
  // La route de relance est rate-limitée serveur : son message brut
  // (« Reessayez dans 573s. ») n'est pas écrit pour un candidat.
  if (cause instanceof ApiException && cause.status === 429) {
    return diagnosticRetryRateLimited(hasOral);
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
  /**
   * 🛑 **On ne choisit plus une PROFONDEUR de diagnostic ici.** L'écran d'entrée
   * fait choisir un EXAMEN (TCF ou civique) ; ce composant ne porte que le
   * tunnel TCF, et ce tunnel est le diagnostic **rapide** — le seul depuis le
   * retrait du diagnostic complet (2026-09-26). Les autres épreuves se mesurent
   * par l'examen blanc que propose le Plan.
   *
   * La mesure enregistre donc `RAPID` au démarrage, ce qui est simplement la
   * vérité : c'est le diagnostic rapide qui commence.
   */
  const commencerTcf = useCallback(() => {
    rememberDiagnosticType("RAPID");
  }, []);
  if (status === "loading") return <DiagnosticSkeleton />;
  // `DualChromeShell` porte les deux chromes de la route : sidebar pour un
  // compte, fond applicatif nu pour un visiteur (qui garde le header et le
  // pied de page publics du layout racine).
  return (
    <DualChromeShell>
      {status === "authenticated" ? (
        <ConnectedDiagnostic onStartTcf={commencerTcf} />
      ) : (
        <GuestDiagnostic onStartTcf={commencerTcf} />
      )}
    </DualChromeShell>
  );
}

// ============================================================================
// RELECTURE d'un diagnostic clos, par son identifiant (`/diagnostic/rapport/…`)
// ============================================================================

/**
 * **La relecture d'un diagnostic TCF CLOS**, désigné par son identifiant —
 * la destination de « Mon diagnostic » du Plan (`diagnosticRapportHref`).
 *
 * 🛑 **Jamais `/diagnostic` pour relire.** Cette route-là lit la session
 * COURANTE (`GET /api/diagnostics/current`, la version de diagnostic servie
 * aujourd'hui) : un compte qui a clos un diagnostic d'un autre code, puis
 * commencé le rapide sans le finir, y voyait l'invitation à REPRENDRE au lieu
 * de son rapport. Ici, la session est celle que le serveur désigne
 * (`estimationSessionId`), lue par `GET /api/diagnostics/{sessionId}`.
 *
 * 🛑 **Lecture seule** : aucun démarrage, aucune soumission, aucune relance.
 * Une session sans rapport ne propose jamais de faire le diagnostic — elle le
 * dit, et rend la main au Plan.
 *
 * Le rendu est le MÊME `DiagnosticReport` que celui de `/diagnostic` : aucun
 * second écran de rapport. Miroir mobile : `DiagnosticRapportScreen`.
 *
 * `vue` choisit l'écran rendu sur la même session : le rapport, sa transition
 * « Votre plan commence ici » (`/plan`) ou « Revoir ma réponse » (`/reponse`).
 * Le chargement, la porte de connexion et les états d'erreur sont communs.
 */
export function DiagnosticRapportView({
  sessionId,
  vue = "rapport",
}: {
  sessionId: string;
  vue?: "rapport" | "plan" | "reponse";
}) {
  const {status, user} = useAuth();
  const [diagnostic, setDiagnostic] = useState<DiagnosticResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setError(null);
    setLoading(true);
    try {
      setDiagnostic(await diagnosticApi.get(sessionId));
    } catch (cause) {
      setError(errorMessage(cause, DIAGNOSTIC_RAPPORT_LOAD_ERROR));
    } finally {
      setLoading(false);
    }
  }, [sessionId]);

  useEffect(() => {
    if (status !== "authenticated") return;
    let annule = false;
    diagnosticApi.get(sessionId).then(
      (fresh) => {
        if (!annule) setDiagnostic(fresh);
      },
      (cause: unknown) => {
        if (!annule) setError(errorMessage(cause, DIAGNOSTIC_RAPPORT_LOAD_ERROR));
      },
    ).finally(() => {
      if (!annule) setLoading(false);
    });
    return () => {
      annule = true;
    };
  }, [status, sessionId]);

  const rapport =
    diagnostic?.result != null
    && (diagnostic.status === "COMPLETED" || diagnostic.nextStep === "RESULT");

  useEffect(() => {
    if (vue === "rapport" && rapport && diagnostic?.sessionId) {
      trackDiagnosticReportViewed("QUICK_TCF", diagnostic.sessionId);
    }
  }, [vue, rapport, diagnostic?.sessionId]);

  if (status === "loading") return <DiagnosticSkeleton />;

  if (status !== "authenticated" || !user) {
    const retour = vue === "plan"
      ? diagnosticTransitionHref(sessionId)
      : vue === "reponse"
        ? diagnosticReponseHref(sessionId)
        : diagnosticRapportHref(sessionId);
    return (
      <DualChromeShell>
        <DiagnosticShell guest>
          <StateCard
            icon={<Info size={26} />}
            title="Connectez-vous pour relire votre diagnostic"
            text="Votre rapport est rattaché à votre compte."
          >
            <Link
              className={styles.primaryButton}
              href={`/connexion?next=${encodeURIComponent(retour)}`}
            >
              Se connecter
            </Link>
          </StateCard>
        </DiagnosticShell>
      </DualChromeShell>
    );
  }

  if (loading && !diagnostic) {
    return (
      <DualChromeShell>
        <DiagnosticSkeleton />
      </DualChromeShell>
    );
  }

  if (!diagnostic || !rapport) {
    return (
      <DualChromeShell>
        <DiagnosticShell>
          <StateCard
            icon={<RotateCcw size={26} />}
            title={diagnostic ? "Rapport indisponible" : "Le diagnostic n'a pas pu être chargé"}
            text={diagnostic ? DIAGNOSTIC_RAPPORT_INDISPONIBLE : error ?? "Réessayez dans un instant."}
            role="alert"
          >
            {!diagnostic && (
              <button className={styles.primaryButton} type="button" onClick={() => void load()}>
                Réessayer
              </button>
            )}
            <Link className={styles.secondaryButton} href={planHref("TCF")}>Retour au plan</Link>
          </StateCard>
        </DiagnosticShell>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      {vue === "plan" ? (
        <DiagnosticPlanTransition sessionId={sessionId} result={diagnostic.result} />
      ) : vue === "reponse" ? (
        <DiagnosticReponse sessionId={sessionId} written={diagnostic.written} />
      ) : (
        <DiagnosticReport diagnostic={diagnostic} backTo={planHref("TCF")} />
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
  // 🛑 `isLocalDiagnosticComplete` connaît la FORME du parcours (L3) : sur le
  // diagnostic rapide, l'écrit seul suffit et l'étape orale n'existe pas. Ne
  // pas remplacer par un test sur l'audio — le candidat resterait bloqué sur
  // un enregistrement qu'on ne lui demande pas.
  if (isLocalDiagnosticComplete(local)) return "account";
  if (hasWritten) return "oral";
  return started ? "written" : "presentation";
}

/**
 * Marqueur de l'entrée d'historique posée quand l'écrit est rouvert depuis
 * l'écran de compte : le « précédent » du navigateur y ramène au compte au
 * lieu de quitter `/diagnostic`, et le « suivant » y retourne.
 */
const EDIT_HISTORY_KEY = "sfDiagnosticEditWritten";

function isEditHistoryState(state: unknown): boolean {
  return Boolean((state as Record<string, unknown> | null)?.[EDIT_HISTORY_KEY]);
}

function GuestDiagnostic({onStartTcf}: {onStartTcf: () => void}) {
  const [subjects, setSubjects] = useState<PublicDiagnosticResponse | null>(null);
  const [local, setLocal] = useState<LocalDiagnosticProductions | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [started, setStarted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Faux quand le navigateur a refusé l'écriture disque : la production vit
  // alors seulement dans l'onglet, et on le dit au lieu de le taire.
  const [storedOnDevice, setStoredOnDevice] = useState(true);
  // 🛑 Un OVERRIDE d'affichage, jamais une étape : l'étape reste dérivée de la
  // production locale (`guestStep`). Rouvrir l'écrit n'efface rien — la
  // production enregistrée ne change qu'au clic « Enregistrer mes
  // modifications », et « Revenir sans modifier » la laisse intacte.
  const [editingWritten, setEditingWritten] = useState(false);

  useEffect(() => {
    const onPopState = (event: PopStateEvent) => {
      setEditingWritten(isEditHistoryState(event.state));
    };
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, []);

  function openWrittenEditor() {
    try {
      window.history.pushState({[EDIT_HISTORY_KEY]: true}, "", window.location.href);
    } catch {
      // Historique indisponible : le retour passe alors par le seul bouton.
    }
    setEditingWritten(true);
    window.scrollTo({top: 0});
  }

  function closeWrittenEditor() {
    setEditingWritten(false);
    // L'entrée posée à l'ouverture est dépilée : sans ça, le « précédent »
    // suivant tomberait sur une entrée morte de la même adresse.
    if (isEditHistoryState(window.history.state)) window.history.back();
    window.scrollTo({top: 0});
  }

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
    track("LANDING_VIEWED", {landingPath: "/diagnostic"}, {once: true});
  }, []);

  const step = guestStep(local, started);

  // Un exercice affiché est un exercice commencé : c'est le seul instant que le
  // navigateur connaisse (rien n'est encore envoyé au serveur à ce stade).
  useEffect(() => {
    if (step === "written") trackDiagnostic("DIAGNOSTIC_EE_STARTED", {once: true});
    if (step === "oral") trackDiagnostic("DIAGNOSTIC_EO_STARTED", {once: true});
    // L'écran qui demande un compte, les deux productions déjà faites : LA
    // mesure de conversion du parcours invité (cf. CLAUDE.md racine). Distinct
    // de `DIAGNOSTIC_EO_COMPLETED` — entre les deux se joue la décision même
    // de créer un compte.
    if (step === "account") trackDiagnostic("DIAGNOSTIC_ACCOUNT_REQUIRED", {once: true});
    // « Sujet vu » (chantier Suivi) : la trace du passage naît à l'affichage
    // de la première question. Idempotente, sans appel si elle existe déjà.
    if (step === "written" || step === "oral") void ensureDiagnosticRun("QUICK_TCF");
  }, [step]);

  async function keepWritten(text: string, options: {editing?: boolean} = {}): Promise<boolean> {
    if (!subjects || saving) return false;
    setSaving(true);
    setError(null);
    const ok = await saveLocalWritten(
      subjects.diagnosticCode,
      subjects.diagnosticVersion,
      subjects.written.productionTaskId,
      text,
      subjects.oral !== null,
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
      oralRequired: subjects.oral !== null,
      savedAt: Date.now(),
    }));
    // Une modification n'est pas un second écrit : aucune mesure de plus.
    if (!options.editing) trackDiagnostic("DIAGNOSTIC_EE_COMPLETED", {once: true});
    // Sans oral, ce bouton EST « analyser mes réponses » : le « soumis » du
    // TCF rapide se pose ici, côté client (D23). Idempotent : une
    // modification ne le repose pas.
    if (subjects.oral === null) void submitQuickTcfRun();
    setSaving(false);
    return true;
  }

  async function saveEditedWritten(text: string) {
    if (await keepWritten(text, {editing: true})) closeWrittenEditor();
  }

  async function keepOral(audio: Blob, durationSec: number) {
    // Sans sujet oral il n'y a rien à enregistrer : l'écran n'est pas
    // atteignable, et ce garde le dit au type comme au lecteur.
    if (!subjects?.oral || saving) return;
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
      oralTaskId: subjects.oral!.productionTaskId,
      oralAudio: audio,
      oralDurationSec: durationSec,
      oralRequired: true,
      savedAt: Date.now(),
    }));
    trackDiagnostic("DIAGNOSTIC_EO_COMPLETED", {once: true});
    void submitQuickTcfRun();
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

  if (step === "account" && editingWritten) {
    // L'écrit rouvert depuis l'écran de compte, PRÉ-REMPLI avec la production
    // enregistrée (prioritaire sur le brouillon, qui peut retarder de quelques
    // frappes). Avec un oral, seul l'écrit se modifie : l'enregistrement est
    // gardé tel quel et l'on revient directement au compte.
    return (
      <DiagnosticShell guest compact back={{label: DIAGNOSTIC_EDIT_CANCEL, onClick: closeWrittenEditor}}>
        <DiagnosticSteps current="written" guest oral={subjects.oral !== null} />
        <ExerciseHeader
          kind="written"
          hasOral={subjects.oral !== null}
          note={diagnosticEditNote(subjects.oral !== null)}
        />
        <WrittenExercise
          key="edit-written"
          exercise={subjects.written}
          initialText={local?.writtenText ?? ""}
          submitting={saving}
          error={error}
          submitLabel={DIAGNOSTIC_EDIT_SUBMIT}
          onSubmit={(text) => void saveEditedWritten(text)}
        />
      </DiagnosticShell>
    );
  }

  if (step === "account") {
    // Le rendu de `/inscription` (AuthShell), pas le shell du diagnostic : le
    // fil des étapes passe dans l'en-tête de l'écran de compte.
    return (
      <DiagnosticAccountGate
        writtenWords={countEeWords(local?.writtenText ?? "")}
        oralDurationSec={local?.oralDurationSec ?? null}
        hasOral={subjects.oral !== null}
        storedOnDevice={storedOnDevice}
        onEditWritten={openWrittenEditor}
      />
    );
  }

  if (step === "oral" && subjects.oral) {
    const oral = subjects.oral;
    return (
      <DiagnosticShell guest compact>
        <DiagnosticSteps current="oral" guest />
        <ExerciseHeader
          kind="oral"
          hasOral
          note={
            storedOnDevice
              ? "Votre écrit est conservé sur cet appareil."
              : "Votre écrit est conservé dans cet onglet."
          }
        />
        <EoRecordingForm
          task={diagnosticExerciseAsProductionTask(oral)}
          submitting={saving}
          error={error}
          submitLabel="Terminer et analyser"
          promptSlot={<ExercisePrompt exercise={oral} kind="oral" />}
          maxDurationSec={oral.durationMaxSeconds}
          onSubmit={(audio, durationSec) => void keepOral(audio, durationSec)}
        />
      </DiagnosticShell>
    );
  }

  if (step === "written") {
    // L'écran précédent de l'écrit est le choix d'examen, sur la même URL.
    return (
      <DiagnosticShell guest compact back={{label: "Retour", onClick: () => setStarted(false)}}>
        <DiagnosticSteps current="written" guest oral={subjects.oral !== null} />
        <ExerciseHeader kind="written" hasOral={subjects.oral !== null} />
        <WrittenExercise
          exercise={subjects.written}
          submitting={saving}
          error={error}
          submitLabel={diagnosticWrittenSubmitLabel({guest: true, hasOral: subjects.oral !== null})}
          onSubmit={(text) => void keepWritten(text)}
        />
      </DiagnosticShell>
    );
  }

  // Le choix d'examen porte sa propre page (bouton « Retour » compris) : la
  // barre de `DiagnosticShell` dit « Vos réponses restent sur cet appareil »,
  // ce qui n'a de sens qu'une fois le TCF commencé.
  return (
    <DiagnosticChoice
      error={error}
      written={subjects.written}
      oral={subjects.oral}
      onStartTcf={() => {
        onStartTcf();
        setStarted(true);
        trackDiagnostic("DIAGNOSTIC_STARTED", {once: true});
      }}
    />
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
  | {kind: "running"; stage: DiagnosticSendingStage; hasOral: boolean}
  | {kind: "error"; message: string}
  /** Le compte porte déjà un diagnostic terminé : rien n'est envoyé. */
  | {kind: "already-completed"}
  /** Les sujets ont changé de version depuis la production locale. */
  | {kind: "version-mismatch"}
  /** Une des deux tâches avait déjà une soumission : on n'a envoyé que l'autre. */
  | {kind: "partially-reused"};

function ConnectedDiagnostic({onStartTcf}: {onStartTcf: () => void}) {
  const {user} = useAuth();
  const [diagnostic, setDiagnostic] = useState<DiagnosticResponse | null>(null);
  const [loading, setLoading] = useState(true);
  // Une cle par production de diagnostic. Le renvoi apres coupure — le cas le
  // plus frequent de ce parcours, ou le compte vient d'etre cree — retrouve la
  // soumission au lieu d'echouer sur « deja rendue ».
  const submissionKey = useSubmissionKey();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [handoff, setHandoff] = useState<Handoff>({kind: "idle"});
  const [pendingLocal, setPendingLocal] = useState<LocalDiagnosticProductions | null>(null);

  const loadCurrent = useCallback(async () => {
    setError(null);
    setLoading(true);
    try {
      setDiagnostic(await diagnosticApi.current());
    } catch (cause) {
      setError(errorMessage(cause, DIAGNOSTIC_RAPPORT_LOAD_ERROR));
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
      const hasOral = local.oralRequired || local.oralAudio != null;
      setHandoff({kind: "running", stage: "session", hasOral});
      try {
        // 🛑 Le sujet REELLEMENT rédigé est renvoyé au serveur : depuis L3 le
        // sujet écrit peut être tiré, et sans cet identifiant la session
        // s'ouvrirait sur un autre énoncé que celui traité par le candidat.
        // Vérifié serveur — un identifiant inconnu retombe sur un tirage.
        // La run du passage d'invité : le serveur la lie à cette session si
        // elle a été claimée par ce compte à l'auth, et l'ignore sinon (D24).
        const runId = await quickTcfRunForHandoff();
        let session = await diagnosticApi.start(local.writtenTaskId ?? undefined, runId);
        setDiagnostic(session);
        if (runId && session.sessionId) void bindQuickTcfSession(runId, session.sessionId);

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
            setHandoff({kind: "running", stage: "written", hasOral});
            await productionApi.submitText({
              productionTaskId: session.written.productionTaskId,
              attemptId: session.written.attemptId,
              texte: local.writtenText,
              clientSubmissionId: submissionKey(
                `${session.written.attemptId}:${session.written.productionTaskId}`,
              ),
            });
            session = await refreshAfterSubmission(sessionId, "WRITTEN");
          } else if (session.written.submissionId != null) {
            reusedExisting = true;
          }
        }

        if (session.oral) {
          if (session.oral.submissionId == null && local.oralAudio) {
            setHandoff({kind: "running", stage: "oral", hasOral});
            await productionApi.submitAudio(
              session.oral.productionTaskId,
              session.oral.attemptId,
              local.oralAudio,
              undefined,
              submissionKey(`${session.oral.attemptId}:${session.oral.productionTaskId}`),
            );
            session = await refreshAfterSubmission(sessionId, "ORAL");
          } else if (session.oral.submissionId != null) {
            reusedExisting = true;
          }
        }

        setHandoff({kind: "running", stage: "confirming", hasOral});
        // 🛑 On attend un accusé pour CHAQUE production que ce diagnostic
        // comporte — une seule sur le diagnostic rapide (L3). Exiger un oral
        // que le serveur n'a pas ouvert ferait échouer un parcours réussi et
        // laisserait le candidat devant un message d'erreur mensonger.
        const allReceived =
          session.written?.submissionId != null &&
          (session.oral == null || session.oral.submissionId != null);
        if (!allReceived) {
          setHandoff({
            kind: "error",
            message: diagnosticSendUnconfirmed(session.oral != null),
          });
          return;
        }

        // Accusé de réception de TOUTES les productions attendues : c'est
        // seulement ici qu'on a le droit d'effacer ce qui est gardé sur
        // l'appareil.
        await clearLocalDiagnostic(local.diagnosticCode, local.diagnosticVersion);
        if (local.writtenTaskId) clearEeDraft(local.writtenTaskId);
        setPendingLocal(null);
        setHandoff(reusedExisting ? {kind: "partially-reused"} : {kind: "idle"});
      } catch (cause) {
        setHandoff({
          kind: "error",
          message: errorMessage(cause, "L’envoi n’a pas abouti."),
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
        setError(errorMessage(cause, DIAGNOSTIC_RAPPORT_LOAD_ERROR));
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
    track("LANDING_VIEWED", {landingPath: "/diagnostic"}, {once: true});
  }, [user]);

  useEffect(() => {
    if (!diagnostic) return;
    if (diagnostic.nextStep === "WRITTEN" && diagnostic.written) {
      trackDiagnostic("DIAGNOSTIC_EE_STARTED", {once: true});
    }
    if (diagnostic.nextStep === "ORAL" && diagnostic.oral) {
      trackDiagnostic("DIAGNOSTIC_EO_STARTED", {once: true});
    }
    // 🛑 Pas d'événement « diagnostic terminé » : il se lit sur
    // `diagnostic_sessions.status`, on ne crée pas une seconde vérité. Le
    // rapport, lui, est compté quand il s'affiche AVEC ses données — et porte
    // la run de CETTE session si l'appareil la connaît (étape 4 du tunnel).
    const sessionId = diagnostic.sessionId;
    if (
      sessionId &&
      diagnostic.result &&
      (diagnostic.status === "COMPLETED" || diagnostic.nextStep === "RESULT")
    ) {
      trackDiagnosticReportViewed("QUICK_TCF", sessionId);
    }
  }, [diagnostic]);

  // « Sujet vu » d'un parcours connecté : la question affichée, hors reprise
  // des productions d'invité (qui n'affiche aucune question).
  useEffect(() => {
    if (!diagnostic?.sessionId || handoff.kind !== "idle") return;
    const shown =
      diagnostic.nextStep === "WRITTEN"
        ? diagnostic.written
        : diagnostic.nextStep === "ORAL"
          ? diagnostic.oral
          : null;
    if (shown && shown.submissionId == null) {
      void ensureDiagnosticRun("QUICK_TCF", diagnostic.sessionId);
    }
  }, [diagnostic, handoff.kind]);

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

  /* 🛑 **Sauter la présentation quand le geste l'a déjà remplacée**
     (2026-09-12). « Faire mon diagnostic », depuis le Plan ou l'Accueil, doit
     LANCER le diagnostic : le bouton porte déjà la décision, une page qui
     redemande de la prendre est une étape de trop. Le transport est
     `?demarrer=1`, posé par les seules portes qui nomment le geste.

     🛑 **Une fois par montage** (`useRef`) : `start()` est aussi appelé par le
     bouton, et le composant se rend à chaque tic d'état. Sans le garde, la
     présentation relancerait l'appel en boucle. Aucun risque de double
     session par ailleurs : `POST /api/diagnostics` est idempotent. */
  /* Lu sur `window` et non par `useSearchParams` : ce dernier impose une
     frontière de Suspense à toute la page, pour un simple drapeau que seul cet
     effet — donc le client — a besoin de connaître. */
  const demarrageFait = useRef(false);
  useEffect(() => {
    if (demarrageFait.current || typeof window === "undefined") return;
    const demarrageDemande = demarrageDirectDemande(
      new URLSearchParams(window.location.search),
    );
    if (!demarrageDemande) return;
    if (diagnostic === null) return;
    if (diagnostic.status !== "NOT_STARTED" && diagnostic.nextStep !== "PRESENTATION") return;
    demarrageFait.current = true;
    void start();
    // `start` est stable pour ce montage ; le garde borne l'effet à un appel.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [diagnostic]);

  async function start() {
    if (submitting) return;
    onStartTcf();
    setSubmitting(true);
    setError(null);
    try {
      setDiagnostic(await diagnosticApi.start());
      trackDiagnostic("DIAGNOSTIC_STARTED", {once: true});
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
        clientSubmissionId: submissionKey(
          `${exercise.attemptId}:${exercise.productionTaskId}`,
        ),
      });
      trackDiagnostic("DIAGNOSTIC_EE_COMPLETED", {once: true});
      if (diagnostic.oral == null) void submitQuickTcfRun(diagnostic.sessionId);
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
      await productionApi.submitAudio(
        exercise.productionTaskId,
        exercise.attemptId,
        audio,
        undefined,
        submissionKey(`${exercise.attemptId}:${exercise.productionTaskId}`),
      );
      trackDiagnostic("DIAGNOSTIC_EO_COMPLETED", {once: true});
      void submitQuickTcfRun(diagnostic.sessionId);
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
      setError(retryErrorMessage(cause, diagnostic.oral != null));
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
        <WaitCard
          kicker={null}
          title={<>{diagnosticSendingTitle(handoff.hasOral)}</>}
          lead={diagnosticSendingText(handoff.hasOral)}
          steps={diagnosticSendingSteps(handoff.hasOral, handoff.stage)}
        />
      </DiagnosticShell>
    );
  }

  if (handoff.kind === "error") {
    const hasOral = pendingLocal != null && (pendingLocal.oralRequired || pendingLocal.oralAudio != null);
    return (
      <DiagnosticShell>
        <StateCard
          icon={<RotateCcw size={26} />}
          title={diagnosticSendFailedTitle(hasOral)}
          text={`${handoff.message} ${diagnosticSendFailedText(hasOral)}`}
          role="alert"
        >
          <button
            className={styles.primaryButton}
            type="button"
            onClick={() => {
              if (pendingLocal) void runHandoff(pendingLocal);
            }}
          >
            {DIAGNOSTIC_SEND_RETRY_CTA}
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
          onStart={() => void start()}
        />
      </DiagnosticShell>
    );
  }

  if (diagnostic.status === "FAILED") {
    return (
      <DiagnosticShell>
        <StateCard
          icon={<RotateCcw size={26} />}
          title={DIAGNOSTIC_ANALYSIS_FAILED_TITLE}
          // La carte dit d'abord, en langage clair, ce que le candidat doit
          // savoir. Le message brut du serveur (« Sortie diagnostic invalide
          // après réparation : EO2-C3 … ») n'est pas écrit pour lui : il passe
          // en second plan, sans jamais disparaître — le support s'en sert.
          text={diagnosticAnalysisFailedText(diagnostic.oral != null)}
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
                <p className={styles.stateNote}>
                  {diagnosticAnalysisRetryExhausted(diagnostic.oral != null)}
                </p>
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
    // L'analyse est terminée mais sa synthèse n'est pas encore là : on ne
    // prétend pas avoir un rapport, et rien n'est perdu.
    if (diagnostic.status === "COMPLETED" && !diagnostic.result) {
      return (
        <DiagnosticShell>
          {notice}
          <StateCard
            icon={<Sparkles size={26} />}
            title="Votre résultat se prépare"
            text="L'analyse est terminée, mais sa synthèse n'est pas encore disponible."
            busy
          />
        </DiagnosticShell>
      );
    }
    // 🛑 **Hors du `DiagnosticShell`** : le rapport porte son propre en-tête de
    // retour (le `Top` du kit). Le garder dans la coque aurait affiché deux
    // sorties l'une au-dessus de l'autre.
    return (
      <DiagnosticReport
        diagnostic={diagnostic}
        notice={notice}
        backTo={DIAGNOSTIC_REPORT_BACK_HREF}
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
        {/* Pas de fil de parcours ici : la carte porte ses propres étapes
            (reçu → analyse → rapport), un second fil les répéterait. */}
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
        <DiagnosticSteps current="written" guest={false} oral={diagnostic.oral != null} />
        <ExerciseHeader kind="written" hasOral={diagnostic.oral != null} />
        <WrittenExercise
          exercise={exercise}
          submitting={submitting}
          error={error}
          submitLabel={diagnosticWrittenSubmitLabel({guest: false, hasOral: diagnostic.oral != null})}
          onSubmit={(text) => void submitWritten(exercise, text)}
        />
      </DiagnosticShell>
    );
  }

  if (diagnostic.nextStep === "ORAL" && diagnostic.oral) {
    const exercise = diagnostic.oral;
    return (
      <DiagnosticShell compact>
        <DiagnosticSteps current="oral" guest={false} />
        <ExerciseHeader kind="oral" hasOral />
        <EoRecordingForm
          task={diagnosticExerciseAsProductionTask(exercise)}
          submitting={submitting}
          error={error}
          submitLabel="Analyser mes deux réponses"
          promptSlot={<ExercisePrompt exercise={exercise} kind="oral" />}
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
  back,
}: {
  children: ReactNode;
  compact?: boolean;
  guest?: boolean;
  /** Remplace le retour de page par un retour dans le parcours (l'écrit
   *  rouvert depuis l'écran de compte revient au compte, il ne sort pas). */
  back?: {label: string; onClick: () => void};
}) {
  const router = useRouter();
  // ≤ 900 px (shell connecté) : la flèche de la barre du haut remplace le lien.
  const backInBar = useAppBarBack(guest ? null : { fallbackHref: "/dashboard" });
  return (
    <main className={`${styles.page} ${compact ? styles.pageCompact : ""}`}>
      <nav className={styles.backNav} aria-label="Sortir du diagnostic">
        {back ? (
          <button type="button" onClick={back.onClick}>
            <ArrowLeft size={16} aria-hidden /> {back.label}
          </button>
        ) : (
          <button
            type="button"
            className={backInBar ? "in-bar-back" : undefined}
            onClick={() => retourOuRepli(router, guest ? "/" : "/dashboard")}
          >
            <ArrowLeft size={16} aria-hidden /> Retour
          </button>
        )}
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

/**
 * En-tête d'un exercice : sur-titre mono, titre Fraunces à `<em>` rouge, puis
 * le rang de l'exercice **lu sur la forme servie** (`hasOral`) et la mention
 * « aucune note sur 20 ». Miroir : `DiagnosticExerciseHeader`
 * (`diagnostic_common.dart`).
 */
function ExerciseHeader({
  kind,
  hasOral,
  note,
}: {
  kind: DiagnosticExerciseKind;
  hasOral: boolean;
  note?: string;
}) {
  const title = DIAGNOSTIC_EXERCISE_TITLE[kind];
  return (
    <header className={styles.exerciseHeader}>
      <p className={styles.eyebrow}>{DIAGNOSTIC_EXERCISE_KICKER[kind]}</p>
      <h1 className={styles.exerciseTitle}>
        {title.lead} <em>{title.em}</em>
        {title.tail}
      </h1>
      <p className={styles.exerciseSub}>{diagnosticExerciseSub(kind, hasOral)}</p>
      {note && <p className={styles.exerciseNote}>{note}</p>}
    </header>
  );
}

/**
 * L'écrit du diagnostic : carte du sujet, puis la zone de saisie en carte.
 * 🛑 **La fourchette de mots s'affiche une seule fois**, en tête de la zone de
 * saisie, à côté du compteur qui la mesure — lue sur les bornes servies
 * (`wordsMin` / `wordsMax`), les mêmes que celles que le serveur applique. Ni
 * la carte du sujet ni la consigne ne la répètent. Le champ grandit avec le
 * texte (`EeWritingForm`) ; `initialText` rouvre une production enregistrée.
 */
function WrittenExercise({
  exercise,
  initialText,
  submitting,
  error,
  submitLabel,
  onSubmit,
}: {
  exercise: DiagnosticExerciseContent;
  initialText?: string;
  submitting: boolean;
  error: string | null;
  submitLabel: string;
  onSubmit: (text: string) => void;
}) {
  return (
    <div className={styles.writing}>
      <EeWritingForm
        task={diagnosticExerciseAsProductionTask(exercise)}
        initialText={initialText}
        submitting={submitting}
        error={error}
        submitLabel={submitLabel}
        promptSlot={<ExercisePrompt exercise={exercise} kind="written" />}
        answerCard={{
          title: DIAGNOSTIC_WRITTEN_EDITOR_TITLE,
          icon: <PenLine size={16} strokeWidth={2.2} />,
          range: diagnosticWordRangeLabel(exercise),
        }}
        onSubmit={onSubmit}
      />
    </div>
  );
}

function ExercisePrompt({
  exercise,
  kind,
}: {
  exercise: DiagnosticExerciseContent;
  kind: DiagnosticExerciseKind;
}) {
  return (
    <section className={styles.prompt} aria-labelledby={`${kind}-prompt-title`}>
      <p className={styles.promptTag}>{DIAGNOSTIC_SUBJECT_TAG}</p>
      <h2 id={`${kind}-prompt-title`} className={styles.promptTitle}>{exercise.title}</h2>
      <DiagnosticConsigne text={exercise.instruction} />
      {kind === "oral" && exercise.durationMaxSeconds != null && (
        <div className={styles.constraints}>
          <span><Clock3 size={14} aria-hidden /> Jusqu&apos;à {Math.ceil(exercise.durationMaxSeconds / 60)} min</span>
        </div>
      )}
      {kind === "oral" && exercise.instructionAudioUrl && (
        <div className={styles.audioInstruction}>
          <span><Headphones size={18} aria-hidden /> Écouter la consigne</span>
          <audio controls preload="metadata" src={exercise.instructionAudioUrl}>
            Votre navigateur ne peut pas lire cette consigne audio.
          </audio>
        </div>
      )}
      {exercise.helperText && (
        <p className={styles.helper}>
          <Info size={14} aria-hidden /> {exercise.helperText}
        </p>
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

function formatElapsed(elapsedMs: number): string {
  const totalSeconds = Math.max(0, Math.floor(elapsedMs / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

/** Temps écoulé depuis l'ENTRÉE dans l'écran d'attente, pas depuis le montage
 *  de la page : c'est le composant qui l'appelle qui le porte. */
function useElapsedMs(): number {
  const [elapsedMs, setElapsedMs] = useState(0);
  useEffect(() => {
    const startedAt = Date.now();
    const timer = setInterval(() => setElapsedMs(Date.now() - startedAt), 1_000);
    return () => clearInterval(timer);
  }, []);
  return elapsedMs;
}

/**
 * Carte d'attente partagée par l'envoi des productions et par l'analyse :
 * kicker, titre, une phrase, les étapes RÉELLES, le temps écoulé en discret.
 * Miroir de `DiagnosticWaitCard` (`widgets/diagnostic_wait.dart`).
 */
function WaitCard({
  kicker,
  title,
  lead,
  steps,
  children,
}: {
  kicker: string | null;
  title: ReactNode;
  lead: string;
  steps: DiagnosticWaitStep[];
  /** Rendu sous le temps écoulé : réassurance, panneau, actions. */
  children?: (elapsedMs: number) => ReactNode;
}) {
  const elapsedMs = useElapsedMs();
  return (
    <section className={styles.waitCard} aria-busy="true">
      {kicker && <p className={styles.waitKicker}>{kicker}</p>}
      <h1 className={styles.waitTitle}>{title}</h1>
      <p className={styles.waitLead}>{lead}</p>

      <ol className={styles.waitSteps} role="status">
        {steps.map((step) => (
          <li key={step.key} data-state={step.state}>
            <span aria-hidden>
              {step.state === "done" && <Check size={12} strokeWidth={3.2} />}
            </span>
            {step.label}
          </li>
        ))}
      </ol>

      <p className={styles.waitTimer}>
        {DIAGNOSTIC_ELAPSED_LABEL} ·{" "}
        {/* Pas de région live sur le chiffre : un lecteur d'écran ne doit pas
            énoncer une nouvelle valeur chaque seconde. */}
        <b aria-live="off">{formatElapsed(elapsedMs)}</b>
      </p>

      {children?.(elapsedMs)}
    </section>
  );
}

/**
 * Attente de l'analyse IA — le seul écran où le candidat n'a plus rien à faire
 * et où le rapport n'est pas encore là.
 *
 * 🛑 **La forme est lue sur la session servie** (2026-09-26) : une ligne par
 * production que la session comporte (`diagnostic.written` / `.oral`), jamais
 * une « réponse orale en attente » sur le diagnostic rapide qui n'en a pas.
 * Pendant l'attente, on montre ce que le rapport contiendra (les items du
 * panneau de l'écran de compte, `TCF_DIAGNOSTIC_PANEL`) : une information vraie
 * plutôt qu'un rond qui tourne.
 */
function AnalysisWaiting({
  diagnostic,
  transientMessage,
}: {
  diagnostic: DiagnosticResponse;
  transientMessage: string | null;
}) {
  const hasOral = diagnostic.oral != null;
  const title = diagnosticAnalysisTitle(hasOral);
  const steps = diagnosticAnalysisSteps({
    writtenReceived: diagnostic.written ? diagnostic.written.submissionId != null : null,
    oralReceived: diagnostic.oral ? diagnostic.oral.submissionId != null : null,
  });

  return (
    <WaitCard
      kicker={DIAGNOSTIC_ANALYSIS_KICKER}
      title={
        <>
          {title.lead} <em>{title.em}</em> {title.tail}
        </>
      }
      lead={DIAGNOSTIC_ANALYSIS_LEAD}
      steps={steps}
    >
      {(elapsedMs) => (
        <>
          <p className={styles.waitReassurance}>
            {elapsedMs >= DIAGNOSTIC_ANALYSIS_USUAL_MS
              ? diagnosticAnalysisSlow(hasOral)
              : DIAGNOSTIC_ANALYSIS_USUAL}
          </p>

          {transientMessage && <p className={styles.waitTransient}>{transientMessage}</p>}

          <div className={styles.waitOutcomes}>
            <p className={styles.waitOutcomesTitle}>{DIAGNOSTIC_OUTCOMES_TITLE}</p>
            <ul>
              {TCF_DIAGNOSTIC_PANEL.items.map(({Icon, title: itemTitle, text}) => (
                <li key={itemTitle}>
                  <span aria-hidden>{Icon && <Icon size={16} />}</span>
                  <div>
                    <b>{itemTitle}</b>
                    {text && <small>{text}</small>}
                  </div>
                </li>
              ))}
            </ul>
            {TCF_DIAGNOSTIC_PANEL.note && (
              <p className={styles.waitOutcomesNote}>{TCF_DIAGNOSTIC_PANEL.note}</p>
            )}
          </div>

          <div className={styles.actions}>
            <Link className={styles.secondaryButton} href="/dashboard">
              {DIAGNOSTIC_ANALYSIS_HOME_CTA}
            </Link>
          </div>
        </>
      )}
    </WaitCard>
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
