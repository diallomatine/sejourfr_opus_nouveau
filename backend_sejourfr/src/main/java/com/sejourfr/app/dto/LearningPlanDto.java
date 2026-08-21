package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanState;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Plan actionnable ; aucune priorité n'est recalculée dans les fronts. */
public record LearningPlanDto(
        LearningPlanState state,
        UUID diagnosticSessionId,
        Instant diagnosticCompletedAt,
        /**
         * Les <b>étapes déjà franchies</b>, de la plus ancienne à la plus
         * récente : elles se lisent <b>avant</b> {@link #currentPriority()} et
         * {@link #nextPriorities()}, dans le même parcours numéroté, et
         * s'affichent cochées.
         *
         * <p>Jamais {@code null} ; <b>vide</b> tant qu'aucune compétence n'a
         * prouvé son transfert — cas normal au sortir du diagnostic. Bornée aux
         * {@code LearningPlanService.MAX_COMPLETED_STEPS} plus récentes : elles
         * s'accumulent indéfiniment et un parcours de quarante étapes ne se lit
         * pas. L'historique complet reste consultable par la Progression.
         */
        List<LearningPlanCompletedStepDto> completedSteps,
        LearningPlanPriorityDto currentPriority,
        List<LearningPlanPriorityDto> nextPriorities,
        List<LearningPlanSkillDto> observedSkills,
        int observedSkillCount,
        int activitiesThisWeek,
        boolean progressionAvailable,
        /**
         * Le <b>jalon</b> du parcours, un cran au-dessus des étapes : un examen
         * blanc d'épreuve puis l'examen blanc TCF complet
         * ({@code PlanExerciseKind.EPREUVE_MOCK_EXAM} /
         * {@code FULL_TCF_MOCK_EXAM}). Il vit <b>à côté</b> des priorités, il ne
         * les remplace pas — chaque étape garde son propre
         * {@code recommendedExercise}.
         *
         * <p>{@code null} est le <b>cas normal</b> : tant qu'une épreuve n'a pas
         * majoritairement transféré, il n'y a rien à mesurer, et juste après un
         * examen blanc il n'y a rien à re-mesurer. Verrouillé, il reste
         * <b>désigné</b> avec son {@code locked} : le Plan reste intégralement
         * visible, seuls les accès sont fermés.
         */
        PlanRecommendedExerciseDto milestone,
        /**
         * Les <b>quatre domaines</b> du TCF — compréhension orale, compréhension
         * écrite, expression orale, expression écrite — <b>toujours les quatre</b>,
         * y compris ceux qui n'ont jamais été mesurés ({@code evaluated=false}).
         *
         * <p>🛑 <b>L'ordre est décidé par le SERVEUR</b> : par urgence
         * ({@code PlanDomainPriority}, ordre de déclaration), et à égalité par
         * l'ordre des épreuves du TCF. Aucun front ne réordonne, aucun front ne
         * complète les trous — une liste trouée ferait disparaître de l'écran
         * exactement ce que « Compléter mon profil » doit montrer.
         *
         * <p>Le niveau d'un domaine est celui de {@code TcfProfileService}, le
         * même que publie le dashboard : il n'est jamais recalculé ici.
         */
        List<PlanDomainDto> domaines,
        /**
         * Le <b>cycle de palier</b> en cours : d'où part le candidat, quel palier
         * le Plan construit maintenant, son objectif, et son chemin.
         *
         * <p>Entièrement <b>dérivé</b>, jamais persisté : aucune table, aucune
         * migration. {@code state == READY_FOR_GATE_MOCK} est le moment où le Plan
         * réclame l'examen blanc complet qui confirmera le palier — le jalon
         * correspondant est servi, comme les autres, sur {@link #milestone()}.
         */
        PlanCycleDto cycle,
        /**
         * <b>La seance du jour</b> : au plus trois entrainements, dans l'ordre,
         * et leur duree totale. Jamais {@code null} ; ses items sont vides quand
         * le Plan n'a rien a proposer.
         *
         * <p>C'est une <b>vue</b> des priorites et du jalon ci-dessus, pas une
         * seconde source de verite : chaque item reprend un exercice deja
         * designe. Elle ne depend d'<b>aucune date</b> — une competence entree
         * dans la seance y reste tant qu'elle n'est pas reussie, ce qui est
         * acquis par construction (les priorites ne changent qu'a l'arrivee
         * d'une nouvelle observation).
         */
        PlanSeanceDto seance,
        /**
         * <b>Ce qui a change recemment</b> : les transitions reellement mesurees
         * par le moteur de maitrise sur une fenetre choisie par le serveur, et
         * la priorite n&deg;1 si elle vient d'etre designee.
         *
         * <p>🛑 <b>{@code null} est le cas NORMAL</b> — rien n'a bouge, l'ecran
         * n'affiche rien. Aucune ligne n'est fabriquee pour remplir le bloc.
         * A ne pas confondre avec {@code PlanChangeDto}, servi sur le detail
         * d'une production : celui-la dit ce qu'une soumission a change,
         * celui-ci ce qui a bouge recemment (cf. {@link PlanRecentChangesDto}).
         */
        PlanRecentChangesDto recentChanges
) {}
