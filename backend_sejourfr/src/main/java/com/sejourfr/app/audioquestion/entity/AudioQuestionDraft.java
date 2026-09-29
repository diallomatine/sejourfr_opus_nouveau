package com.sejourfr.app.audioquestion.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "audio_question_draft", indexes = {
        @Index(name = "idx_audio_draft_status", columnList = "status"),
        @Index(name = "idx_audio_draft_batch", columnList = "batch_id"),
        @Index(name = "idx_audio_draft_created", columnList = "created_at")
})
public class AudioQuestionDraft {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 2)
    private Difficulty difficulty;

    @Column(name = "competence_code", length = 50)
    private String competenceCode;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "theme_id", nullable = false)
    private Theme theme;

    @Column(name = "transcript_text", nullable = false, columnDefinition = "text")
    private String transcriptText;

    @Column(name = "ssml_text", nullable = false, columnDefinition = "text")
    private String ssmlText;

    @Column(nullable = false, columnDefinition = "text")
    private String statement;

    @Column(columnDefinition = "text")
    private String explanation;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    private List<DraftChoice> choices;

    @Column(name = "voice_recommended", length = 50)
    private String voiceRecommended;

    /**
     * Image support d'un draft CO_IMAGE. {@link #inlineSvg} = SVG généré
     * (offline-first), {@link #imageUrl} = image hébergée sur R2 (prioritaire
     * si renseignée). NULL pour un draft CO classique.
     */
    @Column(name = "inline_svg", columnDefinition = "text")
    private String inlineSvg;

    @Column(name = "image_url", columnDefinition = "text")
    private String imageUrl;

    @Column(name = "image_alt_text", columnDefinition = "text")
    private String imageAltText;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AudioDraftStatus status = AudioDraftStatus.TEXT_VALIDATED;

    @Column(name = "audio_url", columnDefinition = "text")
    private String audioUrl;

    @Column(name = "audio_duration_sec")
    private Integer audioDurationSec;

    @Column(name = "audio_voice_used", length = 50)
    private String audioVoiceUsed;

    @Column(name = "audio_generated_at")
    private Instant audioGeneratedAt;

    @Column(name = "batch_id", columnDefinition = "uuid")
    private UUID batchId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "audio_validated_at")
    private Instant audioValidatedAt;

    @Column(name = "audio_validated_by", length = 100)
    private String audioValidatedBy;

    @Column(name = "rejection_reason", columnDefinition = "text")
    private String rejectionReason;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    /**
     * Mapping JSONB <-> record : les choices sont inseres en SQL avec des cles
     * snake_case (`is_correct`, `display_order`), conformement au schema documente
     * dans la migration. Jackson serialise en CamelCase par defaut, d'ou les annotations.
     */
    public record DraftChoice(
        String label,
        @JsonProperty("is_correct") boolean isCorrect,
        @JsonProperty("display_order") int displayOrder
    ) {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Difficulty getDifficulty() { return difficulty; }
    public void setDifficulty(Difficulty difficulty) { this.difficulty = difficulty; }

    public String getCompetenceCode() { return competenceCode; }
    public void setCompetenceCode(String competenceCode) { this.competenceCode = competenceCode; }

    public Theme getTheme() { return theme; }
    public void setTheme(Theme theme) { this.theme = theme; }

    public String getTranscriptText() { return transcriptText; }
    public void setTranscriptText(String transcriptText) { this.transcriptText = transcriptText; }

    public String getSsmlText() { return ssmlText; }
    public void setSsmlText(String ssmlText) { this.ssmlText = ssmlText; }

    public String getStatement() { return statement; }
    public void setStatement(String statement) { this.statement = statement; }

    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }

    public List<DraftChoice> getChoices() { return choices; }
    public void setChoices(List<DraftChoice> choices) { this.choices = choices; }

    public String getVoiceRecommended() { return voiceRecommended; }
    public void setVoiceRecommended(String voiceRecommended) { this.voiceRecommended = voiceRecommended; }

    public String getInlineSvg() { return inlineSvg; }
    public void setInlineSvg(String inlineSvg) { this.inlineSvg = inlineSvg; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getImageAltText() { return imageAltText; }
    public void setImageAltText(String imageAltText) { this.imageAltText = imageAltText; }

    public AudioDraftStatus getStatus() { return status; }
    public void setStatus(AudioDraftStatus status) { this.status = status; }

    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }

    public Integer getAudioDurationSec() { return audioDurationSec; }
    public void setAudioDurationSec(Integer audioDurationSec) { this.audioDurationSec = audioDurationSec; }

    public String getAudioVoiceUsed() { return audioVoiceUsed; }
    public void setAudioVoiceUsed(String audioVoiceUsed) { this.audioVoiceUsed = audioVoiceUsed; }

    public Instant getAudioGeneratedAt() { return audioGeneratedAt; }
    public void setAudioGeneratedAt(Instant audioGeneratedAt) { this.audioGeneratedAt = audioGeneratedAt; }

    public UUID getBatchId() { return batchId; }
    public void setBatchId(UUID batchId) { this.batchId = batchId; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getAudioValidatedAt() { return audioValidatedAt; }
    public void setAudioValidatedAt(Instant audioValidatedAt) { this.audioValidatedAt = audioValidatedAt; }

    public String getAudioValidatedBy() { return audioValidatedBy; }
    public void setAudioValidatedBy(String audioValidatedBy) { this.audioValidatedBy = audioValidatedBy; }

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
}
