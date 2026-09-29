package com.sejourfr.app.entity;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "exam_template_rules")
public class ExamTemplateRule {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exam_template_id", nullable = false)
    private ExamTemplate examTemplate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "theme_id")
    private Theme theme;

    @Enumerated(EnumType.STRING)
    @Column(name = "question_type", length = 24)
    private QuestionType questionType;

    @Enumerated(EnumType.STRING)
    @Column(length = 8)
    private Difficulty difficulty;

    @Column(name = "question_count", nullable = false)
    private int questionCount;

    @Column(nullable = false)
    private int position;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ExamTemplate getExamTemplate() { return examTemplate; }
    public void setExamTemplate(ExamTemplate examTemplate) { this.examTemplate = examTemplate; }

    public Theme getTheme() { return theme; }
    public void setTheme(Theme theme) { this.theme = theme; }

    public QuestionType getQuestionType() { return questionType; }
    public void setQuestionType(QuestionType questionType) { this.questionType = questionType; }

    public Difficulty getDifficulty() { return difficulty; }
    public void setDifficulty(Difficulty difficulty) { this.difficulty = difficulty; }

    public int getQuestionCount() { return questionCount; }
    public void setQuestionCount(int questionCount) { this.questionCount = questionCount; }

    public int getPosition() { return position; }
    public void setPosition(int position) { this.position = position; }
}
