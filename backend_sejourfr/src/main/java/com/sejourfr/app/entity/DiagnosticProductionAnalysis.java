package com.sejourfr.app.entity;

import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.DiagnosticTaskCompletion;
import com.sejourfr.app.enums.NiveauCecrl;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Analyse structurée dédiée au diagnostic, sans note sur 20. */
@Entity
@Table(name = "diagnostic_production_analyses")
public class DiagnosticProductionAnalysis {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "submission_id", nullable = false)
    private ProductionSubmission submission;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "analysis_json", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> analysisJson = new LinkedHashMap<>();

    @Enumerated(EnumType.STRING)
    @Column(name = "level_estimate", nullable = false, length = 20)
    private NiveauCecrl levelEstimate;

    @Enumerated(EnumType.STRING)
    @Column(name = "task_completion", nullable = false, length = 24)
    private DiagnosticTaskCompletion taskCompletion;

    @Enumerated(EnumType.STRING)
    @Column(name = "communication_status", nullable = false, length = 24)
    private DiagnosticCommunicationStatus communicationStatus;

    @Column(name = "model_used", nullable = false, length = 80)
    private String modelUsed;

    @Column(name = "schema_version", nullable = false, length = 20)
    private String schemaVersion;

    @Column(name = "tokens_input")
    private Integer tokensInput;

    @Column(name = "tokens_output")
    private Integer tokensOutput;

    @Column(name = "cost_estimate_cents")
    private Integer costEstimateCents;

    @Column(name = "analyzed_at", nullable = false, updatable = false)
    private Instant analyzedAt;

    @PrePersist
    void prePersist() { if (analyzedAt == null) analyzedAt = Instant.now(); }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public ProductionSubmission getSubmission() { return submission; }
    public void setSubmission(ProductionSubmission submission) { this.submission = submission; }
    public Map<String, Object> getAnalysisJson() { return analysisJson; }
    public void setAnalysisJson(Map<String, Object> analysisJson) { this.analysisJson = new LinkedHashMap<>(analysisJson); }
    public NiveauCecrl getLevelEstimate() { return levelEstimate; }
    public void setLevelEstimate(NiveauCecrl levelEstimate) { this.levelEstimate = levelEstimate; }
    public DiagnosticTaskCompletion getTaskCompletion() { return taskCompletion; }
    public void setTaskCompletion(DiagnosticTaskCompletion taskCompletion) { this.taskCompletion = taskCompletion; }
    public DiagnosticCommunicationStatus getCommunicationStatus() { return communicationStatus; }
    public void setCommunicationStatus(DiagnosticCommunicationStatus communicationStatus) { this.communicationStatus = communicationStatus; }
    public String getModelUsed() { return modelUsed; }
    public void setModelUsed(String modelUsed) { this.modelUsed = modelUsed; }
    public String getSchemaVersion() { return schemaVersion; }
    public void setSchemaVersion(String schemaVersion) { this.schemaVersion = schemaVersion; }
    public Integer getTokensInput() { return tokensInput; }
    public void setTokensInput(Integer tokensInput) { this.tokensInput = tokensInput; }
    public Integer getTokensOutput() { return tokensOutput; }
    public void setTokensOutput(Integer tokensOutput) { this.tokensOutput = tokensOutput; }
    public Integer getCostEstimateCents() { return costEstimateCents; }
    public void setCostEstimateCents(Integer costEstimateCents) { this.costEstimateCents = costEstimateCents; }
    public Instant getAnalyzedAt() { return analyzedAt; }
    public void setAnalyzedAt(Instant analyzedAt) { this.analyzedAt = analyzedAt; }
}
