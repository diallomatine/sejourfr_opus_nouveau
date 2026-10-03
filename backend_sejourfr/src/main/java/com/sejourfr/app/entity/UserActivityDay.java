package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Presence d'un compte un jour donne sur une plateforme (V087). L'ecriture passe
 * par un upsert natif ({@code UserActivityDayRepository.touch}) ; l'entite sert
 * a la lecture et a la validation du schema.
 */
@Entity
@Table(name = "user_activity_day")
@Getter
@Setter
public class UserActivityDay {

    @EmbeddedId
    private UserActivityDayId id;

    @Column(name = "first_seen_at", nullable = false)
    private Instant firstSeenAt;

    @Column(name = "last_seen_at", nullable = false)
    private Instant lastSeenAt;
}
