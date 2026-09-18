"use client";

import Link from "next/link";
import {useEffect, useState, type ReactNode} from "react";
import {
  ChevronRight,
  Clock3,
  Lock,
  RefreshCw,
  Target,
  type LucideIcon,
} from "lucide-react";
import {ApiException, journeyApi, learningPlanApi} from "@/lib/api";
import {track} from "@/lib/analytics";
import {withTrafficSource} from "@/lib/traffic-source";
import {useAuth} from "@/lib/auth-context";
import {productionSectionLabel, skillTaskNumber} from "@/lib/diagnostic";
import {
  PLAN_PROGRESS_HREF,
  PLAN_PROGRESS_LEVEL_UNKNOWN,
  PLAN_PROGRESS_TITLE_SHORT,
  PLAN_SKILLS_HREF,
  PLAN_SKILLS_TITLE,
  PLAN_STARTING,
  planNowCard,
  planTaskBadge,
  planTransitionLine,
} from "@/lib/plan-domain";
import {
  affinerPlan,
  DIAGNOSTIC_RAPIDE_HREF,
  PLAN_REVOIR_ESTIMATION,
  planIndisponibleDepuisEtat,
} from "@/lib/preparation";
import {
  canAccessModule,
  type JourneyDto,
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
  NowCard,
  Pad,
  Section,
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
import {PlanCycleSection} from "./PlanCycleSection";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";

/**
 * **Le Plan TCF** — refonte du 2026-09-11 sur le kit `sejour/`.
 *
 * Deux écrans, un seul contrat de données (`GET /api/me/plan`) : l'**abonné**
 * lit son parcours (à faire maintenant → le cycle par épreuve → déjà validé →
 * progression détectée), le **gratuit** lit le même cycle, cadenassé, et ce
 * qu'un pass ouvrirait.
 *
 * 🛑 **Le bloc « Vos priorités pour atteindre … » n'existe plus** (arbitrage du
 * propriétaire, 2026-09-18) : il disait la même chose que les blocs d'épreuve
 * du cycle, en moins précis — mêmes compétences, sans leur position dans le
 * cycle, sans leur examen, et plafonné à trois groupes. Ne pas le réintroduire.
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
 *   largeur, le cycle en pleine largeur, puis `deskPair`
 *   « Déjà travaillé et validé » | « Progression détectée » ;
 * - **gratuit** (`SejourApp sticky`, 980 px) : la maquette n'y met **aucune**
 *   paire. 🛑 C'est voulu : sur cet écran, « Débloquer mon plan » doit rester
 *   la seule action dominante, et mettre deux blocs côte à côte au-dessus
 *   d'elle remplirait l'espace de choses à faire au lieu de mener au
 *   déblocage.
 */

/* ------------------------------------------------------------------ racine */

export function LearningPlanView({prep}: {prep?: ModulePreparation | null}) {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  /* 🛑 Le parcours est chargé **en parallèle** du Plan, jamais après : les deux
     alimentent le même écran, et les enchaîner ferait clignoter la carte
     « À faire maintenant » entre deux autorités. Son échec est **silencieux** —
     un backend antérieur à l'endpoint ne doit pas casser le Plan, qui garde sa
     règle tant que le parcours n'a rien à dire. */
  const [journey, setJourney] = useState<JourneyDto | null>(null);
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
    journeyApi.getCached().then(
      (current) => { if (!cancelled) setJourney(current); },
      () => { /* silencieux : le Plan reste lisible sans son parcours */ },
    );
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
        ? <TcfPlanPremium plan={plan} journey={journey} affiner={affinerCard} />
        : <TcfPlanFree plan={plan} journey={journey} affiner={affinerCard} />}
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

function TcfPlanPremium({plan, journey, affiner}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
  affiner: ReactNode;
}) {
  const objective = plan.cycle.objectiveLevel;
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

      <ActionMaintenant plan={plan} journey={journey} />

      {/* 🛑 **Le CYCLE remplace la file plate** (D-12 / D-22, 2026-09-18) : un
          bloc par épreuve, l'examen en fin de bloc, et la fin de cycle avec ses
          deux issues. Il prend **toute la largeur** — quatre accordéons dans une
          demi-colonne de tableau de bord ne se lisent plus. */}
      <PlanCycleSection journey={journey} plan={plan} />

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

      <AllerPlusLoin />

      <p className={sejourStyles.footNote}>
        Estimation d&apos;entraînement SejourFR, non officielle : elle situe votre travail,
        elle ne remplace pas le résultat du TCF.
      </p>
    </>
  );
}

/* ---------------------------------------------------------------- gratuit */

function TcfPlanFree({plan, journey, affiner}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
  affiner: ReactNode;
}) {
  const objective = plan.cycle.objectiveLevel;
  return (
    <>
      <Top
        kicker="Créé à partir de votre diagnostic"
        title={objective ? `Mon plan du jour ${objective}` : "Mon plan du jour"}
      />

      <Pad>
        <CycleGoal cycle={plan.cycle} />
      </Pad>

      <ActionMaintenant plan={plan} journey={journey} free />

      {/* 🛑 **Le cycle reste ENTIER, même sans accès** : ses quatre blocs et
          toutes leurs étapes sont affichés à leur place, avec leur cadenas. Le
          masquer priverait le candidat de l'information la plus utile qu'il
          possède — c'est la contradiction #1 du dépôt, tranchée le 2026-08-21.
          Le bouton « Débloquer mon plan » est **juste en dessous**. */}
      <PlanCycleSection journey={journey} plan={plan} />

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
function ActionMaintenant({plan, journey, free}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
  free?: boolean;
}) {
  const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const assessments = usePlanAssessment();
  /* 🛑 **Le paywall d'une étape VERROUILLÉE** (spec §7 / D-18) : la carte nomme
     l'étape fermée, et le geste ouvre l'offre. C'est le paywall **existant** du
     Plan, avec son contexte (`origin="plan"`, `LOCKED_PLAN`) — aucune modale
     nouvelle, aucun libellé nouveau. Il est distinct des deux paywalls des
     lanceurs, qui répondent à un **403** ; celui-ci répond à un `locked` servi,
     avant tout appel. */
  const [unlockOpen, setUnlockOpen] = useState(false);

  /* 🛑 **L'identité de la carte est décidée par `planNowCard`, pas ici** — la
     même autorité que l'Accueil (`ActionPrincipale`) et que les deux cartes du
     mobile. C'est elle qui applique « une MESURE passe devant tout le reste »,
     et qui garantit que les deux écrans annoncent la même action. */
  const vue = planNowCard(plan, {free, journey});
  if (!vue) return null;

  const {mesure, exercise, lines} = vue;
  const actionLocked = vue.locked;
  /* 🛑 **Le geste vient de `planNowCard`, il ne se redéduit pas ici.** Les six
     surfaces qui portent cette carte lisent le même champ ; recalculer
     « verrouillé ⇒ offre » de chaque côté est ce qui avait laissé cette carte
     muette pendant que le mobile ouvrait déjà l'offre. */
  const debloquer = vue.geste === "DEBLOQUER";

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

     🛑 **AUCUN ENTRAÎNEMENT ne part d'ici** (arbitrage du propriétaire,
     2026-09-12 : « dans le plan, on ne travaille rien si on n'est pas abonné ;
     on passe par Réviser pour voir ce qu'on peut utiliser gratuitement »). Le
     seul geste est l'**offre**, exigé par la spec §7 depuis D-18 : la carte
     nomme la première étape verrouillée, le tap ouvre « Débloquer mon plan ».
     Il ne travaille rien — il ne contredit donc pas l'arbitrage. */
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
          {/* 🛑 **Le bouton dit ce que le geste FAIT**, et son libellé vient
              lui aussi de `planNowCard` : « Débloquer cet entraînement » sur un
              verrou, l'action sinon. En **bleu** sur le verrou — sur un Plan
              gratuit, le seul bouton rouge de la page reste « Débloquer mon
              plan », ancré sous le cycle. */}
          {debloquer && (
            <Cta variant="blue" onClick={() => setUnlockOpen(true)}>
              {vue.cta}
            </Cta>
          )}
          {/* 🛑 **Aucun bouton sur une étape dont l'action ne se résout pas.**
              Il ne lançait rien, et la version d'avant lançait pire : la
              compétence que le Plan priorisait ce jour-là, pendant que la carte
              en annonçait une autre. */}
          {vue.geste === "LANCER" && (
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
        open={paywallOpen || assessments.paywallOpen || unlockOpen}
        onClose={() => {
          closePaywall();
          assessments.closePaywall();
          setUnlockOpen(false);
        }}
      />
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
