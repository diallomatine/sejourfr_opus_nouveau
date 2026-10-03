package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ClientPlatform;
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

/**
 * Une <b>ouverture de session</b> (login ou inscription, locale ou sociale) —
 * V087. Jamais un refresh, jamais d'IP ni de User-Agent : c'est une mesure
 * (12 mois), pas un journal de securite. Ecrite par {@code UserLoginEventService}
 * apres le commit de l'authentification.
 */
@Entity
@Table(name = "user_login_event")
@Getter
@Setter
public class UserLoginEvent {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "kind", nullable = false, length = 16)
    private AuthKind kind;

    /** Methode de CETTE connexion (un compte local qui passe par Google ⇒ GOOGLE). */
    @Enumerated(EnumType.STRING)
    @Column(name = "auth_method", nullable = false, length = 16)
    private AuthProvider authMethod;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", nullable = false, length = 16)
    private ClientPlatform platform;
}
