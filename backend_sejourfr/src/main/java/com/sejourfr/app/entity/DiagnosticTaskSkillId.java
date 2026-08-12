package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class DiagnosticTaskSkillId implements Serializable {

    @Column(name = "production_task_id", columnDefinition = "uuid")
    private UUID productionTaskId;

    @Column(name = "skill_id", columnDefinition = "uuid")
    private UUID skillId;

    public DiagnosticTaskSkillId() {}

    public DiagnosticTaskSkillId(UUID productionTaskId, UUID skillId) {
        this.productionTaskId = productionTaskId;
        this.skillId = skillId;
    }

    public UUID getProductionTaskId() { return productionTaskId; }
    public void setProductionTaskId(UUID productionTaskId) { this.productionTaskId = productionTaskId; }
    public UUID getSkillId() { return skillId; }
    public void setSkillId(UUID skillId) { this.skillId = skillId; }

    @Override
    public boolean equals(Object other) {
        if (this == other) return true;
        if (!(other instanceof DiagnosticTaskSkillId that)) return false;
        return Objects.equals(productionTaskId, that.productionTaskId)
                && Objects.equals(skillId, that.skillId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(productionTaskId, skillId);
    }
}
