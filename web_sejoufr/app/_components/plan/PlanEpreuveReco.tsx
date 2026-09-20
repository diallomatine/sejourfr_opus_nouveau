"use client";

/**
 * **Ce que le cycle propose pour CETTE épreuve**, en tête de son écran
 * d'entraînement (demande du propriétaire, 2026-09-20).
 *
 * 🛑 **Le clic fait exactement ce que ferait la même étape cliquée depuis le
 * Plan** : l'étape vient de `planEpreuveCarte`, son action de `planStepAction`,
 * et le lancement des **mêmes lanceurs** que le Plan (`usePlanExercise` /
 * `usePlanAssessment`). Aucun second chemin n'est écrit ici.
 *
 * 🛑 **Rien ne s'affiche quand il n'y a rien à dire**, et c'est fréquent : un
 * visiteur (pas de plan), une épreuve sans bloc dans ce cycle — « Structure de
 * la langue » n'en a **jamais**, elle est hors des quatre épreuves du TCF IRN —,
 * un bloc terminé, ou une action qui ne se résout pas. On ne fabrique ni
 * squelette ni bouton mort.
 *
 * ⚠️ **Aucun appel de plus dans le cas courant** : le Plan et le parcours sont
 * lus **en cache**, le candidat arrivant d'un écran qui les a déjà chargés.
 *
 * Miroir mobile : `screens/plan/widgets/plan_epreuve_reco.dart`.
 */

import type {ReactNode} from "react";
import {journeyApi, learningPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {useCachedData} from "@/lib/use-cached-data";
import {canAccessModule} from "@/lib/types";
import type {JourneyDto, LearningPlanDto} from "@/lib/types";
import {planEpreuveCarte} from "@/lib/plan-domain";
import {REVISER_RESUME_LABEL} from "@/lib/reviser";
import {planUnlockHref} from "@/lib/plan-unlock";
import {PlanRecoCard} from "./PlanRecoCard";
import {usePlanAssessment, usePlanExercise} from "./use-plan-exercise";
import {PaywallSheet} from "@/app/_components/PaywallSheet";

/**
 * **L'étape du cycle pour cette épreuve**, lue en cache.
 *
 * Exportée parce qu'un écran peut avoir besoin de l'étape **sans** la carte —
 * la liste des tâches EE/EO y surligne la tâche concernée. Deux lectures sous
 * la même clé de cache ne coûtent qu'un appel.
 */
export function usePlanEpreuveCarte(blocCode: string) {
    const {status, user} = useAuth();
    const connecte = status === "authenticated";
    const plan = useCachedData<LearningPlanDto>(
        connecte ? learningPlanApi.cacheKey : null,
        () => learningPlanApi.getCached(),
    );
    const journey = useCachedData<JourneyDto>(
        connecte ? journeyApi.cacheKey : null,
        () => journeyApi.getCached(),
    );
    if (!connecte) return null;
    return planEpreuveCarte(plan.data ?? null, journey.data ?? null, blocCode, {
        free: !canAccessModule(user, "TCF"),
    });
}

export function PlanEpreuveReco({
    blocCode,
    icon,
    tone = "primary",
}: {
    /** Le code du bloc du cycle : `TCF_CO`, `TCF_CE`, `TCF_EE`, `TCF_EO`. */
    blocCode: string;
    icon: ReactNode;
    tone?: "primary" | "blue";
}) {
    const carte = usePlanEpreuveCarte(blocCode);
    const exercise = usePlanExercise();
    const assessment = usePlanAssessment();
    if (!carte) return null;

    const busy = exercise.starting || assessment.starting !== null;
    const lancer = () => {
        const action = carte.action;
        if (!action) return;
        if (action.mesure) void assessment.start(action.mesure.assessment);
        else if (action.exercise) void exercise.start(action.exercise);
    };

    return (
        <>
            <PlanRecoCard
                pad={false}
                icon={icon}
                label={REVISER_RESUME_LABEL}
                title={carte.title}
                subtitle={carte.subtitle}
                cta={carte.cta}
                tone={tone}
                {...(carte.geste === "DEBLOQUER"
                    ? {href: planUnlockHref("TCF")}
                    : {
                          onClick: lancer,
                          busy,
                          error: exercise.error ?? assessment.error,
                      })}
            />
            {/* ⚠️ Ce paywall ne répond qu'à un **403** : le geste d'achat, lui,
                passe par l'écran de transition (A145). */}
            <PaywallSheet
                ctaLocation="LOCKED_PLAN"
                screen="plan"
                module="INTEGRAL"
                open={exercise.paywallOpen || assessment.paywallOpen}
                onClose={() => {
                    exercise.closePaywall();
                    assessment.closePaywall();
                }}
            />
        </>
    );
}
