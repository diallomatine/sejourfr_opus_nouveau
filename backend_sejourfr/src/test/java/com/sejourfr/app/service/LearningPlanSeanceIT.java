package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.PlanSeanceItemDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La <b>seance du jour</b> d'un candidat reel, servie de bout en bout contre la
 * vraie base — et le prix qu'elle coute.
 *
 * <p>Deux choses ne se verifient qu'ici. D'abord la regle « sticky » : on fait
 * <b>vieillir l'historique de quarante jours</b>, ce qui revient exactement a
 * relire le Plan quarante jours plus tard sans que le candidat ait rien fait, et
 * on exige la meme seance. Ensuite le cout : le Plan porte desormais deux blocs
 * de plus, tous deux derives de donnees deja chargees — le compte de requetes ne
 * doit pas bouger d'une unite quand l'historique grossit.
 */
class LearningPlanSeanceIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanService service;
    @Autowired private SkillManager skillManager;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("La seance d'un candidat reel : ses priorites, leurs actions, son total")
    void laSeanceDunCandidatReel() {
        User user = candidat();
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        // Une comprehension fragile : elle se travaille par une serie ciblee.
        Skill coB1 = seed("CO-B1");
        observation(user, coB1, LearningPlanSourceType.TCF_CO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(1));
        // Deux competences d'expression fragiles : deux petits sujets.
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        observation(user, seed("EO1-C1"), LearningPlanSourceType.PRODUCTION_EO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(3));
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.state()).isEqualTo(LearningPlanState.ACTIVE);
        assertThat(plan.seance().items()).hasSize(3);
        // Chaque entrainement porte une action reellement lancable.
        assertThat(plan.seance().items()).allSatisfy(item ->
                assertThat(item.exercise()).isNotNull());
        assertThat(plan.seance().estimatedMinutes())
                .isEqualTo(plan.seance().items().stream()
                        .mapToInt(item -> item.exercise().estimatedMinutes()).sum())
                .isPositive();

        // La comprehension se lance avec la seule competence.
        PlanSeanceItemDto serie = item(plan, SkillSection.CO);
        assertThat(serie.exercise().kind()).isEqualTo(PlanExerciseKind.TARGETED_QCM_SERIES);
        assertThat(serie.exercise().skillId()).isEqualTo(coB1.getId());
        assertThat(serie.exercise().questionCount()).isEqualTo(20);
        assertThat(serie.level()).isEqualTo("B1");

        // L'expression garde ses petits sujets et ses compteurs d'etape.
        PlanSeanceItemDto sujet = item(plan, SkillSection.EO);
        assertThat(sujet.exercise().kind()).isEqualTo(PlanExerciseKind.MICRO_TRAINING);
        assertThat(sujet.exercise().skillPromptId()).isNotNull();
        assertThat(sujet.stepPromptCount()).isPositive();
        assertThat(sujet.masteryState()).isNotNull();

        // Une competence = un item : trois competences, trois lignes, jamais six.
        assertThat(plan.seance().items()).extracting(PlanSeanceItemDto::skillId)
                .doesNotHaveDuplicates();
    }

    /**
     * 🛑 La regle produit : « nouveau jour &rarr; competence oubliee » ne doit
     * jamais arriver. On vieillit tout l'historique de quarante jours — le
     * candidat n'a rien fait, seul le calendrier a avance — et on relit.
     */
    @Test
    @DisplayName("Quarante jours plus tard, sans rien faire : la meme seance")
    void laSeanceSurvitAuPassageDuTemps() {
        User user = candidat();
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        observation(user, seed("EO1-C1"), LearningPlanSourceType.PRODUCTION_EO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(3));
        flush();

        List<UUID> avant = competences(service.get(user.getId()));

        vieillirDeQuaranteJours(user);

        LearningPlanDto plusTard = service.get(user.getId());
        assertThat(competences(plusTard))
                .as("une competence non reussie ne quitte pas la seance parce que la date a changé")
                .isEqualTo(avant);
        assertThat(plusTard.seance().items()).allSatisfy(item ->
                assertThat(item.masteryState()).isNotEqualTo(SkillMasteryState.SOLID));
    }

    /**
     * Le Plan porte deux blocs de plus, tous deux derives de donnees deja
     * chargees : le cout ne doit pas grandir avec l'historique. Patron de
     * {@code LearningPlanCycleIT}.
     */
    @Test
    @DisplayName("La seance et les changements ne coutent aucune requete de plus")
    void leCoutNeGrandiPasAvecLHistorique() {
        User user = candidat();
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        observation(user, seed("EE1-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        observation(user, seed("EO1-C1"), LearningPlanSourceType.PRODUCTION_EO,
                LearningPlanSkillStatus.TO_REINFORCE, jours(3));
        flush();

        service.get(user.getId());
        long deuxCompetences = requetes(user);

        // Dix-huit competences de plus, toutes PLUS ANCIENNES que les deux
        // premieres : les priorites — donc la seance — restent les memes, et ce
        // qu'on mesure est bien le CHARGEMENT, pas un changement de contenu.
        for (SkillTaskCode tache : SkillTaskCode.values()) {
            for (int rang = 2; rang <= 3; rang++) {
                observation(user, seed(tache.name() + "-C" + rang),
                        LearningPlanSourceType.PRODUCTION_EE,
                        LearningPlanSkillStatus.TO_REINFORCE, jours(30));
            }
        }
        for (String code : new String[]{"CO-A2", "CO-B1", "CE-A2", "CE-B1"}) {
            observation(user, seed(code), LearningPlanSourceType.TCF_CO,
                    LearningPlanSkillStatus.TO_REINFORCE, jours(30));
        }
        flush();
        long vingtCompetences = requetes(user);

        assertThat(deuxCompetences).isPositive();
        assertThat(vingtCompetences)
                .as("la seance et « ce qui a change » se derivent de ce qui est deja charge")
                .isEqualTo(deuxCompetences);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private static List<UUID> competences(LearningPlanDto plan) {
        return plan.seance().items().stream().map(PlanSeanceItemDto::skillId).toList();
    }

    private static PlanSeanceItemDto item(LearningPlanDto plan, SkillSection section) {
        return plan.seance().items().stream()
                .filter(item -> item.section() == section)
                .findFirst()
                .orElseThrow();
    }

    /** Le calendrier avance, le candidat ne fait rien : ses lignes reculent. */
    private void vieillirDeQuaranteJours(User user) {
        flush();
        entityManager.createNativeQuery(
                        "UPDATE learning_plan_observations "
                                + "SET observed_at = observed_at - interval '40 days' "
                                + "WHERE user_id = :user")
                .setParameter("user", user.getId())
                .executeUpdate();
        flush();
    }

    private long requetes(User user) {
        flush();
        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();
        service.get(user.getId());
        return statistics.getPrepareStatementCount();
    }

    private void flush() {
        entityManager.flush();
        entityManager.clear();
    }

    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    private Skill seed(String code) {
        return skillManager.findByCode(code).orElseThrow();
    }

    private void observation(
            User user, Skill skill, LearningPlanSourceType source,
            LearningPlanSkillStatus status, Instant quand) {
        data.learningPlanObservation(user, skill, source, status,
                ObservationConfidence.HIGH, UUID.randomUUID(), quand);
    }

    private static Instant jours(int nombre) {
        return Instant.now().minus(nombre, ChronoUnit.DAYS);
    }
}
