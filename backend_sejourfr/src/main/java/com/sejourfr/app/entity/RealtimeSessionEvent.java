package com.sejourfr.app.entity;

import com.sejourfr.app.enums.RealtimeConductEventType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/** Événement de conduite d'une session EO temps réel (V090). */
@Entity
@Table(name = "realtime_session_events")
@Getter
@Setter
public class RealtimeSessionEvent {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "session_id", nullable = false, columnDefinition = "uuid")
    private UUID sessionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private RealtimeConductEventType type;

    /** ms depuis setupComplete côté client ; {@code null} pour un événement tracé par le serveur. */
    @Column(name = "at_ms")
    private Integer atMs;

    /** Durée associée (grâce de fin de temps), sinon {@code null}. */
    @Column(name = "value_ms")
    private Integer valueMs;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
