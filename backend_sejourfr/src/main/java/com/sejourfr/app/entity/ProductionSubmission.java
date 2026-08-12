package com.sejourfr.app.entity;

import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
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
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une soumission utilisateur (audio EO ou texte EE) rattachee a un attempt et
 * a une production_task. Sa duree de vie est portee par les statuts (cf.
 * {@link SubmissionStatut}).
 */
@Entity
@Table(name = "production_submissions", indexes = {
        @Index(name = "idx_prod_sub_attempt", columnList = "attempt_id"),
        @Index(name = "idx_prod_sub_user_submitted", columnList = "user_id, submitted_at DESC"),
        @Index(name = "idx_prod_sub_statut_pending", columnList = "statut")
})
public class ProductionSubmission {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attempt_id", nullable = false)
    private Attempt attempt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "production_task_id", nullable = false)
    private ProductionTask productionTask;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "submitted_at", nullable = false)
    private Instant submittedAt;

    /** EO uniquement : URL R2 (signee ou cle de stockage). NULL pour EE. */
    @Column(name = "media_url", length = 500)
    private String mediaUrl;

    @Column(name = "media_duration_sec")
    private Integer mediaDurationSec;

    /** EE uniquement : texte rendu par l'utilisateur. NULL pour EO. */
    @Column(name = "texte_soumis", columnDefinition = "text")
    private String texteSoumis;

    @Column(name = "mots_count")
    private Integer motsCount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SubmissionStatut statut = SubmissionStatut.SUBMITTED;

    /**
     * Origine : ASYNC (upload audio/texte classique) ou REALTIME (session EO
     * temps reel, production portee par la Transcription, sans media stocke).
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private ProductionSubmissionSource source = ProductionSubmissionSource.ASYNC;

    /** Purpose persistant : le runner ne déduit jamais sa branche d'un état front. */
    @Column(name = "is_diagnostic", nullable = false)
    private boolean diagnostic;

    /** Nombre de relances manuelles via /retry. Plafonne a 3 (anti-abus). */
    @Column(name = "retry_count", nullable = false)
    private short retryCount = 0;

    @Column(name = "erreur_message", columnDefinition = "text")
    private String erreurMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (submittedAt == null) submittedAt = now;
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Attempt getAttempt() { return attempt; }
    public void setAttempt(Attempt attempt) { this.attempt = attempt; }

    public ProductionTask getProductionTask() { return productionTask; }
    public void setProductionTask(ProductionTask productionTask) { this.productionTask = productionTask; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Instant getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(Instant submittedAt) { this.submittedAt = submittedAt; }

    public String getMediaUrl() { return mediaUrl; }
    public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }

    public Integer getMediaDurationSec() { return mediaDurationSec; }
    public void setMediaDurationSec(Integer mediaDurationSec) { this.mediaDurationSec = mediaDurationSec; }

    public String getTexteSoumis() { return texteSoumis; }
    public void setTexteSoumis(String texteSoumis) { this.texteSoumis = texteSoumis; }

    public Integer getMotsCount() { return motsCount; }
    public void setMotsCount(Integer motsCount) { this.motsCount = motsCount; }

    public SubmissionStatut getStatut() { return statut; }
    public void setStatut(SubmissionStatut statut) { this.statut = statut; }

    public ProductionSubmissionSource getSource() { return source; }
    public void setSource(ProductionSubmissionSource source) { this.source = source; }

    public boolean isDiagnostic() { return diagnostic; }
    public void setDiagnostic(boolean diagnostic) { this.diagnostic = diagnostic; }

    public short getRetryCount() { return retryCount; }
    public void setRetryCount(short retryCount) { this.retryCount = retryCount; }

    public String getErreurMessage() { return erreurMessage; }
    public void setErreurMessage(String erreurMessage) { this.erreurMessage = erreurMessage; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
