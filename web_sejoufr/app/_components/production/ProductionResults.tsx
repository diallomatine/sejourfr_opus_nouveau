"use client";

import Link from "next/link";
import {useParams, useSearchParams} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  isSubmissionPending,
  niveauViseTcf,
  type ProductionSubmissionDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {SkillShell} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import {ProductionFeedbackView} from "./ProductionFeedbackView";
import {TranscriptDialogue} from "./TranscriptDialogue";
import {type ProductionConfig, TCF_HUB_HREF, TCF_HUB_LABEL} from "./config";

const POLL_MS = 3000;
const MAX_POLLS = 40; // ~2 min

/**
 * Feedback IA d'une production (EE/EO). Poll la submission toutes les 3 s tant
 * que l'évaluation n'a pas abouti (EO passe par TRANSCRIBING), affiche le détail
 * une fois EVALUATED, et propose « Réessayer » si FAILED.
 *
 * **L'accusé de traitement a disparu** : « Production évaluée » au-dessus d'un
 * hero qui annonce déjà le verdict et la note ne disait rien de plus, et coûtait
 * le premier écran. Le rapport commence donc directement par
 * `ProductionFeedbackView`, qui porte l'écho de la production à l'écrit (dans la
 * carte « Votre rédaction », là où se fait la comparaison). À l'oral, la
 * transcription reste dans son dépliant ici : `ProductionSubmissionDto` ne porte
 * pas d'URL audio, et on n'invente pas un lecteur sur une donnée que l'API ne
 * sert pas.
 */
export function ProductionResults({config}: {config: ProductionConfig}) {
  const params = useParams<{submissionId: string}>();
  const id = params?.submissionId ?? "";
  const searchParams = useSearchParams();
  const {user, status} = useAuth();

  // Écran d'origine (bilan d'examen `…/session/{id}`, historique…) passé en
  // `?back=` par l'appelant — sans lui, retour au hub TCF (l'épreuve n'a pas
  // d'écran d'accueil). On n'accepte qu'un chemin interne (pas d'open redirect).
  const backParam = searchParams?.get("back");
  const backHref = backParam && backParam.startsWith("/") ? backParam : TCF_HUB_HREF;

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
        const sub = await productionApi.getSubmission(id);
        if (cancelled) return;
        setSubmission(sub);
        if (isSubmissionPending(sub) && polls < MAX_POLLS) {
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
      const sub = await productionApi.retrySubmission(submission.id);
      setSubmission(sub);
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
      <SkillShell
        config={config}
        backHref={backHref}
        backLabel={backParam ? "Retour" : TCF_HUB_LABEL}
      >
        {error && <div className={s.error}>{error}</div>}

        {!submission ? (
          <div className={s.pending}>
            <div className={s.spinner} />
            <p className={s.pendingText}>Chargement…</p>
          </div>
        ) : failed ? (
          <section className={`${s.card} ${s.panel}`}>
            <h1 className={s.resultHeading}>Évaluation échouée</h1>
            <p className={s.verdictText}>
              {submission.erreurMessage ??
                "L'évaluation n'a pas pu aboutir. Vous pouvez la relancer."}
            </p>
            <div className={s.actionRow}>
              {submission.retryCount < 3 && (
                <button type="button" className={s.primary} disabled={retrying} onClick={retry}>
                  {retrying ? "Relance…" : "Réessayer"}
                </button>
              )}
              <Link href={backHref} className={s.secondary}>
                Retour
              </Link>
            </div>
          </section>
        ) : pending ? (
          <div className={s.pending}>
            <div className={s.spinner} />
            <p className={s.resultHeading}>
              {transcribing ? "Transcription en cours…" : "Évaluation en cours…"}
            </p>
            <p className={s.pendingText}>
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
              eyebrow={`${config.epreuve === "TCF_EO" ? "Expression orale" : "Expression écrite"} · Tâche ${tacheNum}`}
              productionText={config.mode === "text" ? submission.texteSoumis : null}
              motsCount={submission.motsCount}
              // Palier VISÉ : la démarche fait plancher (NAT ⇒ B2, même si le
              // compte porte un `targetLevel` plus bas). Volontairement SANS le
              // repli « B1 » de `resolveTcfLevel` : un objectif deviné n'a rien
              // à faire dans une phrase qui dit au candidat ce qu'il joue.
              targetLevel={niveauViseTcf(user)}
            />

            {/* À l'oral, l'écho de la production est la transcription. */}
            {config.mode === "audio" && submission.transcription && (
              <details className={s.answerBox}>
                <summary className={s.answerLabel}>Votre production · transcription</summary>
                <div className={s.aiPanel}>
                  <TranscriptDialogue raw={submission.transcription} />
                </div>
              </details>
            )}

            <div className={s.actions}>
              <Link href={backHref} className={`${s.primary} ${s.actionWide}`}>
                {backParam ? "Retour" : "Retour aux tâches"}
              </Link>
            </div>
          </>
        ) : (
          <p className={s.empty}>Évaluation indisponible.</p>
        )}
      </SkillShell>
    </DualChromeShell>
  );
}
