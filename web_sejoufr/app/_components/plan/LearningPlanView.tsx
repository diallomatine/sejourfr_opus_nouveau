"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {
  ChevronRight,
  Clock3,
  Target,
  type LucideIcon,
} from "lucide-react";
import {
  ApiException,
  dashboardApi,
  journeyApi,
  learningPlanApi,
} from "@/lib/api";
import {track} from "@/lib/analytics";
import {usePlanRelecture} from "@/lib/use-plan-relecture";
import {withTrafficSource} from "@/lib/traffic-source";
import {useAuth} from "@/lib/auth-context";
import {PLAN_STARTING, planNowCard} from "@/lib/plan-domain";
import {journeyTargetPathHref} from "@/lib/journey";
import {PlanLinks} from "./PlanLinks";
import {planHref} from "@/lib/module-switch";
import {
  MODULE_TCF_KICKER,
  PLAN_TCF_TITLE,
  planTcfChipActuel,
  planTcfChipObjectif,
  planTcfSubtitle,
} from "@/lib/module-ecrans";
import {useCachedData} from "@/lib/use-cached-data";
import {
  canAccessModule,
  type DashboardSummaryResponse,
  type JourneyDto,
  type LearningPlanDto,
  niveauCecrlShort,
  type TargetLevel,
} from "@/lib/types";
import {useTrafficSource} from "@/lib/use-traffic-source";
import {useRouter} from "next/navigation";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {planUnlockHref} from "@/lib/plan-unlock";
import {
  Badge,
  BlockSkeleton,
  Card,
  Cta,
  NowCard,
  Pad,
  PageHead,
  Section,
  Split,
  Stack,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {planNowIcon} from "./PlanBits";
import {PlanPaywall} from "./PlanPaywallCard";
import {PlanCycleSection} from "./PlanCycleSection";
import {ExamenCompletJalon} from "./ExamenCompletJalon";
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
 * ## Navigation v2 (2026-10-03) — maquette `#tcf-plan`
 *
 * `PageHead` (pastilles « Niveau actuel » / « Objectif »), puis `Split` :
 * colonne principale (carte Cycle, « À faire maintenant », jalon,
 * « Priorités actuelles ») et colonne latérale (bandeau « Ma progression »,
 * accès). Sous 1 180 px les deux colonnes s'empilent. ⚠️ **Le `GoalStrip`
 * « départ → objectif » est retiré** : les pastilles de l'en-tête disent la
 * même chose, sur l'autorité d'affichage du niveau (`estimatedTcfLevel`, celle
 * de l'Accueil) — le palier de départ du cycle (`startingLevel`) en aurait été
 * une seconde lecture, différente, au même endroit.
 */

/* ------------------------------------------------------------------ racine */

export function LearningPlanView({diagnosticHref}: {diagnosticHref: string | null}) {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  /* 🛑 Le parcours est chargé **en parallèle** du Plan, jamais après : les deux
     alimentent le même écran, et les enchaîner ferait clignoter la carte
     « À faire maintenant » entre deux autorités. Son échec est **silencieux** —
     un backend antérieur à l'endpoint ne doit pas casser le Plan, qui garde sa
     règle tant que le parcours n'a rien à dire. */
  const [journey, setJourney] = useState<JourneyDto | null>(null);
  /** La lecture du parcours a abouti ou échoué : `PLAN_OPENED` l'attend pour
   *  porter son `journeyId`, sans jamais attendre indéfiniment. */
  const [journeyRead, setJourneyRead] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const trafficSource = useTrafficSource();
  const relecture = usePlanRelecture();

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
    ).finally(() => {
      if (!cancelled) setJourneyRead(true);
    });
    return () => { cancelled = true; };
    /* 🛑 `relecture` : « Actualiser mon plan » se clique ICI — sans ce
       signal, la purge du cache ne faisait relire personne. */
  }, [authStatus, user, relecture]);

  // Étape 5 du tunnel « Suivi » : le Plan affiché, avec son `journeyId`. La
  // run fondatrice se résout serveur depuis le parcours (Q8), jamais ici.
  const planShown = plan !== null;
  const journeyId = journey?.journeyId ?? null;
  useEffect(() => {
    if (!planShown || !journeyRead) return;
    track("PLAN_OPENED", {}, {once: true, context: {journeyId}});
  }, [planShown, journeyRead, journeyId]);

  if (authStatus === "loading" || (Boolean(user) && loading)) {
    return <TcfPlanSquelette cible={user?.targetLevel ?? null} />;
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

  /* 🛑 **Aucune invitation au diagnostic complet ici** (arbitrage du
     propriétaire, 2026-09-19) : la carte « Diagnostic complet en cours » a été
     supprimée du Plan, puis de l'Accueil le même jour — `affinerPlan` et
     `AffinerPlanCard` avec elle ; le parcours complet lui-même est retiré des
     fronts depuis le 2026-09-26. Les épreuves non mesurées se mesurent par
     l'examen blanc que propose le cycle. Ne pas la réintroduire.

     🛑 **Le Plan existe pour tout compte** (D-69, 2026-09-28) : plus de porte
     « diagnostic obligatoire ». 🛑 **Et la carte « Affinez votre plan avec le
     diagnostic » n'est PAS sur le Plan** (2026-09-28) : elle ne vit que sur
     l'Accueil. Ici, « À faire maintenant », le jalon éventuel et le cycle. */
  return (
    <TcfPlan
      plan={plan}
      journey={journey}
      diagnosticHref={diagnosticHref}
      free={!canAccessModule(user, "TCF")}
      cible={user.targetLevel ?? null}
    />
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
      <Pad>
        <PageHead kicker={MODULE_TCF_KICKER} title={PLAN_TCF_TITLE} />
      </Pad>
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

/** Le chargement : l'en-tête tout de suite, chaque bloc à ses dimensions. */
function TcfPlanSquelette({cible}: {cible: TargetLevel | null}) {
  return (
    <>
      <Pad>
        <PageHead kicker={MODULE_TCF_KICKER} title={PLAN_TCF_TITLE} subtitle={planTcfSubtitle(cible)} />
      </Pad>
      <Split
        main={
          <Pad className={sejourStyles.pageBody}>
            <Stack>
              <BlockSkeleton height={154} />
              <BlockSkeleton height={96} />
              <BlockSkeleton height={280} />
            </Stack>
          </Pad>
        }
        side={
          <Pad className={sejourStyles.pageBody}>
            <BlockSkeleton height={220} radius={30} />
          </Pad>
        }
      />
    </>
  );
}

/* ------------------------------------------------------------- l'écran */

/**
 * **Le Plan TCF, abonné comme gratuit** — Navigation v2 (maquette `#tcf-plan`).
 *
 * En-tête (niveau actuel servi, objectif `AuthenticatedUser.targetLevel` — X13),
 * puis `Split` : à gauche la carte Cycle, « À faire maintenant », le jalon et
 * « Priorités actuelles » (le cycle par blocs), le jalon d'examen mérité ; à
 * droite le bandeau « Ma progression » et les accès « Mes cycles » / « Mon
 * diagnostic ». « Conseil du plan » de la maquette est **masqué** : rien ne
 * le sert.
 *
 * 🛑 **`free` ne retire que des GESTES** (contradiction #1) : un compte sans
 * accès lit exactement le même plan, cadenas compris, et la barre « Débloquer
 * mon plan » reste la seule action dominante de l'écran.
 */
function TcfPlan({plan, journey, diagnosticHref, free, cible}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
  /** « Mon diagnostic » : le rapport du diagnostic clos (`diagnosticTcfHref`),
   *  `null` ⇒ ligne masquée. */
  diagnosticHref: string | null;
  free: boolean;
  cible: TargetLevel | null;
}) {
  /* La lecture de l'en-tête est celle, EN CACHE, de l'Accueil et de la barre
     latérale : aucun appel propre à cet écran. */
  const summary = useCachedData<DashboardSummaryResponse>("plan:dashboard", () => dashboardApi.summaryCached());
  const objective = plan.cycle.objectiveLevel;

  /* `null` = inconnu ⇒ « — » ; pendant la lecture, la pastille attend. */
  const niveau = summary.data?.estimatedTcfLevel ?? null;
  const chipActuel = summary.data !== undefined || summary.error !== null
    ? planTcfChipActuel(niveau ? niveauCecrlShort(niveau) : null)
    : null;

  return (
    <>
      <Pad>
        <PageHead
          kicker={MODULE_TCF_KICKER}
          title={PLAN_TCF_TITLE}
          subtitle={planTcfSubtitle(cible)}
          aside={
            <>
              {chipActuel && <Badge>{chipActuel}</Badge>}
              {cible && <Badge tone="success">{planTcfChipObjectif(cible)}</Badge>}
            </>
          }
        />
        {/* 🛑 Sans démarche déclarée, aucun objectif n'est deviné : le lien
            propose de le fixer (le Plan ne l'exige pas). */}
        {!cible && (
          <Link className={sejourStyles.link} href={journeyTargetPathHref(planHref("TCF"))}>
            <Target size={15} aria-hidden /> Choisir ma démarche pour fixer mon objectif
            <ChevronRight size={15} aria-hidden />
          </Link>
        )}
      </Pad>

      <Split
        main={
          <>
            {/* 🛑 **Le cycle reste ENTIER, même sans accès** : ses blocs et
                toutes leurs étapes sont affichés à leur place, avec leur
                cadenas — c'est la contradiction #1 du dépôt, tranchée le
                2026-08-21. Ordre (parité mobile, 2026-10-03) : « À faire
                maintenant » → jalon → carte Cycle → « Priorités actuelles ». */}
            <PlanCycleSection
              journey={journey}
              plan={plan}
              avantPriorites={
                <>
                  <ActionMaintenant plan={plan} journey={journey} />
                  {/* 🛑 **Le jalon d'examen complet** (D-68) : servi, jamais
                      décidé ici. Il ne porte aucun verrou : le cycle d'examens
                      qu'il ouvre porte les verrous d'accès servis. */}
                  <ExamenCompletJalon journey={journey} module="TCF" />
                </>
              }
            />

          </>
        }
        side={
          <>
            {/* ✅ **Visible aussi sans accès** (demande du propriétaire,
                2026-09-20) : ce sont deux **constats**, rien ne s'y travaille. */}
            <AllerPlusLoin diagnosticHref={diagnosticHref} />
          </>
        }
      />

      {!free && (
        <p className={sejourStyles.footNote}>
          Estimation d&apos;entraînement SejourFR, non officielle : elle situe votre travail,
          elle ne remplace pas le résultat du TCF.
        </p>
      )}

      {free && (
        <PlanPaywall
          module="TCF"
          cta={objective ? `Débloquer mon plan ${objective}` : "Débloquer mon plan"}
        />
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
function ActionMaintenant({plan, journey}: {
  plan: LearningPlanDto;
  journey: JourneyDto | null;
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
  const vue = planNowCard(plan, {journey});
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

     🛑 **Le geste suit le verrou SERVI** (2026-10-04) : le serveur ferme toute
     étape d'entraînement d'un compte sans accès, donc aucun entraînement ne
     part d'ici sans abonnement ; l'examen blanc n°1, offert (D-69), se lance
     comme depuis la ligne du cycle. La garantie n'est pas dans cet écran. */
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
          {vue.note && <p className={sejourStyles.tiny}>{vue.note}</p>}
          {/* 🛑 **Le bouton dit ce que le geste FAIT**, et son libellé vient
              lui aussi de `planNowCard` : `PLAN_NOW_CTA_LOCKED` sur un verrou
              (son motif est écrit à sa déclaration), l'action sinon. À la
              couleur du module (navigation v2, TCF bleu). */}
          {debloquer && (
            <Cta variant="tcf" onClick={() => router.push(planUnlockHref("TCF"))}>
              {vue.cta}
            </Cta>
          )}
          {/* 🛑 **Aucun bouton sur une étape dont l'action ne se résout pas.**
              Il ne lançait rien, et la version d'avant lançait pire : la
              compétence que le Plan priorisait ce jour-là, pendant que la carte
              en annonçait une autre. */}
          {vue.geste === "LANCER" && (
            <Cta variant="tcf" onClick={startNext} disabled={busy}>
              {busy ? PLAN_STARTING : vue.cta}
            </Cta>
          )}
          {/* 🛑 **`OUVRIR_ETAPE` ouvre l'écran de l'étape**, il ne lance rien :
              une compétence de compréhension et une unité civique se
              travaillent par séries, et le candidat les choisit là-bas. La
              destination est **servie** par `planNowCard` — cet écran ne
              recompose aucune adresse. */}
          {vue.geste === "OUVRIR_ETAPE" && vue.etapeHref && (
            <Cta variant="tcf" href={vue.etapeHref}>{vue.cta}</Cta>
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
        journeyId={journey?.journeyId}
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
function AllerPlusLoin({diagnosticHref}: {diagnosticHref: string | null}) {
  /* 🛑 Le RAPPORT du diagnostic clos, jamais `/diagnostic` : celle-ci lit la
     session COURANTE, qui peut être un rapide commencé après coup — le lien
     invitait alors à reprendre au lieu de relire. */
  return <PlanLinks module="TCF" diagnosticHref={diagnosticHref}/>;
}
