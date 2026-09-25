package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserEmailPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface UserEmailPreferenceRepository extends JpaRepository<UserEmailPreference, UUID> {

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM UserEmailPreference p WHERE p.userId = :userId")
    int deleteByUserIdQuery(@Param("userId") UUID userId);
}
