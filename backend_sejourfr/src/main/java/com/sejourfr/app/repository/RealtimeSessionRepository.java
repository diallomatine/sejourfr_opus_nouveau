package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Les lignes {@code realtime_sessions} portent le cycle de vie d'une session
 * (PENDING → ACTIVE → COMPLETED | FAILED) et servent d'audit / analytics. Le
 * quota n'est PLUS dérivé de leur comptage : il vit sur
 * {@code user_subscriptions.realtime_eo_sessions_remaining} (cf. RealtimeQuotaService).
 */
@Repository
public interface RealtimeSessionRepository extends JpaRepository<RealtimeSession, UUID> {

    long countByStatus(RealtimeSessionStatus status);

    /**
     * Lecture VERROUILLEE (SELECT … FOR UPDATE) d'une session, pour toute
     * ecriture concurrente sur la meme ligne.
     *
     * <p>Deux invariants en dependent, et les deux se cassaient sur une simple
     * lecture non verrouillee — d'autant plus depuis qu'une coupure reseau peut
     * faire coexister deux connexions du meme candidat :
     * <ul>
     *   <li>le DEBIT DU SLOT n'a lieu qu'une fois : deux transactions lisant
     *       {@code PENDING} en meme temps passaient toutes deux la session
     *       {@code ACTIVE} et debitaient chacune une session du pass ;</li>
     *   <li>le TRANSCRIPT ne perd pas de tour : deux ajouts concurrents lisaient
     *       le meme texte et le dernier ecrasait l'autre.</li>
     * </ul>
     * A n'appeler que dans une transaction ({@code @Transactional}).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM RealtimeSession s WHERE s.id = :id")
    Optional<RealtimeSession> findByIdForUpdate(@Param("id") UUID id);
}
