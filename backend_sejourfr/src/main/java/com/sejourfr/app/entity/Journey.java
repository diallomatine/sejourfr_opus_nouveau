package com.sejourfr.app.entity;

import com.sejourfr.app.enums.TargetLevel;
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
 * Le <b>parcours TCF</b> d'un candidat pour <b>un</b> niveau cible (R18).
 *
 * <p>Cette table n'est qu'une <b>enveloppe</b> : elle porte l'identite du
 * parcours et le compteur de positions. Tout ce qui se lit a l'ecran — le statut
 * de chaque etape, le verrou, l'etape courante — se <b>derive a la lecture</b>
 * (D-7), et tout ce qui se mesure — priorites, niveau, maitrise — vit chez ses
 * autorites existantes.
 *
 * <p>🛑 <b>Pas de parcours sans niveau cible</b> (arbitrage D-3). Un candidat qui
 * n'a pas declare sa demarche n'a <b>aucune ligne ici</b> : l'API rend
 * {@code NEEDS_OBJECTIVE} et l'ecran propose « Choisir mon objectif ». Creer un
 * parcours « par defaut » reviendrait a choisir un objectif a sa place, et a
 * batir une file sur cette supposition.
 *
 * <p><b>Changer d'objectif ne detruit rien</b> : on bascule vers le parcours de
 * ce niveau, l'ancien est conserve tel quel, et si le nouveau n'existe pas le
 * bootstrap (R19) le reconstruit depuis les evaluations deja passees. Un
 * changement d'objectif ne force <b>jamais</b> un nouveau diagnostic.
 */
@Entity
@Table(name = "journey")
@Getter
@Setter
public class Journey {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * Le niveau vise par ce parcours. <b>Jamais {@code null}</b> (D-3).
     *
     * <p>🛑 Il est <b>lu</b> chez {@code TargetProcedure.niveauVise(procedure,
     * declare)} au moment de la creation, jamais recalcule ici : la table des
     * paliers a deja vecu en six copies dans ce depot.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "target_level", nullable = false, length = 8)
    private TargetLevel targetLevel;

    /**
     * La prochaine position libre de la file. <b>Monotone</b> : jamais
     * decremente, jamais renumerote.
     *
     * <p>C'est ce qui rend R4 vrai — « toute nouvelle etape se range apres tout
     * ce qui est deja planifie ». Renumeroter ferait bouger un parcours que le
     * candidat a sous les yeux, et rendrait l'ordre dependant du moment de la
     * lecture.
     */
    @Column(name = "next_position", nullable = false)
    private long nextPosition = 1L;

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

    /** Reserve la position suivante. Appele sous le verrou du parcours (R14). */
    public long consommerPosition() {
        long position = nextPosition;
        nextPosition = position + 1;
        return position;
    }
}
