package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
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
 * Une <b>décision admin</b> sur l'accès d'un compte à un produit (V083) :
 * {@code GRANT} ou {@code REVOKE} sur la fenêtre {@code [startsAt, endsAt)}.
 *
 * <p>🛑 Ce n'est PAS un achat : les achats restent dans {@code user_subscriptions},
 * intacts. L'accès effectif se calcule à la lecture
 * ({@code AccesEffectifResolver}), jamais ici.
 *
 * <p>Jamais supprimée (hors purge de compte), toujours <b>remplacée</b>
 * ({@code supersededAt}). Les fenêtres des décisions courantes d'un même
 * (compte, produit) ne se chevauchent jamais (contrainte d'exclusion V083).
 */
@Entity
@Table(name = "access_overrides")
@Getter
@Setter
public class AccessOverride {

    /** Tiré en Java : la décision est simulée (aperçu) avant d'être écrite. */
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "product", nullable = false, length = 16)
    private ModuleAccess product;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 8)
    private AccessOverrideType type;

    @Column(name = "starts_at", nullable = false)
    private Instant startsAt;

    /** Borne EXCLUSIVE ; {@code null} = sans fin (REVOKE seulement). */
    @Column(name = "ends_at")
    private Instant endsAt;

    /**
     * Instant de la décision d'origine — copié tel quel sur une copie tronquée.
     * C'est lui que lit « un achat postérieur au REVOKE rouvre l'accès ».
     */
    @Column(name = "decided_at", nullable = false)
    private Instant decidedAt;

    @Column(name = "reason", nullable = false, length = 500)
    private String reason;

    @Column(name = "created_by", nullable = false, columnDefinition = "uuid")
    private UUID createdBy;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "operation_id", nullable = false, columnDefinition = "uuid")
    private UUID operationId;

    @Column(name = "replaces_override_id", columnDefinition = "uuid")
    private UUID replacesOverrideId;

    @Column(name = "superseded_at")
    private Instant supersededAt;

    @Column(name = "superseded_by_operation_id", columnDefinition = "uuid")
    private UUID supersededByOperationId;

    /** Vrai si la fenêtre de cette décision couvre {@code t} (début inclus, fin exclue). */
    public boolean couvre(Instant t) {
        return !startsAt.isAfter(t) && (endsAt == null || endsAt.isAfter(t));
    }

    public boolean estCourante() {
        return supersededAt == null;
    }
}
