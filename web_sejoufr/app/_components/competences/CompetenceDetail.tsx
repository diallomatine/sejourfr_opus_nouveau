"use client";

import Link from "next/link";
import {useParams, useRouter, useSearchParams} from "next/navigation";
import {useRef, useState} from "react";
import {ArrowRight, Check, Info, Lock, Sparkles} from "lucide-react";
import {learningPlanApi, skillApi} from "@/lib/api";
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
import {skillDetailKey} from "@/lib/skill-catalog";
import {progressPercent} from "@/lib/skill-progress";
import {useCachedData} from "@/lib/use-cached-data";
import {
  SKILL_DIFFICULTY_LABEL,
  SKILL_PROMPT_STATUS_LABEL,
  type SkillPromptSummaryDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {type ProductionConfig} from "@/app/_components/production/config";
import {ConfirmSheet} from "@/app/_components/hub/ConfirmSheet";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {CompetenceStatusBadge, promptCardToneClass} from "./CompetenceStatusBadge";
import {SkillTrajectory} from "./SkillTrajectory";
import {
  MiniBar,
  RowChevron,
  SectionHead,
  SKILL_PREMIUM_CTA,
  SkillLockBadge,
  SkillNotice,
  SkillShell,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";

type Filter = "all" | "todo" | "done" | "locked";

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
  // Le Plan est relu **en cache** : venir de lui, c'est l'avoir déjà chargé.
  // Rien n'est demandé au serveur pour afficher une compétence.
  const step = isPlanStep(searchParams)
    ? planStepFor(learningPlanApi.peekCached(), skillId)
    : null;

  const [filter, setFilter] = useState<Filter>("all");
  const [infoOpen, setInfoOpen] = useState(false);
  const [paywallOpen, setPaywallOpen] = useState(false);
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
  const loading = detailQuery.loading;
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
  /* Trois seaux **disjoints**, dont la somme fait exactement « Tous » — un
     compteur qui ne totalise pas est un compteur qui ment.
     - « Traités » décrit l'HISTORIQUE : un sujet produit y reste, même si le
       verrou est retombé dessus depuis (pass expiré) ;
     - « À faire » décrit ce qui est RÉELLEMENT ouvrable maintenant, donc jamais
       un sujet verrouillé — l'y compter enverrait le candidat sur le paiement
       en croyant ouvrir un exercice ;
     - « Verrouillés » n'existe que s'il y en a. Le verrou vient du serveur, on
       ne le recalcule pas.
     La barre de progression, elle, garde `prompts.length` au dénominateur : la
     compétence a bien N sujets, l'abonnement ne change pas ce qu'elle contient. */
  const treated = prompts.filter((p) => p.status !== "TODO");
  const openTodo = prompts.filter((p) => p.status === "TODO" && !p.locked);
  const lockedTodo = prompts.filter((p) => p.status === "TODO" && p.locked);
  const shown =
    filter === "all"
      ? prompts
      : filter === "done"
        ? treated
        : filter === "locked"
          ? lockedTodo
          : openTodo;
  /* En mode étape, la progression affichée est **celle du serveur**
     (`stepAttemptedCount` / `stepPromptCount`) : on ne la recompte pas depuis la
     liste — seule la largeur de la barre se dérive de ces deux nombres. */
  const attempted = scoped ? step.stepAttemptedCount : treated.length;
  const total = scoped ? step.stepPromptCount : prompts.length;
  const pct = progressPercent(attempted, total);
  const firstTodo = openTodo[0];
  const stepDone = scoped && step.stepCompleted;
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
    ...(lockedTodo.length > 0
      ? ([["locked", "Verrouillés", lockedTodo.length]] as [Filter, string, number][])
      : []),
  ];

  return (
    <DualChromeShell>
      <SkillShell
        backHref={scoped ? "/plan" : base}
        backLabel={scoped ? PLAN_STEP_BACK_LABEL : "Compétences"}
      >
        {error && <div className={s.error}>{error}</div>}

        {loading ? (
          <p className={s.empty}>Chargement…</p>
        ) : !skill ? (
          <p className={s.empty}>Compétence introuvable.</p>
        ) : (
          <>
            <section className={`${s.card} ${s.summary}`}>
              <div className={s.summaryTop}>
                <span className={s.tile} aria-hidden>
                  <Sparkles size={22} strokeWidth={2.2} />
                </span>
                {/* Pas de pastille de niveau ici (parité mobile) : le palier
                    est celui de toute la tâche, il est déjà porté par le hero
                    de la liste des compétences et par l'écran d'un sujet. */}
                <div className={s.summaryBody}>
                  {/* On dit d'où l'on vient : sans ça, l'écran ressemble à la
                      fiche complète tout en n'en montrant qu'une partie. */}
                  {scoped && <span className={s.stepPill}>{PLAN_STEP_PILL}</span>}
                  <h1 className={s.summaryTitle}>{skill.title}</h1>
                </div>
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

              <div className={s.critBox}>
                <span className={s.critLabel}>Critère travaillé</span>
                <p className={s.critText}>{skill.generalCriterion}</p>
              </div>

              <MiniBar attempted={attempted} total={total} percent={pct} />
            </section>

            {/* Étape finie : on ne fabrique **aucun** second parcours de
                vérification ici — « Vérifier ma progression » vit sur le Plan,
                qui seul sait si le moteur de maîtrise est prêt. On y ramène. */}
            {stepDone && (
              <SkillNotice title={PLAN_STEP_DONE_TITLE}>
                <p>{planStepDoneText(step.stepPromptCount)}</p>
                <Link href="/plan" className={s.headLink}>
                  {PLAN_STEP_DONE_CTA} →
                </Link>
              </SkillNotice>
            )}

            {/* L'action de l'étape : on démarre le sujet **désigné par le
                serveur**. Le libellé dit ce qui va se passer — commencer un
                sujet neuf et revenir sur un sujet déjà rendu ne se disent pas
                pareil —, et c'est le statut servi du sujet qui tranche. */}
            {target && (
              <button
                type="button"
                className={`${s.primary} ${s.stepCta}`}
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
                  : filter === "locked"
                    ? "Aucun sujet verrouillé."
                    : "Tous les sujets ouverts ont été traités."}
              </p>
            ) : (
              <div className={s.list}>
                {shown.map((p) => (
                  <PromptCard
                    key={p.id}
                    prompt={p}
                    onOpen={
                      p.locked
                        ? () => setPaywallOpen(true)
                        : () => router.push(promptHref(p.id))
                    }
                  />
                ))}
              </div>
            )}

            {/* La frise arrive APRÈS les sujets : elle raconte le chemin déjà
                parcouru, l'écran sert d'abord à en produire un de plus. */}
            <SkillTrajectory points={data?.trajectory ?? []} />

            {scoped ? (
              <Link href="/plan" className={s.footLink}>
                ← {PLAN_STEP_LINK}
              </Link>
            ) : (
              <Link href={`${config.base}/tache/${n}`} className={s.footLink}>
                ← Revenir aux sujets TCF complets
              </Link>
            )}

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

/** Un sujet verrouillé garde son titre, son rang et son historique : ce qui
 *  change, c'est la pastille (cadenas), la mention « Premium » et la
 *  destination du clic. Le verrou est celui du serveur. */
function PromptCard({prompt, onOpen}: {prompt: SkillPromptSummaryDto; onOpen: () => void}) {
  const done = prompt.status !== "TODO";
  const locked = prompt.locked;
  return (
    <button
      type="button"
      className={`${s.card} ${s.rowCard} ${promptCardToneClass(prompt.status)}`}
      onClick={onOpen}
    >
      <span
        className={`${s.tile} ${locked ? s.tileLocked : done ? s.tileDone : ""}`}
        aria-hidden
      >
        {locked ? (
          <Lock size={20} />
        ) : done ? (
          <Check size={22} strokeWidth={2.8} />
        ) : (
          prompt.displayOrder
        )}
      </span>
      {/* Le critère unique ne s'affiche plus sous le titre (parité mobile) : il
          est répété par la check-list de l'écran de saisie, et il faisait de
          chaque carte un pavé de texte. */}
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{prompt.title}</span>
        {done && (
          <span className={s.rowMeta}>
            <CompetenceStatusBadge status={prompt.status} />
            <span className={s.metaText}>
              {prompt.attemptCount} tentative{prompt.attemptCount > 1 ? "s" : ""}
              {prompt.lastAttemptAt ? ` · ${shortDate(prompt.lastAttemptAt)}` : ""}
            </span>
          </span>
        )}
      </span>
      <span className={s.rowAside}>
        {locked ? (
          <SkillLockBadge />
        ) : done ? (
          <span className={s.metaText}>{SKILL_DIFFICULTY_LABEL[prompt.difficultyLevel]}</span>
        ) : (
          <CompetenceStatusBadge status={prompt.status} />
        )}
        <RowChevron />
      </span>
    </button>
  );
}
