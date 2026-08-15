package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La sortie de priorite relue depuis la <b>vraie base</b> : l'ordre DESC de
 * {@code findAllByUserWithSkill}, la contrainte
 * {@code chk_learning_plan_observation_status} et la contrainte de coherence
 * {@code observed / status / evidence} sont exercees pour de vrai.
 *
 * <p>C'est aussi ce que lit {@code SkillAccessService} pour ouvrir la competence
 * de la priorite n&deg;1 a un compte gratuit : ce qui est verrouille ici l'est
 * pour le Plan et pour le verrou commercial en meme temps.
 */
class LearningPlanPriorityResolverIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanPriorityResolver resolver;
    @Autowired private LearningPlanObservationManager observationManager;

    @Test
    @DisplayName("Une reussite en situation libere l'etape pour la competence suivante")
    void uneReussiteEnSituationLibereLetape() {
        User user = data.user();
        Skill reussie = data.skill();
        Skill suivante = data.skill();
        observation(user, reussie, LearningPlanSourceType.DIAGNOSTIC_EE,
                LearningPlanSkillStatus.PRIORITY, jours(30));
        observation(user, suivante, LearningPlanSourceType.DIAGNOSTIC_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(30));

        assertThat(resolver.currentPrioritySkillId(user.getId())).contains(reussie.getId());

        observation(user, reussie, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(1));

        assertThat(resolver.currentPrioritySkillId(user.getId())).contains(suivante.getId());
        assertThat(codes(user)).containsExactly(suivante.getCode());
    }

    /**
     * Un micro-exercice rate apres la preuve ne ramene pas la competence : c'est
     * exactement le defaut corrige. Un {@code SOLID} de micro-entrainement, lui,
     * n'aurait jamais libere l'etape.
     */
    @Test
    @DisplayName("Un micro-exercice rate apres la preuve ne ramene pas la competence")
    void unMicroExerciceRateApresLaPreuveNeRamenePasLaCompetence() {
        User user = data.user();
        Skill skill = data.skill();
        observation(user, skill, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(5));
        observation(user, skill, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.PRIORITY, jours(1));

        assertThat(codes(user)).isEmpty();
        assertThat(resolver.currentPrioritySkillId(user.getId())).isEmpty();
    }

    @Test
    @DisplayName("Un SOLID de micro-entrainement ou de diagnostic ne libere rien")
    void seuleUnePreuveEnSituationLibereLetape() {
        User user = data.user();
        Skill cible = data.skill();
        Skill baseline = data.skill();
        observation(user, cible, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.SOLID, jours(6));
        observation(user, cible, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.PRIORITY, jours(2));
        observation(user, baseline, LearningPlanSourceType.DIAGNOSTIC_EO,
                LearningPlanSkillStatus.SOLID, jours(20));
        observation(user, baseline, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.PRIORITY, jours(3));

        assertThat(codes(user)).containsExactlyInAnyOrder(cible.getCode(), baseline.getCode());
    }

    /** Rien n'est verrouille : une production ulterieure ramene la competence. */
    @Test
    @DisplayName("Fragilisee par une production ulterieure, la competence redevient priorite")
    void uneCompetenceFragiliseeRedevientPriorite() {
        User user = data.user();
        Skill skill = data.skill();
        observation(user, skill, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(15));

        assertThat(codes(user)).isEmpty();

        observation(user, skill, LearningPlanSourceType.MOCK_EXAM_EO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(1));

        assertThat(codes(user)).containsExactly(skill.getCode());
    }

    private List<String> codes(User user) {
        List<LearningPlanObservation> actionable = resolver.actionable(
                observationManager.findAllByUserWithSkill(user.getId()));
        return actionable.stream().map(item -> item.getSkill().getCode()).toList();
    }

    private void observation(User user, Skill skill, LearningPlanSourceType source,
                             LearningPlanSkillStatus status, Instant quand) {
        data.learningPlanObservation(user, skill, source, status, ObservationConfidence.HIGH,
                UUID.randomUUID(), quand);
    }

    private static Instant jours(int nombre) {
        return Instant.now().minus(Duration.ofDays(nombre));
    }
}
