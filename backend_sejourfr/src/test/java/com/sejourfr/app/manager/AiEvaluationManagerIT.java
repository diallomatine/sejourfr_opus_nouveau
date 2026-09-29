package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link AiEvaluationManager} : dernière éval par
 * submission, filtre par (user, épreuve) avec niveau non null, et compteurs de
 * calibration. Les compteurs globaux sont vérifiés en delta (table partagée).
 */
class AiEvaluationManagerIT extends AbstractIntegrationTest {

    @Autowired
    private AiEvaluationManager manager;

    @Autowired
    private TestData testData;

    private AiEvaluation eval(ProductionSubmission submission,
                              NiveauCecrl niveauCecrl,
                              NiveauCecrl niveauCecrlIa,
                              Instant evaluatedAt) {
        AiEvaluation e = new AiEvaluation();
        e.setSubmission(submission);
        e.setModeleUtilise("claude-test");
        e.setPromptVersion("v1.0");
        e.setNoteSur20(new BigDecimal("14.0"));
        e.setNiveauCecrl(niveauCecrl);
        e.setNiveauCecrlIa(niveauCecrlIa);
        e.setFeedbackJson(new HashMap<>());
        e.setEvaluatedAt(evaluatedAt);
        return manager.save(e);
    }

    @Test
    void findLatestBySubmissionIdReturnsMostRecent() {
        ProductionSubmission submission = testData.productionSubmission();
        Instant now = Instant.now();

        eval(submission, NiveauCecrl.B1, NiveauCecrl.B1, now.minus(2, ChronoUnit.HOURS));
        AiEvaluation latest =
                eval(submission, NiveauCecrl.B2, NiveauCecrl.B2, now);

        assertThat(manager.findLatestBySubmissionId(submission.getId()))
                .get()
                .extracting(AiEvaluation::getId)
                .isEqualTo(latest.getId());
    }

    @Test
    void findLatestBySubmissionIdAbsentReturnsEmpty() {
        assertThat(manager.findLatestBySubmissionId(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByUserAndEpreuveFiltersUserEpreuveAndNonNullNiveau() {
        User user = testData.user();
        ProductionSubmission eeSubmission = testData.productionSubmission(
                testData.attempt(user), testData.productionTask(EpreuveType.TCF_EE), user);
        ProductionSubmission eoSubmission = testData.productionSubmission(
                testData.attempt(user), testData.productionTask(EpreuveType.TCF_EO), user);
        ProductionSubmission eeNullNiveau = testData.productionSubmission(
                testData.attempt(user), testData.productionTask(EpreuveType.TCF_EE), user);

        Instant now = Instant.now();
        AiEvaluation matching = eval(eeSubmission, NiveauCecrl.B1, NiveauCecrl.B1, now);
        eval(eoSubmission, NiveauCecrl.B1, NiveauCecrl.B1, now);     // mauvaise épreuve
        eval(eeNullNiveau, null, NiveauCecrl.B1, now);              // niveau calculé null

        // Autre user, même épreuve : ne doit pas remonter.
        User other = testData.user();
        ProductionSubmission otherSubmission = testData.productionSubmission(
                testData.attempt(other), testData.productionTask(EpreuveType.TCF_EE), other);
        eval(otherSubmission, NiveauCecrl.B2, NiveauCecrl.B2, now);

        List<AiEvaluation> result = manager.findByUserAndEpreuve(user.getId(), EpreuveType.TCF_EE);
        assertThat(result).extracting(AiEvaluation::getId).containsExactly(matching.getId());
    }

    @Test
    void countWithBothNiveauxCountsOnlyRowsWithBothLevels() {
        long before = manager.countWithBothNiveaux();

        eval(testData.productionSubmission(), NiveauCecrl.B1, NiveauCecrl.B1, Instant.now());
        eval(testData.productionSubmission(), NiveauCecrl.B1, null, Instant.now());   // IA null
        eval(testData.productionSubmission(), null, NiveauCecrl.B1, Instant.now());   // calc null

        assertThat(manager.countWithBothNiveaux()).isEqualTo(before + 1);
    }

    @Test
    void countNiveauDivergentCountsOnlyDifferingLevels() {
        long beforeDivergent = manager.countNiveauDivergent();
        long beforeBoth = manager.countWithBothNiveaux();

        eval(testData.productionSubmission(), NiveauCecrl.B1, NiveauCecrl.B2, Instant.now()); // diverge
        eval(testData.productionSubmission(), NiveauCecrl.B1, NiveauCecrl.B1, Instant.now()); // identique

        assertThat(manager.countNiveauDivergent()).isEqualTo(beforeDivergent + 1);
        assertThat(manager.countWithBothNiveaux()).isEqualTo(beforeBoth + 2);
    }
}
