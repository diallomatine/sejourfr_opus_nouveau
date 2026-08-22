"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useState, type ReactNode} from "react";
import {
  ArrowRight,
  BarChart3,
  Check,
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
import {track} from "@/lib/analytics";
import {withTrafficSource} from "@/lib/traffic-source";
import {useAuth} from "@/lib/auth-context";
import {
  PLAN_MILESTONE_SECTION_TEXT,
  PLAN_MILESTONE_SECTION_TITLE,
  productionSectionLabel,
} from "@/lib/diagnostic";
import {
  isComprehension,
  masteryLabel,
  PLAN_COMPLETE_PROFILE_NOTE,
  PLAN_COMPLETE_PROFILE_TEXT,
  PLAN_COMPLETE_PROFILE_TITLE,
  PLAN_CYCLE_STATE_TEXT,
  PLAN_DOMAIN_NOT_EVALUATED,
  PLAN_RECENT_NEW_PRIORITY,
  PLAN_SEANCE_RESTART,
  PLAN_SEANCE_START,
  PLAN_STARTING,
  PLAN_SEANCE_WHY_CLOSE,
  PLAN_SEANCE_WHY_TITLE,
  PLAN_SKILLS_HREF,
  PLAN_SKILLS_TITLE,
  planActivePriorities,
  planAssessmentCta,
  planAssessmentMeta,
  planCycleLine,
  planDomainHref,
  PLAN_LOCKED_PRIORITY_LABEL,
  PLAN_LOCKED_SEANCE_LABEL,
  PLAN_REASON_A_ACQUERIR,
  PLAN_REASON_A_VERIFIER,
  planDomainLabel,
  planDomainLevelLine,
  planItemMinutes,
  planItemReason,
  planItemTitle,
  planPathTitle,
  PLAN_PROGRESS_HREF,
  PLAN_PROGRESS_TITLE_SHORT,
  planProfileCountLabel,
  planSeanceItemDone,
  planSeanceItemKey,
  planSeanceItemLocked,
  planSeanceMeta,
  planSeanceRationale,
  planSkillHref,
  planSkillLevel,
  planSkillMeta,
  planTaskLabel,
  planTitle,
  planTransitionLine,
  itemEpreuve,
} from "@/lib/plan-domain";
import {PlanMilestoneCard} from "./PlanMilestoneCard";
import {PlanPaywallCard} from "./PlanPaywallCard";
import {
  AllSkillsLink,
  PlanBlur,
  PlanDomainIcon,
  PlanDomainPriorityPill,
  PlanFreeBar,
  PlanLevelRail,
  PlanNaturePill,
  PlanPathList,
  PlanUpdatedBanner,
  trackPremiumClick,
  usePremiumHref,
} from "./PlanBits";
import {PlanPriorityGroups, PlanSeanceCard} from "./PlanGroups";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";
import {
  planDoneSectionCta,
  PLAN_STEP_BADGE_DONE,
  PLAN_STEP_DONE_MARK_LABEL,
} from "@/lib/plan-step";
import {
  type LearningPlanCompletedStepDto,
  type LearningPlanDto,
  type LearningPlanPriorityDto,
  type PlanDomainAssessmentDto,
  type PlanDomainDto,
  PLAN_RECENT_CHANGES_WINDOW_LABEL,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {RowChevron, SkillLockBadge} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

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

  // Ne sert aucun bloc de cet écran : posé pour ne pas perdre une mesure qui
  // existait avant la migration vers `lib/analytics.ts` (cf. CLAUDE.md racine).
  useEffect(() => {
    if (!user) return;
    track("PLAN_OPENED", {}, {once: true});
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

  const priorities = useMemo(() => planActivePriorities(plan), [plan]);
  const completedSteps = plan.completedSteps ?? [];
  const changes = plan.recentChanges;
  /* « Quelque chose a bougé » = au moins une transition **ou** une nouvelle
     priorité (miroir de `PlanRecentChanges.isEmpty` côté mobile). La section
     « ce qui a changé », elle, reste plus exigeante : elle a besoin d'une vraie
     transition, son titre étant une période. */
  const changed = Boolean(changes && (changes.transitions.length > 0 || changes.newPriority));
  const milestone = plan.milestone;
  /* Un jalon déjà présent dans la séance ne se répète pas en carte : ce serait
     le même examen blanc annoncé deux fois sur le même écran. Miroir du mobile
     (`milestoneInSeance`). */
  const milestoneInSeance = Boolean(
    milestone
    && plan.seance.items.some(
      (item) =>
        item.exercise !== null
        && (item.exercise.kind === "EPREUVE_MOCK_EXAM" || item.exercise.kind === "FULL_TCF_MOCK_EXAM")
        && item.exercise.epreuve === milestone.epreuve
        && item.exercise.slotNumber === milestone.slotNumber,
    ),
  );

  return (
    <PlanShell>
      <header className={styles.header}>
        <p className={styles.eyebrow}><ListChecks size={15} aria-hidden /> Mon plan</p>
        <div className={styles.headerRow}>
          <h1>{planTitle(plan.cycle)}</h1>
          <Link className={styles.headerAction} href={PLAN_PROGRESS_HREF}>
            <BarChart3 size={16} aria-hidden /> {PLAN_PROGRESS_TITLE_SHORT}
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

      {/* Bandeau de tête : « Plan actualisé » quand quelque chose a bougé,
          « Version gratuite » sinon — **jamais les deux**, comme sur mobile.
          `PlanFreeBar` se retire d'elle-même dès que l'accès TCF est là ; un
          `recentChanges` vide (ni transition, ni nouvelle priorité) est le cas
          normal et ne fabrique aucun bandeau. */}
      {changed ? (
        <PlanUpdatedBanner changes={plan.recentChanges!} />
      ) : (
        <PlanFreeBar onPremiumClick={trackPremiumClick} />
      )}

      <div className={styles.layout}>
        <div className={styles.main}>
          <PriorityCard plan={plan} onWhy={() => setWhyOpen(true)} />

          <PlanSeanceCard plan={plan} onWhy={() => setWhyOpen(true)} />

          <PrioritiesSection priorities={priorities} completedSteps={completedSteps} plan={plan} />

          {/* Ce que l'abonnement ouvre, juste après les priorités — la carte se
              retire d'elle-même dès que l'accès TCF est là. */}
          <PlanPaywallCard onPremiumClick={trackPremiumClick} />

          {/* Le jalon est un cran AU-DESSUS des étapes : il suit les priorités,
              il ne remplace jamais l'une d'elles. `milestone === null` est le
              cas NORMAL — rien ne s'affiche, et un jalon déjà servi dans la
              séance n'est pas répété ici.

              ⚠️ Il vit dans la colonne PRINCIPALE, pas dans l'aside : rangé à
              côté, il tombait tout en bas une fois les deux colonnes empilées
              sur petit écran, très loin des priorités qu'il couronne. C'est
              aussi l'ordre du mobile (`plan_screen.dart`). */}
          {milestone && !milestoneInSeance && (
            <section aria-labelledby="milestone-section">
              <BlockHead
                title={PLAN_MILESTONE_SECTION_TITLE}
                text={PLAN_MILESTONE_SECTION_TEXT}
                titleId="milestone-section"
              />
              <PlanMilestoneCard milestone={milestone} onPremiumClick={trackPremiumClick} />
            </section>
          )}

          <PlanRecentChanges plan={plan} />
        </div>

        <aside className={styles.aside}>
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
 * 🛑 **Verrouillée, son IDENTITÉ passe derrière le rideau** — titre, domaine et
 * motif —, exactement comme la ligne correspondante de « Mes priorités » et
 * comme le héros du mobile (`PlanPriorityHero`). C'est la même compétence :
 * l'afficher en clair ici démentirait le flou posé vingt lignes plus bas. Ce
 * qui reste **net** pour tout le monde ne bouge pas : la nature de l'action, le
 * cadenas, l'objectif, le rail des paliers et le bouton — savoir quoi
 * travailler est ce que le Plan apporte, et le Plan reste entièrement visible.
 *
 * 🛑 **Le bouton principal LANCE la séance, pas la priorité seule** (miroir du
 * mobile) : le serveur a ordonné les actions du jour, et une **mesure de
 * domaine** passe devant tout le reste. Démarrer la priorité par-dessus elle
 * ferait avancer le candidat à l'aveugle sur un domaine qu'on ne sait pas
 * encore lire. Sur le cas courant — la priorité **est** la première ligne de la
 * séance —, rien ne change.
 */
function PriorityCard({plan, onWhy}: {plan: LearningPlanDto; onWhy: () => void}) {
  const premiumHref = usePremiumHref();
  const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const assessments = usePlanAssessment();
  const priority = plan.currentPriority;

  /* Ce que le bouton lance : la première ligne **non faite** de la séance,
     sinon la première (« Refaire ma séance »), sinon l'exercice de la priorité
     quand il n'y a pas de séance du tout. */
  const items = plan.seance.items;
  const pending = items.filter((item) => !planSeanceItemDone(item));
  const next = pending[0] ?? items[0] ?? null;
  const resumed = next !== null && pending.length > 0 && pending.length !== items.length;
  const replay = next !== null && pending.length === 0;

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
  /* Deux verrous distincts, comme sur mobile : celui de la **compétence**
     (ce qu'on floute) et celui de **l'action du bouton** (la séance peut
     proposer autre chose que la priorité n°1). */
  const identityLocked = priority.locked;
  const actionLocked = next ? planSeanceItemLocked(next) : (priority.locked || exercise?.locked === true);
  const minutes = next
    ? planItemMinutes(next)
    : exercise?.estimatedMinutes ?? null;
  const level = planSkillLevel(plan, priority.skillId);
  /* Le repère de la priorité : son épreuve, puis sa tâche **en toutes lettres**
     — « Tâche 2 — Raconter une expérience ». Le titre vient du miroir de
     `SkillTaskCode` (le serveur ne le sert pas) ; un code inattendu retombe sur
     le code lui-même plutôt que sur une tâche inventée. La compréhension, elle,
     n'a aucune tâche : elle se repère par son palier. */
  const taskLabel = isComprehension(priority.section)
    ? level ? `palier ${level}` : productionSectionLabel(priority.section)
    : planTaskLabel(priority.skillCode) ?? priority.skillCode;

  const cta = actionLocked
    ? "Débloquer cet entraînement"
    : replay
      ? PLAN_SEANCE_RESTART
      : next
        ? `${resumed ? "Reprendre" : PLAN_SEANCE_START}${minutes === null ? "" : ` · ${minutes} min`}`
        : exercise
          ? `${priority.nature === "A_ACQUERIR" ? "Découvrir" : "Commencer"}${minutes === null ? "" : ` · ${minutes} min`}`
          : "Ouvrir l'épreuve";

  const startNext = () => {
    if (!next) {
      if (exercise) {
        void start(exercise);
      }
      return;
    }
    if (next.exercise === null) {
      void assessments.start(next.assessment);
      return;
    }
    void start(next.exercise);
  };

  /** L'identité de la priorité — titre, repère de domaine, motif. Floutée
   *  telle quelle quand l'accès est fermé : jamais un décor fabriqué. */
  const identity = (
    <>
      <div className={styles.priorityTitleRow}>
        {/* 🛑 Le titre est l'ÉPREUVE, pas la compétence (miroir du mobile) : un
            candidat se repère sur « Expression orale », pas sur « Repérer une
            information explicite à l'oral ». La compétence reste servie, juste
            en dessous — même ordre que les encarts groupés par épreuve. */}
        <h2>{productionSectionLabel(priority.section)}</h2>
      </div>
      <p className={styles.prioritySkill}>{taskLabel} · {priority.title}</p>
      {priorityLines(priority).map((line) => (
        <p className={styles.priorityText} key={line}>{line}</p>
      ))}
    </>
  );

  return (
    <section className={styles.priority} aria-labelledby="priority-eyebrow">
      <div className={styles.priorityHead}>
        <p className={styles.priorityEyebrow} id="priority-eyebrow">
          <Zap size={15} aria-hidden /> Priorité actuelle
        </p>
        {/* Ce que le Plan demande de faire ici, et si l'accès est ouvert. Deux
            informations qui restent vraies pour tout le monde : elles vivent
            donc HORS du bloc flouté. Une compétence **à acquérir** n'a rien
            d'observé — la pastille est la seule chose qui empêche cette carte de
            se lire comme une fragilité. */}
        <span className={styles.priorityNature}>
          <PlanNaturePill nature={priority.nature} />
          {identityLocked && <span className={styles.lockAside}><SkillLockBadge /></span>}
        </span>
        {identityLocked ? (
          <>
            <span className={styles.srOnly}>{PLAN_LOCKED_PRIORITY_LABEL}</span>
            <PlanBlur>{identity}</PlanBlur>
          </>
        ) : (
          identity
        )}
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
        {actionLocked ? (
          <Link className={styles.primaryButton} href={premiumHref} onClick={trackPremiumClick}>
            <Lock size={16} aria-hidden /> {cta}
          </Link>
        ) : next || exercise ? (
          <button
            type="button"
            className={styles.primaryButton}
            disabled={starting || assessments.starting !== null}
            onClick={startNext}
          >
            {starting || assessments.starting !== null ? PLAN_STARTING : cta}{" "}
            <ArrowRight size={17} aria-hidden />
          </button>
        ) : (
          <Link className={styles.primaryButton} href={planSkillHref(priority, {planStep: true})}>
            {cta} <ArrowRight size={17} aria-hidden />
          </Link>
        )}
        <button type="button" className={styles.linkButton} onClick={onWhy}>Voir pourquoi</button>
        <Link
          className={styles.mutedLink}
          href={identityLocked ? premiumHref : planSkillHref(priority, {planStep: true})}
          onClick={identityLocked ? trackPremiumClick : undefined}
        >
          Voir le détail
        </Link>
      </div>

      {actionLocked && (
        <p className={styles.lockNote}>
          Cet exercice fait partie de l&apos;abonnement Intégral. Votre plan, lui, reste entier.
        </p>
      )}
      {(error ?? assessments.error) && (
        <p className={styles.milestoneError} role="alert">{error ?? assessments.error}</p>
      )}
      <PaywallSheet ctaLocation="LOCKED_PLAN" screen="plan"
        open={paywallOpen || assessments.paywallOpen}
        onClose={() => { closePaywall(); assessments.closePaywall(); }}
        module="INTEGRAL"
      />
    </section>
  );
}

/**
 * Pourquoi cette compétence est en tête — **deux lignes de faits servis**, pas
 * un jugement.
 *
 * 1. ce que le correcteur a observé (`explanation`), ou — sur une compétence
 *    jamais travaillée — **ce qu'elle est** ; c'est ce que le mobile affichait
 *    déjà, le web l'omettait ;
 * 2. l'état agrégé et l'avancement de l'étape — ce que le web affichait déjà,
 *    le mobile l'omettait.
 *
 * 🛑 **La nature passe avant les compteurs.** Sur une compétence à acquérir,
 * « 0 sujet sur 5 traité » se lirait comme un retard alors qu'il n'y a rien eu à
 * traiter : on dit ce qui est vrai — rien n'a été constaté, il reste à
 * l'apprendre.
 *
 * ⚠️ **Miroir mot pour mot du mobile** (`planPriorityLines`, `plan_labels.dart`).
 */
function priorityLines(priority: LearningPlanPriorityDto): string[] {
  const lines: string[] = [];
  if (priority.nature === "A_ACQUERIR") {
    lines.push(PLAN_REASON_A_ACQUERIR);
  } else if (priority.explanation) {
    lines.push(priority.explanation);
  } else if (priority.readyForReassessment) {
    lines.push(PLAN_REASON_A_VERIFIER);
  }

  const state = masteryLabel(priority.masteryState);
  if (priority.stepPromptCount > 0) {
    const done = `${priority.stepAttemptedCount} sujet${plural(priority.stepAttemptedCount)} sur ${priority.stepPromptCount} traité${plural(priority.stepAttemptedCount)} dans cette étape`;
    lines.push(state ? `${state} · ${done}.` : `${done}.`);
  } else if (lines.length === 0 || state) {
    lines.push(
      state
        ? `${state} · c'est cette compétence qui fait le plus avancer votre palier.`
        : "C'est cette compétence qui fait le plus avancer votre palier.",
    );
  }
  return lines;
}

/* ---------------------------------------------------------- mes priorités */

/**
 * « Mes priorités », **groupées par épreuve puis par tâche** — la liste plate
 * numérotée d'avant ne disait pas *où* le candidat travaillait, alors que c'est
 * la première question qu'il se pose devant son plan.
 *
 * L'ordre reste **celui du serveur** : le premier encart est celui de la
 * première priorité servie, et les lignes ne sont jamais retriées à l'intérieur.
 */
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
        text="Toutes vos compétences par épreuve, dans l'ordre décidé par votre plan."
        titleId="priorities-title"
        action={<AllSkillsLink />}
      />
      <PlanPriorityGroups plan={plan} priorities={priorities} />
      <CompletedStepsBlock steps={completedSteps} />
    </section>
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
 *  message générique.
 *
 *  Exportée parce que « Ma progression » sert **exactement la même** section :
 *  deux copies auraient fini par raconter deux histoires différentes du même
 *  `recentChanges`. */
export function PlanRecentChanges({plan}: {plan: LearningPlanDto}) {
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
      <PaywallSheet ctaLocation="LOCKED_PLAN" screen="plan" open={paywallOpen} onClose={closePaywall} module="INTEGRAL" />
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
          {busy ? PLAN_STARTING : planAssessmentCta(assessment)} <ChevronRight size={15} aria-hidden />
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
  const rows: Array<{
    icon: ReactNode;
    title: string;
    text: string;
    href: string;
  }> = [
    {
      /* 🛑 Aucun cadenas : le référentiel est ouvert à tout le monde
         (2026-08-22) — cf. `AllSkillsLink`. */
      icon: <LayoutGrid size={18} />,
      title: PLAN_SKILLS_TITLE,
      text: "6 tâches · 3 paliers par domaine",
      href: PLAN_SKILLS_HREF,
    },
    {
      /* 🛑 L'écran adossé au PLAN, pas `/statistiques` — qui reste, avec sa
         propre entrée de barre latérale, et répond à une autre question
         (thèmes révisés, séries jouées) que « où j'en suis sur les quatre
         domaines du TCF ». */
      icon: <BarChart3 size={18} />,
      title: PLAN_PROGRESS_TITLE_SHORT,
      text: "Domaine par domaine",
      href: PLAN_PROGRESS_HREF,
    },
    {icon: <GraduationCap size={18} />, title: "Mes examens blancs", text: "TCF et civique", href: "/examens-blancs"},
    {icon: <Sparkles size={18} />, title: "Mon diagnostic", text: "Résultat de départ", href: "/diagnostic"},
  ];
  return (
    <section className={styles.panel} aria-label="Accès secondaires">
      <ul className={styles.panelList}>
        {rows.map((row) => (
          <li key={row.title}>
            <Link className={styles.panelRow} href={row.href}>
              <span className={styles.panelIcon} aria-hidden>{row.icon}</span>
              <span className={styles.panelBody}>
                <span className={styles.panelTitle}>{row.title}</span>
                <span className={styles.panelMeta}>{row.text}</span>
              </span>
              <RowChevron />
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

        {/* Les raisons de la séance, composées de faits servis — miroir mot pour
            mot du mobile. L'état du cycle, lui, est déjà dans l'en-tête de
            l'écran : le redire ici ferait deux fois la même phrase. */}
        {planSeanceRationale(plan).map((line) => (
          <p className={styles.modalCopy} key={line}>{line}</p>
        ))}

        {items.length > 0 && (
          <ul className={styles.modalList}>
            {items.map((item) => {
              const minutes = planItemMinutes(item);
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
                    {planSeanceItemLocked(item) ? (
                      <>
                        <span className={styles.srOnly}>{PLAN_LOCKED_SEANCE_LABEL}</span>
                        <PlanBlur>{text}</PlanBlur>
                      </>
                    ) : (
                      text
                    )}
                  </span>
                  {/* 🛑 Rien de net sur une ligne floutée : la durée d'un
                      entraînement verrouillé est une information de plus sur ce
                      qu'on ne peut pas encore ouvrir. */}
                  {!planSeanceItemLocked(item) && minutes !== null && (
                    <span className={styles.modalMinutes}>{minutes} min</span>
                  )}
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
  action,
}: {
  title: string;
  text?: string;
  titleId?: string;
  action?: ReactNode;
}) {
  return (
    <div className={styles.blockHead}>
      <div>
        <h2 id={titleId}>{title}</h2>
        {text && <p>{text}</p>}
      </div>
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
