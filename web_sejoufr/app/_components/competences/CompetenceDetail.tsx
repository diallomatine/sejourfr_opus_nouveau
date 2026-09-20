"use client";

import Link from "next/link";
import {useParams, useRouter, useSearchParams} from "next/navigation";
import {useMemo, useRef, useState} from "react";
import {
  ArrowRight,
  Check,
  Info,
  ListChecks,
  Lock,
  RefreshCw,
  Zap,
} from "lucide-react";
import {journeyApi, learningPlanApi, skillApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {cached} from "@/lib/data-cache";
import {
  isPlanStep,
  PLAN_STEP_BACK_LABEL,
  PLAN_STEP_DONE_CTA,
  PLAN_STEP_DONE_TITLE,
  PLAN_STEP_LINK,
  PLAN_STEP_PILL,
  PLAN_STEP_RETRY_CTA,
  PLAN_STEP_SECTION_TITLE,
  PLAN_STEP_START_CTA,
  planStepDoneText,
  planStepFor,
  planStepPrompts,
  planStepRecommendedPrompt,
  planStepSectionText,
  withPlanStep,
} from "@/lib/plan-step";
import {
  competenceCta,
  competenceEyebrow,
  EXPRESSION_LEARNING_POINTS_TITLE,
  restantsLabel,
  sujetsMeta,
} from "@/lib/expression";
import {skillDetailKey} from "@/lib/skill-catalog";
import {useCachedData} from "@/lib/use-cached-data";
import {
  SKILL_DIFFICULTY_LABEL,
  SKILL_PROMPT_STATUS_LABEL,
  type JourneyDto,
  type SkillPromptSummaryDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {type ProductionConfig} from "@/app/_components/production/config";
import {ConfirmSheet} from "@/app/_components/hub/ConfirmSheet";
import {ExamDoneSheet} from "@/app/_components/hub/ExamDoneSheet";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {CompetenceStatusBadge} from "./CompetenceStatusBadge";
import {
  RowChevron,
  SectionHead,
  SKILL_PREMIUM_CTA,
  SKILL_PROMPT_REDO_CTA,
  skillPromptLastAttemptCta,
  SkillLockBadge,
  SkillMasteryPill,
  SkillNotice,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import {
  journeyEtapeSuivante,
  journeyEtapeSuivanteCta,
} from "@/lib/journey";
import {planStepAction} from "@/lib/plan-domain";
import {
  usePlanAssessment,
  usePlanExercise,
} from "@/app/_components/plan/use-plan-exercise";
import s from "@/app/_components/skill-ui/skill.module.css";

type Filter = "all" | "todo" | "done";

/** Surtitre de la carte qui met en avant le sujet à faire maintenant. Miroir
 *  mot pour mot de `kNextPromptEyebrow` côté mobile. */
const NEXT_PROMPT_EYEBROW = "Prochain sujet recommandé";

/** Ce qu'on dit d'un sujet qu'on **repropose**. Formulation positive, règle
 *  gelée du dépôt : on nomme ce que la reprise apporte, jamais un manque — et
 *  on n'affirme aucun nombre de passages, un sujet pouvant être repris
 *  plusieurs fois. Miroir mot pour mot de `kNextPromptReinforceReason`. */
const NEXT_PROMPT_REINFORCE_REASON =
  "Déjà traité : le reprendre consolide ce qui restait fragile.";

/** Le rappel de pied de liste. « Tout traité » n'est pas « acquis » : la preuve
 *  se fait en situation, sur une production complète, et c'est le Plan qui la
 *  déclenche. Sans cette ligne, une série au complet se lit comme une
 *  compétence maîtrisée. Miroir mot pour mot de `kSkillSeriesNote`. */
const SKILL_SERIES_NOTE =
  "Avoir traité tous les sujets ne veut pas dire que la compétence est " +
  "acquise : elle se confirme sur une production complète, que ton plan te " +
  "proposera.";

/** Date courte d'une dernière tentative (« 4 août »). */
function shortDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("fr-FR", {day: "numeric", month: "long"});
}

/**
 * Niveau 4 de la spec, écran d'une compétence : ce qu'elle travaille, où en est
 * le candidat, et ses 15 petits sujets.
 *
 * La progression affichée est le nombre de **sujets traités**, pas de sujets
 * validés (spec §12) : on ne veut pas laisser croire qu'il faut tout valider
 * pour avancer — un sujet raté puis compris a fait son travail.
 *
 * ⚠️ **Deux vues, selon la porte d'entrée** (décision produit, cf.
 * `lib/plan-step.ts`). Ouvert **depuis le Plan** (`?etape=1`) et tant que la
 * compétence est une priorité, l'écran se limite aux **sujets de l'étape** et
 * compte « 2/5 » ; par « Réviser → épreuve → Compétences », il garde la fiche
 * complète et son « x/15 », **strictement inchangée**. Sans périmètre
 * exploitable — Plan pas chargé, compétence sortie des priorités, étape vide —
 * on retombe **silencieusement** sur la fiche complète : jamais d'erreur,
 * jamais d'écran vide.
 */
export function CompetenceDetail({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string; skillId: string}>();
  const searchParams = useSearchParams();
  const n = Number(params?.n ?? "0");
  const skillId = params?.skillId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();

  const base = `${config.base}/tache/${n}/competences`;
  /* Le marqueur d'URL dit « on arrive du Plan » — et il survit à tout, y
     compris à un rechargement. Le Plan, lui, vit en mémoire : le lire au
     `peek` seul faisait retomber l'écran sur la fiche des 15 sujets au premier
     F5, sans pilule d'étape, avec un retour qui renvoyait dans
     `/entrainement`. On le branche donc sur le cache : déjà chargé ⇒ peint
     tout de suite, sans un appel ; cache froid ⇒ **un** appel, et seulement
     dans ce cas. */
  const fromPlan = isPlanStep(searchParams);
  const planQuery = useCachedData(
    fromPlan && status === "authenticated" ? learningPlanApi.cacheKey : null,
    () => learningPlanApi.getCached(),
    {errorMessage: "Impossible de charger votre plan."},
  );
  /* 🛑 Le parcours, lu au **même endroit** que le Plan : c'est lui qui désigne
     l'étape suivante quand celle-ci se termine, et n'en lire qu'un rouvrirait
     l'écart entre ce que le Plan annonce et ce que cet écran propose. */
  const journeyQuery = useCachedData<JourneyDto>(
    fromPlan && status === "authenticated" ? journeyApi.cacheKey : null,
    () => journeyApi.getCached(),
  );
  /* Les mêmes lanceurs que le Plan, jamais un second chemin. */
  const exercise = usePlanExercise();
  const assessment = usePlanAssessment();
  const step = fromPlan ? planStepFor(planQuery.data, skillId) : null;
  /* Tant que le Plan n'est pas revenu, on ne sait pas encore si l'écran est
     celui d'une étape : afficher la fiche complète en attendant la ferait
     passer de 15 sujets à 5 sous les yeux du candidat. On garde le
     squelette — il est déjà là pour la compétence elle-même. */
  const planPending = fromPlan && planQuery.data === undefined && planQuery.error === null;

  const [filter, setFilter] = useState<Filter>("all");
  const [infoOpen, setInfoOpen] = useState(false);
  const [paywallOpen, setPaywallOpen] = useState(false);
  /* Le sujet déjà traité sur lequel on vient de taper : on lui propose de
     relire son dernier retour **ou** de refaire le sujet, au lieu de le
     renvoyer d'office en production. `null` = aucune feuille ouverte, et c'est
     le cas de tout sujet jamais traité — on n'ajoute pas d'étape là où il n'y a
     rien à choisir. */
  const [donePrompt, setDonePrompt] = useState<SkillPromptSummaryDto | null>(null);
  const infoButtonRef = useRef<HTMLButtonElement>(null);

  // Mémorisé pour la session : aller sur un petit sujet puis revenir à la liste
  // ne recharge pas la compétence. L'entrée est purgée dès qu'une production ou
  // une analyse change le statut d'un sujet (`lib/api.ts`).
  const detailQuery = useCachedData(
    status === "authenticated" && skillId ? skillDetailKey(skillId) : null,
    () => cached(skillDetailKey(skillId), () => skillApi.getSkill(skillId)),
    {errorMessage: "Impossible de charger cette compétence."},
  );
  const data = detailQuery.data;
  const loading = detailQuery.loading || planPending;
  const error = detailQuery.error;

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${base}/${skillId}`} />;

  const skill = data?.skill;
  const allPrompts = data?.prompts ?? [];
  /* Périmètre de l'étape : les identifiants servis par le serveur, dans leur
     ordre. On ne rejoue **aucune** règle (« les 5 premiers par rang »), on ne
     fait que retrouver les sujets correspondants. Rien à montrer ⇒ repli sur la
     fiche complète, sans un mot. */
  const stepPrompts = step ? planStepPrompts(allPrompts, step.stepPromptIds) : [];
  const scoped = step !== null && stepPrompts.length > 0;
  const prompts = scoped ? stepPrompts : allPrompts;
  const promptHref = (promptId: string) =>
    withPlanStep(`${base}/${skillId}/${promptId}`, scoped);
  /* L'écran de résultat d'une tentative de **compétence** — celui qui rend le
     verdict du critère, la carte de niveau et le plan d'action. Ce n'est ni le
     rapport d'une production TCF complète, ni une liste : on ouvre directement
     le dernier retour. */
  const resultHref = (promptId: string, attemptId: string) =>
    withPlanStep(`${base}/${skillId}/${promptId}/resultat/${attemptId}`, scoped);
  /* Taper un sujet : verrouillé ⇒ l'offre ; déjà traité et relisible ⇒ le
     choix ; sinon ⇒ production directe, exactement comme avant. Un sujet marqué
     traité mais **sans** `lastAttemptId` (ligne héritée) suit ce dernier chemin :
     jamais de bouton qui n'ouvrirait rien. */
  const openPrompt = (p: SkillPromptSummaryDto) => {
    if (p.locked) {
      setPaywallOpen(true);
      return;
    }
    if (p.status !== "TODO" && p.lastAttemptId) {
      setDonePrompt(p);
      return;
    }
    router.push(promptHref(p.id));
  };
  /* DEUX seaux disjoints, dont la somme fait exactement « Tous » — un compteur
     qui ne totalise pas est un compteur qui ment.
     - « Traités » décrit l'HISTORIQUE : un sujet produit y reste, même si le
       verrou est retombé dessus depuis (pass expiré) ;
     - « À faire » contient tout le reste, **verrouillés compris**. Ils sont
       bien à faire ; le verrou est commercial, il se dit sur la carte (cadenas
       + « Premium ») et au tap (l'offre). Le 4ᵉ filtre « Verrouillés » a été
       retiré le 2026-08-16 à la demande du propriétaire : sans lui, les
       exclure de « À faire » aurait affiché « Tous · 5 = 0 + 2 ».
     La barre de progression garde `prompts.length` au dénominateur : la
     compétence a bien N sujets, l'abonnement ne change pas ce qu'elle contient. */
  const treated = prompts.filter((p) => p.status !== "TODO");
  const openTodo = prompts.filter((p) => p.status === "TODO");
  const shown =
    filter === "all" ? prompts : filter === "done" ? treated : openTodo;
  /* En mode étape, la progression affichée est **celle du serveur**
     (`stepAttemptedCount` / `stepPromptCount`) : on ne la recompte pas depuis la
     liste — seule la largeur de la barre se dérive de ces deux nombres. */
  const meta = sujetsMeta(prompts);
  const attempted = scoped ? step.stepAttemptedCount : treated.length;
  const total = scoped ? step.stepPromptCount : prompts.length;
  /* Le lien d'appoint de l'intertitre vise le premier sujet **ouvrable** :
     « À faire » compte désormais les verrouillés, mais proposer d'en commencer
     un mènerait à l'offre, pas à un exercice. */
  const firstTodo = openTodo.find((p) => !p.locked);
  /* Série terminée : on propose de RETRAVAILLER le premier sujet ouvrable.
     Tout verrouillé ⇒ ni l'un ni l'autre, et le CTA bascule sur l'offre. */
  const reprenable = prompts.find((p) => !p.locked);
  const stepDone = scoped && step.stepCompleted;
  const suivante = stepDone
    ? journeyEtapeSuivante(journeyQuery.data ?? null, skill?.code ?? null)
    : null;
  /* 🛑 Les mêmes lanceurs que le Plan, jamais un second chemin. */
  const suivanteAction = useMemo(() => {
    const plan = planQuery.data;
    if (!suivante || !plan) return null;
    const action = planStepAction(plan, suivante);
    if (!action) return null;
    if (action.mesure) return () => void assessment.start(action.mesure!.assessment);
    return () => void exercise.start(action.exercise!);
  }, [assessment, exercise, planQuery.data, suivante]);
  /* Le sujet que l'étape propose de faire : **celui que le serveur a désigné**
     (`recommendedExercise.skillPromptId`), jamais un « premier sujet non
     validé » recalculé ici — le Plan désignerait alors un autre sujet que cet
     écran. `null` est un cas normal (pas d'exercice, vérification, fiche
     complète) : l'écran garde son comportement d'origine, avec son lien
     « Commencer le sujet N » dans l'intertitre. */
  const target = scoped ? planStepRecommendedPrompt(step, stepPrompts) : null;
  /* Un exercice verrouillé reste **désigné**, jamais détourné vers un autre
     sujet : c'est le traitement freemium de l'écran (cadenas + paywall), pas un
     changement de cible. */
  const targetLocked =
    target !== null && (target.locked || step?.recommendedExercise?.locked === true);

  const chips: [Filter, string, number][] = [
    ["all", "Tous", prompts.length],
    ["todo", SKILL_PROMPT_STATUS_LABEL.TODO, openTodo.length],
    ["done", "Traités", treated.length],
  ];

  return (
    <DualChromeShell>
      <SkillShell
        /* 🛑 Le retour suit la PROVENANCE, la liste suit la PORTÉE — deux
           questions distinctes qu'un seul booléen confondait. Une compétence
           simplement **observée** (ni priorité, ni étape franchie) n'a pas
           d'étape : `scoped` est faux, et le retour partait alors dans
           `/entrainement` alors que le candidat venait de cliquer dessus dans
           son Plan. La portée, elle, reste honnête : sans étape, on montre bien
           les 15 sujets. */
        backHref={fromPlan ? "/plan" : base}
        backLabel={fromPlan ? PLAN_STEP_BACK_LABEL : "Compétences"}
        /* 🛑 Le nom de la compétence vit ICI, et nulle part ailleurs — miroir
           de `ScreenHeader` côté mobile (titre = le nom, sous-titre =
           « code · épreuve »). La carte de résumé le répétait juste en dessous,
           pour un tiers de la hauteur visible. */
        title={skill?.title ?? "Compétence"}
        meta={skill ? `${skill.code} · ${config.label}` : config.label}
      >
        {error && <div className={s.error}>{error}</div>}

        {loading ? (
          <p className={s.empty}>Chargement…</p>
        ) : !skill ? (
          <p className={s.empty}>Compétence introuvable.</p>
        ) : (
          <>
            {/* Carte de résumé : filet d'accent, lavis dégradé, puis la
                progression, « Vous allez apprendre à » et le critère travaillé.
                🛑 **Elle ne répète ni le sur-titre ni le nom de la
                compétence** : l'en-tête de l'écran les porte déjà, juste
                au-dessus. Elle ne réutilise **pas** `.summary`, qui sert les
                modèles corrigés et ne bouge pas. */}
            <section className={s.skillHead}>
              <span className={s.skillHeadRule} aria-hidden />
              <div className={s.skillHeadInner}>
                {/* On dit d'où l'on vient : sans ça, l'écran ressemble à la
                    fiche complète tout en n'en montrant qu'une partie. */}
                {scoped && <span className={s.stepPill}>{PLAN_STEP_PILL}</span>}

                {/* Première ligne de la carte : les points d'avancement de la
                    maquette — un segment par sujet du périmètre affiché (5 en
                    mode étape, 15 sur la fiche complète). Les deux nombres
                    viennent d'au-dessus — en mode étape, ce sont **ceux du
                    serveur**.

                    🛑 La pastille d'information ne dépend PAS du compteur : une
                    compétence servie sans sujet garde son explication, et elle
                    **n'existe pas** quand il n'y a rien à expliquer. */}
                {(total > 0 || !!skill.description) && (
                  <div className={s.skillHeadProgress}>
                    {total > 0 && (
                      <>
                        <span className={s.skillHeadCount}>
                          {attempted} / {total} sujets travaillés
                        </span>
                        <span
                          className={s.dots}
                          role="img"
                          aria-label={`${attempted} sujets travaillés sur ${total}`}
                        >
                          {Array.from({length: total}, (_, i) => (
                            <span
                              key={i}
                              className={`${s.dot} ${i < attempted ? s.dotOn : ""}`}
                            />
                          ))}
                        </span>
                        {/* L'état de maîtrise, s'il existe : c'est la réponse à
                            « où j'en suis sur cette compétence », dérivée
                            serveur. `null` (aucune observation) ⇒ rien — on
                            n'invente pas un état. */}
                        {skill.masteryState && <SkillMasteryPill state={skill.masteryState} />}
                      </>
                    )}
                    {skill.description && (
                      <button
                        type="button"
                        ref={infoButtonRef}
                        className={s.infoBtn}
                        aria-label="À quoi sert cette compétence ?"
                        aria-haspopup="dialog"
                        onClick={() => setInfoOpen(true)}
                      >
                        <span className={s.infoDot} aria-hidden>
                          <Info size={15} strokeWidth={2.4} />
                        </span>
                      </button>
                    )}
                  </div>
                )}

                {/* 🛑 **Deux blocs distincts, jamais l'un à la place de
                    l'autre** (arbitrage du propriétaire, 2026-09-13).
                    `learningPoints` est une colonne NULLABLE (`V063`) : absente,
                    la section « Vous allez apprendre à » **disparaît
                    entièrement** — elle ne retombe pas sur le critère général,
                    qui n'est pas la même chose et garde son emplacement propre
                    juste en dessous. Le jour où les points sont injectés, le
                    bloc apparaît tout seul, sans toucher à cet écran. */}
                {skill.learningPoints && skill.learningPoints.length > 0 && (
                  <>
                    <p className={s.learnTitle}>{EXPRESSION_LEARNING_POINTS_TITLE}</p>
                    <ul className={s.learnList}>
                      {skill.learningPoints.map((point) => (
                        <li key={point} className={s.learnItem}>
                          <span className={s.learnDot} aria-hidden>
                            <Check size={12} strokeWidth={3} />
                          </span>
                          {point}
                        </li>
                      ))}
                    </ul>
                  </>
                )}

                {/* Le critère travaillé, à sa place, **quoi qu'il arrive** : il
                    dit ce qui est évalué, là où les points d'apprentissage
                    disent ce qu'on va apprendre à faire. */}
                {skill.generalCriterion.trim() !== "" && (
                  <div className={s.critBox}>
                    <span className={s.critLabel}>Critère travaillé</span>
                    <p className={s.critText}>{skill.generalCriterion}</p>
                  </div>
                )}

                {/* « 5 petits sujets · ≈ 4 min chacun » — la minute vient
                    d'`estimatedMinutes`, dérivé serveur par `ExerciseDuration`.
                    🛑 « chacun » : les 5 sujets font un quart d'heure, pas 4 min. */}
                {meta && (
                  <p className={s.learnMeta}>
                    <span>
                      <ListChecks size={15} strokeWidth={2.2} aria-hidden />
                      {meta}
                    </span>
                  </p>
                )}

                {/* 🛑 **Le CTA de la maquette `detail_competence.png`.** Hors
                    mode étape, l'écran n'en portait aucun : le parcours libre
                    (Réviser → tâche → compétence) s'arrêtait sur une liste, sans
                    rien à presser. Le mode étape, lui, garde sa carte
                    « Prochain sujet recommandé » — c'est le Plan qui y désigne
                    la cible, et deux appels à l'action se contrediraient.

                    La cible est le premier sujet OUVRABLE ; tout verrouillé ⇒
                    l'offre, jamais un bouton qui n'ouvre rien. Le libellé vient
                    de `competenceCta`, qui dit ce qui va se passer (commencer,
                    continuer, retravailler). */}
                {!scoped && prompts.length > 0 && (
                  <button
                    type="button"
                    className={`${s.primary} ${s.stepCta} ${s.headCta}`}
                    onClick={
                      firstTodo
                        ? () => router.push(promptHref(firstTodo.id))
                        : reprenable
                          ? () => router.push(promptHref(reprenable.id))
                          : () => setPaywallOpen(true)
                    }
                  >
                    {firstTodo || reprenable ? (
                      <>
                        {competenceCta(prompts, {locked: false})}{" "}
                        <ArrowRight size={16} aria-hidden />
                      </>
                    ) : (
                      <>
                        <Lock size={16} aria-hidden /> {SKILL_PREMIUM_CTA}
                      </>
                    )}
                  </button>
                )}
              </div>
            </section>

            {/* « Compétence acquise · 0 restants » + barre (maquette
                `detail_competence.png`). Les deux nombres viennent des statuts
                **servis** des sujets du périmètre affiché. */}
            {prompts.length > 0 && (
              <>
                <div className={s.resteRow}>
                  <h2 className={s.resteTitle}>{competenceEyebrow(skill)}</h2>
                  <span className={s.resteCount}>{restantsLabel(prompts)}</span>
                </div>
                <div className={s.resteBar}>
                  <span
                    className={s.resteBarFill}
                    style={{width: `${Math.round((100 * attempted) / Math.max(1, total))}%`}}
                  />
                </div>
              </>
            )}

            {/* Étape finie : on ne fabrique **aucun** second parcours de
                vérification ici — « Vérifier ma progression » vit sur le Plan,
                qui seul sait si le moteur de maîtrise est prêt. On y ramène. */}
            {stepDone && (
              <SkillNotice title={PLAN_STEP_DONE_TITLE}>
                <p>{planStepDoneText(step.stepPromptCount)}</p>
                {/* 🛑 **On nomme la suivante, on ne la devine pas** : elle
                    vient du parcours, et son action de `planStepAction` — donc
                    le clic fait exactement ce que ferait la même étape cliquée
                    depuis le Plan. Tant que le serveur n'a pas clos celle-ci
                    (les évaluations sont asynchrones), il n'y a pas de suivante
                    et on retombe sur le Plan : on ne promet jamais une étape
                    qui n'existe pas encore. */}
                {suivanteAction ? (
                  <button
                    type="button"
                    className={s.headLink}
                    disabled={exercise.starting || assessment.starting !== null}
                    onClick={suivanteAction}
                  >
                    {journeyEtapeSuivanteCta(suivante!)} →
                  </button>
                ) : (
                  <Link href="/plan" className={s.headLink}>
                    {PLAN_STEP_DONE_CTA} →
                  </Link>
                )}
              </SkillNotice>
            )}

            {/* L'action de l'étape, dans la carte d'appel de la maquette : on
                démarre le sujet **désigné par le serveur**, et on le nomme —
                l'ancien bouton nu ne disait pas sur quoi il ouvrait. Le libellé
                dit ce qui va se passer — commencer un sujet neuf et revenir sur
                un sujet déjà rendu ne se disent pas pareil —, et c'est le statut
                servi du sujet qui tranche.

                ⚠️ Un sujet **verrouillé reste désigné** (règle serveur) : on
                affiche son titre et l'offre, on ne détourne jamais vers un autre
                sujet qui ne serait plus la priorité mesurée. */}
            {target && (
              <section className={s.recoCard}>
                <div className={s.recoInner}>
                  <span className={s.recoEyebrow}>
                    <Zap size={13} strokeWidth={2.4} aria-hidden />
                    {NEXT_PROMPT_EYEBROW}
                  </span>
                  <h2 className={s.recoTitle}>{target.title}</h2>
                  <p className={s.recoText}>
                    {targetLocked
                      ? "Ce sujet fait partie de l'abonnement Intégral. Il reste celui que ton plan a désigné."
                      : target.status === "TODO"
                        ? "Nouveau sujet sur cette compétence."
                        : NEXT_PROMPT_REINFORCE_REASON}
                  </p>
                  <button
                    type="button"
                    className={`${s.primary} ${s.stepCta} ${s.recoAction}`}
                    onClick={
                      targetLocked
                        ? () => setPaywallOpen(true)
                        : () => router.push(promptHref(target.id))
                    }
                  >
                    {targetLocked ? (
                      <>
                        <Lock size={16} aria-hidden /> {SKILL_PREMIUM_CTA}
                      </>
                    ) : (
                      <>
                        {target.status === "TODO" ? PLAN_STEP_START_CTA : PLAN_STEP_RETRY_CTA}{" "}
                        <ArrowRight size={16} aria-hidden />
                      </>
                    )}
                  </button>
                </div>
              </section>
            )}

            <SectionHead
              title={scoped ? PLAN_STEP_SECTION_TITLE : "Petits sujets"}
              text={
                scoped
                  ? planStepSectionText(step.stepPromptCount)
                  : "Les sujets déjà réalisés restent clairement identifiables."
              }
              action={
                !target && firstTodo && (
                  <button
                    type="button"
                    className={s.headLink}
                    onClick={() => router.push(promptHref(firstTodo.id))}
                  >
                    Commencer le sujet {firstTodo.displayOrder} →
                  </button>
                )
              }
            />

            <div className={s.filterRow} role="tablist" aria-label="Filtrer les petits sujets">
              {chips.map(([key, label, count]) => (
                <button
                  key={key}
                  type="button"
                  role="tab"
                  aria-selected={filter === key}
                  className={`${s.filter} ${filter === key ? s.filterOn : ""}`}
                  onClick={() => setFilter(key)}
                >
                  {label} · {count}
                </button>
              ))}
            </div>

            {shown.length === 0 ? (
              <p className={s.empty}>
                {filter === "done"
                  ? "Aucun sujet traité pour l'instant."
                  : "Tous les sujets ont été traités."}
              </p>
            ) : (
              /* Un seul cadre, des filets entre les lignes — la liste de la
                 maquette. Quinze cartes autonomes empilées faisaient quinze
                 blocs à parcourir ; groupées, elles se lisent d'un trait. */
              <div className={s.groupCard}>
                {shown.map((p) => (
                  <PromptRow
                    key={p.id}
                    prompt={p}
                    recommended={target?.id === p.id}
                    onOpen={() => openPrompt(p)}
                  />
                ))}
              </div>
            )}

            {/* Traité ≠ acquis : sans cette ligne, une série au complet se lit
                comme une compétence maîtrisée. La preuve se fait en situation,
                sur une production complète, et c'est le Plan qui la déclenche. */}
            <p className={s.seriesNote}>{SKILL_SERIES_NOTE}</p>

            {fromPlan ? (
              <Link href="/plan" className={s.footLink}>
                ← {PLAN_STEP_LINK}
              </Link>
            ) : (
              <Link href={`${config.base}/tache/${n}`} className={s.footLink}>
                ← Revenir aux sujets TCF complets
              </Link>
            )}

            {/* Même geste que sur un examen déjà passé, même composant : sur un
                sujet fait, on relit ou on refait. Le premier libellé suit le
                statut servi — une tentative « Fait » n'a pas d'analyse IA, et
                son écran de résultat ne montre que la production et les
                références. */}
            <ExamDoneSheet
              open={donePrompt !== null}
              title={donePrompt?.title ?? ""}
              subtitle={
                donePrompt
                  ? `${SKILL_PROMPT_STATUS_LABEL[donePrompt.status]}${
                      donePrompt.lastAttemptAt ? ` · ${shortDate(donePrompt.lastAttemptAt)}` : ""
                    }`
                  : null
              }
              detailLabel={donePrompt ? skillPromptLastAttemptCta(donePrompt.status) : ""}
              resumeLabel={SKILL_PROMPT_REDO_CTA}
              resumeTone="blue"
              onViewDetail={() => {
                if (!donePrompt?.lastAttemptId) return;
                const href = resultHref(donePrompt.id, donePrompt.lastAttemptId);
                setDonePrompt(null);
                router.push(href);
              }}
              onResume={() => {
                if (!donePrompt) return;
                const href = promptHref(donePrompt.id);
                setDonePrompt(null);
                router.push(href);
              }}
              onClose={() => setDonePrompt(null)}
            />

            <PaywallSheet
              open={paywallOpen}
              onClose={() => setPaywallOpen(false)}
              module="INTEGRAL"
              title="Tous les petits sujets"
              message="Ce sujet est réservé à l'abonnement Intégral. Il ouvre tous les petits sujets de chaque compétence, les 8 compétences de chaque tâche et l'analyse IA sans limite. Ton plan personnalisé, lui, reste entier."
            />

            <ConfirmSheet
              open={infoOpen && !!skill.description}
              tone="info"
              title={skill.title}
              message={skill.description ?? ""}
              onClose={() => {
                setInfoOpen(false);
                infoButtonRef.current?.focus();
              }}
            />
          </>
        )}
      </SkillShell>
    </DualChromeShell>
  );
}

/**
 * Une ligne de petit sujet dans la liste groupée.
 *
 * Un sujet **verrouillé garde son titre, son rang et son historique** : ce qui
 * change, c'est la pastille (cadenas), la mention « Premium » et la destination
 * du clic. Le verrou est celui du serveur, et il n'est **pas** flouté — masquer
 * le sujet reviendrait à cacher au candidat ce qu'il y a à travailler, c'est
 * l'inverse de ce qu'on lui vend ; et son titre est de toute façon rendu en
 * clair par l'écran du sujet lui-même.
 *
 * L'état se lit à trois endroits qui disent la même chose sans se contredire :
 * la pastille de gauche (icône), le badge de statut (couleur + libellé gelé) et,
 * pour un sujet à faire, le badge repris à droite. Le liseré vertical de la
 * carte autonome disparaît avec elle — dans une liste groupée il aurait strié
 * chaque ligne sans rien ajouter à ces trois signaux.
 */
function PromptRow({
  prompt,
  recommended,
  onOpen,
}: {
  prompt: SkillPromptSummaryDto;
  /** Le sujet que le serveur a désigné pour l'étape : fond tenu, jamais une
   *  couleur de texte — le titre doit rester lisible à l'identique. */
  recommended: boolean;
  onOpen: () => void;
}) {
  const done = prompt.status !== "TODO";
  const locked = prompt.locked;

  return (
    <button
      type="button"
      className={`${s.groupRow} ${recommended ? s.groupRowOn : ""}`}
      onClick={onOpen}
    >
      <span
        className={`${s.groupNum} ${
          locked
            ? ""
            : prompt.status === "VALIDATED"
              ? s.groupNumDone
              : done
                ? s.groupNumRedo
                : ""
        }`}
        aria-hidden
      >
        {locked ? (
          <Lock size={14} />
        ) : prompt.status === "VALIDATED" ? (
          <Check size={15} strokeWidth={3} />
        ) : prompt.status === "TO_REINFORCE" ? (
          <RefreshCw size={13} strokeWidth={2.4} />
        ) : prompt.status === "TREATED" ? (
          <Check size={15} strokeWidth={2.4} />
        ) : (
          prompt.displayOrder
        )}
      </span>
      {/* Le critère unique ne s'affiche pas sous le titre (parité mobile) : il
          est répété par la check-list de l'écran de saisie, et il faisait de
          chaque ligne un pavé de texte. */}
      <span className={s.groupBody}>
        <span className={s.groupTitle}>{prompt.title}</span>
        {done && (
          <span className={s.groupMeta}>
            <CompetenceStatusBadge status={prompt.status} />
            <span className={s.metaText}>
              {prompt.attemptCount} tentative{prompt.attemptCount > 1 ? "s" : ""}
              {prompt.lastAttemptAt ? ` · ${shortDate(prompt.lastAttemptAt)}` : ""}
            </span>
          </span>
        )}
      </span>
      <span className={s.groupAside}>
        {locked ? (
          <SkillLockBadge />
        ) : done ? (
          <span className={`${s.metaText} ${s.groupDifficulty}`}>
            {SKILL_DIFFICULTY_LABEL[prompt.difficultyLevel]}
          </span>
        ) : (
          <CompetenceStatusBadge status={prompt.status} />
        )}
        <RowChevron />
      </span>
    </button>
  );
}
