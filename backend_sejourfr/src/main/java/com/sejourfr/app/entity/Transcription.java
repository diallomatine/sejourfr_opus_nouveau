package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Resultat brut Whisper pour une submission EO. Table separee de
 * {@link ProductionSubmission} pour permettre la re-transcription / versioning.
 * En MVP, une seule transcription par submission.
 */
@Entity
@Table(name = "transcriptions", indexes = {
        @Index(name = "idx_transcription_submission", columnList = "submission_id")
})
public class Transcription {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "submission_id", nullable = false)
    private ProductionSubmission submission;

    @Column(nullable = false, columnDefinition = "text")
    private String texte;

    @Column(name = "langue_detectee", length = 8)
    private String langueDetectee;

    @Column(name = "modele_utilise", nullable = false, length = 40)
    private String modeleUtilise;

    /** Prompt Whisper utilise (mode litteral v2). Conserve pour debug / A-B test. */
    @Column(name = "prompt_utilise", columnDefinition = "text")
    private String promptUtilise;

    @Column(name = "audio_duration_sec")
    private Integer audioDurationSec;

    @Column(name = "cout_estime_centimes")
    private Integer coutEstimeCentimes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ProductionSubmission getSubmission() { return submission; }
    public void setSubmission(ProductionSubmission submission) { this.submission = submission; }

    public String getTexte() { return texte; }
    public void setTexte(String texte) { this.texte = texte; }

    public String getLangueDetectee() { return langueDetectee; }
    public void setLangueDetectee(String langueDetectee) { this.langueDetectee = langueDetectee; }

    public String getModeleUtilise() { return modeleUtilise; }
    public void setModeleUtilise(String modeleUtilise) { this.modeleUtilise = modeleUtilise; }

    public String getPromptUtilise() { return promptUtilise; }
    public void setPromptUtilise(String promptUtilise) { this.promptUtilise = promptUtilise; }

    public Integer getAudioDurationSec() { return audioDurationSec; }
    public void setAudioDurationSec(Integer audioDurationSec) { this.audioDurationSec = audioDurationSec; }

    public Integer getCoutEstimeCentimes() { return coutEstimeCentimes; }
    public void setCoutEstimeCentimes(Integer coutEstimeCentimes) { this.coutEstimeCentimes = coutEstimeCentimes; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
