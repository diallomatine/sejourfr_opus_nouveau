package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * IMPORTANT : recopier uniquement les méthodes manquantes si tu as déjà
 * un AttemptRepository.
 */
@Repository
public interface AttemptRepository extends JpaRepository<Attempt, UUID> {

    long countByUserId(UUID userId);

    long countByExamTemplateId(UUID examTemplateId);

    List<Attempt> findByUserIdOrderByStartedAtDesc(UUID userId);


    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND (:type IS NULL OR a.type = :type)
              AND (:module IS NULL OR a.module = :module)
            ORDER BY a.startedAt DESC
            """)
    List<Attempt> findByUserFiltered(
            @Param("userId") UUID userId,
            @Param("type") AttemptType type,
            @Param("module") Module module,
            Pageable pageable
    );

    /**
     * Quota mensuel des attempts "démo guest" (sans user) pour une IP donnée :
     * compte les attempts créés depuis {@code since} (1er du mois courant)
     * pour le couple (module, type). Cf. {@code idx_attempts_demo_quota}.
     */
    long countByClientIpAndModuleAndTypeAndUserIsNullAndStartedAtAfter(
            String clientIp,
            Module module,
            AttemptType type,
            Instant since
    );

    /**
     * Lookup sécurisé d'un attempt guest : exige que l'attempt soit bien
     * démo (user IS NULL) ET appartienne à la même IP que le caller.
     */
    Optional<Attempt> findByIdAndClientIpAndUserIsNull(UUID id, String clientIp);
}
