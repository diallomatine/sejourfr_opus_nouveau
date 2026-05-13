package com.sejourfr.app.entity;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "answers", indexes = {
        @Index(name = "idx_answer_aq", columnList = "attempt_question_id", unique = true),
        @Index(name = "idx_answer_user", columnList = "user_id")
})
public class Answer {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attempt_question_id", nullable = false, unique = true)
    private AttemptQuestion attemptQuestion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "selected_choice_ids", columnDefinition = "jsonb")
    private List<UUID> selectedChoiceIds = new ArrayList<>();

    @Column(name = "is_correct")
    private Boolean correct;

    @Column(name = "answered_at", nullable = false)
    private Instant answeredAt;

    @PrePersist
    void prePersist() {
        if (answeredAt == null) answeredAt = Instant.now();
        // user_id était NOT NULL en base : on le dérive si possible.
        if (user == null && attemptQuestion != null && attemptQuestion.getAttempt() != null) {
            user = attemptQuestion.getAttempt().getUser();
        }
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public AttemptQuestion getAttemptQuestion() { return attemptQuestion; }
    public void setAttemptQuestion(AttemptQuestion attemptQuestion) { this.attemptQuestion = attemptQuestion; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public List<UUID> getSelectedChoiceIds() { return selectedChoiceIds; }
    public void setSelectedChoiceIds(List<UUID> selectedChoiceIds) {
        this.selectedChoiceIds = selectedChoiceIds != null ? selectedChoiceIds : new ArrayList<>();
    }

    public Boolean getCorrect() { return correct; }
    public void setCorrect(Boolean correct) { this.correct = correct; }
    public void setCorrect(boolean correct) { this.correct = correct; }

    public Instant getAnsweredAt() { return answeredAt; }
    public void setAnsweredAt(Instant answeredAt) { this.answeredAt = answeredAt; }
}
