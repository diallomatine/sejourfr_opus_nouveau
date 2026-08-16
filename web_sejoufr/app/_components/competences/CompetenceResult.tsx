"use client";

import {useParams, useRouter, useSearchParams} from "next/navigation";
import {useCallback, useEffect, useId, useState} from "react";
import {
  ArrowRight,
  Check,
  ChevronDown,
  Clock,
  RefreshCw,
  Sparkles,
  Target,
  TrendingUp,
} from "lucide-react";
import {ApiException, skillApi} from "@/lib/api";
import {isPlanStep, withPlanStep} from "@/lib/plan-step";
import {useAuth} from "@/lib/auth-context";
import {
  referencesOpenByDefault,
  skillNiveauViseMayStillArrive,
  skillResultAnalysisView,
  skillResultBannerAction,
  type SkillResultAnalysisView,
} from "@/lib/skill-result-view";
import {
  formatDurationSec,
  isSkillAttemptPending,
  SKILL_CRITERION_STATUS_LABEL,
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
import {CompetenceLevelCard} from "./CompetenceLevelCard";
import {CompetenceReferences} from "./CompetenceReferences";
import {
  ACTION_PLAN_EXEMPLE_TITLE,
  ACTION_PLAN_GRACE_MS,
  ActionPlanExemple,
  ActionPlanLeviers,
  ActionPlanMemoCard,
  ActionPlanPending,
  pourPasserAuTitle,
} from "@/app/_components/skill-ui/ActionPlan";
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
 * L'écran doit se comprendre en trois secondes : **où j'en suis** (la carte de
 * niveau et sa jauge), **ce qu'il me manque** (les leviers), **à quoi ça
 * ressemble quand c'est bien fait** (l'exemple annoté). Tout le texte affiché
 * est plafonné en mots côté serveur : aucune phrase d'accompagnement n'est
 * ajoutée ici.
 *
 * L'ordre est imposé et commun au mobile : bandeau de confirmation, verdict du
 * critère, niveau, leviers, exemple, mémo, **puis** la production — repliée,
 * jamais supprimée : à l'oral, se réécouter en lisant le retour est la moitié
 * de la valeur de l'exercice —, puis les références, puis les actions.
 *
 * **Deux générations d'analyses cohabitent sans migration.** Une analyse sans
 * `levelProgress` vient des contrats v1/v2 : elle retombe intégralement sur
 * l'affichage historique (point réussi / priorité / proposition améliorée). On
 * ne régresse jamais sur ce qui est déjà en base.
 *
 * Il n'y a ici **ni note /20 ni niveau d'épreuve** : le niveau rendu est celui
 * que **cette** micro-production démontre, dérivé serveur.
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
  const searchParams = useSearchParams();
  const router = useRouter();
  const {user, status} = useAuth();

  const base = `${config.base}/tache/${n}/competences`;
  /* Le marqueur d'étape se propage jusqu'ici : remonter d'un résultat doit
     ramener à l'étape (« 2/5 ») quand on est venu du Plan, pas à la fiche des
     15 sujets. Absent, tout se comporte exactement comme avant. */
  const step = isPlanStep(searchParams);
  const skillHref = withPlanStep(`${base}/${skillId}`, step);

  const [attempt, setAttempt] = useState<SkillAttemptDto | null>(null);
  const [prompt, setPrompt] = useState<SkillPromptDto | null>(null);
  const [references, setReferences] = useState<SkillReferenceDto[]>([]);
  const [quota, setQuota] = useState<SkillAnalysisQuotaDto | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [retrying, setRetrying] = useState(false);
  const [pollKey, setPollKey] = useState(0);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [niveauVisePending, setNiveauVisePending] = useState(false);
  const [prodOpen, setProdOpen] = useState(false);
  const prodPanelId = useId();

  // Poll tant que l'analyse est en vol (EO passe par TRANSCRIBING). Une
  // tentative RECORDED est finale : aucun appel inutile n'est déclenché.
  //
  // **Sursis après `EVALUATED`** : le bloc « pour viser X » vient d'un SECOND
  // appel, lancé une fois l'évaluation persistée. S'arrêter net sur
  // `EVALUATED` afficherait un écran sans leviers alors qu'ils arrivent une
  // seconde plus tard. La règle vit dans `lib/skill-result-view.ts` et sa durée
  // (`ACTION_PLAN_GRACE_MS`) est commune au rapport de production, qui attend
  // exactement le même bloc ; le budget global reste la borne dure, et pendant
  // le sursis la place du bloc porte un indicateur discret — jamais d'erreur.
  useEffect(() => {
    if (status !== "authenticated" || !attemptId) return;
    let cancelled = false;
    let polls = 0;
    let observedInFlight = false;
    let graceStartedAt: number | null = null;
    let timer: ReturnType<typeof setTimeout> | null = null;
    async function tick() {
      try {
        const a = await skillApi.getAttempt(attemptId);
        if (cancelled) return;
        setAttempt(a);

        let again = isSkillAttemptPending(a);
        // Vu en vol : l'analyse s'achève sous les yeux du candidat, donc le
        // second appel tourne encore. Un résultat rouvert plus tard n'entre
        // jamais ici — un seul appel, aucun sursis, aucun indicateur.
        if (again) observedInFlight = true;

        let pending = false;
        if (!again) {
          const waiting = skillNiveauViseMayStillArrive({
            evaluated: a.statut === "EVALUATED",
            observedInFlight,
            hasLevelProgress: a.analysis?.levelProgress != null,
            objectifAtteint: a.analysis?.levelProgress?.situation === "OBJECTIF_ATTEINT",
            hasNiveauVise: a.analysis?.niveauVise != null,
          });
          if (waiting) {
            graceStartedAt ??= Date.now();
            again = Date.now() - graceStartedAt < ACTION_PLAN_GRACE_MS;
            pending = again;
          }
        }

        const continues = again && polls < MAX_POLLS;
        // Fin du sursis sans rien : l'indicateur s'efface en silence. Il
        // s'efface AUSSI quand c'est le budget global qui coupe la boucle —
        // sans ce `continues`, plus aucun tirage ne viendrait le retirer et le
        // spinner resterait à l'écran indéfiniment (le mobile, lui, remet son
        // drapeau à faux dès que le budget est épuisé).
        setNiveauVisePending(pending && continues);

        if (continues) {
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

  const analysis = attempt?.analysis ?? null;
  const nextId = prompt?.nextPromptId ?? null;
  const view = skillResultAnalysisView({
    pending: attempt ? isSkillAttemptPending(attempt) : true,
    hasAnalysis: analysis != null,
    failed: attempt?.statut === "FAILED",
    analysisAllowed: quota == null || quota.remaining !== 0,
  });

  return (
    <DualChromeShell>
      {/* En-tête de sujet, miroir de `ScreenHeader` côté mobile : le **titre du
          sujet** et « compétence · épreuve ». Sans lui, l'écran ne disait pas
          quel sujet venait d'être traité — on arrivait sur un verdict orphelin.
          Sujet pas encore chargé ⇒ « Résultat », jamais un titre inventé. */}
      <SkillShell
        backHref={skillHref}
        backLabel={prompt?.skillTitle ?? "Petits sujets"}
        title={prompt?.title ?? "Résultat"}
        meta={prompt ? `${prompt.skillTitle} · ${config.label}` : config.label}
      >
        {error && <div className={s.error}>{error}</div>}

        {!attempt ? (
          <div className={s.pending}>
            <div className={s.spinner} />
            <p className={s.pendingText}>Chargement…</p>
          </div>
        ) : (
          /* ⚠️ **Pas de carte englobante.** Chaque bloc porte déjà sa propre
             surface (carte de niveau teintée, leviers en liste blanche, exemple,
             mémo ambre, dépliants, boîte de production) : les empiler dans une
             grande carte blanche écrasait la hiérarchie et faisait lire l'écran
             comme un seul pavé. Structure à plat, exactement comme la `ListView`
             du mobile. Ne pas y remettre `s.card` / `s.panel`. */
          <section className={s.result}>
            {/* Bandeau de confirmation : ce qui vient de se passer, puis la
                conséquence sur la progression.

                « Production analysée » n'est **pas** servi à une tentative sans
                analyse (`RECORDED`, quota épuisé, analyse en échec) : elle n'a
                pas été analysée, et l'annoncer serait faux. Ces états gardent
                l'accusé historique. Condition et libellés identiques au mobile
                (`_TreatedHeader`). */}
            <div className={s.resultTitle}>
              <span className={s.check} aria-hidden>
                <Check size={20} strokeWidth={3} />
              </span>
              <div>
                {/* `h2` et non `h1` : depuis que l'en-tête porte le titre du
                    sujet, c'est lui le titre de la page — deux `h1` mettraient
                    le lecteur d'écran devant deux titres concurrents. */}
                <h2 className={s.resultHeading}>
                  {analysis ? "Production analysée" : "Sujet marqué comme traité"}
                </h2>
                <p className={s.resultSub}>
                  {analysis
                    ? "Progression mise à jour"
                    : "La progression de la compétence a été mise à jour."}
                </p>
              </div>
            </div>

            {view === "PENDING" ? (
              <div className={s.pending}>
                <div className={s.spinner} />
                <p className={s.pendingText}>
                  {attempt.statut === "TRANSCRIBING"
                    ? "Transcription de ton enregistrement…"
                    : "Analyse de ta réponse…"}
                </p>
              </div>
            ) : analysis ? (
              <AnalysisView analysis={analysis} niveauVisePending={niveauVisePending} />
            ) : (
              <AnalysisBanner
                view={view}
                errorMessage={attempt.errorMessage}
                busy={retrying}
                onRetry={() => void retry()}
                onUnlock={() => setPaywallOpen(true)}
                onRequest={() => router.push(withPlanStep(`${base}/${skillId}/${promptId}`, step))}
              />
            )}

            {/* La production passe **après** le retour et s'ouvre repliée : elle
                n'est plus ce qu'on vient lire, mais elle reste à un clic — à
                l'oral pour se réécouter, à l'écrit pour se relire. */}
            <section className={s.refSection}>
              <button
                type="button"
                className={s.refToggle}
                aria-expanded={prodOpen}
                aria-controls={prodPanelId}
                onClick={() => setProdOpen((o) => !o)}
              >
                <span className={s.refToggleBody}>
                  <span className={s.refToggleTitle}>Ta production</span>
                </span>
                <span className={s.refToggleAction}>
                  {prodOpen ? "Masquer" : "Afficher"}
                  <ChevronDown
                    size={15}
                    strokeWidth={2.4}
                    aria-hidden
                    className={`${s.refChevron} ${prodOpen ? s.refChevronOpen : ""}`}
                  />
                </span>
              </button>

              {prodOpen && (
                <div id={prodPanelId} className={s.answerBox}>
                  {/* Intitulé + mesure en tête de carte, comme `_ProductionCard`
                      côté mobile : la durée ou le nombre de mots se lisent avec
                      la production, pas relégués sous elle. */}
                  <div className={s.prodHead}>
                    <span className={s.prodEyebrow}>TA PRODUCTION</span>
                    {attempt.audioDurationSec != null ? (
                      <span className={s.chip}>
                        <Clock size={11} strokeWidth={2.4} aria-hidden />
                        {formatDurationSec(attempt.audioDurationSec)}
                      </span>
                    ) : attempt.wordsCount != null ? (
                      <span className={s.chip}>
                        {attempt.wordsCount} mot{attempt.wordsCount > 1 ? "s" : ""}
                      </span>
                    ) : null}
                  </div>
                  {/* Pas de lecteur : l'enregistrement n'est pas conservé (il
                      sert à produire la transcription, puis il disparaît). Ce
                      qu'on rend d'une production orale, c'est son texte — la
                      réécoute existe avant l'envoi, dans `EoRecordingForm`. */}
                  {attempt.writtenProduction && (
                    <p className={s.prodText}>{attempt.writtenProduction}</p>
                  )}
                  {attempt.transcript && (
                    <>
                      <span className={s.transcriptLabel}>Transcription</span>
                      <p className={s.prodText}>{attempt.transcript}</p>
                    </>
                  )}
                  {/* À l'oral sans transcription, ce n'est pas une production
                      « indisponible » : elle est bien enregistrée, c'est la
                      transcription qui n'est produite qu'avec une analyse (on ne
                      paie pas Whisper pour rien). Phrase reprise mot pour mot du
                      mobile — l'ancienne laissait croire à une perte. */}
                  {!attempt.writtenProduction && !attempt.transcript && (
                    <p className={s.prodEmpty}>
                      {config.mode === "audio"
                        ? "Ta réponse orale est enregistrée. La transcription n'est produite que lorsqu'une analyse IA est demandée."
                        : "Aucune réponse enregistrée."}
                    </p>
                  )}
                </div>
              )}
            </section>

            <CompetenceReferences
              references={references}
              defaultOpen={referencesOpenByDefault(view)}
            />

            <div className={s.actions}>
              <button
                type="button"
                className={`btn btn-ghost ${s.actionWide}`}
                disabled={!nextId}
                title={nextId ? undefined : "Tous les sujets de cette compétence ont été traités."}
                onClick={() => nextId && router.push(withPlanStep(`${base}/${skillId}/${nextId}`, step))}
              >
                Sujet suivant
                <ArrowRight size={16} strokeWidth={2.2} aria-hidden />
              </button>
              <button
                type="button"
                className={`btn ${s.actionWide}`}
                onClick={() => router.push(withPlanStep(`${base}/${skillId}/${promptId}`, step))}
              >
                <RefreshCw size={15} strokeWidth={2.2} aria-hidden />
                S&apos;entraîner sur ce point
              </button>
            </div>
          </section>
        )}

        <PaywallSheet
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

/**
 * Le retour de l'IA, **déplié, sans bandeau ni bouton**.
 *
 * C'est ce que le candidat vient chercher : le lui faire déverrouiller d'un
 * clic ajoutait une étape à un contenu déjà acquis (et déjà décompté de ses
 * analyses offertes).
 *
 * Deux générations de contrat, aucune migration : `levelProgress` présent ⇒
 * restitution v3 (verdict du critère + niveau, leviers, exemple, mémo) ; absent
 * ⇒ l'affichage historique, conservé tel quel pour les analyses déjà en base.
 * Le verdict n'a plus de section propre en v3 : `status` et `verdict` sont
 * rendus en compact dans `CompetenceLevelCard` (pastille + ligne de texte).
 */
function AnalysisView({
  analysis,
  niveauVisePending = false,
}: {
  analysis: SkillAnalysisDto;
  /** Le sursis accordé au second appel court encore : la place du plan porte
   *  un indicateur discret, qui s'efface en silence s'il ne vient rien. */
  niveauVisePending?: boolean;
}) {
  const progress = analysis.levelProgress ?? null;
  const cible = analysis.niveauVise ?? null;

  // Analyse d'avant le contrat v3 : pas de carte de niveau, et on retombe
  // intégralement sur l'affichage historique.
  if (!progress) {
    return (
      <section className={s.aiPanel}>
        <h2 className={s.resultSectionTitle}>Analyse IA du critère</h2>
        <VerdictCard analysis={analysis} />
        <LegacyAnalysis analysis={analysis} />
      </section>
    );
  }

  return (
    <section className={s.aiPanel}>
      <CompetenceLevelCard
        progress={progress}
        strengthTag={analysis.strengthTag ?? null}
        focusTag={analysis.focusTag ?? null}
        criterionStatus={analysis.status}
        verdict={analysis.verdict}
      />
      {/* `niveauVise` absent est un cas NORMAL — objectif déjà atteint, ou
          second appel best-effort resté muet. Ni message d'échec, ni spinner,
          ni encart d'excuse : la carte de niveau se suffit. Le palier des
          intertitres vient du bloc qui les porte, jamais d'un niveau déduit. */}
      {cible && (
        <>
          {cible.leviers && cible.leviers.length > 0 && (
            <section className={s.block}>
              {/* `niveauVise` porte ici le PALIER CIBLE (la marche suivante), pas
                  l'objectif lointain : le titre nomme donc ce que le texte modèle
                  démontre vraiment. L'objectif, lui, est dit juste au-dessus par
                  la carte de niveau. */}
              <h3 className={s.resultSectionTitle}>{pourPasserAuTitle(cible.niveauVise)}</h3>
              <ActionPlanLeviers leviers={cible.leviers} />
            </section>
          )}
          {cible.exempleCible && (
            <section className={s.block}>
              <h3 className={s.resultSectionTitle}>{ACTION_PLAN_EXEMPLE_TITLE}</h3>
              <ActionPlanExemple exemple={cible.exempleCible} />
            </section>
          )}
          {cible.aRetenir && <ActionPlanMemoCard memo={cible.aRetenir} />}
        </>
      )}
      {/* Le second appel tourne encore : une ligne à sa place, le temps du
          sursis, sans bloquer la lecture de la carte de niveau. */}
      {!cible && niveauVisePending && <ActionPlanPending />}
    </section>
  );
}

/** Verdict sur le critère unique — **restitution v1/v2 seulement**.
 *
 *  Sous le contrat v3, le niveau démontré et son écart à l'objectif ouvrent
 *  l'écran : deux verdicts empilés au même endroit se disputeraient la première
 *  lecture. Parité stricte avec le mobile (`_VerdictCard`, branche héritée). */
function VerdictCard({analysis}: {analysis: SkillAnalysisDto}) {
  const tone = VERDICT_TONE[analysis.status];

  return (
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
  );
}

/**
 * Restitution des contrats **v1/v2**, conservée telle quelle.
 *
 * Ces analyses sont déjà en base et n'ont pas été migrées : elles ne portent ni
 * niveau, ni leviers, ni exemple. Chaque bloc est rendu **seulement s'il a du
 * texte** — un champ vide affiché produirait une carte creuse.
 */
function LegacyAnalysis({analysis}: {analysis: SkillAnalysisDto}) {
  const {successPoint, improvementPriority, improvedVersion} = analysis;

  return (
    <>
      {(successPoint || improvementPriority) && (
        <div className={s.feedbackGrid}>
          {successPoint && (
            <div className={s.feedbackItem}>
              <span className={`${s.feedbackIcon} ${s.feedbackIconGood}`} aria-hidden>
                <Check size={16} strokeWidth={2.8} />
              </span>
              <div>
                <strong className={s.feedbackTitle}>Ce qui est réussi</strong>
                <p className={s.feedbackText}>{successPoint}</p>
              </div>
            </div>
          )}
          {improvementPriority && (
            <div className={s.feedbackItem}>
              <span className={`${s.feedbackIcon} ${s.feedbackIconFocus}`} aria-hidden>
                <TrendingUp size={16} strokeWidth={2.4} />
              </span>
              <div>
                <strong className={s.feedbackTitle}>À travailler en priorité</strong>
                <p className={s.feedbackText}>{improvementPriority}</p>
              </div>
            </div>
          )}
        </div>
      )}

      {improvedVersion && (
        <div className={s.rewrite}>
          <strong className={s.rewriteLabel}>Proposition améliorée</strong>
          <p className={s.rewriteText}>{improvedVersion}</p>
          <small className={s.rewriteNote}>
            Exemple de reformulation : ce n&apos;est pas la seule bonne réponse, et ton idée
            doit être conservée.
          </small>
        </div>
      )}
    </>
  );
}

/**
 * Bandeau « Analyse IA du critère » — **le cas où il n'y a rien à montrer**.
 *
 * Il ne sert plus à replier un contenu existant : il dit au candidat ce qui
 * manque et propose l'unique action qui y remédie — relancer une analyse en
 * échec, ouvrir l'offre quand les analyses offertes sont épuisées, refaire le
 * sujet quand la production est partie sans analyse alors qu'il en restait.
 * Le faire disparaître dans ces cas-là ne dirait jamais au candidat ce qu'il
 * rate — c'est exactement le point premium du module.
 */
function AnalysisBanner({
  view,
  errorMessage,
  busy,
  onRetry,
  onUnlock,
  onRequest,
}: {
  view: SkillResultAnalysisView;
  errorMessage: string | null;
  busy: boolean;
  onRetry: () => void;
  onUnlock: () => void;
  onRequest: () => void;
}) {
  const action = skillResultBannerAction(view);
  if (!action) return null;

  const hint =
    action === "RETRY"
      ? (errorMessage ??
        "Ta production est bien enregistrée. Tu peux relancer l'analyse.")
      : action === "PAYWALL"
        ? "Tes analyses offertes ont été utilisées. Tes références restent accessibles."
        : "Ta production a été enregistrée sans analyse. Refais le sujet pour en obtenir une.";

  const label =
    action === "RETRY"
      ? busy
        ? "Relance…"
        : "Relancer l'analyse"
      : action === "PAYWALL"
        ? "Débloquer"
        : "Analyser";

  return (
    <div className={s.premium}>
      <span className={s.spark} aria-hidden>
        <Sparkles size={18} strokeWidth={2.2} />
      </span>
      <div className={s.premiumCopy}>
        <strong className={s.premiumTitle}>
          {action === "RETRY" ? "L'analyse n'a pas abouti" : "Analyse IA du critère"}
        </strong>
        <span className={s.premiumHint}>{hint}</span>
      </div>
      <button
        type="button"
        className={s.unlock}
        disabled={action === "RETRY" && busy}
        onClick={action === "RETRY" ? onRetry : action === "PAYWALL" ? onUnlock : onRequest}
      >
        {action === "RETRY" && <RefreshCw size={13} strokeWidth={2.2} aria-hidden />}
        {label}
      </button>
    </div>
  );
}
