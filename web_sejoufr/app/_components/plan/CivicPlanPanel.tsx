"use client";

import {Landmark, ListChecks, RotateCcw} from "lucide-react";
import {useEffect, useMemo, useState} from "react";
import {useRouter} from "next/navigation";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {useMockExamLauncher} from "@/app/_components/hub/MockExamLauncher";
import {planUnlockHref} from "@/lib/plan-unlock";
import {useCivicSerie} from "./useCivicSerie";
import {civicDiagnosticApi, civicPlanApi, dashboardApi, journeyApi} from "@/lib/api";
import {track} from "@/lib/analytics";
import {usePlanRelecture} from "@/lib/use-plan-relecture";
import {useAuth} from "@/lib/auth-context";
import {
  CIVIC_PLAN_LOCKED_CTA,
  CIVIC_PLAN_LOCKED_NOTE,
  CIVIC_PLAN_NOW_TITLE,
  CIVIC_PLAN_REVIEW_TITLE,
  CIVIC_PLAN_WORK_CTA,
  civicCibleGeste,
  civicNowCard,
  civicPlanGrainNote,
  civicRevueLabel,
} from "@/lib/civic-plan";
import {
  canAccessModule,
  CIVIC_MAITRISE_LABEL,
  type CivicDiagnosticDto,
  type CivicPlanDto,
  type DashboardSummaryResponse,
  type JourneyDto,
} from "@/lib/types";
import {
  Badge,
  BlockError,
  BlockSkeleton,
  Cta,
  GoalStrip,
  Hero,
  InfoCard,
  NowCard,
  Pad,
  PageHead,
  Section,
  Stack,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {IconTarget} from "@/app/_components/shell/ShellIcons";
import {ACCUEIL_BLOCK_ERROR, ACCUEIL_RETRY, accueilPourcentage} from "@/lib/accueil";
import {
  MODULE_CIVIQUE_KICKER,
  MODULE_VOIR_DETAIL,
  PLAN_CIVIQUE_BADGE_SEUIL,
  PLAN_CIVIQUE_HERO_LABEL,
  PLAN_CIVIQUE_HERO_STAT,
  PLAN_CIVIQUE_HERO_SUB,
  PLAN_CIVIQUE_SUBTITLE,
  PLAN_CIVIQUE_TITLE,
  seriesTermineesTitre,
} from "@/lib/module-ecrans";
import {progressionHref} from "@/lib/progression";
import {avancementSeriesCivique} from "@/lib/reviser";
import {type CachedData, useCachedData} from "@/lib/use-cached-data";
import {PlanCycleSection} from "./PlanCycleSection";
import {ExamenCompletJalon} from "./ExamenCompletJalon";
import {useCivicUniteSerie} from "./use-civic-unite-serie";
import {PlanLinks} from "./PlanLinks";
import {CIVIC_DIAGNOSTIC_HUB_HREF, civicDiagnosticHref} from "@/lib/civic-diagnostic";
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "@/lib/civique-examen";
import {PlanPaywall} from "./PlanPaywallCard";

/**
 * **Le plan civique** (L10) — refonte du 2026-09-11 sur le kit `sejour/`.
 *
 * 🛑 **Rien n'est dérivé ici.** L'ordre des cibles, leur état de maîtrise, leur
 * échéance et leur verrou arrivent **servis**. Ce panneau les met en mots
 * (`lib/civic-plan.ts`) et ouvre ce qui existe déjà — la série ciblée.
 *
 * 🛑 **La boîte Leitner ne s'affiche JAMAIS** au candidat : on montre
 * `maitrise` et `prochaineRevue`.
 *
 * 🛑 **Le constat est intégralement gratuit.** `locked` porte sur la **série**,
 * jamais sur ce que le candidat a mesuré.
 *
 * ## ⚠️ UNE SEULE ANATOMIE, ABONNÉ COMME GRATUIT (2026-09-20)
 *
 * **Demande du propriétaire, verbatim** : « pour la partie Examen civique du
 * plan, pour un non abonné, il faut aussi la même chose qu'un abonné, sauf
 * qu'il peut pas travailler dessus. comme ce qu'on fait actuellement sur le
 * TCF. il voit le plan, mais il peut pas travailler dessus, il doit débloquer
 * son plan. »
 *
 * ⚠️ **Ceci RÉVOQUE A89** (« ce que D-50 arbitre, c'est le Plan civique
 * *abonné* ; l'écran gratuit garde ses sections ») et, avec elle, l'anatomie
 * gratuite : la carte de score du diagnostic, « Thèmes à travailler »,
 * « Vos priorités » et « Votre première étape est prête » sont **supprimées**.
 * C'est la transposition exacte de la passe TCF du même jour (A114).
 *
 * L'ordre est donc le même pour les deux — Navigation v2 (2026-10-03,
 * maquette `#civique-plan`) : `PageHead` → **bandeau rouge** du % de séries
 * (X8-A) → bande objectif → « À faire maintenant » (`Grid` : `NowCard` de
 * l'étape courante + `InfoCard` « Examen blanc civique ») → jalon → le **cycle** →
 * « À revoir bientôt ». Seul le pied change — l'offre pour un compte sans
 * accès.
 *
 * ⚠️ **Les boutons de la carte d'action sont ROUGES** (token du module civique,
 * arbitrage Navigation v2 — révoque DEC-06/A46 pour ce Plan, des deux côtés) :
 * sur un compte sans accès, le geste de la carte EST « Débloquer », donc un
 * seul geste dominant tient. La carte « Examen blanc civique » est une
 * `InfoCard` cliquable, sans bouton.
 *
 * 🛑 **Ce qui TIENT** : « dans le plan, on ne travaille rien si on n'est pas
 * abonné » (D-33, que `CivicPlanService` oppose déjà en **403**). La garantie
 * n'est pas dans cet écran — `civicNowCard` / `civicCibleGeste` rendent
 * `geste === "DEBLOQUER"` dès que `free`, et les lanceurs ne sont attachés
 * qu'à la branche `LANCER`.
 *
 * 🛑 **La contradiction #1 reste fermée** : le nom de l'étape, l'état de
 * maîtrise, les compteurs et les échéances sont des **résultats mesurés** — ils
 * restent lisibles. On floute l'**action**, jamais le **résultat**.
 *
 * 🛑 **Le Plan civique s'affiche pour tout compte** (D-69, 2026-09-28) :
 * `CivicPlanDto.disponible` garde son sens (« plan DÉRIVÉ du diagnostic
 * civique disponible ») mais ne ferme plus l'écran. Sans diagnostic civique, le
 * cycle et « À faire maintenant » se lisent sur le parcours, les listes du plan
 * dérivé sont vides. 🛑 La carte « Affinez votre plan avec le diagnostic »
 * n'est PAS sur le Plan (2026-09-28) : elle ne vit que sur l'Accueil.
 */
export function CivicPlanPanel({diagnosticFait}: {diagnosticFait: boolean}) {
  const {user} = useAuth();
  const [plan, setPlan] = useState<CivicPlanDto | null>(null);
  /* 🛑 **Le CYCLE civique** (D-50) : c'est lui qui porte « À faire maintenant »
     et les blocs. `null` est un cas normal — pas encore lu. */
  const [journey, setJourney] = useState<JourneyDto | null>(null);
  const [journeyRead, setJourneyRead] = useState(false);
  const relecture = usePlanRelecture();

  useEffect(() => {
    let vivant = true;
    civicPlanApi.getCached().then(
      (p) => { if (vivant) setPlan(p); },
      () => { /* best-effort : jamais une erreur technique à la place d'un plan */ },
    );
    journeyApi.getCached("CIVIQUE").then(
      (j) => { if (vivant) setJourney(j); },
      () => { /* idem : le cycle absent fait disparaître sa section, pas l'écran */ },
    ).finally(() => {
      if (vivant) setJourneyRead(true);
    });
    return () => { vivant = false; };
    /* 🛑 `relecture` : « Actualiser mon plan » se clique ICI — sans ce
       signal, la purge du cache ne faisait relire personne. */
  }, [relecture]);

  // Étape 5 du tunnel « Suivi » : le Plan civique affiché, avec son
  // `journeyId`. Miroir de `LearningPlanView`.
  const planShown = plan !== null;
  const journeyId = journey?.journeyId ?? null;
  useEffect(() => {
    if (!planShown || !journeyRead) return;
    track("PLAN_OPENED", {}, {once: true, context: {journeyId}});
  }, [planShown, journeyRead, journeyId]);

  /* L'en-tête ne se fait jamais attendre : il est rendu dès le premier
     passage, avant le plan, avec un squelette par bloc. */
  if (!plan) {
    return (
      <>
        <CiviqueHead />
        <Pad className={sejourStyles.pageBody}>
          <Stack>
            <BlockSkeleton height={220} radius={30} />
            <BlockSkeleton height={154} />
            <BlockSkeleton height={280} />
          </Stack>
        </Pad>
      </>
    );
  }

  return (
    <CiviquePlan
      plan={plan}
      journey={journey}
      free={!canAccessModule(user, "CIVIQUE")}
      diagnosticFait={diagnosticFait}
    />
  );
}

/** L'en-tête de la maquette `#civique-plan` : kicker rouge, titre, seuil de l'arrêté. */
function CiviqueHead() {
  return (
    <Pad>
      <PageHead
        tone="civique"
        kicker={MODULE_CIVIQUE_KICKER}
        title={PLAN_CIVIQUE_TITLE}
        subtitle={PLAN_CIVIQUE_SUBTITLE}
        aside={<Badge module="civique">{PLAN_CIVIQUE_BADGE_SEUIL}</Badge>}
      />
    </Pad>
  );
}

/* ------------------------------------------------------------- l'écran */

function CiviquePlan({plan, journey, free, diagnosticFait}: {
  plan: CivicPlanDto;
  journey: JourneyDto | null;
  free: boolean;
  diagnosticFait: boolean;
}) {
  /* 🛑 **Depuis le Plan, TOUT chemin vers le paywall passe par l'écran de
     transition** (demande du propriétaire, 2026-09-20, TCF **et** civique) : il
     dit au candidat ce qu'il achète — ses priorités, son écart à l'objectif, le
     prix d'entrée — avant de lui montrer des durées et des montants. ⚠️ Les
     paywalls qui répondent à un **403** restent en place : ce sont des refus,
     pas des gestes d'achat. */
  const router = useRouter();
  const maintenant = useMemo(() => new Date(), []);
  /* Les deux lanceurs, **un par grain** (A87) : l'unité officielle du cycle et
     la cible du plan dérivé. Ils sont partagés avec l'écran Réviser — la même
     unité ne peut pas s'ouvrir de deux façons selon l'écran. */
  /* 🛑 **Un `locked` SERVI passe par l'écran de transition**, comme tous les
     autres gestes d'achat du Plan : sans cette porte, une cible fermée
     ouvrait le paywall d'un coup. Le 403 du lanceur, lui, reste un refus. */
  const serieCible = useCivicSerie(() => router.push(planUnlockHref("CIVIQUE")));
  const serieUnite = useCivicUniteSerie();
  /* L'examen de thème de l'étape courante : le lanceur partagé avec la ligne
     du cycle. Son 403 ouvre la même offre que les séries. */
  const launchExam = useMockExamLauncher();
  const [examPaywall, setExamPaywall] = useState(false);

  /* La lecture du bandeau est celle, EN CACHE, de
     l'Accueil, de la barre latérale et de l'écran Progression civique. */
  const summary = useCachedData<DashboardSummaryResponse>("plan:dashboard", () => dashboardApi.summaryCached());

  const carte = civicNowCard(plan, {journey, free, lancerExamen: true});
  const grainNote = civicPlanGrainNote(plan.grain);
  const erreur = serieCible.erreur ?? serieUnite.erreur;

  return (
    <>
      <CiviqueHead />

      {/* **Hero rouge (X8-A)** : le pourcentage UNIQUE du parcours en séries
          (`avancementSeriesCivique`), la même valeur que l'Accueil, la barre
          latérale et l'écran Progression civique. Le cycle reste lisible dans
          sa carte et ses blocs, plus bas. */}
      <Pad className={sejourStyles.pageBody}>
        <AvancementHero summary={summary} />
      </Pad>

      {/* 🛑 LA BANDE OBJECTIF (D-50 §1) : la démarche visée et le seuil, deux
          FAITS du référentiel. ⛔ **Jamais un score d'entrée** — il se lirait
          comme un niveau acquis alors que c'est un résultat d'examen blanc. */}
      {journey?.objectif && (
        <Pad className={sejourStyles.pageBody}>
          <GoalStrip
            currentLabel="Objectif"
            current={journey.objectif.label}
            goalLabel="Seuil de réussite"
            goal={`${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`}
          />
        </Pad>
      )}

      {/* 🛑 « À FAIRE MAINTENANT » VIENT DU CYCLE (D-50 §2), avec repli sur le
          plan dérivé. Le contenu est identique pour les deux accès ; seul le
          geste change. */}
      <Section title={CIVIC_PLAN_NOW_TITLE}>
        <Pad>
          {carte && (
              <div>
                <NowCard
                  module="civique"
                  icon={Landmark}
                  title={carte.title}
                  subtitle={carte.subtitle ?? undefined}
                  badge={carte.badge ?? undefined}
                  objectiveLabel={carte.objectiveLabel ?? undefined}
                  objective={carte.objective ?? undefined}
                  meta={carte.meta ? [{icon: ListChecks, label: carte.meta}] : undefined}
                >
                  {/* 🛑 **Le geste vient de `civicNowCard`, il ne se redéduit pas
                      ici.** `AUCUN` ⇒ aucun bouton (garde-fou du 2026-09-17) ;
                      `DEBLOQUER` ⇒ l'offre, jamais un lanceur. En **rouge**
                      (token du module, Navigation v2 — révoque DEC-06/A46 pour
                      ce Plan) : sur un compte gratuit le geste de cette carte
                      EST « Débloquer », donc un seul geste dominant tient. */}
                  {carte.geste === "DEBLOQUER" && (
                    <Cta variant="civique" onClick={() => router.push(planUnlockHref("CIVIQUE"))}>{carte.cta}</Cta>
                  )}
                  {/* 🛑 **L'étape d'examen lance l'examen de thème SERVI**
                      (`carte.examen`) — le même lanceur que la ligne du cycle. */}
                  {carte.geste === "LANCER" && carte.examen && (
                    <Cta
                      variant="civique"
                      onClick={() => launchExam({
                        kind: "CIVIQUE",
                        ...carte.examen!,
                        onPaywall: () => setExamPaywall(true),
                      })}
                    >
                      {carte.cta}
                    </Cta>
                  )}
                  {carte.geste === "LANCER" && carte.source && (
                    <Cta
                      variant="civique"
                      disabled={enCoursSur(carte.source, serieCible.enCours, serieUnite.enCours)}
                      onClick={() => lancer(carte.source!, serieCible, serieUnite)}
                    >
                      {carte.cta}
                    </Cta>
                  )}
                  {/* 🛑 **« Travailler » ouvre l'écran de l'étape** quand l'unité se
                      travaille par séries — le même écran que la ligne du cycle, et
                      la même autorité (`civicNowCard`) qui le décide. */}
                  {carte.geste === "OUVRIR_ETAPE" && carte.etapeHref && (
                    <Cta variant="civique" href={carte.etapeHref}>{carte.cta}</Cta>
                  )}
                </NowCard>
                {carte.geste === "DEBLOQUER" && (
                  <p className={sejourStyles.tiny}>{CIVIC_PLAN_LOCKED_NOTE}</p>
                )}
              </div>
            )}
          {erreur && <p className={sejourStyles.tiny} role="alert">{erreur}</p>}
        </Pad>
      </Section>

      {/* 🛑 **Le jalon d'examen complet** (D-68), sous « À faire maintenant » :
          servi, jamais décidé ici. En civique, le cycle d'examens porte un
          examen par thématique. */}
      <ExamenCompletJalon journey={journey} module="CIVIQUE" />

      {/* Le cycle en blocs — la MÊME section que le TCF, module en paramètre.
          🛑 **Il reste ENTIER sans accès** : ses blocs et toutes leurs étapes
          sont affichés à leur place, avec leur cadenas et le geste d'offre que
          `PlanCycleSection` attache à une étape `locked`. */}
      <PlanCycleSection journey={journey} plan={null} module="CIVIQUE" />

      {/* 🛑 Secondaire, et JAMAIS présenté comme une alerte : ce sont des points
          acquis qu'on entretient. La **boîte** Leitner ne s'affiche pas — on
          montre l'état de maîtrise et l'échéance, tous deux servis. */}
      {plan.aRevoirVisibles.length > 0 && (
        <Section title={CIVIC_PLAN_REVIEW_TITLE}>
          <Pad>
            <Stack>
              {plan.aRevoirVisibles.map((cible) => {
                const geste = civicCibleGeste(cible, {free});
                const revue = civicRevueLabel(cible, maintenant);
                return (
                  <InfoCard
                    key={cible.id}
                    module="civique"
                    icon={<RotateCcw />}
                    title={cible.label}
                    meta={[CIVIC_MAITRISE_LABEL[cible.maitrise], revue].filter(Boolean).join(" · ")}
                    trailing={
                      <Badge module="civique">
                        {geste === "DEBLOQUER" ? CIVIC_PLAN_LOCKED_CTA : CIVIC_PLAN_WORK_CTA}
                      </Badge>
                    }
                    onClick={serieCible.enCours === cible.id
                      ? null
                      : () => {
                        if (geste === "DEBLOQUER") router.push(planUnlockHref("CIVIQUE"));
                        else void serieCible.commencer(cible);
                      }}
                  />
                );
              })}
              {/* 🛑 **Le plan DIT à quel grain il travaille** (`20_` §3.3), et
                  il le dit **ici** : c'est la dernière surface qui montre des
                  cibles du plan dérivé. */}
              {grainNote && <p className={sejourStyles.tiny}>{grainNote}</p>}
            </Stack>
          </Pad>
        </Section>
      )}

      {free && <PlanPaywall module="CIVIQUE" cta="Débloquer mon plan" />}
      <AllerPlusLoin diagnosticFait={diagnosticFait} />

      {/* ⚠️ **Ce paywall ne répond plus qu'à un 403** : depuis que tout geste
          d'achat du Plan passe par l'écran de transition, plus rien ici ne
          l'ouvre délibérément. Il reste parce qu'un lanceur peut toujours se
          voir refuser au démarrage — c'est un refus, pas une vente. */}
      {/* Un 403 d'une série lancée depuis le Plan civique : c'est le CTA du Plan
          (contrôle F), avec le parcours servi. */}
      <PaywallSheet
        ctaLocation="LOCKED_PLAN"
        screen="plan_civique"
        journeyId={journey?.journeyId ?? null}
        open={serieCible.paywall || serieUnite.paywall || examPaywall}
        module="CIVIQUE"
        onClose={() => {
          serieCible.setPaywall(false);
          serieUnite.setPaywall(false);
          setExamPaywall(false);
        }}
      />
    </>
  );
}

/* ------------------------------------------------ les blocs de la maquette */

/**
 * **Le bandeau rouge « Progression globale »** : `{terminées} séries
 * terminées`, `{pct} %` « du parcours », barre = pct — la fonction UNIQUE
 * `avancementSeriesCivique` sur les thèmes servis par `/api/me/dashboard`.
 * 0 série ⇒ « 0 % », jamais vide.
 */
function AvancementHero({summary}: {summary: CachedData<DashboardSummaryResponse>}) {
  if (summary.loading) return <BlockSkeleton height={220} radius={30} />;
  if (summary.error !== null || !summary.data) {
    return <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={summary.reload} />;
  }
  const avancement = avancementSeriesCivique(summary.data.civique);
  return (
    <Hero
      module="civique"
      icon={<IconTarget />}
      label={PLAN_CIVIQUE_HERO_LABEL}
      title={seriesTermineesTitre(avancement.terminees)}
      sub={PLAN_CIVIQUE_HERO_SUB}
      stat={{value: accueilPourcentage(avancement.pourcentage), label: PLAN_CIVIQUE_HERO_STAT}}
      progress={avancement.pourcentage / 100}
      cta={{label: MODULE_VOIR_DETAIL, href: progressionHref("CIVIQUE")}}
    />
  );
}

/* ------------------------------------------------- les deux lanceurs */

type Serie = ReturnType<typeof useCivicSerie>;
type SerieUnite = ReturnType<typeof useCivicUniteSerie>;

/** Le témoin d'attente du lanceur **de ce grain-là**. */
function enCoursSur(
  source: NonNullable<ReturnType<typeof civicNowCard>>["source"],
  cible: string | null,
  unite: string | null,
): boolean {
  if (!source) return false;
  return source.kind === "UNITE" ? unite === source.code : cible === source.cible.id;
}

/**
 * 🛑 **Un lanceur par GRAIN** (A87) : l'unité officielle du cycle et la cible du
 * plan dérivé sont deux routes serveur distinctes. Un aiguillage à l'intérieur
 * d'un lanceur unique aurait mis les deux règles au même endroit.
 */
function lancer(
  source: NonNullable<NonNullable<ReturnType<typeof civicNowCard>>["source"]>,
  cible: Serie,
  unite: SerieUnite,
): void {
  if (source.kind === "UNITE") {
    void unite.start(source.code);
    return;
  }
  cible.commencer(source.cible);
}

/**
 * **L'accès à « Mes cycles »**, au bas du Plan civique.
 *
 * 🛑 **Le MÊME point d'entrée que le TCF** (`AllerPlusLoin` de
 * `LearningPlanView`) : même section, même carte, même libellé, même écran
 * d'arrivée — seul le `?module=` change.
 *
 * 🛑 **« Mon diagnostic » n'apparaît que si le diagnostic civique est clos**
 * (`diagnosticFait`, 2026-09-28) — sinon la ligne est masquée et la session
 * n'est même pas lue.
 *
 * ⚠️ **Absente sur un compte sans accès**, comme sur le Plan TCF gratuit : la
 * seule action dominante de cet écran-là est « Débloquer mon plan ».
 */
function AllerPlusLoin({diagnosticFait}: {diagnosticFait: boolean}) {
  /* 🛑 **Le rapport directement**, quand il y a un rapport à lire : la session
     est lue au CLIC, pas au montage — un lien que la plupart des candidats ne
     touchent pas ne coûte alors aucun appel, et sans session on retombe sur le
     hub, le comportement d'avant. La règle de destination vit une seule fois
     (`civicDiagnosticHref`), elle n'est pas rejouée ici. */
  const [href, setHref] = useState(CIVIC_DIAGNOSTIC_HUB_HREF);
  useEffect(() => {
    if (!diagnosticFait) return;
    let annule = false;
    civicDiagnosticApi.current().then(
      (session: CivicDiagnosticDto | null) => {
        if (!annule) setHref(civicDiagnosticHref(session));
      },
      () => { /* le hub reste la destination : on ne bloque jamais l'accès */ },
    );
    return () => { annule = true; };
  }, [diagnosticFait]);

  return <PlanLinks module="CIVIQUE" diagnosticHref={diagnosticFait ? href : null}/>;
}
