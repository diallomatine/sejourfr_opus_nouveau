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
 * La projection matérialisée d'un {@code stateKey} (V4.2 §27.2).
 *
 * <p>Ce n'est <b>pas</b> une vérité : elle est entièrement reconstructible
 * depuis {@code learning_evidence}. Elle existe pour que lire l'état d'un
 * candidat coûte une ligne au lieu de tout son historique — et elle porte
 * {@code engineVersion} pour que deux versions du moteur puissent coexister le
 * temps d'un replay comparé (§29).
 *
 * <p>🛑 <b>{@code masteryScore} et {@code confidence} ne sortent jamais vers un
 * front</b> (§25 bis.2). Console admin et journal de prédictions, rien d'autre.
 *
 * <p>🛑 <b>{@code visibleProgress} est {@code null}, jamais 0, quand aucune
 * preuve directe n'existe</b> (§18.6, invariant I41). Zéro se lit comme une
 * régression ; le candidat n'a simplement jamais été mesuré à ce palier.
 */
@Entity
@Table(name = "progression_state")
@Getter
@Setter
public class ProgressionStateRecord {

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

    /** {@code null} = inconnu, jamais « mauvais ». */
    @Column(name = "mastery_score")
    private Double masteryScore;

    @Column(name = "confidence", nullable = false)
    private double confidence;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 24)
    private ProgressionStatus status = ProgressionStatus.NOT_EVALUATED;

    /* §27.2.1 — double, jamais BigDecimal : ces accumulateurs croissent
     * exponentiellement et un décimal à précision fixe déborderait en silence. */

    @Column(name = "sum_weight_epoch", nullable = false)
    private double sumWeightEpoch;

    @Column(name = "sum_weighted_result_epoch", nullable = false)
    private double sumWeightedResultEpoch;

    @Column(name = "micro_sum_weight_epoch", nullable = false)
    private double microSumWeightEpoch;

    @Column(name = "non_micro_sum_weight_epoch", nullable = false)
    private double nonMicroSumWeightEpoch;

    @Column(name = "qualifying_evidence_count", nullable = false)
    private int qualifyingEvidenceCount;

    @Column(name = "recent_strong_negative_count", nullable = false)
    private int recentStrongNegativeCount;

    @Column(name = "qualification_gate", nullable = false)
    private boolean qualificationGate;

    @Column(name = "transfer_gate", nullable = false)
    private boolean transferGate;

    @Column(name = "direct_qualification", nullable = false)
    private boolean directQualification;

    @Column(name = "visible_progress")
    private Integer visibleProgress;

    @Column(name = "practice_points", nullable = false)
    private double practicePoints;

    @Column(name = "level_cycle_id", nullable = false, length = 96)
    private String levelCycleId;

    @Column(name = "last_evidence_at")
    private Instant lastEvidenceAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
