"use client";

import {useRouter} from "next/navigation";
import {useCallback, useState} from "react";
import {track, trackDiagnosticAssessmentStarted} from "@/lib/analytics";
import {attemptApi, fullTcfExamApi} from "@/lib/api";
import {recommendedExerciseHref} from "@/lib/diagnostic";
import {unlockCoAudio} from "@/lib/co-audio";
import {handleStartFailure} from "@/lib/start-failure";
import {adresseCourante, sessionHref} from "@/lib/retour";
import {planSkillHref} from "@/lib/plan-domain";
import type {
    PlanDomainAssessmentDto,
    PlanRecommendedExerciseDto,
    PlanSeanceExerciseItemDto,
} from "@/lib/types";
import {useMockExamLauncher} from "@/app/_components/hub/MockExamLauncher";
import {EPREUVE_PRESENTATION, plannedEpreuveLabel} from "@/lib/exam-durations";

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
 * | `EPREUVE_MOCK_EXAM` | on **ouvre** la feuille d'information de l'examen blanc EE/EO (`useMockExamLauncher`, le lanceur de la grille) |
 * | `FULL_TCF_MOCK_EXAM` | on **démarre** l'examen complet (chemin de `TcfFullExamBriefingSheet`) |
 *
 * 🛑 **Aucun runner concurrent n'est créé.** Une série ciblée est un attempt
 * `TRAINING` ordinaire : elle atterrit sur `/sessions/{id}`, exactement comme
 * une série de thème — même correction immédiate, mêmes raccourcis, même
 * rapport de série. `?retour=` (`sessionHref`) en fait rendre le rapport
 * complet, dont « Continuer » revient sur l'écran du Plan qui l'a lancée.
 *
 * Un **403** au démarrage n'est pas une panne : c'est le verrou freemium que le
 * serveur oppose, et il ouvre l'offre (`handleStartFailure`), jamais un message
 * d'erreur technique.
 */
export function usePlanExercise() {
    const router = useRouter();
    const launchExam = useMockExamLauncher();
    const [starting, setStarting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const start = useCallback(
        async (exercise: PlanRecommendedExerciseDto) => {
            setError(null);
            // Ne sert aucun bloc de cet écran : posé pour ne pas perdre une
            // mesure qui existait avant la migration vers `lib/analytics.ts`
            // (cf. CLAUDE.md racine). Point unique : les 5 natures d'exercice
            // du Plan passent toutes par ce lanceur.
            track("PLAN_EXERCISE_STARTED", {exerciseKind: exercise.kind});
            /* 🛑 **Un petit sujet ciblé ouvre la FICHE DE SA COMPÉTENCE**,
               jamais le sujet directement (demande du propriétaire,
               2026-09-20) : c'est là que le candidat voit ses cinq sujets et
               lesquels sont faits. L'écran s'ouvre à l'échelle de l'**étape**
               (« x/5 »), pas de la compétence entière (« x/15 »).

               ⚠️ **Révoque** le saut direct au sujet : les lignes du cycle et
               la carte « À faire maintenant » passaient par ici, pendant que la
               ligne de séance (`startItem`) ouvrait déjà la fiche. La même
               compétence menait à deux écrans selon l'endroit où on la
               touchait. */
            if (exercise.kind === "MICRO_TRAINING") {
                router.push(planSkillHref(exercise, {planStep: true}));
                return;
            }
            /* 🛑 **La VÉRIFICATION garde son lancement direct** : son sujet est
               une tâche de production qui ne fait pas partie des cinq de la
               fiche — l'y envoyer laisserait le candidat sans moyen de la
               faire. */
            if (exercise.kind === "REASSESSMENT") {
                router.push(recommendedExerciseHref(exercise, {planStep: true}));
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
                        // Dans le clic, avant tout `await` : la 1re question CO partira seule.
                        if (exercise.section === "CO") unlockCoAudio();
                        const attempt = await attemptApi.startTargetedSeries(exercise.skillId);
                        router.push(sessionHref(attempt.id, adresseCourante()));
                        break;
                    }
                    case "FULL_TCF_MOCK_EXAM": {
                        const exam = await fullTcfExamApi.start(exercise.slotNumber);
                        router.push(`/examens-blancs/tcf/${exam.id}`);
                        break;
                    }
                    case "EPREUVE_MOCK_EXAM": {
                        launchExam({
                            kind: "PRODUCTION",
                            epreuve: exercise.epreuve === "TCF_EO" ? "TCF_EO" : "TCF_EE",
                            slotNumber: exercise.slotNumber,
                            onPaywall: () => setPaywallOpen(true),
                        });
                        setStarting(false);
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
        [router, launchExam],
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
        async (skillId: string, coAudio: boolean) => {
            // Dans le clic, avant tout `await` : la 1re question CO partira seule.
            if (coAudio) unlockCoAudio();
            setError(null);
            setStarting(true);
            try {
                const attempt = await attemptApi.startTargetedSeries(skillId);
                router.push(sessionHref(attempt.id, adresseCourante()));
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
     *
     * 🛑 **Un item `A_EVALUER` n'entre pas ici** : ce n'est pas un exercice mais
     * une **mesure de domaine**, et elle se lance par `usePlanAssessment` — le
     * lanceur qui sert déjà « Compléter mon profil ». Le type l'impose : un
     * second chemin de démarrage finirait par diverger de celui-là.
     */
    const startItem = useCallback(
        async (item: PlanSeanceExerciseItemDto) => {
            const exercise = item.exercise;
            if (exercise.kind === "MICRO_TRAINING" || exercise.kind === "REASSESSMENT") {
                setError(null);
                // `start()` ne voit jamais ce cas (il retourne avant) : la
                // marque se pose donc ici, seule autre porte d'entrée.
                track("PLAN_EXERCISE_STARTED", {exerciseKind: exercise.kind});
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
 * Démarre le parcours de **mesure** d'un domaine. Deux natures, deux parcours
 * existants — et là encore, aucun contenu créé.
 *
 * **Cinq appelants, un seul lanceur** : la carte d'épreuve de l'Accueil
 * (« Où vous en êtes »), l'écran Progrès, la fiche d'un domaine, la ligne
 * `A_EVALUER` de la **séance** et Réviser. Tous ouvrent le même genre de
 * parcours et portent le même DTO ; en écrire un second aurait fini par les
 * faire diverger.
 *
 * 🛑 **Les quatre épreuves lancent un EXAMEN BLANC** (arbitrage du
 * propriétaire, 2026-09-16) : examen de module en CO/CE, examen de production
 * (les 3 tâches) en EE/EO — le même que le jalon du Plan, par le **même**
 * lanceur (`useMockExamLauncher` : feuille d'information, puis
 * démarrage). L'expression partait auparavant vers `/diagnostic` ou vers la
 * liste des 3 tâches en entraînement libre : aucun des deux ne lançait un
 * examen blanc.
 *
 * 🛑 **`slotNumber` est SERVI** : c'est lui qui pilote le démarrage, jamais un
 * `1` décidé ici (le repli ne couvre qu'un client servi par un backend qui ne
 * le publierait pas).
 */
export function usePlanAssessment() {
    const launchExam = useMockExamLauncher();
    const [starting, setStarting] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    /* 🛑 **Les deux natures passent par le lanceur partagé** (feuille
       d'information, puis démarrage au clic) — exactement ce que fait la grille
       d'examens de l'épreuve, et ce que fait l'app (`openPlanAssessment`). Le
       démarrage, ses erreurs et son 403 vivent là-bas ; l'offre reste celle
       de l'appelant. */
    const start = useCallback(
        (assessment: PlanDomainAssessmentDto) => {
            setError(null);
            setStarting(null);
            const onPaywall = () => setPaywallOpen(true);
            if (assessment.kind === "PRODUCTION_MOCK_EXAM") {
                launchExam({
                    kind: "PRODUCTION",
                    epreuve: assessment.epreuve === "TCF_EO" ? "TCF_EO" : "TCF_EE",
                    slotNumber: assessment.slotNumber ?? 1,
                    onPaywall,
                });
                return;
            }
            // `moduleExamQuestionType` et `slotNumber` viennent du serveur : on
            // les repasse tels quels. Le repli sur CO vaut pour un type absent
            // (miroir de `openPlanAssessment`) ; la Structure, hors des quatre
            // épreuves, n'est jamais mesurée par le Plan.
            const epreuve = assessment.moduleExamQuestionType === "CE" ? "TCF_CE" : "TCF_CO";
            launchExam({
                kind: "COMPREHENSION",
                questionType: epreuve === "TCF_CE" ? "CE" : "CO",
                title: EPREUVE_PRESENTATION[epreuve].label,
                durationLabel: plannedEpreuveLabel(epreuve),
                slotNumber: assessment.slotNumber ?? 1,
                onPaywall,
                // Les deux domaines de compréhension, que le diagnostic rapide
                // ne mesure pas, se mesurent par cette série : c'est le seul
                // instant où le navigateur sait POURQUOI l'examen blanc
                // s'ouvre. Le runner, lui, ne le saura jamais — d'où la marque
                // posée ici, que l'écran de résultat consomme
                // (`lib/analytics.ts`).
                onStarted: (attemptId) => {
                    if (assessment.epreuve === "TCF_CO" || assessment.epreuve === "TCF_CE") {
                        trackDiagnosticAssessmentStarted(
                            attemptId,
                            assessment.epreuve === "TCF_CO" ? "CO" : "CE",
                        );
                    }
                },
            });
        },
        [launchExam],
    );

    const closePaywall = useCallback(() => {
        setPaywallOpen(false);
        setStarting(null);
    }, []);

    return {start, starting, error, paywallOpen, closePaywall} as const;
}
