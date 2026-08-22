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
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
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
 * <p>C'est aussi ce dont {@link PlanFocusResolver} tire la <b>premiere place</b>
 * du Plan, celle que {@code SkillAccessService} ouvre a un compte gratuit : ce
 * qui est verrouille ici l'est pour le Plan et pour le verrou commercial en meme
 * temps.
 */
class LearningPlanPriorityResolverIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanPriorityResolver resolver;
    @Autowired private PlanFocusResolver focusResolver;
    @Autowired private LearningPlanObservationManager observationManager;
    @Autowired private SkillMasteryResolver masteryResolver;
    @Autowired private EntityManager entityManager;

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

        assertThat(focusResolver.currentFocusSkillId(user.getId())).contains(reussie.getId());

        observation(user, reussie, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(1));

        assertThat(focusResolver.currentFocusSkillId(user.getId())).contains(suivante.getId());
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
        assertThat(focusResolver.currentFocusSkillId(user.getId())).isEmpty();
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

    /**
     * Rien n'est verrouille : quand les echecs en situation depassent la
     * tolerance du moteur (2), la competence revient parmi les priorites. Une
     * seule production moins bonne, elle, ne revoque rien — c'est la meme
     * tolerance que celle qui protege {@code SOLID}.
     */
    @Test
    @DisplayName("Deux echecs en situation ramenent la competence parmi les priorites")
    void deuxEchecsEnSituationRamenentLaCompetence() {
        User user = data.user();
        Skill skill = data.skill();
        observation(user, skill, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(15));

        assertThat(codes(user)).isEmpty();

        observation(user, skill, LearningPlanSourceType.MOCK_EXAM_EO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(3));

        assertThat(codes(user)).isEmpty();
        assertThat(franchies(user)).containsExactly(skill.getCode());

        observation(user, skill, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.PRIORITY, jours(2));
        observation(user, skill, LearningPlanSourceType.MOCK_EXAM_EO,
                LearningPlanSkillStatus.PRIORITY, jours(1));

        assertThat(codes(user)).containsExactly(skill.getCode());
        assertThat(franchies(user)).isEmpty();
    }

    /**
     * <b>Le blocage mesure sur {@code user@sejourfr.fr} / {@code EE1-C8}</b>,
     * rejoue depuis la vraie base : trois preuves en situation, une production
     * moins bonne, puis les cinq sujets de l'etape valides. La competence sortait
     * definitivement du parcours sans jamais pouvoir en sortir — ni priorite
     * levee, ni verification proposee.
     */
    @Test
    @DisplayName("Trois preuves en situation tiennent malgre une production moins bonne")
    void troisPreuvesEnSituationNeSontPasRevoqueesParUneProductionMoinsBonne() {
        User user = data.user();
        Skill bloquee = data.skill();
        Skill suivante = data.skill();
        observation(user, bloquee, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(6));
        observation(user, bloquee, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(6));
        observation(user, bloquee, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(5));
        observation(user, bloquee, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(4));
        observation(user, suivante, LearningPlanSourceType.PRODUCTION_EO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(5));
        for (int sujet = 0; sujet < 5; sujet++) {
            observation(user, bloquee, LearningPlanSourceType.SKILL_TRAINING,
                    LearningPlanSkillStatus.TO_REINFORCE, jours(1));
        }

        assertThat(codes(user)).containsExactly(suivante.getCode());
        assertThat(franchies(user)).containsExactly(bloquee.getCode());
        assertThat(focusResolver.currentFocusSkillId(user.getId())).contains(suivante.getId());
    }

    /**
     * <b>« Une reussite suffit »</b> : les cinq sujets de l'etape valides puis une
     * seule verification en situation reussie liberent l'etape — sans que l'etat
     * agrege atteigne {@code SOLID}, que les micro-entrainements diluent.
     */
    @Test
    @DisplayName("Cinq sujets valides puis UNE verification reussie liberent l'etape")
    void leParcoursNormalLibereLetape() {
        User user = data.user();
        Skill skill = data.skill();
        observation(user, skill, LearningPlanSourceType.DIAGNOSTIC_EE,
                LearningPlanSkillStatus.PRIORITY, jours(30));
        for (int sujet = 0; sujet < 5; sujet++) {
            observation(user, skill, LearningPlanSourceType.SKILL_TRAINING,
                    LearningPlanSkillStatus.TO_REINFORCE, jours(10 - sujet));
        }

        assertThat(codes(user)).containsExactly(skill.getCode());

        observation(user, skill, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.SOLID, jours(1));

        assertThat(codes(user)).isEmpty();
        assertThat(franchies(user)).containsExactly(skill.getCode());
    }

    /**
     * <b>Le cout ne bouge pas d'une requete.</b> Depuis que « transfert prouve »
     * se lit chez le moteur de maitrise, ce resolveur en depend — mais le moteur
     * travaille sur l'historique <b>deja charge</b>. Les deux lectures a partir
     * d'une liste en memoire ne doivent donc emettre <b>aucune</b> requete.
     *
     * <p>🛑 Et {@link PlanFocusResolver#currentFocusSkillId} — ce que lit
     * {@code SkillAccessService}, donc <b>tous</b> les ecrans de competences —
     * doit en emettre exactement <b>une</b> des lors que le candidat a une
     * fragilite : c'est le retour anticipe qui garde le verrou d'acces au meme
     * cout qu'avant l'arrivee des competences « a acquerir ». Sans lui, le cycle
     * de palier tournerait a chaque ouverture de catalogue.
     */
    @Test
    @DisplayName("Le moteur de maitrise n'ajoute aucune requete au resolveur de priorites")
    void leResolveurNemetAucuneRequeteDePlus() {
        User user = data.user();
        for (int rang = 0; rang < 12; rang++) {
            Skill skill = data.skill();
            observation(user, skill, LearningPlanSourceType.PRODUCTION_EE,
                    rang % 2 == 0 ? LearningPlanSkillStatus.SOLID
                            : LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        }
        entityManager.flush();
        entityManager.clear();
        List<LearningPlanObservation> historique =
                observationManager.findAllByUserWithSkill(user.getId());

        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();

        var mastery = masteryResolver.fromObservations(
                historique, resolver.latestObservedBySkill(historique).keySet());
        assertThat(resolver.actionable(historique, mastery)).isNotEmpty();
        assertThat(resolver.franchies(historique, mastery)).isNotEmpty();
        assertThat(statistics.getPrepareStatementCount()).isZero();

        statistics.clear();
        assertThat(focusResolver.currentFocusSkillId(user.getId())).isPresent();
        assertThat(statistics.getPrepareStatementCount())
                .as("une fragilite suffit : ni cycle de palier, ni referentiel charge")
                .isEqualTo(1);
    }

    private List<String> codes(User user) {
        List<LearningPlanObservation> actionable = resolver.actionable(
                observationManager.findAllByUserWithSkill(user.getId()));
        return actionable.stream().map(item -> item.getSkill().getCode()).toList();
    }

    private List<String> franchies(User user) {
        List<LearningPlanObservation> observations =
                observationManager.findAllByUserWithSkill(user.getId());
        return resolver.franchies(observations, masteryResolver.fromObservations(
                        observations, resolver.latestObservedBySkill(observations).keySet()))
                .stream().map(item -> item.getSkill().getCode()).toList();
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
