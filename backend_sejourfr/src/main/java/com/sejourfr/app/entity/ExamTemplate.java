package com.sejourfr.app.entity;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
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

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Module module;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_level", length = 8)
    private TargetLevel targetLevel;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "duration_seconds", nullable = false)
    private int durationSeconds;

    @Column(name = "total_questions", nullable = false)
    private int totalQuestions;

    @Column(name = "passing_score", nullable = false)
    private int passingScore;

    @OneToMany(mappedBy = "examTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ExamTemplateRule> rules = new ArrayList<>();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Module getModule() { return module; }
    public void setModule(Module module) { this.module = module; }

    public TargetLevel getTargetLevel() { return targetLevel; }
    public void setTargetLevel(TargetLevel targetLevel) { this.targetLevel = targetLevel; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(int durationSeconds) { this.durationSeconds = durationSeconds; }

    public int getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(int totalQuestions) { this.totalQuestions = totalQuestions; }

    public int getPassingScore() { return passingScore; }
    public void setPassingScore(int passingScore) { this.passingScore = passingScore; }

    public List<ExamTemplateRule> getRules() { return rules; }
    public void setRules(List<ExamTemplateRule> rules) { this.rules = rules; }
}
