package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.repository.TranscriptionRepository;
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
 * transcription la plus récente par submission (re-transcription / versioning),
 * et recollage des tours appliqué à la lecture SANS toucher la ligne en base.
 */
class TranscriptionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private TranscriptionManager manager;

    @Autowired
    private TranscriptionRepository repository;

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
    void findLatestTexteBySubmissionIdReturnsMostRecent() {
        ProductionSubmission submission = testData.productionSubmission();
        Instant now = Instant.now();

        transcription(submission, now.minus(1, ChronoUnit.HOURS), "Ancienne transcription");
        transcription(submission, now, "Transcription récente");

        // Transcription d'une autre submission : ne doit pas matcher.
        transcription(testData.productionSubmission(), now, "Autre submission");

        assertThat(manager.findLatestTexteBySubmissionId(submission.getId()))
                .contains("Transcription récente");
    }

    @Test
    void findLatestTexteBySubmissionIdAbsentReturnsEmpty() {
        assertThat(manager.findLatestTexteBySubmissionId(UUID.randomUUID())).isEmpty();
    }

    @Test
    void existsBySubmissionIdSuitLaPresenceDUneTranscription() {
        ProductionSubmission submission = testData.productionSubmission();
        assertThat(manager.existsBySubmissionId(submission.getId())).isFalse();

        transcription(submission, Instant.now(), "Bonjour");

        assertThat(manager.existsBySubmissionId(submission.getId())).isTrue();
    }

    /**
     * Le recollage est une transformation DE LECTURE : la ligne
     * {@code transcriptions.texte} reste le transcript brut, mot pour mot.
     */
    @Test
    void leRecollageNeModifieJamaisLaLigneEnBase() {
        ProductionSubmission submission = testData.productionSubmission();
        String brut = """
            Examinateur : Bonjour, je vous écoute.
            Candidat : Je voudrais louer une voiture
            Candidat : si vous en avez s'il vous plaît.""";
        Transcription persisted = transcription(submission, Instant.now(), brut);

        assertThat(manager.findLatestTexteBySubmissionId(submission.getId()))
                .contains("""
                    Examinateur : Bonjour, je vous écoute.
                    Candidat : Je voudrais louer une voiture si vous en avez s'il vous plaît.""");

        assertThat(repository.findById(persisted.getId()))
                .get()
                .satisfies(t -> assertThat(t.getTexte()).isEqualTo(brut));
    }
}
