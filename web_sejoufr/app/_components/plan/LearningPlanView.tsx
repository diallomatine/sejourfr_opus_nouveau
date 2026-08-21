"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useState, type ReactNode} from "react";
import {
  ArrowRight,
  BarChart3,
  Check,
  ChevronDown,
  ChevronRight,
  Clock3,
  FilePenLine,
  GraduationCap,
  Headphones,
  LayoutGrid,
  ListChecks,
  Lock,
  RotateCcw,
  Sparkles,
  Target,
  Zap,
} from "lucide-react";
import {ApiException, learningPlanApi} from "@/lib/api";
import {trackAudienceEvent, withTrafficSource} from "@/lib/audience";
import {useAuth} from "@/lib/auth-context";
import {productionSectionLabel} from "@/lib/diagnostic";
import {
  isComprehension,
  masteryLabel,
  PLAN_COMPLETE_PROFILE_NOTE,
  PLAN_COMPLETE_PROFILE_TEXT,
  PLAN_COMPLETE_PROFILE_TITLE,
  PLAN_CYCLE_STATE_TEXT,
  PLAN_DOMAIN_NOT_EVALUATED,
  PLAN_RECENT_NEW_PRIORITY,
  PLAN_SEANCE_EMPTY,
  PLAN_SEANCE_META_HINT,
  PLAN_SEANCE_TITLE,
  PLAN_SEANCE_WHY_CLOSE,
  PLAN_SEANCE_WHY_CTA,
  PLAN_SEANCE_WHY_TITLE,
  PLAN_SKILLS_HREF,
  PLAN_SKILLS_LOCKED_LABEL,
  PLAN_SKILLS_TITLE,
  planActivePriorities,
  planAssessmentCta,
  planAssessmentMeta,
  planCycleLine,
  planDomainHref,
  planDomainLabel,
  planDomainLevelLine,
  planItemEyebrow,
  planItemNature,
  planItemReason,
  planItemTitle,
  planPathTitle,
  planProfileCountLabel,
  planSeanceItemDone,
  planSeanceItemKey,
  planSeanceMeta,
  planSkillHref,
  planSkillLevel,
  planSkillMeta,
  planTitle,
  planTransitionLine,
  itemEpreuve,
} from "@/lib/plan-domain";
import {PlanMilestoneCard} from "./PlanMilestoneCard";
import {
  PlanBlur,
  PlanDomainIcon,
  PlanDomainPriorityPill,
  PlanDots,
  PlanLevelRail,
  PlanPathList,
} from "./PlanBits";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";
import {
  planDoneSectionCta,
  PLAN_STEP_BADGE_DONE,
  PLAN_STEP_DONE_MARK_LABEL,
} from "@/lib/plan-step";
import {competenceProgressLabel} from "@/lib/skill-progress";
import {
  canAccessModule,
  type LearningPlanCompletedStepDto,
  type LearningPlanDto,
  type LearningPlanPriorityDto,
  type LearningPlanSkillDto,
  type PlanDomainAssessmentDto,
  type PlanDomainDto,
  type PlanSeanceItemDto,
  PLAN_RECENT_CHANGES_WINDOW_LABEL,
} from "@/lib/types";
import {useTrafficSource, useTrafficSourceHref} from "@/lib/use-traffic-source";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
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
 * verrou freemium. L'événement est autorisé côté serveur sur `/plan` — et c'est
 * le seul qu'on émette ici, avec `PLAN_OPENED` et
 * `PLAN_RECOMMENDED_EXERCISE_STARTED`. **Ne jamais en inventer un autre** :
 * l'allowlist est doublée serveur, tout le reste est rejeté en silence.
 */
function trackPremiumClick() {
  trackAudienceEvent("/plan", "DIAGNOSTIC_TO_PREMIUM_CLICKED");
}

function usePremiumHref(): string {
  return useTrafficSourceHref(SKILL_PREMIUM_HREF);
}

/**
 * Ce que porte une ligne verrouillée, dit **net**.
 *
 * Le contenu réel part sous `PlanBlur`, donc hors de l'arbre d'accessibilité :
 * sans ces deux phrases, la ligne n'aurait plus de nom accessible du tout. Elles
 * ne divulguent rien de ce que le flou cache — elles disent qu'il y a quelque
 * chose et comment l'ouvrir, ce qui reste vrai pour tout le monde.
 */
const PLAN_LOCKED_SEANCE_LABEL =
  "Entraînement réservé à l'abonnement. Ouvrir l'offre pour le débloquer.";
const PLAN_LOCKED_PRIORITY_LABEL =
  "Priorité réservée à l'abonnement. Ouvrir l'offre pour la débloquer.";

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
          <Link
            className={styles.primaryButton}
            href={withTrafficSource(`/connexion?next=${encodeURIComponent(planHref)}`, trafficSource)}
          >
            Se connecter
          </Link>
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

  return <ActivePlan plan={plan} />;
}

/* --------------------------------------------------------------- plan actif */

function ActivePlan({plan}: {plan: LearningPlanDto}) {
  const [whyOpen, setWhyOpen] = useState(false);

  const observed = useMemo(
    () => plan.observedSkills.filter((skill) => skill.status !== "NOT_OBSERVED"),
    [plan.observedSkills],
  );
  const priorities = useMemo(() => planActivePriorities(plan), [plan]);
  const completedSteps = plan.completedSteps ?? [];

  return (
    <PlanShell>
      <header className={styles.header}>
        <p className={styles.eyebrow}><ListChecks size={15} aria-hidden /> Mon plan</p>
        <div className={styles.headerRow}>
          <h1>{planTitle(plan.cycle)}</h1>
          <Link className={styles.headerAction} href="/statistiques">
            <BarChart3 size={16} aria-hidden /> Ma progression
          </Link>
        </div>
        <p>
          {planCycleLine(plan.cycle)} {PLAN_CYCLE_STATE_TEXT[plan.cycle.state]}
        </p>
        {!plan.cycle.objectiveLevel && (
          /* 🛑 L'objectif est INCONNU tant que la démarche n'est pas déclarée :
             on ne met jamais « B2 » à sa place, on propose de le dire. */
          <Link className={styles.headerNudge} href="/parcours">
            <Target size={15} aria-hidden /> Choisir ma démarche pour fixer mon objectif
            <ChevronRight size={15} aria-hidden />
          </Link>
        )}
      </header>

      <div className={styles.layout}>
        <div className={styles.main}>
          <PriorityCard plan={plan} onWhy={() => setWhyOpen(true)} />

          <SeanceCard plan={plan} onWhy={() => setWhyOpen(true)} />

          <PrioritiesSection priorities={priorities} completedSteps={completedSteps} plan={plan} />

          <RecentChanges plan={plan} />

          <ObservedSkills skills={observed} total={plan.observedSkillCount} />
        </div>

        <aside className={styles.aside}>
          {/* Le jalon est un cran AU-DESSUS des étapes : il ouvre la colonne
              latérale, il ne remplace jamais une priorité.
              `milestone === null` est le cas NORMAL — rien ne s'affiche. */}
          {plan.milestone && (
            <PlanMilestoneCard milestone={plan.milestone} onPremiumClick={trackPremiumClick} />
          )}

          <ProfileCard plan={plan} />

          <CompleteProfileCard plan={plan} />

          <PathCard plan={plan} />

          <SecondaryLinks />

          <p className={styles.asideNote}>
            Estimation d&apos;entraînement SejourFR, non officielle : elle situe votre
            travail, elle ne remplace pas le résultat du TCF.
          </p>
        </aside>
      </div>

      {whyOpen && <WhyModal plan={plan} onClose={() => setWhyOpen(false)} />}
    </PlanShell>
  );
}

/* ------------------------------------------------------- priorité actuelle */

/**
 * La carte de tête : **une seule action**, celle que le serveur a désignée.
 *
 * Verrouillée, elle reste **entière** — titre, domaine, compteurs, rail : le
 * Plan reste intégralement visible, seul l'accès est fermé (`locked`).
 */
function PriorityCard({plan, onWhy}: {plan: LearningPlanDto; onWhy: () => void}) {
  const premiumHref = usePremiumHref();
  const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const priority = plan.currentPriority;

  if (!priority) {
    return (
      <EmptyCard
        icon={<Sparkles size={28} />}
        title="Votre prochaine priorité se prépare"
        text="Continuez une production ciblée : le Plan se réordonnera avec les nouvelles observations."
      >
        <Link className={styles.primaryButton} href="/entrainement?module=TCF">Continuer l&apos;entraînement</Link>
      </EmptyCard>
    );
  }

  const exercise = priority.recommendedExercise;
  const locked = priority.locked || exercise?.locked === true;
  const check = exercise?.kind === "REASSESSMENT";
  const level = planSkillLevel(plan, priority.skillId);
  const taskLabel = isComprehension(priority.section)
    ? level ? `palier ${level}` : productionSectionLabel(priority.section)
    : priority.skillCode;

  const cta = locked
    ? "Débloquer cet exercice"
    : check
      ? "Vérifier ma progression"
      : exercise
        ? `Commencer · ${exercise.estimatedMinutes} min`
        : "Ouvrir l'épreuve";

  return (
    <section className={styles.priority} aria-labelledby="priority-title">
      <div className={styles.priorityHead}>
        <p className={styles.priorityEyebrow}><Zap size={15} aria-hidden /> Priorité actuelle</p>
        <div className={styles.priorityTitleRow}>
          <h2 id="priority-title">{priority.title}</h2>
          <span className={styles.priorityTag}>
            {priority.section} · {taskLabel}
          </span>
        </div>
        <p className={styles.priorityText}>{priorityReason(priority)}</p>
        <div className={styles.priorityFoot}>
          <span className={styles.priorityGoal}>
            <Target size={16} aria-hidden />
            {plan.cycle.objectiveLevel
              ? `Objectif ${plan.cycle.objectiveLevel}`
              : `Palier en construction : ${plan.cycle.targetLevel}`}
          </span>
          <span className={styles.priorityRail}>
            <PlanLevelRail current={plan.cycle.targetLevel} dark />
          </span>
        </div>
      </div>

      <div className={styles.priorityActions}>
        {locked ? (
          <Link className={styles.primaryButton} href={premiumHref} onClick={trackPremiumClick}>
            <Lock size={16} aria-hidden /> {cta}
          </Link>
        ) : exercise ? (
          <button
            type="button"
            className={styles.primaryButton}
            disabled={starting}
            onClick={() => {
              trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED");
              void start(exercise);
            }}
          >
            {starting ? "Démarrage…" : cta} <ArrowRight size={17} aria-hidden />
          </button>
        ) : (
          <Link className={styles.primaryButton} href={planSkillHref(priority, {planStep: true})}>
            {cta} <ArrowRight size={17} aria-hidden />
          </Link>
        )}
        <button type="button" className={styles.linkButton} onClick={onWhy}>Voir pourquoi</button>
        <Link className={styles.mutedLink} href={planSkillHref(priority, {planStep: true})}>Voir le détail</Link>
      </div>

      {locked && (
        <p className={styles.lockNote}>
          Cet exercice fait partie de l&apos;abonnement Intégral. Votre plan, lui, reste entier.
        </p>
      )}
      {error && <p className={styles.milestoneError} role="alert">{error}</p>}
      <PaywallSheet open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </section>
  );
}

/** Pourquoi cette compétence est en tête : **des compteurs servis**, pas un
 *  jugement. L'explication de l'observation (`priority.explanation`) reste
 *  volontairement absente — elle raconte le passé sur une carte qui annonce
 *  l'action. */
function priorityReason(priority: LearningPlanPriorityDto): string {
  const state = masteryLabel(priority.masteryState);
  if (priority.readyForReassessment) {
    return "Assez travaillée en exercice ciblé : il reste à le prouver sur une vraie tâche, en situation.";
  }
  if (priority.stepPromptCount > 0) {
    const done = `${priority.stepAttemptedCount} sujet${plural(priority.stepAttemptedCount)} sur ${priority.stepPromptCount} traité${plural(priority.stepAttemptedCount)} dans cette étape`;
    return state ? `${state} · ${done}.` : `${done}.`;
  }
  return state
    ? `${state} · c'est cette compétence qui fait le plus avancer votre palier.`
    : "C'est cette compétence qui fait le plus avancer votre palier.";
}

/* ------------------------------------------------------------- la séance */

/**
 * « Aujourd'hui » : la séance servie par le serveur, dans **son** ordre.
 *
 * ⚠️ **Ce qui est coché ne repose que sur des faits SERVIS** — l'étape bouclée
 * (`stepCompleted`) ou une dernière activité datée d'aujourd'hui
 * (`lastActivityAt`, comparé en Europe/Paris par `planSeanceItemDone`). Le
 * marqueur local d'avant disparaissait au rechargement et ne traversait pas
 * l'appareil : deux candidats — le même — voyaient deux séances différentes.
 * La séance, elle, continue de ne dépendre d'aucune date : c'est le front qui
 * compare, jamais le serveur.
 */
function SeanceCard({plan, onWhy}: {plan: LearningPlanDto; onWhy: () => void}) {
  const items = plan.seance.items;
  const done = items.filter((item) => planSeanceItemDone(item)).length;
  const percent = items.length ? Math.round((done / items.length) * 100) : 0;

  return (
    <section className={styles.seance} aria-labelledby="seance-title">
      <div className={styles.seanceHead}>
        <div>
          <h2 id="seance-title">{PLAN_SEANCE_TITLE}</h2>
          <p>{planSeanceMeta(items.length, plan.seance.estimatedMinutes)}</p>
        </div>
        {items.length > 0 && (
          <span className={styles.seanceCount} data-done={done === items.length ? "1" : "0"}>
            {done}/{items.length}
          </span>
        )}
      </div>

      {items.length > 0 && (
        <div className={styles.seanceBar} role="presentation">
          <span style={{width: `${percent}%`}} />
        </div>
      )}

      {items.length === 0 ? (
        <p className={styles.seanceEmpty}>{PLAN_SEANCE_EMPTY}</p>
      ) : (
        <ul className={styles.seanceList}>
          {items.map((item) => (
            <SeanceRow key={planSeanceItemKey(item)} item={item} />
          ))}
        </ul>
      )}

      <button type="button" className={styles.seanceWhy} onClick={onWhy}>
        <Sparkles size={16} aria-hidden />
        <span>{PLAN_SEANCE_WHY_CTA}</span>
        <ChevronRight size={16} aria-hidden />
      </button>
    </section>
  );
}

function SeanceRow({item}: {item: PlanSeanceItemDto}) {
  const premiumHref = usePremiumHref();
  const {startItem, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const done = planSeanceItemDone(item);
  const epreuve = itemEpreuve(item);

  /** Les trois lignes de texte de l'item — le contenu RÉEL, qu'il soit servi
   *  net ou flouté. Rien n'est fabriqué pour remplir le flou. */
  const text = (
    <>
      <span className={styles.seanceEyebrow}>{planItemEyebrow(item)}</span>
      <span className={styles.seanceTitle} data-done={done ? "1" : "0"}>{planItemTitle(item)}</span>
      <span className={styles.seanceMeta}>
        {planItemNature(item)} · {item.exercise.estimatedMinutes} min
      </span>
    </>
  );

  /* L'icône de domaine reste NETTE même verrouillée, comme dans la maquette :
     elle dit de quelle épreuve relève la ligne, pas ce qu'il y a à y faire. */
  const icon = <PlanDomainIcon epreuve={epreuve} active={!done && !item.locked} />;

  return (
    <li className={styles.seanceItem} data-done={done ? "1" : "0"}>
      {item.locked ? (
        <Link className={styles.seanceRow} href={premiumHref} onClick={trackPremiumClick}>
          {icon}
          <span className={styles.seanceBody}>
            <span className={styles.srOnly}>{PLAN_LOCKED_SEANCE_LABEL}</span>
            <PlanBlur>{text}</PlanBlur>
          </span>
          <SkillLockBadge />
        </Link>
      ) : (
        <button
          type="button"
          className={styles.seanceRow}
          disabled={starting}
          onClick={() => {
            trackAudienceEvent("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED");
            void startItem(item);
          }}
        >
          {icon}
          <span className={styles.seanceBody}>{text}</span>
          {done ? (
            <span className={styles.seanceDone} aria-label="Étape terminée"><Check size={15} strokeWidth={3} aria-hidden /></span>
          ) : (
            <RowChevron />
          )}
        </button>
      )}
      {error && <p className={styles.milestoneError} role="alert">{error}</p>}
      <PaywallSheet open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </li>
  );
}

/* ---------------------------------------------------------- mes priorités */

function PrioritiesSection({
  priorities,
  completedSteps,
  plan,
}: {
  priorities: LearningPlanPriorityDto[];
  completedSteps: LearningPlanCompletedStepDto[];
  plan: LearningPlanDto;
}) {
  if (priorities.length === 0 && completedSteps.length === 0) return null;
  return (
    <section aria-labelledby="priorities-title">
      <BlockHead
        title="Mes priorités"
        text="Dans l'ordre décidé par votre plan : la première d'abord."
        titleId="priorities-title"
        action={<AllSkillsLink />}
      />
      {priorities.length > 0 && (
        <ol className={styles.priorityList}>
          {priorities.map((priority, index) => (
            <PriorityRow key={priority.skillId} priority={priority} rank={index + 1} plan={plan} />
          ))}
        </ol>
      )}
      <CompletedStepsBlock steps={completedSteps} />
    </section>
  );
}

function PriorityRow({
  priority,
  rank,
  plan,
}: {
  priority: LearningPlanPriorityDto;
  rank: number;
  plan: LearningPlanDto;
}) {
  const premiumHref = usePremiumHref();
  const level = planSkillLevel(plan, priority.skillId);
  const locked = priority.locked;

  /** Le titre et la meta — le contenu RÉEL, net ou flouté selon l'accès. */
  const text = (
    <>
      <span className={styles.priorityRowTitle}>{priority.title}</span>
      <span className={styles.priorityRowMeta}>
        {planSkillMeta(priority)}
        {level ? ` · palier ${level}` : ""}
      </span>
    </>
  );

  return (
    <li className={styles.priorityItem}>
      <Link
        className={styles.priorityRow}
        href={locked ? premiumHref : planSkillHref(priority, {planStep: true})}
        onClick={locked ? trackPremiumClick : undefined}
      >
        {/* Verrouillée, la pastille perd sa teinte d'urgence : la première
            priorité est celle qu'on peut commencer, la mettre en avant sous un
            cadenas serait une invitation à un mur. */}
        <span className={styles.priorityRank} data-first={!locked && rank === 1 ? "1" : "0"}>{rank}</span>
        <span className={styles.priorityBody}>
          {locked ? (
            <>
              <span className={styles.srOnly}>{PLAN_LOCKED_PRIORITY_LABEL}</span>
              <PlanBlur>{text}</PlanBlur>
            </>
          ) : (
            text
          )}
        </span>
        {/* Les points d'avancement disparaissent sous le verrou : ils
            compteraient un travail qu'on ne peut pas faire. */}
        {!locked && priority.stepPromptCount > 0 && (
          <span className={styles.priorityProgress}>
            <PlanDots done={priority.stepAttemptedCount} total={priority.stepPromptCount} />
            <span>{priority.stepAttemptedCount} / {priority.stepPromptCount}</span>
          </span>
        )}
        {locked ? <SkillLockBadge /> : <SkillMasteryPill state={priority.masteryState} />}
        <RowChevron />
      </Link>
    </li>
  );
}

/**
 * Les étapes **franchies**, sous les priorités et repliées par défaut.
 * Le serveur en sert cinq au plus, de la plus ancienne à la plus récente : on
 * ne trie ni ne reborne rien. Aucun bouton d'action — il n'y a plus rien à y
 * faire, et ce n'est pas une porte commerciale.
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
        <ol className={styles.priorityList}>
          {steps.map((step) => (
            <li className={styles.priorityItem} key={step.skillId}>
              <Link className={styles.priorityRow} href={planSkillHref(step, {planStep: true})}>
                <span
                  className={`${styles.priorityRank} ${styles.priorityRankDone}`}
                  role="img"
                  aria-label={PLAN_STEP_DONE_MARK_LABEL}
                >
                  <Check size={15} strokeWidth={3} aria-hidden />
                </span>
                <span className={styles.priorityBody}>
                  <span className={styles.priorityRowTitle}>{step.title}</span>
                  <span className={styles.priorityRowMeta}>{planSkillMeta(step)}</span>
                </span>
                <span className={styles.doneBadge}>{PLAN_STEP_BADGE_DONE}</span>
                <RowChevron />
              </Link>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}

/* -------------------------------------------------------- ce qui a changé */

/** 🛑 `recentChanges === null` est le cas **NORMAL** : rien n'a bougé, on
 *  n'affiche rien. Aucune ligne n'est fabriquée pour remplir le bloc, aucun
 *  message générique. */
function RecentChanges({plan}: {plan: LearningPlanDto}) {
  const changes = plan.recentChanges;
  if (!changes) return null;
  /* 🛑 **Pas de transition réelle ⇒ pas de section du tout.** Le serveur sert
     aussi ce bloc pour une simple « nouvelle priorité », et une PREMIÈRE mesure
     n'est jamais une transition : au sortir du diagnostic, la période
     s'affichait au-dessus d'une seule ligne qui ne racontait aucun changement.
     Le titre de la section EST la période — l'écrire sans rien qui ait bougé
     dans cette période serait faux. */
  if (changes.transitions.length === 0) return null;
  return (
    <section aria-labelledby="changes-title">
      <BlockHead
        title={PLAN_RECENT_CHANGES_WINDOW_LABEL[changes.window]}
        text="Ce que vos dernières productions ont changé dans votre plan."
        titleId="changes-title"
        action={<Link className={styles.blockAction} href="/plan/evolution">Voir le détail <ChevronRight size={15} aria-hidden /></Link>}
      />
      <div className={styles.changesCard}>
        <ul className={styles.changesList}>
          {changes.transitions.map((transition) => (
            <li key={transition.skillId}>
              <span className={styles.changesMark} data-up={transition.progress ? "1" : "0"} aria-hidden>
                {transition.progress ? "+" : "−"}
              </span>
              <span>
                <b>{transition.title}</b>
                <small>{planSkillMeta(transition)} · {planTransitionLine(transition)}</small>
              </span>
            </li>
          ))}
        </ul>
        {changes.newPriority && (
          <div className={styles.changesPriority}>
            <p>{PLAN_RECENT_NEW_PRIORITY}</p>
            <b>{changes.newPriority.title}</b>
          </div>
        )}
      </div>
    </section>
  );
}

/* ------------------------------------------------------------ profil TCF */

/** Les quatre domaines, **dans l'ordre servi** : par urgence, puis par ordre
 *  des épreuves du TCF. 🛑 Aucun front ne retrie, aucun front ne complète les
 *  trous — une liste trouée ferait disparaître exactement ce que « Compléter
 *  mon profil » doit montrer. */
function ProfileCard({plan}: {plan: LearningPlanDto}) {
  return (
    <section className={styles.panel} aria-labelledby="profile-title">
      <div className={styles.panelHead}>
        <div>
          <h2 id="profile-title">Mon profil TCF</h2>
          <p>{planProfileCountLabel(plan.cycle)}</p>
        </div>
        <span className={styles.profileDots} aria-hidden>
          {plan.domaines.map((domain) => (
            <span key={domain.epreuve} data-on={domain.evaluated ? "1" : "0"} />
          ))}
        </span>
      </div>
      <ul className={styles.panelList}>
        {plan.domaines.map((domain) => <DomainRow key={domain.epreuve} domain={domain} />)}
      </ul>
    </section>
  );
}

function DomainRow({domain}: {domain: PlanDomainDto}) {
  return (
    <li>
      <Link className={styles.panelRow} href={planDomainHref(domain.epreuve)}>
        <PlanDomainIcon
          epreuve={domain.epreuve}
          active={domain.evaluated && domain.priority === "FORTE"}
          small
        />
        <span className={styles.panelBody}>
          <span className={styles.panelTitle}>{planDomainLabel(domain.epreuve)}</span>
          <span className={styles.panelMeta}>{planDomainLevelLine(domain)}</span>
        </span>
        <PlanDomainPriorityPill priority={domain.priority} />
      </Link>
    </li>
  );
}

/* ---------------------------------------------------- compléter mon profil */

/** **Vide = profil complet**, l'état visé et non une anomalie : la carte
 *  disparaît, sans message de félicitations ni indicateur. */
function CompleteProfileCard({plan}: {plan: LearningPlanDto}) {
  const {start, starting, error, paywallOpen, closePaywall} = usePlanAssessment();
  if (plan.domainesAEvaluer.length === 0) return null;
  return (
    <section className={styles.panel} aria-labelledby="complete-title">
      <div className={styles.panelHead}>
        <div>
          <h2 id="complete-title">{PLAN_COMPLETE_PROFILE_TITLE}</h2>
          <p>{PLAN_COMPLETE_PROFILE_TEXT}</p>
        </div>
      </div>
      <ul className={styles.panelList}>
        {plan.domainesAEvaluer.map((assessment) => (
          <AssessmentRow
            key={`${assessment.epreuve}-${assessment.kind}`}
            assessment={assessment}
            busy={starting === assessment.epreuve}
            onStart={() => void start(assessment)}
          />
        ))}
      </ul>
      <p className={styles.panelNote}>{PLAN_COMPLETE_PROFILE_NOTE}</p>
      {error && <p className={styles.milestoneError} role="alert">{error}</p>}
      <PaywallSheet open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
    </section>
  );
}

function AssessmentRow({
  assessment,
  busy,
  onStart,
}: {
  assessment: PlanDomainAssessmentDto;
  busy: boolean;
  onStart: () => void;
}) {
  return (
    <li>
      <button type="button" className={styles.panelRow} onClick={onStart} disabled={busy}>
        <PlanDomainIcon epreuve={assessment.epreuve} small />
        <span className={styles.panelBody}>
          <span className={styles.panelTitle}>{planDomainLabel(assessment.epreuve)}</span>
          <span className={styles.panelMeta}>{PLAN_DOMAIN_NOT_EVALUATED} · {planAssessmentMeta(assessment)}</span>
        </span>
        <span className={styles.panelCta}>
          {busy ? "Démarrage…" : planAssessmentCta(assessment)} <ChevronRight size={15} aria-hidden />
        </span>
      </button>
    </li>
  );
}

/* ---------------------------------------------------------------- chemin */

/** Le chemin de palier. La liste et la règle du gate vivent dans `PlanPathList`
 *  — « Votre programme évolue » sert exactement la même. */
function PathCard({plan}: {plan: LearningPlanDto}) {
  if (plan.cycle.path.length === 0) return null;
  return (
    <section className={styles.panel} aria-labelledby="path-title">
      <div className={styles.panelHead}>
        <div><h2 id="path-title">{planPathTitle(plan.cycle)}</h2></div>
      </div>
      <PlanPathList cycle={plan.cycle} titleId="path-title" />
    </section>
  );
}

/* -------------------------------------------------------- accès secondaires */

function SecondaryLinks() {
  const {href: skillsHref, locked: skillsLocked} = useAllSkillsTarget();
  const rows: Array<{
    icon: ReactNode;
    title: string;
    text: string;
    href: string;
    locked?: boolean;
  }> = [
    {
      icon: <LayoutGrid size={18} />,
      title: PLAN_SKILLS_TITLE,
      text: "6 tâches · 3 paliers par domaine",
      href: skillsHref,
      locked: skillsLocked,
    },
    {icon: <BarChart3 size={18} />, title: "Ma progression", text: "Domaine par domaine", href: "/statistiques"},
    {icon: <GraduationCap size={18} />, title: "Mes examens blancs", text: "TCF et civique", href: "/examens-blancs"},
    {icon: <Sparkles size={18} />, title: "Mon diagnostic", text: "Résultat de départ", href: "/diagnostic"},
  ];
  return (
    <section className={styles.panel} aria-label="Accès secondaires">
      <ul className={styles.panelList}>
        {rows.map((row) => (
          <li key={row.title}>
            <Link
              className={styles.panelRow}
              href={row.href}
              onClick={row.locked ? trackPremiumClick : undefined}
            >
              <span className={styles.panelIcon} aria-hidden>{row.icon}</span>
              <span className={styles.panelBody}>
                <span className={styles.panelTitle}>{row.title}</span>
                <span className={styles.panelMeta}>{row.text}</span>
              </span>
              {row.locked ? <SkillLockBadge /> : <RowChevron />}
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

/**
 * **Où mène « Toutes mes compétences »**, et si l'accès est ouvert.
 *
 * ⚠️ C'est un **verrou de navigation**, pas un contenu masqué : le Plan reste
 * intégralement visible — priorités, compteurs, exercice désigné —, seul le
 * référentiel complet demande l'abonnement, exactement comme un exercice
 * `locked`. L'autorité est `canAccessModule(user, "TCF")`, la même que partout
 * ailleurs sur le web ; le serveur, lui, retranche déjà ce qu'il faut sur
 * chaque ligne.
 */
function useAllSkillsTarget(): {href: string; locked: boolean} {
  const {user} = useAuth();
  const premiumHref = usePremiumHref();
  const locked = !canAccessModule(user, "TCF");
  return {href: locked ? premiumHref : PLAN_SKILLS_HREF, locked};
}

/** Le « tout voir » de « Mes priorités » — même destination, même verrou. */
function AllSkillsLink() {
  const {href, locked} = useAllSkillsTarget();
  return (
    <Link
      className={styles.blockAction}
      href={href}
      onClick={locked ? trackPremiumClick : undefined}
      aria-label={locked ? PLAN_SKILLS_LOCKED_LABEL : undefined}
    >
      {locked && <Lock size={14} aria-hidden />}
      {PLAN_SKILLS_TITLE} <ChevronRight size={15} aria-hidden />
    </Link>
  );
}

/* ---------------------------------------------------- pourquoi cette séance */

/** Le « pourquoi » est composé de **faits servis** — état de maîtrise,
 *  compteurs d'étape, palier travaillé, nature du passage. Le serveur n'écrit
 *  aucune phrase, et on n'en invente pas au-delà de ce qu'il expose. */
function WhyModal({plan, onClose}: {plan: LearningPlanDto; onClose: () => void}) {
  useEffect(() => {
    const escape = (event: KeyboardEvent) => { if (event.key === "Escape") onClose(); };
    window.addEventListener("keydown", escape);
    return () => window.removeEventListener("keydown", escape);
  }, [onClose]);

  const items = plan.seance.items;
  return (
    <div className={styles.modalScrim} role="presentation" onClick={onClose}>
      <div
        className={styles.modal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="why-title"
        onClick={(event) => event.stopPropagation()}
      >
        <div className={styles.modalHead}>
          <span className={styles.modalIcon} aria-hidden><Sparkles size={22} /></span>
          <div>
            <h2 id="why-title">{PLAN_SEANCE_WHY_TITLE}</h2>
            <p>{planSeanceMeta(items.length, plan.seance.estimatedMinutes)}</p>
          </div>
        </div>

        <p className={styles.modalCopy}>{PLAN_SEANCE_META_HINT}</p>
        <p className={styles.modalCopy}>{PLAN_CYCLE_STATE_TEXT[plan.cycle.state]}</p>

        {items.length > 0 && (
          <ul className={styles.modalList}>
            {items.map((item) => {
              const text = (
                <>
                  <b>{planItemTitle(item)}</b>
                  <small>{planItemReason(item)}</small>
                </>
              );
              return (
                <li key={planSeanceItemKey(item)}>
                  <PlanDomainIcon epreuve={itemEpreuve(item)} small />
                  <span>
                    {/* 🛑 C'est la MÊME séance : montrer ici en clair un item
                        flouté dix lignes plus haut démentirait le verrou. Le
                        « pourquoi » de la séance reste dicible sans nommer ce
                        qu'on ne peut pas encore ouvrir. */}
                    {item.locked ? (
                      <>
                        <span className={styles.srOnly}>{PLAN_LOCKED_SEANCE_LABEL}</span>
                        <PlanBlur>{text}</PlanBlur>
                      </>
                    ) : (
                      text
                    )}
                  </span>
                  <span className={styles.modalMinutes}>{item.exercise.estimatedMinutes} min</span>
                </li>
              );
            })}
          </ul>
        )}

        <button type="button" className={styles.primaryButton} onClick={onClose}>
          {PLAN_SEANCE_WHY_CLOSE}
        </button>
      </div>
    </div>
  );
}

/* ------------------------------------------------- mes compétences observées */

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
  const premiumHref = usePremiumHref();
  const done = skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount;
  const locked = skill.locked;
  return (
    <Link
      href={locked ? premiumHref : planSkillHref(skill, {planStep: true})}
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

export function BlockHead({
  title,
  text,
  titleId,
  aside,
  action,
}: {
  title: string;
  text?: string;
  titleId?: string;
  aside?: string;
  action?: ReactNode;
}) {
  return (
    <div className={styles.blockHead}>
      <div>
        <h2 id={titleId}>{title}</h2>
        {text && <p>{text}</p>}
      </div>
      {aside && <span>{aside}</span>}
      {action}
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

export function EmptyCard({icon, title, text, children, role}: {icon: ReactNode; title: string; text: string; children?: ReactNode; role?: "alert"}) {
  return (
    <section className={styles.emptyCard} role={role}>
      <span className={styles.emptyIcon} aria-hidden>{icon}</span>
      <h2>{title}</h2>
      <p>{text}</p>
      {children && <div className={styles.actions}>{children}</div>}
    </section>
  );
}

export function PlanShell({children}: {children: ReactNode}) {
  return <main className={styles.page}>{children}</main>;
}

function PlanSkeleton() {
  return <main className={styles.page} aria-busy="true" aria-label="Chargement du plan"><div className={styles.skeletonHead} /><div className={styles.skeletonHero} /><div className={styles.skeletonGrid}><span /><span /></div></main>;
}
