"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useState, type ReactNode} from "react";
import {
  ArrowRight,
  CalendarCheck,
  ChevronDown,
  Clock3,
  FilePenLine,
  Headphones,
  ListChecks,
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
  LEARNING_PLAN_SKILL_STATUS_LABEL,
  productionSectionLabel,
  recommendedExerciseHref,
} from "@/lib/diagnostic";
import {competenceProgressLabel} from "@/lib/skill-progress";
import {
  type DashboardSummaryResponse,
  estimatedTcfLevelScopeLabel,
  type LearningPlanDto,
  type LearningPlanPriorityDto,
  type LearningPlanSkillDto,
  type LearningPlanSkillStatus,
  niveauCecrlLabel,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {
  RowChevron,
  SkillAccent,
  SkillBadge,
  type SkillBadgeTone,
  SkillRing,
} from "@/app/_components/skill-ui/SkillLayout";
import s from "@/app/_components/skill-ui/skill.module.css";
import styles from "./plan.module.css";

/** Pastille d'état, empruntée telle quelle au module Compétences : le Plan et
 *  « Réviser → Compétences » parlent des mêmes compétences, ils doivent se
 *  ressembler. */
const SKILL_BADGE_TONE: Record<LearningPlanSkillStatus, SkillBadgeTone> = {
  NOT_OBSERVED: "todo",
  PRIORITY: "priority",
  TO_REINFORCE: "reinforce",
  SOLID: "validated",
};

/** Nombre de compétences observées affichées avant le repli — le brief §20
 *  interdit de dérouler les 48 d'un coup. */
const VISIBLE_SKILLS = 6;

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
  const steps = useMemo<Array<{priority: LearningPlanPriorityDto; current: boolean}>>(
    () => [
      ...(plan.currentPriority ? [{priority: plan.currentPriority, current: true}] : []),
      ...plan.nextPriorities.slice(0, 3).map((priority) => ({priority, current: false})),
    ],
    [plan.currentPriority, plan.nextPriorities],
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
        priorities={steps.length}
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

      {/* Sans aucune priorité, un « chemin » réduit à sa dernière étape ne
          raconterait rien : on ne l'affiche pas. */}
      {steps.length > 0 && (
        <>
          <BlockHead
            title="Votre parcours"
            text={`${steps.length} priorité${plural(steps.length)} active${plural(steps.length)}, puis une vérification.`}
          />
          <PlanPath steps={steps} />
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

function TodayCard({priority}: {priority: LearningPlanPriorityDto}) {
  const exercise = priority.recommendedExercise;
  return (
    <section className={styles.today} aria-labelledby="today-title">
      <div className={styles.todayTop}>
        <div>
          <span className={styles.todayPill}>Priorité n°1</span>
          <h3 id="today-title">{priority.title}</h3>
          <p>{priority.explanation ?? "Cette compétence est votre prochaine priorité utile."}</p>
        </div>
        {exercise && (
          <span className={styles.todayDuration}>
            <Clock3 size={15} aria-hidden /> ≈ {exercise.estimatedMinutes} min
          </span>
        )}
      </div>

      {exercise && (
        <div className={styles.todayTask}>
          <span className={styles.todayTaskIcon} aria-hidden>
            {exercise.section === "EE" ? <FilePenLine size={17} /> : <Mic size={17} />}
          </span>
          <span>
            <b>{exercise.title}</b>
            <small>{productionSectionLabel(exercise.section)} · {exercise.skillCode}</small>
          </span>
        </div>
      )}

      {exercise ? (
        <Link
          className={`${styles.primaryButton} ${styles.todayCta}`}
          href={recommendedExerciseHref(exercise)}
          onClick={() => trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED")}
        >
          Commencer <ArrowRight size={17} aria-hidden />
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
 * Le chemin en étapes numérotées verticales — colonne vertébrale de l'écran.
 *
 * Les étapes sont **reliées** par un filet continu : c'est ce qui les fait lire
 * comme un chemin et non comme une pile de cartes. La dernière étape est
 * toujours la réévaluation, qui flottait jusqu'ici à part alors qu'elle est
 * précisément la fin du parcours.
 */
function PlanPath({steps}: {steps: Array<{priority: LearningPlanPriorityDto; current: boolean}>}) {
  return (
    <SkillAccent>
      <ol className={styles.path}>
        {steps.map(({priority, current}, index) => (
          <PathStep
            key={priority.skillId}
            priority={priority}
            index={index + 1}
            current={current}
          />
        ))}
        <li className={`${styles.step} ${styles.stepLast}`}>
          <span className={styles.stepMark} aria-hidden><CalendarCheck size={17} /></span>
          <div className={`${styles.stepCard} ${styles.stepCardFinal}`}>
            <div className={styles.stepHead}>
              <span className={styles.stepState} data-state="later">Réévaluation</span>
            </div>
            <h3 className={styles.stepTitle}>Prochaine vérification</h3>
            <p className={styles.stepText}>
              Après quelques entraînements, une nouvelle production permettra de vérifier si
              cette faiblesse est réellement corrigée.
            </p>
          </div>
        </li>
      </ol>
    </SkillAccent>
  );
}

function PathStep({
  priority,
  index,
  current,
}: {
  priority: LearningPlanPriorityDto;
  index: number;
  current: boolean;
}) {
  const exercise = priority.recommendedExercise;
  const done = priority.promptCount > 0 && priority.attemptedCount >= priority.promptCount;
  return (
    <li className={`${styles.step} ${current ? styles.stepCurrent : ""}`}>
      <span className={`${styles.stepMark} ${current ? styles.stepMarkCurrent : ""}`} aria-hidden>
        {index}
      </span>
      <div className={`${styles.stepCard} ${current ? styles.stepCardCurrent : ""}`}>
        <div className={styles.stepHead}>
          <span className={styles.stepState} data-state={current ? "current" : "next"}>
            {current ? "En cours" : "À venir"}
          </span>
          <span className={styles.stepMeta}>
            {priority.skillCode} · {productionSectionLabel(priority.section)}
          </span>
        </div>

        <div className={styles.stepBody}>
          <SkillRing
            attempted={priority.attemptedCount}
            total={priority.promptCount}
            done={done}
          />
          <div className={styles.stepBodyText}>
            <h3 className={styles.stepTitle}>{priority.title}</h3>
          </div>
        </div>

        {/* Ni citation de la production, ni explication ici. Le Plan répond à
            « que travailler maintenant ? » : relire ce qu'on a rendu a déjà son
            endroit (le sujet, atteint par l'exercice ci-dessous), et
            l'explication de la priorité n°1 vit dans « À faire maintenant » —
            l'étape 1 EST cette priorité, la redire deux fois n'apprend rien.
            Miroir de `_CurrentStepCard` / `_NextStepCard` côté mobile. */}

        {current && exercise && (
          <>
            <div className={styles.stepTask}>
              <span className={styles.stepTaskIcon} aria-hidden>
                {exercise.section === "EE" ? <FilePenLine size={16} /> : <Mic size={16} />}
              </span>
              <span>
                <b>{exercise.title}</b>
                <small>{productionSectionLabel(exercise.section)} · {exercise.estimatedMinutes} min</small>
              </span>
            </div>
            <Link
              className={styles.stepCtaStrong}
              href={recommendedExerciseHref(exercise)}
              aria-label={`Continuer cette étape : ${priority.title}`}
              onClick={() => trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED")}
            >
              Continuer cette étape <ArrowRight size={16} aria-hidden />
            </Link>
          </>
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

function SkillCard({skill}: {skill: LearningPlanSkillDto}) {
  const done = skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount;
  return (
    <Link href={competenceHref(skill)} className={`${s.card} ${s.rowCard} ${s.ringRow}`}>
      <SkillRing attempted={skill.attemptedCount} total={skill.promptCount} done={done} />
      <span className={s.rowBody}>
        <span className={s.rowTitle}>{skill.title}</span>
        <span className={s.rowText}>{productionSectionLabel(skill.section)}</span>
        <span className={s.rowState}>{competenceProgressLabel(skill)}</span>
      </span>
      <span className={styles.skillAside}>
        <SkillBadge tone={SKILL_BADGE_TONE[skill.status]}>
          {LEARNING_PLAN_SKILL_STATUS_LABEL[skill.status]}
        </SkillBadge>
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
