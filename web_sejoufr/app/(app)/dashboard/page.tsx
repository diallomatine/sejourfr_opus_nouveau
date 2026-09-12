"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useMemo, useState} from "react";
import {ArrowRight, ClipboardCheck, Landmark, Sparkles, Target} from "lucide-react";
import {AffinerPlanCard} from "@/app/_components/plan/AffinerPlanCard";
import {
    Card,
    Cta,
    ModuleToggle,
    NowCard,
    Pad,
    PathRow,
    Section,
    SejourApp,
    Stack,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {civicPlanApi, diagnosticApi, learningPlanApi, progressApi, userContentApi} from "@/lib/api";
import {civicPath, civicPathCounter, civicPlanRaison} from "@/lib/civic-plan";
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
    parcoursDeLaTache,
    planDomainLabel,
    planSectionEpreuve,
    planTaskBadge,
    type PlanPathStep,
} from "@/lib/plan-domain";
import {
    diagnosticCompletedExerciseCount,
    diagnosticDashboardState,
    recommendedExerciseHref,
} from "@/lib/diagnostic";
import {
    CIVIC_MAITRISE_LABEL,
    type CivicPlanCibleDto,
    type CivicPlanDto,
    type DiagnosticResponse,
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
            const [progression, currentDiagnostic, currentPlan, preparation, planCivique] = await Promise.all([
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
            ]);
            if (cancelled) return;
            setProgres(progression);
            setDiagnostic(currentDiagnostic);
            setPlan(currentPlan);
            setPrep(preparation);
            setCivicPlan(planCivique);
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
                    plan={plan}
                    cible={cibleCivique}
                />
            </div>

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
                              dismissed,
                              onDismiss,
                          }: {
    diagnostic: DiagnosticResponse;
    plan: LearningPlanDto | null;
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
                subtitle="2 exercices · ≈ 8 à 10 min"
                badge="Votre point de départ"
                objective="On analyse votre écrit et votre oral pour construire votre premier plan."
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
                subtitle={`${done} / 2 terminé${done > 1 ? "s" : ""}`}
                badge="Diagnostic en cours"
                objective={
                    analyzing
                        ? "Vos deux réponses sont enregistrées ; vous pouvez revenir voir le résultat."
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

    const live = plan?.currentPriority ?? null;
    /* 🛑 **Une priorité verrouillée n'est jamais NOMMÉE ici.** Depuis que le
       Plan sait aussi désigner une compétence *à acquérir*, la priorité n°1
       peut porter un cadenas — et « Mes priorités » la floute alors. L'écrire
       en clair sur l'Accueil démentirait ce rideau. Miroir du mobile
       (`PlanPriorityHomeCard`, `home_screen.dart`), qui retombe déjà sur son
       texte générique. */
    const priority = live && !live.locked ? live : null;
    const exercise = priority?.recommendedExercise ?? null;
    /* 🛑 **Un raccourci verrouillé n'en est pas un.** La priorité du jour peut
       être une compétence **à acquérir** — désignée avec son `locked`, le
       serveur ayant vérifié qu'elle n'est pas ouverte par sa place n°1 —, et
       « Commencer directement » enverrait alors un compte gratuit droit sur un
       403. Le Plan, lui, reste ouvert : on garde « Continuer mon plan », qui
       porte le cadenas et l'offre. */
    const startable = Boolean(exercise) && !exercise?.locked;
    return (
        <NowCard
            icon={Target}
            /* Le titre de la priorité, et rien d'autre : `explanation` est le
               constat d'une production déjà faite — il raconte le passé sur une
               carte qui annonce l'action à mener, et il vit déjà dans le Plan. */
            title={priority?.title ?? "Continuez votre plan personnalisé"}
            subtitle={exercise ? `${exercise.title} · ${exercise.estimatedMinutes} min` : undefined}
            badge="Votre priorité du jour"
        >
            <div className="home-now-actions">
                <Cta href="/plan">Continuer mon plan</Cta>
                {startable && exercise && (
                    <Link href={recommendedExerciseHref(exercise)} className="home-now-later">
                        Commencer directement
                    </Link>
                )}
            </div>
        </NowCard>
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
function VotrePlan({civique, plan, cible}: {
    civique: boolean;
    plan: LearningPlanDto | null;
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

    const priority = plan?.currentPriority ?? null;
    if (!plan || !priority || priority.locked) return null;
    const path = parcoursDeLaTache(plan, priority);
    if (!path) return null;
    const epreuve = planSectionEpreuve(priority.section);
    return (
        <PlanApercu
            title={`${planDomainLabel(epreuve)} · ${planTaskBadge(path.tacheNumero)}`}
            subtitle={priority.title}
            counter={path.counterLabel}
            steps={path.steps}
            href={planHref("TCF")}
        />
    );
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
    counter: string;
    steps: PlanPathStep[];
    href: string;
}) {
    return (
        <Section title="Votre Plan">
            <Pad>
                <Card>
                    <div className="home-plan-head">
                        <p className={sejourStyles.label}>Priorité actuelle</p>
                        <span className={sejourStyles.tiny}>{counter}</span>
                    </div>
                    <p className="home-plan-title">{title}</p>
                    {subtitle && (
                        <p className={sejourStyles.tiny} style={{margin: "2px 0 10px"}}>
                            {subtitle}
                        </p>
                    )}
                    {apercuSteps(steps).map((step, index) => (
                        <PathRow key={`${step.label}-${index}`} label={step.label} state={step.state}/>
                    ))}
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
