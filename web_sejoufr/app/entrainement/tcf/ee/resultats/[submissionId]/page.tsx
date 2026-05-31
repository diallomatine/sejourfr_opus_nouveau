"use client";

import Link from "next/link";
import {useParams} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {eeTaskTitle, isSubmissionPending, type ProductionSubmissionDto} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {EeFeedbackView} from "@/app/_components/production/EeFeedbackView";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "@/app/_components/production/production.module.css";

const POLL_MS = 3000;
const MAX_POLLS = 40; // ~2 min

/**
 * Feedback IA d'une production EE. Poll la submission toutes les 3 s tant que
 * l'évaluation n'a pas abouti (parité `EeResultsScreen` mobile), affiche le
 * détail (note/20, CECRL, critères, feedback) une fois EVALUATED, et propose un
 * « Réessayer » si FAILED.
 */
export default function EeResultsPage() {
  const params = useParams<{submissionId: string}>();
  const id = params?.submissionId ?? "";
  const {user, status} = useAuth();

  const [submission, setSubmission] = useState<ProductionSubmissionDto | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [retrying, setRetrying] = useState(false);
  // Incrémenté pour relancer le polling après un « Réessayer ».
  const [pollKey, setPollKey] = useState(0);

  useEffect(() => {
    if (status !== "authenticated" || !id) return;
    let cancelled = false;
    let polls = 0;
    let timer: ReturnType<typeof setTimeout> | null = null;
    async function tick() {
      try {
        const s = await productionApi.getSubmission(id);
        if (cancelled) return;
        setSubmission(s);
        if (isSubmissionPending(s) && polls < MAX_POLLS) {
          polls += 1;
          timer = setTimeout(tick, POLL_MS);
        }
      } catch (e) {
        if (cancelled) return;
        setError(e instanceof ApiException ? e.message : "Impossible de charger l'évaluation.");
      }
    }
    void tick();
    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
  }, [status, id, pollKey]);

  async function retry() {
    if (retrying || !submission) return;
    setError(null);
    setRetrying(true);
    try {
      const s = await productionApi.retrySubmission(submission.id);
      setSubmission(s);
      setPollKey((k) => k + 1); // relance le polling
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de relancer l'évaluation.");
    } finally {
      setRetrying(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/ee/resultats/${id}`} />;

  const tacheNum = submission?.tacheNumero ?? 0;
  const pending = submission ? isSubmissionPending(submission) : true;
  const failed = submission?.statut === "FAILED";

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref="/entrainement/tcf/ee"
          title="Résultat"
          subtitle={submission ? `Tâche ${tacheNum} · ${eeTaskTitle(tacheNum)}` : "Expression écrite"}
        />

        {error && <div className={prod.error}>{error}</div>}

        {!submission ? (
          <div className={prod.pending}>
            <div className={prod.spinner} />
            <p className={prod.pendingSub}>Chargement…</p>
          </div>
        ) : failed ? (
          <div className={prod.card}>
            <p className={prod.cardLabel}>Évaluation échouée</p>
            <p className={prod.consigne} style={{fontSize: 14}}>
              {submission.erreurMessage ??
                "L'évaluation n'a pas pu aboutir. Vous pouvez relancer."}
            </p>
            <div className={prod.actions} style={{justifyContent: "flex-start", marginTop: 14}}>
              {submission.retryCount < 3 && (
                <button type="button" className="btn btn-blue" disabled={retrying} onClick={retry}>
                  {retrying ? "Relance…" : "Réessayer"}
                </button>
              )}
              <Link href="/entrainement/tcf/ee" className="btn btn-ghost">
                Retour
              </Link>
            </div>
          </div>
        ) : pending ? (
          <div className={prod.pending}>
            <div className={prod.spinner} />
            <p className={prod.pendingTitle}>Évaluation en cours…</p>
            <p className={prod.pendingSub}>
              L&apos;IA analyse votre production (cohérence, lexique, grammaire…). Cela prend
              généralement une quinzaine de secondes.
            </p>
          </div>
        ) : submission.evaluation ? (
          <>
            <EeFeedbackView evaluation={submission.evaluation} />
            {submission.texteSoumis && (
              <details className={prod.card}>
                <summary className={prod.cardLabel} style={{cursor: "pointer"}}>
                  Voir le texte soumis ({submission.motsCount ?? 0} mots)
                </summary>
                <p className={prod.submitted} style={{marginTop: 12}}>
                  {submission.texteSoumis}
                </p>
              </details>
            )}
            <div className={prod.actions}>
              <Link href="/entrainement/tcf/ee" className="btn btn-blue">
                Retour aux tâches
              </Link>
            </div>
          </>
        ) : (
          <p className={prod.empty}>Évaluation indisponible.</p>
        )}
      </main>
    </DualChromeShell>
  );
}
