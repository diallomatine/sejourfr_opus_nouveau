package com.sejourfr.app.entity;

import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.FunnelEvent;
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
import jakarta.persistence.Table;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Premiere occurrence d'une etape de funnel qui n'existe que dans le
 * navigateur (ou posee par le serveur au depart d'un paiement).
 *
 * <p><strong>Une ligne par (compte, evenement), jamais deux</strong> : l'index
 * unique {@code uq_user_funnel_event} borne la table a 3 lignes par compte.
 * L'ecriture passe par un {@code ON CONFLICT DO NOTHING} — un rejeu ne cree
 * rien et ne leve rien.
 */
@Entity
@Table(name = "user_funnel_events", indexes = {
        @Index(name = "idx_user_funnel_events_event_date", columnList = "event, occurred_at DESC")
})
public class UserFunnelEvent {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 48)
    private FunnelEvent event;

    /** Contexte du moment : il peut differer de celui de l'inscription. */
    @Enumerated(EnumType.STRING)
    @Column(length = 16)
    private ClientPlatform platform;

    @Column(length = 40)
    private String source;

    @Column(name = "occurred_at", nullable = false, updatable = false)
    private Instant occurredAt;

    @PrePersist
    void prePersist() {
        if (occurredAt == null) occurredAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public FunnelEvent getEvent() { return event; }
    public void setEvent(FunnelEvent event) { this.event = event; }

    public ClientPlatform getPlatform() { return platform; }
    public void setPlatform(ClientPlatform platform) { this.platform = platform; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }
}
