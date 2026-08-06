"use client";

import Link from "next/link";
import {useParams, useSearchParams} from "next/navigation";
import {useEffect, useState} from "react";
import {Check} from "lucide-react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  isSubmissionPending,
  productionTaskTitle,
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
 * L'écran suit l'ordre de la maquette : **accusé de traitement** (la production
 * est enregistrée — c'est ce que le candidat vient vérifier), puis l'**écho de
 * sa production**, puis le retour détaillé, puis les actions de fin. Le contenu
 * du retour lui-même (`ProductionFeedbackView`) garde son ordre et ses règles
 * de lecture : ce sont des décisions de notation, pas de mise en page.
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
            {/* Accusé de traitement : la production est enregistrée. C'est la
                première chose qu'un candidat vient vérifier — avant même la
                note. */}
            <section className={`${s.card} ${s.panel} ${s.result}`}>
              <div className={s.resultTitle}>
                <span className={s.check} aria-hidden>
                  <Check size={22} strokeWidth={3} />
                </span>
                <div>
                  <h1 className={s.resultHeading}>Production évaluée</h1>
                  <p className={s.resultSub}>
                    Tâche {tacheNum} · {productionTaskTitle(config.epreuve, tacheNum)}
                  </p>
                </div>
              </div>

              {/* Écho de la production : on relit ce qu'on a rendu en lisant le
                  retour — à l'oral, on se réécoute. */}
              {config.mode === "text" && submission.texteSoumis && (
                <div className={s.answerBox}>
                  <span className={s.answerLabel}>
                    Votre production · {submission.motsCount ?? 0} mots
                  </span>
                  <p className={s.prodText}>{submission.texteSoumis}</p>
                </div>
              )}

              {/* À l'oral, l'écho de la production est la transcription :
                  `ProductionSubmissionDto` ne porte pas d'URL audio (contrairement
                  à `SkillAttemptDto`), et on n'invente pas un lecteur sur une
                  donnée que l'API ne sert pas. */}
              {config.mode === "audio" && submission.transcription && (
                <details className={s.answerBox}>
                  <summary className={s.answerLabel}>Votre production · transcription</summary>
                  <div className={s.aiPanel}>
                    <TranscriptDialogue raw={submission.transcription} />
                  </div>
                </details>
              )}
            </section>

            <ProductionFeedbackView
              evaluation={submission.evaluation}
              isOral={config.mode === "audio"}
            />

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
