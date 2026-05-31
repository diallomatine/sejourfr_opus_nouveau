"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {eeTaskTitle, type ProductionTaskDto} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {EeWritingForm, clearEeDraft} from "@/app/_components/production/EeWritingForm";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "@/app/_components/production/production.module.css";

/**
 * Rédaction libre d'un sujet EE : crée un attempt de production à la volée,
 * soumet le texte, puis redirige vers le feedback IA. Le paywall Intégral
 * s'ouvre quand le backend renvoie 403 (quota de 2 essais gratuits dépassé).
 */
export default function EeRedactionPage() {
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

  async function submit(texte: string) {
    if (submitting || !task) return;
    setSubmitError(null);
    setSubmitting(true);
    try {
      const attempt = await productionApi.startAttempt({module: "TCF", epreuve: "TCF_EE"});
      const sub = await productionApi.submitText({
        productionTaskId: task.id,
        attemptId: attempt.id,
        texte,
      });
      clearEeDraft(task.id);
      router.push(`/entrainement/tcf/ee/resultats/${sub.id}`);
    } catch (e) {
      if (e instanceof ApiException && e.status === 403) {
        setPaywallOpen(true);
      } else {
        setSubmitError(
          e instanceof ApiException ? e.message : "Impossible d'envoyer votre texte.",
        );
      }
      setSubmitting(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/ee/redaction/${taskId}`} />;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement/tcf/ee"
          title="Expression écrite"
          subtitle={task ? `Tâche ${task.tacheNumero} · ${eeTaskTitle(task.tacheNumero)}` : "Rédaction"}
        />
        {loading ? (
          <p className={prod.loading}>Chargement du sujet…</p>
        ) : loadError || !task ? (
          <p className={prod.empty}>{loadError ?? "Sujet introuvable."}</p>
        ) : (
          <EeWritingForm
            task={task}
            submitting={submitting}
            error={submitError}
            submitLabel="Soumettre à l'évaluation"
            onSubmit={submit}
          />
        )}
        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title="Débloquez l'expression écrite"
          message="Vous avez utilisé vos 2 essais gratuits d'expression écrite. L'abonnement Intégral débloque l'entraînement et les examens blancs EE/EO illimités, plus tout le TCF et le civique."
        />
      </main>
    </DualChromeShell>
  );
}
