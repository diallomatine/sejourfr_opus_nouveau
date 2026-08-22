package com.sejourfr.app.entity;

import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.ProductionEvaluabilite;
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

    /**
     * Ce qui a pu etre observe de cette production. {@code NON_EVALUABLE} =
     * production rendue mais sans matiere (vide/quasi vide, langue non
     * francaise, recopiage de la consigne) : aucun appel au correcteur n'a ete
     * emis et les trois verdicts ci-dessous valent {@code null}. Contrainte
     * {@code chk_diagnostic_analysis_verdicts_si_evaluable} : les deux etats ne
     * peuvent pas se melanger.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "evaluabilite", nullable = false, length = 16)
    private ProductionEvaluabilite evaluabilite = ProductionEvaluabilite.EVALUABLE;

    /**
     * {@code null} quand rien n'etait observable — <b>null = inconnu, jamais
     * mauvais</b>. Ecrire {@code A1_NON_ATTEINT} ici enregistrerait une absence
     * de preuve comme la preuve du niveau le plus faible, et le repli du profil
     * TCF tirerait tout le candidat au fond (cf. V040).
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "level_estimate", length = 20)
    private NiveauCecrl levelEstimate;

    @Enumerated(EnumType.STRING)
    @Column(name = "task_completion", length = 24)
    private DiagnosticTaskCompletion taskCompletion;

    @Enumerated(EnumType.STRING)
    @Column(name = "communication_status", length = 24)
    private DiagnosticCommunicationStatus communicationStatus;

    @Column(name = "model_used", nullable = false, length = 80)
    private String modelUsed;

    @Column(name = "schema_version", nullable = false, length = 20)
    private String schemaVersion;

    @Column(name = "tokens_input")
    private Integer tokensInput;

    @Column(name = "tokens_output")
    private Integer tokensOutput;

    /**
     * Part de {@code tokensInput} servie par le CACHE DE PREFIXE du fournisseur,
     * telle qu'il la rapporte. {@code null} = non rapporte, donc facturee au
     * plein tarif. Le cache miss se deduit, il n'a pas de colonne.
     */
    @Column(name = "tokens_input_cache_hit")
    private Integer tokensInputCacheHit;

    /**
     * Cout estime de l'appel en MILLIONIEMES de dollar. L'ancienne colonne en
     * centimes arrondissait au cent SUPERIEUR : sur une analyse a 0,0013 $ elle
     * multipliait la facture par ~8. Elle reste en base, LEGACY, plus jamais
     * ecrite — l'historique n'est pas reecrit.
     */
    @Column(name = "cost_micro_usd")
    private Integer costMicroUsd;

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
    public ProductionEvaluabilite getEvaluabilite() { return evaluabilite; }
    public void setEvaluabilite(ProductionEvaluabilite evaluabilite) { this.evaluabilite = evaluabilite; }
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
    public Integer getTokensInputCacheHit() { return tokensInputCacheHit; }
    public void setTokensInputCacheHit(Integer v) { this.tokensInputCacheHit = v; }

    public Integer getCostMicroUsd() { return costMicroUsd; }
    public void setCostMicroUsd(Integer costMicroUsd) { this.costMicroUsd = costMicroUsd; }
    public Instant getAnalyzedAt() { return analyzedAt; }
    public void setAnalyzedAt(Instant analyzedAt) { this.analyzedAt = analyzedAt; }
}
