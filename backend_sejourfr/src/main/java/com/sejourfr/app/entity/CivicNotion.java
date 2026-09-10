package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une <b>notion civique</b> du referentiel de travail (V051, lot L8).
 *
 * <p>🛑 <b>Referentiel de TRAVAIL, pas liste figee.</b> {@code 50_} §6.1 :
 * les 40 notions « ne sont ni validees ni remplacees par une liste
 * definitive » et sont « destinees a etre ajustees APRES le tagging ».
 *
 * <p>🛑 <b>Une notion ne se supprime pas, elle FUSIONNE.</b> A la porte de
 * revue (§6.1.3), une notion trop peu dotee est desactivee et
 * {@link #mergedInto} pointe vers celle qui la reprend. Les questions deja
 * taguees gardent leur lien, et la decision reste lisible en base — supprimer
 * la ligne effacerait a la fois le travail humain et sa raison.
 */
@Entity
@Table(name = "civic_notions")
@Getter
@Setter
public class CivicNotion {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false, length = 64, unique = true)
    private String code;

    @Column(nullable = false, length = 200)
    private String label;

    /** Le theme par son CODE ({@code CIV_PRINCIPES}…), jamais par UUID. */
    @Column(name = "theme_code", nullable = false, length = 64)
    private String themeCode;

    @Column(name = "display_order", nullable = false)
    private short displayOrder;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /**
     * Notion qui reprend celle-ci apres fusion. {@code null} = notion vivante.
     * La base impose qu'une notion fusionnee soit desactivee.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "merged_into_id")
    private CivicNotion mergedInto;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
