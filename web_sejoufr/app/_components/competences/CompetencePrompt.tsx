"use client";

import {useParams, useRouter} from "next/navigation";
import {useCallback, useEffect, useState} from "react";
import {Check, Lock, Mic, PenLine, Sparkles} from "lucide-react";
import {ApiException, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {answerStarterOf, tipOf} from "@/lib/skill-guidance";
import {findSkillProgress, type SkillProgress} from "@/lib/skill-progress";
import {handleStartFailure} from "@/lib/start-failure";
import {
  type ProductionTaskDto,
  type SkillAnalysisQuotaDto,
  type SkillPromptDto,
  type SkillSelfEvaluation,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {clearEeDraft, EeWritingForm, setEeDraft} from "@/app/_components/production/EeWritingForm";
import {EoRecordingForm} from "@/app/_components/production/EoRecordingForm";
import {type ProductionConfig} from "@/app/_components/production/config";
import {PromptGuidance} from "./PromptGuidance";
import {SelfEvaluationPicker} from "./SelfEvaluationPicker";
import {SkillShell} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * Adapte un petit sujet au contrat `ProductionTaskDto` attendu par
 * `EeWritingForm` / `EoRecordingForm`. On réutilise ces deux formulaires tels
 * quels — brouillon local, compteur de mots, capture micro, réécoute et
 * diagnostic d'autorisation sont déjà résolus là-bas, et les dupliquer serait
 * la garantie de les voir diverger.
 *
 * Les bornes de longueur sont **transmises** (et non plus annulées) : le
 * formulaire les affiche et **avertit** quand on en sort, sans jamais bloquer
 * la soumission — c'est le drapeau `lengthAdvisory` qui fait la différence
 * (spec §8 règle 15 : une production courte qui satisfait le critère est
 * valide).
 */
function toProductionTask(prompt: SkillPromptDto, tacheNumero: number): ProductionTaskDto {
  const oral = prompt.section === "EO";
  return {
    id: prompt.id,
    epreuve: oral ? "TCF_EO" : "TCF_EE",
    tacheNumero,
    niveauCible: prompt.skillTargetLevel,
    consigne: prompt.instruction,
    contexte: prompt.context,
    dureeMaxSec: oral ? prompt.recommendedDurationSeconds : null,
    dureeMinSec: null,
    motsMin: oral ? null : prompt.recommendedMinWords,
    motsMax: oral ? null : prompt.recommendedMaxWords,
  };
}

/** Libellé de l'option d'analyse IA, identique que la case soit ouverte ou
 *  verrouillée — seul le contrôle qui la porte change. */
function AnalysisCopy({allowed}: {allowed: boolean}) {
  return (
    <span className={s.analysisBody}>
      <span className={s.analysisTitle}>
        <Sparkles size={13} strokeWidth={2.4} aria-hidden />
        Analyser ma réponse avec l&apos;IA
      </span>
      <span className={s.analysisHint}>
        {allowed
          ? "Un retour court sur le seul critère de ce sujet. Décochez pour enregistrer votre production sans analyse : les trois références resteront accessibles."
          : "Vos analyses offertes ont été utilisées. Vous pouvez toujours produire, vous auto-évaluer et lire les trois références."}
      </span>
    </span>
  );
}

/**
 * Niveau 5 de la spec — un petit sujet.
 *
 * **L'écran ne raconte plus l'exercice, il le fait faire.** La version
 * précédente ouvrait sur un fil d'Ariane à deux lignes, deux badges, un titre
 * d'intention, un paragraphe d'objectif, l'encart « Compétence évaluée » et
 * l'encart « Pourquoi cet exercice ? » : la zone de production arrivait très
 * loin sous la ligne de flottaison, et le candidat lisait une leçon au lieu de
 * produire. Tout cela est supprimé.
 *
 * Structure, de haut en bas (maquette client, **identique à l'écrit et à
 * l'oral**) : ligne compacte `Sujet i/N` + palier · barre de progression ·
 * carte **« Ce qu'il faut faire »** (la check-list du sujet) · carte
 * **« Situation »** · puces de contrainte · carte **« Votre réponse »** (champ
 * ou enregistreur, astuce et compteur en pied) · auto-évaluation **sous** la
 * zone de production · actions.
 *
 * Rien du **comportement** ne bouge : brouillon local, compteur de mots,
 * auto-soumission, capture micro, quota d'analyses IA et paywall sont ceux des
 * formulaires partagés, pilotés par des props **optionnelles** dont les écrans
 * de production TCF n'ont pas connaissance.
 *
 * Les trois références restent invisibles jusqu'à la validation (§13.2) : voir
 * le modèle avant d'écrire, c'est ne plus s'entraîner mais recopier — et c'est
 * exactement ce que le rappel ambre explique au candidat.
 */
export function CompetencePrompt({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string; skillId: string; promptId: string}>();
  const n = Number(params?.n ?? "0");
  const skillId = params?.skillId ?? "";
  const promptId = params?.promptId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const base = `${config.base}/tache/${n}/competences`;
  const oral = config.mode === "audio";

  const [prompt, setPrompt] = useState<SkillPromptDto | null>(null);
  const [skillProgress, setSkillProgress] = useState<SkillProgress | null>(null);
  const [quota, setQuota] = useState<SkillAnalysisQuotaDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [selfEval, setSelfEval] = useState<SkillSelfEvaluation | null>(null);
  const [wantAnalysis, setWantAnalysis] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  // Remonte `EeWritingForm` après « Reprendre ma réponse » : le formulaire relit
  // son brouillon au montage, c'est donc un changement de `key` qui l'applique.
  const [resumeKey, setResumeKey] = useState(0);
  const [resuming, setResuming] = useState(false);

  // Un seul appel bloquant : le sujet porte lui-même le nom de sa compétence,
  // son explication et son nombre de sujets — aller relire la compétence pour
  // trois textes serait un aller-retour réseau de plus sur le chemin critique.
  useEffect(() => {
    if (status !== "authenticated" || !promptId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    skillApi
      .getPrompt(promptId)
      .then((p) => {
        if (!cancelled) setPrompt(p);
      })
      .catch((e) => {
        if (!cancelled)
          setLoadError(e instanceof ApiException ? e.message : "Impossible de charger ce sujet.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, promptId]);

  // Progression de la compétence (« 2/5 »). Aucun DTO ne la porte pour un sujet
  // isolé : on la dérive de la liste des compétences de la tâche, déjà servie
  // par l'API. Appel **non bloquant** et hors chemin critique — la barre
  // apparaît quand elle arrive, l'écran s'affiche sans elle.
  useEffect(() => {
    if (status !== "authenticated" || !prompt) return;
    let cancelled = false;
    skillApi
      .listSkills(prompt.taskCode)
      .then((list) => {
        if (!cancelled) setSkillProgress(findSkillProgress(list, prompt.skillId));
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, prompt]);

  // Quota d'analyses IA : un compte gratuit en a 3 à vie. Un échec de lecture
  // n'empêche jamais de produire — c'est le backend qui tranche à la soumission.
  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    skillApi
      .analysisQuota()
      .then((q) => {
        if (cancelled) return;
        setQuota(q);
        if (q.remaining === 0) setWantAnalysis(false);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status]);

  const analysisAllowed = quota == null || quota.remaining !== 0;

  const submit = useCallback(
    async (payload: {texte?: string; audio?: Blob; durationSec?: number}) => {
      if (submitting) return;
      setSubmitError(null);
      setSubmitting(true);
      const requestAnalysis = wantAnalysis && analysisAllowed;
      try {
        const attempt =
          payload.audio != null
            ? await skillApi.submitAudio({
                skillPromptId: promptId,
                audio: payload.audio,
                durationSec: payload.durationSec ?? 0,
                selfEvaluation: selfEval,
                requestAnalysis,
              })
            : await skillApi.submitText({
                skillPromptId: promptId,
                texte: payload.texte ?? "",
                selfEvaluation: selfEval,
                requestAnalysis,
              });
        if (!oral) clearEeDraft(promptId);
        router.push(`${base}/${skillId}/${promptId}/resultat/${attempt.id}`);
      } catch (e) {
        handleStartFailure(e, {
          onPaywall: () => setPaywallOpen(true),
          onMessage: setSubmitError,
          fallbackMessage: "Impossible d'enregistrer votre réponse.",
        });
        setSubmitting(false);
      }
    },
    [submitting, wantAnalysis, analysisAllowed, promptId, selfEval, oral, router, base, skillId],
  );

  /** Recharge la production précédente dans la zone de saisie (§13.5, EE). */
  async function resumeLastAnswer() {
    if (!prompt?.lastAttemptId || resuming) return;
    setResuming(true);
    try {
      const last = await skillApi.getAttempt(prompt.lastAttemptId);
      if (last.writtenProduction) {
        setEeDraft(promptId, last.writtenProduction);
        setResumeKey((k) => k + 1);
      }
    } catch {
      setSubmitError("Impossible de récupérer votre réponse précédente.");
    } finally {
      setResuming(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${base}/${skillId}/${promptId}`} />;

  const total = prompt?.skillPromptCount ?? 0;
  const task = prompt ? toProductionTask(prompt, n) : null;
  const alreadyDone = (prompt?.attemptCount ?? 0) > 0;

  /* Ce qu'il faut faire · la situation · les contraintes. Remplace la carte
     d'exercice générique des formulaires partagés. */
  const promptSlot = prompt ? <PromptGuidance prompt={prompt} oral={oral} /> : null;

  /* Amorce et astuce se dégradent en silence : sans amorce, le champ garde un
     texte grisé neutre ; sans astuce, le pied n'affiche que le compteur. */
  const starter = prompt ? answerStarterOf(prompt) : null;
  const tip = prompt ? tipOf(prompt) : null;

  const footerSlot = (
    <>
      <SelfEvaluationPicker value={selfEval} disabled={submitting} onChange={setSelfEval} />

      <div className={s.analysisBlock}>
        {analysisAllowed ? (
          <label className={s.analysisRow}>
            <input
              type="checkbox"
              className={s.analysisCheck}
              checked={wantAnalysis}
              disabled={submitting}
              onChange={(e) => setWantAnalysis(e.target.checked)}
            />
            <AnalysisCopy allowed />
          </label>
        ) : (
          /* Quota épuisé : un vrai bouton, donc atteignable au clavier — une
             case désactivée ne l'aurait pas été, et l'offre serait restée
             hors de portée. */
          <button type="button" className={s.analysisRow} onClick={() => setPaywallOpen(true)}>
            <span className={s.analysisLock} aria-hidden>
              <Lock size={14} strokeWidth={2.4} />
            </span>
            <AnalysisCopy allowed={false} />
          </button>
        )}
        {quota && !quota.unlimited && (
          <span className={s.quota}>
            {Math.max(0, quota.remaining)} analyse{quota.remaining > 1 ? "s" : ""} offerte
            {quota.remaining > 1 ? "s" : ""} sur {quota.freeAnalysesTotal}
          </span>
        )}
      </div>

      {/* Dit POURQUOI les références sont masquées — sans elle, le candidat
          croit à un contenu verrouillé plutôt qu'à une règle d'entraînement. */}
      <p className={s.tipline}>
        <b>Important :</b>
        <span>
          Les exemples de référence et l&apos;analyse apparaissent seulement après votre
          production.
        </span>
      </p>
    </>
  );

  return (
    <DualChromeShell>
      <SkillShell
        config={config}
        backHref={`${base}/${skillId}`}
        backLabel={prompt?.skillTitle ?? "Petits sujets"}
      >
        {loadError && <div className={s.error}>{loadError}</div>}

        {loading ? (
          <p className={s.empty}>Chargement du sujet…</p>
        ) : !prompt || !task ? (
          <p className={s.empty}>Sujet introuvable.</p>
        ) : (
          <>
            {/* Où j'en suis et à quel palier, en une ligne. L'ancien fil
                d'Ariane disait la même chose sur deux lignes, en plus long. */}
            <div className={s.compactLine}>
              <span className={s.compactStep}>
                Sujet {prompt.displayOrder}
                {total > 0 ? `/${total}` : ""}
              </span>
              <span className={`${s.badge} ${s.levelPill}`}>{prompt.skillTargetLevel}</span>
            </div>

            {skillProgress && skillProgress.total > 0 && (
              <div className={s.inlineProgress}>
                <div className={s.inlineProgressLabel}>
                  <span>Progression</span>
                  <span>
                    {skillProgress.attempted}/{skillProgress.total}
                  </span>
                </div>
                <span className={s.rail}>
                  <span
                    className={s.railFill}
                    style={{width: `${skillProgress.percent}%`}}
                  />
                </span>
              </div>
            )}

            {alreadyDone && (
              <div className={s.previous}>
                <span className={s.previousIcon} aria-hidden>
                  <Check size={18} strokeWidth={2.8} />
                </span>
                <div className={s.previousBody}>
                  <strong className={s.previousTitle}>Sujet déjà traité</strong>
                  <span className={s.previousText}>
                    {prompt.attemptCount} tentative{prompt.attemptCount > 1 ? "s" : ""}. Le
                    refaire n&apos;efface rien : chaque essai s&apos;ajoute à votre
                    historique.
                  </span>
                </div>
                {/* Une seule action, aux libellés gelés par le contrat (parité
                    mot pour mot avec le mobile) : l'écrit se reprend dans la
                    zone de saisie, l'oral se réécoute sur son écran de résultat
                    — un enregistrement ne se « reprend » pas. */}
                {prompt.lastAttemptId &&
                  (oral ? (
                    <button
                      type="button"
                      className={s.previousAction}
                      onClick={() =>
                        router.push(
                          `${base}/${skillId}/${promptId}/resultat/${prompt.lastAttemptId}`,
                        )
                      }
                    >
                      Écouter ma dernière réponse
                    </button>
                  ) : (
                    <button
                      type="button"
                      className={s.previousAction}
                      disabled={resuming}
                      onClick={resumeLastAnswer}
                    >
                      {resuming ? "Chargement…" : "Reprendre ma réponse"}
                    </button>
                  ))}
              </div>
            )}

            <div className={s.formStack}>
              {oral ? (
                <EoRecordingForm
                  task={task}
                  submitting={submitting}
                  error={submitError}
                  submitLabel="Valider et comparer"
                  promptSlot={promptSlot}
                  criteriaSlot={null}
                  answerCard={{
                    title: "Votre réponse",
                    icon: <Mic size={16} strokeWidth={2.2} />,
                    starter,
                    tip,
                  }}
                  footerSlot={footerSlot}
                  onSubmit={(audio, durationSec) => void submit({audio, durationSec})}
                />
              ) : (
                <EeWritingForm
                  key={`${promptId}-${resumeKey}`}
                  task={task}
                  submitting={submitting}
                  error={submitError}
                  submitLabel="Valider et comparer"
                  promptSlot={promptSlot}
                  criteriaSlot={null}
                  answerCard={{
                    title: "Votre réponse",
                    icon: <PenLine size={16} strokeWidth={2.2} />,
                    placeholder: starter,
                    tip,
                  }}
                  footerSlot={footerSlot}
                  lengthAdvisory
                  clearLabel="Effacer"
                  onSubmit={(texte) => void submit({texte})}
                />
              )}
            </div>
          </>
        )}

        <PaywallSheet
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title="Analyses IA illimitées"
          message="Vos analyses offertes ont été utilisées. L'abonnement Intégral ouvre l'analyse ciblée sur tous les petits sujets. Produire, s'auto-évaluer et lire les trois références restent gratuits."
        />
      </SkillShell>
    </DualChromeShell>
  );
}
