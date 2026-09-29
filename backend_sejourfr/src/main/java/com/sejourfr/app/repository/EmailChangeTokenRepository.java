package com.sejourfr.app.repository;

import com.sejourfr.app.entity.EmailChangeToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EmailChangeTokenRepository extends JpaRepository<EmailChangeToken, UUID> {

    Optional<EmailChangeToken> findByTokenHash(String tokenHash);

    @Modifying
    @Query("UPDATE EmailChangeToken t SET t.usedAt = :now WHERE t.user.id = :userId AND t.usedAt IS NULL")
    void invalidateAllForUser(UUID userId, Instant now);

    @Modifying
    @Query("DELETE FROM EmailChangeToken t WHERE t.expiresAt < :before")
    int deleteExpired(Instant before);
}
