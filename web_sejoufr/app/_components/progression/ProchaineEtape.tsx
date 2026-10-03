"use client";

import {
    BlockError,
    BlockSkeleton,
    Hero,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {IconEar, IconShield} from "@/app/_components/shell/ShellIcons";
import {useGesteEtapeCivique, useGesteEtapeTcf} from "@/app/_components/plan/now-card-gestes";
import {
    ACCUEIL_BLOCK_ERROR,
    ACCUEIL_CIVIQUE_CTA,
    ACCUEIL_RETRY,
    ACCUEIL_TCF_CTA,
    accueilCiviqueActionMeta,
    accueilTcfActionMeta,
} from "@/lib/accueil";
import {civicPlanApi, journeyApi, learningPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {civicNowCard} from "@/lib/civic-plan";
import {JOURNEY_UP_TO_DATE_TITLE} from "@/lib/journey";
import {planHref} from "@/lib/module-switch";
import {planNowCard} from "@/lib/plan-domain";
import {canAccessModule, type CivicPlanDto, type JourneyDto, type LearningPlanDto} from "@/lib/types";
import {useCachedData} from "@/lib/use-cached-data";

/** L'intitulé du bandeau (maquette `#tcf-progression` / `#civique-progression`). */
export const PROCHAINE_ETAPE_LABEL = "Prochaine étape";

/**
 * **« Prochaine étape »** des écrans Progression — le `journey.current` du
 * module, avec **le même geste que la carte « À faire maintenant » de
 * l'Accueil** : `planNowCard` (TCF) / `civicNowCard` (civique) décident de
 * LANCER, OUVRIR_ETAPE, DEBLOQUER ou AUCUN, et les lanceurs sont ceux du Plan
 * (`usePlanExercise`, `usePlanAssessment`, `useMockExamLauncher`).
 *
 * 🛑 Rien n'est redéduit ici : ni verrou, ni adresse, ni étape. Le bloc charge,
 * échoue et se réessaie seul (brief §7). Parcours à jour ⇒ le bandeau le dit
 * et mène au Plan du module, où vit « Actualiser mon plan ».
 *
 * Les gestes sont ceux de l'Accueil, par la même brique
 * (`plan/now-card-gestes.tsx`, miroir de `now_card_gestes.dart`).
 */
export function ProchaineEtapeTcf() {
    const {user, status} = useAuth();
    const geste = useGesteEtapeTcf("progression");
    const actif = status === "authenticated";
    const plan = useCachedData<LearningPlanDto>(
        actif ? learningPlanApi.cacheKey : null,
        () => learningPlanApi.getCached(),
    );
    const journey = useCachedData<JourneyDto>(
        actif ? journeyApi.cacheKeyFor("TCF") : null,
        () => journeyApi.getCached("TCF"),
    );

    if (plan.error || journey.error) {
        return (
            <BlockError
                message={ACCUEIL_BLOCK_ERROR}
                retryLabel={ACCUEIL_RETRY}
                onRetry={() => {
                    if (plan.error) plan.reload();
                    if (journey.error) journey.reload();
                }}
            />
        );
    }
    if (!plan.data || !journey.data || !user) return <BlockSkeleton height={220}/>;

    const vue = planNowCard(plan.data, {free: !canAccessModule(user, "TCF"), journey: journey.data});
    if (!vue) return <AJour module="tcf"/>;

    const cta = geste.cta(vue);
    const erreur = geste.erreur;
    const note = vue.geste === "AUCUN" ? vue.lines[0] ?? null : null;

    return (
        <>
            <Hero
                module="tcf"
                icon={<IconEar/>}
                label={PROCHAINE_ETAPE_LABEL}
                title={vue.title}
                sub={accueilTcfActionMeta(vue)}
                cta={cta}
            >
                {note || erreur ? (
                    <p className={sejourStyles.modHeroSub} role={erreur ? "alert" : undefined}>
                        {erreur ?? note}
                    </p>
                ) : null}
            </Hero>
            {geste.paywall(journey.data.journeyId)}
        </>
    );
}

export function ProchaineEtapeCivique() {
    const {user, status} = useAuth();
    const geste = useGesteEtapeCivique("progression");
    const actif = status === "authenticated";
    const plan = useCachedData<CivicPlanDto>(
        actif ? civicPlanApi.cacheKey : null,
        () => civicPlanApi.getCached(),
    );
    const journey = useCachedData<JourneyDto>(
        actif ? journeyApi.cacheKeyFor("CIVIQUE") : null,
        () => journeyApi.getCached("CIVIQUE"),
    );

    if (plan.error || journey.error) {
        return (
            <BlockError
                message={ACCUEIL_BLOCK_ERROR}
                retryLabel={ACCUEIL_RETRY}
                onRetry={() => {
                    if (plan.error) plan.reload();
                    if (journey.error) journey.reload();
                }}
            />
        );
    }
    if (!plan.data || !journey.data || !user) return <BlockSkeleton height={220}/>;

    const carte = civicNowCard(plan.data, {
        journey: journey.data,
        free: !canAccessModule(user, "CIVIQUE"),
        lancerExamen: true,
    });
    if (!carte) return <AJour module="civique"/>;

    const cta = geste.cta(carte);

    return (
        <>
            <Hero
                module="civique"
                icon={<IconShield/>}
                label={PROCHAINE_ETAPE_LABEL}
                title={carte.title}
                sub={accueilCiviqueActionMeta(carte)}
                cta={cta}
            />
            {geste.paywall(journey.data.journeyId)}
        </>
    );
}

/** Plus d'étape à annoncer : le bandeau le dit et mène au Plan du module. */
function AJour({module}: {module: "tcf" | "civique"}) {
    const tcf = module === "tcf";
    return (
        <Hero
            module={module}
            icon={tcf ? <IconEar/> : <IconShield/>}
            label={PROCHAINE_ETAPE_LABEL}
            title={JOURNEY_UP_TO_DATE_TITLE}
            cta={{
                label: tcf ? ACCUEIL_TCF_CTA : ACCUEIL_CIVIQUE_CTA,
                href: planHref(tcf ? "TCF" : "CIVIQUE"),
            }}
        />
    );
}
