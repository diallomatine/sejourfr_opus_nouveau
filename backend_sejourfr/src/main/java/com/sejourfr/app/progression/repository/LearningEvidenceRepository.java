package com.sejourfr.app.progression.repository;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface LearningEvidenceRepository extends JpaRepository<LearningEvidenceRecord, UUID> {

    boolean existsByUserIdAndNaturalKey(UUID userId, String naturalKey);

    /** Tout l'historique receptif d'un domaine — les trois paliers ensemble. */
    List<LearningEvidenceRecord> findByUserIdAndSectionOrderByOccurredAtAsc(
            UUID userId, SkillSection section);

    List<LearningEvidenceRecord> findByUserIdAndSectionAndSkillIdOrderByOccurredAtAsc(
            UUID userId, SkillSection section, String skillId);

    List<LearningEvidenceRecord> findByUserIdOrderByOccurredAtAsc(UUID userId);

    /**
     * Les series recentes du meme couple {@code user + section + level}, pour le
     * calcul du recouvrement (§12 bis.2).
     *
     * <p>La fenetre est bornee a {@code overlapWindowDays} : au-dela, on
     * considere qu'un item revu n'est plus « deja connu ».
     */
    @Query("""
            SELECT e FROM LearningEvidenceRecord e
            WHERE e.userId = :userId
              AND e.section = :section
              AND e.level = :level
              AND e.occurredAt >= :depuis
            ORDER BY e.occurredAt DESC
            """)
    List<LearningEvidenceRecord> findSeriesRecentes(@Param("userId") UUID userId,
                                                    @Param("section") SkillSection section,
                                                    @Param("level") TargetLevel level,
                                                    @Param("depuis") Instant depuis);

    /**
     * Les preuves d'un examen qualifiant survenu apres une prediction, pour le
     * rattachement shadow (§47.3).
     */
    @Query("""
            SELECT e FROM LearningEvidenceRecord e
            WHERE e.userId = :userId
              AND e.section = :section
              AND e.level = :level
              AND e.sourceType IN ('DOMAIN_MOCK', 'FULL_MOCK_EXAM')
              AND e.occurredAt > :apres
              AND e.occurredAt <= :avant
            ORDER BY e.occurredAt ASC
            """)
    List<LearningEvidenceRecord> findExamensQualifiants(@Param("userId") UUID userId,
                                                        @Param("section") SkillSection section,
                                                        @Param("level") TargetLevel level,
                                                        @Param("apres") Instant apres,
                                                        @Param("avant") Instant avant);
}
