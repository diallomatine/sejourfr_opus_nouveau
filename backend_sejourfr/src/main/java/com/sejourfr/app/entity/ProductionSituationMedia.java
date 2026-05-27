package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import org.hibernate.annotations.UuidGenerator;

import java.util.UUID;

/**
 * Support visuel d'une {@link ProductionSituation}. {@code type=IMAGE} pointe
 * une URL R2 ({@code imageUrl}) ; {@code type=SVG} embarque un SVG inline
 * ({@code inlineSvg}) — pratique pour les sujets EO tache 2 facon "3 logements".
 */
@Entity
@Table(name = "production_situation_medias", indexes = {
        @Index(name = "idx_prod_sit_medias_situation", columnList = "situation_id, display_order")
})
public class ProductionSituationMedia {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "situation_id", nullable = false, columnDefinition = "uuid")
    private UUID situationId;

    /** IMAGE | SVG. */
    @Column(nullable = false, length = 10)
    private String type;

    @Column(name = "image_url", columnDefinition = "text")
    private String imageUrl;

    @Column(name = "inline_svg", columnDefinition = "text")
    private String inlineSvg;

    @Column(columnDefinition = "text")
    private String legende;

    @Column(name = "alt_text", nullable = false, columnDefinition = "text")
    private String altText;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getSituationId() { return situationId; }
    public void setSituationId(UUID situationId) { this.situationId = situationId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getInlineSvg() { return inlineSvg; }
    public void setInlineSvg(String inlineSvg) { this.inlineSvg = inlineSvg; }

    public String getLegende() { return legende; }
    public void setLegende(String legende) { this.legende = legende; }

    public String getAltText() { return altText; }
    public void setAltText(String altText) { this.altText = altText; }

    public int getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }
}
