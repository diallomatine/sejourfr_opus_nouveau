package com.sejourfr.app.manager;

import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link HumanCalibrationNoteManager} : dernière note
 * d'une submission, ids annotés chargés en lot, listage global ordonné.
 */
class HumanCalibrationNoteManagerIT extends AbstractIntegrationTest {

    @Autowired
    private HumanCalibrationNoteManager manager;

    @Autowired
    private TestData testData;

    private HumanCalibrationNote note(ProductionSubmission submission, User evaluator, Instant createdAt) {
        HumanCalibrationNote n = new HumanCalibrationNote();
        n.setSubmission(submission);
        n.setEvaluator(evaluator);
        n.setNoteHumaineSur20(new BigDecimal("15.0"));
        n.setNiveauCecrlHumain(NiveauCecrl.B1);
        n.setCommentaires("Calibration de test.");
        n.setCreatedAt(createdAt);
        return manager.save(n);
    }

    @Test
    void findLatestBySubmissionReturnsNewest() {
        ProductionSubmission submission = testData.productionSubmission();
        User evaluator = testData.admin();
        Instant now = Instant.now();

        note(submission, evaluator, now.minus(2, ChronoUnit.HOURS));
        HumanCalibrationNote newer = note(submission, evaluator, now);

        // Note sur une autre submission : exclue.
        note(testData.productionSubmission(), evaluator, now);

        assertThat(manager.findLatestBySubmission(submission.getId()))
                .get()
                .extracting(HumanCalibrationNote::getId)
                .isEqualTo(newer.getId());
    }

    @Test
    void findLatestBySubmissionAbsentReturnsEmpty() {
        assertThat(manager.findLatestBySubmission(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findAnnotatedSubmissionIdsNeGardeQueLesAnnotees() {
        ProductionSubmission annotee = testData.productionSubmission();
        ProductionSubmission vierge = testData.productionSubmission();
        note(annotee, testData.admin(), Instant.now());

        Set<UUID> ids = manager.findAnnotatedSubmissionIds(
                List.of(annotee.getId(), vierge.getId()));

        assertThat(ids).containsExactly(annotee.getId());
    }

    @Test
    void findAnnotatedSubmissionIdsDedupliqueLesReannotations() {
        ProductionSubmission submission = testData.productionSubmission();
        User evaluator = testData.admin();
        note(submission, evaluator, Instant.now().minus(1, ChronoUnit.HOURS));
        note(submission, evaluator, Instant.now());

        assertThat(manager.findAnnotatedSubmissionIds(List.of(submission.getId())))
                .containsExactly(submission.getId());
    }

    @Test
    void findAnnotatedSubmissionIdsSansEntreeNeTapePasLaBase() {
        assertThat(manager.findAnnotatedSubmissionIds(List.of())).isEmpty();
        assertThat(manager.findAnnotatedSubmissionIds(null)).isEmpty();
    }

    @Test
    void findAllOrderedByCreatedAtDescReturnsNewestFirst() {
        int before = manager.findAllOrderedByCreatedAtDesc().size();
        ProductionSubmission submission = testData.productionSubmission();
        User evaluator = testData.admin();
        Instant now = Instant.now();

        HumanCalibrationNote older = note(submission, evaluator, now.minus(2, ChronoUnit.HOURS));
        HumanCalibrationNote newer = note(submission, evaluator, now);

        List<HumanCalibrationNote> all = manager.findAllOrderedByCreatedAtDesc();
        assertThat(all).hasSize(before + 2);
        List<UUID> ids = all.stream().map(HumanCalibrationNote::getId).toList();
        assertThat(ids).contains(newer.getId(), older.getId());
        assertThat(ids.indexOf(newer.getId())).isLessThan(ids.indexOf(older.getId()));
    }
}
