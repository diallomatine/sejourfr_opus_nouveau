"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {productionTaskTitle, type ProductionTaskDto, type RealtimeSessionDescriptor} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {EeWritingForm, clearEeDraft} from "./EeWritingForm";
import {EoRecordingForm} from "./EoRecordingForm";
import {RealtimeLaunchSheet} from "./RealtimeLaunchSheet";
import {RealtimeEoRunner} from "./RealtimeEoRunner";
import {useRealtimeEo} from "./useRealtimeEo";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

type UiMode = "loading" | "choosing" | "classic" | "realtime";

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
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Mode temps réel (EO T1/T2 uniquement) — logique de lancement partagée.
  const rt = useRealtimeEo(status === "authenticated" && config.mode === "audio");
  const [uiMode, setUiMode] = useState<UiMode>("loading");
  const [rtStarting, setRtStarting] = useState(false);
  const [rtError, setRtError] = useState<string | null>(null);
  const [rtDescriptor, setRtDescriptor] = useState<RealtimeSessionDescriptor | null>(null);
  const [rtAttemptId, setRtAttemptId] = useState<string | null>(null);

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
        const eligible = config.mode === "audio" && (t.tacheNumero === 1 || t.tacheNumero === 2);
        setUiMode(eligible ? "choosing" : "classic");
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
      if (e instanceof ApiException && e.status === 403) setPaywallOpen(true);
      else
        setSubmitError(
          e instanceof ApiException ? e.message : "Impossible d'envoyer votre réponse.",
        );
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
        setPaywallOpen(true);
        setUiMode("classic");
      } else if (res.kind === "error") {
        setRtError(res.message);
      } else {
        // Quota épuisé / non éligible : bascule silencieuse en classique.
        setUiMode("classic");
      }
    } catch (e) {
      setRtError(e instanceof ApiException ? e.message : "Connexion à l'examinateur impossible.");
    } finally {
      setRtStarting(false);
    }
  }

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
    // À défaut : retour au hub (la session est notée en arrière-plan, visible dans l'historique).
    router.push(config.base);
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/${config.inputSegment}/${taskId}`} />;

  const taskTitle = task ? productionTaskTitle(config.epreuve, task.tacheNumero) : config.label;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={config.base}
          title={config.label}
          subtitle={task ? `Tâche ${task.tacheNumero} · ${taskTitle}` : config.label}
        />
        {loading ? (
          <p className={prod.loading}>Chargement du sujet…</p>
        ) : loadError || !task ? (
          <p className={prod.empty}>{loadError ?? "Sujet introuvable."}</p>
        ) : uiMode === "realtime" && rtDescriptor && rtAttemptId ? (
          <RealtimeEoRunner
            descriptor={rtDescriptor}
            taskTitle={taskTitle}
            onFinished={() => goToRealtimeResult(rtAttemptId)}
            onFatalError={(m) => {
              setRtError(m);
              setUiMode("classic");
            }}
          />
        ) : config.mode === "audio" ? (
          <EoRecordingForm
            task={task}
            submitting={submitting}
            error={submitError ?? rtError}
            submitLabel="Soumettre à l'évaluation"
            onSubmit={(audio) =>
              finalize((attemptId) => productionApi.submitAudio(task.id, attemptId, audio))
            }
          />
        ) : (
          <EeWritingForm
            task={task}
            submitting={submitting}
            error={submitError}
            submitLabel="Soumettre à l'évaluation"
            onSubmit={(texte) =>
              finalize((attemptId) =>
                productionApi.submitText({productionTaskId: task.id, attemptId, texte}),
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
            realtimeAvailable={rt.remaining == null ? true : rt.remaining > 0}
            starting={rtStarting}
            error={rtError}
            onPickRealtime={startRealtime}
            onPickClassic={() => setUiMode("classic")}
            onClose={() => setUiMode("classic")}
          />
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title={`Débloquez l'${config.label.toLowerCase()}`}
          message={`Vous avez utilisé votre essai gratuit d'${config.label.toLowerCase()}. L'abonnement Intégral débloque l'entraînement et les examens blancs EE/EO illimités, plus tout le TCF et le civique.`}
        />
      </main>
    </DualChromeShell>
  );
}
