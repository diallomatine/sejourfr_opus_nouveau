"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useState, type ReactNode} from "react";
import {
  ArrowRight,
  Check,
  ChevronDown,
  Clock3,
  FilePenLine,
  Headphones,
  ListChecks,
  Lock,
  Mic,
  RotateCcw,
  Sparkles,
  Target,
} from "lucide-react";
import {ApiException, dashboardApi, learningPlanApi} from "@/lib/api";
import {
  trackAudienceEvent,
  withTrafficSource,
} from "@/lib/audience";
import {useAuth} from "@/lib/auth-context";
import {
  competenceHref,
  PLAN_MILESTONE_SECTION_TEXT,
  PLAN_MILESTONE_SECTION_TITLE,
  productionSectionLabel,
  recommendedExerciseHref,
} from "@/lib/diagnostic";
import {PlanMilestoneCard} from "./PlanMilestoneCard";
import {
  planDoneSectionCta,
  planPathSubtitle,
  PLAN_STEP_BADGE_DONE,
  PLAN_STEP_DONE_MARK_LABEL,
} from "@/lib/plan-step";
import {competenceProgressLabel} from "@/lib/skill-progress";
import {
  type DashboardSummaryResponse,
  estimatedTcfLevelScopeLabel,
  type LearningPlanCompletedStepDto,
  type LearningPlanDto,
  type LearningPlanPriorityDto,
  type LearningPlanSkillDto,
  niveauCecrlLabel,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {
  LearningPlanStatusPill,
  RowChevron,
  SKILL_PREMIUM_HREF,
  SkillAccent,
  SkillLockBadge,
  SkillMasteryPill,
  SkillRing,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import styles from "./plan.module.css";

/** Nombre de compétences observées affichées avant le repli — le brief §20
 *  interdit de dérouler les 48 d'un coup. */
const VISIBLE_SKILLS = 6;

/**
 * Un cadenas du Plan qui renvoie au paiement, c'est LA mesure de conversion du
 * verrou freemium : sans elle, on saurait combien de candidats voient le Plan,
 * jamais combien le verrou en envoie vers l'abonnement. L'événement est
 * autorisé côté serveur sur `/plan` — et c'est le seul qu'on émette ici.
 */
function trackPremiumClick() {
  trackAudienceEvent("/plan", "DIAGNOSTIC_TO_PREMIUM_CLICKED");
}

function formatDate(value: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat("fr-FR", {day: "numeric", month: "long", year: "numeric"}).format(date);
}

function plural(count: number): string {
  return count > 1 ? "s" : "";
}

export function LearningPlanView() {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const trafficSource = useTrafficSource();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setPlan(await learningPlanApi.get());
    } catch (cause) {
      setError(cause instanceof ApiException ? cause.message : "Impossible de charger votre plan.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authStatus === "loading") return;
    if (!user) return;
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => {
        if (cancelled) return;
        setPlan(current);
        setError(null);
      },
      (cause: unknown) => {
        if (!cancelled) {
          setError(cause instanceof ApiException ? cause.message : "Impossible de charger votre plan.");
        }
      },
    ).finally(() => {
      if (!cancelled) setLoading(false);
    });
    return () => { cancelled = true; };
  }, [authStatus, user]);

  useEffect(() => {
    if (!user) return;
    trackAudienceEvent("/plan", "PLAN_OPENED", {once: true});
  }, [user]);

  if (authStatus === "loading" || (Boolean(user) && loading)) return <PlanSkeleton />;
  if (!user) {
    const planHref = withTrafficSource("/plan", trafficSource);
    return (
      <PlanShell>
        <EmptyCard
          icon={<ListChecks size={28} />}
          title="Connectez-vous pour retrouver votre plan"
          text="Vos priorités restent synchronisées avec vos productions."
        >
          <Link className={styles.primaryButton} href={`/connexion?next=${encodeURIComponent(planHref)}`}>Se connecter</Link>
        </EmptyCard>
      </PlanShell>
    );
  }
  if (!plan) {
    return (
      <PlanShell>
        <EmptyCard
          icon={<RotateCcw size={28} />}
          title="Votre plan n'a pas pu être chargé"
          text={error ?? "Réessayez dans un instant."}
          role="alert"
        >
          <button className={styles.primaryButton} type="button" onClick={() => void load()}>Réessayer</button>
        </EmptyCard>
      </PlanShell>
    );
  }

  if (plan.state === "NEEDS_DIAGNOSTIC") {
    return (
      <PlanShell>
        <PlanHeader
          title="Mon plan"
          text="La prochaine action utile, sans tableau de chiffres à décoder."
        />
        <EmptyCard
          icon={<Target size={28} />}
          title="Construisons votre plan personnalisé"
          text="Faites 1 exercice écrit et 1 oral pour identifier vos premières priorités."
        >
          <Link className={styles.primaryButton} href="/diagnostic">Faire mon diagnostic <ArrowRight size={17} aria-hidden /></Link>
        </EmptyCard>
        <ClassicTraining />
      </PlanShell>
    );
  }

  if (plan.state === "DIAGNOSTIC_IN_PROGRESS") {
    return (
      <PlanShell>
        <PlanHeader
          title="Votre diagnostic est en cours"
          text="Reprenez exactement à l'étape enregistrée. Une production déjà reçue ne sera pas redemandée."
        />
        <EmptyCard
          icon={<Clock3 size={28} />}
          title="Terminez vos deux exercices"
          text="Votre première priorité apparaîtra dès que l'écrit et l'oral auront été analysés."
        >
          <Link className={styles.primaryButton} href="/diagnostic">Reprendre mon diagnostic <ArrowRight size={17} aria-hidden /></Link>
        </EmptyCard>
      </PlanShell>
    );
  }

  return <ActivePlan plan={plan} targetLevel={user.targetLevel ?? null} />;
}

function ActivePlan({plan, targetLevel}: {plan: LearningPlanDto; targetLevel: string | null}) {
  // Le niveau TCF estimé d'un candidat n'a qu'une surface autorisée :
  // `GET /api/me/dashboard`. On lit le même agrégat mémorisé que la sidebar et
  // le tableau de bord, on ne recalcule rien — et son absence ne dégrade que le
  // bandeau, jamais le plan lui-même.
  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  useEffect(() => {
    let cancelled = false;
    dashboardApi.summaryCached().then(
      (current) => { if (!cancelled) setSummary(current); },
      () => { /* confort d'affichage : un échec ne remonte pas à l'écran */ },
    );
    return () => { cancelled = true; };
  }, []);

  const observed = useMemo(
    () => plan.observedSkills.filter((skill) => skill.status !== "NOT_OBSERVED"),
    [plan.observedSkills],
  );
  const activeSteps = useMemo<Array<{priority: LearningPlanPriorityDto; current: boolean}>>(
    () => [
      ...(plan.currentPriority ? [{priority: plan.currentPriority, current: true}] : []),
      // Une courante + **deux** suivantes, comme le serveur en sert au plus
      // (`LearningPlanPriorityResolver.MAX_PRIORITIES = 3`) et comme le mobile
      // en affiche (`plan.nextPriorities.take(2)`).
      ...plan.nextPriorities.slice(0, 2).map((priority) => ({priority, current: false})),
    ],
    [plan.currentPriority, plan.nextPriorities],
  );
  /* Le parcours s'ouvre sur les priorités **actives**, numérotées à partir de
     1 — l'étape courante puis les suivantes. Les étapes **franchies** vivent
     dessous, repliées : servies par cinq, en tête elles repoussaient la
     priorité en 6ᵉ position, hors écran. Elles restent consultables, elles ne
     s'imposent plus. Ordre et borne viennent du serveur : on ne trie ni ne
     reborne rien. */
  const completedSteps = plan.completedSteps ?? [];
  const path = useMemo<PathEntry[]>(
    () => activeSteps.map(({priority, current}): PathEntry => ({kind: "active", priority, current})),
    [activeSteps],
  );
  const diagnosticDate = formatDate(plan.diagnosticCompletedAt);

  return (
    <PlanShell>
      <PlanHeader
        title="Votre chemin, étape par étape"
        text="Construit à partir de votre diagnostic et de vos dernières productions. Une seule action à la fois."
      />

      <PlanHero
        estimatedLevel={summary?.estimatedTcfLevel ?? null}
        scopeLabel={estimatedTcfLevelScopeLabel(summary)}
        targetLevel={targetLevel}
        priorities={activeSteps.length}
        activitiesThisWeek={plan.activitiesThisWeek}
        observedSkillCount={plan.observedSkillCount}
      />

      <BlockHead
        title="À faire maintenant"
        text="Votre priorité principale, et l'exercice qui la travaille."
      />
      {plan.currentPriority ? (
        <TodayCard priority={plan.currentPriority} />
      ) : (
        <EmptyCard
          icon={<Sparkles size={28} />}
          title="Votre prochaine priorité se prépare"
          text="Continuez une production ciblée : le Plan se réordonnera avec les nouvelles observations."
        >
          <Link className={styles.primaryButton} href="/entrainement?module=TCF">Continuer l&apos;entraînement</Link>
        </EmptyCard>
      )}

      {/* Sans aucune étape — ni active, ni franchie — un « chemin » ne
          raconterait rien : on ne l'affiche pas. */}
      {(path.length > 0 || completedSteps.length > 0) && (
        <>
          <BlockHead
            title="Votre parcours"
            text={planPathSubtitle(activeSteps.length)}
          />
          {path.length > 0 && <PlanPath path={path} />}
          <CompletedStepsBlock steps={completedSteps} />
        </>
      )}

      {/* Le jalon vit SOUS les priorités, jamais à leur place : c'est un cran
          au-dessus des étapes, pas un remplaçant. `milestone === null` est le
          cas NORMAL (rien à mesurer, ou examen blanc tout juste passé) — rien
          ne s'affiche, ni indicateur, ni message. */}
      {plan.milestone && (
        <>
          <BlockHead title={PLAN_MILESTONE_SECTION_TITLE} text={PLAN_MILESTONE_SECTION_TEXT} />
          <PlanMilestoneCard milestone={plan.milestone} onPremiumClick={trackPremiumClick} />
        </>
      )}

      <ObservedSkills skills={observed} total={plan.observedSkillCount} />

      <div className={styles.bottomGrid}>
        <section className={styles.diagnosticLink}>
          <span className={styles.sectionIcon} aria-hidden><ListChecks size={20} /></span>
          <div>
            <span>Diagnostic initial</span>
            <b>{diagnosticDate ? `Réalisé le ${diagnosticDate}` : "Diagnostic réalisé"}</b>
          </div>
          <Link href="/diagnostic">Voir mon diagnostic <ArrowRight size={15} aria-hidden /></Link>
        </section>
      </div>
    </PlanShell>
  );
}

/* ------------------------------------------------------------------ bandeau */

function PlanHero({
  estimatedLevel,
  scopeLabel,
  targetLevel,
  priorities,
  activitiesThisWeek,
  observedSkillCount,
}: {
  estimatedLevel: DashboardSummaryResponse["estimatedTcfLevel"];
  scopeLabel: string | null;
  targetLevel: string | null;
  priorities: number;
  activitiesThisWeek: number;
  observedSkillCount: number;
}) {
  return (
    <section className={styles.hero} aria-labelledby="plan-hero-title">
      <div className={styles.heroTop}>
        <div className={styles.heroLevels}>
          <p className={styles.heroLabel} id="plan-hero-title">
            {estimatedLevel ? "Niveau estimé aujourd'hui" : "Votre objectif TCF"}
          </p>
          <p className={styles.heroLevelLine}>
            {estimatedLevel && (
              <>
                <b>{niveauCecrlLabel(estimatedLevel)}</b>
                {targetLevel && <span className={styles.heroArrow} aria-hidden>→</span>}
              </>
            )}
            {targetLevel ? (
              <b className={styles.heroTarget}>{targetLevel}</b>
            ) : (
              !estimatedLevel && <b className={styles.heroTarget}>TCF</b>
            )}
          </p>
        </div>
        {/* La pastille ne redit l'objectif que si la ligne de niveaux montre
            autre chose que lui — sinon elle ferait doublon. */}
        {estimatedLevel && targetLevel && (
          <span className={styles.heroBadge}>
            <Target size={13} aria-hidden /> Objectif {targetLevel}
          </span>
        )}
      </div>

      <p className={styles.heroCopy}>
        {estimatedLevel
          ? "Votre plan cible l'écart entre ce que vous produisez déjà et ce qui est attendu au niveau visé."
          : "Votre niveau estimé apparaîtra dès qu'une épreuve aura été réellement passée. En attendant, votre plan cible ce que vos productions ont révélé."}
      </p>
      {scopeLabel && <p className={styles.heroScope}>{scopeLabel}</p>}

      <ul className={styles.heroStats}>
        <li>
          <b>{priorities}</b>
          <span>priorité{plural(priorities)} active{plural(priorities)}</span>
        </li>
        <li>
          <b>{activitiesThisWeek}</b>
          <span>activité{plural(activitiesThisWeek)} cette semaine</span>
        </li>
        <li>
          <b>{observedSkillCount}</b>
          <span>compétence{plural(observedSkillCount)} observée{plural(observedSkillCount)}</span>
        </li>
      </ul>

      <p className={styles.heroFoot}>Estimation d&apos;entraînement, non officielle.</p>
    </section>
  );
}

/* ------------------------------------------------------- à faire maintenant */

/**
 * Le verrou ne retire **rien** de ce que le candidat a appris de sa propre
 * production : la priorité et l'exercice visé restent écrits. Seule la
 * destination du bouton change — ouvrir un sujet que le serveur refusera en
 * 403 ne rendrait service à personne.
 *
 * Le constat détaillé de l'observation (`priority.explanation`) n'est PAS
 * affiché ici : c'est le résultat d'une production déjà faite, il raconte le
 * passé sur une carte qui annonce l'action à mener. Le champ reste sur le DTO
 * (`LearningPlanPriorityDto.explanation`) et peut être servi ailleurs — ne
 * pas le réafficher sur cette carte.
 */
function TodayCard({priority}: {priority: LearningPlanPriorityDto}) {
  const exercise = priority.recommendedExercise;
  const locked = priority.locked || exercise?.locked === true;
  // Assez travaillée en ciblé, pas encore prouvée en situation : la même carte,
  // au même endroit, cesse de proposer un micro-sujet et propose une
  // vérification sur une vraie tâche TCF. Jamais une seconde carte à côté.
  const check = exercise?.kind === "REASSESSMENT";
  return (
    <section className={styles.today} aria-labelledby="today-title">
      <div className={styles.todayTop}>
        <div>
          <span className={styles.todayPill}>Priorité n°1</span>
          {locked && <span className={styles.lockAside}><SkillLockBadge /></span>}
          <h3 id="today-title">{priority.title}</h3>
        </div>
        {exercise && (
          <span className={styles.todayDuration}>
            <Clock3 size={15} aria-hidden /> ≈ {exercise.estimatedMinutes} min
          </span>
        )}
      </div>

      {/* Le Plan ne nomme QUE des compétences, jamais un sujet : le titre de
          l'exercice vit sur l'écran d'étape, où le candidat voit les 5 et
          choisit. « Commencer » l'y emmène. Seule la vérification lance encore
          une production directement — c'est une tâche d'examen, pas un
          micro-sujet, et elle n'a pas de liste où atterrir. */}
      {locked ? (
        <>
          <Link
            className={`${styles.primaryButton} ${styles.todayCta}`}
            href={SKILL_PREMIUM_HREF}
            onClick={trackPremiumClick}
          >
            <Lock size={16} aria-hidden /> Débloquer cet exercice
          </Link>
          <p className={styles.lockNote}>
            Cet exercice fait partie de l&apos;abonnement Intégral. Votre plan, lui,
            reste entier.
          </p>
        </>
      ) : exercise ? (
        <Link
          className={`${styles.primaryButton} ${styles.todayCta}`}
          href={check ? recommendedExerciseHref(exercise) : competenceHref(priority, {planStep: true})}
          onClick={
            check
              ? () => trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED")
              : undefined
          }
        >
          {check ? "Vérifier ma progression" : "Commencer"} <ArrowRight size={17} aria-hidden />
        </Link>
      ) : (
        <Link
          className={`${styles.primaryButton} ${styles.todayCta}`}
          href={`/entrainement/tcf/${priority.section.toLowerCase()}`}
        >
          Ouvrir l&apos;épreuve <ArrowRight size={17} aria-hidden />
        </Link>
      )}
    </section>
  );
}

/* -------------------------------------------------------------- le parcours */

/**
 * Une entrée du parcours : une étape **franchie** (cochée) ou une étape active
 * (courante ou à venir). Union discriminée — une carte franchie n'a ni exercice
 * ni cadenas, le type l'impose plutôt qu'une convention à relire.
 */
type PathEntry =
  | {kind: "done"; step: LearningPlanCompletedStepDto}
  | {kind: "active"; priority: LearningPlanPriorityDto; current: boolean};

/**
 * Le chemin en étapes numérotées verticales — colonne vertébrale de l'écran.
 *
 * Les étapes sont **reliées** par un filet continu : c'est ce qui les fait lire
 * comme un chemin et non comme une pile de cartes.
 *
 * 🛑 **Aucun élément décoratif de fin.** Une carte « Réévaluation / Prochaine
 * vérification » était rendue en dur ici : elle ne venait d'aucun champ du DTO,
 * ne portait aucun lien et annonçait une action qui n'existait pas. La
 * vérification, quand elle est réellement disponible, est portée par l'étape
 * courante elle-même (`recommendedExercise.kind === "REASSESSMENT"`).
 *
 * La numérotation est **continue sur toute la liste** : les étapes franchies
 * occupent les premiers rangs, l'étape en cours et les suivantes continuent la
 * série — aucun numéro dupliqué ni sauté quand le nombre de franchies change.
 */
/**
 * Les étapes franchies, **sous** le parcours et **repliées par défaut**.
 *
 * Elles s'accumulent (le serveur en sert 5) : en tête de liste, elles
 * repoussaient la priorité en 6ᵉ position, hors écran — l'inverse de ce que le
 * Plan doit faire. Elles n'ont pas de numéro : elles ne sont plus des rangs du
 * chemin, mais ce qui a déjà été franchi.
 */
function CompletedStepsBlock({steps}: {steps: LearningPlanCompletedStepDto[]}) {
  const [open, setOpen] = useState(false);
  if (steps.length === 0) return null;
  return (
    <div className={styles.doneBlock}>
      <button
        type="button"
        className={styles.doneToggle}
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <Check size={15} strokeWidth={3} aria-hidden />
        {planDoneSectionCta(steps.length, open)}
      </button>
      {open && (
        <SkillAccent>
          <ol className={styles.path}>
            {steps.map((step, index) => (
              <CompletedPathStep
                key={step.skillId}
                step={step}
                index={index + 1}
                last={index === steps.length - 1}
              />
            ))}
          </ol>
        </SkillAccent>
      )}
    </div>
  );
}

function PlanPath({path}: {path: PathEntry[]}) {
  return (
    <SkillAccent>
      <ol className={styles.path}>
        {path.map((entry, index) =>
          entry.kind === "done" ? (
            <CompletedPathStep
              key={entry.step.skillId}
              step={entry.step}
              index={index + 1}
              last={index === path.length - 1}
            />
          ) : (
            <PathStep
              key={entry.priority.skillId}
              priority={entry.priority}
              index={index + 1}
              current={entry.current}
              last={index === path.length - 1}
            />
          ),
        )}
      </ol>
    </SkillAccent>
  );
}

/**
 * Une étape **franchie** : à la place de son numéro, une **coche**, et la
 * pastille passe au vert.
 *
 * Sobre par construction — titre, code · épreuve, compteurs d'étape — et
 * **sans aucun bouton d'action** : il n'y a plus rien à y faire, et ce n'est pas
 * une porte commerciale (le DTO ne porte d'ailleurs ni exercice ni `locked`).
 * Elle reste **cliquable** et ouvre l'écran d'étape, pour se relire.
 *
 * ⚠️ La coche ne dépend **pas** de `masteryState` : sur un compte réel une seule
 * compétence franchie est `SOLID`, les autres sont `CONSOLIDATING`.
 * L'appartenance à `completedSteps` **est** la coche.
 */
function CompletedPathStep({
  step,
  index,
  last,
}: {
  step: LearningPlanCompletedStepDto;
  index: number;
  last: boolean;
}) {
  return (
    <li className={`${styles.step} ${last ? styles.stepLast : ""}`}>
      <span className={`${styles.stepMark} ${styles.stepMarkDone}`} role="img" aria-label={`${PLAN_STEP_DONE_MARK_LABEL} ${index}`}>
        <Check size={17} strokeWidth={3} aria-hidden />
      </span>
      <Link className={`${styles.stepCard} ${styles.stepCardDone}`} href={competenceHref(step, {planStep: true})}>
        <div className={styles.stepHead}>
          <span className={styles.stepState} data-state="done">{PLAN_STEP_BADGE_DONE}</span>
          <span className={styles.stepMeta}>
            {step.skillCode} · {productionSectionLabel(step.section)}
          </span>
        </div>

        {/* Pas d'anneau de sujets sur une etape franchie : c'est l'ETAPE qui
            est cochee, pas ses micro-sujets. Une competence prouvee par de
            vraies productions n'en a souvent traite aucun, et l'anneau
            affichait alors « 0/5 » a cote de « Terminee » — exact, et
            illisible. La coche dit tout ce qu'il y a a dire. */}
        <div className={styles.stepBody}>
          <div className={styles.stepBodyText}>
            <h3 className={styles.stepTitle}>{step.title}</h3>
          </div>
          <span className={styles.stepChevron}><RowChevron /></span>
        </div>
      </Link>
    </li>
  );
}

function PathStep({
  priority,
  index,
  current,
  last,
}: {
  priority: LearningPlanPriorityDto;
  index: number;
  current: boolean;
  last: boolean;
}) {
  const exercise = priority.recommendedExercise;
  // Une étape, ce sont les 5 premiers sujets de la compétence — jamais ses 15.
  // L'état « terminée » est **servi** (`stepCompleted`), plus déduit d'une
  // comparaison locale : c'est le serveur qui sait ce qui compose une étape.
  const done = priority.stepCompleted;
  const partiallyValidated = done && priority.stepValidatedCount < priority.stepPromptCount;
  // Le verrou est **lu**, jamais déduit du rang de l'étape : si le serveur
  // change sa règle d'ouverture, cet écran suit sans une ligne à retoucher.
  const locked = priority.locked || exercise?.locked === true;
  // L'étape courante change de NATURE quand le serveur juge la compétence assez
  // travaillée en ciblé sans preuve de transfert : même carte, même place, mais
  // on ne propose plus un micro-sujet — on va vérifier en situation.
  const check = current && exercise?.kind === "REASSESSMENT";
  return (
    <li className={`${styles.step} ${current ? styles.stepCurrent : ""} ${last ? styles.stepLast : ""}`}>
      <span className={`${styles.stepMark} ${current ? styles.stepMarkCurrent : ""}`} aria-hidden>
        {index}
      </span>
      <div className={`${styles.stepCard} ${current ? styles.stepCardCurrent : ""}`}>
        <div className={styles.stepHead}>
          <span
            className={styles.stepState}
            data-state={check ? "check" : current ? (done ? "done" : "current") : "next"}
          >
            {check ? "Vérification" : current ? (done ? "Terminée" : "En cours") : "À venir"}
          </span>
          {locked && <SkillLockBadge />}
          <span className={styles.stepMeta}>
            {priority.skillCode} · {productionSectionLabel(priority.section)}
          </span>
        </div>

        <div className={styles.stepBody}>
          <SkillRing
            attempted={priority.stepAttemptedCount}
            total={priority.stepPromptCount}
            done={done}
          />
          <div className={styles.stepBodyText}>
            <h3 className={styles.stepTitle}>{priority.title}</h3>
            {/* Une étape terminée RESTE affichée : les priorités ne bougent
                qu'à la prochaine production. Sans cette phrase, un candidat qui
                a fini son étape et la voit toujours là croit à un bug. */}
            {done && <p className={styles.stepDone}>Réévaluée à ta prochaine production.</p>}
            {/* Terminer n'est pas tout réussir — la distinction se voit ici, et
                seulement quand elle apprend quelque chose. */}
            {partiallyValidated && (
              <p className={styles.stepValidated}>
                {priority.stepValidatedCount} validés sur {priority.stepPromptCount}
              </p>
            )}
          </div>
        </div>

        {/* Ni citation de la production, ni explication ici. Le Plan répond à
            « que travailler maintenant ? » : relire ce qu'on a rendu a déjà son
            endroit (le sujet, atteint par l'exercice ci-dessous), et
            l'explication de la priorité n°1 vit dans « À faire maintenant » —
            l'étape 1 EST cette priorité, la redire deux fois n'apprend rien.
            Miroir de `_CurrentStepCard` / `_NextStepCard` côté mobile. */}

        {/* ⚠️ La carte d'étape NE NOMME PLUS l'exercice (décision propriétaire) :
            un seul endroit nomme ce qu'il y a à faire — « À faire maintenant »
            pour l'action immédiate, l'écran d'étape pour la liste des sujets.
            « Continuer cette étape » ouvre donc les 5 sujets de l'étape, et le
            candidat voit enfin LESQUELS sont les siens avant de s'y remettre.
            🛑 **Sauf pour une vérification** : là, le candidat vient
            précisément de terminer ces 5 sujets — l'y renvoyer serait un
            cul-de-sac. La carte garde alors son comportement d'origine et lance
            la vraie production par `recommendedExerciseHref`. */}
        {current && exercise && (
          locked ? (
            <Link
              className={styles.stepCtaStrong}
              href={SKILL_PREMIUM_HREF}
              aria-label={`Débloquer cette étape : ${priority.title}`}
              onClick={trackPremiumClick}
            >
              <Lock size={15} aria-hidden /> Débloquer cette étape
            </Link>
          ) : check ? (
            <Link
              className={styles.stepCtaStrong}
              href={recommendedExerciseHref(exercise)}
              aria-label={`Vérifier ma progression : ${priority.title}`}
              onClick={() => trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED")}
            >
              Vérifier ma progression <ArrowRight size={16} aria-hidden />
            </Link>
          ) : (
            /* Pas d'événement « exercice démarré » ici : ce lien n'en démarre
               plus aucun, il ouvre une liste. La mesure du funnel reste portée
               par « À faire maintenant », qui lance toujours l'exercice. */
            <Link
              className={styles.stepCtaStrong}
              href={competenceHref(priority, {planStep: true})}
              aria-label={`Continuer cette étape : ${priority.title}`}
            >
              Continuer cette étape <ArrowRight size={16} aria-hidden />
            </Link>
          )
        )}
      </div>
    </li>
  );
}

/* ------------------------------------------------- mes compétences observées */

/**
 * Les compétences du Plan portent **exactement** l'anatomie de carte de
 * « Réviser → EE/EO → Compétences » : anneau de progression réel, titre, état en
 * clair (`competenceProgressLabel`, libellé partagé avec le mobile), pastille
 * d'état, chevron. Ce sont les mêmes compétences — elles doivent se ressembler,
 * et le clic ouvre la même fiche.
 */
function ObservedSkills({skills, total}: {skills: LearningPlanSkillDto[]; total: number}) {
  if (skills.length === 0) return null;
  return (
    <section aria-labelledby="skills-title">
      <BlockHead
        title="Mes compétences observées"
        text="Uniquement ce qui a été réellement observé dans vos productions."
        titleId="skills-title"
        aside={`${total} observée${plural(total)}`}
      />
      <SkillAccent>
        <div className={styles.skillGrid}>
          {skills.slice(0, VISIBLE_SKILLS).map((skill) => <SkillCard key={skill.skillId} skill={skill} />)}
        </div>
        {skills.length > VISIBLE_SKILLS && (
          <details className={styles.moreSkills}>
            <summary>Voir toutes mes compétences observées <ChevronDown size={15} aria-hidden /></summary>
            <div className={styles.skillGrid}>
              {skills.slice(VISIBLE_SKILLS).map((skill) => <SkillCard key={skill.skillId} skill={skill} />)}
            </div>
          </details>
        )}
      </SkillAccent>
    </section>
  );
}

/** Verrouillée, la compétence garde son anneau, son état et sa pastille : c'est
 *  le résultat de la propre production du candidat, le masquer serait le lui
 *  reprendre. Seule la destination change.
 *
 *  La pastille dit l'état de maîtrise (tout l'historique) dès que le serveur en
 *  a un ; sans observation agrégée, elle retombe sur le verdict de la dernière
 *  production. **Jamais les deux** : « Priorité » et « Prioritaire » côte à côte
 *  se liraient comme deux informations, alors que c'est la même.
 *
 *  Le lien porte le marqueur d'étape (`?etape=1`) : ouverte **depuis le Plan**,
 *  une compétence qui est encore une priorité s'affiche à l'échelle de son
 *  étape (« 2/5 »), pas de la compétence entière (« 1/15 »). Si elle n'en est
 *  plus une — le serveur l'en sort dès qu'une vérification a réussi —, l'écran
 *  retombe **silencieusement** sur la fiche complète. */
function SkillCard({skill}: {skill: LearningPlanSkillDto}) {
  const done = skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount;
  const locked = skill.locked;
  return (
    <Link
      href={locked ? SKILL_PREMIUM_HREF : competenceHref(skill, {planStep: true})}
      onClick={locked ? trackPremiumClick : undefined}
      className={`${s.card} ${s.rowCard} ${s.ringRow}`}
    >
      <SkillRing attempted={skill.attemptedCount} total={skill.promptCount} done={done} />
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{skill.title}</span>
        <span className={s.rowText}>{productionSectionLabel(skill.section)}</span>
        <span className={s.rowState}>{competenceProgressLabel(skill)}</span>
      </span>
      <span className={styles.skillAside}>
        {locked && <SkillLockBadge />}
        {skill.masteryState ? (
          <SkillMasteryPill state={skill.masteryState} />
        ) : (
          <LearningPlanStatusPill status={skill.status} />
        )}
        <RowChevron />
      </span>
    </Link>
  );
}

/* --------------------------------------------------------------- structures */

function PlanHeader({title, text}: {title: string; text: string}) {
  return (
    <header className={styles.header}>
      <p className={styles.eyebrow}><ListChecks size={15} aria-hidden /> Plan personnalisé</p>
      <h1>{title}</h1>
      <p>{text}</p>
    </header>
  );
}

function BlockHead({
  title,
  text,
  titleId,
  aside,
}: {
  title: string;
  text?: string;
  titleId?: string;
  aside?: string;
}) {
  return (
    <div className={styles.blockHead}>
      <div>
        <h2 id={titleId}>{title}</h2>
        {text && <p>{text}</p>}
      </div>
      {aside && <span>{aside}</span>}
    </div>
  );
}

function ClassicTraining() {
  return (
    <section className={styles.classic} aria-labelledby="classic-title">
      <h2 id="classic-title">Vous pouvez aussi vous entraîner librement</h2>
      <div>
        <Link href="/entrainement/tcf/ee"><FilePenLine size={19} aria-hidden /><span><b>Expression écrite</b><small>Productions et compétences</small></span><ArrowRight size={16} aria-hidden /></Link>
        <Link href="/entrainement/tcf/eo"><Headphones size={19} aria-hidden /><span><b>Expression orale</b><small>Enregistrements et simulations</small></span><ArrowRight size={16} aria-hidden /></Link>
      </div>
    </section>
  );
}

function EmptyCard({icon, title, text, children, role}: {icon: ReactNode; title: string; text: string; children: ReactNode; role?: "alert"}) {
  return (
    <section className={styles.emptyCard} role={role}>
      <span className={styles.emptyIcon} aria-hidden>{icon}</span>
      <h2>{title}</h2>
      <p>{text}</p>
      <div className={styles.actions}>{children}</div>
    </section>
  );
}

function PlanShell({children}: {children: ReactNode}) {
  return <main className={styles.page}>{children}</main>;
}

function PlanSkeleton() {
  return <main className={styles.page} aria-busy="true" aria-label="Chargement du plan"><div className={styles.skeletonHead} /><div className={styles.skeletonHero} /><div className={styles.skeletonGrid}><span /><span /></div></main>;
}
