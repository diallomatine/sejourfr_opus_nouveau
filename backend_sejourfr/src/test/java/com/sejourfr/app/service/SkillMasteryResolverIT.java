package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le moteur de maitrise contre la <b>vraie base</b> : la colonne
 * {@code subject_id} de V031, la contrainte de source elargie aux examens
 * blancs, et surtout le <b>cout du chargement</b>.
 *
 * <p>Un ecran de competences en affiche 24 : si le resolveur emettait une
 * requete par competence, la regression serait invisible en unitaire et
 * couteuse en production. On compte donc les requetes reellement preparees par
 * Hibernate — c'est l'index {@code idx_learning_plan_user_skill_recent} qui
 * porte cette lecture.
 */
class SkillMasteryResolverIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private SkillMasteryResolver resolver;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("24 competences, UNE requete")
    void leChargementResteEnLot() {
        User user = data.user();
        List<Skill> skills = new ArrayList<>();
        for (SkillTaskCode code : List.of(SkillTaskCode.EE1, SkillTaskCode.EE2, SkillTaskCode.EE3,
                SkillTaskCode.EO1, SkillTaskCode.EO2, SkillTaskCode.EO3)) {
            for (int i = 0; i < 4; i++) {
                Skill skill = data.skill(code);
                skills.add(skill);
                observation(user, skill, LearningPlanSourceType.SKILL_TRAINING,
                        LearningPlanSkillStatus.TO_REINFORCE, jours(2));
            }
        }
        entityManager.flush();
        entityManager.clear();

        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();

        Map<UUID, SkillMasteryEngine.SkillMastery> mastery =
                resolver.bySkillIds(user.getId(), skills.stream().map(Skill::getId).toList());

        assertThat(skills).hasSize(24);
        assertThat(mastery).hasSize(24);
        assertThat(statistics.getPrepareStatementCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("Le parcours complet se relit depuis la base : micro-exercices puis examen blanc")
    void leParcoursCompletSeRelitDepuisLaBase() {
        User user = data.user();
        Skill skill = data.skill();
        observation(user, skill, LearningPlanSourceType.DIAGNOSTIC_EE,
                LearningPlanSkillStatus.PRIORITY, jours(40));
        observation(user, skill, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.TO_REINFORCE, jours(20));
        observation(user, skill, LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.TO_REINFORCE, jours(15));

        SkillMasteryEngine.SkillMastery avant =
                resolver.bySkillIds(user.getId(), List.of(skill.getId())).get(skill.getId());
        assertThat(avant.state()).isNotEqualTo(SkillMasteryState.SOLID);
        assertThat(avant.readyForReassessment()).isTrue();

        // L'examen blanc alimente le MEME moteur : c'est tout l'objet de V031.
        observation(user, skill, LearningPlanSourceType.MOCK_EXAM_EE,
                LearningPlanSkillStatus.SOLID, jours(1));

        SkillMasteryEngine.SkillMastery apres =
                resolver.bySkillIds(user.getId(), List.of(skill.getId())).get(skill.getId());
        assertThat(apres.state()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(apres.readyForReassessment()).isFalse();
    }

    @Test
    @DisplayName("Une competence sans aucune observation reste presente, sans etat invente")
    void uneCompetenceSansObservationNInventeRien() {
        User user = data.user();
        Skill skill = data.skill();

        Map<UUID, SkillMasteryEngine.SkillMastery> mastery =
                resolver.bySkillIds(user.getId(), List.of(skill.getId()));

        assertThat(mastery).containsKey(skill.getId());
        assertThat(mastery.get(skill.getId()).state()).isNull();
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
