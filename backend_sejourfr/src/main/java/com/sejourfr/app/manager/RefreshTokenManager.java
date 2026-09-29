package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RefreshToken;
import com.sejourfr.app.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'accès aux données pour {@link RefreshToken}.
 */
@Component
@RequiredArgsConstructor
public class RefreshTokenManager {

    private final RefreshTokenRepository repository;

    public Optional<RefreshToken> findByJti(UUID jti) {
        return repository.findById(jti);
    }

    public RefreshToken save(RefreshToken token) {
        return repository.save(token);
    }

    public int revokeAllForUser(UUID userId) {
        return repository.revokeAllForUser(userId, Instant.now());
    }
}
