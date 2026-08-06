"use client";

import {useParams, useRouter} from "next/navigation";
import {useCallback, useEffect, useId, useState} from "react";
import {ArrowRight, Check, Clock, RefreshCw, Sparkles, Target, TrendingUp} from "lucide-react";
import {ApiException, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  formatDurationSec,
  isSkillAttemptPending,
  SKILL_CRITERION_STATUS_LABEL,
  SKILL_SELF_EVALUATION_LABEL,
  type SkillAnalysisDto,
  type SkillAnalysisQuotaDto,
  type SkillAttemptDto,
  type SkillCriterionStatus,
  type SkillPromptDto,
  type SkillReferenceDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {type ProductionConfig} from "@/app/_components/production/config";
import {CompetenceReferences} from "./CompetenceReferences";
import {SkillShell} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

const POLL_MS = 3000;
/**
 * Plafond de polling **partagé mot pour mot avec le mobile : 3 s de cadence,
 * 120 s de budget**. Il est déclaré en **durée**, pas en nombre de tirages :
 * c'est la durée qui est la valeur de parité, et c'est en la traduisant chacun
 * de son côté (« 40 tirages » ici, « timeout 90 s » là-bas) que les deux fronts
 * avaient divergé — une analyse qui aboutit à 100 s aboutissait sur le web et
 * échouait sur le mobile. Abandonner une analyse qui allait aboutir est le pire
 * des deux défauts : on retient la valeur la plus généreuse.
 */
const POLL_BUDGET_MS = 120_000;
const MAX_POLLS = Math.floor(POLL_BUDGET_MS / POLL_MS);

/** Habillage du verdict du critère unique.
 *
 *  `NOT_VALIDATED` est **rouge**, comme sur mobile et comme la référence
 *  « Insuffisant » : c'est un critère, pas un niveau CECRL — la règle « jamais
 *  de rouge sur un palier » ne s'applique pas ici. Le mettre en bleu d'un côté
 *  et en rouge de l'autre laissait le même verdict tantôt neutre, tantôt
 *  alarmant.
 *
 *  Le **libellé** ne vit pas ici : il vient de `SKILL_CRITERION_STATUS_LABEL`,
 *  partagé avec le backend et le mobile. Ce fichier en tenait une copie locale,
 *  et c'est ainsi que le web s'était mis à dire « Critère à retravailler » là où
 *  le mobile disait « Critère non atteint ». */
const VERDICT_TONE: Record<SkillCriterionStatus, {card: string; status: string}> = {
  VALIDATED: {card: "", status: s.statusValidated},
  PARTIAL: {card: s.verdictPartial, status: s.statusPartial},
  NOT_VALIDATED: {card: s.verdictNot, status: s.statusNot},
};

/**
 * Retour après une tentative sur un petit sujet.
 *
 * L'ordre est imposé (spec §13.4) : accusé de traitement, la production, puis
 * le retour de l'IA, puis **seulement ensuite** les références comparatives.
 * Voir les modèles avant son propre retour pousse à se comparer au lieu de se
 * relire.
 *
 * Il n'y a ici **ni note /20 ni niveau CECRL** (spec §9) : un exercice de
 * quinze mots ne situe personne sur l'échelle du TCF. Le seul verdict porte sur
 * le critère unique du sujet.
 */
export function CompetenceResult({config}: {config: ProductionConfig}) {
  const params = useParams<{
    n: string;
    skillId: string;
    promptId: string;
    attemptId: string;
  }>();
  const n = Number(params?.n ?? "0");
  const skillId = params?.skillId ?? "";
  const promptId = params?.promptId ?? "";
  const attemptId = params?.attemptId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const base = `${config.base}/tache/${n}/competences`;

  const [attempt, setAttempt] = useState<SkillAttemptDto | null>(null);
  const [prompt, setPrompt] = useState<SkillPromptDto | null>(null);
  const [references, setReferences] = useState<SkillReferenceDto[]>([]);
  const [quota, setQuota] = useState<SkillAnalysisQuotaDto | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [retrying, setRetrying] = useState(false);
  const [pollKey, setPollKey] = useState(0);
  const [paywallOpen, setPaywallOpen] = useState(false);

  // Poll tant que l'analyse est en vol (EO passe par TRANSCRIBING). Une
  // tentative RECORDED est finale : aucun appel inutile n'est déclenché.
  useEffect(() => {
    if (status !== "authenticated" || !attemptId) return;
    let cancelled = false;
    let polls = 0;
    let timer: ReturnType<typeof setTimeout> | null = null;
    async function tick() {
      try {
        const a = await skillApi.getAttempt(attemptId);
        if (cancelled) return;
        setAttempt(a);
        if (isSkillAttemptPending(a) && polls < MAX_POLLS) {
          polls += 1;
          timer = setTimeout(tick, POLL_MS);
        }
      } catch (e) {
        if (cancelled) return;
        setError(e instanceof ApiException ? e.message : "Impossible de charger le résultat.");
      }
    }
    void tick();
    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
  }, [status, attemptId, pollKey]);

  // Références + sujet (pour `nextPromptId`). Le 403 sur les références n'est
  // pas une panne : c'est le garde « pas de modèle avant d'avoir produit ».
  useEffect(() => {
    if (status !== "authenticated" || !promptId) return;
    let cancelled = false;
    skillApi
      .listReferences(promptId)
      .then((r) => {
        if (!cancelled) setReferences(r);
      })
      .catch(() => undefined);
    skillApi
      .getPrompt(promptId)
      .then((p) => {
        if (!cancelled) setPrompt(p);
      })
      .catch(() => undefined);
    skillApi
      .analysisQuota()
      .then((q) => {
        if (!cancelled) setQuota(q);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, promptId]);

  const retry = useCallback(async () => {
    if (retrying || !attempt) return;
    setError(null);
    setRetrying(true);
    try {
      const a = await skillApi.retryAnalysis(attempt.id);
      setAttempt(a);
      setPollKey((k) => k + 1);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de relancer l'analyse.");
    } finally {
      setRetrying(false);
    }
  }, [retrying, attempt]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user)
    return <ModuleDetailGate next={`${base}/${skillId}/${promptId}/resultat/${attemptId}`} />;

  const pending = attempt ? isSkillAttemptPending(attempt) : true;
  const failed = attempt?.statut === "FAILED";
  const recorded = attempt?.statut === "RECORDED";
  const analysis = attempt?.analysis ?? null;
  const nextId = prompt?.nextPromptId ?? null;
  const analysisAllowed = quota == null || quota.remaining !== 0;

  return (
    <DualChromeShell>
      <SkillShell
        config={config}
        backHref={`${base}/${skillId}`}
        backLabel={prompt?.skillTitle ?? "Petits sujets"}
      >
        {error && <div className={s.error}>{error}</div>}

        {!attempt ? (
          <div className={s.pending}>
            <div className={s.spinner} />
            <p className={s.pendingText}>Chargement…</p>
          </div>
        ) : (
          <section className={`${s.card} ${s.panel} ${s.result}`}>
            {/* Accusé de traitement : le sujet compte, la progression a bougé. */}
            <div className={s.resultTitle}>
              <span className={s.check} aria-hidden>
                <Check size={20} strokeWidth={3} />
              </span>
              <div>
                <h1 className={s.resultHeading}>Sujet marqué comme traité</h1>
                <p className={s.resultSub}>
                  La progression de la compétence a été mise à jour.
                </p>
              </div>
            </div>

            <div className={s.answerBox}>
              <span className={s.answerLabel}>Ta production</span>
              {/* L'oral conserve son audio : se réécouter en lisant le retour
                  est la moitié de la valeur de l'exercice. Même lecteur que
                  l'enregistreur (`EoRecordingForm`) — l'URL R2 est présignée
                  15 min, `preload="metadata"` évite de la consommer pour rien. */}
              {attempt.audioUrl && (
                <div className={s.player}>
                  <audio src={attempt.audioUrl} controls preload="metadata" />
                </div>
              )}
              {attempt.writtenProduction && (
                <p className={s.prodText}>{attempt.writtenProduction}</p>
              )}
              {attempt.transcript && (
                <>
                  <span className={s.transcriptLabel}>Transcription</span>
                  <p className={s.prodText}>{attempt.transcript}</p>
                </>
              )}
              {!attempt.writtenProduction && !attempt.audioUrl && (
                <p className={s.prodText}>Production indisponible.</p>
              )}
              {(attempt.audioDurationSec != null ||
                attempt.wordsCount != null ||
                attempt.selfEvaluation) && (
                <div className={s.chips}>
                  {attempt.audioDurationSec != null && (
                    <span className={s.chip}>
                      <Clock size={11} strokeWidth={2.4} aria-hidden />
                      {formatDurationSec(attempt.audioDurationSec)}
                    </span>
                  )}
                  {attempt.audioDurationSec == null && attempt.wordsCount != null && (
                    <span className={s.chip}>
                      {attempt.wordsCount} mot{attempt.wordsCount > 1 ? "s" : ""}
                    </span>
                  )}
                  {attempt.selfEvaluation && (
                    <span className={s.chip}>
                      Ton ressenti : {SKILL_SELF_EVALUATION_LABEL[attempt.selfEvaluation]}
                    </span>
                  )}
                </div>
              )}
            </div>

            {pending ? (
              <div className={s.pending}>
                <div className={s.spinner} />
                <p className={s.pendingText}>
                  {attempt.statut === "TRANSCRIBING"
                    ? "Transcription de ton enregistrement…"
                    : "Analyse de ta réponse…"}
                </p>
              </div>
            ) : failed ? (
              <div className={s.invite}>
                <div className={s.inviteBody}>
                  <p className={s.inviteTitle}>L&apos;analyse n&apos;a pas abouti</p>
                  <p className={s.inviteSub}>
                    {attempt.errorMessage ??
                      "Ta production est bien enregistrée. Tu peux relancer l'analyse."}
                  </p>
                </div>
                <button
                  type="button"
                  className="btn"
                  disabled={retrying}
                  onClick={() => void retry()}
                >
                  <RefreshCw size={15} strokeWidth={2.2} aria-hidden />
                  {retrying ? "Relance…" : "Relancer l'analyse"}
                </button>
              </div>
            ) : (
              <AnalysisPanel
                analysis={analysis}
                locked={!analysis && recorded && !analysisAllowed}
                onUnlock={() => setPaywallOpen(true)}
                onRequest={() => router.push(`${base}/${skillId}/${promptId}`)}
              />
            )}

            <CompetenceReferences references={references} />

            <div className={s.actions}>
              <button
                type="button"
                className="btn btn-ghost"
                onClick={() => router.push(`${base}/${skillId}`)}
              >
                Retour aux petits sujets
              </button>
              <button
                type="button"
                className="btn btn-ghost"
                onClick={() => router.push(`${base}/${skillId}/${promptId}`)}
              >
                <RefreshCw size={15} strokeWidth={2.2} aria-hidden />
                Refaire ce sujet
              </button>
              <button
                type="button"
                className={`btn ${s.actionWide}`}
                disabled={!nextId}
                title={nextId ? undefined : "Tous les sujets de cette compétence ont été traités."}
                onClick={() => nextId && router.push(`${base}/${skillId}/${nextId}`)}
              >
                Sujet suivant à travailler
                <ArrowRight size={16} strokeWidth={2.2} aria-hidden />
              </button>
            </div>
          </section>
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title="Analyses IA illimitées"
          message="Tes analyses offertes ont été utilisées. L'abonnement Intégral ouvre l'analyse ciblée sur tous les petits sujets. Produire, t'auto-évaluer et lire les trois références restent gratuits."
        />
      </SkillShell>
    </DualChromeShell>
  );
}

/**
 * Bandeau « Analyse IA du critère » et son bloc repliable.
 *
 * Le bandeau est **toujours** là, ce qui change c'est ce que fait son bouton :
 * dépliage quand l'analyse existe (« Voir » ⇄ « Masquer »), ouverture de
 * l'offre quand le quota d'analyses offertes est épuisé, relance de l'exercice
 * quand il reste des analyses mais que la production a été enregistrée sans.
 * Un bandeau qui disparaîtrait ne dirait jamais au candidat ce qu'il rate.
 */
function AnalysisPanel({
  analysis,
  locked,
  onUnlock,
  onRequest,
}: {
  analysis: SkillAnalysisDto | null;
  locked: boolean;
  onUnlock: () => void;
  onRequest: () => void;
}) {
  const [open, setOpen] = useState(false);
  const panelId = useId();

  const tone = analysis ? VERDICT_TONE[analysis.status] : null;

  return (
    <>
      <div className={s.premium}>
        <span className={s.spark} aria-hidden>
          <Sparkles size={18} strokeWidth={2.2} />
        </span>
        <div className={s.premiumCopy}>
          <strong className={s.premiumTitle}>Analyse IA du critère</strong>
          <span className={s.premiumHint}>
            {analysis
              ? "Verdict, point réussi, priorité et reformulation courte."
              : locked
                ? "Tes analyses offertes ont été utilisées. Tes références restent accessibles."
                : "Ta production a été enregistrée sans analyse. Refais le sujet en cochant l'analyse."}
          </span>
        </div>
        <button
          type="button"
          className={s.unlock}
          aria-expanded={analysis ? open : undefined}
          aria-controls={analysis ? panelId : undefined}
          onClick={() => {
            if (analysis) setOpen((o) => !o);
            else if (locked) onUnlock();
            else onRequest();
          }}
        >
          {analysis ? (open ? "Masquer" : "Voir") : locked ? "Débloquer" : "Analyser"}
        </button>
      </div>

      {analysis && open && tone && (
        <div className={s.aiPanel} id={panelId}>
          <div className={`${s.verdict} ${tone.card}`}>
            <div className={s.verdictTop}>
              <span className={s.verdictLabel}>Critère unique</span>
              <span className={`${s.status} ${tone.status}`}>
                {analysis.status === "VALIDATED" ? (
                  <Check size={12} strokeWidth={2.8} aria-hidden />
                ) : (
                  <Target size={11} strokeWidth={2.4} aria-hidden />
                )}
                {SKILL_CRITERION_STATUS_LABEL[analysis.status]}
              </span>
            </div>
            <p className={s.verdictText}>{analysis.verdict}</p>
          </div>

          <div className={s.feedbackGrid}>
            <div className={s.feedbackItem}>
              <span className={`${s.feedbackIcon} ${s.feedbackIconGood}`} aria-hidden>
                <Check size={16} strokeWidth={2.8} />
              </span>
              <div>
                <strong className={s.feedbackTitle}>Ce qui est réussi</strong>
                <p className={s.feedbackText}>{analysis.successPoint}</p>
              </div>
            </div>
            <div className={s.feedbackItem}>
              <span className={`${s.feedbackIcon} ${s.feedbackIconFocus}`} aria-hidden>
                <TrendingUp size={16} strokeWidth={2.4} />
              </span>
              <div>
                <strong className={s.feedbackTitle}>À travailler en priorité</strong>
                <p className={s.feedbackText}>{analysis.improvementPriority}</p>
              </div>
            </div>
          </div>

          <div className={s.rewrite}>
            <strong className={s.rewriteLabel}>Proposition améliorée</strong>
            <p className={s.rewriteText}>{analysis.improvedVersion}</p>
            <small className={s.rewriteNote}>
              Exemple de reformulation : ce n&apos;est pas la seule bonne réponse, et ton
              idée doit être conservée.
            </small>
          </div>
        </div>
      )}
    </>
  );
}
