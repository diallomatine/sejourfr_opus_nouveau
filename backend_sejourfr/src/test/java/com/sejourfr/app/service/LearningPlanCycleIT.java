package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.PlanPathStepStatus;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le Plan d'un candidat <b>reel</b>, construit de bout en bout contre la vraie
 * base : ses quatre domaines, son cycle de palier, et le <b>cout</b> de la
 * lecture.
 *
 * <p>Le cout est la moitie de l'objet de ce test. Le Plan lit un historique
 * d'observations, six competences de comprehension, six taches d'expression et
 * quatre domaines : si l'une de ces lectures se faisait element par element, la
 * regression serait invisible en unitaire et payee a chaque ouverture de
 * l'ecran. On compte donc les requetes reellement preparees par Hibernate et on
 * verifie qu'elles <b>ne bougent pas</b> quand l'historique grossit — patron de
 * {@code SkillMasteryResolverIT}.
 */
class LearningPlanCycleIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanService service;
    @Autowired private SkillManager skillManager;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Le Plan d'un candidat reel : quatre domaines mesures, un cycle vers le B1")
    void lePlanCompletDunCandidatReel() {
        User user = candidat(TargetProcedure.NAT);
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);

        // Compréhension : deux examens blancs QCM réellement passés.
        examenQcmPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2);
        examenQcmPasse(user, EpreuveType.TCF_CE, NiveauCecrl.B1);
        // Expression : deux productions corrigées.
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EO, NiveauCecrl.A2);

        // CO-A2 consolidée par deux séries ; une fragilité en expression écrite.
        Skill coA2 = seed("CO-A2");
        observation(user, coA2, LearningPlanSourceType.TCF_CO,
                LearningPlanSkillStatus.SOLID, jours(3));
        observation(user, coA2, LearningPlanSourceType.TCF_CO,
                LearningPlanSkillStatus.SOLID, jours(1));
        Skill ee2 = data.skill(SkillTaskCode.EE2);
        observation(user, ee2, LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.state()).isEqualTo(LearningPlanState.ACTIVE);
        // Les quatre domaines, toujours, ordonnés par le serveur.
        assertThat(plan.domaines()).hasSize(4);
        assertThat(plan.domaines()).allSatisfy(domaine ->
                assertThat(domaine.evaluated()).isTrue());
        assertThat(plan.domaines().getFirst().priority()).isEqualTo(PlanDomainPriority.FORTE);
        assertThat(plan.domaines().getFirst().epreuve()).isEqualTo(EpreuveType.TCF_EE);

        // Le cycle part du plancher mesuré (A2) et vise le cran au-dessus.
        assertThat(plan.cycle().startingLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(plan.cycle().targetLevel()).isEqualTo(TargetLevel.B1);
        assertThat(plan.cycle().objectiveLevel()).isEqualTo(TargetLevel.B2);
        assertThat(plan.cycle().profileComplete()).isTrue();
        assertThat(plan.cycle().domainsEvaluated()).isEqualTo(4);
        // Une fragilité reste ouverte : le palier n'est pas prêt à être confirmé.
        assertThat(plan.cycle().state()).isEqualTo(PlanCycleState.TRAINING);
        assertThat(plan.cycle().path())
                .filteredOn(etape -> etape.status() == PlanPathStepStatus.CURRENT)
                .hasSize(1);

        // Compréhension : la règle de prérequis se lit sur les trois paliers.
        PlanDomainDto co = domaine(plan, EpreuveType.TCF_CO);
        assertThat(co.paliers()).hasSize(3);
        assertThat(co.paliers().getFirst().masteryState()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(co.consolidatedLevel()).isEqualTo(TargetLevel.A2);
        assertThat(co.blockingLevel()).isEqualTo(TargetLevel.B1);
        assertThat(co.taches()).isEmpty();

        // Expression : les trois tâches et leur couverture.
        PlanDomainDto ee = domaine(plan, EpreuveType.TCF_EE);
        assertThat(ee.taches()).hasSize(3);
        assertThat(ee.taches().get(1).taskCode()).isEqualTo(SkillTaskCode.EE2);
        assertThat(ee.taches().get(1).observedSkills()).isEqualTo(1);
        assertThat(ee.taches().get(1).totalSkills()).isGreaterThanOrEqualTo(8);
        assertThat(ee.paliers()).isEmpty();
    }

    /**
     * Brief §77 : trois domaines mesures et rien de fragile ne suffisent pas.
     * Le Plan reclame d'abord de completer le profil ; le gate n'a rien a
     * confirmer sur un domaine jamais mesure.
     */
    @Test
    @DisplayName("Profil a 3 sur 4 : aucun examen de palier, meme sans priorite restante")
    void unProfilIncompletNouvrePasLeGate() {
        User user = candidat(TargetProcedure.NAT);
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        examenQcmPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.cycle().domainsEvaluated()).isEqualTo(3);
        assertThat(plan.cycle().state()).isEqualTo(PlanCycleState.BUILDING_BASELINE);
        assertThat(plan.milestone()).isNull();
        assertThat(domaine(plan, EpreuveType.TCF_CE).priority())
                .isEqualTo(PlanDomainPriority.A_EVALUER);
        assertThat(domaine(plan, EpreuveType.TCF_CE).niveau()).isNull();
    }

    /**
     * Le cout de la lecture ne doit pas dependre du nombre de competences
     * observees : tout se charge en lot. On mesure deux fois, avec un historique
     * quatre fois plus gros la seconde fois.
     */
    @Test
    @DisplayName("Le cout du Plan ne grandit pas avec l'historique")
    void leCoutDuPlanNeGrandiPasAvecLHistorique() {
        User user = candidat(TargetProcedure.NAT);
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        examenQcmPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2);
        examenQcmPasse(user, EpreuveType.TCF_CE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        for (SkillTaskCode code : new SkillTaskCode[]{SkillTaskCode.EE1, SkillTaskCode.EO1}) {
            observation(user, data.skill(code), LearningPlanSourceType.PRODUCTION_EE,
                    LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        }
        flush();

        // Une premiere lecture pour amorcer le contexte (metadonnees, plans).
        service.get(user.getId());
        long petit = requetes(user);

        for (SkillTaskCode code : SkillTaskCode.values()) {
            for (int rang = 0; rang < 3; rang++) {
                observation(user, data.skill(code), LearningPlanSourceType.PRODUCTION_EE,
                        LearningPlanSkillStatus.TO_REINFORCE, jours(2));
            }
        }
        flush();
        long grand = requetes(user);

        // Mesure du jour : 19 requetes pour un Plan complet, dont 7 pour le
        // cycle et les domaines (le compte, les quatre epreuves du profil TCF,
        // les six competences de comprehension en un lot, les six taches en un
        // lot). La borne est large a dessein : ce qui compte, c'est l'egalite
        // ci-dessous — une requete par competence ferait exploser la seconde
        // mesure, pas la premiere.
        assertThat(petit).isPositive().isLessThan(30);
        assertThat(grand)
                .as("le Plan se charge en lot : 2 competences observees ou 20, meme cout")
                .isEqualTo(petit);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    /** Requetes reellement preparees par une lecture du Plan, contexte vide. */
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

    private User candidat(TargetProcedure procedure) {
        User user = data.user();
        user.setTargetProcedure(procedure);
        user.setTargetLevel(procedure.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /** Une competence du referentiel publie (V318), designee par son code. */
    private Skill seed(String code) {
        return skillManager.findByCode(code).orElseThrow();
    }

    /**
     * Un examen blanc QCM reellement passe : termine, avec au moins une reponse
     * — c'est exactement ce que {@code TcfProfileService} exige pour compter une
     * epreuve de comprehension.
     */
    private void examenQcmPasse(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        Attempt attempt = data.attempt(user);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(epreuve);
        attempt.setMode(AttemptMode.EXAMEN);
        attempt.setStatus(AttemptStatus.TERMINE);
        attempt.setFinishedAt(Instant.now());
        attempt.setCecrlLevel(niveau);
        AttemptQuestion question = data.attemptQuestion(attempt, data.question());
        data.answer(question);
    }

    /** Une production corrigee : c'est elle qui donne son niveau a EE ou EO. */
    private void productionEvaluee(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        ProductionSubmission submission = data.productionSubmission(
                data.attempt(user), data.productionTask(epreuve), user);
        data.aiEvaluation(submission).setNiveauCecrl(niveau);
    }

    private void observation(
            User user, Skill skill, LearningPlanSourceType source,
            LearningPlanSkillStatus status, Instant quand) {
        data.learningPlanObservation(user, skill, source, status,
                ObservationConfidence.HIGH, UUID.randomUUID(), quand);
    }

    private static PlanDomainDto domaine(LearningPlanDto plan, EpreuveType epreuve) {
        return plan.domaines().stream()
                .filter(item -> item.epreuve() == epreuve)
                .findFirst()
                .orElseThrow();
    }

    private static Instant jours(int nombre) {
        return Instant.now().minus(nombre, ChronoUnit.DAYS);
    }
}
