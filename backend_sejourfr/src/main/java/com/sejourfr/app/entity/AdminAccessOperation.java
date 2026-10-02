package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Une action admin sur l'accès d'un compte (V083) : qui, quand, quoi, motif,
 * et la photo avant / après. Son {@code id} est l'{@code operationId} partagé
 * par toutes les décisions qu'elle a écrites.
 *
 * <p>⚠️ {@code beforeState} / {@code afterState} sont figés à l'instant de
 * l'action pour l'HISTORIQUE seulement : ils ne servent jamais à calculer un
 * accès (même famille que les exceptions « décision prise à un instant »).
 */
@Entity
@Table(name = "admin_access_operations")
@Getter
@Setter
public class AdminAccessOperation {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "admin_user_id", nullable = false, columnDefinition = "uuid")
    private UUID adminUserId;

    @Enumerated(EnumType.STRING)
    @Column(name = "operation", nullable = false, length = 24)
    private AdminAccessOperationType operation;

    @Enumerated(EnumType.STRING)
    @Column(name = "product", nullable = false, length = 16)
    private ModuleAccess product;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_product", length = 16)
    private ModuleAccess fromProduct;

    @Column(name = "starts_at")
    private Instant startsAt;

    @Column(name = "ends_at")
    private Instant endsAt;

    @Column(name = "reason", nullable = false, length = 500)
    private String reason;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "before_state", nullable = false, columnDefinition = "jsonb")
    private List<Map<String, Object>> beforeState;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "after_state", nullable = false, columnDefinition = "jsonb")
    private List<Map<String, Object>> afterState;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
