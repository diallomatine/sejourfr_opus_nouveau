package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Reponse modele illustrant une {@link ProductionTask} (ex. "un boulanger qui
 * se presente"). Rattachee a la TACHE, pas a une situation : le candidat la
 * consulte pour s'inspirer, independamment du sujet choisi dans le carrousel.
 * {@code audioUrl} est renseigne pour l'EO (pipeline audio Azure+R2), NULL pour l'EE.
 */
@Entity
@Table(name = "production_examples", indexes = {
        @Index(name = "idx_prod_examples_task", columnList = "task_id, display_order")
})
public class ProductionExample {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "task_id", nullable = false, columnDefinition = "uuid")
    private UUID taskId;

    @Column(nullable = false, length = 150)
    private String titre;

    @Column(length = 255)
    private String resume;

    @Column(nullable = false, columnDefinition = "text")
    private String contenu;

    @Column(name = "audio_url", columnDefinition = "text")
    private String audioUrl;

    /** Plan rapide : liste de chaines affichees en check-list. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "plan_points", columnDefinition = "jsonb")
    private List<String> planPoints;

    @Column(name = "niveau_indicatif", length = 2)
    private String niveauIndicatif;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getTaskId() { return taskId; }
    public void setTaskId(UUID taskId) { this.taskId = taskId; }

    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }

    public String getResume() { return resume; }
    public void setResume(String resume) { this.resume = resume; }

    public String getContenu() { return contenu; }
    public void setContenu(String contenu) { this.contenu = contenu; }

    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }

    public List<String> getPlanPoints() { return planPoints; }
    public void setPlanPoints(List<String> planPoints) { this.planPoints = planPoints; }

    public String getNiveauIndicatif() { return niveauIndicatif; }
    public void setNiveauIndicatif(String niveauIndicatif) { this.niveauIndicatif = niveauIndicatif; }

    public int getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }
}
