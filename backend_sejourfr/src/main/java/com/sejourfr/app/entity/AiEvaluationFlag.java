package com.sejourfr.app.entity;

import com.sejourfr.app.enums.MotifSignalement;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Signalement admin d'une évaluation IA (V085, console « Productions IA »).
 *
 * <p>🛑 Il ne touche JAMAIS {@link AiEvaluation} : ni note, ni niveau, ni
 * feedback. Actif tant que {@code removedAt} est nul ; vérifié quand
 * {@code verifiedAt} est posé ; retiré = {@code removedAt} posé (historique
 * conservé). Au plus un signalement actif par évaluation
 * ({@code uq_ai_evaluation_flags_actif}).
 */
@Entity
@Table(name = "ai_evaluation_flags")
@Getter
@Setter
public class AiEvaluationFlag {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "evaluation_id", nullable = false, columnDefinition = "uuid")
    private UUID evaluationId;

    @Column(name = "submission_id", nullable = false, columnDefinition = "uuid")
    private UUID submissionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private MotifSignalement motif;

    @Column(length = 1000)
    private String commentaire;

    @Column(name = "created_by", nullable = false, columnDefinition = "uuid")
    private UUID createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "verified_by", columnDefinition = "uuid")
    private UUID verifiedBy;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @Column(name = "removed_by", columnDefinition = "uuid")
    private UUID removedBy;

    @Column(name = "removed_at")
    private Instant removedAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }
}
