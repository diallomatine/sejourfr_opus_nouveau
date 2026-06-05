package com.sejourfr.app.entity;

import com.sejourfr.app.enums.EpreuveType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Catalogue des consignes pour les epreuves productives (TCF_EO / TCF_EE).
 * Une task est rejouable a l'infini et independante des attempts.
 */
@Entity
@Table(name = "production_tasks", indexes = {
        @Index(name = "idx_prod_task_lookup", columnList = "epreuve, niveau_cible, is_active")
})
public class ProductionTask {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EpreuveType epreuve;

    @Column(name = "tache_numero", nullable = false)
    private Short tacheNumero;

    @Column(name = "niveau_cible", nullable = false, length = 4)
    private String niveauCible;

    @Column(nullable = false, columnDefinition = "text")
    private String consigne;

    @Column(columnDefinition = "text")
    private String contexte;

    /** Pour les taches EO uniquement (NULL sinon). Cible officielle. */
    @Column(name = "duree_max_sec")
    private Integer dureeMaxSec;

    /**
     * Seuil minimal acceptable EO (NULL sinon). En dessous, la production n'est
     * pas bloquee mais minoree + avertie (cf. AiEvaluationService).
     */
    @Column(name = "duree_min_sec")
    private Integer dureeMinSec;

    /** Pour les taches EE uniquement (NULL sinon). */
    @Column(name = "mots_min")
    private Integer motsMin;

    @Column(name = "mots_max")
    private Integer motsMax;

    @Column(name = "is_active", nullable = false)
    private boolean active = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public EpreuveType getEpreuve() { return epreuve; }
    public void setEpreuve(EpreuveType epreuve) { this.epreuve = epreuve; }

    public Short getTacheNumero() { return tacheNumero; }
    public void setTacheNumero(Short tacheNumero) { this.tacheNumero = tacheNumero; }

    public String getNiveauCible() { return niveauCible; }
    public void setNiveauCible(String niveauCible) { this.niveauCible = niveauCible; }

    public String getConsigne() { return consigne; }
    public void setConsigne(String consigne) { this.consigne = consigne; }

    public String getContexte() { return contexte; }
    public void setContexte(String contexte) { this.contexte = contexte; }

    public Integer getDureeMaxSec() { return dureeMaxSec; }
    public void setDureeMaxSec(Integer dureeMaxSec) { this.dureeMaxSec = dureeMaxSec; }

    public Integer getDureeMinSec() { return dureeMinSec; }
    public void setDureeMinSec(Integer dureeMinSec) { this.dureeMinSec = dureeMinSec; }

    public Integer getMotsMin() { return motsMin; }
    public void setMotsMin(Integer motsMin) { this.motsMin = motsMin; }

    public Integer getMotsMax() { return motsMax; }
    public void setMotsMax(Integer motsMax) { this.motsMax = motsMax; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
