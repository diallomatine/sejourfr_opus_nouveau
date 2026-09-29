package com.sejourfr.app.entity;

import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "attempt_questions", indexes = {
        @Index(name = "idx_aq_attempt", columnList = "attempt_id")
})
public class AttemptQuestion {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attempt_id", nullable = false)
    private Attempt attempt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;

    @Column(nullable = false)
    private int position;

    @Column(name = "is_correct")
    private Boolean correct;

    @Column(name = "time_spent_sec")
    private Integer timeSpentSec;

    @OneToOne(mappedBy = "attemptQuestion", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    private Answer answer;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Attempt getAttempt() { return attempt; }
    public void setAttempt(Attempt attempt) { this.attempt = attempt; }

    public Question getQuestion() { return question; }
    public void setQuestion(Question question) { this.question = question; }

    public int getPosition() { return position; }
    public void setPosition(int position) { this.position = position; }

    public Boolean getCorrect() { return correct; }
    public void setCorrect(Boolean correct) { this.correct = correct; }

    public Integer getTimeSpentSec() { return timeSpentSec; }
    public void setTimeSpentSec(Integer timeSpentSec) { this.timeSpentSec = timeSpentSec; }

    public Answer getAnswer() { return answer; }
    public void setAnswer(Answer answer) { this.answer = answer; }
}
