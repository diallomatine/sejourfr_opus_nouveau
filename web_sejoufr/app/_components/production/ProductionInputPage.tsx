"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {productionTaskTitle, type ProductionTaskDto} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {EeWritingForm, clearEeDraft} from "./EeWritingForm";
import {EoRecordingForm} from "./EoRecordingForm";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

/**
 * Écran de saisie d'un sujet (entraînement libre) : crée un attempt à la volée,
 * soumet (texte EE ou audio EO), puis redirige vers le feedback IA. Le paywall
 * Intégral s'ouvre quand le backend renvoie 403 (quota de 2 essais dépassé).
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

  useEffect(() => {
    if (status !== "authenticated" || !taskId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .getTask(taskId)
      .then((t) => {
        if (!cancelled) setTask(t);
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
  }, [status, taskId]);

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

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/${config.inputSegment}/${taskId}`} />;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={config.base}
          title={config.label}
          subtitle={
            task ? `Tâche ${task.tacheNumero} · ${productionTaskTitle(config.epreuve, task.tacheNumero)}` : config.label
          }
        />
        {loading ? (
          <p className={prod.loading}>Chargement du sujet…</p>
        ) : loadError || !task ? (
          <p className={prod.empty}>{loadError ?? "Sujet introuvable."}</p>
        ) : config.mode === "audio" ? (
          <EoRecordingForm
            task={task}
            submitting={submitting}
            error={submitError}
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
        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title={`Débloquez l'${config.label.toLowerCase()}`}
          message={`Vous avez utilisé vos 2 essais gratuits d'${config.label.toLowerCase()}. L'abonnement Intégral débloque l'entraînement et les examens blancs EE/EO illimités, plus tout le TCF et le civique.`}
        />
      </main>
    </DualChromeShell>
  );
}
