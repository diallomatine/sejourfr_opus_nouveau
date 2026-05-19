package com.sejourfr.app.entity;

import com.sejourfr.app.enums.NiveauCecrl;
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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Note humaine de reference pour calibrer l'IA. Renseignee par un admin ou un
 * prof partenaire. L'ecart_note est calcule a l'insertion par l'application
 * (note humaine - derniere {@link AiEvaluation#noteSur20}).
 */
@Entity
@Table(name = "human_calibration_notes", indexes = {
        @Index(name = "idx_human_cal_submission", columnList = "submission_id"),
        @Index(name = "idx_human_cal_evaluator", columnList = "evaluator_user_id, created_at DESC")
})
public class HumanCalibrationNote {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "submission_id", nullable = false)
    private ProductionSubmission submission;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "evaluator_user_id", nullable = false)
    private User evaluator;

    @Column(name = "note_humaine_sur_20", nullable = false, precision = 4, scale = 1)
    private BigDecimal noteHumaineSur20;

    @Enumerated(EnumType.STRING)
    @Column(name = "niveau_cecrl_humain", nullable = false, length = 20)
    private NiveauCecrl niveauCecrlHumain;

    @Column(columnDefinition = "text")
    private String commentaires;

    /** note_humaine - note_ia (derniere ai_evaluation). NULL si pas encore d'eval IA. */
    @Column(name = "ecart_note", precision = 4, scale = 1)
    private BigDecimal ecartNote;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ProductionSubmission getSubmission() { return submission; }
    public void setSubmission(ProductionSubmission submission) { this.submission = submission; }

    public User getEvaluator() { return evaluator; }
    public void setEvaluator(User evaluator) { this.evaluator = evaluator; }

    public BigDecimal getNoteHumaineSur20() { return noteHumaineSur20; }
    public void setNoteHumaineSur20(BigDecimal noteHumaineSur20) { this.noteHumaineSur20 = noteHumaineSur20; }

    public NiveauCecrl getNiveauCecrlHumain() { return niveauCecrlHumain; }
    public void setNiveauCecrlHumain(NiveauCecrl niveauCecrlHumain) { this.niveauCecrlHumain = niveauCecrlHumain; }

    public String getCommentaires() { return commentaires; }
    public void setCommentaires(String commentaires) { this.commentaires = commentaires; }

    public BigDecimal getEcartNote() { return ecartNote; }
    public void setEcartNote(BigDecimal ecartNote) { this.ecartNote = ecartNote; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
