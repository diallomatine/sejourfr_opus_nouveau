package com.sejourfr.app.progression.entity;

import com.sejourfr.app.progression.domain.EvidenceSourceFamily;
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
 * La masse de preuves d'une clé, <b>ventilée par famille de sources</b>
 * (V4.2 §27.3).
 *
 * <p>Elle existe pour le seul plafond du moteur : celui des micro-sujets
 * (§11.1). Cinquante micro-sujets parfaits ne doivent jamais fournir à eux seuls
 * la confiance nécessaire à {@code SOLID}, et c'est cette ventilation qui rend
 * la règle vérifiable après coup — sans elle, on lit une masse totale sans
 * savoir ce qui l'a remplie.
 *
 * <p>🛑 <b>{@code double precision}, jamais {@code NUMERIC}</b> : ce sont les
 * mêmes accumulateurs epoch que {@link ProgressionStateRecord}, avec la même
 * croissance exponentielle et le même risque de débordement silencieux
 * (§27.2.1, invariant I40).
 *
 * <p>C'est une <b>projection</b>, comme {@code progression_state} : entièrement
 * reconstructible depuis {@code learning_evidence}, et réécrite à chaque
 * recalcul de la clé.
 */
@Entity
@Table(name = "progression_state_family_aggregate")
@Getter
@Setter
public class ProgressionFamilyAggregateRecord {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "state_key", nullable = false, length = 80)
    private String stateKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_family", nullable = false, length = 16)
    private EvidenceSourceFamily sourceFamily;

    @Column(name = "engine_version", nullable = false)
    private int engineVersion;

    @Column(name = "sum_weight_epoch", nullable = false)
    private double sumWeightEpoch;

    @Column(name = "sum_weighted_result_epoch", nullable = false)
    private double sumWeightedResultEpoch;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
