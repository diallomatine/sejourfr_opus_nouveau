package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * Un segment relayé d'une session EO temps réel, horodaté côté client (V090).
 * Mesure seulement : la notation lit {@code realtime_sessions.transcript}.
 */
@Entity
@Table(name = "realtime_session_turns")
@Getter
@Setter
public class RealtimeSessionTurn {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "session_id", nullable = false, columnDefinition = "uuid")
    private UUID sessionId;

    /** Ordre d'arrivée côté serveur (0, 1, 2…), indépendant de l'index client. */
    @Column(nullable = false)
    private int seq;

    @Column(name = "turn_index")
    private Integer turnIndex;

    /** {@code CANDIDATE} ou {@code EXAMINER}. */
    @Column(nullable = false, length = 16)
    private String speaker;

    @Column(columnDefinition = "text", nullable = false)
    private String text;

    @Column(name = "word_count", nullable = false)
    private int wordCount;

    @Column(name = "started_at_ms")
    private Integer startedAtMs;

    @Column(name = "ended_at_ms")
    private Integer endedAtMs;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
