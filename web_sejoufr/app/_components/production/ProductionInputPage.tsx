"use client";

import {useParams, useRouter} from "next/navigation";
import {useCallback, useEffect, useRef, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {handleStartFailure} from "@/lib/start-failure";
import {useSubmissionKey} from "@/lib/idempotency";
import {useAuth} from "@/lib/auth-context";
import {productionTaskTitle, type ProductionTaskDto, type RealtimeSessionDescriptor} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {SkillShell} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {EeWritingForm, clearEeDraft} from "./EeWritingForm";
import {EoRecordingForm} from "./EoRecordingForm";
import {RealtimeLaunchSheet} from "./RealtimeLaunchSheet";
import {RealtimeEoRunner} from "./RealtimeEoRunner";
import {REALTIME_UNAVAILABLE_MESSAGE, useRealtimeEo} from "./useRealtimeEo";
import {type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL} from "./config";
import prod from "./production.module.css";

type UiMode = "loading" | "choosing" | "classic" | "realtime" | "noSpeech";

/**
 * Écran de saisie d'un sujet (entraînement libre) : crée un attempt à la volée,
 * soumet (texte EE ou audio EO), puis redirige vers le feedback IA. Le paywall
 * Intégral s'ouvre quand le backend renvoie 403 (essai gratuit déjà utilisé).
 *
 * EO Tâches 1 & 2 : un modal de lancement (§2.3) propose le mode TEMPS RÉEL
 * (examinateur IA) ou CLASSIQUE (enregistrement). Quota épuisé / non éligible /
 * échec → bascule silencieuse en classique (le candidat n'est jamais bloqué).
 */
export function ProductionInputPage({config}: {config: ProductionConfig}) {
  const params = useParams<{taskId: string}>();
  const taskId = params?.taskId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const [task, setTask] = useState<ProductionTaskDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  // Une cle par production : renvoyer la meme tache apres une coupure ne
  // doit pas faire payer une seconde correction.
  const submissionKey = useSubmissionKey();
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Mode temps réel (EO T1/T2 uniquement) — logique de lancement partagée.
  const rt = useRealtimeEo(status === "authenticated" && config.mode === "audio");
  const [uiMode, setUiMode] = useState<UiMode>("loading");
  const [rtStarting, setRtStarting] = useState(false);
  const [rtError, setRtError] = useState<string | null>(null);
  /** Le temps réel a été refusé (quota, broker indisponible, session refusée) :
   *  on ne repropose plus le choix, le prochain tap sur le micro enregistre. */
  const [rtRefused, setRtRefused] = useState(false);
  const [rtDescriptor, setRtDescriptor] = useState<RealtimeSessionDescriptor | null>(null);
  const [rtAttemptId, setRtAttemptId] = useState<string | null>(null);

  /** Écran parent : la tâche d'où vient ce sujet. L'épreuve n'a pas d'écran
   *  d'accueil — sujet inconnu, on remonte au hub TCF. */
  const upHref = task ? `${config.base}/tache/${task.tacheNumero}` : TCF_HUB_HREF;

  useEffect(() => {
    if (status !== "authenticated" || !taskId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .getTask(taskId)
      .then((t) => {
        if (cancelled) return;
        setTask(t);
        // On affiche D'ABORD le sujet (EoRecordingForm / EeWritingForm). Le choix
        // du mode EO T1/T2 (examinateur temps réel vs seul) est proposé sur le
        // bouton « démarrer » du formulaire (askMode), pas avant lecture du sujet.
        setUiMode("classic");
      })
      .catch((e) => {
        if (!cancelled)
          setLoadError(e instanceof ApiException ? e.message : "Sujet introuvable.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, taskId, config.mode]);

  async function finalize(send: (attemptId: string) => Promise<{id: string}>) {
    if (submitting || !task) return;
    setSubmitError(null);
    setSubmitting(true);
    try {
      const attempt = await productionApi.startAttempt({module: "TCF", epreuve: config.epreuve});
      const sub = await send(attempt.id);
      if (config.mode === "text") clearEeDraft(task.id);
      router.push(`${config.base}/resultats/${sub.id}`);
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => setPaywallOpen(true),
        onMessage: setSubmitError,
        fallbackMessage: "Impossible d'envoyer votre réponse.",
      });
      setSubmitting(false);
    }
  }

  async function startRealtime() {
    if (!task || rtStarting) return;
    setRtError(null);
    setRtStarting(true);
    try {
      const attempt = await productionApi.startAttempt({module: "TCF", epreuve: config.epreuve});
      const res = await rt.start(task.id, attempt.id);
      if (res.kind === "realtime") {
        setRtAttemptId(attempt.id);
        setRtDescriptor(res.descriptor);
        setUiMode("realtime");
      } else if (res.kind === "paywall") {
        setRtRefused(true);
        setPaywallOpen(true);
        setUiMode("classic");
      } else if (res.kind === "error") {
        // Refus du backend (épreuve non concordante, tâche déjà rendue) ou
        // panne : message dans la feuille, enregistrement classique en repli.
        setRtRefused(true);
        setRtError(res.message);
      } else {
        // Quota épuisé / non éligible / fournisseur indisponible : on bascule en
        // classique — jamais bloqué — mais on le DIT. Une bascule muette a caché
        // quatre jours de temps réel mort (cf. REALTIME_UNAVAILABLE_MESSAGE).
        setRtRefused(true);
        setRtError(REALTIME_UNAVAILABLE_MESSAGE);
        setUiMode("classic");
      }
    } catch (e) {
      setRtRefused(true);
      setRtError(e instanceof ApiException ? e.message : "Connexion à l'examinateur impossible.");
    } finally {
      setRtStarting(false);
    }
  }

  // Choix du mode EO T1/T2, déclenché par le bouton « démarrer » du formulaire.
  // askMode ouvre la modal (RealtimeLaunchSheet) et rend une promesse résolue par
  // ses callbacks : « classic » → le formulaire enregistre en place ; « realtime »
  // → startRealtime prend la main ; « cancel » → retour au sujet.
  const modeResolverRef = useRef<((c: "classic" | "realtime" | "cancel") => void) | null>(null);
  const askMode = useCallback((): Promise<"classic" | "realtime" | "cancel"> => {
    setUiMode("choosing");
    return new Promise((resolve) => {
      modeResolverRef.current = resolve;
    });
  }, []);
  const resolveMode = useCallback((choice: "classic" | "realtime" | "cancel") => {
    modeResolverRef.current?.(choice);
    modeResolverRef.current = null;
  }, []);

  /** Après une session temps réel, le backend a créé la submission : on la
   *  retrouve par attempt puis on navigue vers le résultat (poll de l'éval). */
  async function goToRealtimeResult(attemptId: string) {
    for (let i = 0; i < 4; i++) {
      try {
        const subs = await productionApi.listMine({epreuve: config.epreuve, limit: 10});
        const sub = subs.find((s) => s.attemptId === attemptId);
        if (sub) {
          router.push(`${config.base}/resultats/${sub.id}`);
          return;
        }
      } catch {
        // retry
      }
      await new Promise((r) => setTimeout(r, 700));
    }
    // À défaut : retour à la tâche (la session est notée en arrière-plan,
    // visible dans l'historique).
    router.push(upHref);
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/${config.inputSegment}/${taskId}`} />;

  const taskTitle = task ? productionTaskTitle(config.epreuve, task.tacheNumero) : config.label;

  return (
    <DualChromeShell>
      <SkillShell
        backHref={upHref}
        backLabel={task ? `${config.label} · Tâche ${task.tacheNumero}` : TCF_HUB_LABEL}
      >
        {loading ? (
          <p className={s.empty}>Chargement du sujet…</p>
        ) : loadError || !task ? (
          <p className={s.empty}>{loadError ?? "Sujet introuvable."}</p>
        ) : uiMode === "realtime" && rtDescriptor && rtAttemptId ? (
          <RealtimeEoRunner
            descriptor={rtDescriptor}
            task={task}
            taskTitle={taskTitle}
            onFinished={(result) =>
              result.kind === "evaluated"
                ? goToRealtimeResult(rtAttemptId)
                : setUiMode("noSpeech")
            }
            onFatalError={(m) => {
              setRtError(m);
              setUiMode("classic");
            }}
          />
        ) : uiMode === "noSpeech" ? (
          <div className={prod.rtPrep}>
            <div className={`${s.card} ${s.panel}`}>
              <p className={s.answerLabel}>Aucune prise de parole</p>
              <p className={s.verdictText}>
                L&apos;examinateur s&apos;est présenté, mais vous n&apos;avez rien dit —
                il n&apos;y a donc rien à évaluer. Reprenez l&apos;échange quand vous
                êtes prêt·e à répondre à voix haute.
              </p>
            </div>
            <div className={s.actionRow}>
              <button
                type="button"
                className={s.primary}
                onClick={() => setUiMode("classic")}
              >
                Réessayer l&apos;oral
              </button>
              <button
                type="button"
                className={s.secondary}
                onClick={() => router.push(upHref)}
              >
                Retour à l&apos;épreuve
              </button>
            </div>
          </div>
        ) : config.mode === "audio" ? (
          <EoRecordingForm
            task={task}
            submitting={submitting}
            error={submitError ?? rtError}
            submitLabel="Soumettre à l'évaluation"
            exerciseTitle={taskTitle}
            onModeChoice={
              !rtRefused && (task.tacheNumero === 1 || task.tacheNumero === 2)
                ? askMode
                : undefined
            }
            onSubmit={(audio) =>
              finalize((attemptId) =>
                productionApi.submitAudio(
                  task.id, attemptId, audio, undefined,
                  submissionKey(`${attemptId}:${task.id}`),
                ),
              )
            }
          />
        ) : (
          <EeWritingForm
            task={task}
            submitting={submitting}
            error={submitError}
            submitLabel="Soumettre à l'évaluation"
            exerciseTitle={taskTitle}
            onSubmit={(texte) =>
              finalize((attemptId) =>
                productionApi.submitText({
                  productionTaskId: task.id,
                  attemptId,
                  texte,
                  clientSubmissionId: submissionKey(`${attemptId}:${task.id}`),
                }),
              )
            }
          />
        )}

        {task && (
          <RealtimeLaunchSheet
            open={uiMode === "choosing"}
            tacheNumero={task.tacheNumero}
            taskTitle={taskTitle}
            sessionsRemaining={rt.remaining}
            cap={rt.cap}
            starting={rtStarting}
            error={rtError}
            onPickRealtime={() => {
              resolveMode("realtime");
              startRealtime();
            }}
            onPickClassic={() => {
              setUiMode("classic");
              resolveMode("classic");
            }}
            // Paywall par-dessus le modal ; on résout « cancel » (rien n'a été
            // lancé) et on revient au sujet — retaper « démarrer » rouvre le choix.
            onPaywall={() => {
              setUiMode("classic");
              resolveMode("cancel");
              setPaywallOpen(true);
            }}
            onClose={() => {
              setUiMode("classic");
              resolveMode("cancel");
            }}
          />
        )}

        <PaywallSheet ctaLocation="AI_CORRECTION" screen="production_saisie"
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title={`Débloquez l'${config.label.toLowerCase()}`}
          message={`Vous avez utilisé votre essai gratuit d'${config.label.toLowerCase()}. L'abonnement Intégral débloque l'entraînement et les examens blancs EE/EO illimités, plus tout le TCF et le civique.`}
        />
      </SkillShell>
    </DualChromeShell>
  );
}
