"use client";

import Link from "next/link";
import {useEffect, useMemo, useState, type ReactNode} from "react";
import {
  Check,
  ChevronRight,
  Circle,
  Clock3,
  Lock,
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
  planGroupMoreLabel,
  PLAN_GROUP_LESS_LABEL,
  PLAN_PRIORITY_ROWS_COLLAPSED,
  PLAN_PRIORITY_ROWS_VISIBLE,
  PLAN_PROGRESS_HREF,
  PLAN_PROGRESS_LEVEL_UNKNOWN,
  PLAN_PROGRESS_TITLE_SHORT,
  PLAN_SKILLS_HREF,
  PLAN_SKILLS_TITLE,
  PLAN_STARTING,
  planActivePriorities,
  planNowCard,
  planPathStepNote,
  planPathStepTitle,
  planPathTitle,
  planPriorityGroups,
  parcoursDeLaTache,
  type PlanTachePath,
  planRowStatusSummary,
  planTaskBadge,
  planTransitionLine,
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
  type LearningPlanCompletedStepDto,
  type LearningPlanDto,
  type ModulePreparation,
  type PlanCycleDto,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
  Card,
  Cta,
  DoneRow,
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
} from "@/app/_components/sejour/SejourKit";
import {PlanBlur, planNowIcon} from "./PlanBits";
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
    learningPlanApi.getCached().then(
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
     2026-09-12, tenu). Ce qui change le 2026-09-13 : il devient le SEUL appel
     à compléter son profil — « Compléter mon profil » et ses cartes d'épreuve
     ont été supprimés, et leur emplacement revient à cette carte.

     🛑 **Une seule occurrence du CTA par écran.** La carte descend donc DANS
     la vue (l'emplacement de l'ancien bloc chez l'abonné, après le paywall
     chez un compte gratuit) au lieu d'être posée une seconde fois ici. Elle
     disparaît d'elle-même à 4 / 4 : c'est `affinerPlan` qui rend `null`, sur
     des faits servis. */
  const abonne = canAccessModule(user, "TCF");
  const affiner = prep ? affinerPlan(prep, {surface: "plan", abonne}) : null;
  const affinerCard = affiner ? <AffinerPlanCard info={affiner} /> : null;

  return (
    <>
      {abonne
        ? <TcfPlanPremium plan={plan} affiner={affinerCard} />
        : <TcfPlanFree plan={plan} affiner={affinerCard} />}
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

function TcfPlanPremium({plan, affiner}: {plan: LearningPlanDto; affiner: ReactNode}) {
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
                  foldable={groups.length > 1}
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
          ne couvre pas — un examen blanc mérité et le chemin des paliers quand
          ce n'est pas lui qui sert de parcours. */}
      {plan.milestone && <PlanMilestoneCard milestone={plan.milestone} />}

      {/* 🛑 L'emplacement de l'ancien « Compléter mon profil » : c'est ici que
          se complète un profil, et il n'y a plus qu'une façon de le faire. */}
      {affiner}

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

function TcfPlanFree({plan, affiner}: {plan: LearningPlanDto; affiner: ReactNode}) {
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
            {lignesVerrouillees(tachePath).map((row, index) => (
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

      {/* 🛑 APRÈS le paywall, et c'est délibéré : sur un Plan gratuit, le seul
          bouton ROUGE de la page reste « Débloquer mon plan ». Le diagnostic
          complet, lui, porte le bleu plein — visible, jamais concurrent. */}
      {affiner}
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
  const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const assessments = usePlanAssessment();

  /* 🛑 **L'identité de la carte est décidée par `planNowCard`, pas ici** — la
     même autorité que l'Accueil (`ActionPrincipale`) et que les deux cartes du
     mobile. C'est elle qui applique « une MESURE passe devant tout le reste »,
     et qui garantit que les deux écrans annoncent la même action. */
  const vue = planNowCard(plan, {free});
  if (!vue) return null;

  const {mesure, exercise, lines} = vue;
  const actionLocked = vue.locked;

  const busy = starting || assessments.starting !== null;
  const startNext = () => {
    if (mesure) {
      void assessments.start(mesure.assessment);
      return;
    }
    if (exercise) void start(exercise);
  };

  const meta: Array<{icon: LucideIcon; label: string}> = [];
  if (vue.minutesLabel) meta.push({icon: Clock3, label: vue.minutesLabel});
  if (vue.kindLabel) meta.push({icon: Target, label: vue.kindLabel});

  /* 🛑 **Un compte SANS accès ne voit pas la carte d'un abonné** (correctif du
     2026-09-12, sur la maquette du propriétaire `~/Desktop/capture_plan_gratuit.png`).
     « Votre première étape est prête » nomme l'étape et montre les **trois
     bénéfices verrouillés** — c'est sa raison d'être.

     🛑 **AUCUN geste ne part d'ici** (arbitrage du propriétaire, 2026-09-12 :
     « dans le plan, on ne travaille rien si on n'est pas abonné ; on passe par
     Réviser pour voir ce qu'on peut utiliser gratuitement »). */
  return (
    <Section title={free ? "Votre première étape est prête" : "À faire maintenant"}>
      <Pad>
        <NowCard
          icon={planNowIcon(vue)}
          variant={vue.nature === "VERIFICATION" && !free ? "verify" : "default"}
          title={vue.title}
          subtitle={vue.subtitle}
          badge={vue.badge ?? undefined}
          objectiveLabel={vue.objectiveLabel ?? undefined}
          objective={vue.objective ?? undefined}
          meta={meta}
        >
          {/* Deux lignes DISTINCTES : ce que le correcteur a constaté, et où en
              est la série. Concaténées, la seconde se lisait comme la suite de
              la première phrase. Sur une mesure, c'est le motif de la mesure
              qui se dit — jamais le constat d'une AUTRE compétence. */}
          {lines.map((line: string) => (
            <p className={sejourStyles.tiny} key={line}>{line}</p>
          ))}
          {(free || actionLocked) && (
            <LockList>
              <LockItem icon={Lock} label="Exercice recommandé" />
              <LockItem icon={Lock} label="Correction personnalisée" />
              <LockItem icon={Lock} label="Suivi de cette compétence" />
            </LockList>
          )}
          {!free && !actionLocked && (
            <Cta onClick={startNext} disabled={busy}>
              {busy ? PLAN_STARTING : vue.cta}
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
      <PaywallSheet origin="plan"
        ctaLocation="LOCKED_PLAN"
        screen="plan"
        module="INTEGRAL"
        open={paywallOpen || assessments.paywallOpen}
        onClose={() => { closePaywall(); assessments.closePaywall(); }}
      />
    </Section>
  );
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

function PriorityCard({group, rank, currentSkillId, detailed, foldable}: {
  group: PlanPriorityGroup;
  rank: 1 | 2 | 3;
  currentSkillId: string | null;
  /** L'abonné déroule les compétences de la tâche ; le plan gratuit s'arrête au
   *  repère et au compte — il ne nomme aucune ligne verrouillée. */
  detailed?: boolean;
  /** 🛑 Rétractable dès qu'il y a plus d'une priorité à l'écran. Une priorité
   *  seule n'a aucune raison de se replier : elle EST l'écran. */
  foldable?: boolean;
}) {
  const rows = group.rows;
  const solid = rows.filter((row) => row.status === "SOLIDE").length;
  const visible = rows.slice(0, PLAN_PRIORITY_ROWS_VISIBLE);
  // Un plan gratuit ne nomme aucune ligne : il n'y a rien à replier.
  const folded = detailed && foldable ? rows.slice(PLAN_PRIORITY_ROWS_COLLAPSED) : [];
  const shown = folded.length > 0 ? rows.slice(0, PLAN_PRIORITY_ROWS_COLLAPSED) : visible;

  const skillRow = (row: PlanPriorityGroup["rows"][number]) => (
    <SkillRow
      key={row.skillId}
      label={row.title}
      state={row.skillId === currentSkillId ? "now" : row.status === "SOLIDE" ? "done" : "todo"}
    />
  );

  return (
    <Prio
      rank={rank}
      tag={`Priorité ${rank}`}
      title={groupTitle(group)}
      text={planRowStatusSummary(rows.map((row) => row.status))}
      // 🛑 Le compteur du bouton porte sur ce qui est RÉELLEMENT replié —
      // jamais une constante, jamais le « + N autres » d'un autre plafond.
      moreLabel={folded.length > 0 ? planGroupMoreLabel(folded.length) : undefined}
      lessLabel={folded.length > 0 ? PLAN_GROUP_LESS_LABEL : undefined}
      details={folded.length > 0 ? <SkillList>{folded.map(skillRow)}</SkillList> : undefined}
    >
      {rows.length > 0 && (
        <ProgressMini
          ratio={solid / rows.length}
          label={`${solid} compétence${solid > 1 ? "s" : ""} solide${solid > 1 ? "s" : ""} sur ${rows.length}`}
        />
      )}
      {detailed && shown.length > 0 && <SkillList>{shown.map(skillRow)}</SkillList>}
    </Prio>
  );
}

function groupTitle(group: PlanPriorityGroup): string {
  if (group.taskNumber !== null) return `${group.label} — ${planTaskBadge(group.taskNumber)}`;
  return group.context ? `${group.label} — ${group.context}` : group.label;
}

/* -------------------------------------------------------------- parcours */

/** La même liste, vue par un compte gratuit : le rang et le cadenas restent
 *  nets, le titre d'une ligne **verrouillée** passe derrière le rideau.
 *
 * 🛑 La dérivation, elle, vit dans `parcoursDeLaTache` (`lib/plan-domain.ts`),
 * partagée avec le bloc « Votre Plan » de l'Accueil : deux copies auraient fini
 * par cocher deux étapes différentes. Ici on n'habille que les icônes, que la
 * couche pure n'a pas à connaître.
 */
function lignesVerrouillees(path: PlanTachePath) {
  return path.skills.map((skill) => ({
    key: skill.skillId,
    label: skill.title,
    /* 🛑 La coche suit l'état d'étape **servi** — jamais un statut reclassé
       ici : seul `ACQUIS` (donc `SOLID`) en mérite une. */
    icon: skill.locked ? Lock : skill.stepState === "ACQUIS" ? Check : Circle,
    blurred: skill.locked,
  }));
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
