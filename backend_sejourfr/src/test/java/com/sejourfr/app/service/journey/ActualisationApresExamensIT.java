package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le scenario de prod du 2026-10-03</b> ({@code user@sejourfr.fr}) : un cycle
 * d'examens fini, « Actualiser mon plan », et un cycle suivant dont les blocs CO
 * et CE etaient VIDES — affiches « termines » sans qu'aucune etape n'y ait ete
 * faite.
 *
 * <p>Non transactionnel : le parcours ecrit en {@link Propagation#REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ActualisationApresExamensIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyStepRepository steps;
    @Autowired private SkillManager skillManager;
    @Autowired private TestData data;
    @Autowired private AccountDeletionService accountDeletionService;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    // =====================================================================
    // Bug 1 — l'examen « plus ancien que lui-meme »
    // =====================================================================

    @Test
    @DisplayName("Un examen CE dont la fin porte des nanosecondes arrondies a la hausse par "
            + "la base n'est JAMAIS ignore pour anciennete : ses priorites vont au cycle suivant")
    void unExamenNEstJamaisPlusAncienQueLuiMeme() {
        User user = candidat();
        // Le Plan par defaut : le cycle d'examens (D-69).
        journeyService.lire(user.getId(), Module.TCF);
        // 🛑 La valeur exacte du journal de prod : `.331182712` en Java,
        // `.331183` relu en base (timestamptz arrondit a la microseconde).
        Instant fin = Instant.now().truncatedTo(ChronoUnit.SECONDS)
                .plusSeconds(1).plusNanos(331_182_712);
        Attempt examenCe = examenQcm(user, EpreuveType.TCF_CE, fin);
        for (Skill competence : comprehension(SkillSection.CE)) {
            priorite(user, competence, LearningPlanSourceType.TCF_CE, examenCe.getId(), fin);
        }

        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCe.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CE, fin));

        Journey attente = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE).orElseThrow(
                        () -> new AssertionError("l'examen CE a ete ignore pour anciennete"));
        assertThat(competences(attente, EpreuveType.TCF_CE))
                .containsExactlyInAnyOrder("CE-A2", "CE-B1", "CE-B2");
    }

    // ------------------------------------------------------------- fabriques

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        user = data.saveUser(user);
        data.userSubscription(user, data.plan());
        return user;
    }

    /** Un examen blanc QCM termine a {@code fin}, tout faux (A1 non atteint). */
    private Attempt examenQcm(User user, EpreuveType epreuve, Instant fin) {
        Attempt attempt = data.examenQcmTcfPasse(user, epreuve, NiveauCecrl.A1_NON_ATTEINT);
        attempt.setFinishedAt(fin);
        return data.saveAttempt(attempt);
    }

    private void priorite(User user, Skill competence, LearningPlanSourceType source,
                          UUID examen, Instant quand) {
        data.learningPlanObservation(user, competence, source, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.MEDIUM, examen, quand, examen);
    }

    /** Les competences de comprehension seedees d'un domaine (A2, B1, B2). */
    private List<Skill> comprehension(SkillSection section) {
        return skillManager.findActiveComprehension().stream()
                .filter(skill -> skill.getSection() == section)
                .toList();
    }

    private List<String> competences(Journey journey, EpreuveType epreuve) {
        return steps.findAllByJourney(journey.getId()).stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.getExamType() == epreuve)
                .filter(JourneyStep::estOuverte)
                .map(step -> step.getSkill().getCode())
                .toList();
    }
}
