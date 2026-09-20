"use client";

import Link from "next/link";
import {ChevronRight, Landmark, ListChecks} from "lucide-react";
import {useEffect, useMemo, useState} from "react";
import {useRouter} from "next/navigation";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {planUnlockHref} from "@/lib/plan-unlock";
import {useCivicSerie} from "./useCivicSerie";
import {civicDiagnosticApi, civicPlanApi, journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  CIVIC_PLAN_LOCKED_CTA,
  CIVIC_PLAN_LOCKED_NOTE,
  CIVIC_PLAN_NOW_TITLE,
  CIVIC_PLAN_REVIEW_TITLE,
  CIVIC_PLAN_SCREEN_TITLE,
  CIVIC_PLAN_TOP_KICKER,
  CIVIC_PLAN_TOP_KICKER_FREE,
  CIVIC_PLAN_WORK_CTA,
  civicCibleGeste,
  civicNowCard,
  civicPlanGrainNote,
  civicRevueLabel,
} from "@/lib/civic-plan";
import {planIndisponibleDepuisEtat} from "@/lib/preparation";
import {
  canAccessModule,
  CIVIC_MAITRISE_LABEL,
  type CivicDiagnosticDto,
  type CivicPlanDto,
  type JourneyDto,
} from "@/lib/types";
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
import {PlanGate} from "./PlanGate";
import {PlanCycleSection} from "./PlanCycleSection";
import {useCivicUniteSerie} from "./use-civic-unite-serie";
import {JOURNEY_HISTORY_TITLE, journeyHistoryHref} from "@/lib/journey";
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
 * L'ordre est donc le même pour les deux : `Top` → bande objectif →
 * « À faire maintenant » → le **cycle** → « À revoir bientôt ». Seul le pied
 * change — l'offre pour un compte sans accès, « Aller plus loin » pour un
 * abonné.
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
 */
export function CivicPlanPanel() {
  const {user} = useAuth();
  const [plan, setPlan] = useState<CivicPlanDto | null>(null);
  /* 🛑 **Le CYCLE civique** (D-50) : c'est lui qui porte « À faire maintenant »
     et les blocs. `null` est un cas normal — pas encore lu. */
  const [journey, setJourney] = useState<JourneyDto | null>(null);

  useEffect(() => {
    let vivant = true;
    civicPlanApi.getCached().then(
      (p) => { if (vivant) setPlan(p); },
      () => { /* best-effort : jamais une erreur technique à la place d'un plan */ },
    );
    journeyApi.getCached("CIVIQUE").then(
      (j) => { if (vivant) setJourney(j); },
      () => { /* idem : le cycle absent fait disparaître sa section, pas l'écran */ },
    );
    return () => { vivant = false; };
  }, []);

  /* 🛑 **La bascule de parcours ne se fait jamais attendre.** C'est l'en-tête
     qui la porte (`TopSlot`), donc on le rend dès le premier passage, avant le
     plan : rendre `null` ici laissait l'écran sans aucune porte vers le TCF
     tant que `/api/me/civic-plan` n'avait pas répondu. Même état que le
     chargement du plan TCF, qui rend déjà son `Top` seul. */
  if (!plan) {
    return <Top kicker={CIVIC_PLAN_TOP_KICKER} title={CIVIC_PLAN_SCREEN_TITLE} />;
  }

  if (!plan.disponible) {
    return (
      <PlanGate
        kicker={CIVIC_PLAN_TOP_KICKER}
        gate={planIndisponibleDepuisEtat("DIAGNOSTIC_A_FAIRE", "CIVIQUE")}
        icon={Landmark}
      />
    );
  }

  return <CiviquePlan plan={plan} journey={journey} free={!canAccessModule(user, "CIVIQUE")} />;
}

/* ------------------------------------------------------------- l'écran */

function CiviquePlan({plan, journey, free}: {
  plan: CivicPlanDto;
  journey: JourneyDto | null;
  free: boolean;
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

  const carte = civicNowCard(plan, {journey, free});
  const grainNote = civicPlanGrainNote(plan.grain);
  const erreur = serieCible.erreur ?? serieUnite.erreur;

  return (
    <>
      <Top
        kicker={free ? CIVIC_PLAN_TOP_KICKER_FREE : CIVIC_PLAN_TOP_KICKER}
        title={CIVIC_PLAN_SCREEN_TITLE}
      />

      {/* 🛑 LA BANDE OBJECTIF (D-50 §1) : la démarche visée et le seuil, deux
          FAITS du référentiel. ⛔ **Jamais un score d'entrée** — il se lirait
          comme un niveau acquis alors que c'est un résultat d'examen blanc. */}
      {journey?.objectif && (
        <Pad>
          <GoalStrip
            currentLabel="Objectif"
            current={journey.objectif.label}
            goalLabel="Seuil de réussite"
            goal={`${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`}
          />
        </Pad>
      )}

      {/* 🛑 « À FAIRE MAINTENANT » VIENT DU CYCLE (D-50 §2), avec repli sur le
          plan dérivé — la même forme que `planNowCard`. Le contenu est
          identique pour les deux accès ; seul le geste change. */}
      {carte && (
        <Section title={CIVIC_PLAN_NOW_TITLE}>
          <Pad>
            <NowCard
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
                  `DEBLOQUER` ⇒ l'offre, jamais un lanceur. En **bleu** : le
                  seul bouton rouge de l'écran reste « Débloquer mon plan »,
                  ancré en pied (A46). */}
              {carte.geste === "DEBLOQUER" && (
                <Cta variant="blue" onClick={() => router.push(planUnlockHref("CIVIQUE"))}>{carte.cta}</Cta>
              )}
              {carte.geste === "LANCER" && carte.source && (
                <Cta
                  variant="blue"
                  disabled={enCoursSur(carte.source, serieCible.enCours, serieUnite.enCours)}
                  onClick={() => lancer(carte.source!, serieCible, serieUnite)}
                >
                  {carte.cta}
                </Cta>
              )}
            </NowCard>
            {carte.geste === "DEBLOQUER" && (
              <p className={sejourStyles.tiny}>{CIVIC_PLAN_LOCKED_NOTE}</p>
            )}
          </Pad>
        </Section>
      )}

      {erreur && (
        <Pad>
          <p className={sejourStyles.tiny} role="alert">{erreur}</p>
        </Pad>
      )}

      {/* Le cycle en blocs — la MÊME section que le TCF, module en paramètre.
          🛑 **Il reste ENTIER sans accès** : ses blocs et toutes leurs étapes
          sont affichés à leur place, avec leur cadenas et le geste d'offre que
          `PlanCycleSection` attache à une étape `locked`. */}
      <PlanCycleSection journey={journey} plan={null} module="CIVIQUE" />

      {/* 🛑 Secondaire, et JAMAIS présenté comme une alerte : ce sont des points
          acquis qu'on entretient. La **boîte** Leitner ne s'affiche pas — on
          montre l'état de maîtrise et l'échéance, tous deux servis. */}
      {plan.aRevoirVisibles.length > 0 && (
        <Section title={CIVIC_PLAN_REVIEW_TITLE} flush>
          <Card variant="soft">
            <p className={sejourStyles.label}>Révision courte</p>
            <Stack>
              {plan.aRevoirVisibles.map((cible) => {
                const geste = civicCibleGeste(cible, {free});
                return (
                  <div key={cible.id}>
                    <b>{cible.label}</b>
                    <p className={sejourStyles.tiny}>
                      {CIVIC_MAITRISE_LABEL[cible.maitrise]}
                      {civicRevueLabel(cible, maintenant)
                        ? ` · ${civicRevueLabel(cible, maintenant)}`
                        : ""}
                    </p>
                    <button
                      type="button"
                      className={sejourStyles.link}
                      disabled={serieCible.enCours === cible.id}
                      onClick={() => {
                        if (geste === "DEBLOQUER") router.push(planUnlockHref("CIVIQUE"));
                        else void serieCible.commencer(cible);
                      }}
                    >
                      {geste === "DEBLOQUER" ? CIVIC_PLAN_LOCKED_CTA : CIVIC_PLAN_WORK_CTA}
                    </button>
                  </div>
                );
              })}
            </Stack>
            {/* 🛑 **Le plan DIT à quel grain il travaille** (`20_` §3.3), et il
                le dit **ici** : c'est la dernière surface qui montre des cibles
                du plan dérivé, donc la seule que cette note qualifie encore.
                Elle vivait sur les deux écrans gratuits (A84) ; les deux
                anatomies ayant fusionné, elle accompagne désormais ce qu'elle
                décrit, abonné compris. */}
            {grainNote && <p className={sejourStyles.tiny}>{grainNote}</p>}
          </Card>
        </Section>
      )}

      {free && <PlanPaywall module="CIVIQUE" cta="Débloquer mon plan" />}
      <AllerPlusLoin />

      {/* ⚠️ **Ce paywall ne répond plus qu'à un 403** : depuis que tout geste
          d'achat du Plan passe par l'écran de transition, plus rien ici ne
          l'ouvre délibérément. Il reste parce qu'un lanceur peut toujours se
          voir refuser au démarrage — c'est un refus, pas une vente. */}
      <PaywallSheet
        open={serieCible.paywall || serieUnite.paywall}
        module="CIVIQUE"
        onClose={() => {
          serieCible.setPaywall(false);
          serieUnite.setPaywall(false);
        }}
      />
    </>
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
 * **L'accès à « Ma progression »**, au bas du Plan civique.
 *
 * 🛑 **Le MÊME point d'entrée que le TCF** (`AllerPlusLoin` de
 * `LearningPlanView`) : même section, même carte, même libellé, même écran
 * d'arrivée — seul le `?module=` change.
 *
 * ⚠️ **Une seule ligne, là où le TCF en a deux.** Sa seconde ligne mène à
 * « Mon diagnostic » ; le civique a bien la sienne (`/diagnostic-civique`),
 * mais l'ajouter serait une entrée de navigation que personne n'a demandée —
 * à rouvrir sur un mot du propriétaire, pas ici.
 *
 * ⚠️ **Absente sur un compte sans accès**, comme sur le Plan TCF gratuit : la
 * seule action dominante de cet écran-là est « Débloquer mon plan ».
 */
function AllerPlusLoin() {
  /* 🛑 **Le rapport directement**, quand il y a un rapport à lire : la session
     est lue au CLIC, pas au montage — un lien que la plupart des candidats ne
     touchent pas ne coûte alors aucun appel, et sans session on retombe sur le
     hub, le comportement d'avant. La règle de destination vit une seule fois
     (`civicDiagnosticHref`), elle n'est pas rejouée ici. */
  const [href, setHref] = useState(CIVIC_DIAGNOSTIC_HUB_HREF);
  useEffect(() => {
    let annule = false;
    civicDiagnosticApi.current().then(
      (session: CivicDiagnosticDto | null) => {
        if (!annule) setHref(civicDiagnosticHref(session));
      },
      () => { /* le hub reste la destination : on ne bloque jamais l'accès */ },
    );
    return () => { annule = true; };
  }, []);

  const rows: Array<{href: string; label: string}> = [
    {href: journeyHistoryHref("CIVIQUE"), label: JOURNEY_HISTORY_TITLE},
    /* 🛑 Le diagnostic **civique** a sa propre porte — le TCF pointe sur
       `/diagnostic`, qui ne raconte rien du civique. */
    {href, label: "Mon diagnostic"},
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
