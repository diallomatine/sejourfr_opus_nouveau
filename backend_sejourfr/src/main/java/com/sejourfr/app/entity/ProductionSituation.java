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
import java.util.Map;
import java.util.UUID;

/**
 * Scenario concret rattache a une {@link ProductionTask}. Pour l'EO tache 2/3,
 * plusieurs situations actives = les "5 sujets" parmi lesquels l'examinateur
 * choisirait. Les supports ({@link ProductionSituationMedia}) et les reponses
 * modeles ({@link ProductionExample}) sont charges separement par le manager.
 */
@Entity
@Table(name = "production_situations", indexes = {
        @Index(name = "idx_prod_situations_task", columnList = "task_id, display_order")
})
public class ProductionSituation {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "task_id", nullable = false, columnDefinition = "uuid")
    private UUID taskId;

    @Column(nullable = false, length = 150)
    private String titre;

    @Column(nullable = false, columnDefinition = "text")
    private String contexte;

    @Column(columnDefinition = "text")
    private String consigne;

    /** Jeu de role (EO tache 2) : role tenu par le candidat. */
    @Column(name = "role_candidat", columnDefinition = "text")
    private String roleCandidat;

    /** Jeu de role : role tenu par l'app / l'examinateur. */
    @Column(name = "role_examinateur", columnDefinition = "text")
    private String roleExaminateur;

    @Column(columnDefinition = "text")
    private String objectif;

    /** EE : message declencheur {expediteur, avatar, texte}. NULL sinon. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> declencheur;

    /** Plan d'aide : [{icon, titre, aide}]. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private List<Map<String, Object>> etapes;

    @Column(name = "niveau_indicatif", length = 2)
    private String niveauIndicatif;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

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

    public String getContexte() { return contexte; }
    public void setContexte(String contexte) { this.contexte = contexte; }

    public String getConsigne() { return consigne; }
    public void setConsigne(String consigne) { this.consigne = consigne; }

    public String getRoleCandidat() { return roleCandidat; }
    public void setRoleCandidat(String roleCandidat) { this.roleCandidat = roleCandidat; }

    public String getRoleExaminateur() { return roleExaminateur; }
    public void setRoleExaminateur(String roleExaminateur) { this.roleExaminateur = roleExaminateur; }

    public String getObjectif() { return objectif; }
    public void setObjectif(String objectif) { this.objectif = objectif; }

    public Map<String, Object> getDeclencheur() { return declencheur; }
    public void setDeclencheur(Map<String, Object> declencheur) { this.declencheur = declencheur; }

    public List<Map<String, Object>> getEtapes() { return etapes; }
    public void setEtapes(List<Map<String, Object>> etapes) { this.etapes = etapes; }

    public String getNiveauIndicatif() { return niveauIndicatif; }
    public void setNiveauIndicatif(String niveauIndicatif) { this.niveauIndicatif = niveauIndicatif; }

    public int getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
