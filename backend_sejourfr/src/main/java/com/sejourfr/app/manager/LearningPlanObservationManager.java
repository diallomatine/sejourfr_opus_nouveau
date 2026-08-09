package com.sejourfr.app.manager;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.repository.LearningPlanObservationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class LearningPlanObservationManager {

    private final LearningPlanObservationRepository repository;

    public List<LearningPlanObservation> findAllByUserWithSkill(UUID userId) {
        return repository.findAllByUserWithSkill(userId);
    }

    public Optional<LearningPlanObservation> findBySource(
            UUID userId, UUID skillId, LearningPlanSourceType sourceType, UUID sourceId) {
        return repository.findByUserIdAndSkillIdAndSourceTypeAndSourceId(
                userId, skillId, sourceType, sourceId);
    }

    public LearningPlanObservation save(LearningPlanObservation observation) {
        return repository.save(observation);
    }

    public long countSince(UUID userId, Instant after) {
        return repository.countDistinctActivitiesSince(userId, after);
    }

    public int deleteByUserId(UUID userId) { return repository.deleteByUserId(userId); }
}
