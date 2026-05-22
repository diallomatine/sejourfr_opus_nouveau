package com.sejourfr.app.manager;

import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.repository.EmailChangeTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'accès aux données pour {@link EmailChangeToken}. Même API que
 * {@link PasswordResetTokenManager}, étendue d'une méthode d'invalidation
 * scoped par user.
 */
@Component
@RequiredArgsConstructor
public class EmailChangeTokenManager {

    private final EmailChangeTokenRepository repository;

    public Optional<EmailChangeToken> findByTokenHash(String tokenHash) {
        return repository.findByTokenHash(tokenHash);
    }

    public EmailChangeToken save(EmailChangeToken token) {
        return repository.save(token);
    }

    /** Invalide tous les tokens en attente d'un user (avant d'en émettre un nouveau). */
    public void invalidateAllForUser(UUID userId, Instant now) {
        repository.invalidateAllForUser(userId, now);
    }
}
