package com.sejourfr.app.entity;

import com.sejourfr.app.enums.MediaType;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "medias")
public class Media {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private MediaType type;

    /** URL publique (locale, externe ou R2). Null pour les medias SVG inline. */
    @Column(length = 500)
    private String url;

    /** Cle de stockage relative pour le provider local (null si URL externe). */
    @Column(name = "storage_key", length = 500)
    private String storageKey;

    @Column(name = "original_filename", length = 255)
    private String originalFilename;

    @Column(name = "content_type", length = 120)
    private String contentType;

    @Column(name = "size_bytes")
    private Long sizeBytes;

    @Column(name = "duration_sec")
    private Integer durationSec;

    @Column(name = "alt_text", length = 500)
    private String altText;

    @Column(name = "transcript", columnDefinition = "text")
    private String transcript;

    /**
     * SVG inline. Quand renseigné, le front affiche ce balisage SVG plutôt
     * que de charger {@link #url}. Utilisé pour les questions TCF (CE A2/B1)
     * où l'image est dessinée à la volée et embarquée dans la migration.
     */
    @Column(name = "inline_svg", columnDefinition = "text")
    private String inlineSvg;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public MediaType getType() { return type; }
    public void setType(MediaType type) { this.type = type; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getStorageKey() { return storageKey; }
    public void setStorageKey(String storageKey) { this.storageKey = storageKey; }

    public String getOriginalFilename() { return originalFilename; }
    public void setOriginalFilename(String originalFilename) { this.originalFilename = originalFilename; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public Long getSizeBytes() { return sizeBytes; }
    public void setSizeBytes(Long sizeBytes) { this.sizeBytes = sizeBytes; }

    public Integer getDurationSec() { return durationSec; }
    public void setDurationSec(Integer durationSec) { this.durationSec = durationSec; }

    /** Alias pour compatibilité avec le runner/DTO MediaResponse. */
    public Integer getDurationSeconds() { return durationSec; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSec = durationSeconds; }

    public String getAltText() { return altText; }
    public void setAltText(String altText) { this.altText = altText; }

    public String getTranscript() { return transcript; }
    public void setTranscript(String transcript) { this.transcript = transcript; }

    public String getInlineSvg() { return inlineSvg; }
    public void setInlineSvg(String inlineSvg) { this.inlineSvg = inlineSvg; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
