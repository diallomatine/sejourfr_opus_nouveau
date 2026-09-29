package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le <b>perimetre de l'etape</b> contre la vraie base : l'ordre vient du
 * {@code display_order} de {@code skill_prompts}, et il ne coute <b>aucune
 * requete de plus</b>.
 *
 * <p>Les sujets etaient deja charges pour les compteurs ; publier leurs
 * identifiants ne doit rien ajouter. Le Plan demande jusqu'a onze competences
 * d'un coup — une requete par competence y serait un N+1 invisible en unitaire
 * et couteux en production, d'ou le comptage des statements prepares, comme dans
 * {@code SkillMasteryResolverIT}.
 */
class SkillProgressCounterIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private SkillProgressCounter counter;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("15 sujets publies : l'etape en designe 5, dans l'ordre du catalogue")
    void lEtapeDesigneLesCinqPremiersSujetsDansLOrdreDuCatalogue() {
        User user = data.user();
        Skill skill = data.skill();
        List<SkillPrompt> publies = new ArrayList<>();
        for (int rang = 0; rang < 15; rang++) {
            publies.add(data.skillPrompt(skill));
        }

        LearningPlanStep.Progress step = step(user, skill);

        assertThat(step.promptCount()).isEqualTo(LearningPlanStep.PROMPTS_PAR_ETAPE);
        assertThat(step.promptIds()).containsExactly(
                publies.get(0).getId(), publies.get(1).getId(), publies.get(2).getId(),
                publies.get(3).getId(), publies.get(4).getId());
    }

    /**
     * Une competence qui publie moins de cinq sujets a une etape plus courte :
     * le perimetre vaut ce qui existe, aucun identifiant n'est invente.
     */
    @Test
    @DisplayName("Moins de 5 sujets actifs : etape plus courte, rien d'invente")
    void uneCompetenceDeTroisSujetsALeperimetreDeCeQuiExiste() {
        User user = data.user();
        Skill skill = data.skill();
        List<SkillPrompt> publies = List.of(
                data.skillPrompt(skill), data.skillPrompt(skill), data.skillPrompt(skill));

        LearningPlanStep.Progress step = step(user, skill);

        assertThat(step.promptIds()).containsExactly(
                publies.get(0).getId(), publies.get(1).getId(), publies.get(2).getId());
        assertThat(step.promptCount()).isEqualTo(3);
    }

    @Test
    @DisplayName("Aucun sujet actif : perimetre vide, jamais une erreur")
    void uneCompetenceSansSujetActifRendUnPerimetreVide() {
        User user = data.user();
        Skill skill = data.skill();

        LearningPlanStep.Progress step = step(user, skill);

        assertThat(step.promptIds()).isEmpty();
        assertThat(step.promptCount()).isZero();
        assertThat(step.completed()).isFalse();
    }

    @Test
    @DisplayName("12 competences, DEUX requetes — le perimetre n'en ajoute aucune")
    void lePerimetreNAjouteAucuneRequete() {
        User user = data.user();
        List<UUID> skillIds = new ArrayList<>();
        for (SkillTaskCode code : List.of(SkillTaskCode.EE1, SkillTaskCode.EE2, SkillTaskCode.EE3,
                SkillTaskCode.EO1, SkillTaskCode.EO2, SkillTaskCode.EO3)) {
            for (int i = 0; i < 2; i++) {
                Skill skill = data.skill(code);
                data.skillPrompt(skill);
                data.skillPrompt(skill);
                skillIds.add(skill.getId());
            }
        }
        entityManager.flush();
        entityManager.clear();

        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();

        Map<UUID, SkillProgressCounter.SkillProgress> progress =
                counter.bySkillIds(user.getId(), skillIds);

        assertThat(skillIds).hasSize(12);
        assertThat(progress).hasSize(12);
        assertThat(progress.values())
                .allSatisfy(item -> assertThat(item.step().promptIds()).hasSize(2));
        assertThat(statistics.getPrepareStatementCount()).isEqualTo(2);
    }

    private LearningPlanStep.Progress step(User user, Skill skill) {
        return counter.bySkillIds(user.getId(), List.of(skill.getId()))
                .get(skill.getId())
                .step();
    }
}
