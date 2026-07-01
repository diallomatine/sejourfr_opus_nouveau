package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle pour {@link TranscriptionManager} : sélection de la
 * transcription la plus récente par submission (re-transcription / versioning).
 */
class TranscriptionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private TranscriptionManager manager;

    @Autowired
    private TestData testData;

    private Transcription transcription(ProductionSubmission submission, Instant createdAt, String texte) {
        Transcription t = new Transcription();
        t.setSubmission(submission);
        t.setTexte(texte);
        t.setModeleUtilise("whisper-test");
        t.setLangueDetectee("fr");
        t.setCreatedAt(createdAt);
        return manager.save(t);
    }

    @Test
    void findLatestBySubmissionIdReturnsMostRecent() {
        ProductionSubmission submission = testData.productionSubmission();
        Instant now = Instant.now();

        transcription(submission, now.minus(1, ChronoUnit.HOURS), "Ancienne transcription");
        Transcription latest = transcription(submission, now, "Transcription récente");

        // Transcription d'une autre submission : ne doit pas matcher.
        transcription(testData.productionSubmission(), now, "Autre submission");

        assertThat(manager.findLatestBySubmissionId(submission.getId()))
                .get()
                .satisfies(t -> {
                    assertThat(t.getId()).isEqualTo(latest.getId());
                    assertThat(t.getTexte()).isEqualTo("Transcription récente");
                });
    }

    @Test
    void findLatestBySubmissionIdAbsentReturnsEmpty() {
        assertThat(manager.findLatestBySubmissionId(UUID.randomUUID())).isEmpty();
    }
}
