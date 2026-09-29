package com.sejourfr.app.entity;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
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

    /** Version du tool-schema de sortie demande au LLM (ex: "v2"). */
    @Column(name = "prompt_version", nullable = false, length = 20)
    private String promptVersion;

    /**
     * Version de la GRILLE de notation appliquee (criteres, poids, consignes —
     * {@code prompts/production-rubrics-<v>.json}, ex: "v4.2"). Distincte de
     * {@link #promptVersion} qui ne decrit que la forme de la reponse : deux
     * notes produites avec le meme tool-schema mais des grilles differentes ne
     * sont pas comparables. Indispensable pour relire une note a posteriori et
     * pour un retour arriere sur {@code EVAL_RUBRICS_VERSION}. NULL sur les
     * evaluations anterieures a la colonne.
     */
    @Column(name = "rubrics_version", length = 20)
    private String rubricsVersion;

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

    /**
     * La production a-t-elle pu etre OBSERVEE ? {@code NON_EVALUABLE} = rendue,
     * mais sans matiere (vide, quasi vide, langue non francaise, recopiage de la
     * consigne) : aucun appel au correcteur n'a eu lieu, et
     * {@link #noteSur20} / {@link #niveauCecrl} / {@link #niveauCecrlIa} sont
     * {@code null} — <b>null = inconnu, jamais mauvais</b>. La contrainte
     * {@code chk_ai_eval_aucun_verdict_si_non_evaluable} le rend opposable en
     * base.
     *
     * <p>⚠️ A ne pas confondre avec l'ABSENCE de ligne, qui signifie « pas
     * encore evaluee », ni avec l'absence de lignes sur une epreuve d'examen
     * ouverte puis abandonnee, qui reste comptee {@code A1_NON_ATTEINT} par
     * {@code ProductionBilanService.bilanEpreuveTerminee}.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "evaluabilite", nullable = false, length = 16)
    private ProductionEvaluabilite evaluabilite = ProductionEvaluabilite.EVALUABLE;

    /** Structure : note_globale + scores_criteres[] + points_forts[] + points_a_ameliorer[] + suggestions[] + exemples_corriges[]. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "feedback_json", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> feedbackJson = new HashMap<>();

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
    @Column(name = "cout_micro_usd")
    private Integer coutMicroUsd;

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

    public String getRubricsVersion() { return rubricsVersion; }
    public void setRubricsVersion(String rubricsVersion) { this.rubricsVersion = rubricsVersion; }

    public BigDecimal getNoteSur20() { return noteSur20; }
    public void setNoteSur20(BigDecimal noteSur20) { this.noteSur20 = noteSur20; }

    public NiveauCecrl getNiveauCecrl() { return niveauCecrl; }
    public void setNiveauCecrl(NiveauCecrl niveauCecrl) { this.niveauCecrl = niveauCecrl; }

    public NiveauCecrl getNiveauCecrlIa() { return niveauCecrlIa; }
    public void setNiveauCecrlIa(NiveauCecrl niveauCecrlIa) { this.niveauCecrlIa = niveauCecrlIa; }

    public ProductionEvaluabilite getEvaluabilite() { return evaluabilite; }
    public void setEvaluabilite(ProductionEvaluabilite evaluabilite) { this.evaluabilite = evaluabilite; }

    public Map<String, Object> getFeedbackJson() { return feedbackJson; }
    public void setFeedbackJson(Map<String, Object> feedbackJson) { this.feedbackJson = feedbackJson; }

    public Integer getTokensInput() { return tokensInput; }
    public void setTokensInput(Integer tokensInput) { this.tokensInput = tokensInput; }

    public Integer getTokensOutput() { return tokensOutput; }
    public void setTokensOutput(Integer tokensOutput) { this.tokensOutput = tokensOutput; }

    public Integer getTokensInputCacheHit() { return tokensInputCacheHit; }
    public void setTokensInputCacheHit(Integer v) { this.tokensInputCacheHit = v; }

    public Integer getCoutMicroUsd() { return coutMicroUsd; }
    public void setCoutMicroUsd(Integer coutMicroUsd) { this.coutMicroUsd = coutMicroUsd; }

    public short getNbRetries() { return nbRetries; }
    public void setNbRetries(short nbRetries) { this.nbRetries = nbRetries; }

    public Instant getEvaluatedAt() { return evaluatedAt; }
    public void setEvaluatedAt(Instant evaluatedAt) { this.evaluatedAt = evaluatedAt; }
}
