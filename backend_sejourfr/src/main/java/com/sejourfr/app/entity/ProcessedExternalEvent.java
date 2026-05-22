package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;

/**
 * Journal des évènements webhook externes déjà traités (Stripe pour
 * l'instant, extensible). Sert d'idempotence : avant tout side-effect,
 * on tente d'insérer (provider, event_id) — si la PK conflit, on a déjà
 * traité l'évènement et on skip.
 *
 * <p>Cf. {@code BillingService.handleWebhook} et migration V101.
 */
@Entity
@Table(name = "processed_external_events")
@IdClass(ProcessedExternalEvent.PK.class)
public class ProcessedExternalEvent {

    /** Provider Stripe = "stripe". Réserver d'autres si on ajoute Google/Apple. */
    @Id
    @Column(name = "provider", length = 32, nullable = false)
    private String provider;

    @Id
    @Column(name = "event_id", length = 255, nullable = false)
    private String eventId;

    @Column(name = "processed_at", nullable = false)
    private Instant processedAt;

    public ProcessedExternalEvent() {}

    public ProcessedExternalEvent(String provider, String eventId, Instant processedAt) {
        this.provider = provider;
        this.eventId = eventId;
        this.processedAt = processedAt;
    }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public Instant getProcessedAt() { return processedAt; }
    public void setProcessedAt(Instant processedAt) { this.processedAt = processedAt; }

    /** Clé composite pour {@code @IdClass}. */
    public static class PK implements Serializable {
        private String provider;
        private String eventId;

        public PK() {}
        public PK(String provider, String eventId) {
            this.provider = provider;
            this.eventId = eventId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof PK pk)) return false;
            return Objects.equals(provider, pk.provider) && Objects.equals(eventId, pk.eventId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(provider, eventId);
        }
    }
}
