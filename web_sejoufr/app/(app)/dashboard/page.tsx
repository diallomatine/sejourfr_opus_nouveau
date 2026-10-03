"use client";

import Link from "next/link";
import {useEffect, useRef, useState} from "react";
import {
    ActionCard,
    BlockError,
    BlockSkeleton,
    Card,
    Cta,
    ObjCard,
    PageHead,
    Pad,
    Section,
    SejourApp,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {IconEar, IconMap, IconShield, IconSparkle, IconTarget} from "@/app/_components/shell/ShellIcons";
import {useGesteEtapeCivique, useGesteEtapeTcf} from "@/app/_components/plan/now-card-gestes";
import {civicPlanApi, dashboardApi, diagnosticApi, journeyApi, learningPlanApi, progressApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
    ACCUEIL_BLOCK_ERROR,
    ACCUEIL_CIVIQUE_CTA,
    ACCUEIL_CIVIQUE_LABEL,
    ACCUEIL_CIVIQUE_METRIC_EXAMEN,
    ACCUEIL_CIVIQUE_METRIC_PARCOURS,
    ACCUEIL_CIVIQUE_METRIC_SERIES,
    ACCUEIL_CIVIQUE_OBJECTIF_TITRE,
    ACCUEIL_CIVIQUE_SEUIL,
    ACCUEIL_DIAGNOSTIC_CTA_ANALYSIS,
    ACCUEIL_DIAGNOSTIC_CTA_RESUME,
    ACCUEIL_DIAGNOSTIC_LABEL,
    ACCUEIL_DIAGNOSTIC_RESUME_TEXT,
    ACCUEIL_DIAGNOSTIC_TITLE_ANALYSIS,
    ACCUEIL_DIAGNOSTIC_TITLE_RESUME,
    ACCUEIL_NOW_TITLE,
    ACCUEIL_OBJECTIVES_TITLE,
    ACCUEIL_PARCOURS_BANNER_LABEL,
    ACCUEIL_PARCOURS_BANNER_TEXT,
    ACCUEIL_PARCOURS_BANNER_TITLE,
    ACCUEIL_RETRY,
    ACCUEIL_SUBTITLE,
    ACCUEIL_TCF_CTA,
    ACCUEIL_TCF_LABEL,
    ACCUEIL_TCF_METRIC_CYCLE,
    ACCUEIL_TCF_METRIC_PROGRESSION,
    ACCUEIL_TCF_NB_EPREUVES,
    accueilBonjour,
    accueilCiviqueActionMeta,
    accueilCiviqueDescription,
    accueilCycleLabel,
    accueilCycleRatio,
    accueilEpreuvesAuNiveau,
    accueilPourcentage,
    accueilSeries,
    accueilTcfActionMeta,
    accueilTcfDescription,
    accueilTcfMetricEpreuves,
    accueilTcfObjectifTitre,
    accueilTcfProgression,
} from "@/lib/accueil";
import {civicNowCard} from "@/lib/civic-plan";
import {
    diagnosticAnalyzingObjective,
    diagnosticCompletedExerciseCount,
    diagnosticCountLabel,
    diagnosticDashboardState,
    diagnosticExerciseCount,
} from "@/lib/diagnostic";
import {
    JOURNEY_NEEDS_OBJECTIVE_CTA,
    JOURNEY_NEEDS_OBJECTIVE_TEXT,
    JOURNEY_NEEDS_OBJECTIVE_TITLE,
    JOURNEY_UP_TO_DATE_TITLE,
    journeyTargetPathHref,
} from "@/lib/journey";
import {planHref} from "@/lib/module-switch";
import {planNowCard} from "@/lib/plan-domain";
import {DIAGNOSTIC_RAPIDE_START_HREF, objectifKicker} from "@/lib/preparation";
import {progressionHref} from "@/lib/progression";
import {avancementSeriesCivique} from "@/lib/reviser";
import {
    type CivicPlanDto,
    type DashboardSummaryResponse,
    type DiagnosticResponse,
    type JourneyDto,
    type LearningPlanDto,
    type ProgressDto,
} from "@/lib/types";

/**
 * 🛑 **Carte « Reprenez votre diagnostic » MASQUÉE pour tous** (2026-10-03,
 * décision du propriétaire) : une fois le compte créé, le diagnostic, ce sont
 * les examens blancs du premier cycle du Plan (D-69). Le diagnostic rapide se
 * passe AVANT le compte (`/`, `/reussir`, `/diagnostic`). Code gardé : repasser à
 * `true` suffit. Miroir mobile : `kHomeShowDiagnosticCard`.
 */
const ACCUEIL_SHOW_DIAGNOSTIC_CARD = false;

/**
 * **L'Accueil** de l'espace connecté — Navigation v2, phase 3 (2026-10-03).
 *
 * Maquette : `docs/redesign/sejourfr-navigation-web.html`, écran `#accueil`.
 * Ordre web (D2-A) : en-tête → **À faire maintenant** (deux cartes, une par
 * module) → **Mes objectifs** (deux cartes dégradées). Tout est monté sur le
 * KIT (`PageHead`, `ActionCard`, `ObjCard`, `BlockSkeleton`, `BlockError`) ;
 * l'écran n'a aucun style à lui.
 *
 * ⚠️ **Ce qui est parti** (X7) : la bascule TCF / Civique et `?module=` (la
 * barre latérale porte les deux modules ; un `?module=` dans l'adresse est
 * ignoré), « Où vous en êtes » (remplacé par « Mes objectifs »), les CTA
 * secondaires de la carte d'action. **Ce qui reste** : la carte de diagnostic
 * en cours (au-dessus de « À faire maintenant », MASQUÉE pour tous depuis le
 * 2026-10-03, cf. `ACCUEIL_SHOW_DIAGNOSTIC_CARD`) et l'invitation à choisir son
 * objectif.
 *
 * 🛑 **Chaque bloc charge, échoue et se réessaie SEUL** (brief §7) : un
 * squelette aux dimensions de sa carte, puis un message + « Réessayer » à sa
 * place — le reste de l'écran reste utilisable.
 *
 * 🛑 **Les gestes sont SERVIS** : `planNowCard` / `civicNowCard` décident de
 * LANCER, OUVRIR_ETAPE, DEBLOQUER ou AUCUN — l'Accueil ne redéduit ni un
 * verrou d'un rang ni une adresse.
 */

export default function DashboardPage() {
    const {user, status} = useAuth();
    const actif = status === "authenticated" && Boolean(user);

    const summary = useSource<DashboardSummaryResponse>(actif, () => dashboardApi.summaryCached());
    const progres = useSource<ProgressDto>(actif, () => progressApi.get());
    const plan = useSource<LearningPlanDto>(actif, () => learningPlanApi.getCached());
    const journeyTcf = useSource<JourneyDto>(actif, () => journeyApi.getCached());
    const journeyCivique = useSource<JourneyDto>(actif, () => journeyApi.getCached("CIVIQUE"));
    const civicPlan = useSource<CivicPlanDto>(actif, () => civicPlanApi.getCached());
    /* Best-effort : sans diagnostic lisible, la carte de reprise n'existe pas. */
    const diagnostic = useSource<DiagnosticResponse>(actif, () => diagnosticApi.currentCached());

    if (status === "loading") return <AccueilSquelette/>;
    if (!user) {
        return (
            <SejourApp className={sejourStyles.home}>
                <Pad>
                    <p className={sejourStyles.tiny}>
                        Session expirée.{" "}
                        <Link href="/connexion">Se reconnecter</Link>
                    </p>
                </Pad>
            </SejourApp>
        );
    }

    return (
        <SejourApp className={sejourStyles.home}>
            {/* Compte sans démarche déclarée : la seule chose qui manque pour
                personnaliser la préparation (miroir de `HomeBanner`). */}
            {!user.targetProcedure && (
                <Pad>
                    <div className={sejourStyles.homeStackBottom}>
                        <ActionCard
                            module="tcf"
                            icon={<IconTarget/>}
                            label={ACCUEIL_PARCOURS_BANNER_LABEL}
                            title={ACCUEIL_PARCOURS_BANNER_TITLE}
                            meta={ACCUEIL_PARCOURS_BANNER_TEXT}
                            cta={{label: JOURNEY_NEEDS_OBJECTIVE_CTA, href: journeyTargetPathHref("/dashboard")}}
                            block
                        />
                    </div>
                </Pad>
            )}

            <Pad>
                <PageHead
                    kicker={objectifKicker(user.targetProcedure)}
                    title={accueilBonjour(user.firstName, user.lastName)}
                    subtitle={ACCUEIL_SUBTITLE}
                />
            </Pad>

            {/* Le diagnostic en cours vit AU-DESSUS de « À faire maintenant » : le
                titre reste collé aux deux cartes de module, comme sur le mobile. */}
            {ACCUEIL_SHOW_DIAGNOSTIC_CARD && diagnostic.data && (
                <Pad className={sejourStyles.pageBody}>
                    <CarteDiagnostic diagnostic={diagnostic.data}/>
                </Pad>
            )}

            <Section title={ACCUEIL_NOW_TITLE}>
                <Pad>
                    <div className={sejourStyles.homeGrid}>
                        <ActionTcf
                            plan={plan}
                            journey={journeyTcf}
                        />
                        <ActionCivique
                            plan={civicPlan}
                            journey={journeyCivique}
                        />
                    </div>
                </Pad>
            </Section>

            {/* 🛑 **L'invitation à déclarer un objectif** (parcours TCF
                `NEEDS_OBJECTIVE`) : elle s'AJOUTE aux cartes d'action, elle ne
                ferme rien. Miroir de `_objectifADeclarer`. */}
            {journeyTcf.data?.state === "NEEDS_OBJECTIVE" && (
                <Section title={JOURNEY_NEEDS_OBJECTIVE_TITLE}>
                    <Pad>
                        <Card>
                            <p className={sejourStyles.tiny}>{JOURNEY_NEEDS_OBJECTIVE_TEXT}</p>
                            <Cta href={journeyTargetPathHref("/dashboard")}>{JOURNEY_NEEDS_OBJECTIVE_CTA}</Cta>
                        </Card>
                    </Pad>
                </Section>
            )}

            <Section title={ACCUEIL_OBJECTIVES_TITLE}>
                <Pad>
                    <div className={sejourStyles.homeGrid}>
                        <ObjectifTcf
                            cible={user.targetLevel ?? null}
                            summary={summary}
                            progres={progres}
                            journey={journeyTcf}
                        />
                        <ObjectifCivique summary={summary}/>
                    </div>
                </Pad>
            </Section>
        </SejourApp>
    );
}

/* ================================================================ Données */

interface Source<T> {
    data: T | undefined;
    error: boolean;
    loading: boolean;
    reload: () => void;
}

/**
 * Une lecture d'un bloc : chargée une fois, réessayable seule. Les lecteurs
 * passés sont ceux, EN CACHE, des autres écrans (Plan, Réviser, barre
 * latérale) — l'Accueil n'ajoute aucune lecture propre.
 */
function useSource<T>(enabled: boolean, load: () => Promise<T>): Source<T> {
    const loadRef = useRef(load);
    useEffect(() => {
        loadRef.current = load;
    });
    const [state, setState] = useState<{data: T | undefined; error: boolean}>({data: undefined, error: false});
    const [tentative, setTentative] = useState(0);

    useEffect(() => {
        if (!enabled) return;
        let vivant = true;
        loadRef
            .current()
            .then((data) => {
                if (vivant) setState({data, error: false});
            })
            .catch(() => {
                if (vivant) setState((s) => ({data: s.data, error: true}));
            });
        return () => {
            vivant = false;
        };
    }, [enabled, tentative]);

    return {
        data: state.data,
        error: state.error,
        loading: enabled && state.data === undefined && !state.error,
        reload: () => {
            setState((s) => ({data: s.data, error: false}));
            setTentative((n) => n + 1);
        },
    };
}

/** L'état d'un bloc qui lit plusieurs sources. */
function etatBloc(sources: Array<Source<unknown>>): "loading" | "error" | "ready" {
    if (sources.some((s) => s.error)) return "error";
    if (sources.some((s) => s.loading)) return "loading";
    return "ready";
}

function reessayer(sources: Array<Source<unknown>>): () => void {
    return () => sources.filter((s) => s.error).forEach((s) => s.reload());
}

/* ======================================================== À faire maintenant */

/**
 * **La carte TCF** — l'action servie par `planNowCard`, la même autorité que
 * le Plan et Réviser.
 *
 * 🛑 **Le geste est celui du « Continuer » du Plan** : `LANCER` démarre la
 * mesure ou l'exercice par les lanceurs du Plan (`usePlanAssessment`,
 * `usePlanExercise`), `OUVRIR_ETAPE` ouvre l'écran de l'étape servi,
 * `DEBLOQUER` l'écran de transition, `AUCUN` rien — carte neutre, sans bouton.
 */
function ActionTcf({plan, journey}: {
    plan: Source<LearningPlanDto>;
    journey: Source<JourneyDto>;
}) {
    const geste = useGesteEtapeTcf("dashboard");

    const etat = etatBloc([plan, journey]);
    if (etat === "loading") return <BlockSkeleton height={154}/>;
    if (etat === "error" || !plan.data) {
        return <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={reessayer([plan, journey])}/>;
    }

    const vue = planNowCard(plan.data, {journey: journey.data ?? null});
    if (!vue) return <CarteFinDeCycle module="tcf"/>;

    /* 🛑 Le libellé suit le droit réel : un verrou se DIT (« Débloquer cette
       étape »), il ne se déguise pas en « Continuer » — `useGesteEtapeTcf`. */
    const cta = geste.cta(vue);
    const erreur = geste.erreur;

    return (
        <>
            <ActionCard
                module="tcf"
                icon={<IconEar/>}
                label={ACCUEIL_TCF_LABEL}
                title={vue.title}
                meta={accueilTcfActionMeta(vue)}
                badge={vue.section}
                cta={cta}
                block
            >
                {vue.geste === "AUCUN" && vue.lines[0] ? (
                    <p className={sejourStyles.actionNote}>{vue.lines[0]}</p>
                ) : null}
                {vue.note ? <p className={sejourStyles.actionNote}>{vue.note}</p> : null}
                {erreur ? <p className={sejourStyles.actionNote} role="alert">{erreur}</p> : null}
            </ActionCard>
            {geste.paywall(journey.data?.journeyId)}
        </>
    );
}

/**
 * **La carte civique** — l'action servie par `civicNowCard`, la même autorité
 * que le Plan civique ; titre, méta et geste suivent le TYPE de l'étape
 * courante (examen de thème, unité officielle, cible du plan dérivé).
 *
 * 🛑 L'examen de thème part du lanceur partagé avec le Plan
 * (`useMockExamLauncher`) ; une unité par séries ouvre son écran ; une cible
 * du plan dérivé mène au Plan civique, seul porteur de son lanceur de série
 * (le « Continuer » de l'ancien Accueil).
 */
function ActionCivique({plan, journey}: {
    plan: Source<CivicPlanDto>;
    journey: Source<JourneyDto>;
}) {
    const geste = useGesteEtapeCivique("dashboard");

    const etat = etatBloc([plan, journey]);
    if (etat === "loading") return <BlockSkeleton height={154}/>;
    if (etat === "error" || !plan.data) {
        return <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={reessayer([plan, journey])}/>;
    }

    const carte = civicNowCard(plan.data, {journey: journey.data ?? null, lancerExamen: true});
    if (!carte) return <CarteFinDeCycle module="civique"/>;

    const cta = geste.cta(carte);

    return (
        <>
            <ActionCard
                module="civique"
                icon={<IconShield/>}
                label={ACCUEIL_CIVIQUE_LABEL}
                title={carte.title}
                meta={accueilCiviqueActionMeta(carte)}
                badge={carte.badge}
                cta={cta}
                block
            >
                {carte.note ? <p className={sejourStyles.actionNote}>{carte.note}</p> : null}
            </ActionCard>
            {geste.paywall(journey.data?.journeyId)}
        </>
    );
}

/**
 * Plus d'étape à annoncer (cycle terminé, parcours à jour) : la carte le dit
 * et mène au Plan du module, où vit « Actualiser mon plan ». Miroir mobile.
 */
function CarteFinDeCycle({module}: {module: "tcf" | "civique"}) {
    const tcf = module === "tcf";
    return (
        <ActionCard
            module={module}
            icon={tcf ? <IconEar/> : <IconShield/>}
            label={tcf ? ACCUEIL_TCF_LABEL : ACCUEIL_CIVIQUE_LABEL}
            title={JOURNEY_UP_TO_DATE_TITLE}
            cta={{label: tcf ? ACCUEIL_TCF_CTA : ACCUEIL_CIVIQUE_CTA, href: planHref(tcf ? "TCF" : "CIVIQUE")}}
            block
        />
    );
}

/**
 * **Le diagnostic rapide commencé** — gardé (X7), au-dessus des cartes
 * d'action, et seulement quand il existe. « Reprendre » relance l'étape où
 * le candidat s'est arrêté ; « Voir l'analyse » ouvre l'écran tel quel.
 */
function CarteDiagnostic({diagnostic}: {diagnostic: DiagnosticResponse}) {
    if (diagnosticDashboardState(diagnostic) !== "IN_PROGRESS") return null;
    const analyse = diagnostic.status === "ANALYZING" || diagnostic.nextStep === "ANALYSIS";
    return (
        <div className={sejourStyles.homeStackBottom}>
            <ActionCard
                module="tcf"
                icon={<IconSparkle/>}
                label={ACCUEIL_DIAGNOSTIC_LABEL}
                title={analyse ? ACCUEIL_DIAGNOSTIC_TITLE_ANALYSIS : ACCUEIL_DIAGNOSTIC_TITLE_RESUME}
                meta={diagnosticCountLabel(
                    diagnosticCompletedExerciseCount(diagnostic),
                    diagnosticExerciseCount(diagnostic),
                )}
                cta={analyse
                    ? {label: ACCUEIL_DIAGNOSTIC_CTA_ANALYSIS, href: "/diagnostic"}
                    : {label: ACCUEIL_DIAGNOSTIC_CTA_RESUME, href: DIAGNOSTIC_RAPIDE_START_HREF}}
                block
            >
                <p className={sejourStyles.actionNote}>
                    {analyse ? diagnosticAnalyzingObjective(diagnostic.format) : ACCUEIL_DIAGNOSTIC_RESUME_TEXT}
                </p>
            </ActionCard>
        </div>
    );
}

/* =========================================================== Mes objectifs */

/**
 * **La carte TCF** : barre = avancement du cycle en cours (D4-B, servi) ;
 * métriques = niveau actuel estimé → cible, épreuves au niveau cible (statut
 * servi), numéro du cycle. Une valeur absente est masquée.
 */
function ObjectifTcf({cible, summary, progres, journey}: {
    cible: DashboardCibleTcf;
    summary: Source<DashboardSummaryResponse>;
    progres: Source<ProgressDto>;
    journey: Source<JourneyDto>;
}) {
    const etat = etatBloc([summary, progres, journey]);
    if (etat === "loading") return <BlockSkeleton height={280} radius={30}/>;
    if (etat === "error" || !summary.data) {
        return <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={reessayer([summary, progres, journey])}/>;
    }
    const cycle = journey.data?.cycle ?? null;
    const metrics = [
        {value: accueilTcfProgression(summary.data.estimatedTcfLevel, cible), label: ACCUEIL_TCF_METRIC_PROGRESSION},
    ];
    if (progres.data) {
        metrics.push({
            value: accueilSeries(accueilEpreuvesAuNiveau(progres.data.tcf.epreuves), ACCUEIL_TCF_NB_EPREUVES),
            label: accueilTcfMetricEpreuves(cible),
        });
    }
    if (cycle) metrics.push({value: accueilCycleLabel(cycle), label: ACCUEIL_TCF_METRIC_CYCLE});

    return (
        <ObjCard
            module="tcf"
            icon={<IconMap/>}
            pill={ACCUEIL_TCF_LABEL}
            title={accueilTcfObjectifTitre(cible)}
            description={accueilTcfDescription(cible)}
            progress={accueilCycleRatio(cycle)}
            metrics={metrics}
            href={progressionHref("TCF")}
        />
    );
}

type DashboardCibleTcf = NonNullable<Parameters<typeof accueilTcfObjectifTitre>[0]> | null;

/**
 * **La carte civique** : le pourcentage unique `avancementSeriesCivique`
 * (0 % jamais vide), les séries terminées sur le total servi, et le seuil de
 * l'examen (miroir gelé de l'arrêté).
 */
function ObjectifCivique({summary}: {summary: Source<DashboardSummaryResponse>}) {
    const etat = etatBloc([summary]);
    if (etat === "loading") return <BlockSkeleton height={280} radius={30}/>;
    if (etat === "error" || !summary.data) {
        return <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={reessayer([summary])}/>;
    }
    const themes = summary.data.civique;
    const avancement = avancementSeriesCivique(themes);
    return (
        <ObjCard
            module="civique"
            icon={<IconShield/>}
            pill={ACCUEIL_CIVIQUE_LABEL}
            title={ACCUEIL_CIVIQUE_OBJECTIF_TITRE}
            description={accueilCiviqueDescription(themes.length)}
            progress={avancement.pourcentage / 100}
            metrics={[
                {value: accueilPourcentage(avancement.pourcentage), label: ACCUEIL_CIVIQUE_METRIC_PARCOURS},
                {value: accueilSeries(avancement.terminees, avancement.total), label: ACCUEIL_CIVIQUE_METRIC_SERIES},
                {value: ACCUEIL_CIVIQUE_SEUIL, label: ACCUEIL_CIVIQUE_METRIC_EXAMEN},
            ]}
            href={progressionHref("CIVIQUE")}
        />
    );
}

/* ================================================================ Squelette */

/** Le chargement de l'authentification : chaque bloc à ses dimensions. */
function AccueilSquelette() {
    return (
        <SejourApp className={sejourStyles.home}>
            <Pad>
                <BlockSkeleton height={112} radius={16}/>
            </Pad>
            <Section title={ACCUEIL_NOW_TITLE}>
                <Pad>
                    <div className={sejourStyles.homeGrid}>
                        <BlockSkeleton height={154}/>
                        <BlockSkeleton height={154}/>
                    </div>
                </Pad>
            </Section>
            <Section title={ACCUEIL_OBJECTIVES_TITLE}>
                <Pad>
                    <div className={sejourStyles.homeGrid}>
                        <BlockSkeleton height={280} radius={30}/>
                        <BlockSkeleton height={280} radius={30}/>
                    </div>
                </Pad>
            </Section>
        </SejourApp>
    );
}
