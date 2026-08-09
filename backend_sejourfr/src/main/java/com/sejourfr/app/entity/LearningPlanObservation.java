package com.sejourfr.app.entity;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
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
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/** Un signal sourcé du Plan ; le Plan courant est toujours dérivé côté serveur. */
@Entity
@Table(name = "learning_plan_observations", indexes = {
        @Index(name = "idx_learning_plan_user_recent", columnList = "user_id, observed_at DESC"),
        @Index(name = "idx_learning_plan_user_skill_recent", columnList = "user_id, skill_id, observed_at DESC")
})
public class LearningPlanObservation {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_id", nullable = false)
    private Skill skill;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 24)
    private LearningPlanSourceType sourceType;

    @Column(name = "source_id", nullable = false, columnDefinition = "uuid")
    private UUID sourceId;

    @Column(nullable = false)
    private boolean observed;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LearningPlanSkillStatus status;

    @Column(columnDefinition = "text")
    private String evidence;

    @Column(columnDefinition = "text")
    private String explanation;

    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private ObservationConfidence confidence;

    @Column(nullable = false)
    private boolean baseline;

    @Column(name = "observed_at", nullable = false)
    private Instant observedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (observedAt == null) observedAt = now;
        if (createdAt == null) createdAt = now;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public Skill getSkill() { return skill; }
    public void setSkill(Skill skill) { this.skill = skill; }
    public LearningPlanSourceType getSourceType() { return sourceType; }
    public void setSourceType(LearningPlanSourceType sourceType) { this.sourceType = sourceType; }
    public UUID getSourceId() { return sourceId; }
    public void setSourceId(UUID sourceId) { this.sourceId = sourceId; }
    public boolean isObserved() { return observed; }
    public void setObserved(boolean observed) { this.observed = observed; }
    public LearningPlanSkillStatus getStatus() { return status; }
    public void setStatus(LearningPlanSkillStatus status) { this.status = status; }
    public String getEvidence() { return evidence; }
    public void setEvidence(String evidence) { this.evidence = evidence; }
    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }
    public ObservationConfidence getConfidence() { return confidence; }
    public void setConfidence(ObservationConfidence confidence) { this.confidence = confidence; }
    public boolean isBaseline() { return baseline; }
    public void setBaseline(boolean baseline) { this.baseline = baseline; }
    public Instant getObservedAt() { return observedAt; }
    public void setObservedAt(Instant observedAt) { this.observedAt = observedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
