"use client";

import {useParams, useRouter, useSearchParams} from "next/navigation";
import {useCallback, useEffect, useState} from "react";
import {Check, Mic, PenLine} from "lucide-react";
import {ApiException, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  answerStarterOf,
  SKILL_ANALYSIS_MAX_AUDIO_SEC,
  SKILL_ANALYSIS_MAX_WORDS,
  tipOf,
} from "@/lib/skill-guidance";
import {useSubmissionKey} from "@/lib/idempotency";
import {isPlanStep, withPlanStep} from "@/lib/plan-step";
import {loadSectionSkills} from "@/lib/skill-catalog";
import {findSkillProgress, type SkillProgress} from "@/lib/skill-progress";
import {handleStartFailure} from "@/lib/start-failure";
import {
  type ProductionTaskDto,
  type SkillAnalysisQuotaDto,
  type SkillPromptDto,
  skillSectionOf,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {clearEeDraft, EeWritingForm, setEeDraft} from "@/app/_components/production/EeWritingForm";
import {EoRecordingForm} from "@/app/_components/production/EoRecordingForm";
import {type ProductionConfig} from "@/app/_components/production/config";
import {PromptGuidance} from "./PromptGuidance";
import {SkillLockedCard, SkillShell} from "@/app/_components/skill-ui/SkillLayout";
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
    // Un petit sujet a son propre chrome (« Sujet i/N ») : aucun titre de
    // carte de sujet TCF à emprunter ici.
    titre: null,
    consigne: prompt.instruction,
    contexte: prompt.context,
    dureeMaxSec: oral ? prompt.recommendedDurationSeconds : null,
    dureeMinSec: null,
    motsMin: oral ? null : prompt.recommendedMinWords,
    motsMax: oral ? null : prompt.recommendedMaxWords,
  };
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
 * **« Situation »** · puces de contrainte · carte **« Ta réponse »** (champ
 * ou enregistreur, astuce et compteur en pied) · actions.
 *
 * **L'analyse IA n'est pas une option** (décision client) : il n'y a plus de
 * case à cocher, elle est demandée dès que le candidat y a droit — abonné, ou
 * compte gratuit avec des analyses offertes restantes. Quand le quota est
 * épuisé, la production part **sans** analyse au lieu d'échouer en 403, et
 * c'est l'écran de résultat qui invite à s'abonner. Seule subsiste une
 * information sobre du reliquat : sans elle, un compte gratuit consommerait
 * un de ses essais sans le savoir.
 *
 * **L'auto-évaluation est supprimée** (parité mobile) : elle était
 * déclarative et sans effet, et elle coûtait une décision de plus avant de
 * produire. Le champ `selfEvaluation` reste optionnel côté API — on ne
 * l'envoie simplement plus.
 *
 * **Le candidat est tutoyé** dans tout le chrome de cet écran (décision
 * client) ; le texte du sujet, lui, vient de la base et garde le vouvoiement de
 * l'énoncé d'examen. Les deux formulaires partagés reçoivent donc
 * `voice="tutoiement"` — ils vouvoient par défaut, pour les écrans de
 * production TCF.
 *
 * Rien du **comportement** des formulaires ne bouge : brouillon local,
 * compteur de mots, auto-soumission, capture micro et paywall sont ceux des
 * formulaires partagés, pilotés par des props **optionnelles** dont les écrans
 * de production TCF n'ont pas connaissance.
 *
 * Les trois références restent invisibles jusqu'à la validation (§13.2) : voir
 * le modèle avant d'écrire, c'est ne plus s'entraîner mais recopier — et c'est
 * exactement ce que le rappel ambre explique au candidat.
 */
export function CompetencePrompt({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string; skillId: string; promptId: string}>();
  const searchParams = useSearchParams();
  const n = Number(params?.n ?? "0");
  const skillId = params?.skillId ?? "";
  const promptId = params?.promptId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const base = `${config.base}/tache/${n}/competences`;
  /* Le marqueur d'étape se propage : venu du Plan, le candidat doit retrouver
     l'étape (les 5 sujets, « 2/5 ») en remontant, pas la fiche des 15 — c'est
     ce que fait naturellement le « retour » du mobile, qui dépile. */
  const step = isPlanStep(searchParams);
  const skillHref = withPlanStep(`${base}/${skillId}`, step);
  const oral = config.mode === "audio";

  const [prompt, setPrompt] = useState<SkillPromptDto | null>(null);
  const [skillProgress, setSkillProgress] = useState<SkillProgress | null>(null);
  const [quota, setQuota] = useState<SkillAnalysisQuotaDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  // Une cle par sujet : renvoyer la meme production apres une coupure ne doit

  // pas consommer une seconde des analyses offertes.

  const submissionKey = useSubmissionKey();

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
  // isolé : on la dérive de la liste des compétences de l'épreuve, déjà chargée
  // par l'écran d'où l'on vient — donc **sans appel réseau** dans le cas normal.
  // Non bloquant : la barre apparaît quand elle arrive, l'écran s'affiche sans elle.
  useEffect(() => {
    if (status !== "authenticated" || !prompt) return;
    let cancelled = false;
    void loadSectionSkills(skillApi, skillSectionOf(config.epreuve))
      .then((list) => {
        if (!cancelled) setSkillProgress(findSkillProgress(list, prompt.skillId));
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, prompt, config.epreuve]);

  // Quota d'analyses IA : un compte gratuit en a 3 à vie. Un échec de lecture
  // n'empêche jamais de produire — c'est le backend qui tranche à la soumission.
  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    skillApi
      .analysisQuota()
      .then((q) => {
        if (!cancelled) setQuota(q);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status]);

  /* Le droit à l'analyse, et rien d'autre : `remaining === -1` vaut illimité,
     un quota non chargé laisse trancher le backend. Quand il vaut faux, la
     production part quand même — sans analyse, jamais en erreur. */
  const analysisAllowed = quota == null || quota.remaining !== 0;

  /* Reliquat à annoncer : seulement à un compte gratuit qui a encore des
     analyses. À zéro, on ne dit rien ici — c'est l'écran de résultat qui
     porte l'invitation à s'abonner, une fois la production faite. */
  const freeAnalysesLeft =
    quota && !quota.unlimited && quota.remaining > 0 ? quota.remaining : null;

  const submit = useCallback(
    async (payload: {texte?: string; audio?: Blob; durationSec?: number}) => {
      if (submitting) return;
      setSubmitError(null);
      setSubmitting(true);
      // L'analyse est le comportement naturel : on la demande dès que le
      // candidat y a droit. Quota épuisé ⇒ on soumet quand même, sans elle —
      // demander une analyse interdite renverrait un 403 et ferait perdre la
      // production, alors que l'écran de résultat sait inviter à s'abonner.
      const requestAnalysis = analysisAllowed;
      try {
        const attempt =
          payload.audio != null
            ? await skillApi.submitAudio({
                skillPromptId: promptId,
                audio: payload.audio,
                durationSec: payload.durationSec ?? 0,
                requestAnalysis,
                clientSubmissionId: submissionKey(promptId),
              })
            : await skillApi.submitText({
                skillPromptId: promptId,
                texte: payload.texte ?? "",
                requestAnalysis,
                clientSubmissionId: submissionKey(promptId),
              });
        if (!oral) clearEeDraft(promptId);
        router.push(withPlanStep(`${base}/${skillId}/${promptId}/resultat/${attempt.id}`, step));
      } catch (e) {
        handleStartFailure(e, {
          onPaywall: () => setPaywallOpen(true),
          onMessage: setSubmitError,
          fallbackMessage: "Impossible d'enregistrer ta réponse.",
        });
        setSubmitting(false);
      }
    },
    [submitting, analysisAllowed, promptId, oral, router, base, skillId, step, submissionKey],
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
      setSubmitError("Impossible de récupérer ta réponse précédente.");
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
      {/* Plafond **serveur** de longueur, annoncé avant d'écrire : au-delà, la
          correction est refusée et la production est perdue. Il ne remplace pas
          la fourchette conseillée du sujet, qui reste indicative et n'empêche
          jamais de valider. Muet à l'oral — c'est la capture qui y est bornée. */}
      {!oral && (
        <p className={s.tipline}>
          <b>Longueur maximale :</b>
          <span>
            Au-delà de {SKILL_ANALYSIS_MAX_WORDS} mots, la correction peut être refusée. Ce
            sujet se traite en quelques phrases.
          </span>
        </p>
      )}

      {/* Information, plus une décision : le candidat doit savoir qu'il va
          consommer un de ses essais offerts. La retirer reviendrait à le lui
          prélever en silence. Rien à zéro — l'invitation à s'abonner vit sur
          l'écran de résultat, après la production. */}
      {freeAnalysesLeft != null && (
        <span className={s.quota}>
          Il te reste {freeAnalysesLeft} analyse{freeAnalysesLeft > 1 ? "s" : ""} offerte
          {freeAnalysesLeft > 1 ? "s" : ""}
        </span>
      )}

      {/* Dit POURQUOI les références sont masquées — sans elle, le candidat
          croit à un contenu verrouillé plutôt qu'à une règle d'entraînement. */}
      <p className={s.tipline}>
        <b>Important :</b>
        <span>
          Les exemples de référence et l&apos;analyse apparaissent seulement après ta
          production.
        </span>
      </p>
    </>
  );

  return (
    <DualChromeShell>
      {/* L'en-tête nomme LE SUJET, pas la compétence (parité mobile,
          `competence_prompt_screen`). Le candidat est ici pour produire une
          réponse à ce sujet-là ; la compétence est déjà annoncée par l'écran
          d'où il vient, et la répéter en titre lui laissait vingt sujets
          impossibles à distinguer les uns des autres. Elle reste le libellé du
          retour et la pastille de la carte de résumé. */}
      <SkillShell
        backHref={skillHref}
        backLabel={prompt?.skillTitle ?? "Petits sujets"}
        title={prompt?.title}
        meta={prompt?.taskTitle}
      >
        {loadError && <div className={s.error}>{loadError}</div>}

        {loading ? (
          <p className={s.empty}>Chargement du sujet…</p>
        ) : !prompt || !task ? (
          <p className={s.empty}>Sujet introuvable.</p>
        ) : prompt.locked ? (
          /* Sujet verrouillé atteint par son URL (lien, historique, retour
             arrière). On garde le repère « où suis-je » et on retire la zone de
             production : le serveur refuserait la soumission en 403, et laisser
             produire pour rien ferait perdre la réponse au candidat. Le contenu
             du sujet n'est pas déroulé — il fait partie de ce qui s'achète. */
          <>
            <div className={s.compactLine}>
              <span className={s.compactStep}>
                Sujet {prompt.displayOrder}
                {total > 0 ? `/${total}` : ""}
              </span>
              <span className={`${s.badge} ${s.levelPill}`}>{prompt.skillTargetLevel}</span>
            </div>
            <SkillLockedCard
              title="Ce sujet demande l'abonnement Intégral"
              text="L'abonnement ouvre tous les petits sujets de chaque compétence et l'analyse IA sans limite. Ton plan personnalisé et tes résultats déjà obtenus, eux, restent visibles."
            />
          </>
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
                    refaire n&apos;efface rien : chaque essai s&apos;ajoute à ton
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
                          withPlanStep(
                            `${base}/${skillId}/${promptId}/resultat/${prompt.lastAttemptId}`,
                            step,
                          ),
                        )
                      }
                    >
                      Relire ma dernière réponse
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
                    title: "Ta réponse",
                    icon: <Mic size={16} strokeWidth={2.2} />,
                    starter,
                    tip,
                  }}
                  footerSlot={footerSlot}
                  /* Ce pied se lit AVANT de parler : il annonce qu'un des
                     essais d'analyse offerts va être consommé, et le rappel
                     sur les références n'a plus d'objet une fois la prise
                     faite. */
                  footerAlwaysVisible
                  maxDurationSec={SKILL_ANALYSIS_MAX_AUDIO_SEC}
                  voice="tutoiement"
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
                    title: "Ta réponse",
                    icon: <PenLine size={16} strokeWidth={2.2} />,
                    placeholder: starter,
                    tip,
                  }}
                  footerSlot={footerSlot}
                  voice="tutoiement"
                  lengthAdvisory
                  clearLabel="Effacer"
                  onSubmit={(texte) => void submit({texte})}
                />
              )}
            </div>
          </>
        )}

        <PaywallSheet ctaLocation="AI_CORRECTION" screen="competence_sujet"
          open={paywallOpen}
          onClose={() => setPaywallOpen(false)}
          module="INTEGRAL"
          title="Analyses IA illimitées"
          message="Tes analyses offertes ont été utilisées. L'abonnement Intégral ouvre l'analyse ciblée sur tous les petits sujets. Produire et lire les trois références restent gratuits."
        />
      </SkillShell>
    </DualChromeShell>
  );
}
