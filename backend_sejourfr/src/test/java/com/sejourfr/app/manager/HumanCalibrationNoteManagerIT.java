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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link HumanCalibrationNoteManager} : notes par
 * submission ordonnées par date décroissante et listage global.
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
    void findBySubmissionOrderedByCreatedAtDescReturnsNewestFirst() {
        ProductionSubmission submission = testData.productionSubmission();
        User evaluator = testData.admin();
        Instant now = Instant.now();

        HumanCalibrationNote older = note(submission, evaluator, now.minus(2, ChronoUnit.HOURS));
        HumanCalibrationNote newer = note(submission, evaluator, now);

        // Note sur une autre submission : exclue.
        note(testData.productionSubmission(), evaluator, now);

        List<HumanCalibrationNote> result =
                manager.findBySubmissionOrderedByCreatedAtDesc(submission.getId());
        assertThat(result).extracting(HumanCalibrationNote::getId)
                .containsExactly(newer.getId(), older.getId());
    }

    @Test
    void findBySubmissionAbsentReturnsEmpty() {
        assertThat(manager.findBySubmissionOrderedByCreatedAtDesc(UUID.randomUUID()))
                .isEmpty();
    }

    @Test
    void findAllReturnsPersistedNotes() {
        long before = manager.findAll().size();
        HumanCalibrationNote saved =
                note(testData.productionSubmission(), testData.admin(), Instant.now());

        List<HumanCalibrationNote> all = manager.findAll();
        assertThat(all).hasSize((int) before + 1);
        assertThat(all).extracting(HumanCalibrationNote::getId).contains(saved.getId());
    }
}
