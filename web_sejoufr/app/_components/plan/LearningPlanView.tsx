"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {
  ChevronRight,
  Clock3,
  Target,
  type LucideIcon,
} from "lucide-react";
import {ApiException, journeyApi, learningPlanApi} from "@/lib/api";
import {track} from "@/lib/analytics";
import {withTrafficSource} from "@/lib/traffic-source";
import {useAuth} from "@/lib/auth-context";
import {
  PLAN_PROGRESS_LEVEL_UNKNOWN,
  PLAN_STARTING,
  planNowCard,
} from "@/lib/plan-domain";
import {JOURNEY_HISTORY_TITLE, journeyHistoryHref, journeyTargetPathHref} from "@/lib/journey";
import {planHref} from "@/lib/module-switch";
import {planIndisponibleDepuisEtat} from "@/lib/preparation";
import {
  canAccessModule,
  type JourneyDto,
  type LearningPlanDto,
  type ModulePreparation,
  type PlanCycleDto,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {useRouter} from "next/navigation";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {planUnlockHref} from "@/lib/plan-unlock";
import {
  Card,
  Cta,
  GoalStrip,
  NowCard,
  Pad,
  Section,
  Stack,
  Top,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {planNowIcon} from "./PlanBits";
import {PlanGate} from "./PlanGate";
import {PlanPaywall} from "./PlanPaywallCard";
import {PlanMilestoneCard} from "./PlanMilestoneCard";
import {PlanCycleSection} from "./PlanCycleSection";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";

/**
 * **Le Plan TCF** — refonte du 2026-09-11 sur le kit `sejour/`.
 *
 * Deux écrans, un seul contrat de données (`GET /api/me/plan`) : l'**abonné**
 * lit son parcours (à faire maintenant → le cycle par épreuve), le **gratuit**
 * lit le même cycle, cadenassé, et ce qu'un pass ouvrirait.
 *
 * 🛑 **Le bloc « Vos priorités pour atteindre … » n'existe plus** (arbitrage du
 * propriétaire, 2026-09-18) : il disait la même chose que les blocs d'épreuve
 * du cycle, en moins précis — mêmes compétences, sans leur position dans le
 * cycle, sans leur examen, et plafonné à trois groupes. Ne pas le réintroduire.
 *
 * 🛑 **Le bas de l'écran a été VIDÉ** (arbitrage du propriétaire, 2026-09-19) :
 * « Déjà travaillé et validé », « Progression détectée », la carte du
 * diagnostic complet en cours, « Toutes mes compétences », « Mes examens
 * blancs » et « Revoir mon diagnostic rapide » ont été supprimés. Sous le
 * cycle il ne reste que « Mes cycles » et « Mon diagnostic ». Ne pas les
 * réintroduire.
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
 *   largeur, puis le cycle en pleine largeur ;
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

  /* 🛑 **Aucune invitation au diagnostic complet ici** (arbitrage du
     propriétaire, 2026-09-19) : la carte « Diagnostic complet en cours » a été
     supprimée du Plan, puis de l'Accueil le même jour — `affinerPlan` et
     `AffinerPlanCard` avec elle. Le complet garde sa porte, `/diagnostic-tcf`
     (Réviser, `planIndisponible`). Ne pas la réintroduire sur cet écran. */
  const abonne = canAccessModule(user, "TCF");

  return abonne
    ? <TcfPlanPremium plan={plan} journey={journey} />
    : <TcfPlanFree plan={plan} journey={journey} />;
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

function TcfPlanPremium({plan, journey}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
}) {
  const objective = plan.cycle.objectiveLevel;

  return (
    <>
      <Top
        kicker={objective ? `Votre parcours personnalisé vers ${objective}` : "Votre parcours personnalisé"}
        title="Mon plan du jour"
      />

      <Pad>
        <CycleGoal cycle={plan.cycle} />
      </Pad>

      <ActionMaintenant plan={plan} journey={journey} />

      {/* 🛑 **Le CYCLE remplace la file plate** (D-12 / D-22, 2026-09-18) : un
          bloc par épreuve, l'examen en fin de bloc, et la fin de cycle avec ses
          deux issues. Il prend **toute la largeur** — quatre accordéons dans une
          demi-colonne de tableau de bord ne se lisent plus. */}
      <PlanCycleSection journey={journey} plan={plan} />

      {/* ⚠️ Bloc conservé hors maquette : il porte une information qu'elle ne
          couvre pas — un examen blanc mérité. */}
      {plan.milestone && <PlanMilestoneCard milestone={plan.milestone} />}

      <AllerPlusLoin />

      <p className={sejourStyles.footNote}>
        Estimation d&apos;entraînement SejourFR, non officielle : elle situe votre travail,
        elle ne remplace pas le résultat du TCF.
      </p>
    </>
  );
}

/* ---------------------------------------------------------------- gratuit */

function TcfPlanFree({plan, journey}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
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

      {/* ✅ **Visible aussi sans accès** (demande du propriétaire,
          2026-09-20) : ce sont deux **constats** — ce qui a été mesuré, ce qui
          a été fait — et rien ne s'y travaille. Les en priver n'ouvrait aucun
          droit, ça retirait la lecture de son propre parcours à celui qui en a
          le plus besoin. La barre « Débloquer mon plan » reste la seule
          **action** dominante de l'écran. */}
      <AllerPlusLoin />

      <PlanPaywall
        module="TCF"
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
        <Link className={sejourStyles.link} href={journeyTargetPathHref(planHref("TCF"))}>
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

  /* 🛑 **Depuis le Plan, TOUT chemin vers le paywall passe par l'écran de
     transition** (demande du propriétaire, 2026-09-20, TCF **et** civique) : il
     dit au candidat ce qu'il achète — ses priorités, son écart à l'objectif, le
     prix d'entrée — avant de lui montrer des durées et des montants. Deux
     chemins vers le même achat, dont un plus pauvre, c'est la porte que
     personne ne pense à corriger. */
  const router = useRouter();

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

  /* 🛑 **Un compte sans accès voit EXACTEMENT la carte d'un abonné** (demande
     du propriétaire, 2026-09-20). L'anatomie distincte du 2026-09-12 —
     « Votre première étape est prête » et ses trois bénéfices verrouillés —
     est **supprimée** : elle taisait la pastille de priorité, les métas, le
     constat du correcteur et la progression, tous des **résultats mesurés**
     que la contradiction #1 demande justement de montrer.

     🛑 **AUCUN ENTRAÎNEMENT ne part d'ici** — l'arbitrage du 2026-09-12 qui
     TIENT (« dans le plan, on ne travaille rien si on n'est pas abonné ; on
     passe par Réviser »). La garantie n'est pas dans cet écran : `planNowCard`
     rend `geste === "DEBLOQUER"` dès que `free`, et le seul rendu attaché à ce
     geste ci-dessous est `setUnlockOpen(true)`. Aucun lanceur n'y est
     joignable. */
  return (
    <Section title="À faire maintenant">
      <Pad>
        <NowCard
          icon={planNowIcon(vue)}
          variant={vue.nature === "VERIFICATION" ? "verify" : "default"}
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
          {/* 🛑 **Le bouton dit ce que le geste FAIT**, et son libellé vient
              lui aussi de `planNowCard` : `PLAN_NOW_CTA_LOCKED` sur un verrou
              (son motif est écrit à sa déclaration), l'action sinon. En
              **bleu** (A46) : sur un Plan gratuit, le seul bouton rouge de la
              page reste celui de la barre basse. */}
          {debloquer && (
            <Cta variant="blue" onClick={() => router.push(planUnlockHref("TCF"))}>
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
          {/* 🛑 **`OUVRIR_ETAPE` ouvre l'écran de l'étape**, il ne lance rien :
              une compétence de compréhension et une unité civique se
              travaillent par séries, et le candidat les choisit là-bas. La
              destination est **servie** par `planNowCard` — cet écran ne
              recompose aucune adresse. */}
          {vue.geste === "OUVRIR_ETAPE" && vue.etapeHref && (
            <Cta href={vue.etapeHref}>{vue.cta}</Cta>
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
      {/* ⚠️ **Ce paywall ne répond plus qu'à un 403** : depuis que tout geste
          d'achat du Plan passe par l'écran de transition, plus rien ici ne
          l'ouvre délibérément. Il reste parce qu'un lanceur peut toujours se
          voir refuser au démarrage — c'est un refus, pas une vente. */}
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen="plan"
        module="INTEGRAL"
        open={paywallOpen || assessments.paywallOpen}
        onClose={() => {
          closePaywall();
          assessments.closePaywall();
        }}
      />
    </Section>
  );
}

/* ------------------------------------------------------- aller plus loin */

/** Les écrans adossés au Plan ne sont accessibles que d'ici : la barre latérale
 *  ne les porte pas.
 *
 *  🛑 **Deux accès, et deux seulement** (arbitrage du propriétaire,
 *  2026-09-19) : « Toutes mes compétences » et « Mes examens blancs » ont été
 *  retirés — le premier avec son écran, le second parce que l'onglet Examens
 *  de la barre de navigation y mène déjà. Ne pas les réintroduire.
 *
 *  Les deux accès se rangent en ligne au palier desktop (`deskGrid`) : empilés
 *  sur 1 080 px de colonne, ils faisaient une carte haute et vide. */
function AllerPlusLoin() {
  const rows: Array<{href: string; label: string}> = [
    {href: journeyHistoryHref("TCF"), label: JOURNEY_HISTORY_TITLE},
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
