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
         * <b>Ce qu'il reste a mesurer</b>, et par quoi : un item par domaine
         * jamais evalue, avec l'epreuve concernee et les parametres exacts du
         * parcours <b>deja existant</b> a ouvrir (le diagnostic, un examen blanc
         * de module CO/CE, une production EE/EO).
         *
         * <p>C'est le bloc « Completer mon profil » du brief §7, et c'est ce qui
         * rend le diagnostic <b>progressif</b> : un profil vit a 0, 1, 2, 3 ou
         * 4 domaines mesures, et cette liste dit toujours ou en est le candidat.
         *
         * <p><b>Jamais {@code null}</b> ; <b>vide</b> quand
         * {@code cycle.profileComplete()} — c'est l'etat vise, pas une anomalie.
         * Le <b>compte</b> (2/4, 4/4) ne se lit pas ici mais sur
         * {@link #cycle()}, et l'etat de chaque domaine sur
         * {@link #domaines()} : trois surfaces qui compteraient chacune de leur
         * cote auraient fini par se contredire.
         *
         * <p>🛑 <b>Le serveur expose des faits</b> — quelle epreuve, quel
         * parcours, quels parametres. « Evaluer ma comprehension orale » et
         * « Pas encore evaluee » appartiennent aux fronts.
         */
        List<PlanDomainAssessmentDto> domainesAEvaluer,
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
