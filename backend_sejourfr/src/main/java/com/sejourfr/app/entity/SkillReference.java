package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SkillReferenceLevel;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une production de reference d'un petit sujet : ce qui serait insuffisant, ce
 * qui est attendu, ce qui serait tres reussi. Exactement une par niveau et par
 * sujet ({@code uq_skill_references_prompt_level}).
 *
 * <p><b>Garde produit</b> : ces textes ne sont servis qu'APRES que le candidat
 * a rendu sa propre production. Les montrer avant transformerait l'exercice en
 * recopie. Le controle vit cote serveur, pas seulement dans l'interface.
 */
@Entity
@Table(name = "skill_references")
@Getter
@Setter
public class SkillReference {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_prompt_id", nullable = false)
    private SkillPrompt skillPrompt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private SkillReferenceLevel level;

    @Column(nullable = false, columnDefinition = "text")
    private String text;

    /** Ce que la reference demontre, en une phrase adressee au candidat. */
    @Column(name = "pedagogical_note", nullable = false, columnDefinition = "text")
    private String pedagogicalNote;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
