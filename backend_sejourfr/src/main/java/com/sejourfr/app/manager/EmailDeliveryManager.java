package com.sejourfr.app.manager;

import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailSkipReason;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.repository.EmailDeliveryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Le journal d'envoi ({@code email_deliveries}).
 *
 * <p>🛑 Les ecritures sont en {@code REQUIRES_NEW} : une ligne PENDING doit etre
 * <b>visible</b> des autres appels des qu'elle existe (c'est elle qui fait
 * l'anti-doublon et le plafond), et l'etat final d'un envoi ne doit jamais
 * dependre de la transaction de l'appelant — un mail parti reste « SENT » meme
 * si quelque chose echoue plus loin.
 */
@Component
@RequiredArgsConstructor
public class EmailDeliveryManager {

    private final EmailDeliveryRepository repository;

    /** Ce qu'on inscrit au journal avant (ou au lieu) d'un envoi. */
    public record NewDelivery(
            UUID userId,
            EmailType type,
            String recipient,
            EmailProvider provider,
            String deduplicationKey,
            UUID referenceId,
            Instant occurredAt,
            Instant createdAt
    ) {}

    /**
     * INSERT PENDING, ou rien si la cle est deja occupee.
     *
     * @return l'id de la ligne ecrite ; vide si un autre appel detient la cle
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Optional<UUID> insertPending(NewDelivery d) {
        return insert(d, EmailDeliveryStatus.PENDING, null);
    }

    /** Trace un refus (preference, allowlist, cle consommee). Occupe la cle. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Optional<UUID> insertSkipped(NewDelivery d, EmailSkipReason reason) {
        return insert(d, EmailDeliveryStatus.SKIPPED, reason);
    }

    /**
     * Trace un envoi qui n'a meme pas pu etre tente (executor sature). Une ligne
     * FAILED ne bloque pas la cle : la relance differee pourra la reprendre.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public UUID insertFailed(NewDelivery d, String error) {
        UUID id = insert(d, EmailDeliveryStatus.FAILED, null)
                .orElseThrow(() -> new IllegalStateException("ligne FAILED non ecrite"));
        repository.markFailed(id, d.createdAt(), error, (short) 0);
        return id;
    }

    private Optional<UUID> insert(NewDelivery d, EmailDeliveryStatus status, EmailSkipReason reason) {
        UUID id = UUID.randomUUID();
        int rows = repository.insertIfKeyFree(
                id,
                d.userId() == null ? null : d.userId().toString(),
                d.type().name(),
                d.type().category().name(),
                d.recipient(),
                status.name(),
                d.provider().name(),
                d.deduplicationKey(),
                d.referenceId() == null ? null : d.referenceId().toString(),
                d.occurredAt() == null ? null : d.occurredAt().toString(),
                reason == null ? null : reason.name(),
                d.createdAt());
        return rows == 1 ? Optional.of(id) : Optional.empty();
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markSent(UUID id, Instant sentAt, String providerMessageId, int attempts) {
        repository.markSent(id, sentAt, providerMessageId, (short) attempts);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailed(UUID id, Instant failedAt, String error, int attempts) {
        repository.markFailed(id, failedAt, error, (short) attempts);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int markStalePending(Instant before, Instant now) {
        return repository.markStalePending(before, now);
    }

    @Transactional(readOnly = true)
    public long countEngagementSince(UUID userId, Instant since) {
        return repository.countEngagementSince(userId, since);
    }

    @Transactional(readOnly = true)
    public long countFailedByKey(String key) {
        return repository.countFailedByKey(key);
    }

    @Transactional(readOnly = true)
    public List<EmailDelivery> findEventRetryCandidates(
            Collection<EmailType> types, Instant since, int maxRowsPerKey, int limit) {
        if (types.isEmpty()) {
            return List.of();
        }
        return repository.findEventRetryCandidates(
                types.stream().map(Enum::name).toList(), since, maxRowsPerKey, limit);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int deleteOlderThan(Instant cutoff, int limit) {
        return repository.deleteOlderThan(cutoff, limit);
    }

    /** Suppression / anonymisation du compte : joint la transaction appelante. */
    @Transactional
    public int deleteForAccount(UUID userId, String email) {
        return repository.deleteForAccount(userId, email == null ? "" : email);
    }

    @Transactional(readOnly = true)
    public List<EmailDelivery> findByKey(String deduplicationKey) {
        return repository.findByDeduplicationKeyOrderByCreatedAtAsc(deduplicationKey);
    }

    @Transactional(readOnly = true)
    public List<EmailDelivery> findByUserId(UUID userId) {
        return repository.findByUserIdOrderByCreatedAtAsc(userId);
    }

    @Transactional(readOnly = true)
    public Optional<EmailDelivery> findById(UUID id) {
        return repository.findById(id);
    }
}
