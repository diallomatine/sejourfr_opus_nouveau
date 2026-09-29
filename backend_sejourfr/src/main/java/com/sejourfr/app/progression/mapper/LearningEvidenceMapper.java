package com.sejourfr.app.progression.mapper;

import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;

/** Traduction pure entre la ligne de registre et le record du moteur. */
@Component
public class LearningEvidenceMapper {

    public LearningEvidence toDomain(LearningEvidenceRecord record) {
        return LearningEvidence.builder()
                .id(record.getId())
                .userId(record.getUserId())
                .attemptId(record.getAttemptId())
                .occurredAt(record.getOccurredAt())
                .ingestedAt(record.getIngestedAt())
                .entryPoint(record.getEntryPoint())
                .sourceType(record.getSourceType())
                .section(record.getSection())
                .level(record.getLevel())
                .skillId(record.getSkillId())
                .result(record.getResult())
                .scoringConfidence(record.getScoringConfidence())
                .assistanceLevel(record.getAssistanceLevel())
                .contentId(record.getContentId())
                .blueprintId(record.getBlueprintId())
                .calibrationStatus(record.getCalibrationStatus())
                .independenceClass(record.getIndependenceClass())
                .engineVersionAtCreation(record.getEngineVersionAtCreation())
                .metadata(record.getMetadata())
                .build();
    }

    public List<LearningEvidence> toDomain(Collection<LearningEvidenceRecord> records) {
        return records.stream().map(this::toDomain).toList();
    }

    public LearningEvidenceRecord toEntity(LearningEvidence evidence) {
        LearningEvidenceRecord record = new LearningEvidenceRecord();
        record.setUserId(evidence.userId());
        record.setAttemptId(evidence.attemptId());
        record.setOccurredAt(evidence.occurredAt());
        record.setIngestedAt(evidence.ingestedAt());
        record.setEntryPoint(evidence.entryPoint());
        record.setSourceType(evidence.sourceType());
        record.setSection(evidence.section());
        record.setLevel(evidence.level());
        record.setSkillId(evidence.skillId());
        record.setResult(evidence.result());
        record.setScoringConfidence(evidence.scoringConfidence());
        record.setAssistanceLevel(evidence.assistanceLevel());
        record.setContentId(evidence.contentId());
        record.setBlueprintId(evidence.blueprintId());
        record.setCalibrationStatus(evidence.calibrationStatus());
        record.setIndependenceClass(evidence.independenceClass());
        record.setEngineVersionAtCreation(evidence.engineVersionAtCreation());
        record.setMetadata(evidence.metadata() == null ? java.util.Map.of() : evidence.metadata());
        record.setNaturalKey(evidence.naturalKey());
        return record;
    }
}
