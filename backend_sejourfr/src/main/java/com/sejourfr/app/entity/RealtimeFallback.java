package com.sejourfr.app.entity;

import com.sejourfr.app.enums.RealtimeFallbackReason;
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

/** Une bascule vers l'enregistrement classique d'un candidat qui demandait l'examinateur (V090). */
@Entity
@Table(name = "realtime_fallbacks")
@Getter
@Setter
public class RealtimeFallback {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "production_task_id", columnDefinition = "uuid")
    private UUID productionTaskId;

    /** Renseigné seulement pour une reprise impossible. */
    @Column(name = "session_id", columnDefinition = "uuid")
    private UUID sessionId;

    @Column(name = "tache_numero")
    private Short tacheNumero;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private RealtimeFallbackReason reason;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
