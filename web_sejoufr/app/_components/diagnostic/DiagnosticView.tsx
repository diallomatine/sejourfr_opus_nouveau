"use client";

import Link from "next/link";
import {useCallback, useEffect, useRef, useState, type ReactNode} from "react";
import {
  ArrowLeft,
  Check,
  Clock3,
  FilePenLine,
  Headphones,
  Info,
  RotateCcw,
  Sparkles,
} from "lucide-react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {EeWritingForm, clearEeDraft} from "@/app/_components/production/EeWritingForm";
import {EoRecordingForm} from "@/app/_components/production/EoRecordingForm";
import {ApiException, diagnosticApi, productionApi} from "@/lib/api";
import {useSubmissionKey} from "@/lib/idempotency";
import {
  rememberDiagnosticType,
  track,
  trackDiagnostic,
} from "@/lib/analytics";
import {withTrafficSource} from "@/lib/traffic-source";
import {useAuth} from "@/lib/auth-context";
import {
  type DiagnosticExerciseContent,
  diagnosticExerciseAsProductionTask,
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
import {useTrafficSource} from "@/lib/use-traffic-source";
import {DiagnosticAccountGate} from "./DiagnosticAccountGate";
import {DiagnosticIntro, type DiagnosticParcours} from "./DiagnosticIntro";
import {DiagnosticReport} from "./DiagnosticReport";
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
  // La mesure lit le format au **même** endroit que les écrans : tant que le
  // candidat n'a rien choisi, elle reste à `UNKNOWN` (cf. `lib/analytics.ts`),
  // et un rechargement de page repart légitimement d'`UNKNOWN`.
  const chooseParcours = useCallback((chosen: DiagnosticParcours) => {
    setParcours(chosen);
    rememberDiagnosticType(chosen === "COMPLET" ? "COMPLETE" : "RAPID");
  }, []);
  if (status === "loading") return <DiagnosticSkeleton />;
  // `DualChromeShell` porte les deux chromes de la route : sidebar pour un
  // compte, fond applicatif nu pour un visiteur (qui garde le header et le
  // pied de page publics du layout racine).
  return (
    <DualChromeShell>
      {status === "authenticated" ? (
        <ConnectedDiagnostic parcours={parcours} onChooseParcours={chooseParcours} />
      ) : (
        <GuestDiagnostic parcours={parcours} onChooseParcours={chooseParcours} />
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
    trackDiagnostic("DIAGNOSTIC_EE_COMPLETED", {once: true});
    setSaving(false);
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
        <DiagnosticSteps current="account" guest complete={complete} oral={subjects.oral !== null} />
        <DiagnosticAccountGate
          writtenWords={countEeWords(local?.writtenText ?? "")}
          oralDurationSec={local?.oralDurationSec ?? null}
          hasOral={subjects.oral !== null}
          storedOnDevice={storedOnDevice}
        />
      </DiagnosticShell>
    );
  }

  if (step === "oral" && subjects.oral) {
    const oral = subjects.oral;
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
          task={diagnosticExerciseAsProductionTask(oral)}
          submitting={saving}
          error={error}
          submitLabel="Terminer et analyser"
          promptSlot={<ExercisePrompt exercise={oral} kind="oral" />}
          criteriaSlot={null}
          maxDurationSec={oral.durationMaxSeconds}
          onSubmit={(audio, durationSec) => void keepOral(audio, durationSec)}
        />
      </DiagnosticShell>
    );
  }

  if (step === "written") {
    return (
      <DiagnosticShell guest compact>
        <DiagnosticSteps current="written" guest complete={complete} oral={subjects.oral !== null} />
        <ExerciseHeader kind="written" />
        <EeWritingForm
          task={diagnosticExerciseAsProductionTask(subjects.written)}
          submitting={saving}
          error={error}
          submitLabel={subjects.oral ? "Continuer vers l'oral" : "Valider mon diagnostic"}
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
          trackDiagnostic("DIAGNOSTIC_STARTED", {once: true});
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
  // Une cle par production de diagnostic. Le renvoi apres coupure — le cas le
  // plus frequent de ce parcours, ou le compte vient d'etre cree — retrouve la
  // soumission au lieu d'echouer sur « deja rendue ».
  const submissionKey = useSubmissionKey();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [handoff, setHandoff] = useState<Handoff>({kind: "idle"});
  const [pendingLocal, setPendingLocal] = useState<LocalDiagnosticProductions | null>(null);
  const trafficSource = useTrafficSource();

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
        // 🛑 Le sujet REELLEMENT rédigé est renvoyé au serveur : depuis L3 le
        // sujet écrit peut être tiré, et sans cet identifiant la session
        // s'ouvrirait sur un autre énoncé que celui traité par le candidat.
        // Vérifié serveur — un identifiant inconnu retombe sur un tirage.
        let session = await diagnosticApi.start(local.writtenTaskId ?? undefined);
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
            setHandoff({kind: "running", label: "Envoi de votre enregistrement…"});
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
            message: session.oral
              ? "Le serveur n'a pas confirmé la réception de vos deux réponses."
              : "Le serveur n'a pas confirmé la réception de votre réponse.",
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
    if (diagnostic.status === "COMPLETED") {
      // 🛑 Pas d'événement « diagnostic terminé » : il se lit sur
      // `diagnostic_sessions.status`, on ne crée pas une seconde vérité.
      trackDiagnostic("DIAGNOSTIC_REPORT_VIEWED", {once: true});
    }
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
    const planHref = withTrafficSource("/plan", trafficSource);
    return (
      <DiagnosticShell>
        <DiagnosticReport
          diagnostic={diagnostic}
          targetLevel={user.targetLevel ?? null}
          hasTcf={user.hasTcf ?? false}
          planHref={planHref}
          notice={notice}
        />
      </DiagnosticShell>
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
          submitLabel={diagnostic.oral ? "Continuer vers l'oral" : "Lancer mon analyse"}
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

function DiagnosticSkeleton() {
  return (
    <main className={styles.page} aria-busy="true" aria-label="Chargement du diagnostic">
      <div className={styles.skeletonHeader} />
      <div className={styles.skeletonCard} />
    </main>
  );
}
