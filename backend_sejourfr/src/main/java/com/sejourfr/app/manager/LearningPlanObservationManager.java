package com.sejourfr.app.manager;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.repository.LearningPlanObservationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
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

    /** Historique borne de plusieurs competences, en UNE requete quel que soit leur nombre. */
    public List<LearningPlanObservation> findByUserAndSkillsSince(
            UUID userId, Collection<UUID> skillIds, Instant after) {
        if (skillIds.isEmpty()) return List.of();
        return repository.findByUserAndSkillsSince(userId, skillIds, after);
    }

    /** Les {@code limit} observations probantes les plus recentes d'une competence. */
    public List<LearningPlanObservation> findTrajectory(UUID userId, UUID skillId, int limit) {
        return repository.findTrajectory(userId, skillId, PageRequest.of(0, Math.max(1, limit)));
    }

    public LearningPlanObservation save(LearningPlanObservation observation) {
        return repository.save(observation);
    }

    public long countSince(UUID userId, Instant after) {
        return repository.countDistinctActivitiesSince(userId, after);
    }

    public int deleteByUserId(UUID userId) { return repository.deleteByUserId(userId); }
}
