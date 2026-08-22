package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.ComprehensionObservationService.ReponseComprehension;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le producteur d'observations CO / CE et la serie ciblee, sur base reelle : un
 * examen d'epreuve reellement joue, l'idempotence sur double production, et le
 * tirage d'une serie de 20 questions du bon domaine et du bon niveau.
 *
 * <p>Assertions <b>tolerantes au seed Flyway</b> : la banque de questions et les
 * six competences de comprehension (V318) sont seedees, on filtre donc toujours
 * sur ce que le test a cree ou demande, jamais sur un total de table.
 *
 * <p><b>Hors transaction de test</b> ({@link Propagation#NOT_SUPPORTED}, comme
 * {@code DiagnosticPostSignupSequenceIT}) : le producteur ecrit ses observations
 * dans sa PROPRE transaction, elle ne verrait rien de ce qu'une transaction de
 * test non commitee contient. C'est precisement ce montage qu'on veut exercer —
 * le neutraliser pour la commodite du test reviendrait a ne pas le tester. Le
 * menage se fait donc a la main, dans un {@code finally}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ComprehensionObservationIT extends AbstractIntegrationTest {

    @Autowired AttemptService attemptService;
    @Autowired ComprehensionObservationService observationService;
    @Autowired LearningPlanService planService;
    @Autowired LearningPlanObservationManager observationManager;
    @Autowired AttemptQuestionManager attemptQuestionManager;
    @Autowired SkillManager skillManager;
    @Autowired QuestionManager questionManager;
    @Autowired PlatformTransactionManager txManager;
    @Autowired AccountDeletionService accountDeletionService;
    @Autowired TestData data;

    private final List<User> crees = new ArrayList<>();

    /** Compte de test, dont le menage est garanti par {@link #nettoie()}. */
    private User utilisateur() {
        User user = data.user();
        crees.add(user);
        return user;
    }

    /**
     * Menage explicite : hors transaction de test, rien n'est annule tout seul.
     * La suppression de compte purge observations, sessions puis attempts.
     */
    @AfterEach
    void nettoie() {
        crees.forEach(user -> accountDeletionService.deleteAccount(user.getId()));
        crees.clear();
    }

    // ------------------------------------------------------------------ examen joue

    @Test
    @DisplayName("Un examen d'epreuve CO alimente les trois competences CO, chacune sur ses questions")
    void unExamenCoAlimenteLesTroisCompetences() {
        User user = utilisateur();
        // Slot 1 d'un examen d'epreuve : offert a tout compte inscrit.
        AttemptResponse started = attemptService.start(user.getId(), examenEpreuve(QuestionType.CO));
        // On repond JUSTE a tout le A2 et faux au reste : le score total ment,
        // la verite par niveau est celle que le Plan doit retenir.
        repondreJuste(user, started.id(), Difficulty.A2);

        attemptService.finish(user.getId(), started.id());

        Map<String, LearningPlanObservation> observations = observationsDe(user);
        assertThat(observations).containsKeys("CO-A2", "CO-B1", "CO-B2");
        assertThat(observations.get("CO-A2").getStatus()).isEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(observations.get("CO-B1").getStatus()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
        assertThat(observations.get("CO-B2").getStatus()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
        assertThat(observations.values()).allSatisfy(observation -> {
            assertThat(observation.getSourceType()).isEqualTo(LearningPlanSourceType.TCF_CO);
            assertThat(observation.getSourceId()).isEqualTo(started.id());
            assertThat(observation.getSubjectId()).isEqualTo(started.id());
            assertThat(observation.isBaseline()).isFalse();
        });
        // Aucune competence de comprehension ECRITE n'est touchee par un examen CO.
        assertThat(observations).doesNotContainKeys("CE-A2", "CE-B1", "CE-B2");
    }

    @Test
    @DisplayName("Rejouer la production sur la meme session ne cree aucun doublon")
    void laProductionEstIdempotenteSurLaSession() {
        User user = utilisateur();
        AttemptResponse started = attemptService.start(user.getId(), examenEpreuve(QuestionType.CE));
        attemptService.finish(user.getId(), started.id());
        int apresPremiere = observationsDe(user).size();
        assertThat(apresPremiere).isPositive();

        // 1) Le second `finish` retombe sur le point d'idempotence de la session.
        attemptService.finish(user.getId(), started.id());
        // 2) Et meme une production forcee — rejeu de job, double envoi mobile —
        //    n'ecrit rien de plus : la cle est (user, competence, source, attempt).
        int ecrites = observationService.record(
                user.getId(), started.id(), Instant.now(), reponsesDe(questionsDe(started.id())));

        assertThat(ecrites).isZero();
        assertThat(observationsDe(user)).hasSize(apresPremiere);
    }

    /**
     * <b>Le branchement complet</b> : un examen d'epreuve CO reellement joue
     * remonte jusqu'au Plan — le domaine passe a « mesure » ({@code cycle},
     * {@code domaines}), ses trois paliers portent un etat, et la comprehension
     * devient une <b>priorite</b> comme n'importe quelle competence.
     *
     * <p>C'est le seul endroit ou la chaine entiere est exercee dans les
     * conditions reelles : le producteur d'observations ecrit dans sa PROPRE
     * transaction, ce qu'un test transactionnel ne verrait jamais.
     */
    @Test
    @DisplayName("Une epreuve CO jouee remonte jusqu'aux domaines, au cycle et aux priorites du Plan")
    void uneEpreuveCoRemonteJusquAuPlan() {
        User user = utilisateur();
        // Le Plan ne calcule ses priorites qu'apres un diagnostic termine ; le
        // PROFIL, lui, n'en depend pas — c'est ce que teste le cas voisin.
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);

        AttemptResponse started = attemptService.start(user.getId(), examenEpreuve(QuestionType.CO));
        repondreJuste(user, started.id(), Difficulty.A2);
        attemptService.finish(user.getId(), started.id());

        LearningPlanDto plan = planService.get(user.getId());

        // Le domaine est desormais mesure : il sort de « completer mon profil ».
        assertThat(plan.cycle().domainsEvaluated()).isEqualTo(1);
        assertThat(plan.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        PlanDomainDto co = plan.domaines().stream()
                .filter(domaine -> domaine.epreuve() == EpreuveType.TCF_CO)
                .findFirst().orElseThrow();
        assertThat(co.evaluated()).isTrue();
        assertThat(co.paliers()).hasSize(3);
        assertThat(co.paliers().getFirst().masteryState()).isNotNull();
        // Et la comprehension est traitee comme une competence a part entiere :
        // les paliers rates deviennent des priorites du Plan.
        assertThat(plan.currentPriority()).isNotNull();
        assertThat(plan.currentPriority().skillCode()).startsWith("CO-");
    }

    // ------------------------------------------------------------------ serie ciblee

    @Test
    @DisplayName("Une serie ciblee tire 20 questions du bon domaine et du bon niveau")
    void laSerieCibleeEstReellementCiblee() {
        User user = utilisateur();
        data.userSubscription(user, data.plan());
        Skill ceB1 = competence("CE-B1");

        AttemptResponse started = attemptService.start(user.getId(), serie(ceB1.getId()));

        assertThat(started.totalQuestions()).isEqualTo(20);
        assertThat(questionsDe(started.id()))
                .hasSize(20)
                .allSatisfy(question -> {
                    assertThat(question.type()).isEqualTo(QuestionType.CE);
                    assertThat(question.difficulty()).isEqualTo(Difficulty.B1);
                });
    }

    @Test
    @DisplayName("Une serie ciblee CO privilegie les questions jamais vues")
    void laSerieCibleePrivilegieLesQuestionsJamaisVues() {
        User user = utilisateur();
        data.userSubscription(user, data.plan());
        Skill coB2 = competence("CO-B2");

        List<UUID> premiere = idsQuestions(attemptService.start(user.getId(), serie(coB2.getId())));
        List<UUID> seconde = idsQuestions(attemptService.start(user.getId(), serie(coB2.getId())));

        // Aucune question deja vue ne peut passer devant une question neuve :
        // les seules repetitions tolerees sont celles qu'impose l'epuisement du
        // pool. Sur la banque seedee, ce compte vaut 0 des qu'il reste 40
        // questions CO B2 ; l'ecrire ainsi rend le test independant du volume
        // de contenu, qui grossira.
        long pool = questionManager.countActiveMatching(
                Module.TCF, null, Difficulty.B2, QuestionType.CO);
        long repetitionsInevitables = Math.max(0, 2L * 20 - pool);
        assertThat(seconde).filteredOn(premiere::contains).hasSize((int) repetitionsInevitables);
    }

    @Test
    @DisplayName("Une serie ciblee refuse une competence d'expression")
    void laSerieCibleeRefuseUneCompetenceDExpression() {
        User user = utilisateur();
        data.userSubscription(user, data.plan());
        Skill expression = data.skill();

        assertThatThrownBy(() -> attemptService.start(user.getId(), serie(expression.getId())))
                .isInstanceOf(com.sejourfr.app.exception.BusinessException.class);
    }

    @Test
    @DisplayName("Le verrou freemium des competences est opposable a la serie ciblee")
    void leVerrouFreemiumEstOpposableALaSerie() {
        User user = utilisateur();
        // Compte gratuit : seul le niveau le plus bas de chaque domaine est ouvert.
        Skill coB2 = competence("CO-B2");

        assertThatThrownBy(() -> attemptService.start(user.getId(), serie(coB2.getId())))
                .isInstanceOf(AccessDeniedException.class);

        // ... et le A2 du meme domaine reste jouable sans abonnement.
        AttemptResponse offerte = attemptService.start(user.getId(), serie(competence("CO-A2").getId()));
        assertThat(offerte.totalQuestions()).isEqualTo(20);
    }

    // ------------------------------------------------------------------ compte gratuit

    @Test
    @DisplayName("Un entrainement gratuit cible n'est plus servi par un pool hors sujet")
    void lEntrainementGratuitRespecteLesFiltres() {
        User user = utilisateur();

        AttemptResponse started = attemptService.start(user.getId(), new StartAttemptRequest(
                AttemptType.TRAINING, Module.TCF, null, null,
                Difficulty.B2, QuestionType.CO, 10, null, null, null, null));

        assertThat(started.totalQuestions()).isEqualTo(10);
        assertThat(questionsDe(started.id()))
                .hasSize(10)
                .allSatisfy(question -> {
                    assertThat(question.type()).isIn(QuestionType.CO, QuestionType.CO_IMAGE);
                    assertThat(question.difficulty()).isEqualTo(Difficulty.B2);
                });
    }

    @Test
    @DisplayName("La serie gratuite reste DETERMINISTE : on n'ouvre pas la banque sans abonnement")
    void laSerieGratuiteResteDeterministe() {
        User user = utilisateur();
        StartAttemptRequest req = new StartAttemptRequest(
                AttemptType.TRAINING, Module.TCF, null, null,
                Difficulty.A2, QuestionType.CE, 10, null, null, null, null);

        assertThat(idsQuestions(attemptService.start(user.getId(), req)))
                .isEqualTo(idsQuestions(attemptService.start(user.getId(), req)));
    }

    // ------------------------------------------------------------------ fixtures

    private StartAttemptRequest examenEpreuve(QuestionType epreuve) {
        return new StartAttemptRequest(AttemptType.MOCK_EXAM, Module.TCF, null, null,
                null, null, null, null, epreuve, 1, null);
    }

    private StartAttemptRequest serie(UUID skillId) {
        return new StartAttemptRequest(AttemptType.TRAINING, Module.TCF, null, null,
                null, null, null, null, null, null, skillId);
    }

    private Skill competence(String code) {
        return skillManager.findByCode(code).orElseThrow();
    }

    /**
     * Une question de la session, aplatie : hors transaction de test, les
     * proxies Hibernate ne sont plus chargeables, donc la lecture se fait EN
     * transaction et ne rend que des valeurs.
     */
    private record QuestionJouee(
            UUID attemptQuestionId, UUID questionId, QuestionType type,
            Difficulty difficulty, UUID bonneReponse, boolean correcte) {}

    private List<QuestionJouee> questionsDe(UUID attemptId) {
        return new TransactionTemplate(txManager).execute(status ->
                attemptQuestionManager.findByAttemptOrderedByPosition(attemptId).stream()
                        .map(aq -> new QuestionJouee(
                                aq.getId(),
                                aq.getQuestion().getId(),
                                aq.getQuestion().getQuestionType(),
                                aq.getQuestion().getDifficulty(),
                                aq.getQuestion().getChoices().stream()
                                        .filter(Choice::isCorrect).map(Choice::getId)
                                        .findFirst().orElseThrow(),
                                aq.getAnswer() != null
                                        && Boolean.TRUE.equals(aq.getAnswer().getCorrect())))
                        .toList());
    }

    private void repondreJuste(User user, UUID attemptId, Difficulty niveau) {
        for (QuestionJouee question : questionsDe(attemptId)) {
            if (question.difficulty() != niveau) continue;
            attemptService.submitAnswer(user.getId(), attemptId, new SubmitAnswerRequest(
                    question.attemptQuestionId(), List.of(question.bonneReponse())));
        }
    }

    private static List<ReponseComprehension> reponsesDe(List<QuestionJouee> questions) {
        return questions.stream()
                .map(q -> new ReponseComprehension(q.type(), q.difficulty(), q.correcte()))
                .toList();
    }

    private Map<String, LearningPlanObservation> observationsDe(User user) {
        return observationManager.findAllByUserWithSkill(user.getId()).stream()
                .collect(Collectors.toMap(o -> o.getSkill().getCode(), Function.identity()));
    }

    private List<UUID> idsQuestions(AttemptResponse response) {
        return questionsDe(response.id()).stream().map(QuestionJouee::questionId).toList();
    }
}
