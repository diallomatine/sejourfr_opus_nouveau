"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useState} from "react";
import {
    ArrowRight,
    BookOpen,
    ClipboardCheck,
    Gavel,
    Globe,
    Headphones,
    Landmark,
    type LucideIcon,
    Mic,
    PenLine,
    Scale,
    Sparkles,
    Target,
    Users,
} from "lucide-react";
import {
    Card,
    Cta,
    GoalBanner,
    LevelCard,
    LevelCardGrid,
    LevelLadder,
    MicroNote,
    ModuleToggle,
    NowCard,
    Pad,
    Section,
    SejourApp,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {civicPlanApi, diagnosticApi, journeyApi, learningPlanApi, progressApi, userContentApi} from "@/lib/api";
import {
    JOURNEY_NEEDS_OBJECTIVE_CTA,
    JOURNEY_NEEDS_OBJECTIVE_TEXT,
    JOURNEY_NEEDS_OBJECTIVE_TITLE,
    journeyTargetPathHref,
} from "@/lib/journey";
import {civicBarTone} from "@/lib/civic-diagnostic";
import {themeHistoriqueHref, themeSlug} from "@/lib/themes";
import {
    ACCUEIL_EVALUEES_CAPTION,
    ACCUEIL_EVALUES_CAPTION_CIVIQUE,
    NON_MESURE_LABEL,
    accueilEchelleLabel,
    accueilEchelleLabelCivique,
    accueilEchelons,
    accueilEchelonsCivique,
    accueilEpreuveBadge,
    accueilEpreuveCta,
    accueilEpreuveOuvreLExercice,
    accueilEpreuveStatut,
    accueilEpreuveTon,
    accueilEvaluees,
    accueilEvaluesCivique,
    progresCiviqueScore,
} from "@/lib/progres";
import {moduleDeLUrl, planHref, type ParcoursModule} from "@/lib/module-switch";
import {
    DIAGNOSTIC_RAPIDE_START_HREF,
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
    CIVIC_THEME_STATE_LABEL,
    niveauCecrlShort,
    canAccessModule,
    type CivicPlanDto,
    type DiagnosticResponse,
    type JourneyDto,
    type LearningPlanDto,
    type PreparationDto,
    type ProgressDto,
} from "@/lib/types";
import {planUnlockHref} from "@/lib/plan-unlock";
import {civicNowCard} from "@/lib/civic-plan";

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
 * ## Ce que l'écran porte, de haut en bas (2026-09-19)
 *
 * Bandeau « Choisissez votre parcours » (démarche absente) → en-tête
 * « Bonjour X » + pastille de démarche → **bascule TCF / Examen civique** →
 * **À faire maintenant** (+ l'invitation à choisir un objectif) → **Où vous en
 * êtes**. Et rien d'autre.
 *
 * 🛑 **Le bas de l'Accueil est SUPPRIMÉ** (arbitrage du propriétaire,
 * 2026-09-19, verbatim : « Dans Accueil aussi supprime tout ça sauf le "outil
 * indépendant non affilié…" ») : l'aperçu « Votre Plan », les deux compteurs de
 * « Votre progression », la carte « Continuez votre diagnostic complet »
 * (`AffinerPlanCard`, supprimée avec son autorité `affinerPlan`) et les deux
 * lignes de « Vos parcours » — la bascule ci-dessus fait déjà ce travail.
 * **Ne pas les réintroduire** : le Plan se lit sur `/plan`, les compteurs de
 * compétences sur `/statistiques` (`ProgresMouvement`, qui les dit autrement),
 * et le diagnostic complet garde sa porte (`/diagnostic-tcf`) depuis Réviser,
 * le Plan et le rapport de diagnostic. Même passe côté mobile.
 *
 * 🛑 **Sans objectif déclaré, on INVITE — on ne ferme rien** (arbitrage du
 * 2026-09-17) : la carte « Choisir mon objectif » reste, elle **s'ajoute** à la
 * carte d'action au-dessus. Miroir de `_objectifTcf` côté mobile.
 *
 * ## Les sources, parcours par parcours
 *
 * | bloc | TCF | Civique |
 * |---|---|---|
 * | à faire maintenant | `/api/diagnostics/current` puis `planNowCard(plan, journey)` | `planIndisponible(prep.civique)` puis `civicPlan.prochaine` |
 * | où vous en êtes | `progres.tcf` (4 épreuves) | `progres.civique` (thèmes) |
 *
 * 🛑 **Le civique n'a AUCUN palier CECRL servi** : pas d'échelle, pas
 * d'objectif — on ne fabrique pas une mesure qui n'existe pas.
 *
 * ## Ce que la maquette ne décide PAS
 *
 * `~/Desktop/grok_ecran` — `screenshots/accueil.png` et `accueil-civ.png`.
 * L'écran est monté sur le **KIT** (`SejourApp wide` → colonne de 1080 px au
 * palier desktop) et dispose ses sections par paires avec
 * `sejourStyles.deskPair`. 🛑 **Le desktop n'ajoute aucun composant**, et une
 * carte seule sur sa rangée la prend en entier — c'est la règle `:only-child`
 * du kit, aucun cas particulier n'est écrit ici.
 *
 * 🛑 Elle est une référence de **mise en page**, jamais une source de données
 * ni de règles. La hiérarchie arbitrée est **inchangée** : une seule action
 * dominante — « À faire maintenant » —, un en-tête sans CTA, une priorité TCF
 * verrouillée qui n'est pas nommée.
 *
 * ⚠️ **Un écart assumé avec la maquette civique**, à rouvrir si besoin : la
 * pastille d'objectif nomme la **démarche** servie (« Objectif :
 * naturalisation », autorité `objectifLabel`) et non le module, que la bascule
 * juste en dessous annonce déjà.
 */
/* --------------------------------------------- « Où vous en êtes » ------- */

/**
 * 🛑 **Miroirs mot pour mot de `home_labels.dart`** : un libellé qui bouge, ce
 * sont deux fichiers dans la même passe.
 */
const SITUATION_TITLE = "Où vous en êtes";

/**
 * Le lien de tête de section, vers le Plan **du module affiché** (maquette v3,
 * 2026-09-24). ⚠️ L'ancienne carte-enveloppe (« Votre niveau par épreuve » /
 * « … par thème » et leurs phrases de cadrage) est supprimée avec elle.
 */
const SITUATION_PLAN_LINK = "Mon plan";

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

/**
 * Le pictogramme de chaque carte. Décoratif : le repère court et l'intitulé
 * disent déjà l'épreuve ou le thème. Miroir mobile : `_kSituationIcon`
 * (`home_screen.dart`).
 */
const SITUATION_EPREUVE_ICON: Record<string, LucideIcon> = {
    TCF_CO: Headphones,
    TCF_CE: BookOpen,
    TCF_EE: PenLine,
    TCF_EO: Mic,
};

const SITUATION_THEME_ICON: Record<string, LucideIcon> = {
    CIV_PRINCIPES: Scale,
    CIV_INSTITUTIONS: Landmark,
    CIV_DROITS_DEVOIRS: Gavel,
    CIV_HISTOIRE_GEO: Globe,
    CIV_SOCIETE: Users,
};

/**
 * 🛑 **Elle ne démarre rien, et elle ne mène plus au Plan** (demande du
 * propriétaire, 2026-09-19) : la ligne d'un thème ouvre **l'historique de ses
 * examens blancs**, la page qui existe déjà — pendant exact du « Voir mes
 * résultats » d'une épreuve TCF mesurée. Le lanceur de série reste au Plan.
 */
const SITUATION_CIVIC_CTA = "Voir mes résultats";

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
    const [journeyCivique, setJourneyCivique] = useState<JourneyDto | null>(null);
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
            const [progression, currentDiagnostic, currentPlan, preparation, planCivique, parcours, parcoursCivique] = await Promise.all([
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
                // 🛑 Le cycle CIVIQUE : « À faire maintenant » y lit son étape
                // depuis D-50 §2, exactement comme le Plan civique.
                journeyApi.getCached("CIVIQUE").catch((): JourneyDto | null => null),
            ]);
            if (cancelled) return;
            setProgres(progression);
            setDiagnostic(currentDiagnostic);
            setPlan(currentPlan);
            setPrep(preparation);
            setCivicPlan(planCivique);
            setJourney(parcours);
            setJourneyCivique(parcoursCivique);
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
    const aUneAction = civique ? Boolean(gateCivique ?? civicPlan) : Boolean(diagnostic);

    return (
        <SejourApp wide className="home">
            {!user.targetProcedure && (
                <Pad>
                    <Link href={journeyTargetPathHref("/dashboard")} className="home-banner">
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
                de parcours de la barre latérale. */}
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
                « TCF IRN » / « Examen civique » de la barre latérale — « Vos
                parcours » a été supprimé de l'Accueil le 2026-09-19. */}
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
                                <ActionCivique
                                    gate={gateCivique}
                                    plan={gateCivique ? null : civicPlan ?? null}
                                    journey={journeyCivique}
                                    free={!canAccessModule(user, "CIVIQUE")}
                                />
                            ) : diagnostic ? (
                                <ActionPrincipale
                                    diagnostic={diagnostic}
                                    plan={plan}
                                    journey={journey}
                                    dismissed={diagnosticDismissed}
                                    onDismiss={() => setDiagnosticDismissed(true)}
                                    free={!canAccessModule(user, "TCF")}
                                />
                            ) : null}
                        </Pad>
                    </Section>
                ) : null}

                {/* 🛑 **L'invitation à déclarer un objectif, et rien d'autre**
                    (l'aperçu « Votre Plan » a été supprimé le 2026-09-19) :
                    elle n'enlève rien à la carte ci-dessus, elle s'ajoute. */}
                <ObjectifManquant civique={civique} journey={journey}/>
            </div>

            {/* ✅ **« Où vous en êtes » ajouté le 2026-09-16** (maquette du
                propriétaire, refait en v3 le 2026-09-24) : l'objectif, puis une
                carte par épreuve — palier, échelle, état en un mot, action.

                🛑 **C'est le SEUL constat de l'écran** depuis le 2026-09-19 :
                « Votre progression » et ses deux compteurs de compétences ont
                été supprimés (ils se lisent sur `/statistiques`).

                🛑 **Aucun appel de plus** : `progres` est déjà dans l'état de
                l'écran, et le même `ProgressDto` porte déjà les 4 épreuves.

                ⚠️ Elle prend **toute la rangée** plutôt que d'entrer dans le
                `deskPair` au-dessus : quatre cartes dans une demi-colonne de
                1080 px se replieraient en une file illisible, et la maquette la
                montre pleine largeur. */}
            <OuVousEnEtes progres={progres} civique={civique}/>

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
                              free,
                          }: {
    diagnostic: DiagnosticResponse;
    plan: LearningPlanDto | null;
    journey: JourneyDto | null;
    dismissed: boolean;
    onDismiss: () => void;
    free: boolean;
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
                    {/* 🛑 **Le bouton porte déjà la décision** (arbitrage du
                        2026-09-12) : « Faire mon diagnostic » LANCE le
                        diagnostic, il n'ouvre pas une page qui redemande de le
                        lancer. Ce marqueur manquait ici — un compte neuf
                        atterrissait sur « Quel examen préparez-vous ? » alors
                        qu'il venait de choisir son parcours. */}
                    <Cta href={DIAGNOSTIC_RAPIDE_START_HREF}>Faire mon diagnostic</Cta>
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
                    {/* « Reprendre mon diagnostic » nomme le geste, donc il le
                        pose ; « Voir l'analyse » ne lance rien et ouvre l'écran
                        tel quel. ⚠️ Sans effet quand le candidat est déjà plus
                        loin que la présentation : l'écran ne saute que ce qu'il
                        y a à sauter. */}
                    <Cta href={analyzing ? "/diagnostic" : DIAGNOSTIC_RAPIDE_START_HREF}>
                        {analyzing ? "Voir l'analyse" : "Reprendre mon diagnostic"}
                    </Cta>
                </div>
            </NowCard>
        );
    }

    return <ActionPlanDuJour plan={plan} journey={journey} free={free}/>;
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
function ActionPlanDuJour({plan, journey, free}: {
    plan: LearningPlanDto | null;
    journey: JourneyDto | null;
    /** 🛑 **Le drapeau d'accès descend jusqu'à l'autorité** (2026-09-20) : sans
     *  lui, l'Accueil ne savait pas qu'il fallait proposer de débloquer, et il
     *  annonçait « Commencer » là où le Plan disait « Débloquer ». */
    free: boolean;
}) {
    const router = useRouter();
    const {start, starting, error, paywallOpen, closePaywall} = usePlanExercise();
    const assessments = usePlanAssessment();

    const carte = plan ? planNowCard(plan, {journey, free}) : null;
    /* 🛑 **Une priorité verrouillée se NOMME ici comme sur le Plan** (demande
       du propriétaire, 2026-09-20).

       ⚠️ **Révoque** « une priorité verrouillée n'est jamais nommée ici » : la
       règle protégeait le rideau de « Mes priorités », qui n'existe plus — le
       Plan nomme l'étape depuis le 2026-09-19 et Réviser depuis le 20. Le seul
       écran à se taire encore était celui-ci, et il annonçait « Continuez votre
       plan personnalisé » pendant que le Plan disait « Expression écrite ·
       Tâche 3 ». Deux écrans, deux réponses, au même instant. */
    const debloquer = carte?.geste === "DEBLOQUER";
    /* 🛑 **Une étape de séries ouvre son écran**, elle ne se lance plus d'ici.
       Le geste ET sa destination viennent de `planNowCard` : cet écran ne
       redéduit ni « est-ce une série ? » ni l'adresse. */
    const ouvrirEtape = carte?.geste === "OUVRIR_ETAPE" ? carte.etapeHref : null;
    const mesure = carte?.mesure ?? null;
    const exercise = carte?.exercise ?? null;
    /* 🛑 **Un raccourci verrouillé n'en est pas un.** La priorité du jour peut
       être une compétence **à acquérir** — désignée avec son `locked`, le
       serveur ayant vérifié qu'elle n'est pas ouverte par sa place n°1 —, et
       « Commencer directement » enverrait alors un compte gratuit droit sur un
       403. Le Plan, lui, reste ouvert : on garde « Continuer mon plan », qui
       porte le cadenas et l'offre. */
    /* 🛑 **Le geste vient de l'autorité**, jamais redéduit : un verrou ouvre
       l'écran de transition (A145), une action ouvre l'action. */
    const startable = carte !== null && carte.geste === "LANCER"
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
                    {debloquer && carte ? (
                        <Cta onClick={() => router.push(planUnlockHref("TCF"))}>
                            {carte.cta}
                        </Cta>
                    ) : (
                        <Cta href="/plan">Continuer mon plan</Cta>
                    )}
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
                    {/* 🛑 **Le raccourci OUVRE l'étape** au lieu de lancer sa
                        série : même écran que la ligne du cycle, même
                        destination servie. */}
                    {ouvrirEtape && carte && (
                        <button
                            type="button"
                            className="home-now-later"
                            onClick={() => router.push(ouvrirEtape)}
                        >
                            {carte.cta}
                        </button>
                    )}
                </div>
            </NowCard>
            {(error ?? assessments.error) && (
                <p className={sejourStyles.tiny} role="alert">{error ?? assessments.error}</p>
            )}
            <PaywallSheet
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
function ActionCivique({gate, plan, journey, free}: {
    gate: PlanIndisponible | null;
    plan: CivicPlanDto | null;
    journey: JourneyDto | null;
    free: boolean;
}) {
    const router = useRouter();
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

    /* 🛑 **L'Accueil lit le CYCLE, comme le Plan civique** (2026-09-20).
       ⚠️ **Révoque** la lecture de `plan.prochaine` : le Plan civique annonce
       l'étape du cycle depuis D-50 §2, donc les deux écrans annonçaient deux
       reprises différentes au même candidat, au même instant. C'est la
       troisième fois que ce même écart se rouvre par la bande — après Réviser
       (A149), après le Plan lui-même. */
    const carte = plan ? civicNowCard(plan, {journey, free}) : null;
    /* `null` est un cas NORMAL : plus rien à faire, la carte disparaît. */
    if (!carte) return null;
    const debloquer = carte.geste === "DEBLOQUER";
    /* 🛑 **Une unité qui se travaille par séries ouvre son écran** — le geste et
       sa destination viennent de `civicNowCard`, jamais d'une condition écrite
       ici. */
    const ouvrirEtape = carte.geste === "OUVRIR_ETAPE" ? carte.etapeHref : null;

    return (
        <NowCard
            icon={Landmark}
            title={carte.title}
            subtitle={carte.subtitle ?? undefined}
            badge={carte.badge ?? "Votre priorité du jour"}
            objectiveLabel={carte.objectiveLabel ?? undefined}
            objective={carte.objective ?? undefined}
        >
            {/* 🛑 **Cette carte ne DÉMARRE toujours rien** : elle mène au Plan
                civique, seul porteur du lanceur de série — un second point de
                départ dupliquerait la gestion du 403. Seul le geste d'ACHAT
                part d'ici, vers l'écran de transition (A145). */}
            <div className="home-now-actions">
                {debloquer ? (
                    <Cta variant="blue" onClick={() => router.push(planUnlockHref("CIVIQUE"))}>
                        {carte.cta}
                    </Cta>
                ) : ouvrirEtape ? (
                    <Cta href={ouvrirEtape} variant="blue">{carte.cta}</Cta>
                ) : (
                    <Cta href={planHref("CIVIQUE")} variant="blue">Continuer mon plan</Cta>
                )}
            </div>
        </NowCard>
    );
}

/**
 * **Où vous en êtes** — le titre et son lien « Mon plan », le bandeau
 * d'objectif, puis **une carte par épreuve** en grille, chacune portant son
 * palier en gros et son **échelle CECRL**.
 *
 * ⚠️ **Refait le 2026-09-24 sur la maquette v3 du propriétaire** : la liste
 * verticale dans une seule carte (v2, 2026-09-16) devient une grille de cartes
 * séparées — deux colonnes sur téléphone, quatre sur une rangée quand la
 * grille est assez large.
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
        <Section
            title={SITUATION_TITLE}
            lead
            action={{label: SITUATION_PLAN_LINK, href: planHref("TCF")}}
        >
            <Pad>
                {/* 🛑 **Le bandeau passe AU-DESSUS des cartes** (maquette) : il
                    annonce vers quoi on va avant de montrer où on en est. Sans
                    démarche déclarée, pas de bandeau — on ne devine pas
                    l'objectif d'un candidat qui n'en a pas donné, et le
                    compteur part avec lui. */}
                {objectif && (
                    <GoalBanner
                        label={SITUATION_GOAL_LABEL}
                        value={situationGoalText(niveauCecrlShort(objectif))}
                        count={compte?.faites}
                        total={compte?.total}
                        caption={ACCUEIL_EVALUEES_CAPTION}
                    />
                )}
                <LevelCardGrid>
                    {epreuves.map((e) => {
                        /* 🛑 **Trois issues, aucune inventée.**
                           1. Épreuve jamais mesurée dont le serveur dit par
                              quoi la mesurer ⇒ on **lance** cette mesure, sans
                              étape intermédiaire.
                           2. Quelque chose à faire, mais rien à lancer
                              (épreuve en progression ; ou descripteur absent —
                              client ancien) ⇒ la fiche du domaine, le
                              comportement historique.
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
                            <LevelCard
                                key={e.epreuve}
                                mark={planDomainShort(domaine)}
                                icon={SITUATION_EPREUVE_ICON[e.epreuve] ?? BookOpen}
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
                                   MANQUE : mesurer une épreuve jamais évaluée.
                                   Relire un résultat reste un lien. */
                                ctaPrimary={!mesuree}
                                busy={assessments.starting === e.epreuve}
                                href={mesure ? null : href}
                                onClick={mesure
                                    ? () => void assessments.start(mesure)
                                    : undefined}
                            />
                        );
                    })}
                </LevelCardGrid>
                {/* ⚠️ **Hors maquette, et conservé volontairement** : elle dit
                    ce qui fait bouger le palier (diagnostics et épreuves
                    complètes, pas les séries). Sans elle, un candidat qui vient
                    d'enchaîner des entraînements lit un niveau inchangé et
                    croit à une panne. */}
                <MicroNote>{SITUATION_NOTE}</MicroNote>
                {assessments.error && (
                    <p className={sejourStyles.tiny} role="alert">{assessments.error}</p>
                )}
            </Pad>
            <PaywallSheet
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
 * 2026-09-16) : titre et lien vers le Plan, bande de tête, puis une carte par
 * thème avec son repère, son pictogramme, son statut à pastille colorée, ses
 * crans et son action.
 *
 * 🛑 **Adapté, jamais transposé.** Le civique n'a **ni palier CECRL ni
 * objectif CECRL servi** : pas de palier en gros, pas d'« Atteindre B2
 * partout ». La bande de tête dit ce qui EST servi — le dernier résultat et son
 * seuil (`progresCiviqueScore`, l'autorité déjà en place) — et le compteur
 * porte sur les **thèmes** de la liste servie.
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
        <Section
            title={SITUATION_TITLE}
            lead
            action={{label: SITUATION_PLAN_LINK, href: planHref("CIVIQUE")}}
        >
            <Pad>
                {dernier && (
                    <GoalBanner
                        label={SITUATION_CIVIC_RESULT_LABEL}
                        value={dernier}
                        count={compte?.faites}
                        total={compte?.total}
                        caption={ACCUEIL_EVALUES_CAPTION_CIVIQUE}
                    />
                )}
                <LevelCardGrid>
                    {themes.map((t, rang) => (
                        <LevelCard
                            key={t.themeId}
                            /* 🛑 **Le repère est le RANG SERVI**, pas un code
                               abrégé : un thème n'a aucun code de deux lettres
                               servi (`CIV_PRINCIPES` n'en est pas un), et en
                               inventer un serait fabriquer un libellé. */
                            mark={`${rang + 1}`}
                            icon={SITUATION_THEME_ICON[t.code] ?? BookOpen}
                            title={t.label}
                            /* 🛑 L'état arrive **servi** : on pose son libellé
                               gelé, on ne classe aucun nombre. `NON_EVALUE`
                               reste neutre, jamais ambre. */
                            status={t.etat === "NON_EVALUE"
                                ? NON_MESURE_LABEL
                                : CIVIC_THEME_STATE_LABEL[t.etat]}
                            tone={civicBarTone(t.etat)}
                            /* 🛑 **Aucun palier CECRL en civique** : le civique
                               se mesure en thèmes, jamais en paliers. La carte
                               n'a donc pas de valeur en gros. */
                            level={null}
                            measured={t.etat !== "NON_EVALUE"}
                            /* 🛑 **Le même cran segmenté que le TCF**, sur la
                               seule donnée servie pour un thème : son `etat`
                               (`accueilEchelonsCivique`). Sans libellés : les
                               trois états ne tiennent pas sous une demi-carte,
                               et la pastille de statut les dit déjà. */
                            scale={
                                <LevelLadder
                                    steps={accueilEchelonsCivique(t.etat)}
                                    label={accueilEchelleLabelCivique(t.etat)}
                                    dim={t.etat === "NON_EVALUE"}
                                    labels={false}
                                />
                            }
                            cta={SITUATION_CIVIC_CTA}
                            /* 🛑 **« Vos résultats » du thème**, le pendant
                               civique de l'écran de résultats d'une épreuve
                               TCF (2026-09-19). */
                            href={themeHistoriqueHref(themeSlug(t.code))}
                        />
                    ))}
                </LevelCardGrid>
            </Pad>
        </Section>
    );
}

/**
 * **L'invitation à déclarer un objectif**, quand le candidat n'en a pas.
 *
 * 🛑 **Elle n'enlève rien** (arbitrage du propriétaire, 2026-09-17) : le Plan
 * n'exige **pas** d'objectif déclaré, et la carte « À faire maintenant » reste
 * servie au-dessus, entière. C'est une invitation, jamais une porte fermée — et
 * elle doit se lire partout où une carte « À faire maintenant » se lit, sans
 * quoi le candidat ne découvre jamais que déclarer sa démarche lui ouvre un
 * parcours.
 *
 * 🛑 **TCF seulement** : le parcours est un objet TCF, le civique n'en a pas.
 *
 * ⚠️ Elle vivait dans `VotrePlan`, l'aperçu du Plan, **supprimé le 2026-09-19**
 * (demande du propriétaire). Miroir de `_objectifTcf`
 * (`mobile_sejourfr/lib/screens/home/home_screen.dart`).
 */
function ObjectifManquant({civique, journey}: {
    civique: boolean;
    journey: JourneyDto | null;
}) {
    if (civique || journey?.state !== "NEEDS_OBJECTIVE") return null;
    return (
        <Section title={JOURNEY_NEEDS_OBJECTIVE_TITLE}>
            <Pad>
                <Card>
                    <p className={sejourStyles.tiny}>{JOURNEY_NEEDS_OBJECTIVE_TEXT}</p>
                    <Cta href={journeyTargetPathHref("/dashboard")}>{JOURNEY_NEEDS_OBJECTIVE_CTA}</Cta>
                </Card>
            </Pad>
        </Section>
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
                <div className="sk-grid">
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


  /* ===== « Où vous en êtes » ===== */
  /* 🛑 **Plus une seule règle de cet écran.** Toute la section vit dans le KIT
     depuis la 3ᵉ passe du 2026-09-16 ; maquette v3 du 2026-09-24 : Section
     lead + action, GoalBanner, LevelCardGrid, LevelCard, LevelLadder et MicroNote, avec
     leur miroir Flutter dans la même passe — c'est ce qui garantit que les deux
     fronts montrent la même carte. Les classes .home-situation-title et
     .home-situation-copy sont SUPPRIMÉES avec leurs appelants, comme l'étaient
     déjà .home-situation-grid / -card / -head / -name / -badge / -statut et
     .home-goal. */

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
