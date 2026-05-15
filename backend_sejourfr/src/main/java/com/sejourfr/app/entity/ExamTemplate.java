package com.sejourfr.app.entity;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "exam_templates")
public class ExamTemplate {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false, unique = true, length = 64)
    private String slug;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Module module;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_level", length = 8)
    private TargetLevel targetLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_procedure", length = 8)
    private TargetProcedure targetProcedure;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(length = 160)
    private String subtitle;

    @Column(columnDefinition = "text")
    private String description;

    @Column(name = "duration_seconds", nullable = false)
    private int durationSeconds;

    @Column(name = "total_questions", nullable = false)
    private int totalQuestions;

    @Column(name = "passing_score", nullable = false)
    private int passingScore;

    @Column(name = "is_free", nullable = false)
    private boolean free;

    @Column(name = "is_published", nullable = false)
    private boolean published;

    @Column(nullable = false)
    private int position;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @OneToMany(mappedBy = "examTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("position ASC")
    private List<ExamTemplateRule> rules = new ArrayList<>();

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }

    public Module getModule() { return module; }
    public void setModule(Module module) { this.module = module; }

    public TargetLevel getTargetLevel() { return targetLevel; }
    public void setTargetLevel(TargetLevel targetLevel) { this.targetLevel = targetLevel; }

    public TargetProcedure getTargetProcedure() { return targetProcedure; }
    public void setTargetProcedure(TargetProcedure targetProcedure) { this.targetProcedure = targetProcedure; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getSubtitle() { return subtitle; }
    public void setSubtitle(String subtitle) { this.subtitle = subtitle; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public int getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(int durationSeconds) { this.durationSeconds = durationSeconds; }

    public int getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(int totalQuestions) { this.totalQuestions = totalQuestions; }

    public int getPassingScore() { return passingScore; }
    public void setPassingScore(int passingScore) { this.passingScore = passingScore; }

    public boolean isFree() { return free; }
    public void setFree(boolean free) { this.free = free; }

    public boolean isPublished() { return published; }
    public void setPublished(boolean published) { this.published = published; }

    public int getPosition() { return position; }
    public void setPosition(int position) { this.position = position; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public List<ExamTemplateRule> getRules() { return rules; }
    public void setRules(List<ExamTemplateRule> rules) { this.rules = rules; }
}
