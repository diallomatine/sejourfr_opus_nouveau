package com.sejourfr.app.entity;

import com.sejourfr.app.enums.EmailCategory;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailSkipReason;
import com.sejourfr.app.enums.EmailType;
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
 * Une ligne du journal d'envoi ({@code email_deliveries}, V073).
 *
 * <p>🛑 Ni HTML, ni variables : une URL a jeton ne doit jamais etre persistee.
 * {@code userId} est une colonne nue (pas d'association) : le journal ne charge
 * jamais le compte, et il survit a une ligne {@code users} anonymisee le temps
 * de sa purge.
 *
 * <p>L'insertion passe par {@code EmailDeliveryRepository.insertPending} /
 * {@code insertSkipped} ({@code ON CONFLICT DO NOTHING}), jamais par un
 * {@code save()} : c'est ce qui rend l'anti-doublon atomique.
 */
@Entity
@Table(name = "email_deliveries")
@Getter
@Setter
public class EmailDelivery {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "email_type", nullable = false, length = 64)
    private EmailType emailType;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 16)
    private EmailCategory category;

    @Column(name = "recipient", nullable = false, length = 320)
    private String recipient;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private EmailDeliveryStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "provider", nullable = false, length = 16)
    private EmailProvider provider;

    @Column(name = "provider_message_id", length = 255)
    private String providerMessageId;

    @Column(name = "deduplication_key", length = 255)
    private String deduplicationKey;

    @Column(name = "reference_id", columnDefinition = "uuid")
    private UUID referenceId;

    @Column(name = "occurred_at")
    private Instant occurredAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "skip_reason", length = 32)
    private EmailSkipReason skipReason;

    @Column(name = "error_message", length = 500)
    private String errorMessage;

    @Column(name = "attempt_count", nullable = false)
    private short attemptCount;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "sent_at")
    private Instant sentAt;

    @Column(name = "failed_at")
    private Instant failedAt;
}
