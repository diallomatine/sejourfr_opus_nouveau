"use client";

import Link from "next/link";
import {useParams, useSearchParams} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  isSubmissionPending,
  productionTaskTitle,
  type ProductionSubmissionDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {ProductionFeedbackView} from "./ProductionFeedbackView";
import {EoTranscriptNotice} from "./EoTranscriptNotice";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

const POLL_MS = 3000;
const MAX_POLLS = 40; // ~2 min

/**
 * Feedback IA d'une production (EE/EO). Poll la submission toutes les 3 s tant
 * que l'évaluation n'a pas abouti (EO passe par TRANSCRIBING), affiche le détail
 * une fois EVALUATED, et propose « Réessayer » si FAILED.
 */
export function ProductionResults({config}: {config: ProductionConfig}) {
  const params = useParams<{submissionId: string}>();
  const id = params?.submissionId ?? "";
  const searchParams = useSearchParams();
  const {user, status} = useAuth();

  // Écran d'origine (bilan d'examen `…/session/{id}`, historique…) passé en
  // `?back=` par l'appelant — sans lui, retour au hub de l'épreuve. On
  // n'accepte qu'un chemin interne (pas d'open redirect).
  const backParam = searchParams?.get("back");
  const backHref = backParam && backParam.startsWith("/") ? backParam : config.base;

  const [submission, setSubmission] = useState<ProductionSubmissionDto | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [retrying, setRetrying] = useState(false);
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
      setPollKey((k) => k + 1);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de relancer l'évaluation.");
    } finally {
      setRetrying(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/resultats/${id}`} />;

  const tacheNum = submission?.tacheNumero ?? 0;
  const pending = submission ? isSubmissionPending(submission) : true;
  const failed = submission?.statut === "FAILED";
  const transcribing = submission?.statut === "TRANSCRIBING";

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={backHref}
          title="Résultat"
          subtitle={
            submission
              ? `Tâche ${tacheNum} · ${productionTaskTitle(config.epreuve, tacheNum)}`
              : config.label
          }
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
              <Link href={backHref} className="btn btn-ghost">
                Retour
              </Link>
            </div>
          </div>
        ) : pending ? (
          <div className={prod.pending}>
            <div className={prod.spinner} />
            <p className={prod.pendingTitle}>
              {transcribing ? "Transcription en cours…" : "Évaluation en cours…"}
            </p>
            <p className={prod.pendingSub}>
              {transcribing
                ? "Votre enregistrement est transcrit avant l'analyse. Encore quelques secondes…"
                : "L'IA analyse votre production (cohérence, lexique, grammaire…). Cela prend généralement une quinzaine de secondes."}
            </p>
          </div>
        ) : submission.evaluation ? (
          <>
            <ProductionFeedbackView
              evaluation={submission.evaluation}
              isOral={config.mode === "audio"}
            />
            {config.mode === "audio" && <EoTranscriptNotice />}
            {config.mode === "audio" && submission.transcription && (
              <details className={prod.card}>
                <summary className={prod.cardLabel} style={{cursor: "pointer"}}>
                  Voir la transcription de votre audio
                </summary>
                <p className={prod.submitted} style={{marginTop: 12}}>
                  {submission.transcription}
                </p>
              </details>
            )}
            {config.mode === "text" && submission.texteSoumis && (
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
              <Link href={backHref} className="btn btn-blue">
                {backParam ? "Retour" : "Retour aux tâches"}
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
