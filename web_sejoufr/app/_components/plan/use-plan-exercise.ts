"use client";

import {useRouter} from "next/navigation";
import {useCallback, useState} from "react";
import {attemptApi, fullTcfExamApi, productionApi} from "@/lib/api";
import {recommendedExerciseHref} from "@/lib/diagnostic";
import {handleStartFailure} from "@/lib/start-failure";
import {planSkillHref} from "@/lib/plan-domain";
import type {
    PlanDomainAssessmentDto,
    PlanRecommendedExerciseDto,
    PlanSeanceItemDto,
} from "@/lib/types";
import {EE_CONFIG, EO_CONFIG} from "@/app/_components/production/config";

/**
 * **Le seul endroit du web qui lance une action du Plan.**
 *
 * Les cinq natures ne mènent pas au même écran, et aucune ne crée de contenu :
 * chacune ouvre ou démarre un parcours **déjà existant**.
 *
 * | `kind` | ce qu'on fait |
 * |---|---|
 * | `MICRO_TRAINING` | on **navigue** vers le petit sujet du module Compétences |
 * | `REASSESSMENT` | on **navigue** vers la tâche de production désignée |
 *
 * ⚠️ Depuis une ligne de **séance**, ces deux natures ouvrent la **fiche de la
 * compétence** et non le sujet : cf. `startItem` plus bas.
 * | `TARGETED_QCM_SERIES` | on **démarre** un `TRAINING` (`skillId` seul) puis le runner QCM existant |
 * | `EPREUVE_MOCK_EXAM` | on **démarre** la session de production d'examen (chemin de `ProductionExams`) |
 * | `FULL_TCF_MOCK_EXAM` | on **démarre** l'examen complet (chemin de `TcfFullExamBriefingSheet`) |
 *
 * 🛑 **Aucun runner concurrent n'est créé.** Une série ciblée est un attempt
 * `TRAINING` ordinaire : elle atterrit sur `/sessions/{id}`, exactement comme
 * une série de thème — même correction immédiate, mêmes raccourcis, même écran
 * de résultat.
 *
 * Un **403** au démarrage n'est pas une panne : c'est le verrou freemium que le
 * serveur oppose, et il ouvre l'offre (`handleStartFailure`), jamais un message
 * d'erreur technique.
 */
export function usePlanExercise() {
    const router = useRouter();
    const [starting, setStarting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const start = useCallback(
        async (exercise: PlanRecommendedExerciseDto) => {
            setError(null);
            if (exercise.kind === "MICRO_TRAINING" || exercise.kind === "REASSESSMENT") {
                router.push(recommendedExerciseHref(exercise));
                return;
            }
            setStarting(true);
            try {
                // ⚠️ Un `switch` sur `kind`, pas une exclusion en `||` :
                // `PlanStepExerciseDto` porte DEUX littéraux, et l'exclure par
                // la négative ne le retire pas de l'union — le tapuscrit y
                // verrait encore un `slotNumber: null`.
                switch (exercise.kind) {
                    case "TARGETED_QCM_SERIES": {
                        const attempt = await attemptApi.startTargetedSeries(exercise.skillId);
                        router.push(`/sessions/${attempt.id}`);
                        break;
                    }
                    case "FULL_TCF_MOCK_EXAM": {
                        const exam = await fullTcfExamApi.start(exercise.slotNumber);
                        router.push(`/examens-blancs/tcf/${exam.id}`);
                        break;
                    }
                    case "EPREUVE_MOCK_EXAM": {
                        const config = exercise.epreuve === "TCF_EO" ? EO_CONFIG : EE_CONFIG;
                        const attempt = await productionApi.startAttempt({
                            module: "TCF",
                            epreuve: config.epreuve,
                            exam: true,
                            slotNumber: exercise.slotNumber,
                        });
                        router.push(`${config.base}/session/${attempt.id}`);
                        break;
                    }
                    default:
                        // Traité plus haut : une navigation, pas un démarrage.
                        setStarting(false);
                        break;
                }
            } catch (cause) {
                handleStartFailure(cause, {
                    onPaywall: () => setPaywallOpen(true),
                    onMessage: setError,
                    fallbackMessage: "Impossible de démarrer cet exercice.",
                });
                setStarting(false);
            }
        },
        [router],
    );

    /**
     * Démarrer une **série ciblée** à partir de la seule compétence — c'est ce
     * dont dispose un palier de domaine (`PlanDomainLevelDto`), qui ne porte
     * aucun exercice.
     *
     * 🛑 **On n'envoie que le `skillId`.** Épreuve, palier et taille se
     * dérivent du référentiel côté serveur ; un couple (type de question,
     * difficulté) venu d'ici aurait pu contredire la compétence affichée et
     * faire progresser une autre compétence que celle travaillée.
     */
    const startSeries = useCallback(
        async (skillId: string) => {
            setError(null);
            setStarting(true);
            try {
                const attempt = await attemptApi.startTargetedSeries(skillId);
                router.push(`/sessions/${attempt.id}`);
            } catch (cause) {
                handleStartFailure(cause, {
                    onPaywall: () => setPaywallOpen(true),
                    onMessage: setError,
                    fallbackMessage: "Impossible de démarrer cette série.",
                });
                setStarting(false);
            }
        },
        [router],
    );

    /**
     * Ouvrir une ligne de la **séance**.
     *
     * 🛑 Un item de **nature production** (un petit sujet ciblé, une
     * vérification en situation) ouvre la **fiche de sa compétence**, pas le
     * sujet : le candidat y voit ses cinq sujets et lesquels sont faits, et il
     * choisit. C'est exactement ce que font déjà les lignes de « Mes
     * priorités » — la séance s'aligne dessus au lieu de le court-circuiter.
     *
     * Les autres natures ne changent pas : une **série ciblée** démarre son
     * `TRAINING`, un **jalon** ouvre son examen blanc. Elles n'ont pas de fiche
     * à ouvrir — une compétence de compréhension n'a aucun petit sujet, et un
     * examen blanc ne travaille aucune compétence en particulier.
     */
    const startItem = useCallback(
        async (item: PlanSeanceItemDto) => {
            const exercise = item.exercise;
            if (exercise.kind === "MICRO_TRAINING" || exercise.kind === "REASSESSMENT") {
                setError(null);
                router.push(planSkillHref(exercise, {planStep: true}));
                return;
            }
            await start(exercise);
        },
        [router, start],
    );

    const closePaywall = useCallback(() => {
        setPaywallOpen(false);
        setStarting(false);
    }, []);

    return {start, startItem, startSeries, starting, error, paywallOpen, closePaywall} as const;
}

/**
 * Démarre l'un des parcours de **mesure** d'un domaine (« Compléter mon
 * profil »). Trois natures, trois parcours existants — et là encore, aucun
 * contenu créé.
 */
export function usePlanAssessment() {
    const router = useRouter();
    const [starting, setStarting] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const start = useCallback(
        async (assessment: PlanDomainAssessmentDto) => {
            setError(null);
            if (assessment.kind === "DIAGNOSTIC") {
                router.push("/diagnostic");
                return;
            }
            if (assessment.kind === "PRODUCTION") {
                const config = assessment.epreuve === "TCF_EO" ? EO_CONFIG : EE_CONFIG;
                router.push(config.base);
                return;
            }
            setStarting(assessment.epreuve);
            try {
                const attempt = await attemptApi.start({
                    type: "MOCK_EXAM",
                    module: "TCF",
                    // `moduleExamQuestionType` et `slotNumber` viennent du serveur :
                    // on les repasse tels quels, on ne les choisit pas.
                    moduleExamQuestionType: assessment.moduleExamQuestionType ?? undefined,
                    slotNumber: assessment.slotNumber ?? 1,
                });
                router.push(`/sessions/${attempt.id}`);
            } catch (cause) {
                handleStartFailure(cause, {
                    onPaywall: () => setPaywallOpen(true),
                    onMessage: setError,
                    fallbackMessage: "Impossible de démarrer cette épreuve.",
                });
                setStarting(null);
            }
        },
        [router],
    );

    const closePaywall = useCallback(() => {
        setPaywallOpen(false);
        setStarting(null);
    }, []);

    return {start, starting, error, paywallOpen, closePaywall} as const;
}
