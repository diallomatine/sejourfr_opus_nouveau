package com.sejourfr.app.progression.repository;

import com.sejourfr.app.progression.domain.EvidenceSourceFamily;
import com.sejourfr.app.progression.entity.ProgressionFamilyAggregateRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProgressionFamilyAggregateRepository
        extends JpaRepository<ProgressionFamilyAggregateRecord, UUID> {

    Optional<ProgressionFamilyAggregateRecord>
            findByUserIdAndStateKeyAndSourceFamilyAndEngineVersion(
                    UUID userId, String stateKey, EvidenceSourceFamily family, int engineVersion);

    List<ProgressionFamilyAggregateRecord> findByUserIdAndEngineVersion(
            UUID userId, int engineVersion);

    void deleteByUserIdAndEngineVersion(UUID userId, int engineVersion);
}
