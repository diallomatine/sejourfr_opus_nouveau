package com.sejourfr.app.progression.repository;

import com.sejourfr.app.progression.entity.ProgressionStateRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProgressionStateRepository extends JpaRepository<ProgressionStateRecord, UUID> {

    Optional<ProgressionStateRecord> findByUserIdAndStateKeyAndEngineVersion(
            UUID userId, String stateKey, int engineVersion);

    List<ProgressionStateRecord> findByUserIdAndEngineVersion(UUID userId, int engineVersion);

    void deleteByUserIdAndEngineVersion(UUID userId, int engineVersion);
}
