package com.sejourfr.app.entity;

import com.sejourfr.app.enums.NiveauCecrl;
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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Evaluation IA d'une {@link ProductionSubmission} (Claude via tool_use).
 * Une submission peut avoir N evaluations : la plus recente fait foi (cf. index
 * {@code idx_ai_eval_submission_latest}).
 */
@Entity
@Table(name = "ai_evaluations", indexes = {
        @Index(name = "idx_ai_eval_submission_latest", columnList = "submission_id, evaluated_at DESC")
})
public class AiEvaluation {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "submission_id", nullable = false)
    private ProductionSubmission submission;

    @Column(name = "modele_utilise", nullable = false, length = 40)
    private String modeleUtilise;

    /** Version du prompt LLM utilise (ex: "v1.0"). Toute modification = nouvelle version. */
    @Column(name = "prompt_version", nullable = false, length = 20)
    private String promptVersion;

    @Column(name = "note_sur_20", precision = 4, scale = 1)
    private BigDecimal noteSur20;

    /** Niveau CECRL CALCULÉ serveur (lexique + morphosyntaxe). Valeur affichée au mobile. */
    @Enumerated(EnumType.STRING)
    @Column(name = "niveau_cecrl", length = 20)
    private NiveauCecrl niveauCecrl;

    /** Niveau CECRL brut renvoyé par le LLM. Interne (calibration), jamais exposé au mobile. */
    @Enumerated(EnumType.STRING)
    @Column(name = "niveau_cecrl_ia", length = 20)
    private NiveauCecrl niveauCecrlIa;

    /** Structure : note_globale + scores_criteres[] + points_forts[] + points_a_ameliorer[] + suggestions[] + exemples_corriges[]. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "feedback_json", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> feedbackJson = new HashMap<>();

    @Column(name = "tokens_input")
    private Integer tokensInput;

    @Column(name = "tokens_output")
    private Integer tokensOutput;

    @Column(name = "cout_estime_centimes")
    private Integer coutEstimeCentimes;

    @Column(name = "nb_retries", nullable = false)
    private short nbRetries = 0;

    @Column(name = "evaluated_at", nullable = false, updatable = false)
    private Instant evaluatedAt;

    @PrePersist
    void prePersist() {
        if (evaluatedAt == null) evaluatedAt = Instant.now();
        if (feedbackJson == null) feedbackJson = new HashMap<>();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ProductionSubmission getSubmission() { return submission; }
    public void setSubmission(ProductionSubmission submission) { this.submission = submission; }

    public String getModeleUtilise() { return modeleUtilise; }
    public void setModeleUtilise(String modeleUtilise) { this.modeleUtilise = modeleUtilise; }

    public String getPromptVersion() { return promptVersion; }
    public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }

    public BigDecimal getNoteSur20() { return noteSur20; }
    public void setNoteSur20(BigDecimal noteSur20) { this.noteSur20 = noteSur20; }

    public NiveauCecrl getNiveauCecrl() { return niveauCecrl; }
    public void setNiveauCecrl(NiveauCecrl niveauCecrl) { this.niveauCecrl = niveauCecrl; }

    public NiveauCecrl getNiveauCecrlIa() { return niveauCecrlIa; }
    public void setNiveauCecrlIa(NiveauCecrl niveauCecrlIa) { this.niveauCecrlIa = niveauCecrlIa; }

    public Map<String, Object> getFeedbackJson() { return feedbackJson; }
    public void setFeedbackJson(Map<String, Object> feedbackJson) { this.feedbackJson = feedbackJson; }

    public Integer getTokensInput() { return tokensInput; }
    public void setTokensInput(Integer tokensInput) { this.tokensInput = tokensInput; }

    public Integer getTokensOutput() { return tokensOutput; }
    public void setTokensOutput(Integer tokensOutput) { this.tokensOutput = tokensOutput; }

    public Integer getCoutEstimeCentimes() { return coutEstimeCentimes; }
    public void setCoutEstimeCentimes(Integer coutEstimeCentimes) { this.coutEstimeCentimes = coutEstimeCentimes; }

    public short getNbRetries() { return nbRetries; }
    public void setNbRetries(short nbRetries) { this.nbRetries = nbRetries; }

    public Instant getEvaluatedAt() { return evaluatedAt; }
    public void setEvaluatedAt(Instant evaluatedAt) { this.evaluatedAt = evaluatedAt; }
}
