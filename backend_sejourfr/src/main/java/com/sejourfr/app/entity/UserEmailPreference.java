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
 * Les preferences email d'un compte ({@code user_email_preferences}, V073).
 *
 * <p>🛑 Une ligne ABSENTE vaut les valeurs par defaut (engagement actif,
 * marketing inactif). Elle nait a la premiere modification : aucune migration de
 * masse, et aucun lecteur ne doit supposer qu'elle existe.
 */
@Entity
@Table(name = "user_email_preferences")
@Getter
@Setter
public class UserEmailPreference {

    public static final boolean ENGAGEMENT_PAR_DEFAUT = true;
    public static final boolean MARKETING_PAR_DEFAUT = false;

    @Id
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "engagement_enabled", nullable = false)
    private boolean engagementEnabled = ENGAGEMENT_PAR_DEFAUT;

    @Column(name = "marketing_enabled", nullable = false)
    private boolean marketingEnabled = MARKETING_PAR_DEFAUT;

    @Column(name = "marketing_consent_at")
    private Instant marketingConsentAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
