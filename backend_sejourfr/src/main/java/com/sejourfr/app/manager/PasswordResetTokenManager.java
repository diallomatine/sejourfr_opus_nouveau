package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PasswordResetToken;
import com.sejourfr.app.repository.PasswordResetTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;

/**
 * Couche d'acces aux donnees pour {@link PasswordResetToken}.
 */
@Component
@RequiredArgsConstructor
public class PasswordResetTokenManager {

    private final PasswordResetTokenRepository repository;

    public Optional<PasswordResetToken> findByTokenHash(String tokenHash) {
        return repository.findByTokenHash(tokenHash);
    }

    public PasswordResetToken save(PasswordResetToken token) {
        return repository.save(token);
    }

    /** Invalide tous les tokens encore actifs d'un user (avant d'en emettre un nouveau). */
    public void invalidateAllForUser(java.util.UUID userId, Instant now) {
        repository.invalidateAllForUser(userId, now);
    }
}
