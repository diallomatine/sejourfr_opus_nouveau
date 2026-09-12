"use client";

import Link from "next/link";
import {useEffect, useMemo, useState} from "react";
import {
  BookOpen,
  Check,
  ChevronRight,
  Circle,
  Clock3,
  FilePenLine,
  Headphones,
  Lock,
  Mic,
  RefreshCw,
  Target,
  type LucideIcon,
} from "lucide-react";
import {ApiException, learningPlanApi} from "@/lib/api";
import {track} from "@/lib/analytics";
import {withTrafficSource} from "@/lib/traffic-source";
import {useAuth} from "@/lib/auth-context";
import {productionSectionLabel, skillTaskNumber} from "@/lib/diagnostic";
import {
  findDomain,
  isComprehension,
  masteryStateLabel,
  PLAN_COMPLETE_PROFILE_NOTE,
  PLAN_COMPLETE_PROFILE_TEXT,
  PLAN_COMPLETE_PROFILE_TITLE,
  PLAN_PRIORITY_ROWS_VISIBLE,
  PLAN_PROGRESS_HREF,
  PLAN_PROGRESS_LEVEL_UNKNOWN,
  PLAN_PROGRESS_TITLE_SHORT,
  PLAN_REASON_A_ACQUERIR,
  PLAN_REASON_A_VERIFIER,
  PLAN_SEANCE_RESTART,
  PLAN_SEANCE_START,
  PLAN_SKILLS_HREF,
  PLAN_SKILLS_TITLE,
  PLAN_STARTING,
  planActivePriorities,
  planAssessmentCta,
  planAssessmentMeta,
  planDomainLabel,
  planItemMinutes,
  planPathStepNote,
  planPathStepTitle,
  planPathTitle,
  planPriorityGroups,
  planRowStatus,
  planRowStatusSummary,
  planSeanceItemDone,
  planSeanceItemLocked,
  planSectionEpreuve,
  planSkillLevel,
  planTaskBadge,
  planTaskLabel,
  planTransitionLine,
  skillTaskCode,
  type PlanPriorityGroup,
} from "@/lib/plan-domain";
import {
  affinerPlan,
  DIAGNOSTIC_RAPIDE_HREF,
  PLAN_REVOIR_ESTIMATION,
  planIndisponibleDepuisEtat,
} from "@/lib/preparation";
import {
  canAccessModule,
  PLAN_ACTION_NATURE_LABEL,
  type LearningPlanCompletedStepDto,
  type LearningPlanDto,
  type LearningPlanPriorityDto,
  type ModulePreparation,
  type PlanCycleDto,
  type PlanDomainAssessmentDto,
  type SkillSection,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
  Card,
  Cta,
  DoneRow,
  ExamRow,
  GoalStrip,
  LockItem,
  LockList,
  LockRow,
  NowCard,
  Pad,
  PathCard,
  Prio,
  ProgressMini,
  Section,
  SkillList,
  SkillRow,
  Stack,
  Top,
  sejourStyles,
  type PathStep,
  type StepState,
} from "@/app/_components/sejour/SejourKit";
import {PlanBlur} from "./PlanBits";
import {PlanGate} from "./PlanGate";
import {PLAN_PREMIUM_BENEFITS, PlanPaywall} from "./PlanPaywallCard";
import {AffinerPlanCard} from "./AffinerPlanCard";
import {PlanMilestoneCard} from "./PlanMilestoneCard";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";

/**
 * **Le Plan TCF** — refonte du 2026-09-11 sur le kit `sejour/`.
 *
 * Deux écrans, un seul contrat de données (`GET /api/me/plan`) : l'**abonné**
 * lit son parcours (à faire maintenant → parcours de la tâche → priorités →
 * déjà validé → progression détectée), le **gratuit** lit ce que son diagnostic
 * a produit et ce qu'un pass ouvrirait.
 *
 * 🛑 **Rien n'est dérivé ici.** L'ordre des priorités, la nature de l'action,
 * l'état de chaque compétence, la couverture d'une tâche et le verrou arrivent
 * **servis**. L'écran les met en forme ; il ne classe aucun nombre en état
 * pédagogique et ne déduit aucun cadenas d'un rang.
 *
 * 🛑 **Aucun CSS d'écran** : tout passe par `SejourKit`.
 *
 * ## Le palier desktop (2026-09-12)
 *
 * La mise en page vient de `grok_ecran/screenshots/plan-web.png` et de
 * `screens/plan-premium.tsx` / `plan-gratuit.tsx`. 🛑 **Aucun composant
 * nouveau** : ce sont les mêmes briques, dans deux classes de grille du kit
 * (`deskPair`, `deskGrid`) qui ne déclarent rien sous 960 px.
 *
 * - **abonné** (`SejourApp wide`, 1080 px) : en-tête, objectif en pleine
 *   largeur, puis `deskPair` « À faire maintenant » | « Votre parcours », puis
 *   les priorités en `deskGrid` (1 → 2 → 3 colonnes), puis `deskPair`
 *   « Déjà travaillé et validé » | « Progression détectée » ;
 * - **gratuit** (`SejourApp sticky`, 980 px) : la maquette n'y met **aucune**
 *   paire — seules les priorités passent en grille. 🛑 C'est voulu : sur cet
 *   écran, « Débloquer mon plan » doit rester la seule action dominante, et
 *   mettre deux blocs côte à côte au-dessus d'elle remplirait l'espace de
 *   choses à faire au lieu de mener au déblocage.
 */

const SECTION_ICON: Record<SkillSection, LucideIcon> = {
  CO: Headphones,
  CE: BookOpen,
  EO: Mic,
  EE: FilePenLine,
};

/* ------------------------------------------------------------------ racine */

export function LearningPlanView({prep}: {prep?: ModulePreparation | null}) {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const trafficSource = useTrafficSource();

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

  if (authStatus === "loading" || (Boolean(user) && loading)) {
    return <Top kicker="Votre parcours personnalisé" title="Mon plan du jour" />;
  }

  if (!user) {
    const planHref = withTrafficSource("/plan", trafficSource);
    return (
      <PlanMessage
        title="Connectez-vous pour retrouver votre plan"
        text="Vos priorités restent synchronisées avec vos productions."
        cta="Se connecter"
        href={withTrafficSource(`/connexion?next=${encodeURIComponent(planHref)}`, trafficSource)}
      />
    );
  }

  if (!plan) {
    return (
      <PlanMessage
        title="Votre plan n'a pas pu être chargé"
        text={error ?? "Réessayez dans un instant."}
        cta="Faire mon diagnostic"
        href="/diagnostic"
        alert
      />
    );
  }

  /* 🛑 Pas de plan sans mesure. Les mots viennent de `planIndisponible`, la
     même autorité que l'Accueil et les Examens.

     ⚠️ Ce repli ne se déclenche plus qu'en **désaccord** entre les deux
     lectures : `planDisponible` rend la condition exacte du moteur, donc le
     Plan est normalement `ACTIVE` dès que la porte s'ouvre. `prep` lui est
     passé pour que, dans ce cas-là, le candidat retrouve au moins le rapport de
     son diagnostic rapide plutôt qu'un écran qui ne dit rien. */
  if (plan.state !== "ACTIVE") {
    return (
      <PlanGate
        kicker="Votre parcours personnalisé"
        prep={prep ?? undefined}
        gate={planIndisponibleDepuisEtat(
          plan.state === "DIAGNOSTIC_IN_PROGRESS" ? "DIAGNOSTIC_EN_COURS" : "DIAGNOSTIC_A_FAIRE",
          "TCF",
        )}
      />
    );
  }

  /* 🛑 **Le diagnostic complet n'est qu'une façon d'AFFINER** (arbitrage du
     2026-09-12). La carte se pose donc APRÈS le contenu du Plan — après le
     paywall d'un compte gratuit, dont le CTA « Débloquer mon plan » reste le
     seul bouton plein de la page. Elle disparaît d'elle-même à 4 / 4 : c'est
     `affinerPlan` qui rend `null`, sur des faits servis. */
  const abonne = canAccessModule(user, "TCF");
  const affiner = prep ? affinerPlan(prep, {surface: "plan", abonne}) : null;

  return (
    <>
      {abonne ? <TcfPlanPremium plan={plan} /> : <TcfPlanFree plan={plan} />}
      {affiner && <AffinerPlanCard info={affiner} />}
      {prep?.estimationSessionId && <RevoirEstimation />}
    </>
  );
}

/**
 * **Revoir mon diagnostic rapide** — le retour vers le rapport d'origine.
 *
 * 🛑 **Un lien, en bas de page, et rien d'autre** (arbitrage du propriétaire,
 * 2026-09-12). Pas une carte, pas un bouton plein : il ne doit concurrencer ni
 * « Débloquer mon plan » pour un compte gratuit, ni « À faire maintenant » pour
 * un abonné. Le Plan sert à avancer ; le rapport sert seulement à revenir
 * comprendre d'où viennent les premières priorités.
 *
 * 🛑 Il n'existe que si `estimationSessionId` est **servi** : un candidat venu
 * par le diagnostic complet n'a pas de rapide, donc rien à revoir, et on
 * n'invente pas un rapport. Aucun écran n'est recréé — `/diagnostic` sert déjà
 * ce rapport dès que la session est close.
 */
function RevoirEstimation() {
  return (
    <Section>
      <Pad>
        <Link className={sejourStyles.link} href={DIAGNOSTIC_RAPIDE_HREF}>
          {PLAN_REVOIR_ESTIMATION}
          <ChevronRight size={15} aria-hidden />
        </Link>
      </Pad>
    </Section>
  );
}

function PlanMessage({title, text, cta, href, alert}: {
  title: string;
  text: string;
  cta: string;
  href: string;
  alert?: boolean;
}) {
  return (
    <>
      <Top kicker="Votre parcours personnalisé" title="Mon plan du jour" />
      <Section>
        <Pad>
          <Stack>
            <Card>
              <h2 className={sejourStyles.noteTitleLg} role={alert ? "alert" : undefined}>{title}</h2>
              <p className={sejourStyles.sub}>{text}</p>
            </Card>
            <Cta href={href}>{cta}</Cta>
          </Stack>
        </Pad>
      </Section>
    </>
  );
}

/* ----------------------------------------------------------------- abonné */

function TcfPlanPremium({plan}: {plan: LearningPlanDto}) {
  const objective = plan.cycle.objectiveLevel;
  const groups = usePriorityGroups(plan);
  const tachePath = useMemo(
    () => (plan.currentPriority ? parcoursDeLaTache(plan, plan.currentPriority) : null),
    [plan],
  );
  const palierPath = useMemo(() => parcoursDuPalier(plan.cycle), [plan.cycle]);
  const completed = plan.completedSteps ?? [];

  return (
    <>
      <Top
        kicker={objective ? `Votre parcours personnalisé vers ${objective}` : "Votre parcours personnalisé"}
        title="Mon plan du jour"
      />

      <Pad>
        <CycleGoal cycle={plan.cycle} />
        <p className={sejourStyles.tiny}>
          Le plan choisit la prochaine action selon vos priorités, puis réévalue après chaque séance.
        </p>
      </Pad>

      {/* La paire de tête de la maquette. 🛑 Si l'un des deux manque — pas de
          priorité servie, pas de parcours — l'autre prend toute la rangée : la
          règle est dans le kit (`:only-child`), pas ici. */}
      <div className={sejourStyles.deskPair}>
        <ActionMaintenant plan={plan} />

        {tachePath ? (
          <Section title={tachePath.title} flush>
            <PathCard
              currentLabel={tachePath.currentLabel}
              counterLabel={tachePath.counterLabel}
              steps={tachePath.steps}
            />
          </Section>
        ) : palierPath ? (
          <PalierPath path={palierPath} />
        ) : null}
      </div>

      {groups.length > 0 && (
        <Section title={objective ? `Vos priorités pour atteindre ${objective}` : "Vos priorités"}>
          <Pad>
            <Stack className={sejourStyles.deskGrid}>
              {groups.map((group, index) => (
                <PriorityCard
                  key={group.key}
                  group={group}
                  rank={rankOf(index)}
                  currentSkillId={plan.currentPriority?.skillId ?? null}
                  detailed
                />
              ))}
            </Stack>
            <Link className={sejourStyles.link} href={PLAN_SKILLS_HREF}>
              {PLAN_SKILLS_TITLE} <ChevronRight size={15} aria-hidden />
            </Link>
          </Pad>
        </Section>
      )}

      {/* La seconde paire de la maquette. Les deux blocs disparaissent d'eux-
          mêmes quand ils n'ont rien à dire (`recentChanges === null` est le cas
          NORMAL) : le survivant prend la rangée entière. */}
      <div className={sejourStyles.deskPair}>
        {completed.length > 0 && (
          <Section title="Déjà travaillé et validé">
            <Pad>
              <Card padding="rows">
                {completed.map((step) => (
                  <DoneRow key={step.skillId} label={completedLabel(step)} />
                ))}
              </Card>
            </Pad>
          </Section>
        )}

        <ProgressionDetectee plan={plan} />
      </div>

      {/* ⚠️ Blocs conservés hors maquette : ils portent une information qu'elle
          ne couvre pas — un examen blanc mérité, un domaine jamais mesuré, et
          le chemin des paliers quand ce n'est pas lui qui sert de parcours. */}
      {plan.milestone && <PlanMilestoneCard milestone={plan.milestone} />}

      <CompleterMonProfil plan={plan} />

      {tachePath && palierPath && <PalierPath path={palierPath} />}

      <AllerPlusLoin />

      <p className={sejourStyles.footNote}>
        Estimation d&apos;entraînement SejourFR, non officielle : elle situe votre travail,
        elle ne remplace pas le résultat du TCF.
      </p>
    </>
  );
}

/* ---------------------------------------------------------------- gratuit */

function TcfPlanFree({plan}: {plan: LearningPlanDto}) {
  const objective = plan.cycle.objectiveLevel;
  const groups = usePriorityGroups(plan);
  const tachePath = useMemo(
    () => (plan.currentPriority ? parcoursDeLaTache(plan, plan.currentPriority) : null),
    [plan],
  );

  return (
    <>
      <Top
        kicker="Créé à partir de votre diagnostic"
        title={objective ? `Mon plan du jour ${objective}` : "Mon plan du jour"}
      />

      <Pad>
        <CycleGoal cycle={plan.cycle} />
      </Pad>

      {groups.length > 0 && (
        <Section title="Vos priorités">
          <Pad>
            <Stack className={sejourStyles.deskGrid}>
              {groups.map((group, index) => (
                <PriorityCard
                  key={group.key}
                  group={group}
                  rank={rankOf(index)}
                  currentSkillId={plan.currentPriority?.skillId ?? null}
                />
              ))}
            </Stack>
          </Pad>
        </Section>
      )}

      <ActionMaintenant plan={plan} free />

      {tachePath && (
        <Section title="Le parcours de cette tâche" flush>
          <Card padding="rows">
            {tachePath.locked.map((row, index) => (
              <LockRow
                key={row.key}
                n={index + 1}
                icon={row.icon}
                label={row.blurred ? <PlanBlur>{row.label}</PlanBlur> : row.label}
              />
            ))}
          </Card>
        </Section>
      )}

      <PlanPaywall
        module="INTEGRAL"
        benefits={PLAN_PREMIUM_BENEFITS}
        cta={objective ? `Débloquer mon plan ${objective}` : "Débloquer mon plan"}
      />
    </>
  );
}

/* ------------------------------------------------ objectif et niveau visé */

/**
 * 🛑 `objectiveLevel` est **nullable** — on n'écrit jamais « B2 » à la place
 * d'une démarche non déclarée. Le bandeau montre alors le **palier que le cycle
 * construit**, qui est servi, et propose de fixer l'objectif.
 */
function CycleGoal({cycle}: {cycle: PlanCycleDto}) {
  return (
    <>
      <GoalStrip
        current={cycle.startingLevel ?? PLAN_PROGRESS_LEVEL_UNKNOWN}
        goalLabel={cycle.objectiveLevel ? "Objectif" : "Palier en cours"}
        goal={cycle.objectiveLevel ?? cycle.targetLevel}
      />
      {!cycle.objectiveLevel && (
        <Link className={sejourStyles.link} href="/parcours">
          <Target size={15} aria-hidden /> Choisir ma démarche pour fixer mon objectif
          <ChevronRight size={15} aria-hidden />
        </Link>
      )}
    </>
  );
}

/* ------------------------------------------------- « À faire maintenant » */

/**
 * **Une seule action**, celle que le serveur a désignée.
 *
 * 🛑 **Le bouton lance la SÉANCE, pas la priorité seule** (miroir du mobile) :
 * le serveur a ordonné les actions du jour, et une **mesure de domaine** passe
 * devant tout le reste. Sur le cas courant — la priorité **est** la première
 * ligne de la séance —, rien ne change.
 *
 * 🛑 Le verrou se **lit** (`locked` servi, sur la ligne comme sur l'exercice),
 * jamais déduit d'un rang : la première place du Plan est ouverte à un compte
 * gratuit, et c'est pour ça qu'un vrai CTA s'y affiche.
 */
function ActionMaintenant({plan, free}: {plan: LearningPlanDto; free?: boolean}) {
  const {start, startItem, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const assessments = usePlanAssessment();
  const priority = plan.currentPriority;

  const items = plan.seance.items;
  const pending = items.filter((item) => !planSeanceItemDone(item));
  const next = pending[0] ?? items[0] ?? null;
  const resumed = next !== null && pending.length > 0 && pending.length !== items.length;
  const replay = next !== null && pending.length === 0;

  if (!priority) return null;

  const exercise = priority.recommendedExercise;
  const actionLocked = next
    ? planSeanceItemLocked(next)
    : (priority.locked || exercise?.locked === true);
  const minutes = next ? planItemMinutes(next) : exercise?.estimatedMinutes ?? null;
  const level = planSkillLevel(plan, priority.skillId);
  const repere = isComprehension(priority.section)
    ? level ? `Palier ${level}` : productionSectionLabel(priority.section)
    : planTaskLabel(priority.skillCode) ?? priority.skillCode;

  const cta = replay
    ? PLAN_SEANCE_RESTART
    : next
      ? `${resumed ? "Reprendre" : PLAN_SEANCE_START}${minutes === null ? "" : ` · ${minutes} min`}`
      : exercise
        ? `${priority.nature === "A_ACQUERIR" ? "Découvrir" : "Commencer"}${minutes === null ? "" : ` · ${minutes} min`}`
        : "Ouvrir l'épreuve";

  const busy = starting || assessments.starting !== null;
  const startNext = () => {
    if (!next) {
      if (exercise) void start(exercise);
      return;
    }
    if (next.exercise === null) {
      void assessments.start(next.assessment);
      return;
    }
    void startItem(next);
  };

  const meta: Array<{icon: LucideIcon; label: string}> = [];
  if (minutes !== null) {
    meta.push({
      icon: Clock3,
      label: priority.stepPromptCount > 0
        ? `${priority.stepPromptCount} sujets · ≈ ${minutes} min`
        : `≈ ${minutes} min`,
    });
  }
  meta.push({icon: Target, label: PLAN_ACTION_NATURE_LABEL[priority.nature]});

  return (
    <Section title={free ? "Votre première étape est prête" : "À faire maintenant"}>
      <Pad>
        <NowCard
          icon={SECTION_ICON[priority.section]}
          title={productionSectionLabel(priority.section)}
          subtitle={`${repere} · ${priority.title}`}
          badge={free ? undefined : "Priorité n°1"}
          objectiveLabel="Compétence actuelle"
          objective={priority.title}
          meta={meta}
        >
          {priorityLines(priority).map((line) => (
            <p className={sejourStyles.tiny} key={line}>{line}</p>
          ))}
          {actionLocked ? (
            <LockList>
              <LockItem icon={Lock} label="Exercice recommandé" />
              <LockItem icon={Lock} label="Correction personnalisée" />
              <LockItem icon={Lock} label="Suivi de cette compétence" />
            </LockList>
          ) : (
            <Cta onClick={startNext} disabled={busy}>
              {busy ? PLAN_STARTING : cta}
            </Cta>
          )}
        </NowCard>
        {actionLocked && (
          <p className={sejourStyles.tiny}>
            Cet entraînement fait partie du pass Intégral. Votre plan, lui, reste entier.
          </p>
        )}
        {(error ?? assessments.error) && (
          <p className={sejourStyles.tiny} role="alert">{error ?? assessments.error}</p>
        )}
      </Pad>
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen="plan"
        module="INTEGRAL"
        open={paywallOpen || assessments.paywallOpen}
        onClose={() => { closePaywall(); assessments.closePaywall(); }}
      />
    </Section>
  );
}

/**
 * Pourquoi cette compétence est en tête — **des faits servis**, pas un
 * jugement. 🛑 La nature passe avant les compteurs : « 0 sujet sur 5 » se
 * lirait comme un retard alors qu'il n'y avait rien à traiter.
 *
 * ⚠️ Miroir mot pour mot du mobile (`planPriorityLines`, `plan_labels.dart`).
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

  const state = masteryStateLabel(priority.masteryState);
  if (priority.stepPromptCount > 0) {
    const s = priority.stepAttemptedCount > 1 ? "s" : "";
    const done = `${priority.stepAttemptedCount} sujet${s} sur ${priority.stepPromptCount} traité${s} dans cette étape`;
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

/* -------------------------------------------------------- vos priorités */

/** Les priorités, **groupées par épreuve puis par tâche** — le groupement vit
 *  dans `lib/plan-domain.ts` et l'ordre reste celui du serveur. Le rang vient
 *  de cet ordre, jamais d'un champ. */
function usePriorityGroups(plan: LearningPlanDto): PlanPriorityGroup[] {
  return useMemo(
    () => planPriorityGroups(plan, planActivePriorities(plan)).slice(0, 3),
    [plan],
  );
}

function rankOf(index: number): 1 | 2 | 3 {
  return index === 0 ? 1 : index === 1 ? 2 : 3;
}

function PriorityCard({group, rank, currentSkillId, detailed}: {
  group: PlanPriorityGroup;
  rank: 1 | 2 | 3;
  currentSkillId: string | null;
  /** L'abonné déroule les compétences de la tâche ; le plan gratuit s'arrête au
   *  repère et au compte — il ne nomme aucune ligne verrouillée. */
  detailed?: boolean;
}) {
  const rows = group.rows;
  const solid = rows.filter((row) => row.status === "SOLIDE").length;
  const visible = rows.slice(0, PLAN_PRIORITY_ROWS_VISIBLE);

  return (
    <Prio
      rank={rank}
      tag={`Priorité ${rank}`}
      title={groupTitle(group)}
      text={planRowStatusSummary(rows.map((row) => row.status))}
    >
      {rows.length > 0 && (
        <ProgressMini
          ratio={solid / rows.length}
          label={`${solid} compétence${solid > 1 ? "s" : ""} solide${solid > 1 ? "s" : ""} sur ${rows.length}`}
        />
      )}
      {detailed && visible.length > 0 && (
        <SkillList>
          {visible.map((row) => (
            <SkillRow
              key={row.skillId}
              label={row.title}
              state={row.skillId === currentSkillId ? "now" : row.status === "SOLIDE" ? "done" : "todo"}
            />
          ))}
        </SkillList>
      )}
    </Prio>
  );
}

function groupTitle(group: PlanPriorityGroup): string {
  if (group.taskNumber !== null) return `${group.label} — ${planTaskBadge(group.taskNumber)}`;
  return group.context ? `${group.label} — ${group.context}` : group.label;
}

/* -------------------------------------------------------------- parcours */

interface TachePath {
  title: string;
  currentLabel: string;
  counterLabel: string;
  steps: PathStep[];
  /** La même liste, vue par un compte gratuit : le rang et le cadenas restent
   *  nets, le titre d'une ligne **verrouillée** passe derrière le rideau. */
  locked: Array<{key: string; label: string; icon: LucideIcon; blurred: boolean}>;
}

/**
 * **Le parcours de la tâche de la priorité courante.**
 *
 * 🛑 « Étape X / Y » se lit sur `domaines[].taches[]`
 * (`observedSkills` / `totalSkills`), il ne s'invente pas. Les états des lignes
 * viennent de `planRowStatus`, donc des enums servis.
 */
function parcoursDeLaTache(plan: LearningPlanDto, priority: LearningPlanPriorityDto): TachePath | null {
  const code = skillTaskCode(priority.skillCode);
  if (!code) return null;
  const domain = findDomain(plan, planSectionEpreuve(priority.section));
  if (!domain) return null;
  const tache = domain.taches.find((candidate) => candidate.taskCode === code);
  const skills = (domain.skills ?? []).filter((skill) => skill.taskCode === code);
  if (!tache || skills.length === 0) return null;

  const state = (skillId: string, solide: boolean): StepState =>
    skillId === priority.skillId ? "now" : solide ? "done" : "todo";

  return {
    title: `Votre parcours — ${planTaskBadge(tache.tacheNumero)}`,
    currentLabel: priority.title,
    counterLabel: `Étape ${tache.observedSkills} / ${tache.totalSkills}`,
    steps: skills.map((skill) => ({
      label: skill.title,
      state: state(skill.skillId, planRowStatus(skill) === "SOLIDE"),
    })),
    locked: skills.map((skill) => ({
      key: skill.skillId,
      label: skill.title,
      icon: skill.locked ? Lock : planRowStatus(skill) === "SOLIDE" ? Check : Circle,
      blurred: skill.locked,
    })),
  };
}

interface PalierPathData {
  title: string;
  currentLabel: string;
  counterLabel: string;
  steps: PathStep[];
  note: string | null;
}

/** Le chemin de palier — **le seul parcours à état explicite** servi par le
 *  serveur (`cycle.path`, `DONE|CURRENT|UPCOMING`). Sa note dit **comment** un
 *  palier se confirme, ce qu'aucun autre bloc de l'écran ne porte. */
function parcoursDuPalier(cycle: PlanCycleDto): PalierPathData | null {
  if (cycle.path.length === 0) return null;
  const index = cycle.path.findIndex((step) => step.status === "CURRENT");
  const current = index >= 0 ? cycle.path[index] : null;
  return {
    title: planPathTitle(cycle),
    currentLabel: current ? planPathStepTitle(current) : planPathTitle(cycle),
    counterLabel: `Étape ${Math.max(index, 0) + 1} / ${cycle.path.length}`,
    steps: cycle.path.map((step): PathStep => ({
      label: planPathStepTitle(step),
      state: step.status === "DONE" ? "done" : step.status === "CURRENT" ? "now" : "todo",
    })),
    note: current ? planPathStepNote(current, cycle) : null,
  };
}

function PalierPath({path}: {path: PalierPathData}) {
  return (
    <Section title={path.title} flush>
      <PathCard
        currentLabel={path.currentLabel}
        counterLabel={path.counterLabel}
        steps={path.steps}
      />
      {path.note && <p className={sejourStyles.tiny}>{path.note}</p>}
    </Section>
  );
}

/* ------------------------------------------------------------ déjà validé */

function completedLabel(step: LearningPlanCompletedStepDto): string {
  const task = skillTaskNumber(step.skillCode);
  const domaine = productionSectionLabel(step.section);
  return task
    ? `${step.title} — ${domaine}, ${planTaskBadge(task)}`
    : `${step.title} — ${domaine}`;
}

/* -------------------------------------------------- progression détectée */

/**
 * 🛑 **`recentChanges === null` est le cas NORMAL** : le bloc disparaît, il ne
 * s'affiche pas vide. Le sens de la marche vient de `progress`, calculé
 * serveur — aucun front ne code l'ordre des quatre états.
 */
function ProgressionDetectee({plan}: {plan: LearningPlanDto}) {
  const changes = plan.recentChanges;
  if (!changes) return null;
  if (changes.transitions.length === 0 && !changes.newPriority) return null;

  const monte = changes.transitions.some((transition) => transition.progress);
  const titre = changes.transitions.length === 0
    ? "Votre plan a changé"
    : monte ? "Progression détectée" : "Réévaluation";

  return (
    <Section flush>
      <Card variant="ok">
        <p className={sejourStyles.label}>{titre}</p>
        {changes.transitions.map((transition) => (
          <DoneRow
            key={transition.skillId}
            label={`${transition.title} · ${planTransitionLine(transition)}`}
          />
        ))}
        {changes.newPriority && (
          <p className={sejourStyles.insight}>
            Votre prochaine priorité devient : <b>{changes.newPriority.title}</b>
          </p>
        )}
        <Link className={sejourStyles.link} href="/plan/evolution">
          <RefreshCw size={15} aria-hidden /> Voir le détail
          <ChevronRight size={15} aria-hidden />
        </Link>
      </Card>
    </Section>
  );
}

/* -------------------------------------------------- compléter mon profil */

/** **Vide = profil complet**, l'état visé et non une anomalie : la section
 *  disparaît, sans message de félicitations. */
function CompleterMonProfil({plan}: {plan: LearningPlanDto}) {
  const {start, starting, error, paywallOpen, closePaywall} = usePlanAssessment();
  if (plan.domainesAEvaluer.length === 0) return null;
  return (
    <Section title={PLAN_COMPLETE_PROFILE_TITLE}>
      <Pad>
        <Stack>
          <p className={sejourStyles.tiny}>{PLAN_COMPLETE_PROFILE_TEXT}</p>
          {/* Les cartes d'épreuve passent en deux colonnes au palier desktop —
              le pendant de `sf-exam-grid` de la maquette. Les deux phrases, qui
              se lisent en pleine largeur, restent hors de la grille. */}
          <Stack className={sejourStyles.deskGrid2}>
            {plan.domainesAEvaluer.map((assessment) => (
              <AssessmentCard
                key={`${assessment.epreuve}-${assessment.kind}`}
                assessment={assessment}
                busy={starting === assessment.epreuve}
                onStart={() => void start(assessment)}
              />
            ))}
          </Stack>
          <p className={sejourStyles.tiny}>{PLAN_COMPLETE_PROFILE_NOTE}</p>
          {error && <p className={sejourStyles.tiny} role="alert">{error}</p>}
        </Stack>
      </Pad>
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen="plan"
        module="INTEGRAL"
        open={paywallOpen}
        onClose={closePaywall}
      />
    </Section>
  );
}

function AssessmentCard({assessment, busy, onStart}: {
  assessment: PlanDomainAssessmentDto;
  busy: boolean;
  onStart: () => void;
}) {
  const section: SkillSection = assessment.epreuve === "TCF_CO" ? "CO"
    : assessment.epreuve === "TCF_CE" ? "CE"
      : assessment.epreuve === "TCF_EO" ? "EO" : "EE";
  return (
    <Card padding="rows">
      <ExamRow
        icon={SECTION_ICON[section]}
        title={planDomainLabel(assessment.epreuve)}
        subtitle={planAssessmentMeta(assessment)}
      />
      <Cta variant="line" onClick={onStart} disabled={busy}>
        {busy ? PLAN_STARTING : planAssessmentCta(assessment)}
      </Cta>
    </Card>
  );
}

/* ------------------------------------------------------- aller plus loin */

/** Les écrans adossés au Plan ne sont accessibles que d'ici : la barre latérale
 *  ne les porte pas.
 *
 *  Les trois accès se rangent en ligne au palier desktop (`deskGrid`) : empilés
 *  sur 1 080 px de colonne, ils faisaient une carte haute et vide. */
function AllerPlusLoin() {
  const rows: Array<{href: string; label: string}> = [
    {href: PLAN_SKILLS_HREF, label: PLAN_SKILLS_TITLE},
    {href: PLAN_PROGRESS_HREF, label: PLAN_PROGRESS_TITLE_SHORT},
    {href: "/diagnostic", label: "Mon diagnostic"},
  ];
  return (
    <Section title="Aller plus loin">
      <Pad>
        <Card padding="rows">
          <Stack className={sejourStyles.deskGrid}>
            {rows.map((row) => (
              <Link key={row.href} className={sejourStyles.link} href={row.href}>
                {row.label} <ChevronRight size={15} aria-hidden />
              </Link>
            ))}
          </Stack>
        </Card>
      </Pad>
    </Section>
  );
}
