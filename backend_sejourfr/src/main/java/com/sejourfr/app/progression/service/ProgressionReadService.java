package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.engine.ProgressionEngine;
import com.sejourfr.app.progression.manager.LearningEvidenceManager;
import com.sejourfr.app.progression.mapper.LearningEvidenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * La lecture du moteur : les états, et surtout <b>ce que le Plan a le droit de
 * prescrire</b>.
 *
 * <p>🛑 Tout ce qui est dérivé se recalcule ici, à la lecture, et n'est jamais
 * persisté : {@code prerequisiteSatisfied}, {@code activeLearningLevel},
 * {@code prescriptionLevel}. Les stocker reviendrait à promettre au candidat un
 * acquis qu'on devra lui retirer quand le niveau supérieur qui le fondait
 * retombera (§18.4, invariant I21).
 */
@Service
@RequiredArgsConstructor
public class ProgressionReadService {

    private final ProgressionEngine engine;
    private final LearningEvidenceManager evidenceManager;
    private final LearningEvidenceMapper mapper;
    private final ProgressionProperties properties;

    /**
     * La lecture complète d'un domaine réceptif à l'objectif visé.
     *
     * <p>C'est d'ici que sort {@code prescriptionLevel} — <b>le seul niveau que
     * le Plan a le droit de proposer pour ce domaine</b> (§20, invariant I15).
     * Un domaine, un niveau : jamais {@code CO A2} et {@code CO B1} le même jour.
     */
    @Transactional(readOnly = true)
    public DomainProjection domaine(UUID userId, SkillSection section, TargetLevel objectif,
                                    Instant now) {
        List<LearningEvidence> historique =
                mapper.toDomain(evidenceManager.historiqueDomaine(userId, section));
        return engine.projectDomain(section, objectif, historique, now);
    }

    /** L'état d'une compétence de production. */
    @Transactional(readOnly = true)
    public ProgressionSnapshot competence(UUID userId, SkillSection section, String skillId,
                                          Instant now) {
        ProgressionStateKey cle = ProgressionStateKey.productive(section, skillId);
        List<LearningEvidence> historique =
                mapper.toDomain(evidenceManager.historiqueCompetence(userId, section, skillId));
        return engine.project(cle, historique, now);
    }

    /** L'état d'un palier réceptif. */
    @Transactional(readOnly = true)
    public ProgressionSnapshot palier(UUID userId, SkillSection section, TargetLevel level,
                                      Instant now) {
        ProgressionStateKey cle = ProgressionStateKey.receptive(section, level);
        List<LearningEvidence> historique =
                mapper.toDomain(evidenceManager.historiqueDomaine(userId, section));
        return engine.project(cle, historique, now);
    }

    /** La version de moteur qui sert les lectures. */
    public int engineVersion() {
        return properties.getEngineVersion();
    }
}
