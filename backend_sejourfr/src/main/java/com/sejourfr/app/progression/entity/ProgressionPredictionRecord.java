package com.sejourfr.app.progression.entity;

import com.sejourfr.app.progression.domain.ProgressionStateType;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une prédiction du shadow mode (V4.2 §47.1) — <b>et son résultat, quand il
 * arrive</b>.
 *
 * <p>🛑 <b>Les valeurs sont figées à {@code predictedAt}</b> (invariant I35).
 * On ne les recalcule jamais : une prédiction recalculée avec l'état d'aujourd'hui
 * aurait toujours raison, et ne mesurerait donc rien. C'est tout l'intérêt du
 * shadow mode — savoir si le moteur avait raison <i>avant</i> de le laisser
 * piloter le Plan de vrais candidats.
 */
@Entity
@Table(name = "progression_prediction_log")
@Getter
@Setter
public class ProgressionPredictionRecord {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "state_key", nullable = false, length = 80)
    private String stateKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "state_type", nullable = false, length = 20)
    private ProgressionStateType stateType;

    @Column(name = "engine_version", nullable = false)
    private int engineVersion;

    @Column(name = "predicted_at", nullable = false)
    private Instant predictedAt;

    @Column(name = "level_cycle_id", length = 96)
    private String levelCycleId;

    @Column(name = "mastery_score")
    private Double masteryScore;

    @Column(name = "confidence", nullable = false)
    private double confidence;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 24)
    private ProgressionStatus status;

    @Column(name = "ready_for_mock", nullable = false)
    private boolean readyForMock;

    @Column(name = "direct_qualification", nullable = false)
    private boolean directQualification;

    @Column(name = "prerequisite_satisfied", nullable = false)
    private boolean prerequisiteSatisfied;

    @Column(name = "prediction_reason", nullable = false, length = 48)
    private String predictionReason;

    /* Rattachés plus tard — le premier examen qualifiant du même stateKey dans
     * les 30 jours (§47.3). Nuls tant qu'aucun n'est survenu : une prédiction
     * sans résultat ne compte ni comme juste ni comme fausse. */

    @Column(name = "outcome_attempt_id", columnDefinition = "uuid")
    private UUID outcomeAttemptId;

    @Column(name = "outcome_result")
    private Double outcomeResult;

    @Column(name = "outcome_at")
    private Instant outcomeAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
