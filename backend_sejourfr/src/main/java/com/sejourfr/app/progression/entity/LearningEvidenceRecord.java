package com.sejourfr.app.progression.entity;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
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
 * Une ligne du registre immuable {@code learning_evidence} (V4.2 §5).
 *
 * <p>🛑 <b>Immuable veut dire immuable.</b> Rien ne met à jour une ligne
 * existante : une évaluation IA recalculée laisse l'ancienne en place, pose une
 * invalidation et crée une nouvelle preuve (§43). C'est ce qui rend le replay
 * possible, et le replay est la seule façon honnête de changer un seuil.
 *
 * <p>L'entité porte des identifiants nus ({@code userId}, {@code attemptId})
 * plutôt que des associations JPA : le registre doit rester lisible et
 * rejouable même quand la tentative d'origine a été purgée, et l'ingestion est
 * un chemin chaud qu'on ne veut pas voir charger un graphe.
 */
@Entity
@Table(name = "learning_evidence")
@Getter
@Setter
public class LearningEvidenceRecord {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "attempt_id", nullable = false, columnDefinition = "uuid")
    private UUID attemptId;

    /** L'heure <b>pédagogique</b> de fin d'activité — jamais l'heure de sync. */
    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    @Column(name = "ingested_at", nullable = false)
    private Instant ingestedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "entry_point", nullable = false, length = 24)
    private EvidenceEntryPoint entryPoint;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 32)
    private EvidenceSourceType sourceType;

    @Enumerated(EnumType.STRING)
    @Column(name = "section", nullable = false, length = 2)
    private SkillSection section;

    @Enumerated(EnumType.STRING)
    @Column(name = "level", length = 2)
    private TargetLevel level;

    @Column(name = "skill_id", length = 64)
    private String skillId;

    @Column(name = "result", nullable = false)
    private double result;

    @Column(name = "scoring_confidence", nullable = false)
    private double scoringConfidence;

    @Enumerated(EnumType.STRING)
    @Column(name = "assistance_level", nullable = false, length = 40)
    private AssistanceLevel assistanceLevel;

    @Column(name = "content_id", nullable = false, length = 128)
    private String contentId;

    @Column(name = "blueprint_id", length = 64)
    private String blueprintId;

    @Enumerated(EnumType.STRING)
    @Column(name = "calibration_status", nullable = false, length = 16)
    private CalibrationStatus calibrationStatus;

    /** 🛑 Toujours calculé serveur, jamais reçu du client (invariant I38). */
    @Enumerated(EnumType.STRING)
    @Column(name = "independence_class", nullable = false, length = 32)
    private IndependenceClass independenceClass;

    @Column(name = "engine_version_at_creation", nullable = false)
    private int engineVersionAtCreation;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", nullable = false)
    private Map<String, Object> metadata = Map.of();

    /**
     * La clé d'idempotence (§42). L'unicité est portée <b>par la base</b>
     * ({@code learning_evidence_natural_key_unique}) : un contrôle applicatif
     * perd toujours la course contre deux requêtes concurrentes.
     */
    @Column(name = "natural_key", nullable = false, length = 320)
    private String naturalKey;

    @PrePersist
    void prePersist() {
        if (ingestedAt == null) {
            ingestedAt = Instant.now();
        }
    }
}
