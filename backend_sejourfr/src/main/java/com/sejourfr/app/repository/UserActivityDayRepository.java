package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserActivityDay;
import com.sejourfr.app.entity.UserActivityDayId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface UserActivityDayRepository extends JpaRepository<UserActivityDay, UserActivityDayId> {

    List<UserActivityDay> findByIdUserId(UUID userId);

    /**
     * Upsert de la presence : cree la ligne du jour, ou avance
     * {@code last_seen_at} (jamais en arriere).
     */
    @Modifying
    @Query(value = """
            INSERT INTO user_activity_day (user_id, day, platform, first_seen_at, last_seen_at)
            VALUES (:userId, :day, :platform, :at, :at)
            ON CONFLICT (user_id, day, platform) DO UPDATE
               SET last_seen_at = GREATEST(user_activity_day.last_seen_at, EXCLUDED.last_seen_at)
            """, nativeQuery = true)
    int touch(@Param("userId") UUID userId, @Param("day") LocalDate day, @Param("platform") String platform,
              @Param("at") Instant at);

    /** Purge bornee de la retention (365 j) : les jours strictement anterieurs a {@code before}. */
    @Modifying
    @Query(value = """
            DELETE FROM user_activity_day
             WHERE ctid = ANY (ARRAY(SELECT ctid FROM user_activity_day WHERE day < :before LIMIT :limit))
            """, nativeQuery = true)
    int deleteBefore(@Param("before") LocalDate before, @Param("limit") int limit);

    @Modifying
    @Query(value = "DELETE FROM user_activity_day WHERE user_id = :userId", nativeQuery = true)
    int deleteByUserId(@Param("userId") UUID userId);
}
