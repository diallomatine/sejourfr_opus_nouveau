package com.sejourfr.app.audioquestion.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audio_question_generation_logs", indexes = {
        @Index(name = "idx_audio_gen_logs_admin", columnList = "admin_user_id,created_at"),
        @Index(name = "idx_audio_gen_logs_status", columnList = "status,created_at"),
        @Index(name = "idx_audio_gen_logs_question", columnList = "question_id")
})
public class AudioQuestionGenerationLog {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "question_id", columnDefinition = "uuid")
    private UUID questionId;

    @Column(name = "admin_user_id", nullable = false, columnDefinition = "uuid")
    private UUID adminUserId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "requested_params", nullable = false, columnDefinition = "jsonb")
    private String requestedParams;

    @Column(name = "prompt_version", length = 32)
    private String promptVersion;

    @Column(name = "anthropic_model", length = 64)
    private String anthropicModel;

    @Column(name = "anthropic_input_tokens")
    private Integer anthropicInputTokens;

    @Column(name = "anthropic_output_tokens")
    private Integer anthropicOutputTokens;

    @Column(name = "anthropic_cache_read_tokens")
    private Integer anthropicCacheReadTokens;

    @Column(name = "anthropic_cost_eur", precision = 8, scale = 5)
    private BigDecimal anthropicCostEur;

    @Column(name = "azure_voice_names", length = 512)
    private String azureVoiceNames;

    @Column(name = "azure_characters_count")
    private Integer azureCharactersCount;

    @Column(name = "azure_cost_eur", precision = 8, scale = 5)
    private BigDecimal azureCostEur;

    @Column(name = "r2_object_key", length = 256)
    private String r2ObjectKey;

    @Column(name = "duration_ms")
    private Integer durationMs;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private GenerationStatus status;

    @Column(name = "error_message", columnDefinition = "text")
    private String errorMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getQuestionId() { return questionId; }
    public void setQuestionId(UUID questionId) { this.questionId = questionId; }

    public UUID getAdminUserId() { return adminUserId; }
    public void setAdminUserId(UUID adminUserId) { this.adminUserId = adminUserId; }

    public String getRequestedParams() { return requestedParams; }
    public void setRequestedParams(String requestedParams) { this.requestedParams = requestedParams; }

    public String getPromptVersion() { return promptVersion; }
    public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }

    public String getAnthropicModel() { return anthropicModel; }
    public void setAnthropicModel(String anthropicModel) { this.anthropicModel = anthropicModel; }

    public Integer getAnthropicInputTokens() { return anthropicInputTokens; }
    public void setAnthropicInputTokens(Integer anthropicInputTokens) { this.anthropicInputTokens = anthropicInputTokens; }

    public Integer getAnthropicOutputTokens() { return anthropicOutputTokens; }
    public void setAnthropicOutputTokens(Integer anthropicOutputTokens) { this.anthropicOutputTokens = anthropicOutputTokens; }

    public Integer getAnthropicCacheReadTokens() { return anthropicCacheReadTokens; }
    public void setAnthropicCacheReadTokens(Integer anthropicCacheReadTokens) { this.anthropicCacheReadTokens = anthropicCacheReadTokens; }

    public BigDecimal getAnthropicCostEur() { return anthropicCostEur; }
    public void setAnthropicCostEur(BigDecimal anthropicCostEur) { this.anthropicCostEur = anthropicCostEur; }

    public String getAzureVoiceNames() { return azureVoiceNames; }
    public void setAzureVoiceNames(String azureVoiceNames) { this.azureVoiceNames = azureVoiceNames; }

    public Integer getAzureCharactersCount() { return azureCharactersCount; }
    public void setAzureCharactersCount(Integer azureCharactersCount) { this.azureCharactersCount = azureCharactersCount; }

    public BigDecimal getAzureCostEur() { return azureCostEur; }
    public void setAzureCostEur(BigDecimal azureCostEur) { this.azureCostEur = azureCostEur; }

    public String getR2ObjectKey() { return r2ObjectKey; }
    public void setR2ObjectKey(String r2ObjectKey) { this.r2ObjectKey = r2ObjectKey; }

    public Integer getDurationMs() { return durationMs; }
    public void setDurationMs(Integer durationMs) { this.durationMs = durationMs; }

    public GenerationStatus getStatus() { return status; }
    public void setStatus(GenerationStatus status) { this.status = status; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
