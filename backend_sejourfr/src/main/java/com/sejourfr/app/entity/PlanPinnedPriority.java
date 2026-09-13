package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>La competence en premiere place du Plan</b>, epinglee jusqu'a la sortie de
 * son cycle. Une ligne par candidat, jamais plus.
 *
 * <p>C'est la <b>seule</b> chose que le Plan persiste en dehors de ses
 * observations, et elle repond a une seule question : « laquelle etait la
 * premiere ? ». L'ordre des suivantes, la nature de chaque action et l'etat de
 * chaque etape restent derives a la lecture — les persister creerait une
 * seconde autorite sur ce que le moteur sait deja recalculer.
 *
 * <p>Il n'y a <b>ni colonne d'etat ni {@code released_at}</b> : la condition de
 * liberation est deja ecrite dans
 * {@code LearningPlanPriorityResolver.actionable()}, qui ecarte une competence
 * dont le transfert est prouve ou dont la verification a ete rendue. Tant que la
 * competence epinglee est dans le pool, elle reste premiere ; des qu'elle en
 * sort, la ligne est reecrite sur la suivante.
 */
@Entity
@Table(name = "plan_pinned_priorities")
@Getter
@Setter
public class PlanPinnedPriority {

    @Id
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @MapsId
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_id", nullable = false)
    private Skill skill;

    @Column(name = "pinned_at", nullable = false)
    private Instant pinnedAt;

    @PrePersist
    void prePersist() {
        if (pinnedAt == null) pinnedAt = Instant.now();
    }
}
