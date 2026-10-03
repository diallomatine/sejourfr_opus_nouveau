package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserLoginEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface UserLoginEventRepository extends JpaRepository<UserLoginEvent, UUID> {

    List<UserLoginEvent> findByUserIdOrderByOccurredAtAsc(UUID userId);

    /** Purge bornee de la retention (365 j). */
    @Modifying
    @Query(value = """
            DELETE FROM user_login_event
             WHERE id IN (SELECT id FROM user_login_event WHERE occurred_at < :cutoff LIMIT :limit)
            """, nativeQuery = true)
    int deleteOlderThan(@Param("cutoff") Instant cutoff, @Param("limit") int limit);

    @Modifying
    @Query(value = "DELETE FROM user_login_event WHERE user_id = :userId", nativeQuery = true)
    int deleteByUserId(@Param("userId") UUID userId);
}
