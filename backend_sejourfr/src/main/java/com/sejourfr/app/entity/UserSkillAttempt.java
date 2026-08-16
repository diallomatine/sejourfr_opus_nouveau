package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSelfEvaluation;
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
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Une production d'un candidat sur un petit sujet : le texte (EE) ou l'audio
 * (EO), plus le resultat de l'analyse ciblee quand il en a demande une.
 *
 * <p><b>Analyse facultative</b> — c'est la particularite du module. Produire est
 * gratuit et illimite ; l'analyse IA est payante. Une tentative sans analyse
 * s'arrete a {@link SkillAttemptStatut#RECORDED} : pas de
 * correcteur, donc ni {@link #criterionStatus}, ni
 * {@link #analysisJson}. L'audio est neanmoins conserve — le candidat doit
 * pouvoir se reecouter, et pouvoir faire analyser plus tard.
 *
 * <p>{@link #analysisRequested} porte le quota freemium : il passe a
 * {@code true} au moment ou l'analyse est ACCEPTEE, pas quand elle reussit.
 * Sinon un echec fournisseur suivi d'un retry offrirait des analyses
 * supplementaires.
 */
@Entity
@Table(name = "user_skill_attempts", indexes = {
        @Index(name = "idx_user_skill_attempts_user_prompt",
                columnList = "user_id, skill_prompt_id, created_at DESC")
})
@Getter
@Setter
public class UserSkillAttempt {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_prompt_id", nullable = false)
    private SkillPrompt skillPrompt;

    /** EE uniquement. Exclusif de {@link #transcript} au niveau applicatif. */
    @Column(name = "written_production", columnDefinition = "text")
    private String writtenProduction;

    /**
     * LEGACY — plus jamais ecrite. Cle R2 des productions orales enregistrees
     * avant que l'audio du candidat cesse d'etre stocke (decision produit, motif
     * consentement). Conservee telle quelle sur les lignes historiques ; aucune
     * nouvelle tentative ne la renseigne, et aucun DTO ne l'expose.
     */
    @Column(name = "audio_object_key", length = 500)
    private String audioObjectKey;

    @Column(name = "audio_duration_sec")
    private Integer audioDurationSec;

    /**
     * Transcription Whisper (EO) — <b>LA production orale conservee</b>, puisque
     * l'audio ne l'est pas. Ecrite SYSTEMATIQUEMENT pendant la requete de
     * soumission, analyse demandee ou non : sans elle il ne resterait rien.
     */
    @Column(columnDefinition = "text")
    private String transcript;

    @Column(name = "words_count")
    private Integer wordsCount;

    /** Declaratif, facultatif, sans aucun effet sur le verdict. */
    @Enumerated(EnumType.STRING)
    @Column(name = "self_evaluation", length = 12)
    private SkillSelfEvaluation selfEvaluation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private SkillAttemptStatut statut = SkillAttemptStatut.RECORDED;

    @Column(name = "analysis_requested", nullable = false)
    private boolean analysisRequested = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "criterion_status", length = 16)
    private SkillCriterionStatus criterionStatus;

    /**
     * Sortie stricte de l'analyse ciblee : {@code status}, {@code verdict},
     * {@code success_point}, {@code improvement_priority},
     * {@code improved_version}. Rien d'autre — le tool-schema ne prevoit ni
     * note sur 20 ni niveau CECRL.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "analysis_json", columnDefinition = "jsonb")
    private Map<String, Object> analysisJson;

    @Column(name = "ai_model", length = 64)
    private String aiModel;

    /** Version du tool-schema de sortie demande au correcteur. */
    @Column(name = "prompt_version", length = 16)
    private String promptVersion;

    /** Version des consignes d'analyse appliquees. Distincte du tool-schema. */
    @Column(name = "rubrics_version", length = 16)
    private String rubricsVersion;

    @Column(name = "tokens_input")
    private Integer tokensInput;

    @Column(name = "tokens_output")
    private Integer tokensOutput;

    @Column(name = "cout_estime_centimes")
    private Integer coutEstimeCentimes;

    /**
     * Relances d'analyse deja consommees sur cette tentative, plafonnees a
     * {@code SkillAttemptService.MAX_RETRIES}. Le retry etant offert (le quota
     * freemium a ete decompte a l'acceptation, et l'echec n'est pas du fait du
     * candidat), il serait sans ce compteur illimite : une panne fournisseur se
     * traduirait par une boucle d'appels payants. Meme convention que
     * {@code ProductionSubmission.retryCount}.
     */
    @Column(name = "retry_count", nullable = false)
    private short retryCount = 0;

    @Column(name = "error_message", columnDefinition = "text")
    private String errorMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
