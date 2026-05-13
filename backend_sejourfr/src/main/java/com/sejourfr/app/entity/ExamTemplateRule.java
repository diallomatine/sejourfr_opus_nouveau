package com.sejourfr.app.entity;

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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "theme_id", nullable = false)
    private Theme theme;

    @Enumerated(EnumType.STRING)
    @Column(name = "question_type", length = 24)
    private QuestionType questionType;

    @Column(name = "question_count", nullable = false)
    private int questionCount;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ExamTemplate getExamTemplate() { return examTemplate; }
    public void setExamTemplate(ExamTemplate examTemplate) { this.examTemplate = examTemplate; }

    public Theme getTheme() { return theme; }
    public void setTheme(Theme theme) { this.theme = theme; }

    public QuestionType getQuestionType() { return questionType; }
    public void setQuestionType(QuestionType questionType) { this.questionType = questionType; }

    public int getQuestionCount() { return questionCount; }
    public void setQuestionCount(int questionCount) { this.questionCount = questionCount; }
}
