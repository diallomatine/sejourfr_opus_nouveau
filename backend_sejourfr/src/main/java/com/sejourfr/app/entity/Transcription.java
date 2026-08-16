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

    /**
     * Cout de la transcription en <b>micro-dollars</b> (millioniemes de dollar).
     * Remplace {@code cout_estime_centimes}, laissee LEGACY par V035 : elle
     * arrondissait au centime SUPERIEUR une facture a la minute d'audio, donc
     * surestimait de ~5 % l'audio median du depot. Volontairement non mappee —
     * ses valeurs restent en base, plus rien ne les ecrit.
     */
    @Column(name = "cout_micro_usd")
    private Integer coutMicroUsd;

    /**
     * QUALITE RENVOYEE PAR WHISPER (verbose_json), payee depuis toujours et lue
     * depuis le 2026-08-09 seulement. {@code null} en temps reel : Gemini
     * natif-audio n'expose aucun indicateur de confiance.
     */
    @Column(name = "avg_logprob")
    private Double avgLogprob;

    @Column(name = "no_speech_prob")
    private Double noSpeechProb;

    @Column(name = "compression_ratio")
    private Double compressionRatio;

    @Column(name = "segments_count")
    private Integer segmentsCount;

    /**
     * QUALITE MESUREE PAR NOUS, sur le texte final — donc disponible pour les
     * DEUX sources, temps reel compris. Cf. {@code TranscriptionQualityAudit}.
     * {@code null} quand la production est trop courte pour conclure.
     */
    @Column(name = "taux_formes_suspectes")
    private Double tauxFormesSuspectes;

    @Column(name = "taux_collages")
    private Double tauxCollages;

    @Column(name = "qualite_degradee")
    private Boolean qualiteDegradee;

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

    public Integer getCoutMicroUsd() { return coutMicroUsd; }
    public void setCoutMicroUsd(Integer coutMicroUsd) { this.coutMicroUsd = coutMicroUsd; }

    public Double getAvgLogprob() { return avgLogprob; }
    public void setAvgLogprob(Double avgLogprob) { this.avgLogprob = avgLogprob; }

    public Double getNoSpeechProb() { return noSpeechProb; }
    public void setNoSpeechProb(Double noSpeechProb) { this.noSpeechProb = noSpeechProb; }

    public Double getCompressionRatio() { return compressionRatio; }
    public void setCompressionRatio(Double compressionRatio) { this.compressionRatio = compressionRatio; }

    public Integer getSegmentsCount() { return segmentsCount; }
    public void setSegmentsCount(Integer segmentsCount) { this.segmentsCount = segmentsCount; }

    public Double getTauxFormesSuspectes() { return tauxFormesSuspectes; }
    public void setTauxFormesSuspectes(Double tauxFormesSuspectes) { this.tauxFormesSuspectes = tauxFormesSuspectes; }

    public Double getTauxCollages() { return tauxCollages; }
    public void setTauxCollages(Double tauxCollages) { this.tauxCollages = tauxCollages; }

    public Boolean getQualiteDegradee() { return qualiteDegradee; }
    public void setQualiteDegradee(Boolean qualiteDegradee) { this.qualiteDegradee = qualiteDegradee; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
