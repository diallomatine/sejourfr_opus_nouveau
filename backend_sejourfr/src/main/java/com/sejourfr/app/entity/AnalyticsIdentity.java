package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Lien entre un parcours anonyme et un compte.
 *
 * <p>Cle composee volontaire : un appareil partage porte legitimement plusieurs
 * comptes derriere un seul {@code anonymous_id}, et un meme compte peut avoir
 * plusieurs parcours anonymes (deux navigateurs, un telephone et un
 * ordinateur). Une colonne {@code user_id} sur {@code analytics_visitor}
 * obligerait a en ecraser un.
 */
@Entity
@Table(name = "analytics_identity")
@IdClass(AnalyticsIdentity.Key.class)
public class AnalyticsIdentity {

    @Id
    @Column(name = "anonymous_id", columnDefinition = "uuid")
    private UUID anonymousId;

    @Id
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "linked_at", nullable = false)
    private Instant linkedAt;

    public UUID getAnonymousId() { return anonymousId; }
    public void setAnonymousId(UUID anonymousId) { this.anonymousId = anonymousId; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public Instant getLinkedAt() { return linkedAt; }
    public void setLinkedAt(Instant linkedAt) { this.linkedAt = linkedAt; }

    /** Cle composee (anonyme, compte). */
    public static class Key implements Serializable {
        private UUID anonymousId;
        private UUID userId;

        public Key() {
        }

        public Key(UUID anonymousId, UUID userId) {
            this.anonymousId = anonymousId;
            this.userId = userId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Key key)) return false;
            return Objects.equals(anonymousId, key.anonymousId) && Objects.equals(userId, key.userId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(anonymousId, userId);
        }
    }
}
