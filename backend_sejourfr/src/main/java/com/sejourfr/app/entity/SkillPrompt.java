package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillSection;
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
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Un « petit sujet » : quelques phrases a produire, evaluees sur UN SEUL
 * critere ({@link #uniqueCriterion}). 5 par competence.
 *
 * <p><b>Deux colonnes exclusives</b> : un sujet ecrit porte une fourchette de
 * mots et aucune duree, un sujet oral l'inverse
 * ({@code chk_skill_prompts_ee_eo_coherence}). C'est ce qui garantit qu'un
 * front ne peut pas afficher un compteur de mots sur un enregistrement.
 *
 * <p>Ces bornes sont <b>indicatives et jamais bloquantes</b> : le serveur
 * n'a jamais refuse une production parce qu'elle en sortait. Le seul plafond
 * applique est un garde-fou anti-abus, tres au-dessus de ces valeurs.
 */
@Entity
@Table(name = "skill_prompts", indexes = {
        @Index(name = "idx_skill_prompts_skill_order", columnList = "skill_id, display_order")
})
@Getter
@Setter
public class SkillPrompt {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_id", nullable = false)
    private Skill skill;

    /**
     * Copie de {@code skill.section}, verrouillee par la cle etrangere
     * COMPOSITE {@code (skill_id, section) -> skills(id, section)} : elle ne
     * peut pas diverger de la competence parente. Denormalisee parce qu'un
     * CHECK ne sait pas faire de jointure, et que c'est elle qui rend la
     * coherence mots/duree verifiable par la base.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 2)
    private SkillSection section;

    /** Code editorial stable ({@code "EE1-C1-S1"}), unique et immuable apres creation. */
    @Column(nullable = false, length = 24)
    private String code;

    @Column(nullable = false, length = 160)
    private String title;

    /** La situation posee au candidat (a qui il ecrit/parle, dans quel cadre). */
    @Column(nullable = false, columnDefinition = "text")
    private String context;

    /** Ce qu'on lui demande de produire. */
    @Column(nullable = false, columnDefinition = "text")
    private String instruction;

    /**
     * LE critere evalue, et le seul. Affiche au candidat AVANT sa production
     * (regle UX non negociable : on ne cache pas ce sur quoi on juge) et
     * transmis tel quel au correcteur.
     */
    @Column(name = "unique_criterion", nullable = false, columnDefinition = "text")
    private String uniqueCriterion;

    /** EE uniquement (NULL en EO). Conseil d'ecriture, jamais un plafond. */
    @Column(name = "recommended_min_words")
    private Integer recommendedMinWords;

    @Column(name = "recommended_max_words")
    private Integer recommendedMaxWords;

    /** EO uniquement (NULL en EE). Conseil de duree, jamais un plafond. */
    @Column(name = "recommended_duration_seconds")
    private Integer recommendedDurationSeconds;

    @Enumerated(EnumType.STRING)
    @Column(name = "difficulty_level", nullable = false, length = 8)
    private SkillDifficulty difficultyLevel;

    @Column(name = "display_order", nullable = false)
    private short displayOrder;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

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
