package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;

import java.time.Instant;

/** Allowlist versionnee des competences observables par un sujet diagnostic. */
@Entity
@Table(name = "diagnostic_task_skills")
public class DiagnosticTaskSkill {

    @EmbeddedId
    private DiagnosticTaskSkillId id;

    @MapsId("productionTaskId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "production_task_id", nullable = false)
    private ProductionTask productionTask;

    @MapsId("skillId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_id", nullable = false)
    private Skill skill;

    @Column(name = "display_order", nullable = false)
    private short displayOrder;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public DiagnosticTaskSkillId getId() { return id; }
    public void setId(DiagnosticTaskSkillId id) { this.id = id; }
    public ProductionTask getProductionTask() { return productionTask; }
    public void setProductionTask(ProductionTask productionTask) { this.productionTask = productionTask; }
    public Skill getSkill() { return skill; }
    public void setSkill(Skill skill) { this.skill = skill; }
    public short getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(short displayOrder) { this.displayOrder = displayOrder; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
