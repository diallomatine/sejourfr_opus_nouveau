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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

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

    /**
     * Intitule editorial court du sujet (« Invitation a un pique-nique »),
     * affiche en tete de sa carte. NULLABLE : le contenu anterieur a V028 n'en
     * a pas, et un sujet cree en console peut rester sans titre — les fronts
     * retombent alors sur « Sujet N » + consigne. Jamais une chaine vide
     * (contrainte {@code chk_prod_task_titre}).
     */
    @Column(length = 80)
    private String titre;

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

    /**
     * Fiche de scenario de l'examinateur-personnage — EO tache 2 uniquement,
     * NULL partout ailleurs (contrainte {@code chk_prod_task_agent_role_card}).
     * Absente, l'examinateur retombe sur son comportement historique : il
     * improvise ses faits.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "agent_role_card", columnDefinition = "jsonb")
    private AgentRoleCard agentRoleCard;

    @Column(name = "is_active", nullable = false)
    private boolean active = false;

    /**
     * Identite stable d'un sujet de diagnostic SejourFR. NULL pour tout le
     * catalogue TCF classique. La paire code/version permet de conserver un
     * diagnostic initial commun tout en publiant plus tard une nouvelle
     * version sans remplacer silencieusement les sujets deja passes.
     */
    @Column(name = "diagnostic_code", length = 64)
    private String diagnosticCode;

    @Column(name = "diagnostic_version")
    private Integer diagnosticVersion;

    /** URL publique R2 de la consigne audio fixe (diagnostic EO uniquement). */
    @Column(name = "instruction_audio_url", length = 500)
    private String instructionAudioUrl;

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

    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }

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

    public AgentRoleCard getAgentRoleCard() { return agentRoleCard; }
    public void setAgentRoleCard(AgentRoleCard agentRoleCard) { this.agentRoleCard = agentRoleCard; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getDiagnosticCode() { return diagnosticCode; }
    public void setDiagnosticCode(String diagnosticCode) { this.diagnosticCode = diagnosticCode; }

    public Integer getDiagnosticVersion() { return diagnosticVersion; }
    public void setDiagnosticVersion(Integer diagnosticVersion) { this.diagnosticVersion = diagnosticVersion; }

    public String getInstructionAudioUrl() { return instructionAudioUrl; }
    public void setInstructionAudioUrl(String instructionAudioUrl) { this.instructionAudioUrl = instructionAudioUrl; }

    public boolean isDiagnostic() { return diagnosticCode != null && !diagnosticCode.isBlank(); }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
