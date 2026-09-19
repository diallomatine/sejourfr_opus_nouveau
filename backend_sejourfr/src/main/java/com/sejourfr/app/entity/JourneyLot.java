package com.sejourfr.app.entity;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Un <b>lot</b> : les priorites qu'une evaluation a retenues pour une epreuve
 * (3 max, R2), et l'examen de reevaluation qui les clot (R3).
 *
 * <p>🛑 <b>« Lot », pas « cycle »</b> (arbitrage D-8). Le depot sert deja un
 * <b>cycle de palier CECRL</b> aux fronts ({@code PlanCycleDto},
 * {@code PlanCycleState}, {@code PlanCycleResolver}) : d'ou part le candidat,
 * quel palier se construit, et l'examen blanc complet qui le confirme. Deux
 * « cycles » de sens different dans le meme ecran, c'est exactement la collision
 * qui a produit les six copies de la table des paliers.
 *
 * <p><b>Au plus un lot {@code OPEN} par epreuve</b> (R5), tenu par un index
 * unique partiel en base. Le verrou pessimiste sur le parcours serialise deja
 * les traitements ; l'index est la ceinture.
 */
@Entity
@Table(name = "journey_lot")
@Getter
@Setter
public class JourneyLot {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "journey_id", nullable = false)
    private Journey journey;

    @Enumerated(EnumType.STRING)
    @Column(name = "exam_type", nullable = false, length = 20)
    private EpreuveType examType;

    /**
     * La <b>thematique</b> du bloc, pour un cycle <b>CIVIQUE</b> — l'equivalent
     * d'{@link #examType} cote TCF.
     *
     * <p>🛑 <b>Exclusif d'{@link #examType}</b> ({@code chk_journey_lot_bloc}).
     * Le CHECK ne peut pas lire le module, qui vit sur {@code journey} : la forme
     * « exactement une des deux » est la seule qui tienne en base.
     *
     * <p>FK reelle vers {@code themes} : un bloc range sous une thematique
     * inexistante serait une trace fausse (D-32 Q-F6).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "theme_id")
    private Theme theme;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private JourneyLotStatus status = JourneyLotStatus.OPEN;

    /**
     * L'evaluation qui a <b>cree</b> ce lot. Ce n'est pas de la tracabilite
     * decorative : R14 s'en sert pour ignorer une evaluation arrivee en retard,
     * et « ces priorites viennent de quel examen ? » est une question que le
     * candidat pose.
     */
    @Column(name = "source_assessment_id", nullable = false, columnDefinition = "uuid")
    private UUID sourceAssessmentId;

    /** L'evaluation qui l'a ferme ou remplace. {@code null} tant qu'il est ouvert. */
    @Column(name = "closed_by_assessment_id", columnDefinition = "uuid")
    private UUID closedByAssessmentId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "closed_at")
    private Instant closedAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public boolean estOuvert() {
        return status == JourneyLotStatus.OPEN;
    }

    /**
     * Clot le lot. La base garantit que l'etat et la date ne peuvent pas se
     * contredire ({@code chk_journey_lot_closed_at}).
     */
    public void clore(JourneyLotStatus fin, UUID parEvaluation, Instant quand) {
        this.status = fin;
        this.closedByAssessmentId = parEvaluation;
        this.closedAt = quand;
    }
}
