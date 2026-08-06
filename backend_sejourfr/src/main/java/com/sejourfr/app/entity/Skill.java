package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une micro-competence d'une tache TCF (8 par tache). C'est le grain
 * intermediaire du module : au-dessus vivent les 6 taches (enum
 * {@link SkillTaskCode}, pas de table), en dessous les 5 petits sujets
 * ({@link SkillPrompt}).
 *
 * <p>{@link #section} est denormalisee depuis {@link #taskCode} et verrouillee
 * en base par {@code chk_skills_section_matches_task}. Elle sert surtout de
 * cible a la cle etrangere COMPOSITE de {@code skill_prompts}, qui rend
 * impossible un sujet ecrit rattache a une competence orale.
 */
@Entity
@Table(name = "skills", indexes = {
        @Index(name = "uq_skills_task_order", columnList = "task_code, display_order", unique = true)
})
@Getter
@Setter
public class Skill {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 2)
    private SkillSection section;

    @Enumerated(EnumType.STRING)
    @Column(name = "task_code", nullable = false, length = 3)
    private SkillTaskCode taskCode;

    /** Code editorial stable ({@code "EE1-C1"}), unique et immuable apres creation. */
    @Column(nullable = false, length = 16)
    private String code;

    @Column(nullable = false, length = 160)
    private String title;

    /**
     * Ce que la competence apporte au TCF, en une ou deux phrases adressees au
     * candidat. Rendue telle quelle dans l'encart « Pourquoi cet exercice ? ».
     */
    @Column(nullable = false, columnDefinition = "text")
    private String description;

    /**
     * Le critere GENERAL travaille par la competence, distinct de
     * {@link #description}. La spec demande d'afficher les deux sur l'ecran
     * d'une competence : « une courte explication » ET « le critere general
     * travaille ». Les confondre obligeait les fronts a rendre le meme texte a
     * deux endroits.
     *
     * <p>A ne pas confondre non plus avec {@code SkillPrompt.uniqueCriterion},
     * qui est le critere precis d'UN petit sujet : celui-ci couvre les 5.
     */
    @Column(name = "general_criterion", nullable = false, columnDefinition = "text")
    private String generalCriterion;

    /**
     * Palier CECRL vise par cette competence precise ({@code A1}..{@code B2}).
     * String et non {@code TargetLevel} : le referentiel des competences
     * descend jusqu'a A1, que {@code TargetLevel} (A2/B1/B2, palier
     * d'abonnement du candidat) ne connait pas. Meme convention que
     * {@code ProductionTask.niveauCible}.
     */
    @Column(name = "target_level", nullable = false, length = 4)
    private String targetLevel;

    /** Rang d'affichage 1..8 dans sa tache : progression pedagogique, pas un detail cosmetique. */
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
