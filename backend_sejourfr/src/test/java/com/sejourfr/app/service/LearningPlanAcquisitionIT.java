package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
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
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
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
 * <b>Ce qu'il reste a APPRENDRE</b>, contre la vraie base et le referentiel
 * reellement publie.
 *
 * <p>Le defaut corrige, mesure sur un compte reel : six competences ecrites
 * solides, deux fragiles, l'oral inexploitable — et un Plan qui proposait
 * <b>deux</b> actions a un candidat A2 visant le B2, a qui il reste un palier
 * entier devant lui. Le Plan savait <b>reparer</b> ; il ne savait pas
 * <b>enseigner</b>.
 *
 * <p>Ce qui ne se verifie qu'ici : les competences a acquerir sortent du
 * <b>referentiel publie</b> ({@code skills.target_level}), pas d'un mock — donc
 * le palier demande existe vraiment, et le cout de sa lecture est mesurable.
 */
class LearningPlanAcquisitionIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private LearningPlanService service;
    @Autowired private SkillManager skillManager;
    @Autowired private EntityManager entityManager;

    /**
     * 🛑 Le cas de reference, reproduit ligne pour ligne : deux fragilites
     * ecrites, un oral rendu mais jamais observable. La seance doit <b>ouvrir sur
     * la mesure de l'oral</b> — tant qu'on ne l'a pas mesure, tout le reste
     * travaille a l'aveugle — puis servir les deux fragilites.
     */
    @Test
    @DisplayName("Compte de reference : deux fragilites ecrites et la mesure de l'oral")
    void leCompteDeReferenceRecoitSesDeuxFragilitesEtLaMesureDeSonOral() {
        User user = profilComplet();
        // Six competences ecrites solides : elles ne reviennent jamais.
        for (String code : new String[]{"EE1-C1", "EE1-C2", "EE1-C3"}) {
            observation(user, seed(code), LearningPlanSourceType.PRODUCTION_EE,
                    LearningPlanSkillStatus.SOLID, jours(20));
            observation(user, seed(code), LearningPlanSourceType.MOCK_EXAM_EE,
                    LearningPlanSkillStatus.SOLID, jours(10));
        }
        // Deux fragilites ecrites : c'est ce qui bloque maintenant.
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        observation(user, seed("EE3-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(3));
        // L'oral a bien ete rendu — et le correcteur n'a rien pu y observer.
        for (String code : new String[]{"EO1-C1", "EO2-C1", "EO3-C1"}) {
            observation(user, seed(code), LearningPlanSourceType.PRODUCTION_EO,
                    LearningPlanSkillStatus.NOT_OBSERVED, jours(1));
        }
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.seance().items()).hasSize(PlanSeanceBuilder.MAX_ITEMS);
        assertThat(plan.seance().items().getFirst()).satisfies(mesure -> {
            assertThat(mesure.nature()).isEqualTo(PlanActionNature.A_EVALUER);
            assertThat(mesure.assessment().epreuve()).isEqualTo(EpreuveType.TCF_EO);
            assertThat(mesure.exercise()).isNull();
            assertThat(mesure.skillId()).isNull();
        });
        assertThat(plan.seance().items().subList(1, 3)).allSatisfy(item -> {
            assertThat(item.nature()).isEqualTo(PlanActionNature.A_RENFORCER);
            assertThat(item.section()).isEqualTo(SkillSection.EE);
            assertThat(item.exercise()).isNotNull();
        });
        assertThat(plan.seance().items()).extracting("skillCode")
                .containsExactly(null, "EE2-C1", "EE3-C1");
        // 🛑 Une competence solide n'est jamais reproposee, ni comme fragilite ni
        // comme acquisition — elle est finie.
        assertThat(plan.nextPriorities()).extracting(LearningPlanPriorityDto::skillCode)
                .doesNotContain("EE1-C1", "EE1-C2", "EE1-C3");
    }

    /**
     * 🛑 Le cœur du chantier : <b>non fragile &ne; plus rien a apprendre</b>. Un
     * candidat dont rien n'est fragile, mais qui n'a pas atteint son objectif,
     * recoit des competences du palier en construction — jamais travaillees, donc
     * sans le moindre verdict.
     */
    @Test
    @DisplayName("Sans fragilite mais loin de l'objectif : des competences a acquerir")
    void sansFragiliteLeCandidatRecoitDesCompetencesAAcquerir() {
        User user = profilComplet();
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(plan.currentPriority())
                .as("le Plan a quelque chose a proposer, meme sans aucune fragilite")
                .isNotNull();
        assertThat(plan.currentPriority().nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
        // 🛑 Rien d'observe : on n'invente pas de verdict pour remplir un champ.
        assertThat(plan.currentPriority().status()).isNull();
        assertThat(plan.currentPriority().masteryState()).isNull();
        assertThat(plan.currentPriority().observedAt()).isNull();
        assertThat(plan.currentPriority().recommendedExercise()).isNotNull();

        // Toutes les cartes servies sont des acquisitions, et chacune porte le
        // palier attendu de SON domaine — jamais un autre.
        //
        // ⚠️ Les deux paliers ne sont pas le meme, et c'est voulu : la
        // comprehension a une chaine de prerequis (A2 solide avant B1), donc une
        // competence CO/CE suit le palier BLOQUANT de son domaine, que le palier
        // global du cycle peut depasser. L'expression, elle, suit le cycle.
        String duCycle = plan.cycle().targetLevel().name();
        for (LearningPlanPriorityDto carte : toutesLesCartes(plan)) {
            assertThat(carte.nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
            String attendu = carte.section().isComprehension()
                    ? bloquant(plan, carte.section()) : duCycle;
            assertThat(seed(carte.skillCode()).getTargetLevel())
                    .as("un palier hors de celui que ce domaine construit n'a rien a faire ici")
                    .isEqualTo(attendu);
        }
    }

    /** Le palier que le serveur a designe comme bloquant pour ce domaine. */
    private static String bloquant(LearningPlanDto plan, SkillSection section) {
        EpreuveType epreuve = section == SkillSection.CO ? EpreuveType.TCF_CO : EpreuveType.TCF_CE;
        return plan.domaines().stream()
                .filter(domaine -> domaine.epreuve() == epreuve)
                .findFirst()
                .orElseThrow()
                .blockingLevel()
                .name();
    }

    /**
     * 🛑 Le plafond est un <b>plafond</b>, jamais un quota : cinq cartes au plus
     * dans « Mes priorites », trois entrainements au plus dans la seance, et rien
     * n'est fabrique pour les atteindre.
     */
    @Test
    @DisplayName("Cinq cartes au plus, trois entrainements au plus — jamais du remplissage")
    void lesPlafondsTiennentSansJamaisRemplir() {
        User user = profilComplet();
        flush();

        LearningPlanDto plan = service.get(user.getId());

        assertThat(toutesLesCartes(plan))
                .hasSizeLessThanOrEqualTo(LearningPlanPriorityResolver.MAX_PRIORITIES);
        assertThat(plan.seance().items())
                .hasSizeLessThanOrEqualTo(PlanSeanceBuilder.MAX_ITEMS);
        // Aucune carte n'est une competence solide travestie en action.
        assertThat(toutesLesCartes(plan)).allSatisfy(carte ->
                assertThat(carte.masteryState()).isNotEqualTo(SkillMasteryState.SOLID));
        // Aucune carte sans action : un item sans exercice n'est pas un entrainement.
        assertThat(plan.seance().items()).allSatisfy(item ->
                assertThat(item.exercise() != null || item.assessment() != null).isTrue());
    }

    /**
     * 🛑 Le referentiel du palier se charge en <b>un lot</b>, et son cout ne
     * depend ni du nombre de competences ni de l'historique du candidat. Patron
     * de {@code LearningPlanCycleIT} — c'est la seule facon d'attraper un N+1 qui
     * serait invisible en unitaire et paye a chaque ouverture de l'ecran.
     */
    @Test
    @DisplayName("Ce qu'il reste a apprendre coute UNE requete, quel que soit l'historique")
    void leCoutDeLAcquisitionNeGrandiPasAvecLHistorique() {
        User user = profilComplet();
        observation(user, seed("EE2-C1"), LearningPlanSourceType.PRODUCTION_EE,
                LearningPlanSkillStatus.TO_REINFORCE, jours(2));
        flush();

        service.get(user.getId());
        long peu = requetes(user);

        // Assez de fragilites pour saturer « Mes priorites » : il ne reste plus
        // AUCUNE place pour une acquisition. Le referentiel se charge quand meme
        // — sinon le cout du Plan dependrait des donnees du candidat, et cette
        // egalite ne pourrait plus rien garantir.
        for (String code : new String[]{"EE3-C1", "EO1-C1", "EO2-C1", "EO3-C1",
                "EE1-C2", "EE1-C3"}) {
            observation(user, seed(code), LearningPlanSourceType.PRODUCTION_EE,
                    LearningPlanSkillStatus.TO_REINFORCE, jours(4));
        }
        flush();
        long beaucoup = requetes(user);

        assertThat(peu).isPositive().isLessThan(30);
        assertThat(beaucoup)
                .as("le palier se charge en lot, et toujours : meme cout a vide ou plein")
                .isEqualTo(peu);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    /**
     * Un candidat visant le B2 dont les <b>quatre domaines sont mesures</b> : un
     * domaine jamais mesure se mesure avant de s'apprendre, il ne donnerait donc
     * rien a acquerir.
     */
    private User profilComplet() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        user = data.saveUser(user);
        data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        examenQcmPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2);
        examenQcmPasse(user, EpreuveType.TCF_CE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        productionEvaluee(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        return user;
    }

    private static java.util.List<LearningPlanPriorityDto> toutesLesCartes(LearningPlanDto plan) {
        java.util.List<LearningPlanPriorityDto> cartes = new java.util.ArrayList<>();
        if (plan.currentPriority() != null) cartes.add(plan.currentPriority());
        cartes.addAll(plan.nextPriorities());
        return cartes;
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

    private Skill seed(String code) {
        return skillManager.findByCode(code).orElseThrow();
    }

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

    private static Instant jours(int nombre) {
        return Instant.now().minus(nombre, ChronoUnit.DAYS);
    }
}
