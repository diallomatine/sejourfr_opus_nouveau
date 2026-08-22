package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AnalyticsEvent;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Une ligne du journal comportemental.
 *
 * <p>Nommee {@code AnalyticsEventRecord} et non {@code AnalyticsEvent} : ce
 * dernier nom est pris par l'<b>enum</b> du registre
 * ({@link com.sejourfr.app.enums.AnalyticsEvent}), qui est la piece la plus
 * consultee des deux — c'est elle qui dit ce qui existe.
 *
 * <p>Les cles de {@link #properties} sont bornees par l'evenement lui-meme
 * ({@code AnalyticsProperty}) ; rien d'autre ne peut y entrer.
 *
 * <p>L'ecriture passe par un insert natif {@code ON CONFLICT DO NOTHING} sur
 * {@code dedup_key} : un rejeu n'ecrit rien et ne leve rien. Cette entite sert
 * a la lecture et au parametrage du seul insert.
 */
@Entity
@Table(name = "analytics_event")
public class AnalyticsEventRecord {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "event", nullable = false, length = 48)
    private AnalyticsEvent event;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    @Column(name = "anonymous_id", nullable = false, columnDefinition = "uuid")
    private UUID anonymousId;

    @Column(name = "session_id", nullable = false, columnDefinition = "uuid")
    private UUID sessionId;

    /** Pose a l'ecriture si le visiteur est deja identifie. Jamais backfille. */
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "path", length = 160)
    private String path;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "properties", nullable = false, columnDefinition = "jsonb")
    private Map<String, String> properties;

    @Column(name = "dedup_key", length = 120)
    private String dedupKey;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public AnalyticsEvent getEvent() { return event; }
    public void setEvent(AnalyticsEvent event) { this.event = event; }

    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }

    public UUID getAnonymousId() { return anonymousId; }
    public void setAnonymousId(UUID anonymousId) { this.anonymousId = anonymousId; }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getPath() { return path; }
    public void setPath(String path) { this.path = path; }

    public Map<String, String> getProperties() { return properties; }
    public void setProperties(Map<String, String> properties) { this.properties = properties; }

    public String getDedupKey() { return dedupKey; }
    public void setDedupKey(String dedupKey) { this.dedupKey = dedupKey; }
}
