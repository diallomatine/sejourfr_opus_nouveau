"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {ArrowRight, ClipboardCheck, Landmark, Sparkles, Target} from "lucide-react";
import {AffinerPlanCard} from "@/app/_components/plan/AffinerPlanCard";
import {
    Card,
    Cta,
    GoalBanner,
    LevelLadder,
    LevelList,
    LevelRow,
    MicroNote,
    ModuleToggle,
    NowCard,
    Pad,
    PanelHead,
    JourneyRow,
    PathRow,
    ProgressMini,
    Section,
    SejourApp,
    Stack,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {civicPlanApi, diagnosticApi, journeyApi, learningPlanApi, progressApi, userContentApi} from "@/lib/api";
import {
    journeyBadge,
    journeyKind,
    journeyKitState,
    journeyStepSubtitle,
    journeyStepTitle,
} from "@/lib/journey";
import {civicBarJauge, civicBarTone} from "@/lib/civic-diagnostic";
import {civicPath, civicPathCounter, civicPlanRaison} from "@/lib/civic-plan";
import {
    ACCUEIL_EVALUEES_CAPTION,
    ACCUEIL_EVALUES_CAPTION_CIVIQUE,
    NON_MESURE_LABEL,
    accueilEchelleLabel,
    accueilEchelons,
    accueilEpreuveBadge,
    accueilEpreuveCta,
    accueilEpreuveOuvreLExercice,
    accueilEpreuveStatut,
    accueilEpreuveTon,
    accueilEvaluees,
    accueilEvaluesCivique,
    accueilObjectifLabel,
    progresCiviqueScore,
} from "@/lib/progres";
import {moduleDeLUrl, planHref, type ParcoursModule} from "@/lib/module-switch";
import {
    CIVIQUE_LABEL,
    TCF_LABEL,
    affinerPlan,
    moduleParDefaut,
    objectifLabel,
    planIndisponible,
    type PlanIndisponible,
} from "@/lib/preparation";
import {useAuth} from "@/lib/auth-context";
import {
    planDomainHref,
    planDomainLabel,
    planDomainShort,
    planDomainSlug,
    planNowCard,
    planSectionEpreuve,
    planTaskBadge,
    type PlanPathStep,
} from "@/lib/plan-domain";
import {planNowIcon} from "@/app/_components/plan/PlanBits";
import {usePlanAssessment, usePlanExercise} from "@/app/_components/plan/use-plan-exercise";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
    diagnosticAnalyzingObjective,
    diagnosticCompletedExerciseCount,
    diagnosticCountLabel,
    diagnosticExerciseCount,
    diagnosticStartObjective,
    diagnosticStartSubtitle,
    diagnosticDashboardState,
} from "@/lib/diagnostic";
import {
    CIVIC_MAITRISE_LABEL,
    CIVIC_THEME_STATE_LABEL,
    niveauCecrlShort,
    type CivicPlanCibleDto,
    type CivicPlanDto,
    type DiagnosticResponse,
    type JourneyDto,
    type JourneyStepDto,
    type LearningPlanDto,
    type PreparationDto,
    type ProgressDto,
} from "@/lib/types";

/**
 * **L'Accueil** de l'espace connecté, **scopé au parcours choisi**.
 *
 * ## Un écran, deux parcours (2026-09-12)
 *
 * 🛑 Arbitrage du propriétaire : « **la bascule avec l'Examen civique doit
 * afficher l'accueil de l'Examen civique** ». La bascule ne navigue donc plus
 * vers le hub d'entraînement : elle change **ce que l'Accueil montre**, comme
 * sur le Plan. Le transport est `?module=`, le défaut est **servi**
 * (`moduleParDefaut(prep)`) et s'inscrit dans l'URL — **aucun `useState` de
 * module**, aucune seconde mécanique.
 *
 * Ce qui suit le parcours : l'action du jour, l'aperçu « Votre Plan »,
 * « Ma préparation », « Affiner votre Plan » (TCF seulement — le diagnostic
 * 4 épreuves n'a pas de pendant civique), « Votre progression » et
 * « À renforcer en priorité ».
 * 🛑 **« Vos parcours » N'EST PAS scopé** : c'est le bloc qui garde la vue
 * d'ensemble des deux modules, et c'est aussi l'un des deux chemins vers les
 * hubs d'entraînement (l'autre étant les deux entrées de la barre latérale).
 *
 * ## Les sources, parcours par parcours
 *
 * | bloc | TCF | Civique |
 * |---|---|---|
 * | à faire maintenant | `/api/diagnostics/current` puis `plan.currentPriority` | `planIndisponible(prep.civique)` puis `civicPlan.prochaine` |
 * | préparation | `prep.tcf` | `prep.civique` |
 * | progression | `summary.tcf` + `tcfMockExams` + `estimatedTcfLevel` | `summary.civique` + `civiqueMockExams` |
 * | progression détectée | `plan.recentChanges` | `civicPlan.changements` |
 * | à renforcer | `summary.tcf` | `summary.civique` |
 *
 * 🛑 **Le civique n'a AUCUN niveau estimé servi** : la quatrième tuile
 * disparaît au lieu d'afficher « — ». `null` = inconnu, jamais mauvais, et on
 * ne fabrique pas une mesure qui n'existe pas.
 *
 * ## La mise en page vient de la maquette
 *
 * `~/Desktop/grok_ecran` — `screenshots/accueil.png` et `accueil-civ.png`.
 * L'écran est monté sur le **KIT** (`SejourApp wide` → colonne de 1080 px au
 * palier desktop) et dispose ses sections par paires avec
 * `sejourStyles.deskPair`. 🛑 **Le desktop n'ajoute aucun composant.** En
 * civique, « Affiner votre Plan » disparaît et « Votre progression » prend
 * toute la rangée — c'est la règle `:only-child` du kit qui joue seule, aucun
 * cas particulier n'est écrit ici.
 *
 * ## Ce que la maquette ne décide PAS
 *
 * 🛑 Elle est une référence de **mise en page**, jamais une source de données
 * ni de règles. La hiérarchie arbitrée est **inchangée** : une seule action
 * dominante — « À faire maintenant » —, un en-tête sans CTA, une priorité TCF
 * verrouillée qui n'est pas nommée, et « Continuez votre diagnostic complet »
 * qui reste secondaire. Les blocs de la maquette sans donnée servie (le trio
 * « compétences travaillées / maîtrisée / validations », les raccourcis du bas)
 * restent **omis**, pas fabriqués.
 *
 * ⚠️ **Un écart assumé avec la maquette civique**, à rouvrir si besoin : la
 * pastille d'objectif nomme la **démarche** servie (« Objectif :
 * naturalisation », autorité `objectifLabel`) et non le module, que la bascule
 * juste en dessous annonce déjà.
 *
 * ✅ **« Votre Plan » est revenu le 2026-09-12** (demande du propriétaire :
 * l'Accueil doit ressembler à la maquette, et « côté backend on a tout ce qu'il
 * faut »). C'était le second écart, celui qui était noté « à rouvrir si
 * besoin ». C'est un **aperçu**, pas un second Plan : aucune action n'en part,
 * il mène au Plan. Même bloc et même ordre sur mobile (`HomeMiniPlan`).
 */
/* --------------------------------------------- « Où vous en êtes » ------- */

/**
 * 🛑 **Miroirs mot pour mot de `home_labels.dart`** : un libellé qui bouge, ce
 * sont deux fichiers dans la même passe.
 */
const SITUATION_TITLE = "Où vous en êtes";
const SITUATION_CARD_TITLE = "Votre niveau par épreuve";
const SITUATION_CARD_LEAD =
    "Une vue simple de votre niveau actuel et de ce qu'il reste à atteindre.";

/**
 * La note de pied de carte (maquette).
 *
 * 🛑 **Elle dit ce qui fait bouger le palier**, et c'est la même règle que la
 * page de résultats : un entraînement libre ou un petit sujet n'y entre pas.
 * Sans elle, un candidat qui vient d'enchaîner des séries lit un niveau
 * inchangé et croit à une panne.
 */
const SITUATION_NOTE =
    "Le niveau affiché évolue uniquement avec vos diagnostics et vos "
    + "épreuves complètes.";

/** Le pendant civique : le civique se mesure en thèmes, jamais en paliers. */
const SITUATION_CIVIC_CARD_TITLE = "Votre niveau par thème";
const SITUATION_CIVIC_CARD_LEAD =
    "Mis à jour après vos séries et votre diagnostic.";

/** 🛑 Elle ne démarre rien : le Plan civique porte le seul lanceur de série. */
const SITUATION_CIVIC_CTA = "Travailler ce thème";

/**
 * L'intitulé de la bande de tête civique.
 *
 * 🛑 **Ce n'est PAS « Objectif actuel »** : le civique n'a aucun objectif servi
 * comparable au palier CECRL du TCF. Ce que le serveur sert, c'est le **dernier
 * résultat** et le seuil de son format — la bande le dit, et rien d'autre.
 */
const SITUATION_CIVIC_RESULT_LABEL = "Votre dernier résultat";

const SITUATION_GOAL_LABEL = "Objectif actuel";

/**
 * « Atteindre B1 partout ». Le palier est **servi** (`ProgressTcfDto.objectif`,
 * dérivé de la démarche) — aucun écran ne le devine.
 */
function situationGoalText(niveau: string): string {
    return `Atteindre ${niveau} partout`;
}

export default function DashboardPage() {
    // `useSearchParams` impose une frontière de Suspense côté App Router.
    return (
        <Suspense fallback={<DashSkeleton/>}>
            <DashboardRoot/>
        </Suspense>
    );
}

function DashboardRoot() {
    const {user, status} = useAuth();
    const search = useSearchParams();
    const pathname = usePathname();
    const router = useRouter();

    const [progres, setProgres] = useState<ProgressDto | null>(null);
    const [diagnostic, setDiagnostic] = useState<DiagnosticResponse | null>(null);
    const [plan, setPlan] = useState<LearningPlanDto | null>(null);
    /* 🛑 **Le parcours est lu ICI aussi** : la carte « À faire maintenant » de
       l'Accueil doit annoncer **la même** étape que celle du Plan. Sans lui,
       cet écran retomberait sur la règle du Plan pendant que le Plan suivrait
       le parcours — exactement la contradiction corrigée le 2026-09-16, à un
       étage de plus. */
    const [journey, setJourney] = useState<JourneyDto | null>(null);
    const [civicPlan, setCivicPlan] = useState<CivicPlanDto | null>(null);
    const [prep, setPrep] = useState<PreparationDto | null>(null);
    const [diagnosticDismissed, setDiagnosticDismissed] = useState(false);
    const [loading, setLoading] = useState(true);

    /**
     * 🛑 **Le parcours affiché vit dans l'URL, exactement comme sur le Plan**
     * (`PlanModules`) : `?module=` est le seul transport, le défaut est
     * **servi** par `moduleParDefaut(prep)`, et il n'existe aucun `useState` de
     * module. Deux mécaniques auraient fini par afficher deux parcours
     * différents sur deux écrans du même compte.
     */
    const [defaut, setDefaut] = useState<ParcoursModule | null>(null);
    const demande = moduleDeLUrl(search);
    const affiche: ParcoursModule = demande ?? defaut ?? "TCF";

    useEffect(() => {
        if (status !== "authenticated" || !user) return;
        let cancelled = false;
        (async () => {
            const [progression, currentDiagnostic, currentPlan, preparation, planCivique, parcours] = await Promise.all([
                // 🛑 Les compteurs de compétences viennent d'ICI, servis pour les
                // deux parcours — l'Accueil ne les recompte pas.
                progressApi.get().catch((): ProgressDto | null => null),
                diagnosticApi.currentCached().catch((): DiagnosticResponse | null => null),
                learningPlanApi.getCached().catch((): LearningPlanDto | null => null),
                // 🛑 Un SEUL appel pour tout l'écran : « Ma préparation » et la
                // carte « Continuez votre diagnostic complet » lisent le même
                // état. Deux appels auraient pu proposer deux prochaines actions.
                userContentApi.preparation().catch((): PreparationDto | null => null),
                // Le pendant civique : l'action du jour, ses priorités et ce qui
                // a bougé. Best-effort — son échec laisse l'écran entier.
                civicPlanApi.getCached().catch((): CivicPlanDto | null => null),
                // Best-effort, comme le reste : un backend antérieur à
                // l'endpoint laisse l'Accueil entier, sur la règle du Plan.
                journeyApi.getCached().catch((): JourneyDto | null => null),
            ]);
            if (cancelled) return;
            setProgres(progression);
            setDiagnostic(currentDiagnostic);
            setPlan(currentPlan);
            setPrep(preparation);
            setCivicPlan(planCivique);
            setJourney(parcours);
            if (preparation) setDefaut(moduleParDefaut(preparation));
            setLoading(false);
        })();
        return () => {
            cancelled = true;
        };
    }, [status, user]);

    /* L'URL devient canonique dès que le défaut servi est connu : elle rend le
       parcours affiché partageable, et c'est elle que lit la bascule. Les autres
       paramètres sont conservés. */
    useEffect(() => {
        if (demande !== null || defaut === null || pathname === null) return;
        const params = new URLSearchParams(search?.toString() ?? "");
        params.set("module", defaut);
        router.replace(`${pathname}?${params.toString()}`, {scroll: false});
    }, [demande, defaut, pathname, router, search]);

    /* Le diagnostic complet en cours, en action secondaire persistante.
       🛑 `abonne: false` : sur l'Accueil la carte ne s'affiche que lorsque le
       complet est COMMENCÉ, et ce libellé-là ne dépend pas de l'abonnement.
       🛑 **TCF seulement** : le diagnostic 4 épreuves est un objet TCF, il n'a
       pas de pendant civique — la maquette ne l'affiche d'ailleurs pas sur
       l'Accueil civique (`screenshots/accueil-civ.png`). */
    const affinerAccueil = useMemo(
        () =>
            prep && affiche === "TCF"
                ? affinerPlan(prep.tcf, {surface: "accueil", abonne: false})
                : null,
        [prep, affiche],
    );

    if (status === "loading" || (loading && status === "authenticated")) {
        return <DashSkeleton/>;
    }
    if (!user) {
        return (
            <div className="dash-empty">
                <p>
                    Session expirée.{" "}
                    <Link href="/connexion" className="dash-empty-link">
                        Se reconnecter
                    </Link>
                </p>
                <style>{emptyStyle}</style>
            </div>
        );
    }

    const civique = affiche === "CIVIQUE";

    /* 🛑 **L'action civique se résout ICI, une fois.** `planIndisponible` est
       l'autorité — la même que « Ma préparation » et que la porte du Plan — et
       elle rend `null` dès que le plan est constructible ; c'est alors la cible
       de rang 1 **désignée par le serveur** qui prend la place. Sans rien des
       deux, la section n'existe pas : pas de titre au-dessus du vide, et la
       rangée laisse sa voisine prendre toute la largeur. */
    const gateCivique = prep ? planIndisponible(prep.civique, "CIVIQUE") : null;
    const cibleCivique = gateCivique ? null : civicPlan?.prochaine ?? null;
    const aUneAction = civique ? Boolean(gateCivique ?? cibleCivique) : Boolean(diagnostic);

    return (
        <SejourApp wide className="home">
            {!user.targetProcedure && (
                <Pad>
                    <Link href="/parcours?from=/dashboard" className="home-banner">
                        <span>
                            <strong>Choisissez votre parcours</strong> (CSP, carte de résident ou
                            naturalisation) pour personnaliser votre préparation.
                        </span>
                        <ArrowRight size={16} aria-hidden/>
                    </Link>
                </Pad>
            )}

            {/* L'en-tête de la maquette : le prénom, puis la démarche visée en
                pastille. La démarche est **servie** (`user.targetProcedure`) et
                son libellé vient de l'autorité unique `objectifLabel`.

                🛑 **Aucun CTA ici** (arbitrage du propriétaire, 2026-09-12) :
                « l'en-tête doit rester simple — Bonjour / nom, objectif actuel.
                L'action principale passe entièrement par la carte À faire
                maintenant, juste en dessous. Une seule action dominante par
                écran. » Le bouton « Entraînement du jour » est parti avec son
                libellé ; sa destination reste atteignable par les deux entrées
                de parcours de la barre latérale et par « Vos parcours ». */}
            <header className="home-hello">
                <h1>Bonjour {user.firstName ?? "à vous"}</h1>
                <span className="home-obj">{objectifLabel(user.targetProcedure)}</span>
            </header>

            {/* 🛑 **Le choix TCF / Examen civique vit ICI** (arbitrage du
                propriétaire, 2026-09-12 : « le menu de gauche, faut le laisser
                comme il était ; le choix entre examen civique et TCF, dans les
                écrans dashboard, plan, entraînement »). C'est la **brique du
                kit**, au même endroit que sur le Plan — sous l'en-tête —, pas
                une seconde implémentation.

                🛑 **Elle change ce que l'Accueil AFFICHE**, elle ne navigue plus
                vers le hub (arbitrage du 2026-09-12 : « la bascule avec l'Examen
                civique doit afficher l'accueil de l'Examen civique »). Les deux
                hubs d'entraînement restent atteignables par les deux entrées
                « TCF IRN » / « Examen civique » de la barre latérale et par les
                cartes de « Vos parcours », qui elles ne sont pas scopées. */}
            <ModuleToggle
                current={civique ? "civique" : "tcf"}
                tcfHref={`${pathname ?? "/dashboard"}?module=TCF`}
                civicHref={`${pathname ?? "/dashboard"}?module=CIVIQUE`}
            />

            <div className={sejourStyles.deskPair}>
                {aUneAction ? (
                    <Section title="À faire maintenant">
                        <Pad>
                            {civique ? (
                                <ActionCivique gate={gateCivique} cible={cibleCivique}/>
                            ) : diagnostic ? (
                                <ActionPrincipale
                                    diagnostic={diagnostic}
                                    plan={plan}
                                    journey={journey}
                                    dismissed={diagnosticDismissed}
                                    onDismiss={() => setDiagnosticDismissed(true)}
                                />
                            ) : null}
                        </Pad>
                    </Section>
                ) : null}

                {/* ✅ **« Votre Plan » est revenu le 2026-09-12** (demande du
                    propriétaire : l'Accueil doit ressembler à la maquette, et
                    « côté backend on a tout ce qu'il faut »). Il avait été omis
                    des deux fronts — « il vit sur le Plan » —, et c'était l'un
                    des deux écarts « à rouvrir si besoin ».

                    🛑 **Un aperçu, pas un second Plan** : aucune action n'en
                    part, il mène au Plan. */}
                <VotrePlan
                    civique={civique}
                    journey={journey}
                    cible={cibleCivique}
                />
            </div>

            {/* ✅ **« Où vous en êtes » ajouté le 2026-09-16** (maquette du
                propriétaire) : une carte compacte par épreuve — palier, jauge,
                état en un mot, action —, puis l'objectif.

                🛑 **Elle ne remplace pas « Votre progression »**, qui garde ses
                deux compteurs de compétences juste en dessous : l'une dit *où
                en est chaque épreuve*, l'autre *combien de compétences ont
                bougé*.

                🛑 **Aucun appel de plus** : `progres` est déjà dans l'état de
                l'écran, et le même `ProgressDto` porte déjà les 4 épreuves.

                ⚠️ Elle prend **toute la rangée** plutôt que d'entrer dans le
                `deskPair` au-dessus : quatre cartes dans une demi-colonne de
                1080 px se replieraient en une file illisible, et la maquette la
                montre pleine largeur. */}
            <OuVousEnEtes progres={progres} civique={civique}/>

            <div className={sejourStyles.deskPair}>
                <Section title="Votre progression">
                    <Pad>
                        <Progression progres={progres} civique={civique}/>
                    </Pad>
                </Section>

                {/* 🛑 **Secondaire, et seulement quand le diagnostic complet est
                    COMMENCÉ.** Elle permet de le reprendre sans passer par le Plan,
                    mais elle ne devient jamais l'action principale de l'Accueil :
                    celle-ci reste « Débloquer mon Plan » pour un compte gratuit et
                    l'action pédagogique du Plan pour un abonné. À 4 / 4 elle
                    disparaît — c'est `affinerPlan` qui rend `null`, sur des faits
                    servis, jamais un compteur reconstruit ici. */}
                {affinerAccueil && <AffinerPlanCard info={affinerAccueil}/>}
            </div>

            {/* 🛑 **« Vos parcours » n'est PAS scopé** : c'est le bloc qui garde
                la vue d'ensemble des deux modules pendant que le reste de
                l'écran suit la bascule. Chaque ligne mène au **Plan** de son
                module, comme la maquette — les deux hubs d'entraînement restent
                atteignables par les deux entrées de la barre latérale. */}
            <Section title="Vos parcours">
                <Pad>
                    <Stack className={sejourStyles.deskPair}>
                        <TrackRow title={TCF_LABEL} href={planHref("TCF")}/>
                        <TrackRow title={CIVIQUE_LABEL} href={planHref("CIVIQUE")}/>
                    </Stack>
                </Pad>
            </Section>

            <style>{homeStyles}</style>
        </SejourApp>
    );
}

/**
 * **L'action principale de l'Accueil**, dans la carte hero du KIT.
 *
 * 🛑 Les trois états et leurs phrases sont **inchangés** : ce qui a changé,
 * c'est la brique qui les porte (`NowCard`), pas ce qu'elles disent.
 */
function ActionPrincipale({
                              diagnostic,
                              plan,
                              journey,
                              dismissed,
                              onDismiss,
                          }: {
    diagnostic: DiagnosticResponse;
    plan: LearningPlanDto | null;
    journey: JourneyDto | null;
    dismissed: boolean;
    onDismiss: () => void;
}) {
    const state = diagnosticDashboardState(diagnostic);
    if (state === "NOT_STARTED" && dismissed) return null;

    if (state === "NOT_STARTED") {
        return (
            <NowCard
                icon={ClipboardCheck}
                title="Découvrez ce qui vous bloque au TCF"
                /* 🛑 L'effort annoncé est DÉRIVÉ du format servi, jamais écrit :
                   le diagnostic actif n'a qu'une production écrite, et la carte
                   promettait « 2 exercices · ≈ 8 à 10 min ». */
                subtitle={diagnosticStartSubtitle(diagnostic.format)}
                badge="Votre point de départ"
                objective={diagnosticStartObjective(diagnostic.format)}
            >
                <div className="home-now-actions">
                    <Cta href="/diagnostic">Faire mon diagnostic</Cta>
                    <button type="button" onClick={onDismiss} className="home-now-later">
                        Plus tard
                    </button>
                </div>
            </NowCard>
        );
    }

    if (state === "IN_PROGRESS") {
        const done = diagnosticCompletedExerciseCount(diagnostic);
        const analyzing = diagnostic.status === "ANALYZING" || diagnostic.nextStep === "ANALYSIS";
        return (
            <NowCard
                icon={Sparkles}
                title={analyzing ? "Votre analyse est en préparation" : "Reprenez votre diagnostic"}
                subtitle={diagnosticCountLabel(done, diagnosticExerciseCount(diagnostic))}
                badge="Diagnostic en cours"
                objective={
                    analyzing
                        ? diagnosticAnalyzingObjective(diagnostic.format)
                        : "Continuez exactement à l'étape où vous vous êtes arrêté."
                }
            >
                <div className="home-now-actions">
                    <Cta href="/diagnostic">
                        {analyzing ? "Voir l'analyse" : "Reprendre mon diagnostic"}
                    </Cta>
                </div>
            </NowCard>
        );
    }

    return <ActionPlanDuJour plan={plan} journey={journey}/>;
}

/**
 * **L'action du jour**, une fois le diagnostic terminé.
 *
 * 🛑 **Elle annonce exactement ce qu'annonce le Plan** : `planNowCard` est
 * l'autorité unique des quatre cartes « À faire maintenant » du produit (Plan
 * et Accueil, web et mobile). Sans elle, cet écran ne lisait que
 * `currentPriority` : il annonçait « Raconter brièvement une expérience passée ·
 * VOTRE PRIORITÉ DU JOUR » pendant que le Plan, au même instant, demandait de
 * « Compléter mon évaluation de compréhension écrite · À ÉVALUER ».
 *
 * 🛑 **Cet écran n'a AUCUNE notion de plan gratuit** — contrairement au Plan,
 * qui rend une carte à part pour un compte sans accès. Ici le seul fait lu est
 * le `locked` **servi**, comme avant : rien à masquer de plus.
 */
function ActionPlanDuJour({plan, journey}: {
    plan: LearningPlanDto | null;
    journey: JourneyDto | null;
}) {
    const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
    const assessments = usePlanAssessment();

    const vue = plan ? planNowCard(plan, {journey}) : null;
    /* 🛑 **Une priorité verrouillée n'est jamais NOMMÉE ici.** Depuis que le
       Plan sait aussi désigner une compétence *à acquérir*, la priorité n°1
       peut porter un cadenas — et « Mes priorités » la floute alors. L'écrire
       en clair sur l'Accueil démentirait ce rideau. Miroir du mobile
       (`_actionTcf`, `home_screen.dart`), qui retombe sur son texte générique.

       ⚠️ **Une MESURE n'est pas une priorité** : elle n'est floutée nulle part,
       donc elle se nomme ici comme sur le Plan. Le serveur ne pose d'ailleurs
       aucun verrou dessus — s'il en posait un, `locked` le dirait. */
    const carte = vue && (vue.nature === "MESURE" ? !vue.locked : !vue.priority.locked)
        ? vue
        : null;
    const mesure = carte?.mesure ?? null;
    const exercise = carte?.exercise ?? null;
    /* 🛑 **Un raccourci verrouillé n'en est pas un.** La priorité du jour peut
       être une compétence **à acquérir** — désignée avec son `locked`, le
       serveur ayant vérifié qu'elle n'est pas ouverte par sa place n°1 —, et
       « Commencer directement » enverrait alors un compte gratuit droit sur un
       403. Le Plan, lui, reste ouvert : on garde « Continuer mon plan », qui
       porte le cadenas et l'offre. */
    const startable = carte !== null
        && (mesure !== null ? !carte.locked : Boolean(exercise) && !exercise?.locked);
    const busy = starting || assessments.starting !== null;

    return (
        <>
            <NowCard
                icon={carte ? planNowIcon(carte) : Target}
                variant={carte?.nature === "VERIFICATION" ? "verify" : "default"}
                /* Le titre de l'action, et rien d'autre : `explanation` est le
                   constat d'une production déjà faite — il raconte le passé sur
                   une carte qui annonce l'action à mener, et il vit déjà dans
                   le Plan. */
                title={carte?.title ?? "Continuez votre plan personnalisé"}
                subtitle={carte?.subtitle}
                /* 🛑 Une mesure n'est pas « votre priorité du jour » : sa
                   pastille dit sa nature servie, comme sur le Plan. */
                badge={carte?.badge ?? "Votre priorité du jour"}
            >
                <div className="home-now-actions">
                    <Cta href="/plan">Continuer mon plan</Cta>
                    {/* 🛑 **Les lanceurs du Plan, jamais un second chemin** :
                        une mesure part chez `usePlanAssessment`, un exercice
                        chez `usePlanExercise` — exactement comme le bouton du
                        Plan. Le raccourci **nomme ce qu'il lance** quand c'est
                        une mesure ; sinon il garde le libellé de l'Accueil. */}
                    {startable && carte && (
                        <button
                            type="button"
                            className="home-now-later"
                            disabled={busy}
                            onClick={() => {
                                if (mesure) {
                                    void assessments.start(mesure.assessment);
                                    return;
                                }
                                if (exercise) void start(exercise);
                            }}
                        >
                            {mesure ? carte.cta : "Commencer directement"}
                        </button>
                    )}
                </div>
            </NowCard>
            {(error ?? assessments.error) && (
                <p className={sejourStyles.tiny} role="alert">{error ?? assessments.error}</p>
            )}
            <PaywallSheet
                origin="plan"
                ctaLocation="LOCKED_PLAN"
                screen="dashboard"
                module="INTEGRAL"
                open={paywallOpen || assessments.paywallOpen}
                onClose={() => { closePaywall(); assessments.closePaywall(); }}
            />
        </>
    );
}

/**
 * **L'action principale de l'Accueil CIVIQUE.**
 *
 * 🛑 **Aucune règle nouvelle, aucun libellé nouveau.** Deux autorités déjà en
 * place, exactement celles qu'emploient le Plan civique et les deux autres
 * portes : `planIndisponible(prep, "CIVIQUE")` quand le plan n'est pas encore
 * constructible, et `CivicPlanDto.prochaine` — la cible de rang 1, **désignée
 * par le serveur** — sinon.
 *
 * 🛑 **Cette carte ne DÉMARRE rien.** Elle mène au Plan civique, qui porte le
 * seul lanceur de série (`CivicPlanPanel`). Un second point de départ aurait
 * dupliqué la gestion du 403 et du paywall.
 *
 * 🛑 **Le verrou civique porte sur la SÉRIE, jamais sur le constat** : une
 * cible `locked` garde son nom et son état — c'est la règle du module civique,
 * et elle diffère volontairement de celle du TCF, où une priorité verrouillée
 * n'est pas nommée parce que le Plan la floute.
 */
function ActionCivique({gate, cible}: {
    gate: PlanIndisponible | null;
    cible: CivicPlanCibleDto | null;
}) {
    // La porte : même phrase, même bouton, même destination que « Ma
    // préparation » et que la porte du Plan.
    if (gate) {
        return (
            <NowCard
                icon={Landmark}
                title={gate.titre}
                badge="Votre point de départ"
                objective={gate.texte}
            >
                <div className="home-now-actions">
                    <Cta href={gate.href} variant="blue">{gate.cta}</Cta>
                </div>
            </NowCard>
        );
    }

    if (!cible) return null;

    const sousTitre = cible.label === cible.themeLabel ? undefined : cible.themeLabel;
    return (
        <NowCard
            icon={Landmark}
            title={cible.label}
            subtitle={sousTitre}
            badge="Votre priorité du jour"
            objectiveLabel="Ce que le plan a observé"
            objective={`${CIVIC_MAITRISE_LABEL[cible.maitrise]} · ${civicPlanRaison(cible)}`}
        >
            <div className="home-now-actions">
                <Cta href={planHref("CIVIQUE")} variant="blue">Continuer mon plan</Cta>
            </div>
        </NowCard>
    );
}

/**
 * **Où vous en êtes** — le bandeau d'objectif, puis **une ligne par épreuve**
 * dans une seule carte, chacune portant son **échelle CECRL**.
 *
 * ⚠️ **Refait le 2026-09-16 sur la maquette v2 du propriétaire**
 * (`ou_en_vous_v2.html`), qui **révoque** la grille à deux colonnes de cartes
 * compactes livrée le matin même : ce n'est pas un habillage, c'est la
 * structure qui change.
 *
 * 🛑 **Rien n'est classé ici.** Libellé, pastille, ton, échelle, CTA et
 * destination viennent tous de `accueilEpreuve*` / `accueilEchelons`
 * (`lib/progres.ts`), l'autorité **partagée avec l'écran Progrès**, qui ne lit
 * que des faits servis : `status`, `evolution`, `niveau`, `objectif`. Aucun
 * palier n'est comparé à un autre — cette comparaison vit côté serveur, dans
 * `StatutObjectifResolver`.
 *
 * 🛑 **La section n'existe pas tant que rien n'est servi** : pas de titre
 * au-dessus du vide, comme tous les blocs de cet écran.
 *
 * 🛑 **Miroir de `_ouVousEnEtes` côté mobile**, bloc pour bloc.
 */
function OuVousEnEtes({progres, civique}: {
    progres: ProgressDto | null;
    civique: boolean;
}) {
    if (!progres) return null;
    return civique
        ? <SituationCivique progres={progres}/>
        : <SituationTcf progres={progres}/>;
}

function SituationTcf({progres}: {progres: ProgressDto}) {
    /* 🛑 **Le lanceur du Plan, jamais un second** : une épreuve jamais mesurée
       porte le descripteur `evaluation` servi, et c'est `usePlanAssessment` —
       celui de « Compléter mon profil » et de la ligne `A_EVALUER` de la
       séance — qui l'ouvre. Écrire ici un second chemin de démarrage l'aurait
       fait diverger de celui-là. */
    const assessments = usePlanAssessment();
    const epreuves = progres.tcf.epreuves;
    /* Les 4 épreuves sont **toujours** servies : depuis le 2026-09-16 elles ne
       dépendent plus du diagnostic 4 épreuves. Une liste vide ne devrait donc
       plus arriver — mais un client servi par un backend antérieur au
       correctif la verrait, et le bloc se tait plutôt que d'afficher un titre
       au-dessus du vide. */
    if (epreuves.length === 0) return null;
    const objectif = progres.tcf.objectif;
    const compte = accueilEvaluees(epreuves);

    return (
        <Section title={SITUATION_TITLE}>
            <Pad>
                {/* 🛑 **Le liseré tricolore est décoratif** : il marque la carte
                    de tête de la maquette, il ne code aucun état. */}
                <Card rule="flag">
                    <PanelHead lead title={SITUATION_CARD_TITLE} sub={SITUATION_CARD_LEAD}/>
                    {/* 🛑 **Le bandeau passe AU-DESSUS de la liste** (maquette) :
                        il annonce vers quoi on va avant de montrer où on en
                        est. Sans démarche déclarée, pas de bandeau — on ne
                        devine pas l'objectif d'un candidat qui n'en a pas
                        donné, et le compteur part avec lui. */}
                    {objectif && (
                        <GoalBanner
                            label={SITUATION_GOAL_LABEL}
                            value={situationGoalText(niveauCecrlShort(objectif))}
                            count={compte?.faites}
                            total={compte?.total}
                            caption={ACCUEIL_EVALUEES_CAPTION}
                        />
                    )}
                    <LevelList>
                        {epreuves.map((e) => {
                            /* 🛑 **Trois issues, aucune inventée.**
                               1. Épreuve jamais mesurée dont le serveur dit par
                                  quoi la mesurer ⇒ on **lance** cette mesure,
                                  sans étape intermédiaire.
                               2. Quelque chose à faire, mais rien à lancer
                                  (épreuve en progression ; ou descripteur
                                  absent — client ancien) ⇒ la fiche du domaine,
                                  le comportement historique.
                               3. Rien à faire ⇒ la page des résultats.
                               Le choix se lit sur l'état servi, jamais sur un
                               texte de bouton. */
                            const mesure = e.niveau === null ? e.evaluation : null;
                            const href = accueilEpreuveOuvreLExercice(e)
                                ? planDomainHref(
                                    e.epreuve as Parameters<typeof planDomainHref>[0])
                                : `/historique/epreuve/${planDomainSlug(
                                    e.epreuve as Parameters<typeof planDomainSlug>[0])}`;
                            const domaine = e.epreuve as Parameters<
                                typeof planDomainLabel>[0];
                            const mesuree = Boolean(e.niveau);
                            return (
                                <LevelRow
                                    key={e.epreuve}
                                    mark={planDomainShort(domaine)}
                                    title={planDomainLabel(domaine)}
                                    status={accueilEpreuveStatut(e)}
                                    tone={accueilEpreuveTon(e)}
                                    level={accueilEpreuveBadge(e)}
                                    measured={mesuree}
                                    scale={
                                        <LevelLadder
                                            steps={accueilEchelons(e, objectif)}
                                            label={accueilEchelleLabel(e, objectif)}
                                            dim={!mesuree}
                                        />
                                    }
                                    cta={accueilEpreuveCta(e)}
                                    /* Le bouton plein est réservé à l'action qui
                                       MANQUE : mesurer une épreuve jamais
                                       évaluée. Relire un résultat reste un lien. */
                                    ctaPrimary={!mesuree}
                                    goal={accueilObjectifLabel(objectif)}
                                    busy={assessments.starting === e.epreuve}
                                    href={mesure ? null : href}
                                    onClick={mesure
                                        ? () => void assessments.start(mesure)
                                        : undefined}
                                />
                            );
                        })}
                    </LevelList>
                    {/* ⚠️ **Hors maquette, et conservé volontairement** : elle
                        dit ce qui fait bouger le palier (diagnostics et épreuves
                        complètes, pas les séries). Sans elle, un candidat qui
                        vient d'enchaîner des entraînements lit un niveau
                        inchangé et croit à une panne. Une ligne discrète, qui ne
                        change rien à la structure de la carte. */}
                    <MicroNote>{SITUATION_NOTE}</MicroNote>
                    {assessments.error && (
                        <p className={sejourStyles.tiny} role="alert">{assessments.error}</p>
                    )}
                </Card>
            </Pad>
            <PaywallSheet
                origin="plan"
                ctaLocation="LOCKED_PLAN"
                screen="dashboard"
                module="INTEGRAL"
                open={assessments.paywallOpen}
                onClose={assessments.closePaywall}
            />
        </Section>
    );
}

/**
 * Le pendant civique — **la même anatomie** (arbitrage du propriétaire,
 * 2026-09-16) : carte à liseré tricolore, en-tête, bande de tête, puis une
 * ligne par thème avec sa pastille, son statut à pastille colorée et sa ligne
 * de pied.
 *
 * 🛑 **Adapté, jamais transposé.** Le civique n'a **ni palier CECRL ni
 * objectif CECRL servi** : pas d'échelle à crans, pas d'« Atteindre B2
 * partout », pas de pastille de niveau. La bande de tête dit ce qui EST servi —
 * le dernier résultat et son seuil (`progresCiviqueScore`, l'autorité déjà en
 * place) — et le compteur porte sur les **thèmes** de la liste servie.
 */
function SituationCivique({progres}: {progres: ProgressDto}) {
    const themes = progres.civique.themes;
    if (themes.length === 0) return null;
    /* 🛑 Rien n'est fabriqué : sans examen civique passé, le serveur ne sert ni
       score ni seuil, et la bande disparaît — exactement comme le bandeau TCF
       sans démarche déclarée. */
    const dernier = progresCiviqueScore(progres.civique);
    const compte = accueilEvaluesCivique(themes);

    return (
        <Section title={SITUATION_TITLE}>
            <Pad>
                <Card rule="flag">
                    <PanelHead
                        lead
                        title={SITUATION_CIVIC_CARD_TITLE}
                        sub={SITUATION_CIVIC_CARD_LEAD}
                    />
                    {dernier && (
                        <GoalBanner
                            label={SITUATION_CIVIC_RESULT_LABEL}
                            value={dernier}
                            count={compte?.faites}
                            total={compte?.total}
                            caption={ACCUEIL_EVALUES_CAPTION_CIVIQUE}
                        />
                    )}
                    <LevelList>
                        {themes.map((t, rang) => (
                            <LevelRow
                                key={t.themeId}
                                /* 🛑 **Le repère est le RANG SERVI**, pas un
                                   code abrégé : un thème n'a aucun code de deux
                                   lettres servi (`CIV_PRINCIPES` n'en est pas
                                   un), et en inventer un serait fabriquer un
                                   libellé. Le produit numérote déjà les cinq
                                   thèmes du livret citoyen — on montre leur
                                   position dans la liste que le serveur
                                   ordonne, rien de plus. */
                                mark={`${rang + 1}`}
                                title={t.label}
                                /* 🛑 L'état arrive **servi** : on pose son
                                   libellé gelé, on ne classe aucun nombre.
                                   `NON_EVALUE` reste neutre, jamais ambre. */
                                status={t.etat === "NON_EVALUE"
                                    ? NON_MESURE_LABEL
                                    : CIVIC_THEME_STATE_LABEL[t.etat]}
                                tone={civicBarTone(t.etat)}
                                /* 🛑 **Aucun palier CECRL en civique** : le
                                   civique se mesure en thèmes, jamais en
                                   paliers. La pastille de droite disparaît. */
                                level={null}
                                measured={t.etat !== "NON_EVALUE"}
                                /* 🛑 **Pas d'échelle CECRL non plus** — mais la
                                   jauge d'état, elle, est servie : `civicBarTone`
                                   et `civicBarJauge` restent les autorités déjà
                                   en place pour cet enum. */
                                scale={
                                    <ProgressMini
                                        ratio={civicBarJauge(t.etat)}
                                        tone={civicBarTone(t.etat)}
                                        label={CIVIC_THEME_STATE_LABEL[t.etat]}
                                    />
                                }
                                cta={SITUATION_CIVIC_CTA}
                                goal={null}
                                href={planHref("CIVIQUE")}
                            />
                        ))}
                    </LevelList>
                </Card>
            </Pad>
        </Section>
    );
}

/**
 * **Votre Plan** — la priorité actuelle et son parcours, en aperçu.
 *
 * 🛑 **Rien n'est dérivé ici** : `parcoursDeLaTache` (TCF) et `civicPath`
 * (civique) sont les autorités **partagées avec l'écran Plan**, et les états
 * des étapes viennent du serveur.
 *
 * 🛑 **Une priorité TCF verrouillée n'est pas nommée** : le bloc entier
 * disparaît. Il écrirait en clair, sur l'Accueil, ce que « Mes priorités »
 * floute un écran plus loin. Le civique, lui, nomme sa cible — son verrou porte
 * sur la **série**, jamais sur le constat.
 *
 * 🛑 **Aucun contenu fabriqué** : sans priorité servie, sans tâche servie ou
 * sans parcours servi, la section n'existe pas.
 */
function VotrePlan({civique, journey, cible}: {
    civique: boolean;
    journey: JourneyDto | null;
    cible: CivicPlanCibleDto | null;
}) {
    if (civique) {
        if (!cible) return null;
        const steps = civicPath(cible);
        if (steps.length === 0) return null;
        return (
            <PlanApercu
                title={cible.themeLabel}
                subtitle={cible.label === cible.themeLabel ? null : cible.label}
                counter={civicPathCounter(cible)}
                steps={steps}
                href={planHref("CIVIQUE")}
            />
        );
    }

    /* 🛑 **L'aperçu suit le PARCOURS**, plus le parcours d'une tâche : c'est la
       même file que le Plan affiche en entier, et la même que la carte « À
       faire maintenant » vient de nommer. Trois vues d'un seul objet.

       🛑 **Pas de `current` ⇒ pas de bloc** : aucun objectif déclaré, plus rien
       à faire, ou rien d'exécutable. Dans ce dernier cas la carte d'action
       porte déjà le paywall — l'aperçu n'a rien à ajouter. */
    const courante = journey?.current ?? null;
    if (!journey || !courante) return null;
    const fenetre = apercuJourneySteps(journey.steps, courante.id);
    if (fenetre.length === 0) return null;
    return (
        <PlanApercu
            title={journeyStepTitle(courante)}
            subtitle={journeyStepSubtitle(courante) ?? null}
            /* 🛑 **Aucun compteur d'étape.** Le parcours n'en sert pas, et
               `steps` est **déjà filtrée** par le serveur : un « Étape 2 / 5 »
               dérivé de cette liste compterait la fenêtre, pas la file. On
               n'affiche pas un nombre qu'on ne sait pas. */
            counter={null}
            steps={fenetre}
            href={planHref("TCF")}
        />
    );
}

/**
 * La fenêtre d'étapes affichée sur l'Accueil, **centrée sur l'étape courante**.
 *
 * 🛑 **Un plafond d'AFFICHAGE, jamais un budget pédagogique** : la file entière
 * est servie et se lit sur le Plan, où « Voir mon Plan » renvoie.
 *
 * 🛑 **La fenêtre contient TOUJOURS l'étape courante** : elle et la suivante,
 * ou la précédente et elle quand elle ferme la file. Montrer « les deux
 * premières » aurait caché exactement ce que le candidat doit faire maintenant.
 */
function apercuJourneySteps(steps: JourneyStepDto[], currentId: string): JourneyStepDto[] {
    if (steps.length <= APERCU_STEPS_MAX) return steps;
    const maintenant = steps.findIndex((step) => step.id === currentId);
    if (maintenant < 0) return steps.slice(0, APERCU_STEPS_MAX);
    const debut =
        maintenant + APERCU_STEPS_MAX <= steps.length
            ? maintenant
            : steps.length - APERCU_STEPS_MAX;
    return steps.slice(debut, debut + APERCU_STEPS_MAX);
}

/**
 * Ce que l'Accueil montre du parcours : **deux étapes**, pas plus (demande du
 * propriétaire, 2026-09-12 — un parcours d'expression en compte huit).
 */
const APERCU_STEPS_MAX = 2;

/**
 * La fenêtre d'étapes affichée sur l'Accueil.
 *
 * 🛑 **Un plafond d'AFFICHAGE, jamais un budget pédagogique** : le parcours
 * entier est servi, calculé en entier, et se lit sur le Plan — où « Voir mon
 * Plan » renvoie. On n'en tronque que la vue.
 *
 * 🛑 **La fenêtre contient TOUJOURS l'étape en cours** : elle et la suivante,
 * ou la précédente et elle quand elle ferme le parcours. Montrer « les deux
 * premières » aurait caché exactement ce que le candidat doit faire maintenant.
 * Sans étape en cours **servie**, on prend les premières — on n'en devine
 * aucune. Miroir de `homePlanSteps`
 * (`mobile_sejourfr/lib/screens/home/widgets/home_blocks.dart`).
 */
function apercuSteps(steps: PlanPathStep[]): PlanPathStep[] {
    if (steps.length <= APERCU_STEPS_MAX) return steps;
    const maintenant = steps.findIndex((step) => step.state === "now");
    if (maintenant < 0) return steps.slice(0, APERCU_STEPS_MAX);
    const debut =
        maintenant + APERCU_STEPS_MAX <= steps.length
            ? maintenant
            : steps.length - APERCU_STEPS_MAX;
    return steps.slice(debut, debut + APERCU_STEPS_MAX);
}

function PlanApercu({title, subtitle, counter, steps, href}: {
    title: string;
    subtitle: string | null;
    /** `null` sur le parcours TCF : il ne sert aucune position d'étape. */
    counter: string | null;
    /** Les étapes **du parcours** (TCF) ou **du parcours civique**, déjà
     *  fenêtrées par l'appelant. */
    steps: JourneyStepDto[] | PlanPathStep[];
    href: string;
}) {
    return (
        <Section title="Votre Plan">
            <Pad>
                <Card>
                    <div className="home-plan-head">
                        <p className={sejourStyles.label}>Priorité actuelle</p>
                        {counter && <span className={sejourStyles.tiny}>{counter}</span>}
                    </div>
                    <p className="home-plan-title">{title}</p>
                    {subtitle && (
                        <p className={sejourStyles.tiny} style={{margin: "2px 0 10px"}}>
                            {subtitle}
                        </p>
                    )}
                    {steps.map((step, index) =>
                        "id" in step ? (
                            <JourneyRow
                                key={step.id}
                                title={journeyStepTitle(step)}
                                subtitle={journeyStepSubtitle(step)}
                                state={journeyKitState(step)}
                                kind={journeyKind(step)}
                                badge={journeyBadge(step)}
                                locked={step.locked}
                            />
                        ) : (
                            <PathRow key={`${step.label}-${index}`} label={step.label} state={step.state}/>
                        ),
                    )}
                    <Link href={href} className={sejourStyles.link} style={{marginTop: 12}}>
                        Voir mon Plan <ArrowRight size={16} strokeWidth={2.4} aria-hidden/>
                    </Link>
                </Card>
            </Pad>
        </Section>
    );
}

/**
 * **Votre progression**, du parcours affiché : les deux compteurs de la
 * maquette, et rien d'autre.
 *
 * 🛑 **Ils sont SERVIS** (`GET /api/me/progress`), pour les deux parcours, et
 * **servis même verrouillés** : c'est le *détail* qui est premium, pas le fait
 * d'avoir progressé. Rien n'est recompté ici.
 *
 * ⚠️ **« Progression détectée » a quitté l'Accueil** (2026-09-12, demande du
 * propriétaire). Le bloc vit toujours sur le **Plan**, où il a son contexte :
 * il y annonce une transition d'état de maîtrise mesurée par le moteur, dans
 * une fenêtre choisie par le serveur. Sur l'Accueil, il arrivait sans le
 * parcours qui l'explique.
 *
 * ⚠️ **La troisième colonne « validations » de la maquette n'est servie par
 * rien** : elle est **omise**, pas fabriquée.
 *
 * 🛑 **Le civique compte des notions OU des thèmes** selon ce que le tagging
 * permet (`grainNotion`, servi) : son libellé le dit, au lieu d'écrire
 * « compétences » à tort.
 */
function Progression({progres, civique}: {
    progres: ProgressDto | null;
    civique: boolean;
}) {
    const travaillees = civique
        ? progres?.civique.travaillees ?? 0
        : progres?.tcf.competences.travaillees ?? 0;
    const maitrisees = civique
        ? progres?.civique.maitrisees ?? 0
        : progres?.tcf.competences.maitrisees ?? 0;
    const notion = civique ? progres?.civique.grainNotion ?? false : false;

    // Rien de mesuré : le bloc n'a rien à dire.
    if (travaillees <= 0) return null;

    return (
        <Card>
            <div className="home-stats">
                <StatBloc
                    value={`${travaillees}`}
                    label={compteurLabel(travaillees, {civique, notion, mastered: false})}
                />
                <StatBloc
                    value={`${maitrisees}`}
                    label={compteurLabel(maitrisees, {civique, notion, mastered: true})}
                />
            </div>
        </Card>
    );
}

/**
 * « 3 compétences travaillées » / « 1 thème maîtrisé ».
 *
 * 🛑 Miroir mot pour mot de `homeWorkedLabel` / `homeMasteredLabel`
 * (`mobile_sejourfr/lib/screens/home/home_labels.dart`).
 */
function compteurLabel(
    n: number,
    {civique, notion, mastered}: {civique: boolean; notion: boolean; mastered: boolean},
): string {
    const s = n > 1 ? "s" : "";
    const nom = civique ? (notion ? "notion" : "thème") : "compétence";
    const verbe = mastered ? "maîtrisé" : "travaillé";
    const accord = civique && !notion ? verbe : `${verbe}e`;
    return `${nom}${s} ${accord}${s}`;
}

function StatBloc({value, label}: {value: string; label: string}) {
    return (
        <div className="home-stat">
            <span className="home-stat-value">{value}</span>
            <span className="home-stat-label">{label}</span>
        </div>
    );
}

/**
 * Une ligne de « Vos parcours » : le module, ce qu'elle ouvre, un chevron.
 */
function TrackRow({title, href}: {title: string; href: string}) {
    return (
        <Link href={href} className="home-track">
            <span className="home-track-body">
                <span className="home-track-title">{title}</span>
                <span className="home-track-sub">Voir mon Plan</span>
            </span>
            <ArrowRight size={20} aria-hidden/>
        </Link>
    );
}

function DashSkeleton() {
    return (
        <SejourApp wide className="home">
            <Pad>
                <div className="sk sk-head"/>
                <div className="sk-grid sk-grid-2">
                    <div className="sk sk-card"/>
                    <div className="sk sk-card"/>
                </div>
                <div className="sk-grid sk-grid-2">
                    <div className="sk sk-card"/>
                    <div className="sk sk-card"/>
                </div>
            </Pad>
            <style>{homeStyles}</style>
            <style>{`
        .sk {
          background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
          background-size: 200% 100%;
          animation: sk-shimmer 1.4s infinite;
          border-radius: 16px;
        }
        @keyframes sk-shimmer {
          to { background-position: -200% 0; }
        }
        .sk-head { height: 92px; margin-bottom: 22px; }
        .sk-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 16px;
          margin-bottom: 22px;
        }
        .sk-card { height: 180px; }
        @media (min-width: 960px) {
          .sk-grid-2 { grid-template-columns: 1fr 1fr; }
        }
      `}</style>
        </SejourApp>
    );
}

const emptyStyle = `
  .dash-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px;
    color: var(--color-muted);
  }
  .dash-empty-link { color: var(--color-blue); font-weight: 700; }
`;

/**
 * 🛑 **Aucune couleur ni font en dur** : tout passe par les tokens `@theme`
 * (`--color-*`, `--font-*`) et par les variables du KIT (`--sf-*`), disponibles
 * parce que l'écran est dans le scope `.app`.
 *
 * 🛑 **Aucune borne nouvelle** : les seules media queries ici sont celles de la
 * fondation (960 px), et elles ne font que reprendre ce que le KIT décide déjà.
 */
const homeStyles = `
  /* ===== bandeaux ===== */
  .home-banner {
    display: flex; align-items: center; justify-content: space-between; gap: 14px;
    background: var(--color-blue-light);
    border: 1px solid color-mix(in srgb, var(--color-blue) 18%, transparent);
    color: var(--color-ink);
    border-radius: 14px;
    padding: 13px 18px;
    font-size: 14px;
    text-decoration: none;
    margin-top: 14px;
    transition: filter 0.15s;
  }
  .home-banner:hover { filter: brightness(0.98); }
  .home-banner strong { color: var(--color-blue); }
  /* ===== en-tête « Bonjour X » ===== */
  /* Deux lignes, et rien d'autre : le nom, puis la démarche visée en pastille.
     L'en-tête était une rangée à deux pôles parce qu'elle portait un CTA à
     droite ; il est parti (une seule action dominante par écran), la rangée
     avec lui. La pastille passe à la ligne d'elle-même : le titre est un bloc. */
  .home-hello {
    padding: 14px 16px 2px;
  }
  .home-hello h1 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 26px;
    font-weight: 800;
    letter-spacing: -0.035em;
    line-height: 1.15;
    color: var(--color-ink);
  }
  .home-obj {
    display: inline-flex;
    margin-top: 10px;
    padding: 5px 10px;
    border-radius: var(--sf-radius-pill);
    background: var(--color-blue-light);
    color: var(--color-blue-dark);
    font-size: 12px;
    font-weight: 750;
  }
  /* ===== actions de la carte « À faire maintenant » ===== */
  .home-now-actions {
    margin-top: 14px;
    display: grid;
    gap: 8px;
    justify-items: start;
  }
  .home-now-actions > * { width: 100%; }
  .home-now-later {
    justify-self: center;
    border: 0;
    padding: 4px;
    background: transparent;
    color: var(--color-muted);
    font: inherit;
    font-size: 13px;
    font-weight: 700;
    text-align: center;
    text-decoration: none;
    cursor: pointer;
    width: auto;
  }
  .home-now-later:hover { color: var(--color-blue); text-decoration: underline; }

  /* ===== aperçu « Votre Plan » ===== */
  .home-plan-head {
    display: flex; align-items: baseline; justify-content: space-between;
    gap: 12px;
    margin-bottom: 2px;
  }
  .home-plan-title {
    margin: 0 0 2px;
    font-family: var(--font-sans);
    font-size: 17px;
    font-weight: 800;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }


  /* ===== « Où vous en êtes » ===== */
  /* 🛑 **Plus une seule règle de cet écran.** Toute la section vit dans le KIT
     depuis la 3ᵉ passe du 2026-09-16 (maquette v2) : PanelHead en variante
     lead, GoalBanner, LevelList, LevelRow, LevelLadder et MicroNote, avec
     leur miroir Flutter dans la même passe — c'est ce qui garantit que les deux
     fronts montrent la même carte. Les classes .home-situation-title et
     .home-situation-copy sont SUPPRIMÉES avec leurs appelants, comme l'étaient
     déjà .home-situation-grid / -card / -head / -name / -badge / -statut et
     .home-goal. */

  /* ===== indicateurs ===== */
  /* Les deux compteurs SERVIS de la maquette : un chiffre, un libellé. */
  .home-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 16px 12px;
    margin-bottom: 16px;
  }
  .home-stat { display: flex; flex-direction: column; align-items: center; }
  .home-stat-value {
    font-family: var(--font-display);
    font-size: 30px;
    font-weight: 600;
    letter-spacing: -0.02em;
    color: var(--color-blue);
    line-height: 1.1;
  }
  .home-stat-label {
    font-size: 12.5px;
    font-weight: 600;
    color: var(--color-muted);
    text-align: center;
    margin-top: 4px;
  }

  /* ===== une ligne de « Vos parcours » ===== */
  .home-track {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    padding: 14px 16px;
    background: #fff;
    border-radius: var(--sf-radius-xl, 18px);
    box-shadow: var(--sf-shadow-card, 0 1px 3px rgba(50, 64, 94, 0.06));
    color: var(--color-ink);
    text-decoration: none;
    transition: box-shadow 0.15s;
  }
  .home-track:hover { box-shadow: 0 6px 18px rgba(50, 64, 94, 0.1); }
  .home-track-body { display: flex; flex-direction: column; min-width: 0; }
  .home-track-title {
    font-size: 16px;
    font-weight: 800;
    letter-spacing: -0.01em;
  }
  .home-track-sub { font-size: 12.5px; color: var(--color-muted); margin-top: 1px; }

  /* ===== palier desktop (960 px) — la borne du KIT, pas une de plus ===== */
  @media (min-width: 960px) {
    .home-hello {
      padding-left: 0;
      padding-right: 0;
      padding-top: 10px;
    }
    .home-hello h1 { font-size: 32px; }
  }
`;
