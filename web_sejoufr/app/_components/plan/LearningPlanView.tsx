"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useState, type ReactNode} from "react";
import {
  ArrowRight,
  BarChart3,
  CalendarCheck,
  CheckCircle2,
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
import {ApiException, learningPlanApi} from "@/lib/api";
import {
  trackAudienceEvent,
  withTrafficSource,
} from "@/lib/audience";
import {useAuth} from "@/lib/auth-context";
import {
  LEARNING_PLAN_SKILL_STATUS_LABEL,
  recommendedExerciseHref,
} from "@/lib/diagnostic";
import type {
  LearningPlanDto,
  LearningPlanPriorityDto,
  LearningPlanSkillDto,
  SkillSection,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import styles from "./plan.module.css";

function sectionLabel(section: SkillSection): string {
  return section === "EE" ? "Expression écrite" : "Expression orale";
}

function formatDate(value: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat("fr-FR", {day: "numeric", month: "long", year: "numeric"}).format(date);
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
          <Link className={styles.secondaryButton} href="/statistiques">Voir ma progression</Link>
        </EmptyCard>
      </PlanShell>
    );
  }

  if (plan.state === "NEEDS_DIAGNOSTIC") {
    return (
      <PlanShell>
        <header className={styles.header}>
          <p className={styles.eyebrow}><ListChecks size={15} aria-hidden /> Votre feuille de route</p>
          <h1>Mon plan</h1>
          <p>La prochaine action utile, sans tableau de chiffres à décoder.</p>
        </header>
        <EmptyCard
          icon={<Target size={28} />}
          title="Construisons votre plan personnalisé"
          text="Faites 1 exercice écrit et 1 oral pour identifier vos premières priorités."
        >
          <Link className={styles.primaryButton} href="/diagnostic">Faire mon diagnostic <ArrowRight size={17} aria-hidden /></Link>
        </EmptyCard>
        <ClassicTraining />
        <ProgressionLink />
      </PlanShell>
    );
  }

  if (plan.state === "DIAGNOSTIC_IN_PROGRESS") {
    return (
      <PlanShell>
        <header className={styles.header}>
          <p className={styles.eyebrow}><ListChecks size={15} aria-hidden /> Mon plan</p>
          <h1>Votre diagnostic est en cours</h1>
          <p>Reprenez exactement à l&apos;étape enregistrée. Une production déjà reçue ne sera pas redemandée.</p>
        </header>
        <EmptyCard
          icon={<Clock3 size={28} />}
          title="Terminez vos deux exercices"
          text="Votre première priorité apparaîtra dès que l'écrit et l'oral auront été analysés."
        >
          <Link className={styles.primaryButton} href="/diagnostic">Reprendre mon diagnostic <ArrowRight size={17} aria-hidden /></Link>
        </EmptyCard>
        <ProgressionLink />
      </PlanShell>
    );
  }

  return <ActivePlan plan={plan} targetLevel={user.targetLevel ?? null} />;
}

function ActivePlan({plan, targetLevel}: {plan: LearningPlanDto; targetLevel: string | null}) {
  const observed = useMemo(
    () => plan.observedSkills.filter((skill) => skill.status !== "NOT_OBSERVED"),
    [plan.observedSkills],
  );
  const diagnosticDate = formatDate(plan.diagnosticCompletedAt);
  const prioritiesCount = (plan.currentPriority ? 1 : 0) + plan.nextPriorities.length;

  return (
    <PlanShell>
      <header className={styles.header}>
        <p className={styles.eyebrow}><ListChecks size={15} aria-hidden /> Mon plan</p>
        <h1>{targetLevel ? `Objectif : ${targetLevel}` : "Votre plan personnalisé"}</h1>
        <p>
          {prioritiesCount} priorité{prioritiesCount > 1 ? "s" : ""} détectée{prioritiesCount > 1 ? "s" : ""}
          {plan.activitiesThisWeek > 0 ? ` · ${plan.activitiesThisWeek} activité${plan.activitiesThisWeek > 1 ? "s" : ""} cette semaine` : " · commencez par l'action ci-dessous"}
        </p>
      </header>

      {plan.currentPriority ? (
        <CurrentPriority priority={plan.currentPriority} />
      ) : (
        <EmptyCard
          icon={<Sparkles size={28} />}
          title="Votre prochaine priorité se prépare"
          text="Continuez une production ciblée : le Plan se réordonnera avec les nouvelles observations."
        >
          <Link className={styles.primaryButton} href="/entrainement?module=TCF">Continuer l&apos;entraînement</Link>
        </EmptyCard>
      )}

      {plan.nextPriorities.length > 0 && (
        <section className={styles.section} aria-labelledby="next-priorities-title">
          <div className={styles.sectionHead}>
            <div><span className={styles.sectionIcon} aria-hidden><ListChecks size={19} /></span><h2 id="next-priorities-title">Ensuite</h2></div>
            <span>Jusqu&apos;à 3 priorités</span>
          </div>
          <ol className={styles.priorityRows}>
            {plan.nextPriorities.slice(0, 3).map((priority, index) => (
              <li key={priority.skillId}>
                <span className={styles.priorityNumber}>{index + 2}</span>
                <span className={styles.priorityBody}>
                  <b>{priority.title}</b>
                  <small>{priority.explanation ?? sectionLabel(priority.section)}</small>
                </span>
                {priority.recommendedExercise && (
                  <Link
                    href={recommendedExerciseHref(priority.recommendedExercise)}
                    aria-label={`Travailler : ${priority.title}`}
                    onClick={() => trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED")}
                  >
                    {priority.recommendedExercise.estimatedMinutes} min <ArrowRight size={15} aria-hidden />
                  </Link>
                )}
              </li>
            ))}
          </ol>
        </section>
      )}

      <ObservedSkills skills={observed} total={plan.observedSkillCount} />

      <section className={styles.recheck}>
        <span className={styles.sectionIcon} aria-hidden><CalendarCheck size={20} /></span>
        <div>
          <h2>Prochaine vérification</h2>
          <p>Après quelques entraînements, une nouvelle production permettra de vérifier si cette faiblesse est réellement corrigée.</p>
        </div>
      </section>

      <div className={styles.bottomGrid}>
        <ProgressionLink />
        <section className={styles.diagnosticLink}>
          <div>
            <span>Diagnostic initial</span>
            <b>{diagnosticDate ? `Réalisé le ${diagnosticDate}` : "Diagnostic réalisé"}</b>
          </div>
          <Link href="/diagnostic">Voir le diagnostic <ArrowRight size={15} aria-hidden /></Link>
        </section>
      </div>
    </PlanShell>
  );
}

function CurrentPriority({priority}: {priority: LearningPlanPriorityDto}) {
  const exercise = priority.recommendedExercise;
  return (
    <section className={styles.current} aria-labelledby="current-priority-title">
      <div className={styles.currentCopy}>
        <p className={styles.eyebrow}>À travailler maintenant</p>
        <span className={styles.sectionPill}>{priority.section === "EE" ? <FilePenLine size={14} aria-hidden /> : <Mic size={14} aria-hidden />}{sectionLabel(priority.section)}</span>
        <h2 id="current-priority-title">{priority.title}</h2>
        <p>{priority.explanation ?? "Cette compétence est votre prochaine priorité utile."}</p>
        {priority.evidence && <blockquote>«&nbsp;{priority.evidence}&nbsp;»</blockquote>}
      </div>
      <div className={styles.currentAction}>
        {exercise ? (
          <>
            <span><Clock3 size={16} aria-hidden /> {exercise.estimatedMinutes} min</span>
            <b>{exercise.title}</b>
            <Link
              className={styles.primaryButton}
              href={recommendedExerciseHref(exercise)}
              onClick={() => trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED")}
            >Commencer <ArrowRight size={17} aria-hidden /></Link>
          </>
        ) : (
          <Link className={styles.primaryButton} href={`/entrainement/tcf/${priority.section.toLowerCase()}`}>Ouvrir l&apos;épreuve <ArrowRight size={17} aria-hidden /></Link>
        )}
      </div>
    </section>
  );
}

function ObservedSkills({skills, total}: {skills: LearningPlanSkillDto[]; total: number}) {
  if (skills.length === 0) return null;
  return (
    <section className={styles.section} aria-labelledby="skills-title">
      <div className={styles.sectionHead}>
        <div><span className={styles.sectionIcon} aria-hidden><CheckCircle2 size={19} /></span><h2 id="skills-title">Mes compétences observées</h2></div>
        <span>{total} observée{total > 1 ? "s" : ""}</span>
      </div>
      <ul className={styles.skillGrid}>
        {skills.slice(0, 6).map((skill) => <SkillRow key={skill.skillId} skill={skill} />)}
      </ul>
      {skills.length > 6 && (
        <details className={styles.moreSkills}>
          <summary>Voir toutes mes compétences observées <ChevronDown size={15} aria-hidden /></summary>
          <ul className={styles.skillGrid}>
            {skills.slice(6).map((skill) => <SkillRow key={skill.skillId} skill={skill} />)}
          </ul>
        </details>
      )}
    </section>
  );
}

function SkillRow({skill}: {skill: LearningPlanSkillDto}) {
  return (
    <li>
      <span className={styles.skillSection} aria-hidden>{skill.section === "EE" ? <FilePenLine size={16} /> : <Mic size={16} />}</span>
      <span><b>{skill.title}</b><small>{sectionLabel(skill.section)}</small></span>
      <span className={styles.status} data-status={skill.status}>{LEARNING_PLAN_SKILL_STATUS_LABEL[skill.status]}</span>
    </li>
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

function ProgressionLink() {
  return (
    <section className={styles.progressionLink}>
      <span className={styles.sectionIcon} aria-hidden><BarChart3 size={20} /></span>
      <div><b>Votre progression détaillée</b><small>Scores, séries et évolution par épreuve</small></div>
      <Link href="/statistiques">Voir ma progression <ArrowRight size={15} aria-hidden /></Link>
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
